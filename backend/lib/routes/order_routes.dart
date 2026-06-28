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
    ..post('/', _create);

  Future<Response> _list(Request request) {
    final user = authUser(request);
    return _database.withConnection((connection) async {
      final results = await connection.query(
        'SELECT id, order_no, status, total_amount, created_at FROM orders WHERE buyer_user_id = ? ORDER BY created_at DESC',
        [user.id],
      );
      return jsonResponse(
        results.map((row) {
          final data = row.fields;
          return {
            'id': data['id'],
            'orderNo': data['order_no'],
            'status': data['status'],
            'totalAmount': data['total_amount'].toString(),
            'createdAt': data['created_at'].toString(),
          };
        }).toList(),
      );
    });
  }

  Future<Response> _create(Request request) async {
    final user = authUser(request);
    final body = await readJsonObject(request);
    final addressId = body['addressId'] as int;
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
        'totalAmount': total.toStringAsFixed(2),
        'createdAt': DateTime.now().toIso8601String(),
      }, statusCode: 201);
    });
  }
}
