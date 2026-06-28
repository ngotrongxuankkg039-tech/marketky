import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../common/api_client.dart';
import '../model/product_review.dart';

class ReviewProvider extends ChangeNotifier {
  ReviewProvider(this._apiClient);

  final ApiClient _apiClient;
  final Map<int, List<ProductReview>> _reviewsByProduct = {};
  final Set<int> _loadingProductIds = {};

  List<ProductReview> reviewsFor(int productId) {
    return _reviewsByProduct[productId] ?? const [];
  }

  bool isLoading(int productId) {
    return _loadingProductIds.contains(productId);
  }

  Future<void> loadProductReviews(int productId) async {
    _loadingProductIds.add(productId);
    notifyListeners();
    try {
      final data =
          await _apiClient.get('/reviews/products/$productId') as List<dynamic>;
      _reviewsByProduct[productId] = data
          .map((item) => ProductReview.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _reviewsByProduct[productId] = const [];
    } finally {
      _loadingProductIds.remove(productId);
      notifyListeners();
    }
  }
}
