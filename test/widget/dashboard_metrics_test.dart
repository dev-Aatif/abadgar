import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:abadgar/app.dart';
import 'package:abadgar/core/constants/enums.dart';
import 'package:abadgar/core/models/season.dart';
import 'package:abadgar/core/models/transaction.dart';
import 'package:abadgar/core/providers/active_season_provider.dart';
import 'package:abadgar/core/providers/backup_providers.dart';
import 'package:abadgar/core/providers/comparison_provider.dart';
import 'package:abadgar/core/providers/financial_summary_provider.dart';
import 'package:abadgar/core/providers/seasons_provider.dart';
import 'package:abadgar/core/providers/transactions_provider.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';
import 'package:abadgar/ui/screens/dashboard/dashboard_screen.dart';

class _StubActiveSeasonId extends ActiveSeasonId {
  final String? _id;
  _StubActiveSeasonId(this._id);

  @override
  String? build() => _id;
}

class _StubBackupStatusNotifier extends BackupStatusNotifier {
  @override
  Future<BackupStatus> build() async => const BackupStatus(
        autoBackupEnabled: true,
        lastAutoBackupAt: null,
        lastExternalBackupAt: null,
      );
}

void main() {
  final now = DateTime(2026, 3, 1);
  final sampleSeason = Season(
    id: 's1',
    name: 'Wheat 2026',
    cropType: CropType.wheat,
    landArea: 12.5,
    startDate: now,
    status: SeasonStatus.active,
    createdAt: now,
    updatedAt: now,
  );

  Widget wrapDashboard({
    required Locale locale,
    required List<Override> overrides,
    double textScale = 1.0,
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('ur'), Locale('sd')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          FallbackMaterialLocalizationDelegate(),
          FallbackCupertinoLocalizationDelegate(),
          FallbackWidgetsLocalizationDelegate(),
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: const DashboardScreen(),
      ),
    );
  }

  group('DashboardScreen widget tests', () {
    testWidgets('shows loading indicator while seasonsProvider is loading',
        (tester) async {
      await tester.pumpWidget(
        wrapDashboard(
          locale: const Locale('en'),
          overrides: [
            seasonsProvider.overrideWith((ref) => const Stream.empty()),
            activeSeasonIdProvider
                .overrideWith(() => _StubActiveSeasonId(null)),
            activeSeasonProvider.overrideWith((ref) => Stream.value(null)),
            activeSeasonTransactionsProvider
                .overrideWith((ref) => Stream.value(const [])),
            activeSeasonYieldLogsProvider
                .overrideWith((ref) => Stream.value(const [])),
            financialSummaryProvider.overrideWithValue(null),
            backupStatusNotifierProvider.overrideWith(
              () => _StubBackupStatusNotifier(),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Welcome to Abadgar!'), findsNothing);
    });

    testWidgets('shows onboarding welcome state when no seasons exist',
        (tester) async {
      await tester.pumpWidget(
        wrapDashboard(
          locale: const Locale('en'),
          overrides: [
            seasonsProvider.overrideWith((ref) => Stream.value(const [])),
            activeSeasonIdProvider
                .overrideWith(() => _StubActiveSeasonId(null)),
            activeSeasonProvider.overrideWith((ref) => Stream.value(null)),
            activeSeasonTransactionsProvider
                .overrideWith((ref) => Stream.value(const [])),
            activeSeasonYieldLogsProvider
                .overrideWith((ref) => Stream.value(const [])),
            financialSummaryProvider.overrideWithValue(null),
            backupStatusNotifierProvider.overrideWith(
              () => _StubBackupStatusNotifier(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Abadgar!'), findsOneWidget);
      expect(find.text('Start New Season'), findsOneWidget);
    });

    testWidgets(
        'renders active season metrics cleanly on narrow 320dp Sindhi RTL with 1.3x scale',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final txns = [
        Transaction(
          id: 't1',
          seasonId: 's1',
          amount: 125000,
          type: TransactionType.revenue,
          category: 'Wheat Sale',
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
        Transaction(
          id: 't2',
          seasonId: 's1',
          amount: 45000,
          type: TransactionType.expense,
          category: 'Fertilizer',
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final summary = summarizeSeasonRows(txns, const []);

      await tester.pumpWidget(
        wrapDashboard(
          locale: const Locale('sd'),
          textScale: 1.3,
          overrides: [
            seasonsProvider.overrideWith((ref) => Stream.value([sampleSeason])),
            activeSeasonIdProvider
                .overrideWith(() => _StubActiveSeasonId('s1')),
            activeSeasonProvider
                .overrideWith((ref) => Stream.value(sampleSeason)),
            activeSeasonTransactionsProvider
                .overrideWith((ref) => Stream.value(txns)),
            activeSeasonYieldLogsProvider
                .overrideWith((ref) => Stream.value(const [])),
            financialSummaryProvider.overrideWithValue(summary),
            backupStatusNotifierProvider.overrideWith(
              () => _StubBackupStatusNotifier(),
            ),
            seasonComparisonProvider('s1').overrideWith(
              (ref) async => SeasonComparison(
                currentSeason: sampleSeason,
                currentSummary: summary,
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('80,000'), findsOneWidget);
    });
  });
}
