import '../constants/api_constants.dart';
import '../models/api_response.dart';
import '../models/pricing/pricing_config.dart';
import '../models/pricing/order_calculation.dart';
import 'api_service.dart';

class PricingService {
  final ApiService _apiService = ApiService();

  Future<ApiResponse<PricingConfig>> getPricingConfig() {
    return _apiService.get<PricingConfig>(
      ApiConstants.pricingConfig,
      requiresAuth: false,
      fromJson: (json) => PricingConfig.fromJson(json),
    );
  }

  Future<ApiResponse<OrderCalculation>> calculateOrder({
    required List<Map<String, dynamic>> items,
    bool isBuyNow = false,
  }) {
    return _apiService.post<OrderCalculation>(
      ApiConstants.calculateOrder,
      body: {'items': items, 'isBuyNow': isBuyNow},
      requiresAuth: true,
      fromJson: (json) => OrderCalculation.fromJson(json),
    );
  }
}
