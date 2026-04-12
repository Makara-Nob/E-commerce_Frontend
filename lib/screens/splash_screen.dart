import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import '../providers/notification_provider.dart';
import '../theme/app_colors.dart';
import 'home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _initialize();
  }

  Future<void> _initialize() async {
    await Future.wait([
      _initializeApp(),
      Future.delayed(const Duration(milliseconds: 2000)),
    ]);

    if (!mounted) return;
    _navigate();
  }

  Future<void> _initializeApp() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.tryAutoLogin();

    if (auth.isAuthenticated) {
      await Future.wait([
        Provider.of<CartProvider>(context, listen: false).loadCart(),
        Provider.of<WishlistProvider>(context, listen: false).loadWishlist(),
        Provider.of<NotificationProvider>(context, listen: false).fetchNotifications(),
      ]);
    }
  }

  void _navigate() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Image.asset(
                  'assets/images/logo/NAGA.png',
                  width: 72,
                  height: 72,
                  color: AppColors.primaryStart,
                  fit: BoxFit.contain,
                )
                    .animate()
                    .fadeIn(duration: 700.ms, curve: Curves.easeOut),

                const SizedBox(height: 24),

                // Brand name
                const Text(
                  'NAGA',
                  style: TextStyle(
                    color: AppColors.textPrimaryLight,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 10,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 600.ms, curve: Curves.easeOut),

                const SizedBox(height: 8),

                // Divider
                Container(
                  width: 32,
                  height: 1,
                  color: AppColors.gold.withOpacity(0.5),
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 500.ms),

                const SizedBox(height: 12),

                // Tagline
                const Text(
                  'PREMIUM SHOPPING',
                  style: TextStyle(
                    color: AppColors.textTertiaryLight,
                    fontSize: 10,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w400,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 600.ms, curve: Curves.easeOut),
              ],
            ),
          ),

          // Version label
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: const Text(
              'v1.0.0',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textTertiaryLight,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ).animate().fadeIn(delay: 800.ms, duration: 500.ms),
          ),
        ],
      ),
    );
  }
}
