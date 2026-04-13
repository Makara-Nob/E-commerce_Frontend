import 'order_item.dart';

class Order {
  final int id;
  final int userId;
  final List<OrderItem> items;
  final double totalAmount;
  final double? taxRate;
  final double? taxAmount;
  final double? deliveryFee;
  final double? discountAmount;
  final double? netAmount;
  final String status;
  final String? statusLabel;
  final String? deliveryAddress;
  final String? deliveryPhone;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? invoiceNumber;
  final String? paymentMethod;
  
  // PayWay specific fields returned in checkout response
  final Map<String, dynamic>? paywayPayload;
  final String? paywayApiUrl;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    this.taxRate,
    this.taxAmount,
    this.deliveryFee,
    this.discountAmount,
    this.netAmount,
    required this.status,
    this.statusLabel,
    this.deliveryAddress,
    this.deliveryPhone,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.invoiceNumber,
    this.paymentMethod,
    this.paywayPayload,
    this.paywayApiUrl,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Determine if the JSON is wrapped in { "order": {...}, "paywayPayload": {...} }
    final orderJson = json.containsKey('order') ? json['order'] as Map<String, dynamic> : json;
    
    return Order(
      id: orderJson['id'] ?? orderJson['_id'] ?? 0,
      userId: orderJson['userId'] ?? 0,
      items: (orderJson['items'] as List?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      totalAmount: (orderJson['totalAmount'] ?? 0).toDouble(),
      taxRate: (orderJson['taxRate'] ?? 0).toDouble(),
      taxAmount: (orderJson['taxAmount'] ?? 0).toDouble(),
      deliveryFee: (orderJson['deliveryFee'] ?? 0).toDouble(),
      discountAmount: (orderJson['discountAmount'] ?? 0).toDouble(),
      netAmount: (orderJson['netAmount'] ?? orderJson['totalAmount'] ?? 0).toDouble(),
      status: orderJson['status'] ?? '',
      statusLabel: orderJson['statusLabel'],
      deliveryAddress: orderJson['deliveryAddress'] ?? orderJson['shippingAddress'],
      deliveryPhone: orderJson['deliveryPhone'],
      notes: orderJson['notes'],
      createdAt: orderJson['createdAt'] != null ? DateTime.parse(orderJson['createdAt']) : null,
      updatedAt: orderJson['updatedAt'] != null ? DateTime.parse(orderJson['updatedAt']) : null,
      invoiceNumber: orderJson['invoiceNumber'],
      paymentMethod: orderJson['paymentMethod'],
      paywayPayload: json['paywayPayload'] as Map<String, dynamic>?,
      paywayApiUrl: json['paywayApiUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'deliveryFee': deliveryFee,
      'discountAmount': discountAmount,
      'netAmount': netAmount,
      'status': status,
      'statusLabel': statusLabel,
      'deliveryAddress': deliveryAddress,
      'deliveryPhone': deliveryPhone,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'invoiceNumber': invoiceNumber,
      'paymentMethod': paymentMethod,
      'paywayPayload': paywayPayload,
      'paywayApiUrl': paywayApiUrl,
    };
  }
}

class OrderRequest {
  final String? shippingAddress;
  final String? deliveryPhone;
  final String? notes;
  final String paymentMethod;
  final List<Map<String, dynamic>> items;
  final bool? isBuyNow;

  OrderRequest({
    this.shippingAddress,
    this.deliveryPhone,
    this.notes,
    this.paymentMethod = 'CASH',
    required this.items,
    this.isBuyNow,
  });

  Map<String, dynamic> toJson() {
    return {
      'shippingAddress': shippingAddress,
      'deliveryPhone': deliveryPhone,
      'notes': notes,
      'paymentMethod': paymentMethod,
      'items': items,
      if (isBuyNow != null) 'isBuyNow': isBuyNow,
    };
  }
}

class OrderListResponse {
  final List<Order> content;
  final int totalElements;
  final int totalPages;
  final int pageNo;
  final int pageSize;
  final bool last;

  OrderListResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.pageNo,
    required this.pageSize,
    required this.last,
  });

  factory OrderListResponse.fromJson(Map<String, dynamic> json) {
    return OrderListResponse(
      content: (json['content'] as List?)
              ?.map((item) => Order.fromJson(item))
              .toList() ??
          [],
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      pageNo: json['pageNo'] ?? 1,
      pageSize: json['pageSize'] ?? 10,
      last: json['last'] ?? true,
    );
  }
}
