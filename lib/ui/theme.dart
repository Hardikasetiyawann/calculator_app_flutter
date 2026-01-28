import 'package:flutter/material.dart';

class AppTheme {
  static const Color accentGradientStart = Color(0xFFFF0080);
  static const Color accentGradientEnd = Color(0xFFFF8C00);

  static final dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1E1E22),
    colorScheme: const ColorScheme.dark(
      surface: Color(0xFF25252B),
      onSurface: Colors.white,
      primary: accentGradientStart,
      secondary: accentGradientEnd,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 64,
        fontWeight: FontWeight.w400,
        color: Colors.white,
      ),
      displayMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w300,
        color: Colors.white60,
      ),
    ),
  );

  static final light = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF2F2F7),
    colorScheme: const ColorScheme.light(
      surface: Color(0xFFFFFFFF),
      onSurface: Colors.black,
      primary: accentGradientStart,
      secondary: accentGradientEnd,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 64,
        fontWeight: FontWeight.w400,
        color: Colors.black,
      ),
      displayMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w300,
        color: Colors.black45,
      ),
    ),
  );
}
