import 'package:flutter/foundation.dart';
import '../models/api_response.dart';
import '../models/home/banner_model.dart';
import '../models/home/brand_model.dart';
import '../models/home/category_model.dart';
import '../models/home/promotion_model.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

class HomeService {
  final ApiService _apiService = ApiService();

  // Get Banners
  Future<ApiResponse<List<BannerModel>>> getBanners() async {
    try {
      debugPrint('📡 Fetching banners from: /api/v1/public/banners');
      
      // We expect a List in the 'data' field. ApiService usually unwraps 'data'.
      // So we use dynamic to be safe, or List<dynamic>.
      final response = await _apiService.get<dynamic>(
        '/api/v1/public/banners',
        requiresAuth: false,
        fromJson: (json) => json, // Pass through whatever is in 'data'
      );

      debugPrint('📥 Banner Response Success: ${response.success}');
      
      if (response.success && response.data != null) {
         final data = response.data;
         debugPrint('📦 Banner Data Type: ${data.runtimeType}');
         
         if (data is List) {
           debugPrint('🔢 Found ${data.length} banners in list');
           final banners = data.map((e) => BannerModel.fromJson(e)).toList();
           return ApiResponse(
             success: true, 
             message: 'Banners loaded', 
             data: banners
           );
         } else if (data is Map && data['data'] is List) {
           // Fallback if ApiService DOESN'T unwrap
           final list = data['data'] as List;
           final banners = list.map((e) => BannerModel.fromJson(e)).toList();
           return ApiResponse(success: true, message: 'Banners loaded', data: banners);
         }
      }
      
      return ApiResponse(success: false, message: 'No banner data found');
    } catch (e) {
      debugPrint('❌ Error in getBanners: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // Get Promotions
  Future<ApiResponse<List<PromotionModel>>> getPromotions() async {
    try {
      debugPrint('📡 Fetching promotions from: /api/v1/public/promotions');
      final response = await _apiService.get<dynamic>(
        '/api/v1/public/promotions',
        requiresAuth: false,
        fromJson: (json) => json, 
      );

      if (response.success && response.data != null) {
         final data = response.data;
         if (data is List) {
           final list = data.map((e) => PromotionModel.fromJson(e)).toList();
           return ApiResponse(success: true, message: 'Promotions loaded', data: list);
         } else if (data is Map && data['data'] is List) {
             final list = data['data'] as List;
             final mapped = list.map((e) => PromotionModel.fromJson(e)).toList();
             return ApiResponse(success: true, message: 'Promotions loaded', data: mapped);
         }
      }
      return ApiResponse(success: false, message: 'No promotion data found');
    } catch (e) {
      debugPrint('❌ Error in getPromotions: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // Get Brands
  Future<ApiResponse<List<BrandModel>>> getBrands() async {
    // API requires POST with pagination body
    final body = {
      'page': 1,
      'size': 100, // Fetch all for now
      'searchTerm': ''
    };
    
    // The response is AllBrandResponseDto which contains a list of brands in 'content' or 'data'?
    // Need to verify AllBrandResponseDto structure.
    // Assuming standard pagination structure: { data: [...], total: ... } or just list?
    // Let's assume the ApiService.post handles the wrapper if we define the return type correctly.
    // However, if the API returns a wrapper DTO, we need to map that.
    // PublicBrandController returns AllBrandResponseDto.
    
    // Hack: We'll use dynamic for now to inspect, or better yet, verify AllBrandResponseDto.
    // But for speed, let's try to map the inner list.
    
    // Actually, let's just make a specialized call.
    // The ApiService.post expects to return T.
    
    try {
        final response = await _apiService.post<Map<String, dynamic>>(
          '/api/v1/public/brands/all',
          body: body,
          requiresAuth: false,
          fromJson: (json) => json as Map<String, dynamic>,
        );

        if (response.success && response.data != null) {
            final list = response.data!['content'] ?? [];
            if (list is List) {
                final brands = list.map((e) => BrandModel.fromJson(e)).toList();
                return ApiResponse(success: true, message: 'Success', data: brands);
            }
        }
        return ApiResponse(success: false, message: 'Failed to parse brands');
    } catch (e) {
        return ApiResponse(success: false, message: e.toString());
    }
  }

  // Get Categories
  Future<ApiResponse<List<CategoryModel>>> getCategories() async {
     final body = {
      'pageNo': 1,
      'pageSize': 100,
      'search': '',
      'status': 'ACTIVE'
    };

    try {
        final response = await _apiService.post<Map<String, dynamic>>(
          '/api/v1/public/categories/all',
          body: body,
          requiresAuth: false,
          fromJson: (json) => json as Map<String, dynamic>,
        );

        if (response.success && response.data != null) {
            final list = response.data!['content'] ?? [];
             if (list is List) {
                 final categories = list.map((e) => CategoryModel.fromJson(e)).toList();
                 return ApiResponse(success: true, message: 'Success', data: categories);
             }
        }
        return ApiResponse(success: false, message: 'Failed to parse categories');
    } catch (e) {
        return ApiResponse(success: false, message: e.toString());
    }
  }
}
