/// Type-safe enums for domain concepts, replacing magic strings.

enum TransactionType {
  expense('Expense'),
  revenue('Revenue'),
  yield_('Yield'); // trailing underscore to avoid Dart keyword clash

  final String value;
  const TransactionType(this.value);

  static TransactionType fromString(String s) {
    return TransactionType.values.firstWhere(
      (e) => e.value == s,
      orElse: () => TransactionType.expense,
    );
  }
}

enum SeasonStatus {
  planned('Planned'),
  active('Active'),
  completed('Completed');

  final String value;
  const SeasonStatus(this.value);

  static SeasonStatus fromString(String s) {
    return SeasonStatus.values.firstWhere(
      (e) => e.value == s,
      orElse: () => SeasonStatus.planned,
    );
  }
}

enum CropType {
  wheat('Wheat'),
  rice('Rice');

  final String value;
  const CropType(this.value);

  static CropType fromString(String s) {
    return CropType.values.firstWhere(
      (e) => e.value == s,
      orElse: () => CropType.wheat,
    );
  }
}
