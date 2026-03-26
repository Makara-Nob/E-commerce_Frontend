import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/order/order.dart';
import '../../theme/app_colors.dart';
import '../../providers/cart_provider.dart';
import '../products/product_detail_screen.dart';
import '../cart/cart_screen.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return formatter.format(amount);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return AppColors.accentOrange;
      case 'PROCESSING':
        return AppColors.infoLight;
      case 'SHIPPED':
        return AppColors.primaryEnd;
      case 'DELIVERED':
        return AppColors.successLight;
      case 'CANCELLED':
        return AppColors.errorLight;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(order.status);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Order Details'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor.withOpacity(0.1),
                    ),
                    child: Icon(
                      _getStatusIcon(order.status),
                      color: statusColor,
                      size: 32,
                    ),
                  ).animate().scale(curve: Curves.elasticOut),
                  const SizedBox(height: 16),
                  Text(
                    order.status.toUpperCase(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Order #${order.id}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (order.invoiceNumber != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Invoice: ${order.invoiceNumber}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: order.invoiceNumber!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Invoice copied to clipboard'), duration: Duration(seconds: 1)),
                            );
                          },
                          child: Icon(Icons.copy_rounded, size: 14, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(order.createdAt),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Items',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = order.items[index];
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ProductDetailScreen(product: item.product)),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  image: (item.product.imageUrl != null || item.product.images.isNotEmpty)
                                      ? DecorationImage(
                                          image: NetworkImage(
                                            item.product.images.isNotEmpty
                                                ? item.product.images.first
                                                : item.product.imageUrl!,
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: (item.product.imageUrl == null && item.product.images.isEmpty)
                                    ? const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 24)
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.quantity} x ${_formatCurrency(item.price)}',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _formatCurrency(item.subtotal),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: (100 * index).ms).slideX();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        context,
                        'Delivery',
                        Icons.local_shipping_outlined,
                        [
                          if (order.deliveryAddress != null) order.deliveryAddress!,
                          if (order.deliveryPhone != null) order.deliveryPhone!,
                          if (order.deliveryAddress == null) 'No address provided',
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        context,
                        'Payment',
                        Icons.payments_outlined,
                        [
                          order.paymentMethod?.replaceAll('_', ' ') ?? 'CASH',
                          if (order.notes != null && order.notes!.isNotEmpty) 'Note: ${order.notes}' else 'No notes',
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
                ],
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                    'Subtotal',
                    _formatCurrency(order.totalAmount + (order.discountAmount ?? 0)),
                  ),
                  if (order.discountAmount != null && order.discountAmount! > 0) ...[
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'Discount',
                      '-${_formatCurrency(order.discountAmount!)}',
                      valueColor: Colors.red[400],
                    ),
                  ],
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        _formatCurrency(order.netAmount ?? order.totalAmount),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _handleReorder(context),
                      icon: const Icon(Icons.reorder),
                      label: const Text('Reorder All Items'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ).animate().slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  Future<void> _handleReorder(BuildContext context) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      bool allSuccess = true;
      for (final item in order.items) {
        final success = await cartProvider.addToCart(item.product.id, item.quantity);
        if (!success) allSuccess = false;
      }

      if (context.mounted) {
        Navigator.pop(context);
        if (allSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All items added to cart!'), backgroundColor: Colors.green),
          );
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen()));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Some items could not be added.'), backgroundColor: Colors.orange),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error reordering: $e'), backgroundColor: Colors.red));
      }
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return Icons.hourglass_empty;
      case 'PROCESSING': return Icons.inventory_2_outlined;
      case 'SHIPPED': return Icons.local_shipping_outlined;
      case 'DELIVERED': return Icons.check_circle_outline;
      case 'CANCELLED': return Icons.cancel_outlined;
      default: return Icons.info_outline;
    }
  }

  Widget _buildInfoCard(BuildContext context, String title, IconData icon, List<String> details) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          ...details.map((detail) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(detail, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13), maxLines: 3, overflow: TextOverflow.ellipsis),
              )),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor ?? Colors.black87)),
      ],
    );
  }
}
