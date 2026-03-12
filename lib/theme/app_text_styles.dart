import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App typography system using Google Fonts
class AppTextStyles {
  // Font family
  static String get fontFamily => GoogleFonts.inter().fontFamily ?? 'Inter';
  
  // Display styles
  static TextStyle displayLarge(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurface,
      height: 1.2,
    );
  }
  
  static TextStyle displayMedium(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurface,
      height: 1.2,
    );
  }
  
  static TextStyle displaySmall(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurface,
      height: 1.3,
    );
  }
  
  // Headline styles
  static TextStyle headlineLarge(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
      height: 1.3,
    );
  }
  
  static TextStyle headlineMedium(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
      height: 1.3,
    );
  }
  
  static TextStyle headlineSmall(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
      height: 1.4,
    );
  }
  
  // Title styles
  static TextStyle titleLarge(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
      height: 1.4,
    );
  }
  
  static TextStyle titleMedium(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.onSurface,
      height: 1.4,
    );
  }
  
  static TextStyle titleSmall(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.onSurface,
      height: 1.4,
    );
  }
  
  // Body styles
  static TextStyle bodyLarge(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: Theme.of(context).colorScheme.onSurface,
      height: 1.5,
    );
  }
  
  static TextStyle bodyMedium(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: Theme.of(context).colorScheme.onSurface,
      height: 1.5,
    );
  }
  
  static TextStyle bodySmall(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      height: 1.5,
    );
  }
  
  // Label styles
  static TextStyle labelLarge(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.onSurface,
      height: 1.4,
      letterSpacing: 0.1,
    );
  }
  
  static TextStyle labelMedium(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.onSurface,
      height: 1.4,
      letterSpacing: 0.5,
    );
  }
  
  static TextStyle labelSmall(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      height: 1.4,
      letterSpacing: 0.5,
    );
  }
}
