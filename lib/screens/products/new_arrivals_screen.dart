import 'package:flutter/material.dart';
import '../../services/product_service.dart';
import '../../models/product/product.dart';
import '../../models/product/product_list_response.dart';
import '../../models/api_response.dart';
import '../../widgets/product_card.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/gradient_background.dart';
import '../../theme/app_colors.dart';
import 'product_detail_screen.dart';
import '../profile/wishlist_screen.dart';

class NewArrivalsScreen extends StatefulWidget {
  const NewArrivalsScreen({super.key});

  @override
  State<NewArrivalsScreen> createState() => _NewArrivalsScreenState();
}

class _NewArrivalsScreenState extends State<NewArrivalsScreen> {
  final _scrollController = ScrollController();
  final _productService = ProductService();

  List<Product> _products = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  static const int _limit = 10;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      if (!_isLoading && _hasMore) _loadMore();
    }
  }

  Future<void> _loadMore({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _products = [];
      _page = 1;
      _hasMore = true;
    }
    if (!_hasMore) return;

    setState(() => _isLoading = true);
    try {
      final ApiResponse<ProductListResponse> res =
          await _productService.getLatestProducts(page: _page, limit: _limit);
      if (res.success && res.data != null) {
        setState(() {
          _products.addAll(res.data!.products);
          _hasMore = !res.data!.last;
          _page++;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                    const Icon(Icons.fiber_new_rounded, color: Colors.white, size: 26),
                    const SizedBox(width: 10),
                    const Text(
                      'New Arrivals',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.favorite_border, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WishlistScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _products.isEmpty && _isLoading
                ? GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: 6,
                    itemBuilder: (_, __) => const ProductCardShimmer(),
                  )
                : RefreshIndicator(
                    onRefresh: () => _loadMore(refresh: true),
                    color: AppColors.primaryStart,
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.65,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final product = _products[index];
                                return ProductCard(
                                  product: product,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailScreen(product: product),
                                    ),
                                  ),
                                );
                              },
                              childCount: _products.length,
                            ),
                          ),
                        ),
                        if (_isLoading)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          ),
                        if (!_hasMore && _products.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Text(
                                  "All ${_products.length} new arrivals loaded!",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
