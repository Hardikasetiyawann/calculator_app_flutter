import 'package:flutter/material.dart';

class AppTheme {
  static const Color accentGradientStart = Color(0xFF7B2FF7); // Radiant Purple
  static const Color accentGradientEnd = Color(0xFFF107A3);   // Vivid Pink
  
  static const Color darkBg = Color(0xFF0F0F12);
  static const Color darkCard = Color(0xFF1C1C23);
  
  static const Color lightBg = Color(0xFFF8F9FE);
  static const Color lightCard = Color(0xFFFFFFFF);

  static final dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    dividerColor: Colors.white10,
    colorScheme: const ColorScheme.dark(
      surface: darkCard,
      onSurface: Colors.white,
      primary: accentGradientStart,
      secondary: accentGradientEnd,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 64,
        fontWeight: FontWeight.w300,
        color: Colors.white,
        letterSpacing: -2,
      ),
      displayMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: Colors.white54,
      ),
    ),
  );

  static final light = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBg,
    dividerColor: Colors.black12,
    colorScheme: const ColorScheme.light(
      surface: lightCard,
      onSurface: Colors.black,
      primary: accentGradientStart,
      secondary: accentGradientEnd,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 64,
        fontWeight: FontWeight.w300,
        color: Colors.black,
        letterSpacing: -2,
      ),
      displayMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: Colors.black45,
      ),
    ),
  );
}
