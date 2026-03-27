import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 2026 modern learning app – Duolingo / Quizlet design system
class AppColors {
  static const Color primary = Color(0xFF1F8AA6);
  static const Color primaryLight = Color(0xFFE8F4F7);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1D21);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color success = Color(0xFF10B981);
  static const Color wrong = Color(0xFFEF4444);
  static const Color accent = Color(0xFFFF7A00);

  /// Premium Dark (2026) – Derin lacivert + neon camgöbeği
  static const Color navy900 = Color(0xFF0F172A);
  static const Color navy800 = Color(0xFF1E293B);
  static const Color navy700 = Color(0xFF334155);
  static const Color cyan400 = Color(0xFF22D3EE);
  static const Color cyan300 = Color(0xFF67E8F9);
  static const Color cyanGlow = Color(0xFFA5F3FC);
  static const Color glassWhite = Color(0x14FFFFFF);
  static const Color glassBorder = Color(0x20FFFFFF);
  static const Color reviewOrange = Color(0xFFFB923C);

  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color primaryDark = Color(0xFF22D3EE);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
}

class AppTheme {
  static const double cardRadius = 28;
  static const double cardRadiusLarge = 30;
  static const double buttonRadius = 20;
  static const double buttonHeight = 56;
  static const double progressTrackRadius = 14;

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];
  static const List<BoxShadow> cardShadowStrong = [
    BoxShadow(
      color: Color(0x12000000),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        secondary: AppColors.primaryLight,
        tertiary: AppColors.accent,
        error: AppColors.wrong,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          elevation: 0,
        ),
      ),
      textTheme: _textTheme(AppColors.textPrimary, AppColors.textSecondary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  /// 2026 Premium Dark – lacivert + neon cyan, glassmorphism uyumlu
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.cyan400,
        onPrimary: AppColors.navy900,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        secondary: AppColors.navy700,
        tertiary: AppColors.cyan300,
        error: AppColors.wrong,
        outline: AppColors.glassBorder,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: AppColors.glassWhite,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cyan400,
          foregroundColor: AppColors.navy900,
          minimumSize: const Size(double.infinity, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          elevation: 0,
        ),
      ),
      textTheme: _textTheme(
        AppColors.textPrimaryDark,
        AppColors.textSecondaryDark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassWhite,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: primary,
        letterSpacing: -0.3,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.45,
        color: primary,
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        color: secondary,
      ),
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
    );
  }
}
