import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../db/mysql_database.dart';
import '../middleware/auth_middleware.dart';
import '../utils/json_response.dart';
import '../utils/request_body.dart';

class FavoriteRoutes {
  FavoriteRoutes(this._database);

  final MySqlDatabase _database;

  Router get router => Router()
    ..post('/<productId|[0-9]+>', _add)
    ..delete('/<productId|[0-9]+>', _remove);

  Future<Response> _add(Request request, String productId) {
    final user = authUser(request);
    return _database.withConnection((connection) async {
      await connection.query(
        'INSERT IGNORE INTO favorites(user_id, product_id) VALUES (?, ?)',
        [user.id, int.parse(productId)],
      );
      return jsonResponse({'message': 'Favorite saved'});
    });
  }

  Future<Response> _remove(Request request, String productId) {
    final user = authUser(request);
    return _database.withConnection((connection) async {
      await connection.query(
        'DELETE FROM favorites WHERE user_id = ? AND product_id = ?',
        [user.id, int.parse(productId)],
      );
      return jsonResponse({'message': 'Favorite removed'});
    });
  }
}

class AddressRoutes {
  AddressRoutes(this._database);

  final MySqlDatabase _database;

  Router get router => Router()
    ..get('/', _list)
    ..post('/', _create)
    ..put('/<id|[0-9]+>', _update)
    ..delete('/<id|[0-9]+>', _delete);

  Future<Response> _list(Request request) {
    final user = authUser(request);
    return _database.withConnection((connection) async {
      final results = await connection.query(
        'SELECT id, receiver, phone, province, city, detail, is_default FROM addresses WHERE user_id = ? ORDER BY is_default DESC, id DESC',
        [user.id],
      );
      return jsonResponse(results.map((row) => row.fields).toList());
    });
  }

  Future<Response> _create(Request request) async {
    final user = authUser(request);
    final body = await readJsonObject(request);
    return _database.withConnection((connection) async {
      if (body['isDefault'] == true) {
        await connection.query(
          'UPDATE addresses SET is_default = 0 WHERE user_id = ?',
          [user.id],
        );
      }
      final result = await connection.query(
        '''
        INSERT INTO addresses(user_id, receiver, phone, province, city, detail, is_default)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          user.id,
          body['receiver'],
          body['phone'],
          body['province'],
          body['city'],
          body['detail'],
          body['isDefault'] == true ? 1 : 0,
        ],
      );
      return jsonResponse({'id': result.insertId}, statusCode: 201);
    });
  }

  Future<Response> _update(Request request, String id) async {
    final user = authUser(request);
    final body = await readJsonObject(request);
    return _database.withConnection((connection) async {
      if (body['isDefault'] == true) {
        await connection.query(
          'UPDATE addresses SET is_default = 0 WHERE user_id = ?',
          [user.id],
        );
      }
      final result = await connection.query(
        '''
        UPDATE addresses
        SET receiver = ?, phone = ?, province = ?, city = ?, detail = ?, is_default = ?
        WHERE id = ? AND user_id = ?
        ''',
        [
          body['receiver'],
          body['phone'],
          body['province'],
          body['city'],
          body['detail'],
          body['isDefault'] == true ? 1 : 0,
          int.parse(id),
          user.id,
        ],
      );
      if (result.affectedRows == 0) {
        return jsonResponse({'message': 'Address not found'}, statusCode: 404);
      }
      return jsonResponse({'message': 'Address updated'});
    });
  }

  Future<Response> _delete(Request request, String id) {
    final user = authUser(request);
    return _database.withConnection((connection) async {
      final result = await connection.query(
        'DELETE FROM addresses WHERE id = ? AND user_id = ?',
        [int.parse(id), user.id],
      );
      if (result.affectedRows == 0) {
        return jsonResponse({'message': 'Address not found'}, statusCode: 404);
      }
      return jsonResponse({'message': 'Address deleted'});
    });
  }
}

class ReviewRoutes {
  ReviewRoutes(this._database);

  final MySqlDatabase _database;

  Router get router => Router()
    ..get('/products/<productId|[0-9]+>', _productReviews)
    ..post('/', _create);

  Future<Response> _productReviews(Request request, String productId) {
    return _database.withConnection((connection) async {
      final results = await connection.query(
        '''
        SELECT r.id, r.rating, r.content, r.created_at, u.name AS user_name
        FROM reviews r
        JOIN users u ON u.id = r.user_id
        WHERE r.product_id = ? AND r.status = "VISIBLE"
        ORDER BY r.created_at DESC
        LIMIT 50
        ''',
        [int.parse(productId)],
      );
      return jsonResponse(
        results.map((row) {
          final data = row.fields;
          return {
            'id': data['id'],
            'rating': data['rating'],
            'content': data['content'],
            'userName': data['user_name'],
            'createdAt': data['created_at'].toString(),
          };
        }).toList(),
      );
    });
  }

  Future<Response> _create(Request request) async {
    final user = authUser(request);
    final body = await readJsonObject(request);
    final productId = int.tryParse(body['productId']?.toString() ?? '');
    final orderItemId = int.tryParse(body['orderItemId']?.toString() ?? '');
    final rating = int.tryParse(body['rating']?.toString() ?? '');
    final content = body['content']?.toString().trim() ?? '';
    if (productId == null ||
        orderItemId == null ||
        rating == null ||
        rating < 1 ||
        rating > 5 ||
        content.isEmpty) {
      return jsonResponse({
        'message': 'Product, order item, rating and content are required',
      }, statusCode: 400);
    }
    return _database.withConnection((connection) async {
      final purchased = await connection.query(
        '''
        SELECT oi.id
        FROM order_items oi
        JOIN orders o ON o.id = oi.order_id
        WHERE oi.id = ? AND oi.product_id = ? AND o.buyer_user_id = ?
          AND o.status IN ("PAID", "SHIPPED", "COMPLETED")
        ''',
        [orderItemId, productId, user.id],
      );
      if (purchased.isEmpty) {
        return jsonResponse({
          'message': 'Only purchased products can be reviewed',
        }, statusCode: 403);
      }
      final exists = await connection.query(
        'SELECT id FROM reviews WHERE order_item_id = ?',
        [orderItemId],
      );
      if (exists.isNotEmpty) {
        return jsonResponse({
          'message': 'This order item was already reviewed',
        }, statusCode: 409);
      }
      final result = await connection.query(
        '''
        INSERT INTO reviews(user_id, product_id, order_item_id, rating, content, status)
        VALUES (?, ?, ?, ?, ?, "VISIBLE")
        ''',
        [user.id, productId, orderItemId, rating, content],
      );
      return jsonResponse({'id': result.insertId}, statusCode: 201);
    });
  }
}
