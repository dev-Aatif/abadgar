import '../constants/enums.dart';

class AppCategories {
  static const expenses = [
    'Seed',
    'Fertilizer',
    'Labor',
    'Fuel',
    'Pesticide',
    'Other',
  ];

  static const revenue = [
    'Primary Sale',
    'Byproduct',
    'Subsidy',
  ];

  static List<String> getAllForType(String type) {
    if (type == TransactionType.expense.value) return expenses;
    if (type == TransactionType.revenue.value) return revenue;
    return [];
  }
}
