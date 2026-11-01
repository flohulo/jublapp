import 'package:flutter/material.dart';

/// Farben und Masse der PWA (assets/css/main.css) 1:1 übernommen.
class AppColors {
  AppColors._();

  static const primary = Color(0xFFA62429);
  static const bgOuter = Color(0xFFE0E0E0);
  static const bgInner = Color(0xFFF0F0F0);
  static const textDark = Color(0xFF333333);
  static const label = Color(0xFF4A1012);
  static const emergency = Color(0xFFE53935);
  static const error = Color(0xFFB00020);
  static const success = Color(0xFF2D8F3C);
  static const muted = Color(0xFF666666);
  static const divider = Color(0xFFEEEEEE);
}

class AppTheme {
  AppTheme._();

  /// Maximale Breite der "Handy-Spalte" auf grossen Bildschirmen.
  static const double maxContentWidth = 400;

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bgOuter,
      textTheme: Typography.blackMountainView.apply(
        bodyColor: AppColors.textDark,
        displayColor: AppColors.textDark,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titleTextStyle: const TextStyle(
          color: AppColors.primary,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
