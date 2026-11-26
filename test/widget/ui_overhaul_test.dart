import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';
import 'package:abadgar/core/constants/enums.dart';
import 'package:abadgar/core/models/season.dart';
import 'package:abadgar/core/models/transaction.dart';
import 'package:abadgar/core/models/yield_log.dart';
import 'package:abadgar/core/providers/active_season_provider.dart';
import 'package:abadgar/core/theme/app_theme.dart';
import 'package:abadgar/ui/widgets/app_selector.dart';
import 'package:abadgar/ui/widgets/app_surface.dart';
import 'package:abadgar/ui/widgets/transaction_form/parts/form_shared.dart';
import 'package:abadgar/ui/widgets/transaction_form/parts/generic_transaction_form.dart';
import 'package:abadgar/ui/widgets/transaction_form/parts/yield_form.dart';

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
}
