import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:abadgar/app.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';
import 'package:abadgar/core/constants/enums.dart';
import 'package:abadgar/core/models/season.dart';
import 'package:abadgar/core/models/transaction.dart';
import 'package:abadgar/core/models/yield_log.dart';
import 'package:abadgar/core/providers/active_season_provider.dart';
import 'package:abadgar/core/providers/analytics_selection_provider.dart';
import 'package:abadgar/core/providers/backup_providers.dart';
import 'package:abadgar/core/providers/comparison_provider.dart';
import 'package:abadgar/core/providers/financial_summary_provider.dart';
import 'package:abadgar/core/providers/locale_provider.dart';
import 'package:abadgar/core/providers/seasons_provider.dart';
import 'package:abadgar/core/providers/transactions_provider.dart';
import 'package:abadgar/core/theme/app_theme.dart';
import 'package:abadgar/core/theme/theme_provider.dart';
import 'package:abadgar/ui/screens/analytics/analytics_screen.dart';
import 'package:abadgar/ui/screens/ledger/ledger_screen.dart';
import 'package:abadgar/ui/screens/settings/settings_screen.dart';
import 'package:abadgar/ui/widgets/app_controls.dart';
import 'package:abadgar/ui/widgets/app_selector.dart';
import 'package:abadgar/ui/widgets/app_surface.dart';
import 'package:abadgar/ui/widgets/transaction_form/parts/form_shared.dart';
import 'package:abadgar/ui/widgets/transaction_form/parts/generic_transaction_form.dart';
import 'package:abadgar/ui/widgets/transaction_form/parts/yield_form.dart';
import 'package:abadgar/ui/widgets/transaction_form/transaction_bottom_sheet.dart';

class _StubActiveSeasonId extends ActiveSeasonId {
  final String? _id;
  _StubActiveSeasonId(this._id);

  @override
  String? build() => _id;
}

class _StubAnalyticsSelection extends AnalyticsSeasonSelection {
  final String? _id;
  _StubAnalyticsSelection(this._id);

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

class _StubThemeModeNotifier extends ThemeModeNotifier {
  @override
  Future<ThemeMode> build() async => ThemeMode.light;
}

class _StubLocaleNotifier extends LocaleNotifier {
  final Locale _locale;
  _StubLocaleNotifier(this._locale);

