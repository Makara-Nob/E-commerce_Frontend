import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Gradient background widget for headers and screens
class GradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const GradientBackground({
    super.key,
    required this.child,
    this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColors = [
      AppColors.primaryStart,
      AppColors.primaryEnd,
    ];
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors ?? defaultColors,
          begin: begin,
          end: end,
        ),
      ),
      child: child,
    );
  }
}
