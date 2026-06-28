import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../db/mysql_database.dart';
import '../middleware/auth_middleware.dart';
import '../utils/json_response.dart';
import '../utils/request_body.dart';

class MerchantRoutes {
  MerchantRoutes(this._database);

  final MySqlDatabase _database;

  Router get router => Router()
    ..get('/stats', _stats)
    ..get('/products', _products)
    ..post('/products', _createProduct)
    ..put('/products/<id|[0-9]+>/stock', _updateStock)
    ..put('/products/<id|[0-9]+>/status', _updateStatus)
    ..put('/orders/<id|[0-9]+>/ship', _shipOrder)
    ..put('/refunds/<id|[0-9]+>/audit', _auditRefund);

  Future<Response> _stats(Request request) {
    final user = authUser(request);
    return _database.withConnection((connection) async {
      final shopId = await _shopId(connection, user.id);
      final productCount = await connection.query(
        'SELECT COUNT(*) AS total FROM products WHERE shop_id = ?',
        [shopId],
      );
      final orderCount = await connection.query(
        'SELECT COUNT(*) AS total FROM orders WHERE shop_id = ?',
        [shopId],
      );
      final sales = await connection.query(
        'SELECT COALESCE(SUM(total_amount), 0) AS total FROM orders WHERE shop_id = ? AND status IN ("PAID", "SHIPPED", "COMPLETED")',
        [shopId],
      );
      return jsonResponse({
        'products': productCount.first.fields['total'],
        'orders': orderCount.first.fields['total'],
        'sales': sales.first.fields['total'].toString(),
      });
    });
  }

  Future<Response> _products(Request request) {
    final user = authUser(request);
    return _database.withConnection((connection) async {
      final shopId = await _shopId(connection, user.id);
      final results = await connection.query(
        'SELECT id, name, price, stock, status FROM products WHERE shop_id = ? AND deleted_at IS NULL ORDER BY id DESC',
        [shopId],
      );
      return jsonResponse(results.map((row) => row.fields).toList());
    });
  }

  Future<Response> _createProduct(Request request) async {
    final user = authUser(request);
    final body = await readJsonObject(request);
    return _database.withConnection((connection) async {
      final shopId = await _shopId(connection, user.id);
      final result = await connection.query(
        '''
        INSERT INTO products(shop_id, category_id, name, description, price, stock, status)
        VALUES (?, ?, ?, ?, ?, ?, "ON_SALE")
        ''',
        [
          shopId,
          body['categoryId'],
          body['name'],
          body['description'],
          body['price'],
          body['stock'],
        ],
      );
      await connection.query(
        'INSERT INTO stock_logs(product_id, change_quantity, change_type, remark) VALUES (?, ?, "MANUAL_IN", "商家新增商品初始库存")',
        [result.insertId, body['stock']],
      );
      return jsonResponse({'id': result.insertId}, statusCode: 201);
    });
  }

  Future<Response> _updateStock(Request request, String id) async {
    final user = authUser(request);
    final body = await readJsonObject(request);
    final nextStock = body['stock'] as int;
    if (nextStock < 0) {
      return jsonResponse({
        'message': 'Stock cannot be negative',
      }, statusCode: 400);
    }
    return _database.transaction((connection) async {
      final shopId = await _shopId(connection, user.id);
      final current = await connection.query(
        'SELECT stock FROM products WHERE id = ? AND shop_id = ? FOR UPDATE',
        [int.parse(id), shopId],
      );
      if (current.isEmpty) {
        return jsonResponse({'message': 'Product not found'}, statusCode: 404);
      }
      final oldStock = current.first.fields['stock'] as int;
      await connection.query('UPDATE products SET stock = ? WHERE id = ?', [
        nextStock,
        int.parse(id),
      ]);
      await connection.query(
        'INSERT INTO stock_logs(product_id, change_quantity, change_type, remark) VALUES (?, ?, "ADJUST", ?)',
        [int.parse(id), nextStock - oldStock, '商家库存调整'],
      );
      return jsonResponse({'message': 'Stock updated'});
    });
  }

  Future<Response> _updateStatus(Request request, String id) async {
    final user = authUser(request);
    final body = await readJsonObject(request);
    final status = body['status']?.toString() ?? 'OFF_SALE';
    return _database.withConnection((connection) async {
      final shopId = await _shopId(connection, user.id);
      await connection.query(
        'UPDATE products SET status = ? WHERE id = ? AND shop_id = ?',
        [status, int.parse(id), shopId],
      );
      return jsonResponse({'message': 'Product status updated'});
    });
  }

  Future<Response> _shipOrder(Request request, String id) {
    final user = authUser(request);
    return _database.withConnection((connection) async {
      final shopId = await _shopId(connection, user.id);
      await connection.query(
        'UPDATE orders SET status = "SHIPPED", shipped_at = NOW() WHERE id = ? AND shop_id = ? AND status = "PAID"',
        [int.parse(id), shopId],
      );
      return jsonResponse({'message': 'Order shipped'});
    });
  }

  Future<Response> _auditRefund(Request request, String id) async {
    final user = authUser(request);
    final body = await readJsonObject(request);
    final approved = body['approved'] == true;
    return _database.transaction((connection) async {
      final shopId = await _shopId(connection, user.id);
      final refunds = await connection.query(
        '''
        SELECT r.id, r.order_id
        FROM refunds r
        JOIN orders o ON o.id = r.order_id
        WHERE r.id = ? AND o.shop_id = ?
        FOR UPDATE
        ''',
        [int.parse(id), shopId],
      );
      if (refunds.isEmpty) {
        return jsonResponse({'message': 'Refund not found'}, statusCode: 404);
      }
      await connection.query('UPDATE refunds SET status = ? WHERE id = ?', [
        approved ? 'APPROVED' : 'REJECTED',
        int.parse(id),
      ]);
      if (approved) {
        await connection.query(
          'UPDATE orders SET status = "REFUNDED" WHERE id = ?',
          [refunds.first.fields['order_id']],
        );
      }
      return jsonResponse({'message': 'Refund audited'});
    });
  }

  Future<int> _shopId(dynamic connection, int userId) async {
    final results = await connection.query(
      'SELECT id FROM shops WHERE owner_user_id = ? AND status = "APPROVED" LIMIT 1',
      [userId],
    );
    if (results.isEmpty) {
      throw StateError('当前账号没有已审核店铺');
    }
    return results.first.fields['id'] as int;
  }
}
