import '../product/product.dart';

class PromotionModel {
  final String id;
  final String name;
  final String? description;
  final String discountType;
  final double discountValue;
  final DateTime startDate;
  final DateTime endDate;
  final String productId;
  final String productName;
  final Product product;

  PromotionModel({
    required this.id,
    required this.name,
    this.description,
    required this.discountType,
    required this.discountValue,
    required this.startDate,
    required this.endDate,
    required this.productId,
    required this.productName,
    required this.product,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      discountType: json['discountType'] as String? ?? '',
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0.0,
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : DateTime.now(),
      productId: json['productId']?.toString() ?? '',
      productName: json['productName'] as String? ?? '',
      product: Product.fromJson(json['product'] ?? {}),
    );
  }
}
