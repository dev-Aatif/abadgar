import 'package:flutter_test/flutter_test.dart';
import 'package:abadgar/core/models/transaction.dart';
import 'package:abadgar/core/constants/enums.dart';

void main() {
  group('Comprehensive Financial Logic Tests', () {
    test('Should correctly calculate totals for a variety of transactions', () {
      final now = DateTime.now();
      final transactions = [
        Transaction(
          id: '1',
          seasonId: 's1',
          amount: 10000,
          type: TransactionType.revenue,
          category: 'Harvest Sale',
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
        Transaction(
          id: '2',
          seasonId: 's1',
          amount: 2500,
          type: TransactionType.expense,
          category: 'Fertilizer',
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
        Transaction(
          id: '3',
          seasonId: 's1',
          amount: 1200,
          type: TransactionType.expense,
          category: 'Fuel',
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
        Transaction(
          id: '4',
          seasonId: 's1',
          amount: 500,
          type: TransactionType.yield_, // Treated as revenue in some logic contexts
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
        Transaction(
          id: '5',
          seasonId: 's1',
          amount: 3000.50,
          type: TransactionType.revenue,
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      double revenue = 0;
      double expenses = 0;
      final Map<String, double> catExpenses = {};

      for (final tx in transactions) {
        if (tx.type == TransactionType.revenue || tx.type == TransactionType.yield_) {
          revenue += tx.amount;
        } else {
          expenses += tx.amount;
          final cat = tx.category ?? 'Other';
          catExpenses[cat] = (catExpenses[cat] ?? 0) + tx.amount;
        }
      }

      expect(revenue, 13500.50);
      expect(expenses, 3700.0);
      expect(catExpenses['Fertilizer'], 2500.0);
      expect(catExpenses['Fuel'], 1200.0);
      expect(revenue - expenses, 9800.50);
    });

    test('Zero transaction scenario', () {
      final List<Transaction> transactions = [];
      double revenue = 0;
      double expenses = 0;

      for (final tx in transactions) {
        if (tx.type == TransactionType.revenue || tx.type == TransactionType.yield_) {
          revenue += tx.amount;
        } else {
          expenses += tx.amount;
        }
      }

      expect(revenue, 0);
      expect(expenses, 0);
    });

    test('Negative amount handling (edge case)', () {
      // Amounts should ideally be positive, but logic should handle it if passed
      final now = DateTime.now();
      final transactions = [
        Transaction(
          id: '1',
          seasonId: 's1',
          amount: -500, // Refund or correction
          type: TransactionType.expense,
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      double expenses = 0;
      for (final tx in transactions) {
        if (tx.type == TransactionType.expense) {
          expenses += tx.amount;
        }
      }

      expect(expenses, -500);
    });
  });
}
