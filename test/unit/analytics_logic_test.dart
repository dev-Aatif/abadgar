import 'package:flutter_test/flutter_test.dart';
import 'package:abadgar/core/models/transaction.dart';
import 'package:abadgar/core/constants/enums.dart';

void main() {
  group('Analytics Logic Tests', () {
    test('Should correctly group expenses by category and year', () {
      final year2023 = DateTime(2023, 5, 20);
      final year2024 = DateTime(2024, 6, 15);
      
      final transactions = [
        Transaction(
          id: '1',
          seasonId: 's1',
          amount: 1000,
          type: TransactionType.expense,
          category: 'Seeds',
          date: year2023,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: '2',
          seasonId: 's1',
          amount: 2000,
          type: TransactionType.expense,
          category: 'Seeds',
          date: year2024,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: '3',
          seasonId: 's1',
          amount: 1500,
          type: TransactionType.expense,
          category: 'Fuel',
          date: year2023,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Logic from analytics_provider.dart
      final Map<String, Map<int, double>> groupings = {};

      for (final tx in transactions) {
        if (tx.category == null) continue;
        final year = tx.date.year;
        final cat = tx.category!;
        
        groupings.putIfAbsent(cat, () => {});
        groupings[cat]![year] = (groupings[cat]![year] ?? 0) + tx.amount;
      }

      expect(groupings['Seeds']![2023], 1000.0);
      expect(groupings['Seeds']![2024], 2000.0);
      expect(groupings['Fuel']![2023], 1500.0);
      expect(groupings['Fuel']?.containsKey(2024) ?? false, false);
    });
  });
}
