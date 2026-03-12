import 'order_item.dart';

class Order {
  final int id;
  final int userId;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final String? deliveryAddress;
  final String? deliveryPhone;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    this.deliveryAddress,
    this.deliveryPhone,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      items: (json['items'] as List?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      deliveryAddress: json['deliveryAddress'] ?? json['shippingAddress'],
      deliveryPhone: json['deliveryPhone'],
      notes: json['notes'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'deliveryAddress': deliveryAddress,
      'deliveryPhone': deliveryPhone,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class OrderRequest {
  final String? shippingAddress;
  final String? deliveryPhone;
  final String? notes;
  final String paymentMethod;
  final List<Map<String, dynamic>> items;

  OrderRequest({
    this.shippingAddress,
    this.deliveryPhone,
    this.notes,
    this.paymentMethod = 'CASH',
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'shippingAddress': shippingAddress,
      'deliveryPhone': deliveryPhone,
      'notes': notes,
      'paymentMethod': paymentMethod,
      'items': items,
    };
  }
}

class OrderListResponse {
  final List<Order> orders;
  final int totalElements;
  final int totalPages;
  final int currentPage;
  final int pageSize;

  OrderListResponse({
    required this.orders,
    required this.totalElements,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
  });

  factory OrderListResponse.fromJson(Map<String, dynamic> json) {
    return OrderListResponse(
      orders: (json['content'] as List?)
              ?.map((item) => Order.fromJson(item))
              .toList() ??
          [],
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      currentPage: json['pageNo'] ?? 0,
      pageSize: json['pageSize'] ?? 0,
    );
  }
}
