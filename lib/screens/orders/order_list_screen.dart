import 'package:e_commerce/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/gradient_background.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../auth/login_screen.dart';
import 'order_detail_screen.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        Provider.of<OrderProvider>(context, listen: false).loadOrders();
      }
    });
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return formatter.format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return AppColors.accentOrange;
      case 'PROCESSING':
        return AppColors.infoLight;
      case 'COMPLETED':
      case 'DELIVERED':
        return AppColors.successLight;
      case 'CANCELLED':
        return AppColors.errorLight;
      default:
        return Colors.grey;
    }
  }

  String _selectedStatus = 'All';
  final List<String> _statuses = [
    'All',
    'Pending',
    'Processing',
    'Completed',
    'Delivered',
    'Cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GradientBackground(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: const [
                    Icon(Icons.receipt_long, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'My Orders',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _statuses.length,
              itemBuilder: (context, index) {
                final status = _statuses[index];
                final isSelected = _selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedStatus = status);
                    },
                    selectedColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Consumer<OrderProvider>(
              builder: (context, orderProvider, child) {
                final isAuthenticated = Provider.of<AuthProvider>(context, listen: false).isAuthenticated;
                if (!isAuthenticated) {
                  return EmptyState(
                    icon: Icons.lock_outline,
                    title: 'Login Required',
                    description: 'Please login to view your order history',
                    actionLabel: 'Login',
                    onAction: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
                    },
                  );
                }

                if (orderProvider.isLoading && orderProvider.orders.isEmpty) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 5,
                    itemBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: ListItemShimmer(),
                    ),
                  );
                }

                if (orderProvider.errorMessage != null && orderProvider.orders.isEmpty) {
                  return EmptyState(
                    icon: Icons.error_outline,
                    title: 'Something went wrong',
                    description: orderProvider.errorMessage,
                    actionLabel: 'Try Again',
                    onAction: () => orderProvider.loadOrders(),
                  );
                }

                final orders = _selectedStatus == 'All'
                    ? orderProvider.orders
                    : orderProvider.orders.where((o) {
                        final status = o.status.toUpperCase();
                        final filter = _selectedStatus.toLowerCase();
                        if (filter == 'pending') return status == 'PENDING';
                        if (filter == 'processing') return status == 'CONFIRMED' || status == 'SHIPPED';
                        if (filter == 'completed' || filter == 'delivered') return status == 'DELIVERED';
                        if (filter == 'cancelled') return status == 'CANCELLED';
                        return status == filter.toUpperCase();
                      }).toList();

                if (orders.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: _selectedStatus == 'All' ? 'No past orders' : 'No $_selectedStatus orders',
                    description: _selectedStatus == 'All'
                        ? 'Your order history will appear here'
                        : 'You don\'t have any orders with status "$_selectedStatus"',
                    actionLabel: _selectedStatus == 'All' ? 'Start Shopping' : 'Show All',
                    onAction: () {
                      if (_selectedStatus == 'All') {
                        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
                      } else {
                        setState(() => _selectedStatus = 'All');
                      }
                    },
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => orderProvider.loadOrders(refresh: true),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final statusColor = _getStatusColor(order.status);

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)));
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
                            ],
                            border: Border.all(color: Colors.grey[100]!, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                      child: Icon(Icons.receipt_outlined, color: statusColor, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Order #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        Text(_formatDate(order.createdAt ?? DateTime.now()), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                      ],
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                      child: Text(
                                        order.status.toUpperCase(),
                                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    if (order.items.isNotEmpty)
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                          image: (order.items.first.product.imageUrl != null || order.items.first.product.images.isNotEmpty)
                                              ? DecorationImage(
                                                  image: NetworkImage(
                                                    order.items.first.product.images.isNotEmpty ? order.items.first.product.images.first : order.items.first.product.imageUrl!,
                                                  ),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: (order.items.first.product.imageUrl == null && order.items.first.product.images.isEmpty)
                                            ? const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 20)
                                            : null,
                                      ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${order.items.length} ${order.items.length == 1 ? 'Item' : 'Items'}', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 4),
                                          Text(order.items.map((i) => i.product.name).join(', '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black87, fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(_formatCurrency(order.totalAmount), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (order.status.toUpperCase() == 'DELIVERED')
                                      TextButton.icon(
                                        onPressed: () => _handleReorder(context, order),
                                        icon: const Icon(Icons.reorder, size: 16),
                                        label: const Text('Reorder'),
                                        style: TextButton.styleFrom(foregroundColor: AppColors.primaryStart, padding: const EdgeInsets.symmetric(horizontal: 12)),
                                      ),
                                    if (order.status.toUpperCase() == 'PENDING')
                                      TextButton.icon(
                                        onPressed: () async {
                                          final success = await Provider.of<OrderProvider>(context, listen: false).checkPaymentStatus(order.id!);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(success ? 'Payment Confirmed!' : 'Still Pending or Error'), backgroundColor: success ? Colors.green : Colors.orange),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.sync, size: 16),
                                        label: const Text('Check Payment'),
                                        style: TextButton.styleFrom(foregroundColor: AppColors.primaryStart, padding: const EdgeInsets.symmetric(horizontal: 12)),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReorder(BuildContext context, dynamic order) async {
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All items added to cart!'), backgroundColor: Colors.green));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Some items could not be added.'), backgroundColor: Colors.orange));
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error reordering: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
