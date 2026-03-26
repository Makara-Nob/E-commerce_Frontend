import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  final double scale;
  final bool isLight;
  
  const BrandLogo({super.key, this.scale = 1.0, this.isLight = false});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The 'M' Box
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                margin: const EdgeInsets.only(bottom: 8, right: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: isLight ? Colors.white : Colors.black87, width: 2.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'M',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 48,
                      height: 1.1,
                      color: isLight ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_rounded,
                    color: Color(0xFFC6A664), // Delicate gold accent
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // MAKARA
          Text(
            'MAKARA',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 26,
              letterSpacing: 6,
              color: isLight ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          // - SHOP -
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 20, height: 1, color: const Color(0xFFC6A664)),
              const SizedBox(width: 8),
              const Text(
                'SHOP',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 6,
                  color: Color(0xFFC6A664),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 2), // letterSpacing compensation
              Container(width: 20, height: 1, color: const Color(0xFFC6A664)),
            ],
          ),
        ],
      ),
    );
  }
}
