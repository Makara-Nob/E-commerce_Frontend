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
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.accentOrange;
      case 'processing':
        return AppColors.infoLight;
      case 'completed':
      case 'delivered':
        return AppColors.successLight;
      case 'cancelled':
        return AppColors.errorLight;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Gradient App Bar
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
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: Consumer<OrderProvider>(
              builder: (context, orderProvider, child) {
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

                // Guest User State
                final isAuthenticated = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).isAuthenticated;
                if (!isAuthenticated) {
                  return EmptyState(
                    icon: Icons.lock_outline,
                    title: 'Login Required',
                    description: 'Please login to view your order history',
                    actionLabel: 'Login',
                    onAction: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                  );
                }

                if (orderProvider.errorMessage != null &&
                    orderProvider.orders.isEmpty) {
                  return EmptyState(
                    icon: Icons.error_outline,
                    title: 'Something went wrong',
                    description: orderProvider.errorMessage,
                    actionLabel: 'Try Again',
                    onAction: () => orderProvider.loadOrders(),
                  );
                }

                if (orderProvider.orders.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No past orders',
                    description: 'Your order history will appear here',
                    actionLabel: 'Start Shopping',
                    onAction: () {
                      // Navigate to products (Home Screen)
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const HomeScreen(),
                        ), // Defaults to index 0 (Products)
                        (route) => false,
                      );
                    },
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => orderProvider.loadOrders(refresh: true),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: orderProvider.orders.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final order = orderProvider.orders[index];
                      final statusColor = _getStatusColor(order.status);

                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.local_shipping_outlined,
                                color: statusColor,
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  '#${order.id}',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: statusColor.withOpacity(0.5),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    order.status.toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatDate(
                                      order.createdAt ?? DateTime.now(),
                                    ),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatCurrency(order.totalAmount),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_drop_down,
                            ), // Explicit trailing to avoid confusion
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withOpacity(0.3),
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.grey.withOpacity(0.1),
                                    ),
                                  ),
                                ),
                                padding: const EdgeInsets.all(16),
                                width: double.infinity,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDetailRow(
                                      context,
                                      'Delivery Address',
                                      order.deliveryAddress ?? 'N/A',
                                    ),
                                    const SizedBox(height: 12),
                                    _buildDetailRow(
                                      context,
                                      'Contact',
                                      order.deliveryPhone ?? 'N/A',
                                    ),
                                    if (order.notes != null &&
                                        order.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      _buildDetailRow(
                                        context,
                                        'Notes',
                                        order.notes!,
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (order.status.toUpperCase() ==
                                            'PENDING')
                                          TextButton.icon(
                                            onPressed: () async {
                                              final success =
                                                  await Provider.of<
                                                        OrderProvider
                                                      >(context, listen: false)
                                                      .checkPaymentStatus(
                                                        order.id!,
                                                      );
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      success
                                                          ? 'Payment Confirmed!'
                                                          : 'Still Pending or Error',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            icon: const Icon(Icons.sync),
                                            label: const Text('Check Payment'),
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  AppColors.primaryStart,
                                            ),
                                          ),
                                        TextButton.icon(
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    OrderDetailScreen(
                                                      order: order,
                                                    ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.info_outline),
                                          label: const Text(
                                            'View Full Details',
                                          ),
                                        ),
                                      ],
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

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
