class ProductVariant {
  final int id;
  final String variantName;
  final String sku;
  final String? size;
  final String? color;
  final int stockQuantity;
  final double additionalPrice;
  final String? imageUrl;
  final String status;

  ProductVariant({
    required this.id,
    required this.variantName,
    required this.sku,
    this.size,
    this.color,
    required this.stockQuantity,
    this.additionalPrice = 0.0,
    this.imageUrl,
    required this.status,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] ?? 0,
      variantName: json['variantName'] ?? '',
      sku: json['sku'] ?? '',
      size: json['size'],
      color: json['color'],
      stockQuantity: json['stockQuantity'] ?? 0,
      additionalPrice: (json['additionalPrice'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'],
      status: json['status'] ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'variantName': variantName,
      'sku': sku,
      'size': size,
      'color': color,
      'stockQuantity': stockQuantity,
      'additionalPrice': additionalPrice,
      'imageUrl': imageUrl,
      'status': status,
    };
  }
}
