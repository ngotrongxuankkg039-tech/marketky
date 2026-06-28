import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../db/mysql_database.dart';
import '../middleware/auth_middleware.dart';
import '../utils/ids.dart';
import '../utils/json_response.dart';
import '../utils/request_body.dart';

class OrderRoutes {
  OrderRoutes(this._database);

  final MySqlDatabase _database;

  Router get router => Router()
    ..get('/', _list)
    ..post('/', _create)
    ..get('/<id|[0-9]+>', _detail)
    ..post('/<id|[0-9]+>/refunds', _requestRefund);

  Future<Response> _list(Request request) {
    final user = authUser(request);
    return _database.withConnection((connection) async {
      final results = await connection.query(
        '''
        SELECT o.id, o.order_no, o.status, o.total_amount, o.pay_method, o.created_at,
               COALESCE(p.status, 'PENDING') AS pay_status
        FROM orders o
        LEFT JOIN payments p ON p.order_id = o.id
        WHERE o.buyer_user_id = ?
        ORDER BY o.created_at DESC
        ''',
        [user.id],
      );
      final orders = <Map<String, dynamic>>[];
      for (final row in results) {
        orders.add(await _orderJson(connection, row.fields));
      }
      return jsonResponse(orders);
    });
  }

  Future<Response> _detail(Request request, String id) {
    final user = authUser(request);
    return _database.withConnection((connection) async {
      final results = await connection.query(
        '''
        SELECT o.id, o.order_no, o.status, o.total_amount, o.pay_method, o.created_at,
               COALESCE(p.status, 'PENDING') AS pay_status
        FROM orders o
        LEFT JOIN payments p ON p.order_id = o.id
        WHERE o.id = ? AND o.buyer_user_id = ?
        ''',
        [int.parse(id), user.id],
      );
      if (results.isEmpty) {
        return jsonResponse({'message': 'Order not found'}, statusCode: 404);
      }
      return jsonResponse(await _orderJson(connection, results.first.fields));
    });
  }

