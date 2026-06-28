class Category {
  const Category({required this.id, required this.name, this.parentId});

  final int id;
  final String name;
  final int? parentId;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      parentId: json['parentId'] as int? ?? json['parent_id'] as int?,
    );
  }
}
