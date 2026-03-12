import 'product.dart';

class ProductListResponse {
  final List<Product> products;
  final int totalElements;
  final int totalPages;
  final int currentPage;
  final int pageSize;
  final bool last;

  ProductListResponse({
    required this.products,
    required this.totalElements,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
    this.last = false,
  });

  factory ProductListResponse.fromJson(Map<String, dynamic> json) {
    return ProductListResponse(
      products: (json['content'] as List?)
              ?.map((item) => Product.fromJson(item))
              .toList() ??
          [],
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      currentPage: json['pageNo'] ?? 0,
      pageSize: json['pageSize'] ?? 0,
      last: json['last'] ?? false,
    );
  }
}

class GetAllProductRequest {
  final int pageNo;
  final int pageSize;
  final String? search;
  // Backend DTO only supports search and status, removing explicit category/brand/sort for now
  // final int? categoryId;
  // final int? brandId;
  // final String? sortBy;
  // final String? sortDirection;

  GetAllProductRequest({
    this.pageNo = 1,
    this.pageSize = 10,
    this.search,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'pageNo': pageNo,
      'pageSize': pageSize,
    };
    
    if (search != null && search!.isNotEmpty) data['search'] = search;
    
    return data;
  }
}
