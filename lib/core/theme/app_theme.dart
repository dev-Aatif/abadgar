import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme Colors
  static const Color lightPrimary = Color(0xFFFF1744); // Hot Pink/Red
  static const Color lightBackground = Colors.white;
  static const Color lightText = Colors.black;

  // Dark Theme Colors
  static const Color darkPrimary = Color(0xFFFFB300); // Soft Amber
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkText = Colors.white;

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: lightPrimary,
        primary: lightPrimary,
        background: lightBackground,
        onBackground: lightText,
      ),
      scaffoldBackgroundColor: lightBackground,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: lightText),
        headlineMedium: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: lightText),
        bodyLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: lightText),
        bodyMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: lightText),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: lightPrimary,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: const OutlineInputBorder(
          borderSide: BorderSide(width: 2.0, color: lightPrimary),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(width: 2.0, color: Colors.black),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(width: 2.0, color: lightPrimary),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
      ),
      // Enforce 56x56 touch targets where possible
      visualDensity: VisualDensity.comfortable,
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkPrimary,
        primary: darkPrimary,
        background: darkBackground,
        onBackground: darkText,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: darkBackground,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: darkText),
        headlineMedium: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: darkText),
        bodyLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: darkText),
        bodyMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkText),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: darkPrimary,
        foregroundColor: Colors.black,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white10,
        border: const OutlineInputBorder(
          borderSide: BorderSide(width: 2.0, color: darkPrimary),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(width: 2.0, color: Colors.white),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(width: 2.0, color: darkPrimary),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      visualDensity: VisualDensity.comfortable,
    );
  }
}
