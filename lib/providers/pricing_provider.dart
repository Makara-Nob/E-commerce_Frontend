import 'package:flutter/foundation.dart';
import '../models/pricing/pricing_config.dart';
import '../models/pricing/order_calculation.dart';
import '../services/pricing_service.dart';

class PricingProvider with ChangeNotifier {
  final PricingService _service = PricingService();

  PricingConfig? _config;
  OrderCalculation? _calculation;
  bool _isLoading = false;
  String? _errorMessage;

  PricingConfig? get config => _config;
  OrderCalculation? get calculation => _calculation;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadConfig() async {
    try {
      final response = await _service.getPricingConfig();
      if (response.success && response.data != null) {
        _config = response.data;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> calculate({
    required List<Map<String, dynamic>> items,
    bool isBuyNow = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.calculateOrder(items: items, isBuyNow: isBuyNow);
      if (response.success && response.data != null) {
        _calculation = response.data;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = 'Failed to calculate pricing';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCalculation() {
    _calculation = null;
    _errorMessage = null;
    notifyListeners();
  }
}
