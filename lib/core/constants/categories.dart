class AppCategories {
  static const expenses = [
    'Seed',
    'Land Prep',
    'Fertilizer',
    'Medicine/Pesticides',
    'Irrigation',
    'Labor',
    'Harvesting',
    'Transport',
    'Equipment',
    'Misc',
  ];

  static const revenue = [
    'Primary Crop Sale',
    'Byproduct Sale',
    'Subsidies',
  ];

  static List<String> getAllForType(String type) {
    if (type == 'Expense') return expenses;
    if (type == 'Revenue') return revenue;
    return [];
  }
}
