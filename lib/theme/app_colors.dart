import 'package:flutter/material.dart';

/// App color palette with vibrant, modern colors
class AppColors {
  // Primary gradient colors
  static const primaryStart = Color(0xFF6366F1); // Indigo
  static const primaryEnd = Color(0xFF8B5CF6); // Purple
  
  // Accent colors
  static const accentPink = Color(0xFFEC4899);
  static const accentOrange = Color(0xFFF59E0B);
  static const accentGreen = Color(0xFF10B981);
  static const accentBlue = Color(0xFF3B82F6);
  
  // Semantic colors (Light mode)
  static const successLight = Color(0xFF10B981);
  static const successLightBg = Color(0xFFD1FAE5);
  static const errorLight = Color(0xFFEF4444);
  static const errorLightBg = Color(0xFFFEE2E2);
  static const warningLight = Color(0xFFF59E0B);
  static const warningLightBg = Color(0xFFFEF3C7);
  static const infoLight = Color(0xFF3B82F6);
  static const infoLightBg = Color(0xFFDBEAFE);
  
  // Background colors (Light mode)
  static const backgroundLight = Color(0xFFFAFAFA);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const cardLight = Color(0xFFFFFFFF);
  
  // Text colors (Light mode)
  static const textPrimaryLight = Color(0xFF111827);
  static const textSecondaryLight = Color(0xFF6B7280);
  static const textTertiaryLight = Color(0xFF9CA3AF);
  
  // Dark mode colors
  static const backgroundDark = Color(0xFF0F172A);
  static const surfaceDark = Color(0xFF1E293B);
  static const cardDark = Color(0xFF334155);
  
  // Text colors (Dark mode)
  static const textPrimaryDark = Color(0xFFF8FAFC);
  static const textSecondaryDark = Color(0xFFCBD5E1);
  static const textTertiaryDark = Color(0xFF94A3B8);
  
  // Semantic colors (Dark mode)
  static const successDark = Color(0xFF34D399);
  static const successDarkBg = Color(0xFF064E3B);
  static const errorDark = Color(0xFFF87171);
  static const errorDarkBg = Color(0xFF7F1D1D);
  static const warningDark = Color(0xFFFBBF24);
  static const warningDarkBg = Color(0xFF78350F);
  static const infoDark = Color(0xFF60A5FA);
  static const infoDarkBg = Color(0xFF1E3A8A);
  
  // Gradient definitions
  static const primaryGradient = LinearGradient(
    colors: [primaryStart, primaryEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const accentGradient = LinearGradient(
    colors: [accentPink, accentOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Glassmorphism overlay
  static Color glassOverlay(bool isDark) => 
      isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.7);
}
