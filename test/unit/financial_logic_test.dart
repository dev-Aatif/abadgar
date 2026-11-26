import 'package:flutter_test/flutter_test.dart';
import 'package:abadgar/core/constants/enums.dart';
import 'package:abadgar/core/models/season.dart';
import 'package:abadgar/core/models/transaction.dart';
import 'package:abadgar/core/models/yield_log.dart';
import 'package:abadgar/core/providers/comparison_provider.dart';
import 'package:abadgar/ui/widgets/transaction_form/parts/form_shared.dart';

void main() {
  group('summarizeSeasonRows', () {
    test(
        'calculates revenue, expenses, profit, and unit-normalized yield in Kg',
        () {
      final now = DateTime(2026, 6, 1);
      final transactions = [
        Transaction(
          id: 't1',
          seasonId: 's1',
          amount: 10000,
          type: TransactionType.revenue,
          category: 'Harvest Sale',
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
        Transaction(
          id: 't2',
          seasonId: 's1',
          amount: 2500,
          type: TransactionType.expense,
          category: 'Fertilizer',
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
        Transaction(
          id: 't3',
          seasonId: 's1',
          amount: 1200,
          type: TransactionType.expense,
          category: 'Fuel',
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
        Transaction(
          id: 't4',
          seasonId: 's1',
          amount: 3000.50,
          type: TransactionType.revenue,
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final yieldLogs = [
        YieldLog(
          id: 'y1',
          seasonId: 's1',
          totalWeight: 10,
          unit: YieldUnit.mund, // 400 kg
          disposition: YieldDisposition.sold,
          salePrice: 10000,
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
        YieldLog(
          id: 'y2',
          seasonId: 's1',
          totalWeight: 1.5,
          unit: YieldUnit.tons, // 1500 kg
          disposition: YieldDisposition.stored,
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
        YieldLog(
          id: 'y3',
          seasonId: 's1',
          totalWeight: 50,
          unit: YieldUnit.kg, // 50 kg
          disposition: YieldDisposition.personal,
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final summary = summarizeSeasonRows(transactions, yieldLogs);

      expect(summary.totalRevenue, 13000.50);
      expect(summary.totalExpenses, 3700.0);
      expect(summary.profit, 9300.50);
      expect(summary.expenseByCategory['Fertilizer'], 2500.0);
      expect(summary.expenseByCategory['Fuel'], 1200.0);
      expect(summary.transactionCount, 7);
      expect(summary.totalYieldWeight, 1950.0);
    });

    test('handles empty transactions and yield logs', () {
      final summary = summarizeSeasonRows(const [], const []);
      expect(summary.totalRevenue, 0);
      expect(summary.totalExpenses, 0);
      expect(summary.profit, 0);
      expect(summary.totalYieldWeight, 0);
    });
  });

  group('SeasonComparison variance', () {
    test('handles zero previous profit and yield without division by zero', () {
      final now = DateTime(2026, 1, 1);
      final season = Season(
        id: 's2',
        name: 'Wheat 2026',
        cropType: CropType.wheat,
        landArea: 5,
        startDate: now,
        status: SeasonStatus.active,
        createdAt: now,
        updatedAt: now,
      );
      final prevSeason =
          season.copyWith(id: 's1', startDate: DateTime(2025, 1, 1));
      final emptySummary = summarizeSeasonRows(const [], const []);
      final comparison = SeasonComparison(
        currentSeason: season,
        previousSeason: prevSeason,
        currentSummary: emptySummary,
        previousSummary: emptySummary,
      );

      expect(comparison.profitVariance, 0);
      expect(comparison.yieldVariance, 0);
    });
  });

  group('NormalizedDecimalFormatter', () {
    test('converts Urdu and Arabic-Indic numerals to ASCII', () {
      expect(NormalizedDecimalFormatter.normalizeDigits('۱۲۳۴.۵۰'), '1234.50');
      expect(NormalizedDecimalFormatter.normalizeDigits('٥٠٠'), '500');
    });
  });
}
