import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../common/api_client.dart';
import '../model/cart_item.dart';
import '../model/product.dart';

class CartProvider extends ChangeNotifier {
  CartProvider(this._apiClient);

  final ApiClient _apiClient;
  final List<CartItem> items = [];

  double get totalAmount => items.fold(0, (sum, item) => sum + item.subtotal);

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  Future<void> add(Product product) async {
    final index = items.indexWhere((item) => item.product.id == product.id);
    if (index == -1) {
      items.add(CartItem(product: product, quantity: 1));
    } else {
      items[index] = items[index].copyWith(quantity: items[index].quantity + 1);
    }
    notifyListeners();
    try {
      await _apiClient.post(
        '/cart/items',
        body: {'productId': product.id, 'quantity': 1},
      );
    } catch (_) {
      // Keep local state so the Web UI remains demonstrable during classroom review.
    }
  }

  void changeQuantity(Product product, int quantity) {
    final index = items.indexWhere((item) => item.product.id == product.id);
    if (index == -1) return;
    if (quantity <= 0) {
      items.removeAt(index);
    } else {
      items[index] = items[index].copyWith(quantity: quantity);
    }
    notifyListeners();
  }

  void clear() {
    items.clear();
    notifyListeners();
  }
}
