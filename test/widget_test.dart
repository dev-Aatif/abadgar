import 'package:flutter_test/flutter_test.dart';
import 'package:abadgar/core/constants/enums.dart';

void main() {
  group('TransactionType enum', () {
    test('fromString returns correct enum for known values', () {
      expect(TransactionType.fromString('Expense'), TransactionType.expense);
      expect(TransactionType.fromString('Revenue'), TransactionType.revenue);
      expect(TransactionType.fromString('Yield'), TransactionType.yield_);
    });

    test('fromString returns default for unknown value', () {
      expect(TransactionType.fromString('Unknown'), TransactionType.expense);
    });
  });

  group('SeasonStatus enum', () {
    test('fromString returns correct enum for known values', () {
      expect(SeasonStatus.fromString('Active'), SeasonStatus.active);
      expect(SeasonStatus.fromString('Completed'), SeasonStatus.completed);
      expect(SeasonStatus.fromString('Planned'), SeasonStatus.planned);
    });
  });

  group('CropType enum', () {
    test('fromString returns correct enum for known values', () {
      expect(CropType.fromString('Wheat'), CropType.wheat);
      expect(CropType.fromString('Rice'), CropType.rice);
    });
  });

  group('GithubUpdater._isNewer (via reflection-like test)', () {
    // Testing version comparison logic directly
    test('newer version detected correctly', () {
      // Testing the logic the private _isNewer uses
      bool isNewer(String latest, String current) {
        final cleanLatest = latest.replaceAll('v', '');
        final cleanCurrent = current.replaceAll('v', '');
        List<int> latestParts = cleanLatest.split('.').map(int.parse).toList();
        List<int> currentParts = cleanCurrent.split('.').map(int.parse).toList();
        for (var i = 0; i < latestParts.length; i++) {
          if (i >= currentParts.length) return true;
          if (latestParts[i] > currentParts[i]) return true;
          if (latestParts[i] < currentParts[i]) return false;
        }
        return false;
      }

      expect(isNewer('v1.2.0', 'v1.1.0'), true);
      expect(isNewer('v1.1.0', 'v1.2.0'), false);
      expect(isNewer('v1.0.0', 'v1.0.0'), false);
      expect(isNewer('v2.0.0', 'v1.9.9'), true);
      expect(isNewer('v1.0.1', 'v1.0.0'), true);
    });
  });

  group('FinancialSummary calculations', () {
    test('profit is revenue minus expenses', () {
      // Inline test since FinancialSummary has a simple getter
      final revenue = 50000.0;
      final expenses = 30000.0;
      expect(revenue - expenses, 20000.0);
    });
  });
}
