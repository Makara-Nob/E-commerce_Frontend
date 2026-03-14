import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import '../../models/product/product.dart';
import '../../models/product/product_variant.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';
import '../../widgets/product_card.dart';
import '../../services/product_service.dart';
import '../../models/api_response.dart';
import '../../models/home/brand_model.dart';
import 'brand_detail_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final int? initialVariantId;

  const ProductDetailScreen({super.key, required this.product, this.initialVariantId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  ProductVariant? _selectedVariant;
  int _currentImageIndex = 0;
  late final PageController _pageController = PageController();
  Timer? _autoPlayTimer;

  /// Build an ordered list of images to show: put the selected variant's image first (if any),
  /// then fall back to the product's images array, then imageUrl.
  List<String> get _displayImages {
    final variantImg = _selectedVariant?.imageUrl;
    final base = widget.product.images.isNotEmpty
        ? widget.product.images
        : (widget.product.imageUrl != null ? [widget.product.imageUrl!] : <String>[]);
    if (variantImg != null && !base.contains(variantImg)) {
      return [variantImg, ...base];
    }
    return base.isNotEmpty ? base : (variantImg != null ? [variantImg] : []);
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    if (_displayImages.length <= 1) return;
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_currentImageIndex + 1) % _displayImages.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialVariantId != null) {
      try {
        _selectedVariant = widget.product.variants.firstWhere((v) => v.id == widget.initialVariantId);
      } catch (e) {
        // Variant not found, ignore
      }
    }
    // Start autoplay after first frame so _displayImages is ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoPlay());
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    if (_selectedVariant != null && _selectedVariant!.additionalPrice > 0) {
      amount += _selectedVariant!.additionalPrice;
    }
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return formatter.format(amount);
  }

  LinearGradient _getProductGradient() {
    final gradients = [
      const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)]),
      const LinearGradient(colors: [Color(0xFF4ECDC4), Color(0xFF44A3A0)]),
      const LinearGradient(colors: [Color(0xFFF7B731), Color(0xFFFA8231)]),
      const LinearGradient(colors: [Color(0xFF5F27CD), Color(0xFF341F97)]),
      const LinearGradient(colors: [Color(0xFF00D2FF), Color(0xFF3A7BD5)]),
      const LinearGradient(colors: [Color(0xFFFD79A8), Color(0xFFE84393)]),
    ];
    return gradients[widget.product.id % gradients.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Sliver App Bar with Image Carousel
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: AppColors.primaryStart,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image Carousel
                  _buildImageCarousel(),
                  // Gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Dot indicators
                  if (_displayImages.length > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _displayImages.asMap().entries.map((entry) {
                          final isActive = entry.key == _currentImageIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isActive ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Product Details
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -20, 0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Brand & Category Badges
                    Row(
                      children: [
                        if (widget.product.brand != null)
                          GestureDetector(
                            onTap: () {
                              final b = widget.product.brand!;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BrandDetailScreen(
                                    brand: BrandModel(
                                      id: b.id,
                                      name: b.name,
                                      description: b.description,
                                      logo: b.logoUrl,
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Brand logo
                                  if (widget.product.brand!.logoUrl != null) ...[
                                    ClipOval(
                                      child: Image.network(
                                        widget.product.brand!.logoUrl!,
                                        width: 18,
                                        height: 18,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.store,
                                          size: 14,
                                          color: theme.colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    widget.product.brand!.name,
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 14,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (widget.product.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.product.category!.name,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Product Name
                    Text(
                      widget.product.name,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // SKU & Stock
                    Row(
                      children: [
                        Text(
                          'SKU: ${_selectedVariant?.sku ?? widget.product.sku}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (_selectedVariant?.stockQuantity ?? widget.product.quantity) > 0 
                                ? AppColors.successLightBg 
                                : AppColors.errorLightBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: (_selectedVariant?.stockQuantity ?? widget.product.quantity) > 0 
                                  ? AppColors.successLight 
                                  : AppColors.errorLight,
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                (_selectedVariant?.stockQuantity ?? widget.product.quantity) > 0 
                                    ? Icons.check_circle 
                                    : Icons.cancel,
                                size: 14,
                                color: (_selectedVariant?.stockQuantity ?? widget.product.quantity) > 0 
                                    ? AppColors.successLight 
                                    : AppColors.errorLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (_selectedVariant?.stockQuantity ?? widget.product.quantity) > 0 
                                    ? 'In Stock (${_selectedVariant?.stockQuantity ?? widget.product.quantity})' 
                                    : 'Out of Stock',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: (_selectedVariant?.stockQuantity ?? widget.product.quantity) > 0 
                                      ? AppColors.successLight 
                                      : AppColors.errorLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatCurrency(widget.product.sellingPrice),
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.product.sellingPrice < widget.product.costPrice) ...[
                          const SizedBox(width: 12),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              _formatCurrency(widget.product.costPrice),
                              style: theme.textTheme.titleMedium?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    if (widget.product.variants.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Variants',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: widget.product.variants.map((variant) {
                          bool isSelected = _selectedVariant?.id == variant.id;
                          return ChoiceChip(
                            label: Text('${variant.variantName} ${variant.additionalPrice > 0 ? "+${variant.additionalPrice}" : ""}'),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              setState(() {
                                _selectedVariant = selected ? variant : null;
                                _currentImageIndex = 0;
                              });
                              // Jump to first image to show variant image
                              _pageController.jumpToPage(0);
                              _startAutoPlay();
                            },
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 32),
                    
                    // Description
                    Text(
                      'Description',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.product.description ?? 'No description available.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Supplier Info (Card)
                    if (widget.product.supplier != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Icon(Icons.store, color: theme.colorScheme.onPrimaryContainer),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sold by',
                                    style: theme.textTheme.labelSmall,
                                  ),
                                  Text(
                                    widget.product.supplier!.name,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Related Products
                    FutureBuilder<ApiResponse<List<Product>>>(
                      future: ProductService().getRelatedProducts(widget.product.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.success) {
                          return Center(child: Text("Error loading related products: ${snapshot.error ?? snapshot.data?.message}"));
                        }

                        final relatedProducts = snapshot.data!.data;
                        if (relatedProducts == null || relatedProducts.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: Text("No related products found")),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Related Products',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 280, // Adjust height as needed for ProductCard
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: relatedProducts.length,
                                separatorBuilder: (context, index) => const SizedBox(width: 16),
                                itemBuilder: (context, index) {
                                  return SizedBox(
                                    width: 160, // Fixed width for each card
                                    child: ProductCard(
                                      product: relatedProducts[index],
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ProductDetailScreen(
                                              product: relatedProducts[index],
                                              // initialVariantId: null, // No specific variant selected
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
                        );
                      },
                    ),

                    const SizedBox(height: 100), // Spacing for bottom bar
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: (widget.product.quantity > 0 || (widget.product.variants.isNotEmpty && widget.product.variants.any((v) => v.stockQuantity > 0)))
          ? Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Quantity Selector
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                            icon: const Icon(Icons.remove),
                            color: theme.colorScheme.primary,
                          ),
                          Text(
                            '$_quantity',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: _quantity < (_selectedVariant?.stockQuantity ?? widget.product.quantity)
                                ? () => setState(() => _quantity++)
                                : null,
                            icon: const Icon(Icons.add),
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Add to Cart Button
                    Expanded(
                      child: Consumer<CartProvider>(
                        builder: (context, cartProvider, child) {
                          return FilledButton.icon(
                            onPressed: cartProvider.isLoading
                                ? null
                                : () async {
                                    // Validation: If variants exist, one must be selected
                                    if (widget.product.variants.isNotEmpty && _selectedVariant == null) {
                                       ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please select a variant option'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                      return;
                                    }

                                    // Check if user is logged in
                                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                    if (!authProvider.isAuthenticated) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please login to add items to cart'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                                      );
                                      return;
                                    }

                                    final success = await cartProvider.addToCart(
                                      widget.product.id,
                                      _quantity,
                                      variantId: _selectedVariant?.id,
                                    );
      
                                    if (!context.mounted) return;
      
                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Added to cart'),
                                          backgroundColor: AppColors.successLight,
                                          behavior: SnackBarBehavior.floating,
                                          margin: const EdgeInsets.all(16),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            cartProvider.errorMessage ??
                                                'Failed to add to cart',
                                          ),
                                          backgroundColor: AppColors.errorLight,
                                          behavior: SnackBarBehavior.floating,
                                          margin: const EdgeInsets.all(16),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      );
                                    }
                                  },
                            icon: cartProvider.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.shopping_cart),
                            label: const Text('Add to Cart'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
  Widget _buildImageCarousel() {
    final images = _displayImages;
    if (images.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryStart, AppColors.primaryEnd],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.shopping_bag_outlined,
            size: 120,
            color: Colors.white.withOpacity(0.8),
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
        ),
      );
    }
    return PageView.builder(
      controller: _pageController,
      itemCount: images.length,
      onPageChanged: (index) => setState(() => _currentImageIndex = index),
      itemBuilder: (context, index) {
        return Image.network(
          images[index],
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryStart, AppColors.primaryEnd],
              ),
            ),
            child: Center(
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 120,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        );
      },
    );
  }
}
