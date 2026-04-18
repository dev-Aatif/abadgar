import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryTeal = Color(0xFF0D7377);
  static const Color accentCoral = Color(0xFFFF6B6B);
  
  // Light Palette
  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color lightSurface = Colors.white;
  static const Color lightText = Color(0xFF2D3436);
  
  // Dark Palette
  static const Color darkBg = Color(0xFF0F0F1E);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkText = Color(0xFFE0E0E0);

  static ThemeData get light {
    return _base(Brightness.light);
  }

  static ThemeData get dark {
    return _base(Brightness.dark);
  }

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? darkBg : lightBg;
    final surface = isDark ? darkSurface : lightSurface;
    final text = isDark ? darkText : lightText;
    
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        primary: primaryTeal,
        secondary: accentCoral,
        surface: surface,
        onPrimary: Colors.white,
        onSurface: text,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.interTextTheme(
        TextTheme(
          headlineLarge: TextStyle(fontWeight: FontWeight.w800, color: text),
          headlineMedium: TextStyle(fontWeight: FontWeight.w700, color: text),
          titleLarge: TextStyle(fontWeight: FontWeight.w600, color: text),
          bodyLarge: TextStyle(color: text),
          bodyMedium: TextStyle(color: text.withOpacity(0.8)),
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryTeal, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primaryTeal.withOpacity(0.1),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryTeal);
          }
          return IconThemeData(color: text.withOpacity(0.5));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: primaryTeal, fontWeight: FontWeight.w600);
          }
          return TextStyle(color: text.withOpacity(0.5));
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryTeal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

extension Glassmorphism on Widget {
  Widget glass({double blur = 10, double opacity = 0.1}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
          ),
          child: this,
        ),
      ),
    );
  }
}
