import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFFE53935);
  static const primaryDark = Color(0xFFB71C1C);
  static const secondary = Color(0xFFFF6D00);
  static const accent = Color(0xFFFFD600);
  static const teal = Color(0xFF00BCD4);
  static const green = Color(0xFF66BB6A);
  static const purple = Color(0xFF7E57C2);
  static const pink = Color(0xFFEC407A);
  static const deepPurple = Color(0xFF5C6BC0);
  static const skyBlue = Color(0xFF42A5F5);

  static const surface = Color(0xFFFAFAFA);
  static const cardBg = Colors.white;
  static const divider = Color(0xFFEEEEEE);

  static const gradientWarm = [Color(0xFFE53935), Color(0xFFFF6D00)];
  static const gradientCool = [Color(0xFF5C6BC0), Color(0xFF00BCD4)];
  static const gradientGreen = [Color(0xFF66BB6A), Color(0xFF26A69A)];
  static const gradientPurple = [Color(0xFF7E57C2), Color(0xFFEC407A)];
}

class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: const Color(0xFF212121),
      error: const Color(0xFFD32F2F),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.surface,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF212121),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary);
          }
          return TextStyle(fontSize: 12, color: Colors.grey[600]);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return IconThemeData(color: Colors.grey[500], size: 24);
        }),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }
}
