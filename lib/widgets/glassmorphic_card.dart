import 'package:flutter/material.dart';
import 'dart:ui';

/// Glassmorphic card widget with frosted glass effect
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Border? border;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.padding,
    this.margin,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ??
            Border.all(
              color: Colors.white.withOpacity(isDark ? 0.1 : 0.2),
              width: 1.5,
            ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(opacity)
                  : Colors.white.withOpacity(opacity + 0.5),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
