import 'package:flutter/material.dart';
import '../models/api_response.dart';
import '../models/home/banner_model.dart';
import '../models/home/brand_model.dart';
import '../models/home/category_model.dart';
import '../models/home/promotion_model.dart';
import '../services/home_service.dart';

class HomeProvider with ChangeNotifier {
  final HomeService _homeService = HomeService();

  List<BannerModel> _banners = [];
  List<BrandModel> _brands = [];
  List<CategoryModel> _categories = [];
  
  bool _isLoading = false;
  String? _errorMessage;

  List<BannerModel> get banners => _banners;
  List<PromotionModel> _promotions = [];
  List<PromotionModel> get promotions => _promotions;
  List<BrandModel> get brands => _brands;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchHomeData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch all concurrently
      final results = await Future.wait([
        _homeService.getBanners(),
        _homeService.getBrands(),
        _homeService.getCategories(),
        _homeService.getPromotions(),
      ]);

      final bannerResponse = results[0] as ApiResponse<List<BannerModel>>;
      if (bannerResponse.success && bannerResponse.data != null) {
        _banners = bannerResponse.data!;
        debugPrint('✅ Banners loaded: ${_banners.length}');
      } else {
        debugPrint('❌ Failed to load banners: ${bannerResponse.message}');
      }

      final brandResponse = results[1] as ApiResponse<List<BrandModel>>;
      if (brandResponse.success && brandResponse.data != null) {
        _brands = brandResponse.data!;
         debugPrint('✅ Brands loaded: ${_brands.length}');
      } else {
         debugPrint('❌ Failed to load brands: ${brandResponse.message}');
      }

      final categoryResponse = results[2] as ApiResponse<List<CategoryModel>>;
      if (categoryResponse.success && categoryResponse.data != null) {
        _categories = categoryResponse.data!;
        debugPrint('✅ Categories loaded: ${_categories.length}');
      } else {
        debugPrint('❌ Failed to load categories: ${categoryResponse.message}');
      }

      final promotionResponse = results[3] as ApiResponse<List<PromotionModel>>;
      if (promotionResponse.success && promotionResponse.data != null) {
        _promotions = promotionResponse.data!;
        debugPrint('✅ Promotions loaded: ${_promotions.length}');
      } else {
        debugPrint('❌ Failed to load promotions: ${promotionResponse.message}');
      }

    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error fetching home data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
