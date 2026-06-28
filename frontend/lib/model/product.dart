class Product {
  const Product({
    required this.id,
    required this.shopId,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.imageUrl,
    required this.status,
    this.isFavorite = false,
  });

  final int id;
  final int shopId;
  final int categoryId;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String imageUrl;
  final String status;
  final bool isFavorite;

  Product copyWith({bool? isFavorite, int? stock, String? status}) {
    return Product(
      id: id,
      shopId: shopId,
      categoryId: categoryId,
      name: name,
      description: description,
      price: price,
      stock: stock ?? this.stock,
      imageUrl: imageUrl,
      status: status ?? this.status,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      shopId: json['shopId'] as int? ?? json['shop_id'] as int? ?? 0,
      categoryId:
          json['categoryId'] as int? ?? json['category_id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0,
      stock: json['stock'] as int? ?? 0,
      imageUrl:
          json['imageUrl']?.toString() ?? json['image_url']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ON_SALE',
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}
