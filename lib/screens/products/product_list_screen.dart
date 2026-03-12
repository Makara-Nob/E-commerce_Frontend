import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/home_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gradient_background.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Fetch Home Data (Banners, Categories, Brands)
    WidgetsBinding.instance.addPostFrameCallback((_) {
       Provider.of<HomeProvider>(context, listen: false).fetchHomeData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      if (!provider.isLoading && provider.hasMore) {
        provider.loadProducts();
      }
    }
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
    Provider.of<ProductProvider>(context, listen: false).searchProducts('');
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Consumer2<HomeProvider, ProductProvider>(
          builder: (context, homeProvider, productProvider, _) {
            // Local state for price inputs could be here, but for simplicity we rely on provider state or just clear/set.
            // Since we need to capture input, we'll use controllers initialized with provider values.
            // But doing that inside a builder that rebuilds might reset them. 
            // Ideally this modal should be a separate StatefulWidget.
            // For now, let's keep it simple: Filter by Category is main goal.
            
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                         productProvider.clearFilters();
                         Navigator.pop(context);
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const Divider(),
                
                // Sort By
                const Text('Sort By', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSortChip(productProvider, 'Latest', null), // Default
                    _buildSortChip(productProvider, 'Most Viewed', 'popular'),
                    _buildSortChip(productProvider, 'Price: Low to High', 'price_asc'),
                    _buildSortChip(productProvider, 'Price: High to Low', 'price_desc'),
                  ],
                ),
                const Divider(),
                
                // Categories
                const Text('Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: homeProvider.categories.map((category) {
                    final isSelected = productProvider.selectedCategoryId == category.id;
                    return FilterChip(
                      label: Text(category.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        productProvider.filterByCategory(selected ? category.id : null);
                      },
                      selectedColor: Colors.blue.withOpacity(0.2),
                      checkmarkColor: Colors.blue,
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 30),
                
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSortChip(ProductProvider provider, String label, String? value) {
    final isSelected = provider.sortBy == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        provider.sortProducts(selected ? value : null);
      },
      selectedColor: Colors.blue.withOpacity(0.2),
      checkmarkColor: Colors.blue,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Gradient App Bar with Search
          GradientBackground(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // App Bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        if (!_isSearching) ...[
                          const Icon(
                            Icons.store,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Products',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _startSearch,
                            icon: const Icon(Icons.search, color: Colors.white),
                          ),
                          IconButton(
                            onPressed: _showFilterModal,
                            icon: const Icon(Icons.filter_list, color: Colors.white),
                          ),
                        ] else ...[
                          Expanded(
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                style: const TextStyle(color: Colors.black87),
                                decoration: const InputDecoration(
                                  hintText: 'Search products...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey,
                                  ),
                                  border: InputBorder.none,
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.grey,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                                ),
                                onSubmitted: (value) {
                                  Provider.of<ProductProvider>(context, listen: false)
                                      .searchProducts(value);
                                },
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _stopSearch,
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          // Product Grid
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.products.isEmpty && productProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                // Show empty state if no products and not loading
                if (productProvider.products.isEmpty && !productProvider.isLoading) {
                  return EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: productProvider.errorMessage ?? 'No products found',
                    description: 'Try adjusting your filters',
                    actionLabel: 'Clear Filters',
                    onAction: () {
                      productProvider.clearFilters();
                    },
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await Future.wait([
                       productProvider.loadProducts(refresh: true),
                       Provider.of<HomeProvider>(context, listen: false).fetchHomeData(),
                    ]);
                  },
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                       // Banners
                       SliverToBoxAdapter(
                         child: Consumer<HomeProvider>(
                           builder: (context, homeProvider, _) {
                             // DEBUG: Check banner count
                             debugPrint('🔴 Banners Count: ${homeProvider.banners.length}');
                             if (homeProvider.banners.isEmpty) {
                                return const SizedBox(height: 50, child: Center(child: Text('No Banners'))); // Temporary visual cue
                             }
                             return SizedBox(
                               height: 180,
                               child: PageView.builder(
                                 itemCount: homeProvider.banners.length,
                                 itemBuilder: (context, index) {
                                   final banner = homeProvider.banners[index];
                                   return Container(
                                     margin: const EdgeInsets.all(16),
                                     child: ClipRRect(
                                       borderRadius: BorderRadius.circular(16),
                                       child: Image.network(
                                         banner.imageUrl,
                                         fit: BoxFit.cover,
                                         errorBuilder: (context, error, stackTrace) {
                                           return Container(
                                             color: Colors.grey[300],
                                             child: const Center(
                                               child: Column(
                                                 mainAxisAlignment: MainAxisAlignment.center,
                                                 children: [
                                                   Icon(Icons.broken_image, color: Colors.grey),
                                                   SizedBox(height: 4),
                                                   Text('Image not found', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                                 ],
                                               ),
                                             ),
                                           );
                                         },
                                       ),
                                     ),
                                   );
                                 },
                               ),
                             );
                           },
                         ),
                       ),

                       // Categories
                       SliverToBoxAdapter(
                         child: Consumer<HomeProvider>(
                           builder: (context, homeProvider, _) {
                              if (homeProvider.promotions.isEmpty) return const SizedBox.shrink();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                                    child: Text('Special Offers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ),
                                  SizedBox(
                                    height: 240, // Increased height for ProductCard
                                    child: ListView.separated(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      scrollDirection: Axis.horizontal,
                                      itemCount: homeProvider.promotions.length,
                                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                                      itemBuilder: (context, index) {
                                         final promo = homeProvider.promotions[index];
                                         // Reuse ProductCard
                                         return SizedBox(
                                           width: 160, // Fixed width for horizontal card
                                           child: ProductCard(
                                             product: promo.product,
                                             onTap: () {
                                                Navigator.push(
                                                  context, 
                                                  MaterialPageRoute(
                                                    builder: (_) => ProductDetailScreen(product: promo.product)
                                                  )
                                                );
                                             },
                                           ),
                                         );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              );
                           },
                         ),
                       ),

                       // Categories
                       SliverToBoxAdapter(
                         child: Consumer<HomeProvider>(
                           builder: (context, homeProvider, _) {
                             if (homeProvider.categories.isEmpty) return const SizedBox.shrink();
                             return SizedBox(
                               height: 150, // INCREASED HEIGHT (Aggressive fix)
                               child: ListView.separated(
                                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                 scrollDirection: Axis.horizontal,
                                 itemCount: homeProvider.categories.length,
                                 separatorBuilder: (_, __) => const SizedBox(width: 16),
                                 itemBuilder: (context, index) {
                                   final category = homeProvider.categories[index];
                                   final isSelected = productProvider.selectedCategoryId == category.id;
                                   return GestureDetector(
                                     onTap: () => productProvider.filterByCategory(isSelected ? null : category.id),
                                     child: Column(
                                       mainAxisSize: MainAxisSize.min,
                                       children: [
                                         Container(
                                           width: 70, // Increased width (was 60)
                                           height: 70, // Increased height (was 60)
                                           decoration: BoxDecoration(
                                             color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey[100],
                                             shape: BoxShape.circle,
                                             border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
                                              image: category.icon != null 
                                              ? DecorationImage(image: NetworkImage(category.icon!), fit: BoxFit.cover) 
                                              : null,
                                           ),
                                           child: category.icon == null 
                                            ? Icon(Icons.category_outlined, color: isSelected ? Colors.blue : Colors.grey[600]) 
                                            : null,
                                         ),
                                         const SizedBox(height: 8),
                                         SizedBox(
                                           width: 80, // Increased width constraint (was 70)
                                           child: Text(
                                             category.name, 
                                             textAlign: TextAlign.center,
                                             style: TextStyle(
                                               fontSize: 12, 
                                               fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                               color: isSelected ? Colors.blue : Colors.black
                                             ),
                                             maxLines: 2,
                                             overflow: TextOverflow.ellipsis,
                                           ),
                                         ),
                                       ],
                                     ),
                                   );
                                 },
                               ),
                             );
                           },
                         ),
                       ),

                       // Product Grid Title
                       const SliverToBoxAdapter(
                         child: Padding(
                           padding: EdgeInsets.all(16.0),
                           child: Text('Popular Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                         ),
                       ),

                       // Product Grid
                       SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.65, // Taller cards to prevent overflow
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index >= productProvider.products.length) return null;
                                final product = productProvider.products[index];
                                return ProductCard(
                                  product: product,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
                                );
                              },
                              childCount: productProvider.products.length,
                            ),
                          ),
                       ),
                       
                       // Loader
                       const SliverToBoxAdapter(child: SizedBox(height: 80)), // Bottom padding
                     ],
                   ),
                 );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
      // Kept for structure but unused since we inlined header in build to avoid issues with replace
      return const SizedBox.shrink(); 
  }
}
