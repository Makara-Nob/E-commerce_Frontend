class BrandModel {
  final String id;
  final String name;
  final String? logo;
  final String? description;

  BrandModel({
    required this.id,
    required this.name,
    this.logo,
    this.description,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      logo: json['logoUrl'] as String?,
      description: json['description'] as String?,
    );
  }
}
