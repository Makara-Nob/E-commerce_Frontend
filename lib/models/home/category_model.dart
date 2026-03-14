class CategoryModel {
  final String id;
  final String name;
  final String? icon;
  final String? description;

  CategoryModel({
    required this.id,
    required this.name,
    this.icon,
    this.description,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Unnamed',
      icon: json['icon'] as String?,
      description: json['description'] as String?,
    );
  }
}
