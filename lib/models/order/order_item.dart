import '../product/product.dart';

class OrderItem {
  final int id;
  final Product product;
  final int quantity;
  final double price;
  final double subtotal;

  OrderItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? 0,
      product: json['product'] is Map<String, dynamic>
          ? Product.fromJson(json['product'])
          : Product(
              id: json['product'] is int ? json['product'] : (json['productId'] ?? 0),
              name: json['productName'] ?? 'Unknown Product',
              sku: json['productSku'] ?? '',
              quantity: 0,
              minStock: 0,
              costPrice: 0,
              sellingPrice: (json['unitPrice'] ?? 0).toDouble(),
              status: 'ACTIVE',
            ),
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? json['unitPrice'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
    };
  }
}
