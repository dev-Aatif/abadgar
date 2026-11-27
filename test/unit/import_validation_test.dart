import 'package:flutter_test/flutter_test.dart';
import 'package:abadgar/core/services/import_service.dart';

void main() {
  group('ImportService validation', () {
    test('validates and normalizes a valid v1 backup payload', () {
      const jsonStr = '''
      {
        "version": 1,
        "seasons": [
          {
            "id": "s1",
            "name": "Wheat 2024",
            "crop_type": "Wheat",
            "land_area": 10.5,
            "start_date": "2024-01-01T00:00:00Z",
            "status": "Active",
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z"
          }
        ],
        "transactions": [
          {
            "id": "t1",
            "season_id": "s1",
            "amount": 500,
            "date": "2024-01-02T00:00:00Z",
            "type": "Expense",
            "created_at": "2024-01-02T00:00:00Z",
            "updated_at": "2024-01-02T00:00:00Z"
          }
        ],
        "yield_logs": [
          {
            "id": "y1",
            "season_id": "s1",
            "total_weight": 25,
            "unit": "Mund (40kg)",
            "disposition": "Sold",
            "sale_price": 80000,
            "date": "2024-04-15T00:00:00Z",
            "created_at": "2024-04-15T00:00:00Z",
            "updated_at": "2024-04-15T00:00:00Z"
          }
        ]
      }
      ''';

      final parsed = ImportService.parseAndValidateBackup(jsonStr);
      expect(parsed.seasons.length, 1);
      expect(parsed.transactions.first['category'], 'Other');
      expect(parsed.yieldLogs.first['unit'], 'Mund (40kg)');
    });

    test('rejects unsupported version, invalid enums, and non-positive areas',
        () {
      expect(
        () => ImportService.parseAndValidateBackup(
            '{"version": 2, "seasons": [], "transactions": []}'),
        throwsException,
      );
      expect(() => ImportService.validateString('', 'ID'), throwsException);
      expect(
          () => ImportService.validatePositiveNum(0, 'Area'), throwsException);
      expect(() => ImportService.validateNonNegativeNum(-1, 'Amount'),
          throwsException);
      expect(
          () => ImportService.validateEnum(
              'Barley', {'Wheat', 'Rice'}, 'Crop Type'),
          throwsException);
      expect(() => ImportService.validateIsoDate('not-a-date', 'Date'),
          throwsException);
    });

    test(
        'rejects orphaned transactions and missing linked transaction_id in yield logs',
        () {
      const orphanTxJson = '''
      {
        "version": 1,
        "seasons": [],
        "transactions": [
          {
            "id": "t1",
            "season_id": "missing-season",
            "amount": 500,
            "date": "2024-01-02T00:00:00Z",
            "type": "Expense",
            "created_at": "2024-01-02T00:00:00Z",
            "updated_at": "2024-01-02T00:00:00Z"
          }
        ]
      }
      ''';
      expect(
        () => ImportService.parseAndValidateBackup(orphanTxJson),
        throwsException,
      );

      const missingLinkedTxJson = '''
      {
        "version": 1,
        "seasons": [
          {
            "id": "s1",
            "name": "Wheat 2024",
            "crop_type": "Wheat",
            "land_area": 5,
            "start_date": "2024-01-01T00:00:00Z",
            "status": "Active",
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z"
          }
        ],
        "transactions": [],
        "yield_logs": [
          {
            "id": "y1",
            "season_id": "s1",
            "total_weight": 10,
            "unit": "Kg",
            "disposition": "Sold",
            "transaction_id": "missing-tx",
            "date": "2024-04-01T00:00:00Z",
            "created_at": "2024-04-01T00:00:00Z",
            "updated_at": "2024-04-01T00:00:00Z"
          }
        ]
      }
      ''';
      expect(
        () => ImportService.parseAndValidateBackup(missingLinkedTxJson),
        throwsException,
      );
    });

    test('rejects non-map entries and duplicate IDs in backup arrays', () {
      const nonMapJson = '''
      {
        "version": 1,
        "seasons": ["not-a-map"],
        "transactions": []
      }
      ''';
      expect(
        () => ImportService.parseAndValidateBackup(nonMapJson),
        throwsException,
      );

      const duplicateSeasonJson = '''
      {
        "version": 1,
        "seasons": [
          {
            "id": "s1",
            "name": "Wheat 2024",
            "crop_type": "Wheat",
            "land_area": 5,
            "start_date": "2024-01-01T00:00:00Z",
            "status": "Active",
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z"
          },
          {
            "id": "s1",
            "name": "Wheat 2025",
            "crop_type": "Wheat",
            "land_area": 5,
            "start_date": "2025-01-01T00:00:00Z",
            "status": "Active",
            "created_at": "2025-01-01T00:00:00Z",
            "updated_at": "2025-01-01T00:00:00Z"
          }
        ],
        "transactions": []
      }
      ''';
      expect(
        () => ImportService.parseAndValidateBackup(duplicateSeasonJson),
        throwsException,
      );
    });
  });
}