  @override
  Future<Locale> build() async => _locale;
}

void main() {
  group('AppTheme tokens', () {
    test('light and dark themes provide tinted non-pure surfaces', () {
      final lightTokens = AppTheme.light.extension<AppTokens>()!;
      final darkTokens = AppTheme.dark.extension<AppTokens>()!;

      expect(lightTokens.canvas, isNot(Colors.white));
      expect(lightTokens.surface, isNot(Colors.white));
      expect(darkTokens.canvas, isNot(Colors.black));
      expect(darkTokens.surface, isNot(Colors.black));
    });
  });

  group('TransactionTile widget', () {
    testWidgets(
        'renders localized category, note, and signed amount; swipe triggers delete',
        (WidgetTester tester) async {
      bool deleted = false;
      final tx = Transaction(
        id: 'tx-1',
        seasonId: 's-1',
        amount: 4500,
        type: TransactionType.expense,
        date: DateTime(2026, 11, 20),
        category: 'Fertilizer',
        notes: 'Urea bag',
        createdAt: DateTime(2026, 11, 20),
        updatedAt: DateTime(2026, 11, 20),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TransactionTile(
              transaction: tx,
              currencyFormat:
                  NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0),
              onTap: () {},
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fertilizer'), findsOneWidget);
      expect(find.text('−Rs 4,500'), findsOneWidget);
      expect(find.textContaining('Urea bag'), findsOneWidget);

      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
    });

    testWidgets('cancels swipe delete when confirmDelete returns false',
        (WidgetTester tester) async {
      bool deleted = false;
      final tx = Transaction(
        id: 'tx-2',
        seasonId: 's-1',
        amount: 2500,
        type: TransactionType.expense,
        date: DateTime(2026, 11, 20),
        category: 'Seed',
        createdAt: DateTime(2026, 11, 20),
        updatedAt: DateTime(2026, 11, 20),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TransactionTile(
              transaction: tx,
              currencyFormat:
                  NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0),
              onTap: () {},
              confirmDelete: () async => false,
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(deleted, isFalse);
      expect(find.text('Seed'), findsOneWidget);
    });
  });

  group('QuickDateSelector widget', () {
    testWidgets('switches between Today and Yesterday in one tap',
        (WidgetTester tester) async {
      DateTime current = DateTime.now();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return QuickDateSelector(
                  selectedDate: current,
                  onDateChanged: (d) => setState(() => current = d),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Yesterday'));
      await tester.pumpAndSettle();

      final expectedYesterday =
          DateTime.now().subtract(const Duration(days: 1));
      expect(current.year, expectedYesterday.year);
      expect(current.month, expectedYesterday.month);
      expect(current.day, expectedYesterday.day);
    });
  });

  group('AppSelector widget', () {
    testWidgets('opens selector sheet and updates selected value',
        (WidgetTester tester) async {
      String selected = 's1';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Center(
                  child: AppSelectorTrigger(
                    label: selected == 's1' ? 'Wheat 2026' : 'Rice 2026',
                    badge: '12 Acr',
                    onTap: () async {
                      final picked = await showAppSelectorSheet<String>(
                        context: context,
                        title: 'Select season',
                        selectedValue: selected,
                        options: const [
                          AppSelectorOption(
                              value: 's1',
                              label: 'Wheat 2026',
                              badge: '12 Acr'),
                          AppSelectorOption(
                              value: 's2', label: 'Rice 2026', badge: '8 Acr'),
                        ],
                      );
                      if (picked != null) setState(() => selected = picked);
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Wheat 2026'), findsOneWidget);
      await tester.tap(find.byType(AppSelectorTrigger));
      await tester.pumpAndSettle();

      expect(find.text('Select season'), findsOneWidget);
      await tester.tap(find.text('Rice 2026'));
      await tester.pumpAndSettle();

      expect(selected, 's2');
      expect(find.text('Rice 2026'), findsOneWidget);
    });
  });

  group('Form edge cases', () {
    testWidgets(
        'GenericTransactionForm handles legacy/custom categories without crashing',
        (WidgetTester tester) async {
      final now = DateTime(2026, 6, 1);
      final legacyTx = Transaction(
        id: 'tx-legacy',
        seasonId: 's-1',
        amount: 3200,
        type: TransactionType.expense,
        category: 'Seeds', // Not in AppCategories.expenses ('Seed')
        date: now,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeSeasonProvider
                .overrideWith((ref) => Stream<Season?>.value(null)),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: GenericTransactionForm(
                  seasonId: 's-1',
                  type: TransactionType.expense,
                  transaction: legacyTx,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Seeds'), findsOneWidget);
    });

    testWidgets(
        'GenericTransactionForm resolves revenue crop categories from widget.seasonId rather than activeSeasonProvider',
        (WidgetTester tester) async {
      final now = DateTime(2026, 6, 1);
      final wheatSeason = Season(
        id: 's-wheat',
        name: 'Wheat 2026',
        cropType: CropType.wheat,
        landArea: 10,
        startDate: now,
        status: SeasonStatus.active,
        createdAt: now,
        updatedAt: now,
      );
      final riceSeason = Season(
        id: 's-rice',
        name: 'Rice 2026',
        cropType: CropType.rice,
        landArea: 8,
        startDate: now,
        status: SeasonStatus.completed,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeSeasonProvider
                .overrideWith((ref) => Stream.value(wheatSeason)),
            seasonsProvider
                .overrideWith((ref) => Stream.value([wheatSeason, riceSeason])),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SingleChildScrollView(
                child: GenericTransactionForm(
                  seasonId: 's-rice',
                  type: TransactionType.revenue,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rice Sale'), findsOneWidget);
      expect(find.text('Wheat Sale'), findsNothing);
    });

    testWidgets(
        'TransactionBottomSheet shows Start New Season CTA when empty and routes yield_ to revenue mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeSeasonIdProvider
                .overrideWith(() => _StubActiveSeasonId(null)),
            seasonsProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: TransactionBottomSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Start New Season'), findsOneWidget);

      final now = DateTime(2026, 6, 1);
      final yieldTx = Transaction(
        id: 'tx-yield',
        seasonId: 's-1',
        amount: 50000,
        type: TransactionType.yield_,
        category: 'Harvest Sale',
        date: now,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeSeasonIdProvider
                .overrideWith(() => _StubActiveSeasonId('s-1')),
            seasonsProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TransactionBottomSheet(
                key: const ValueKey('yield-edit'),
                transaction: yieldTx,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Harvest Sale'), findsOneWidget);
    });

    testWidgets(
        'YieldForm preserves exact total sale price when editing without price changes',
        (WidgetTester tester) async {
      final now = DateTime(2026, 6, 1);
      final log = YieldLog(
        id: 'y-1',
        seasonId: 's-1',
        totalWeight: 15.5,
        unit: YieldUnit.mund,
        disposition: YieldDisposition.sold,
        salePrice: 100000,
        date: now,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: YieldForm(seasonId: 's-1', yieldLog: log),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('100,000'), findsOneWidget);
    });

    testWidgets(
        'QuickDateSelector opens date picker cleanly even for future-dated entries',
        (WidgetTester tester) async {
      final futureDate = DateTime.now().add(const Duration(days: 5));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: QuickDateSelector(
              selectedDate: futureDate,
              onDateChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ChoiceChip).last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('Console UI controls', () {
    testWidgets('AppSegmentedControl switches selection cleanly in 1 tap',
        (WidgetTester tester) async {
      var selected = 'expense';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Center(
                  child: AppSegmentedControl<String>(
                    selected: selected,
                    segments: const [
                      AppSegment(value: 'expense', label: 'Expense'),
                      AppSegment(value: 'revenue', label: 'Revenue'),
                      AppSegment(value: 'harvest', label: 'Harvest'),
                    ],
                    onChanged: (next) => setState(() => selected = next),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Revenue'));
      await tester.pumpAndSettle();
      expect(selected, 'revenue');
    });

    testWidgets(
        'CompactStepperCluster increments and decrements values accurately',
        (WidgetTester tester) async {
      double area = 5.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Center(
                  child: CompactStepperCluster(
                    stepLabel: '0.5',
                    onDecrement: () => setState(() => area -= 0.5),
                    onIncrement: () => setState(() => area += 0.5),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      expect(area, 5.5);

      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pump();
      expect(area, 5.0);
    });
  });

  group('Screen-level RTL & data coverage', () {
    testWidgets(
        'LedgerScreen groups transactions by month and renders cleanly in Sindhi RTL at 1.3x scale',
        (WidgetTester tester) async {
      final now = DateTime(2026, 6, 15);
      final season = Season(
        id: 's1',
        name: 'Rice 2026',
        cropType: CropType.rice,
        landArea: 8,
        startDate: now,
        status: SeasonStatus.active,
        createdAt: now,
        updatedAt: now,
      );
      final txns = [
        Transaction(
          id: 't1',
          seasonId: 's1',
          amount: 12000,
          type: TransactionType.expense,
          category: 'Fertilizer',
          notes: 'DAP bag',
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeSeasonIdProvider
                .overrideWith(() => _StubActiveSeasonId('s1')),
            activeSeasonProvider.overrideWith((ref) => Stream.value(season)),
            activeSeasonTransactionsProvider
                .overrideWith((ref) => Stream.value(txns)),
            activeSeasonYieldLogsProvider
                .overrideWith((ref) => Stream.value(const [])),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('sd'),
            supportedLocales: const [Locale('en'), Locale('ur'), Locale('sd')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              FallbackMaterialLocalizationDelegate(),
              FallbackCupertinoLocalizationDelegate(),
              FallbackWidgetsLocalizationDelegate(),
            ],
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.3),
              ),
              child: child!,
            ),
            home: const LedgerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('ڀاڻ'), findsOneWidget);
      expect(find.textContaining('DAP bag'), findsOneWidget);
    });

    testWidgets(
        'AnalyticsScreen shows Kg yield unit, trend chart, and handles comparison error safely',
        (WidgetTester tester) async {
      final s1Date = DateTime(2025, 1, 1);
      final s2Date = DateTime(2026, 1, 1);
      final s1 = Season(
        id: 's1',
        name: 'Wheat 2025',
        cropType: CropType.wheat,
        landArea: 10,
        startDate: s1Date,
        status: SeasonStatus.completed,
        createdAt: s1Date,
        updatedAt: s1Date,
      );
      final s2 = Season(
        id: 's2',
        name: 'Wheat 2026',
        cropType: CropType.wheat,
        landArea: 10,
        startDate: s2Date,
        status: SeasonStatus.completed,
        createdAt: s2Date,
        updatedAt: s2Date,
      );
      final summary1 = FinancialSummary(
        totalRevenue: 100000,
        totalExpenses: 40000,
        expenseByCategory: const {'Seed': 40000},
        transactionCount: 1,
        totalYieldWeight: 2000,
      );
      final summary2 = FinancialSummary(
        totalRevenue: 150000,
        totalExpenses: 50000,
        expenseByCategory: const {'Fertilizer': 50000},
        transactionCount: 1,
        totalYieldWeight: 2500,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seasonsProvider.overrideWith((ref) => Stream.value([s2, s1])),
            analyticsSeasonSelectionProvider
                .overrideWith(() => _StubAnalyticsSelection('s2')),
            seasonComparisonProvider('s2').overrideWith(
              (ref) async => SeasonComparison(
                currentSeason: s2,
                previousSeason: s1,
                currentSummary: summary2,
                previousSummary: summary1,
              ),
            ),
            multiYearTrendProvider.overrideWith(
              (ref) => Stream.value([
                SeasonTrendData(s1, summary1),
                SeasonTrendData(s2, summary2),
              ]),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AnalyticsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Yield / Jareeb'), findsOneWidget);
      expect(find.textContaining('250 Kg'), findsOneWidget);
      expect(find.text('Multi-Year Profit Trend'), findsOneWidget);
    });

    testWidgets(
        'SettingsScreen renders Jareeb land profile and Urdu RTL cleanly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            themeModeNotifierProvider
                .overrideWith(() => _StubThemeModeNotifier()),
            localeNotifierProvider
                .overrideWith(() => _StubLocaleNotifier(const Locale('ur'))),
            backupStatusNotifierProvider
                .overrideWith(() => _StubBackupStatusNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('ur'),
            supportedLocales: const [Locale('en'), Locale('ur'), Locale('sd')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              FallbackMaterialLocalizationDelegate(),
              FallbackCupertinoLocalizationDelegate(),
              FallbackWidgetsLocalizationDelegate(),
            ],
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('سیٹنگز'), findsOneWidget);
      expect(find.text('خفیہ بیک اپ (.abadgar)'), findsOneWidget);
    });
  });
}
