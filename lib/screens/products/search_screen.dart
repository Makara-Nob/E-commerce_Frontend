import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/product/product.dart';
import '../../providers/home_provider.dart';
import '../../services/product_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/product_card.dart';
import 'product_detail_screen.dart';
import 'all_products_screen.dart';

const _kRecentKey = 'recent_searches';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  final _productService = ProductService();

  List<String> _recentSearches = [];
  List<Product> _searchResults = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasSearched = false;
  bool _hasMore = false;
  String _currentQuery = '';
  int _currentPage = 1;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList(_kRecentKey) ?? [];
    });
  }

  Future<void> _saveRecentSearch(String query) async {
    if (_recentSearches.contains(query)) return;
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 8) _recentSearches = _recentSearches.take(8).toList();
    setState(() {});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kRecentKey, _recentSearches);
  }

  Future<void> _removeRecent(String keyword) async {
    setState(() => _recentSearches.remove(keyword));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kRecentKey, _recentSearches);
  }

  Future<void> _clearAllRecent() async {
    setState(() => _recentSearches.clear());
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRecentKey);
  }

  // ── Scroll / Pagination ────────────────────────────────────────────────────

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      if (!_isLoadingMore && _hasMore) {
        _loadMoreResults();
      }
    }
  }

  // ── Search ─────────────────────────────────────────────────────────────────

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        _performSearch(query.trim());
      } else {
        setState(() {
          _searchResults = [];
          _hasSearched = false;
          _currentQuery = '';
          _hasMore = false;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _currentQuery = query;
      _currentPage = 1;
      _searchResults = [];
      _hasMore = false;
    });

    await _saveRecentSearch(query);

    final result = await _productService.getAllProducts(
      search: query,
      page: 1,
      limit: 20,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success && result.data != null) {
        _searchResults = result.data!.products;
        _currentPage = 1;
        _hasMore = _currentPage < result.data!.totalPages;
      } else {
        _searchResults = [];
        _hasMore = false;
      }
    });
  }

  Future<void> _loadMoreResults() async {
    if (_isLoadingMore || !_hasMore || _currentQuery.isEmpty) return;
    setState(() => _isLoadingMore = true);

    final nextPage = _currentPage + 1;
    final result = await _productService.getAllProducts(
      search: _currentQuery,
      page: nextPage,
      limit: 20,
    );

    if (!mounted) return;
    setState(() {
      _isLoadingMore = false;
      if (result.success && result.data != null) {
        _searchResults.addAll(result.data!.products);
        _currentPage = nextPage;
        _hasMore = _currentPage < result.data!.totalPages;
      }
    });
  }

  void _submitSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    _focusNode.unfocus();
    _performSearch(q);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _hasSearched = false;
      _currentQuery = '';
      _hasMore = false;
    });
    _focusNode.requestFocus();
  }

  void _tapKeyword(String keyword) {
    _searchController.text = keyword;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: keyword.length),
    );
    _submitSearch(keyword);
  }

  /// Navigate to AllProductsScreen filtered by category instead of doing a text search
  void _tapCategory(String categoryId, String categoryName) {
    _focusNode.unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllProductsScreen(
          initialCategoryId: categoryId,
          title: categoryName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(21),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              style: const TextStyle(color: Colors.black87, fontSize: 15),
              cursorColor: Colors.black54,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.black45, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: _clearSearch,
                        child: const Icon(Icons.cancel_rounded, color: Colors.black38, size: 20),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
              onChanged: (v) {
                setState(() {}); // refresh suffix icon visibility
                _onSearchChanged(v);
              },
              onSubmitted: _submitSearch,
            ),
          ),
        ),
      ),
      body: _hasSearched ? _buildResults() : _buildSuggestions(isDark),
    );
  }

  // ── Suggestions (before search) ────────────────────────────────────────────
  Widget _buildSuggestions(bool isDark) {
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Consumer<HomeProvider>(
      builder: (context, homeProvider, _) {
        final categories = homeProvider.categories;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Categories as browsable chips ─────────────────────────────
              if (categories.isNotEmpty) ...[
                _SectionLabel(label: 'Browse Categories', icon: Icons.category_rounded),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.asMap().entries.map((e) {
                    final cat = e.value;
                    return _CategoryChip(
                      label: cat.name,
                      isFirst: e.key == 0,
                      onTap: () => _tapCategory(cat.id, cat.name),
                    ).animate().fadeIn(delay: (e.key * 50).ms).scale(begin: const Offset(0.85, 0.85));
                  }).toList(),
                ),
              ] else if (homeProvider.isLoading) ...[
                _SectionLabel(label: 'Browse Categories', icon: Icons.category_rounded),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    6,
                    (_) => Container(
                      width: 80,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],

              // ── Recent Searches ───────────────────────────────────────────
              if (_recentSearches.isNotEmpty) ...[
                const SizedBox(height: 28),
                Row(
                  children: [
                    _SectionLabel(label: 'Recent Searches', icon: Icons.history_rounded),
                    const Spacer(),
                    GestureDetector(
                      onTap: _clearAllRecent,
                      child: Text(
                        'Clear all',
                        style: TextStyle(
                          color: AppColors.primaryEnd,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._recentSearches.asMap().entries.map((e) {
                  return _RecentSearchTile(
                    keyword: e.value,
                    onTap: () {
                      _searchController.text = e.value;
                      _searchController.selection = TextSelection.fromPosition(
                        TextPosition(offset: e.value.length),
                      );
                      _submitSearch(e.value);
                    },
                    onDelete: () => _removeRecent(e.value),
                  ).animate().fadeIn(delay: (e.key * 40).ms).slideX(begin: -0.1);
                }),
              ],

              const SizedBox(height: 40),

              // ── Empty state ───────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF232526), Color(0xFF414345)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF232526).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.search_rounded, color: Colors.white, size: 44),
                    ).animate().scale(
                      begin: const Offset(0.7, 0.7),
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Find Your Perfect Product',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 8),
                    Text(
                      'Search by name, or browse a category above',
                      style: TextStyle(fontSize: 14, color: textSecondary),
                    ).animate().fadeIn(delay: 300.ms),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Results View ───────────────────────────────────────────────────────────
  Widget _buildResults() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primaryStart),
            SizedBox(height: 16),
            Text('Searching...', style: TextStyle(color: AppColors.textSecondaryLight)),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded, color: Colors.grey, size: 44),
            ).animate().scale(begin: const Offset(0.7, 0.7), duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 20),
            Text(
              'No results for "$_currentQuery"',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 8),
            const Text(
              'Try a different keyword or check\nthe spelling',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _clearSearch,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Clear Search'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryStart,
                side: const BorderSide(color: AppColors.primaryStart),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Result count header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${_searchResults.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    TextSpan(
                      text: _hasMore ? '+' : '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryStart,
                      ),
                    ),
                    const TextSpan(
                      text: ' results for ',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondaryLight),
                    ),
                    TextSpan(
                      text: '"$_currentQuery"',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryStart,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms),

        // Product grid with pagination
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _searchResults.length + (_isLoadingMore ? 2 : 0),
            itemBuilder: (context, index) {
              if (index >= _searchResults.length) {
                // Placeholder shimmer tiles while loading next page
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                );
              }
              final product = _searchResults[index];
              return ProductCard(
                product: product,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
                ),
              ).animate().fadeIn(delay: (index * 30).ms).scale(begin: const Offset(0.92, 0.92));
            },
          ),
        ),
      ],
    );
  }
}

// ── Section Label ──────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.primaryStart),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}

// ── Category Chip (navigates to filtered list) ─────────────────────────────────
class _CategoryChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isFirst;

  const _CategoryChip({required this.label, required this.onTap, this.isFirst = false});

  @override
  Widget build(BuildContext context) {
    if (isFirst) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryStart.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryStart.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryStart.withOpacity(0.15)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimaryLight,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Recent Search Tile ─────────────────────────────────────────────────────────
class _RecentSearchTile extends StatelessWidget {
  final String keyword;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RecentSearchTile({
    required this.keyword,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryStart.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history_rounded, size: 18, color: AppColors.primaryStart),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                keyword,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimaryLight),
              ),
            ),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondaryLight),
            ),
          ],
        ),
      ),
    );
  }
}
