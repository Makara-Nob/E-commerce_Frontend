import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_colors.dart';
import '../products/product_list_screen.dart';
import '../cart/cart_screen.dart';
import '../orders/order_list_screen.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ProductListScreen(),
    const CartScreen(),
    const OrderListScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        Provider.of<ProductProvider>(context, listen: false).loadProducts();
      } catch (e) {
        debugPrint('Error loading products: $e');
      }
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          final cartItemCount = cartProvider.cart?.items.length ?? 0;
          
          return Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              onTap: _onTabTapped,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.store_outlined),
                  activeIcon: Icon(Icons.store),
                  label: 'Products',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    label: cartItemCount > 0 ? Text('$cartItemCount') : null,
                    isLabelVisible: cartItemCount > 0,
                    child: const Icon(Icons.shopping_cart_outlined),
                  ),
                  activeIcon: Badge(
                    label: cartItemCount > 0 ? Text('$cartItemCount') : null,
                    isLabelVisible: cartItemCount > 0,
                    child: const Icon(Icons.shopping_cart),
                  ),
                  label: 'Cart',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_outlined),
                  activeIcon: Icon(Icons.receipt_long),
                  label: 'Orders',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

