import 'package:e_commerce/screens/orders/aba_khqr_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/home_provider.dart';
import 'providers/address_provider.dart';
import 'providers/wishlist_provider.dart';
import 'screens/home/home_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/global_draggable_cart.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'E-commerce App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: ThemeMode.system, // Respects system theme preference
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(
              children: [
                if (child != null) child,
                const GlobalDraggableCart(),
              ],
            ),
          );
        },
        home: const AppInitializer(),
      ),
    );
  }
}


class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    // Try to auto-login if token exists
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
    
    await authProvider.tryAutoLogin();
    
    if (!mounted) return;
    
    // If logged in, load cart and wishlist
    if (authProvider.isAuthenticated) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      await Future.wait([
        cartProvider.loadCart(),
        wishlistProvider.loadWishlist(),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreen();
    // return AbaKhqrScreen(
    //   qrImage: "",
    //   qrString: "",
    //   amount: "100.00",
    //   tranId: "724",
    //   onVerify: ({bool silent = false}) async {
    //     // TODO: your verification logic here
    //   },
    // );
  }
}