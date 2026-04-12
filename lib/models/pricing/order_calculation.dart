class OrderCalculation {
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double deliveryFee;
  final double discountAmount;
  final double total;

  const OrderCalculation({
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.deliveryFee,
    required this.discountAmount,
    required this.total,
  });

  factory OrderCalculation.fromJson(Map<String, dynamic> json) => OrderCalculation(
        subtotal: (json['subtotal'] ?? 0).toDouble(),
        taxRate: (json['taxRate'] ?? 0).toDouble(),
        taxAmount: (json['taxAmount'] ?? 0).toDouble(),
        deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
        discountAmount: (json['discountAmount'] ?? 0).toDouble(),
        total: (json['total'] ?? 0).toDouble(),
      );
}
