import 'package:flutter_test/flutter_test.dart';
import 'package:abadgar/core/models/season.dart';
import 'package:abadgar/core/models/transaction.dart';
import 'package:abadgar/core/models/land.dart';
import 'package:abadgar/core/models/yield_log.dart';
import 'package:abadgar/core/constants/enums.dart';

void main() {
  group('Model Integrity Tests', () {
    test('Season Model SQL Mapping', () {
      final now = DateTime.now();
      final season = Season(
        id: 's1',
        name: 'Wheat 2024',
        cropType: CropType.wheat,
        landArea: 10.5,
        startDate: now,
        status: SeasonStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      final row = Season.toRow(season);
      expect(row['id'], 's1');
      expect(row['crop_type'], 'Wheat');
      expect(row['status'], 'Active');

      final fromRow = Season.fromRow(row);
      expect(fromRow.id, season.id);
      expect(fromRow.cropType, season.cropType);
      expect(fromRow.startDate.toIso8601String(), season.startDate.toIso8601String());
    });

    test('Transaction Model SQL Mapping', () {
      final now = DateTime.now();
      final tx = Transaction(
        id: 't1',
        seasonId: 's1',
        amount: 5000,
        type: TransactionType.expense,
        date: now,
        category: 'Fertilizer',
        createdAt: now,
        updatedAt: now,
      );

      final row = Transaction.toRow(tx);
      expect(row['amount'], 5000.0);
      expect(row['type'], 'Expense');

      final fromRow = Transaction.fromRow(row);
      expect(fromRow.amount, 5000.0);
      expect(fromRow.category, 'Fertilizer');
    });

    test('YieldLog Model SQL Mapping', () {
      final now = DateTime.now();
      final log = YieldLog(
        id: 'y1',
        seasonId: 's1',
        totalWeight: 40,
        unit: YieldUnit.mund,
        disposition: YieldDisposition.sold,
        salePrice: 150000,
        date: now,
        createdAt: now,
        updatedAt: now,
      );

      final row = YieldLog.toRow(log);
      expect(row['unit'], 'Mund (40kg)');
      expect(row['sale_price'], 150000.0);

      final fromRow = YieldLog.fromRow(row);
      expect(fromRow.totalWeight, 40.0);
      expect(fromRow.unit, YieldUnit.mund);
    });

    test('Land Model SQL Mapping', () {
      final now = DateTime.now();
      final land = Land(
        id: 'l1',
        name: 'North Plot',
        area: 25.0,
        createdAt: now,
        updatedAt: now,
      );

      final row = Land.toRow(land);
      expect(row['name'], 'North Plot');
      expect(row['area'], 25.0);

      final fromRow = Land.fromRow(row);
      expect(fromRow.name, 'North Plot');
      expect(fromRow.area, 25.0);
    });
  });
}
