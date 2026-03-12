import '../product/product.dart';

class PromotionModel {
  final int id;
  final String name;
  final String? description;
  final String discountType;
  final double discountValue;
  final DateTime startDate;
  final DateTime endDate;
  final int productId;
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
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      discountType: json['discountType'] as String,
      discountValue: (json['discountValue'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      productId: json['productId'] as int,
      productName: json['productName'] as String,
      product: Product.fromJson(json['product'] ?? {}),
    );
  }
}
