import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../common/api_client.dart';
import '../model/merchant_models.dart';
import '../model/product.dart';

class MerchantProvider extends ChangeNotifier {
  MerchantProvider(this._apiClient);

  final ApiClient _apiClient;

  bool isLoading = false;
  String? errorMessage;
  MerchantStats? stats;
  MerchantShop? shop;
  final List<Product> products = [];
  final List<MerchantOrder> orders = [];
  final List<MerchantRefund> refunds = [];

  Future<void> loadAll() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final statsData =
          await _apiClient.get('/merchant/stats') as Map<String, dynamic>;
      final shopData =
          await _apiClient.get('/merchant/shop') as Map<String, dynamic>;
      final productData =
          await _apiClient.get('/merchant/products') as List<dynamic>;
      final orderData =
          await _apiClient.get('/merchant/orders') as List<dynamic>;
      final refundData =
          await _apiClient.get('/merchant/refunds') as List<dynamic>;
      stats = MerchantStats.fromJson(statsData);
      shop = MerchantShop.fromJson(shopData);
      products
        ..clear()
        ..addAll(
          productData.map(
            (item) => Product.fromJson(item as Map<String, dynamic>),
          ),
        );
      orders
        ..clear()
        ..addAll(
          orderData.map(
            (item) => MerchantOrder.fromJson(item as Map<String, dynamic>),
          ),
        );
      refunds
        ..clear()
        ..addAll(
          refundData.map(
            (item) => MerchantRefund.fromJson(item as Map<String, dynamic>),
          ),
        );
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveShop({
    required String name,
    required String description,
    required String contactPhone,
  }) async {
    await _apiClient.put(
      '/merchant/shop',
      body: {
        'name': name,
        'description': description,
        'contactPhone': contactPhone,
      },
    );
    await loadAll();
  }

  Future<void> createProduct({
    required int categoryId,
    required String name,
    required String description,
    required double price,
    required int stock,
    required String imageUrl,
  }) async {
    await _apiClient.post(
      '/merchant/products',
      body: {
        'categoryId': categoryId,
        'name': name,
        'description': description,
        'price': price,
        'stock': stock,
        'imageUrl': imageUrl,
      },
    );
    await loadAll();
  }

  Future<void> updateProduct({
    required Product product,
    required int categoryId,
    required String name,
    required String description,
    required double price,
    required String imageUrl,
  }) async {
    await _apiClient.put(
      '/merchant/products/${product.id}',
      body: {
        'categoryId': categoryId,
        'name': name,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
      },
    );
    await loadAll();
  }

  Future<void> updateStock(Product product, int stock) async {
    await _apiClient.put(
      '/merchant/products/${product.id}/stock',
      body: {'stock': stock},
    );
    await loadAll();
  }

  Future<void> toggleStatus(Product product) async {
    final nextStatus = product.status == 'ON_SALE' ? 'OFF_SALE' : 'ON_SALE';
    await _apiClient.put(
      '/merchant/products/${product.id}/status',
      body: {'status': nextStatus},
    );
    await loadAll();
  }

  Future<void> shipOrder(MerchantOrder order) async {
    await _apiClient.put('/merchant/orders/${order.id}/ship');
    await loadAll();
  }

  Future<void> auditRefund(MerchantRefund refund, bool approved) async {
    await _apiClient.put(
      '/merchant/refunds/${refund.id}/audit',
      body: {'approved': approved},
    );
    await loadAll();
  }
}
