import 'package:flutter/material.dart';

class AppTheme {
  // Colors from JSON reference - Dark Theme Only
  static const Color background = Color(0xFF0F0F0F);
  static const Color backgroundSecondary = Color(0xFF1A1A1A);
  static const Color backgroundTertiary = Color(0xFF2A2A2A);
  static const Color backgroundElevated = Color(0xFF333333);
  
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF666666);
  
  static const Color accentPrimary = Color(0xFF007AFF);
  static const Color accentSecondary = Color(0xFF5856D6);
  static const Color accentSuccess = Color(0xFF34C759);
  static const Color accentWarning = Color(0xFFFF9500);
  static const Color accentError = Color(0xFFFF3B30);
  
  static const Color border = Color(0xFF3A3A3A);
  static const Color borderSecondary = Color(0xFF2A2A2A);

  // Spacing values
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 12.0;
  static const double spacingLg = 16.0;
  static const double spacingXl = 20.0;
  static const double spacingXxl = 24.0;

  // Border radius values
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;

  // Text styles
  static const TextStyle _baseStyle = TextStyle(
    fontFamily: 'SF Pro Text',
    fontFamilyFallback: ['-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto'],
  );

  static final TextStyle bodyText = _baseStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static final TextStyle titleText = _baseStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static final TextStyle headerText = _baseStyle.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  // Dark Theme (Single Theme)
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: accentPrimary,
      secondary: accentSecondary,
      surface: backgroundSecondary,
      error: accentError,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
      onError: Colors.white,
      outline: border,
    ),
    
    scaffoldBackgroundColor: background,
    
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundSecondary,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: headerText,
    ),
    
    cardTheme: CardThemeData(
      color: backgroundSecondary,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        side: const BorderSide(color: borderSecondary, width: 1),
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: spacingLg,
        vertical: spacingSm,
      ),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: backgroundTertiary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: borderSecondary, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: borderSecondary, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: accentPrimary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingLg,
        vertical: spacingMd,
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingXl,
          vertical: spacingMd,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
    ),
    
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: backgroundSecondary,
      indicatorColor: accentPrimary.withValues(alpha: 0.12),
    ),
    
    chipTheme: ChipThemeData(
      backgroundColor: backgroundTertiary,
      selectedColor: accentPrimary.withValues(alpha: 0.62),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
      ),
    ),
  );

  // Helper methods for easy access - simplified for dark theme only
  static Color get textColor => textPrimary;
  static Color get secondaryTextColor => textSecondary;
  static Color get backgroundColor => background;
  static Color get cardColor => backgroundSecondary;
}
