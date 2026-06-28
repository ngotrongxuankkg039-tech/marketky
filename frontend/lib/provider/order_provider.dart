import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../common/api_client.dart';
import '../model/cart_item.dart';
import '../model/order.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider(this._apiClient);

  final ApiClient _apiClient;
  final List<ShopOrder> orders = [];
  bool isLoading = false;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    try {
      final data = await _apiClient.get('/orders') as List<dynamic>;
      orders
        ..clear()
        ..addAll(
          data.map((item) => ShopOrder.fromJson(item as Map<String, dynamic>)),
        );
    } catch (_) {
      orders.clear();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<ShopOrder> createOrder({
    required List<CartItem> items,
    required int addressId,
    required String payMethod,
  }) async {
    final payload = {
      'addressId': addressId,
      'payMethod': payMethod,
      'items': [
        for (final item in items)
          {'productId': item.product.id, 'quantity': item.quantity},
      ],
    };
    final data =
        await _apiClient.post('/orders', body: payload) as Map<String, dynamic>;
    final order = ShopOrder.fromJson(data);
    orders.insert(0, order);
    notifyListeners();
    return order;
  }
}
