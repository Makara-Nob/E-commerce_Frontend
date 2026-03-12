class CategoryModel {
  final int id;
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
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unnamed', // Use 'name' or 'categoryName'? Checking DTO... logic usually 'name' or 'categoryName'
      icon: json['icon'] as String?,
      description: json['description'] as String?,
    );
  }
}
