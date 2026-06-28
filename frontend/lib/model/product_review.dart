class ProductReview {
  const ProductReview({
    required this.id,
    required this.rating,
    required this.content,
    required this.userName,
    required this.createdAt,
  });

  final int id;
  final int rating;
  final String content;
  final String userName;
  final DateTime createdAt;

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      id: json['id'] as int? ?? 0,
      rating: int.tryParse(json['rating'].toString()) ?? 0,
      content: json['content']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
