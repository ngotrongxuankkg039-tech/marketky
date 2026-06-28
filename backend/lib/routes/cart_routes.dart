import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../db/mysql_database.dart';
import '../middleware/auth_middleware.dart';
import '../utils/json_response.dart';
import '../utils/request_body.dart';

class CartRoutes {
  CartRoutes(this._database);

  final MySqlDatabase _database;

  Router get router => Router()
    ..get('/', _list)
    ..post('/items', _addItem)
    ..put('/items/<productId|[0-9]+>', _updateItem)
    ..delete('/items/<productId|[0-9]+>', _deleteItem);

  Future<Response> _list(Request request) {
    final user = authUser(request);
    return _database.withConnection((connection) async {
      final cartId = await _cartId(connection, user.id);
      final results = await connection.query(
        '''
        SELECT ci.quantity, p.id, p.shop_id, p.category_id, p.name, p.description, p.price, p.stock, p.status,
               COALESCE(MIN(pi.url), '') AS image_url
        FROM cart_items ci
        JOIN products p ON p.id = ci.product_id
        LEFT JOIN product_images pi ON pi.product_id = p.id
        WHERE ci.cart_id = ?
        GROUP BY ci.id, p.id
        ORDER BY ci.created_at DESC
        ''',
        [cartId],
      );
      return jsonResponse(
        results.map((row) {
          final data = row.fields;
          return {
            'quantity': data['quantity'],
            'product': {
              'id': data['id'],
              'shopId': data['shop_id'],
              'categoryId': data['category_id'],
              'name': data['name'],
              'description': data['description'],
              'price': data['price'].toString(),
              'stock': data['stock'],
              'status': data['status'],
              'imageUrl': data['image_url'],
            },
          };
        }).toList(),
      );
    });
  }

  Future<Response> _addItem(Request request) async {
    final user = authUser(request);
    final body = await readJsonObject(request);
    final productId = body['productId'] as int;
    final quantity = body['quantity'] as int? ?? 1;
    if (quantity <= 0) {
      return jsonResponse({
        'message': 'Quantity must be positive',
      }, statusCode: 400);
    }
    return _database.withConnection((connection) async {
      final cartId = await _cartId(connection, user.id);
      await connection.query(
        '''
        INSERT INTO cart_items(cart_id, product_id, quantity)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE quantity = quantity + VALUES(quantity)
        ''',
        [cartId, productId, quantity],
      );
      return jsonResponse({'message': 'Cart item saved'});
    });
  }

  Future<Response> _updateItem(Request request, String productId) async {
    final user = authUser(request);
    final body = await readJsonObject(request);
    final quantity = body['quantity'] as int? ?? 1;
    return _database.withConnection((connection) async {
      final cartId = await _cartId(connection, user.id);
      if (quantity <= 0) {
        await connection.query(
          'DELETE FROM cart_items WHERE cart_id = ? AND product_id = ?',
          [cartId, int.parse(productId)],
        );
      } else {
        await connection.query(
          'UPDATE cart_items SET quantity = ? WHERE cart_id = ? AND product_id = ?',
          [quantity, cartId, int.parse(productId)],
        );
      }
      return jsonResponse({'message': 'Cart item updated'});
    });
  }

  Future<Response> _deleteItem(Request request, String productId) async {
    final user = authUser(request);
    return _database.withConnection((connection) async {
      final cartId = await _cartId(connection, user.id);
      await connection.query(
        'DELETE FROM cart_items WHERE cart_id = ? AND product_id = ?',
        [cartId, int.parse(productId)],
      );
      return jsonResponse({'message': 'Cart item deleted'});
    });
  }

  Future<int> _cartId(dynamic connection, int userId) async {
    final carts = await connection.query(
      'SELECT id FROM carts WHERE user_id = ?',
      [userId],
    );
    if (carts.isNotEmpty) {
      return carts.first.fields['id'] as int;
    }
    final result = await connection.query(
      'INSERT INTO carts(user_id) VALUES (?)',
      [userId],
    );
    return result.insertId!;
  }
}
