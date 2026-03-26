import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/gradient_background.dart';
import 'product_detail_screen.dart';
import '../profile/wishlist_screen.dart';

class AllProductsScreen extends StatefulWidget {
  final String? title;
  final String? initialSearch;
  final String? initialCategoryId;
  final String? initialBrandId;

  const AllProductsScreen({
    super.key,
    this.title,
    this.initialSearch,
    this.initialCategoryId,
    this.initialBrandId,
  });

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  final _scrollController = ScrollController();
  late ProductProvider _productProvider;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _productProvider = Provider.of<ProductProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _productProvider.filterByCategory(widget.initialCategoryId);
      _productProvider.filterByBrand(widget.initialBrandId);
      if (widget.initialSearch != null && widget.initialSearch!.isNotEmpty) {
        _productProvider.searchProducts(widget.initialSearch!);
      } else {
        _productProvider.searchProducts('');
      }
      _productProvider.loadProducts(refresh: true);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      if (!_productProvider.isLoading && _productProvider.hasMore) {
        _productProvider.loadProducts();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'All Products'),
        flexibleSpace: const GradientBackground(child: SizedBox.expand()),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WishlistScreen()),
              );
            },
            icon: const Icon(Icons.favorite_border, color: Colors.white),
          ),
        ],
        elevation: 0,
        centerTitle: false,
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: provider.loadProducts,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.products.isEmpty) {
            return const Center(child: Text('No products available.'));
          }

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index >= provider.products.length) return null;
                    final product = provider.products[index];
                    return ProductCard(
                      product: product,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(product: product),
                        ),
                      ),
                    );
                  }, childCount: provider.products.length),
                ),
              ),
              if (provider.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
