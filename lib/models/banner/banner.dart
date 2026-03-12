class Banner {
  final int id;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? linkUrl;
  final int displayOrder;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Banner({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.linkUrl,
    required this.displayOrder,
    required this.active,
    this.createdAt,
    this.updatedAt,
  });

  factory Banner.fromJson(Map<String, dynamic> json) {
    return Banner(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl'],
      linkUrl: json['linkUrl'],
      displayOrder: json['displayOrder'] ?? 0,
      active: json['active'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'linkUrl': linkUrl,
      'displayOrder': displayOrder,
      'active': active,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
