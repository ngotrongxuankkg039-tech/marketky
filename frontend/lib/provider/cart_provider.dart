import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../common/api_client.dart';
import '../model/cart_item.dart';
import '../model/product.dart';

class CartProvider extends ChangeNotifier {
  CartProvider(this._apiClient);

  final ApiClient _apiClient;
  final List<CartItem> items = [];
  bool isLoading = false;

  double get totalAmount => items.fold(0, (sum, item) => sum + item.subtotal);

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    try {
      final data = await _apiClient.get('/cart/') as List<dynamic>;
      items
        ..clear()
        ..addAll(
          data.map((item) => CartItem.fromJson(item as Map<String, dynamic>)),
        );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> add(Product product) async {
    final previousItems = List<CartItem>.of(items);
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
      items
        ..clear()
        ..addAll(previousItems);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> changeQuantity(Product product, int quantity) async {
    final previousItems = List<CartItem>.of(items);
    final index = items.indexWhere((item) => item.product.id == product.id);
    if (index == -1) return;
    if (quantity <= 0) {
      items.removeAt(index);
    } else {
      items[index] = items[index].copyWith(quantity: quantity);
    }
    notifyListeners();
    try {
      if (quantity <= 0) {
        await _apiClient.delete('/cart/items/${product.id}');
      } else {
        await _apiClient.put(
          '/cart/items/${product.id}',
          body: {'quantity': quantity},
        );
      }
      notifyListeners();
    } catch (_) {
      items
        ..clear()
        ..addAll(previousItems);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> clear() async {
    clearLocal();
    try {
      await _apiClient.delete('/cart/items');
    } catch (_) {
      // Local state is already cleared after a successful checkout.
    }
  }

  void clearLocal() {
    items.clear();
    notifyListeners();
  }
}
