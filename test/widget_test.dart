import 'package:flutter_test/flutter_test.dart';
import 'package:abadgar/core/constants/enums.dart';
import 'package:abadgar/core/services/github_updater.dart';

void main() {
  group('Domain enums', () {
    test('TransactionType.fromString resolves known and unknown values', () {
      expect(TransactionType.fromString('Expense'), TransactionType.expense);
      expect(TransactionType.fromString('Revenue'), TransactionType.revenue);
      expect(TransactionType.fromString('Yield'), TransactionType.yield_);
      expect(TransactionType.fromString('Unknown'), TransactionType.expense);
    });

    test('SeasonStatus.fromString resolves known values', () {
      expect(SeasonStatus.fromString('Active'), SeasonStatus.active);
      expect(SeasonStatus.fromString('Completed'), SeasonStatus.completed);
      expect(SeasonStatus.fromString('Planned'), SeasonStatus.planned);
    });

    test('CropType.fromString resolves known values', () {
      expect(CropType.fromString('Wheat'), CropType.wheat);
      expect(CropType.fromString('Rice'), CropType.rice);
    });

    test('YieldUnit converts Kg, Mund (40kg), and Tons accurately', () {
      expect(YieldUnit.kg.toKg(100), 100.0);
      expect(YieldUnit.mund.toKg(10), 400.0);
      expect(YieldUnit.tons.toKg(2.5), 2500.0);
    });
  });

  group('GithubUpdater', () {
    test('isNewerVersion compares semantic and pre-release tags safely', () {
      expect(GithubUpdater.isNewerVersion('v1.2.0', 'v1.1.0'), isTrue);
      expect(GithubUpdater.isNewerVersion('v1.1.0', 'v1.2.0'), isFalse);
      expect(GithubUpdater.isNewerVersion('v1.0.0', 'v1.0.0'), isFalse);
      expect(GithubUpdater.isNewerVersion('v2.0.0', 'v1.9.9'), isTrue);
      expect(GithubUpdater.isNewerVersion('v1.0.1-beta.1', 'v1.0.0'), isTrue);
      expect(GithubUpdater.isNewerVersion('invalid-tag', 'v1.0.0'), isFalse);
    });

    test('isTrustedDownloadUrl enforces HTTPS and GitHub hosts', () {
      expect(
        GithubUpdater.isTrustedDownloadUrl(
          'https://github.com/archon/Abadgar/releases/download/v1.0.1/app.apk',
        ),
        isTrue,
      );
      expect(
        GithubUpdater.isTrustedDownloadUrl(
          'https://objects.githubusercontent.com/github-production-release/app.apk',
        ),
        isTrue,
      );
      expect(
        GithubUpdater.isTrustedDownloadUrl(
            'http://github.com/archon/Abadgar/app.apk'),
        isFalse,
      );
      expect(
        GithubUpdater.isTrustedDownloadUrl('https://evil.example.com/app.apk'),
        isFalse,
      );
    });
  });
}
