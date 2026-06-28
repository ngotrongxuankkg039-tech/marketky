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
    ..get('/shop', _shop)
    ..put('/shop', _updateShop)
    ..get('/products', _products)
    ..post('/products', _createProduct)
    ..put('/products/<id|[0-9]+>', _updateProduct)
    ..put('/products/<id|[0-9]+>/stock', _updateStock)
    ..put('/products/<id|[0-9]+>/status', _updateStatus)
    ..get('/orders', _orders)
    ..get('/refunds', _refunds)
    ..put('/orders/<id|[0-9]+>/ship', _shipOrder)
    ..put('/refunds/<id|[0-9]+>/audit', _auditRefund);

  Future<Response> _stats(Request request) {
    final user = authUser(request);
    return _database.withConnection((connection) async {
      final shopId = await _shopId(connection, user.id);
      final productCount = await connection.query(
        'SELECT COUNT(*) AS total FROM products WHERE shop_id = ? AND deleted_at IS NULL AND status = "ON_SALE"',
        [shopId],
      );
      final orderCount = await connection.query(
        'SELECT COUNT(*) AS total FROM orders WHERE shop_id = ?',
        [shopId],
      );
      final pendingShipments = await connection.query(
        'SELECT COUNT(*) AS total FROM orders WHERE shop_id = ? AND status = "PAID"',
        [shopId],
      );
      final refundRequests = await connection.query(
        '''
        SELECT COUNT(*) AS total
        FROM refunds r
        JOIN orders o ON o.id = r.order_id
        WHERE o.shop_id = ? AND r.status = "REQUESTED"
        ''',
        [shopId],
      );
      final sales = await connection.query(
        'SELECT COALESCE(SUM(total_amount), 0) AS total FROM orders WHERE shop_id = ? AND status IN ("PAID", "SHIPPED", "COMPLETED")',
        [shopId],
      );
      return jsonResponse({
        'products': productCount.first.fields['total'],
        'orders': orderCount.first.fields['total'],
        'pendingShipments': pendingShipments.first.fields['total'],
        'refundRequests': refundRequests.first.fields['total'],
        'sales': sales.first.fields['total'].toString(),
      });
    });
  }

  Future<Response> _shop(Request request) {
    final user = authUser(request);
    return _database.withConnection((connection) async {
      final shopId = await _shopId(connection, user.id);
      final results = await connection.query(
        '''
        SELECT id, owner_user_id, name, description, contact_phone, status, created_at, updated_at
        FROM shops
        WHERE id = ?
        ''',
        [shopId],
      );
      if (results.isEmpty) {
        return jsonResponse({'message': 'Shop not found'}, statusCode: 404);
      }
      final data = results.first.fields;
      return jsonResponse({
        'id': data['id'],
        'name': data['name'],
        'description': data['description'],
        'contactPhone': data['contact_phone'],
        'status': data['status'],
        'createdAt': data['created_at'].toString(),
        'updatedAt': data['updated_at'].toString(),
      });
    });
  }

  Future<Response> _updateShop(Request request) async {
    final user = authUser(request);
    final body = await readJsonObject(request);
    final name = body['name']?.toString().trim() ?? '';
    final description = body['description']?.toString().trim() ?? '';
    final contactPhone = body['contactPhone']?.toString().trim() ?? '';
    if (name.isEmpty) {
      return jsonResponse({
        'message': 'Shop name is required',
      }, statusCode: 400);
    }
    return _database.withConnection((connection) async {
      final shopId = await _shopId(connection, user.id);
      final result = await connection.query(
        'UPDATE shops SET name = ?, description = ?, contact_phone = ? WHERE id = ?',
        [name, description, contactPhone, shopId],
      );
      if (result.affectedRows == 0) {
        return jsonResponse({'message': 'Shop not found'}, statusCode: 404);
      }
      return jsonResponse({'message': 'Shop updated'});
    });
  }

  Future<Response> _products(Request request) {
    final user = authUser(request);
    return _database.withConnection((connection) async {
      final shopId = await _shopId(connection, user.id);
      final results = await connection.query(
        '''
        SELECT p.id, p.shop_id, p.category_id, p.name, p.description, p.price, p.stock, p.status,
               COALESCE(MIN(pi.url), '') AS image_url
        FROM products p
        LEFT JOIN product_images pi ON pi.product_id = p.id
        WHERE p.shop_id = ? AND p.deleted_at IS NULL
        GROUP BY p.id
        ORDER BY p.id DESC
        ''',
        [shopId],
      );
      return jsonResponse(results.map(_productJson).toList());
    });
  }

  Future<Response> _createProduct(Request request) async {
    final user = authUser(request);
    final body = await readJsonObject(request);
    final validation = _validateProductBody(body);
    if (validation != null) return validation;
    final categoryId = int.parse(body['categoryId'].toString());
    final price = num.parse(body['price'].toString());
    final stock = int.parse(body['stock'].toString());
    return _database.withConnection((connection) async {
      final shopId = await _shopId(connection, user.id);
      final result = await connection.query(
        '''
        INSERT INTO products(shop_id, category_id, name, description, price, stock, status)
        VALUES (?, ?, ?, ?, ?, ?, "ON_SALE")
        ''',
        [
          shopId,
          categoryId,
          body['name']?.toString().trim(),
          body['description']?.toString().trim() ?? '',
          price,
          stock,
        ],
      );
      await connection.query(
        'INSERT INTO stock_logs(product_id, change_quantity, change_type, remark) VALUES (?, ?, "MANUAL_IN", "商家新增商品初始库存")',
        [result.insertId, stock],
      );
      final imageUrl = body['imageUrl']?.toString().trim() ?? '';
      if (imageUrl.isNotEmpty) {
        await connection.query(
          'INSERT INTO product_images(product_id, url, sort_order) VALUES (?, ?, 1)',
          [result.insertId, imageUrl],
        );
      }
      return jsonResponse({'id': result.insertId}, statusCode: 201);
    });
  }

  Future<Response> _updateProduct(Request request, String id) async {
    final user = authUser(request);
    final body = await readJsonObject(request);
    final validation = _validateProductBody(body, requireStock: false);
    if (validation != null) return validation;
    final categoryId = int.parse(body['categoryId'].toString());
    final price = num.parse(body['price'].toString());
    return _database.withConnection((connection) async {
      final shopId = await _shopId(connection, user.id);
      final result = await connection.query(
        '''
        UPDATE products
        SET category_id = ?, name = ?, description = ?, price = ?
        WHERE id = ? AND shop_id = ? AND deleted_at IS NULL
        ''',
        [
          categoryId,
          body['name']?.toString().trim(),
          body['description']?.toString().trim() ?? '',
          price,
          int.parse(id),
          shopId,
        ],
      );
      if (result.affectedRows == 0) {
        return jsonResponse({'message': 'Product not found'}, statusCode: 404);
      }
      final imageUrl = body['imageUrl']?.toString().trim() ?? '';
      if (imageUrl.isNotEmpty) {
        await connection.query(
          'DELETE FROM product_images WHERE product_id = ?',
          [int.parse(id)],
        );
        await connection.query(
          'INSERT INTO product_images(product_id, url, sort_order) VALUES (?, ?, 1)',
          [int.parse(id), imageUrl],
        );
      }
      return jsonResponse({'message': 'Product updated'});
    });
  }

  Future<Response> _updateStock(Request request, String id) async {
    final user = authUser(request);
    final body = await readJsonObject(request);
    final nextStock = int.tryParse(body['stock']?.toString() ?? '');
    if (nextStock == null || nextStock < 0) {
      return jsonResponse({
        'message': 'Stock must be a non-negative integer',
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
    if (!{'ON_SALE', 'OFF_SALE'}.contains(status)) {
      return jsonResponse({
        'message': 'Invalid product status',
      }, statusCode: 400);
    }
    return _database.withConnection((connection) async {
      final shopId = await _shopId(connection, user.id);
      final result = await connection.query(
        'UPDATE products SET status = ? WHERE id = ? AND shop_id = ?',
        [status, int.parse(id), shopId],
      );
      if (result.affectedRows == 0) {
        return jsonResponse({'message': 'Product not found'}, statusCode: 404);
      }
      return jsonResponse({'message': 'Product status updated'});
    });
  }

  Future<Response> _orders(Request request) {
    final user = authUser(request);
    final status = request.url.queryParameters['status'];
    return _database.withConnection((connection) async {
      final shopId = await _shopId(connection, user.id);
      final where = <String>['o.shop_id = ?'];
      final values = <Object?>[shopId];
      if (status != null && status.isNotEmpty) {
        where.add('o.status = ?');
        values.add(status);
      }
      final results = await connection.query('''
        SELECT o.id, o.order_no, o.status, o.total_amount, o.pay_method, o.created_at, o.shipped_at,
               u.name AS buyer_name, COUNT(oi.id) AS item_count
        FROM orders o
        JOIN users u ON u.id = o.buyer_user_id
        LEFT JOIN order_items oi ON oi.order_id = o.id
        WHERE ${where.join(' AND ')}
        GROUP BY o.id
        ORDER BY o.created_at DESC
        ''', values);
      return jsonResponse(
        results.map((row) {
          final data = row.fields;
          return {
            'id': data['id'],
            'orderNo': data['order_no'],
            'status': data['status'],
            'totalAmount': data['total_amount'].toString(),
            'payMethod': data['pay_method'],
            'buyerName': data['buyer_name'],
            'itemCount': data['item_count'],
            'createdAt': data['created_at'].toString(),
            'shippedAt': data['shipped_at']?.toString(),
          };
        }).toList(),
      );
    });
  }

  Future<Response> _refunds(Request request) {
    final user = authUser(request);
    return _database.withConnection((connection) async {
      final shopId = await _shopId(connection, user.id);
      final results = await connection.query(
        '''
        SELECT r.id, r.order_id, r.reason, r.amount, r.status, r.created_at,
               o.order_no, u.name AS buyer_name
        FROM refunds r
        JOIN orders o ON o.id = r.order_id
        JOIN users u ON u.id = r.user_id
        WHERE o.shop_id = ?
        ORDER BY r.created_at DESC
        ''',
        [shopId],
      );
      return jsonResponse(
        results.map((row) {
          final data = row.fields;
          return {
            'id': data['id'],
            'orderId': data['order_id'],
            'orderNo': data['order_no'],
            'buyerName': data['buyer_name'],
            'reason': data['reason'],
            'amount': data['amount'].toString(),
            'status': data['status'],
            'createdAt': data['created_at'].toString(),
          };
        }).toList(),
      );
    });
  }

  Future<Response> _shipOrder(Request request, String id) {
    final user = authUser(request);
    return _database.withConnection((connection) async {
      final shopId = await _shopId(connection, user.id);
      final result = await connection.query(
        'UPDATE orders SET status = "SHIPPED", shipped_at = NOW() WHERE id = ? AND shop_id = ? AND status = "PAID"',
        [int.parse(id), shopId],
      );
      if (result.affectedRows == 0) {
        return jsonResponse({
          'message': 'Only paid orders can be shipped',
        }, statusCode: 409);
      }
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

  Response? _validateProductBody(
    Map<String, dynamic> body, {
    bool requireStock = true,
  }) {
    final name = body['name']?.toString().trim() ?? '';
    final categoryId = int.tryParse(body['categoryId']?.toString() ?? '');
    final price = num.tryParse(body['price']?.toString() ?? '');
    final stock = int.tryParse(body['stock']?.toString() ?? '');
    if (name.isEmpty || categoryId == null || price == null || price < 0) {
      return jsonResponse({
        'message': 'Valid category, name and price are required',
      }, statusCode: 400);
    }
    if (requireStock && (stock == null || stock < 0)) {
      return jsonResponse({
        'message': 'Valid stock is required',
      }, statusCode: 400);
    }
    return null;
  }

  Map<String, dynamic> _productJson(dynamic row) {
    final data = row.fields;
    return {
      'id': data['id'],
      'shopId': data['shop_id'],
      'categoryId': data['category_id'],
      'name': data['name'],
      'description': data['description'],
      'price': data['price'].toString(),
      'stock': data['stock'],
      'status': data['status'],
      'imageUrl': data['image_url'],
    };
  }
}
