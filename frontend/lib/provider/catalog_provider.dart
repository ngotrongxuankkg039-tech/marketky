import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../common/api_client.dart';
import '../model/category.dart';
import '../model/product.dart';

class CatalogProvider extends ChangeNotifier {
  CatalogProvider(this._apiClient);

  final ApiClient _apiClient;
  final List<Category> categories = [];
  final List<Product> products = [];
  bool isLoading = false;
  String keyword = '';
  int? selectedCategoryId;

  List<Product> get filteredProducts {
    return products.where((product) {
      final matchesKeyword =
          keyword.isEmpty ||
          product.name.toLowerCase().contains(keyword.toLowerCase());
      final matchesCategory =
          selectedCategoryId == null ||
          product.categoryId == selectedCategoryId;
      return matchesKeyword && matchesCategory && product.status == 'ON_SALE';
    }).toList();
  }

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    try {
      final categoryData = await _apiClient.get('/categories') as List<dynamic>;
      final productData = await _apiClient.get('/products') as List<dynamic>;
      categories
        ..clear()
        ..addAll(
          categoryData.map(
            (item) => Category.fromJson(item as Map<String, dynamic>),
          ),
        );
      products
        ..clear()
        ..addAll(
          productData.map(
            (item) => Product.fromJson(item as Map<String, dynamic>),
          ),
        );
    } catch (_) {
      _loadFallbackData();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void search(String value) {
    keyword = value.trim();
    notifyListeners();
  }

  void selectCategory(int? categoryId) {
    selectedCategoryId = categoryId;
    notifyListeners();
  }

  Future<void> toggleFavorite(Product product) async {
    final index = products.indexWhere((item) => item.id == product.id);
    if (index == -1) return;
    final next = product.copyWith(isFavorite: !product.isFavorite);
    products[index] = next;
    notifyListeners();
    try {
      if (next.isFavorite) {
        await _apiClient.post('/favorites/${product.id}');
      } else {
        await _apiClient.delete('/favorites/${product.id}');
      }
    } catch (_) {
      products[index] = product;
      notifyListeners();
    }
  }

  void _loadFallbackData() {
    categories
      ..clear()
      ..addAll(const [
        Category(id: 1, name: '数码'),
        Category(id: 2, name: '家居'),
        Category(id: 3, name: '服饰'),
        Category(id: 4, name: '食品'),
      ]);
    products
      ..clear()
      ..addAll(const [
        Product(
          id: 1,
          shopId: 1,
          categoryId: 1,
          name: '蓝牙降噪耳机',
          description: 'MarketKy 模板风格商品卡片，已替换为后端商品模型。',
          price: 299,
          stock: 32,
          imageUrl:
              'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=900',
          status: 'ON_SALE',
        ),
        Product(
          id: 2,
          shopId: 1,
          categoryId: 2,
          name: '人体工学椅',
          description: '适合寝室和书房的学习椅，库存由 MySQL 事务控制。',
          price: 699,
          stock: 16,
          imageUrl:
              'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=900',
          status: 'ON_SALE',
        ),
        Product(
          id: 3,
          shopId: 2,
          categoryId: 3,
          name: '通勤双肩包',
          description: '买家端可收藏、加入购物车并评价。',
          price: 159,
          stock: 48,
          imageUrl:
              'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=900',
          status: 'ON_SALE',
        ),
        Product(
          id: 4,
          shopId: 2,
          categoryId: 4,
          name: '精品挂耳咖啡',
          description: '示例数据用于后端未启动时展示页面结构。',
          price: 59,
          stock: 80,
          imageUrl:
              'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=900',
          status: 'ON_SALE',
        ),
      ]);
  }
}
