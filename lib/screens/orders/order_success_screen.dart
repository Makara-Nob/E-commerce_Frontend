import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon with ripple effect
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.successLight.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 80,
                  color: AppColors.successLight,
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              
              const SizedBox(height: 32),
              
              Text(
                'Order Placed!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 16),
              
              Text(
                'Thank you for your purchase.\nYour order has been received and is being processed.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    // Pop until we reach the home screen (which is at the root)
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Continue Shopping', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                ),
              ).animate().fadeIn(delay: 700.ms).scale(),
            ],
          ),
        ),
      ),
    );
  }
}
