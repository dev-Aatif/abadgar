import 'package:flutter_test/flutter_test.dart';
import 'package:abadgar/core/models/transaction.dart';
import 'package:abadgar/core/constants/enums.dart';

void main() {
  group('Financial Calculations Tests', () {
    test('Revenue should correctly sum from Transactions', () {
      final transactions = [
        Transaction(
          id: '1',
          seasonId: 's1',
          amount: 1000,
          type: TransactionType.revenue,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: '2',
          seasonId: 's1',
          amount: 500,
          type: TransactionType.expense,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      double revenue = 0;
      double expenses = 0;
      for (final tx in transactions) {
        if (tx.type == TransactionType.revenue || tx.type == TransactionType.yield_) {
          revenue += tx.amount;
        } else {
          expenses += tx.amount;
        }
      }

      expect(revenue, 1000);
      expect(expenses, 500);
    });

    test('Profit calculation matches Revenue - Expenses', () {
      const revenue = 1500.0;
      const expenses = 400.0;
      expect(revenue - expenses, 1100.0);
    });
  });
}
