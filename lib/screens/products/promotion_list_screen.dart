import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/home/promotion_model.dart';
import '../../providers/home_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/gradient_background.dart';
import '../../theme/app_colors.dart';
import 'product_detail_screen.dart';

class PromotionListScreen extends StatelessWidget {
  const PromotionListScreen({super.key});

  String _formatDiscount(PromotionModel promo) {
    if (promo.discountType.toUpperCase() == 'PERCENTAGE') {
      return '-${promo.discountValue.toStringAsFixed(0)}%';
    }
    return '-\$${promo.discountValue.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GradientBackground(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text('🔥', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    const Text(
                      'Special Offers',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Consumer<HomeProvider>(
              builder: (context, homeProvider, _) {
                if (homeProvider.isLoading && homeProvider.promotions.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (homeProvider.promotions.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No active promotions right now',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final promos = homeProvider.promotions;

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: promos.length,
                  itemBuilder: (context, index) {
                    final promo = promos[index];
                    return Stack(
                      children: [
                        ProductCard(
                          product: promo.product,
                          discountBadge: _formatDiscount(promo),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(product: promo.product),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
