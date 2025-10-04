import 'package:flutter/material.dart';

/// Centralized constants for the multilingual keyboard plugin
class KeyboardConstants {
  // Private constructor to prevent instantiation
  KeyboardConstants._();

  // Supported languages
  static const List<String> supportedLanguages = ['en', 'hi', 'mr'];
  
  // Language names
  static const Map<String, String> languageNames = {
    'en': 'English',
    'hi': 'हिंदी',
    'mr': 'मराठी',
  };

  // Primary colors
  static const Color primary = Color(0xff007AFF); // iOS-style blue
  static const Color primaryLight = Color(0xFFE0F2FF); // Light blue for single tap
  static const Color primaryVariant = Color(0xFFE0F2FF); // Very light blue

  // Key colors
  static const Color keyBackground = Colors.white;
  static const Color keyBorder = Color.fromARGB(124, 208, 208, 208);
  static const Color specialKeyBorder = Color.fromARGB(124, 208, 208, 208);
  static const Color keyText = Colors.black;
  static const Color specialKeyDefault = Color(0xFFB8B8B8); // Default gray
  
  // Splash and highlight colors
  static const Color keySplash = Colors.grey;
  static const Color keyHighlight = Colors.grey;
  static const Color specialKeySplash = Colors.grey;
  static const Color specialKeyHighlight = Colors.grey;
  
  // Splash and highlight alpha values
  static const double splashAlpha = 0.3;
  static const double highlightAlpha = 0.1;

  // Text colors
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Colors.black87;
  static const Color textOnPrimary = Colors.white; // White text on blue background
  static const Color textOnLight = Colors.black; // Black text on light background
  static const Color textGrey = Color(0xFF888888);
  static const Color textGreyDark = Colors.grey;

  // Background colors
  static const Color keyboardBackground = Color(0xFFE8E8E8); // Light keyboard background
  static const Color modalBackground = Colors.white;
  static const Color pageBackground = Color(0xFFF5F5F5); // Light blue background
  
  // Border colors
  static const Color borderLight = Color.fromARGB(124, 208, 208, 208);

  // Transparent
  static const Color transparent = Colors.transparent;

  // System colors (from Material Design)
  static const Color systemRed = Colors.redAccent;

  // Color scheme for Material 3
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: textOnPrimary,
    secondary: primaryLight,
    onSecondary: textOnLight,
    error: systemRed,
    onError: textOnPrimary,
    surface: keyboardBackground,
    onSurface: textPrimary,
  );

  // Keyboard dimensions
  static const double defaultKeyHeight = 50.0;
  static const double keySpacing = 4.0;
  static const double keyBorderRadius = 6.0;
  static const double keyElevation = 1.0;
  
  // Typography
  static const double defaultFontSize = 18.0;
  static const double smallFontSize = 14.0;
  static const double largeFontSize = 20.0;
  
  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 150);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  
  // Helper methods for colors with alpha
  static Color get keySplashWithAlpha => keySplash.withValues(alpha: splashAlpha);
  static Color get keyHighlightWithAlpha => keyHighlight.withValues(alpha: highlightAlpha);
  static Color get specialKeySplashWithAlpha => specialKeySplash.withValues(alpha: splashAlpha);
  static Color get specialKeyHighlightWithAlpha => specialKeyHighlight.withValues(alpha: highlightAlpha);
}