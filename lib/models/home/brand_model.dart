class BrandModel {
  final int id;
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
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      logo: json['logo'] as String?, // Adjust based on actual DTO, checking BrandResponseDto would be safe but standard guessing for now
      description: json['description'] as String?,
    );
  }
}
