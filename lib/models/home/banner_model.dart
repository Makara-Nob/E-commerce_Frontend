class BannerModel {
  final int id;
  final String title;
  final String imageUrl;
  final String? linkUrl;
  final String? description;

  BannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.linkUrl,
    this.description,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      linkUrl: json['linkUrl'] as String?,
      description: json['description'] as String?,
    );
  }
}
