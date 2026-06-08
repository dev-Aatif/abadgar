import '../constants/enums.dart';

class AppCategories {
  static const expenses = [
    'Seed',
    'Fertilizer',
    'Labor',
    'Fuel',
    'Water',
    'Pesticide',
    'Repairs',
    'Other',
  ];

  static const revenue = [
    'Harvest Sale',
    'Subsidy',
    'Other',
  ];

  /// Returns revenue categories with the crop name injected for clarity.
  /// e.g. "Wheat Sale" instead of generic "Harvest Sale".
  static List<String> revenueForCrop(CropType? crop) {
    if (crop == null) return revenue;
    return [
      '${crop.value} Sale',
      'Subsidy',
      'Other',
    ];
  }

  static List<String> getAllForType(String type) {
    if (type == TransactionType.expense.value) return expenses;
    if (type == TransactionType.revenue.value) return revenue;
    return [];
  }
}
