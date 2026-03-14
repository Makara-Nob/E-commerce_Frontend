import 'product_variant.dart';

class Product {
  final int id;
  final String name;
  final String sku;
  final String? description;
  final Category? category;
  final Supplier? supplier;
  final Brand? brand;
  final int quantity;
  final int minStock;
  final double costPrice;
  final double sellingPrice;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final List<ProductVariant> variants;
  final int viewCount;
  final String? imageUrl;
  final List<String> images;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    this.description,
    this.category,
    this.supplier,
    this.brand,
    required this.quantity,
    required this.minStock,
    required this.costPrice,
    required this.sellingPrice,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.variants = const [],
    this.viewCount = 0,
    this.imageUrl,
    this.images = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      sku: json['sku'] ?? '',
      description: json['description'],
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
      supplier: json['supplier'] != null ? Supplier.fromJson(json['supplier']) : null,
      brand: json['brand'] != null ? Brand.fromJson(json['brand']) : null,
      quantity: json['quantity'] ?? 0,
      minStock: json['minStock'] ?? 0,
      costPrice: (json['costPrice'] ?? 0).toDouble(),
      sellingPrice: (json['sellingPrice'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      variants: (json['variants'] as List<dynamic>?)
              ?.map((e) => ProductVariant.fromJson(e))
              .toList() ??
          [],
      viewCount: json['viewCount'] ?? 0,
      imageUrl: json['imageUrl'],
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'description': description,
      'category': category?.toJson(),
      'supplier': supplier?.toJson(),
      'brand': brand?.toJson(),
      'quantity': quantity,
      'minStock': minStock,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'imageUrl': imageUrl,
    };
  }
}

class Category {
  final String id;
  final String name;
  final String? description;

  Category({
    required this.id,
    required this.name,
    this.description,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}

class Supplier {
  final String id;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;

  Supplier({
    required this.id,
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      contactPerson: json['contactPerson'],
      phone: json['phone'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contactPerson': contactPerson,
      'phone': phone,
      'email': email,
    };
  }
}

class Brand {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;

  Brand({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      logoUrl: json['logoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
    };
  }
}