  Future<Response> _create(Request request) async {
    final user = authUser(request);
    final body = await readJsonObject(request);
    final requestedAddressId = body['addressId'] == null
        ? null
        : int.tryParse(body['addressId'].toString());
    final payMethod = body['payMethod']?.toString() ?? 'MOCK';
    final items = (body['items'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .where((item) => (item['quantity'] as int? ?? 0) > 0)
        .toList();
    if (items.isEmpty) {
      return jsonResponse({
        'message': 'Order items are required',
      }, statusCode: 400);
    }

    return _database.transaction((connection) async {
      num total = 0;
      int? shopId;
      final lockedItems = <Map<String, dynamic>>[];
      final addressId =
          requestedAddressId ?? await _defaultAddressId(connection, user.id);
      if (addressId == null) {
        return jsonResponse({'message': '请先添加收货地址'}, statusCode: 400);
      }

      for (final item in items) {
        final productId = item['productId'] as int;
        final quantity = item['quantity'] as int;
        final products = await connection.query(
          'SELECT id, shop_id, name, price, stock FROM products WHERE id = ? AND status = "ON_SALE" AND deleted_at IS NULL FOR UPDATE',
          [productId],
        );
        if (products.isEmpty) {
          throw StateError('Product $productId is unavailable');
        }
        final product = products.first.fields;
        final stock = product['stock'] as int;
        if (stock < quantity) {
          throw StateError('商品 ${product['name']} 库存不足，当前库存 $stock');
        }
        shopId ??= product['shop_id'] as int;
        if (shopId != product['shop_id']) {
          throw StateError('课程设计版订单暂限定同一店铺商品');
        }
        final price = num.parse(product['price'].toString());
        total += price * quantity;
        lockedItems.add({
          'productId': productId,
          'productName': product['name'].toString(),
          'price': price,
          'quantity': quantity,
        });
      }

      final orderNo = newOrderNo();
      final orderResult = await connection.query(
        '''
        INSERT INTO orders(order_no, buyer_user_id, shop_id, address_id, status, total_amount, pay_method)
        VALUES (?, ?, ?, ?, "PAID", ?, ?)
        ''',
        [orderNo, user.id, shopId, addressId, total, payMethod],
      );
      final orderId = orderResult.insertId!;

      for (final item in lockedItems) {
        await connection.query(
          'UPDATE products SET stock = stock - ?, sales_count = sales_count + ? WHERE id = ?',
          [item['quantity'], item['quantity'], item['productId']],
        );
        await connection.query(
          '''
          INSERT INTO order_items(order_id, product_id, product_name, price, quantity, subtotal)
          VALUES (?, ?, ?, ?, ?, ?)
          ''',
          [
            orderId,
            item['productId'],
            item['productName'],
            item['price'],
            item['quantity'],
            item['price'] * item['quantity'],
          ],
        );
        await connection.query(
          '''
          INSERT INTO stock_logs(product_id, change_quantity, change_type, ref_type, ref_id, remark)
          VALUES (?, ?, "ORDER_LOCK", "ORDER", ?, ?)
          ''',
          [
            item['productId'],
            -(item['quantity'] as int),
            orderId,
            '下单事务扣减库存，防止超卖',
          ],
        );
      }

      await connection.query(
        'INSERT INTO payments(order_id, pay_method, amount, status, paid_at) VALUES (?, ?, ?, "SUCCESS", NOW())',
        [orderId, payMethod, total],
      );
      await connection.query(
        'DELETE ci FROM cart_items ci JOIN carts c ON c.id = ci.cart_id WHERE c.user_id = ?',
        [user.id],
      );

      return jsonResponse({
        'id': orderId,
        'orderNo': orderNo,
        'status': 'PAID',
        'payStatus': 'SUCCESS',
        'payMethod': payMethod,
        'totalAmount': total.toStringAsFixed(2),
        'items': lockedItems
            .map(
              (item) => {
                'productId': item['productId'],
                'productName': item['productName'],
                'price': item['price'].toString(),
                'quantity': item['quantity'],
                'subtotal': ((item['price'] as num) * (item['quantity'] as int))
                    .toStringAsFixed(2),
              },
            )
            .toList(),
        'createdAt': DateTime.now().toIso8601String(),
      }, statusCode: 201);
    });
  }

  Future<Response> _requestRefund(Request request, String id) async {
    final user = authUser(request);
    final body = await readJsonObject(request);
    final reason = body['reason']?.toString().trim() ?? '';
    if (reason.isEmpty) {
      return jsonResponse({
        'message': 'Refund reason is required',
      }, statusCode: 400);
    }

    return _database.transaction((connection) async {
      final orders = await connection.query(
        '''
        SELECT id, total_amount, status
        FROM orders
        WHERE id = ? AND buyer_user_id = ?
        FOR UPDATE
        ''',
        [int.parse(id), user.id],
      );
      if (orders.isEmpty) {
        return jsonResponse({'message': 'Order not found'}, statusCode: 404);
      }
      final order = orders.first.fields;
      final status = order['status']?.toString() ?? '';
      if (!{'PAID', 'SHIPPED', 'COMPLETED'}.contains(status)) {
        return jsonResponse({
          'message':
              'Only paid, shipped or completed orders can request refund',
        }, statusCode: 409);
      }
      final exists = await connection.query(
        'SELECT id FROM refunds WHERE order_id = ?',
        [int.parse(id)],
      );
      if (exists.isNotEmpty) {
        return jsonResponse({
          'message': 'Refund already requested',
        }, statusCode: 409);
      }
      final result = await connection.query(
        '''
        INSERT INTO refunds(order_id, user_id, reason, amount, status)
        VALUES (?, ?, ?, ?, "REQUESTED")
        ''',
        [int.parse(id), user.id, reason, order['total_amount']],
      );
      await connection.query(
        'UPDATE orders SET status = "REFUNDING" WHERE id = ?',
        [int.parse(id)],
      );
      return jsonResponse({
        'id': result.insertId,
        'message': 'Refund requested',
      }, statusCode: 201);
    });
  }

  Future<int?> _defaultAddressId(dynamic connection, int userId) async {
    final results = await connection.query(
      'SELECT id FROM addresses WHERE user_id = ? ORDER BY is_default DESC, id DESC LIMIT 1',
      [userId],
    );
    if (results.isEmpty) return null;
    return results.first.fields['id'] as int;
  }

  Future<Map<String, dynamic>> _orderJson(
    dynamic connection,
    Map<String, dynamic> data,
  ) async {
    final orderId = data['id'] as int;
    final items = await connection.query(
      '''
      SELECT id, product_id, product_name, price, quantity, subtotal
      FROM order_items
      WHERE order_id = ?
      ORDER BY id
      ''',
      [orderId],
    );
    final refunds = await connection.query(
      '''
      SELECT id, reason, amount, status, created_at
      FROM refunds
      WHERE order_id = ?
      ORDER BY id DESC
      LIMIT 1
      ''',
      [orderId],
    );
    return {
      'id': orderId,
      'orderNo': data['order_no'],
      'status': data['status'],
      'payMethod': data['pay_method'],
      'payStatus': data['pay_status'],
      'totalAmount': data['total_amount'].toString(),
      'createdAt': data['created_at'].toString(),
      'items': items.map((row) {
        final item = row.fields;
        return {
          'id': item['id'],
          'productId': item['product_id'],
          'productName': item['product_name'],
          'price': item['price'].toString(),
          'quantity': item['quantity'],
          'subtotal': item['subtotal'].toString(),
        };
      }).toList(),
      'refund': refunds.isEmpty
          ? null
          : {
              'id': refunds.first.fields['id'],
              'reason': refunds.first.fields['reason'],
              'amount': refunds.first.fields['amount'].toString(),
              'status': refunds.first.fields['status'],
              'createdAt': refunds.first.fields['created_at'].toString(),
            },
    };
  }
}
