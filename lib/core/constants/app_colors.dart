import 'package:flutter/material.dart';

/// Centralized semantic color tokens for Abadgar's Console palette.
/// Tuned for low-glare outdoor (paper) and low-strain night (graphite) use.
class AppColors {
  AppColors._();

  // --- Brand & Instrument Accents ---
  static const Color amber = Color(0xFFB45F16);
  static const Color amberDark = Color(0xFFE09846);
  static const Color instrument = Color(0xFF2F638D);
  static const Color instrumentDark = Color(0xFF6CA5D4);

  // --- Financial Semantics (Light: Console Paper) ---
  static const Color revenue = Color(0xFF26734D);
  static const Color expense = Color(0xFFB5443A);
  static const Color profit = Color(0xFF246A5B);
  static const Color loss = Color(0xFFB5443A);

  // --- Financial Semantics (Dark: Console Graphite) ---
  static const Color revenueDark = Color(0xFF5CB88A);
  static const Color expenseDark = Color(0xFFE0786E);
  static const Color profitDark = Color(0xFF52B79F);

  // --- Crop Accent Colors ---
  static const Color wheat = Color(0xFFB45F16);
  static const Color wheatDark = Color(0xFFE09846);
  static const Color rice = Color(0xFF2F638D);
  static const Color riceDark = Color(0xFF6CA5D4);

  // --- Calibrated Muted Category Palette ---
  static const Map<String, Color> categoryColors = {
    'Seed': Color(0xFF7A5394),
    'Fertilizer': Color(0xFF26734D),
    'Labor': Color(0xFFB45F16),
    'Fuel': Color(0xFFB5443A),
    'Pesticide': Color(0xFF4B5CA6),
    'Water': Color(0xFF2F638D),
    'Repairs': Color(0xFF9A5D2A),
    'Harvest Sale': Color(0xFF26734D),
    'Wheat Sale': Color(0xFFB45F16),
    'Rice Sale': Color(0xFF2F638D),
    'Subsidy': Color(0xFF246A5B),
    'Other': Color(0xFF656158),
  };

  /// Returns a deterministic muted color for any category string.
  static Color forCategory(String category) {
    return categoryColors[category] ?? const Color(0xFF656158);
  }

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color amberFor(BuildContext context) =>
      _isDark(context) ? amberDark : amber;

  static Color instrumentFor(BuildContext context) =>
      _isDark(context) ? instrumentDark : instrument;

  static Color revenueFor(BuildContext context) =>
      _isDark(context) ? revenueDark : revenue;

  static Color expenseFor(BuildContext context) =>
      _isDark(context) ? expenseDark : expense;

  static Color profitFor(BuildContext context) =>
      _isDark(context) ? profitDark : profit;

  static Color wheatFor(BuildContext context) =>
      _isDark(context) ? wheatDark : wheat;

  static Color riceFor(BuildContext context) =>
      _isDark(context) ? riceDark : rice;

  // --- Soft backgrounds for semantic pills ---
  static Color revenueBg(BuildContext context) =>
      revenueFor(context).withValues(alpha: _isDark(context) ? 0.14 : 0.10);

  static Color expenseBg(BuildContext context) =>
      expenseFor(context).withValues(alpha: _isDark(context) ? 0.14 : 0.10);

  static Color amberBg(BuildContext context) =>
      amberFor(context).withValues(alpha: _isDark(context) ? 0.15 : 0.10);

  static Color instrumentBg(BuildContext context) =>
      instrumentFor(context).withValues(alpha: _isDark(context) ? 0.15 : 0.10);
}
