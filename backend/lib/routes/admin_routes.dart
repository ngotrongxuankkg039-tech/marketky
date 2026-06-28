import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../db/mysql_database.dart';
import '../utils/json_response.dart';
import '../utils/request_body.dart';

class AdminRoutes {
  AdminRoutes(this._database);

  final MySqlDatabase _database;

  Router get router => Router()
    ..get('/stats', _stats)
    ..get('/users', _users)
    ..put('/users/<id|[0-9]+>/status', _updateUserStatus)
    ..get('/merchant-applications', _merchantApplications)
    ..put('/merchant-applications/<id|[0-9]+>/audit', _auditMerchant)
    ..post('/categories', _createCategory)
    ..put('/categories/<id|[0-9]+>', _updateCategory);

  Future<Response> _stats(Request request) {
    return _database.withConnection((connection) async {
      final users = await connection.query(
        'SELECT COUNT(*) AS total FROM users',
      );
      final shops = await connection.query(
        'SELECT COUNT(*) AS total FROM shops',
      );
      final orders = await connection.query(
        'SELECT COUNT(*) AS total FROM orders',
      );
      final sales = await connection.query(
        'SELECT COALESCE(SUM(total_amount), 0) AS total FROM orders WHERE status <> "CANCELLED"',
      );
      return jsonResponse({
        'users': users.first.fields['total'],
        'shops': shops.first.fields['total'],
        'orders': orders.first.fields['total'],
        'sales': sales.first.fields['total'].toString(),
      });
    });
  }

  Future<Response> _users(Request request) {
    return _database.withConnection((connection) async {
      final results = await connection.query(
        'SELECT id, name, email, status, created_at FROM users ORDER BY id DESC LIMIT 200',
      );
      return jsonResponse(results.map((row) => row.fields).toList());
    });
  }

  Future<Response> _updateUserStatus(Request request, String id) async {
    final body = await readJsonObject(request);
    final status = body['status']?.toString() ?? 'DISABLED';
    return _database.withConnection((connection) async {
      await connection.query('UPDATE users SET status = ? WHERE id = ?', [
        status,
        int.parse(id),
      ]);
      return jsonResponse({'message': 'User status updated'});
    });
  }

  Future<Response> _merchantApplications(Request request) {
    return _database.withConnection((connection) async {
      final results = await connection.query('''
        SELECT ma.id, ma.shop_name, u.name AS owner_name, ma.status, ma.created_at
        FROM merchant_applications ma
        JOIN users u ON u.id = ma.user_id
        ORDER BY ma.created_at DESC
        ''');
      return jsonResponse(
        results.map((row) {
          final data = row.fields;
          return {
            'id': data['id'],
            'shopName': data['shop_name'],
            'ownerName': data['owner_name'],
            'status': data['status'],
            'createdAt': data['created_at'].toString(),
          };
        }).toList(),
      );
    });
  }

  Future<Response> _auditMerchant(Request request, String id) async {
    final body = await readJsonObject(request);
    final approved = body['approved'] == true;
    return _database.transaction((connection) async {
      final apps = await connection.query(
        'SELECT * FROM merchant_applications WHERE id = ? FOR UPDATE',
        [int.parse(id)],
      );
      if (apps.isEmpty) {
        return jsonResponse({
          'message': 'Application not found',
        }, statusCode: 404);
      }
      final app = apps.first.fields;
      await connection.query(
        'UPDATE merchant_applications SET status = ?, reviewed_at = NOW() WHERE id = ?',
        [approved ? 'APPROVED' : 'REJECTED', int.parse(id)],
      );
      if (approved) {
        final shop = await connection.query(
          'INSERT INTO shops(owner_user_id, name, description, status) VALUES (?, ?, ?, "APPROVED")',
          [app['user_id'], app['shop_name'], app['description']],
        );
        final role = await connection.query(
          'SELECT id FROM roles WHERE code = "MERCHANT_ADMIN"',
        );
        await connection.query(
          'INSERT IGNORE INTO user_roles(user_id, role_id) VALUES (?, ?)',
          [app['user_id'], role.first.fields['id']],
        );
        return jsonResponse({
          'message': 'Merchant approved',
          'shopId': shop.insertId,
        });
      }
      return jsonResponse({'message': 'Merchant rejected'});
    });
  }

  Future<Response> _createCategory(Request request) async {
    final body = await readJsonObject(request);
    return _database.withConnection((connection) async {
      final result = await connection.query(
        'INSERT INTO categories(parent_id, name, sort_order, status) VALUES (?, ?, ?, "ENABLED")',
        [body['parentId'], body['name'], body['sortOrder'] ?? 0],
      );
      return jsonResponse({'id': result.insertId}, statusCode: 201);
    });
  }

  Future<Response> _updateCategory(Request request, String id) async {
    final body = await readJsonObject(request);
    return _database.withConnection((connection) async {
      await connection.query(
        'UPDATE categories SET name = ?, sort_order = ?, status = ? WHERE id = ?',
        [
          body['name'],
          body['sortOrder'] ?? 0,
          body['status'] ?? 'ENABLED',
          int.parse(id),
        ],
      );
      return jsonResponse({'message': 'Category updated'});
    });
  }
}
