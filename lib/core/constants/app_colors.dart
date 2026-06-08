import 'package:flutter/material.dart';

/// Centralized semantic color constants for financial data.
/// Use these everywhere instead of ad-hoc color values.
class AppColors {
  AppColors._();

  // --- Financial Semantics ---
  static const Color revenue = Color(0xFF10B981);    // Emerald green
  static const Color expense = Color(0xFFEF4444);    // Clear red
  static const Color profit  = Color(0xFF0D7377);    // Teal (matches primary)
  static const Color loss    = Color(0xFFEF4444);    // Same red as expense

  // --- Crop Accent Colors ---
  static const Color wheat = Color(0xFFF59E0B);      // Warm amber
  static const Color rice  = Color(0xFF14B8A6);      // Cool teal

  // --- Expense Category Colors (deterministic) ---
  static const Map<String, Color> categoryColors = {
    'Seed':       Color(0xFF8B5CF6),  // Purple
    'Fertilizer': Color(0xFF10B981),  // Green
    'Labor':      Color(0xFFF59E0B),  // Amber
    'Fuel':       Color(0xFFEF4444),  // Red
    'Pesticide':  Color(0xFF6366F1),  // Indigo
    'Water':      Color(0xFF06B6D4),  // Cyan
    'Repairs':    Color(0xFFD97706),  // Dark amber
    'Other':      Color(0xFF78716C),  // Stone
  };

  /// Returns a deterministic color for any category string.
  static Color forCategory(String category) {
    return categoryColors[category] ?? const Color(0xFF78716C);
  }

  // --- Soft backgrounds (10% opacity variants for cards/avatars) ---
  static Color revenueBg(BuildContext context) => revenue.withOpacity(0.1);
  static Color expenseBg(BuildContext context) => expense.withOpacity(0.1);
}
