import 'package:flutter/material.dart';

const ficsitAmber = Color(0xFFBA7517);

// Status pill colors (shared across themes)
const wipBg = Color(0xFFE6F1FB);
const wipText = Color(0xFF185FA5);
const minimalBg = Color(0xFFFAEEDA);
const minimalText = Color(0xFF633806);
const optimizedBg = Color(0xFFEAF3DE);
const optimizedText = Color(0xFF27500A);

/// Theme-aware tokens. Use `AppColors.of(context).bgSecondary` etc.
class AppColors {
  final Color bgPrimary;
  final Color bgSecondary;
  final Color bgTertiary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color borderPrimary;
  final Color borderSecondary;
  final Color rowAltBg;
  final Color rowAltBorder;

  const AppColors({
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgTertiary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.borderPrimary,
    required this.borderSecondary,
    required this.rowAltBg,
    required this.rowAltBorder,
  });

  static const light = AppColors(
    bgPrimary: Color(0xFFFFFFFF),
    bgSecondary: Color(0xFFF5F5F4),
    bgTertiary: Color(0xFFFAFAF9),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF6B7280),
    textTertiary: Color(0xFF9CA3AF),
    borderPrimary: Color(0xFFD6D3D1),
    borderSecondary: Color(0xFFE7E5E4),
    rowAltBg: Color(0xFFFAFAF9),
    rowAltBorder: Color(0xFFF0EFED),
  );

  static const dark = AppColors(
    bgPrimary: Color(0xFF0F0F0F),
    bgSecondary: Color(0xFF1A1A1A),
    bgTertiary: Color(0xFF242424),
    textPrimary: Color(0xFFEDEDED),
    textSecondary: Color(0xFF9CA3AF),
    textTertiary: Color(0xFF6B7280),
    borderPrimary: Color(0xFF2E2E2E),
    borderSecondary: Color(0xFF1F1F1F),
    rowAltBg: Color(0xFF171717),
    rowAltBorder: Color(0xFF1F1F1F),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final c = isDark ? AppColors.dark : AppColors.light;

  return ThemeData(
    brightness: brightness,
    fontFamily: 'ShareTechMono',
    scaffoldBackgroundColor: c.bgPrimary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: ficsitAmber,
      primary: ficsitAmber,
      surface: c.bgPrimary,
      onSurface: c.textPrimary,
      brightness: brightness,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.bgPrimary,
      foregroundColor: c.textPrimary,
      elevation: 0,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: c.textPrimary),
      bodyMedium: TextStyle(color: c.textPrimary),
      bodySmall: TextStyle(color: c.textSecondary),
      titleLarge: TextStyle(color: c.textPrimary),
      titleMedium: TextStyle(color: c.textPrimary),
      titleSmall: TextStyle(color: c.textPrimary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.bgSecondary,
      hintStyle: TextStyle(color: c.textTertiary),
      labelStyle: TextStyle(color: c.textTertiary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c.borderSecondary, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c.borderSecondary, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: ficsitAmber, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dividerTheme: DividerThemeData(color: c.borderSecondary),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.bgPrimary,
      indicatorColor: ficsitAmber.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.all(
        TextStyle(fontSize: 11, color: c.textSecondary),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.bgPrimary,
    ),
  );
}

final appTheme = _buildTheme(Brightness.light);
final darkTheme = _buildTheme(Brightness.dark);
