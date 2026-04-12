class PricingConfig {
  final double taxRate;
  final bool taxEnabled;
  final double deliveryFee;
  final bool deliveryEnabled;
  final double freeDeliveryThreshold;

  const PricingConfig({
    required this.taxRate,
    required this.taxEnabled,
    required this.deliveryFee,
    required this.deliveryEnabled,
    required this.freeDeliveryThreshold,
  });

  factory PricingConfig.fromJson(Map<String, dynamic> json) => PricingConfig(
        taxRate: (json['taxRate'] ?? 0).toDouble(),
        taxEnabled: json['taxEnabled'] ?? false,
        deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
        deliveryEnabled: json['deliveryEnabled'] ?? false,
        freeDeliveryThreshold: (json['freeDeliveryThreshold'] ?? 0).toDouble(),
      );
}
