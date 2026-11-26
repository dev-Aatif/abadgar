import 'package:flutter/material.dart';

/// Centralized semantic color constants for financial and crop data.
/// Use these everywhere instead of ad-hoc color values.
class AppColors {
  AppColors._();

  // --- Financial Semantics (Light / Base) ---
  static const Color revenue = Color(0xFF15803D);
  static const Color expense = Color(0xFFC83E3B);
  static const Color profit = Color(0xFF0D7377);
  static const Color loss = Color(0xFFC83E3B);

  // --- Financial Semantics (Dark high-contrast) ---
  static const Color revenueDark = Color(0xFF34D399);
  static const Color expenseDark = Color(0xFFF87171);
  static const Color profitDark = Color(0xFF2BA89F);

  // --- Crop Accent Colors ---
  static const Color wheat = Color(0xFFB45309);
  static const Color wheatDark = Color(0xFFF59E0B);
  static const Color rice = Color(0xFF0F766E);
  static const Color riceDark = Color(0xFF2DD4BF);

  // --- Expense & Revenue Category Colors (deterministic) ---
  static const Map<String, Color> categoryColors = {
    'Seed': Color(0xFF7C3AED),
    'Fertilizer': Color(0xFF15803D),
    'Labor': Color(0xFFD97706),
    'Fuel': Color(0xFFC83E3B),
    'Pesticide': Color(0xFF4F46E5),
    'Water': Color(0xFF0284C7),
    'Repairs': Color(0xFFB45309),
    'Harvest Sale': Color(0xFF15803D),
    'Wheat Sale': Color(0xFFB45309),
    'Rice Sale': Color(0xFF0F766E),
    'Subsidy': Color(0xFF0D7377),
    'Other': Color(0xFF6B7280),
  };

  /// Returns a deterministic color for any category string.
  static Color forCategory(String category) {
    return categoryColors[category] ?? const Color(0xFF6B7280);
  }

  static Color revenueFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? revenueDark : revenue;

  static Color expenseFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? expenseDark : expense;

  static Color profitFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? profitDark : profit;

  static Color wheatFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? wheatDark : wheat;

  static Color riceFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? riceDark : rice;

  // --- Soft backgrounds (10% opacity variants for semantic pills) ---
  static Color revenueBg(BuildContext context) =>
      revenueFor(context).withValues(alpha: 0.12);

  static Color expenseBg(BuildContext context) =>
      expenseFor(context).withValues(alpha: 0.12);
}
