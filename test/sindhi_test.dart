import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:abadgar/app.dart';
import 'package:abadgar/core/constants/enums.dart';
import 'package:abadgar/core/utils/l10n_helpers.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('ur'), Locale('sd')]) {
    testWidgets(
        'Loads ${locale.languageCode} localizations, RTL directionality, and helpers cleanly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            FallbackMaterialLocalizationDelegate(),
            FallbackCupertinoLocalizationDelegate(),
            FallbackWidgetsLocalizationDelegate(),
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ur'),
            Locale('sd'),
          ],
          locale: locale,
          home: Builder(
            builder: (context) {
              final loc = AppLocalizations.of(context)!;
              final unit = L10nHelpers.yieldUnitLabel(context, YieldUnit.mund);
              final cat = L10nHelpers.categoryLabel(context, 'Fertilizer');
              final dir = Directionality.of(context);
              if (locale.languageCode == 'sd') {
                expect(dir, TextDirection.rtl);
                expect(unit, 'مڻ (40 ڪلو)');
              } else if (locale.languageCode == 'ur') {
                expect(dir, TextDirection.rtl);
                expect(unit, 'من (40 کلو)');
              } else {
                expect(dir, TextDirection.ltr);
              }
              return Text('${loc.dashboard}|$unit|$cat');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Sindhi (sd) mirrors Row layout RTL like Urdu (ur)',
      (WidgetTester tester) async {
    Future<double> measureFirstItemLeft(Locale locale) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            FallbackMaterialLocalizationDelegate(),
            FallbackCupertinoLocalizationDelegate(),
            FallbackWidgetsLocalizationDelegate(),
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ur'),
            Locale('sd'),
          ],
          locale: locale,
          home: const Scaffold(
            body: Row(
              children: [
                SizedBox(key: ValueKey('first'), width: 50, height: 40),
                SizedBox(key: ValueKey('second'), width: 50, height: 40),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getTopLeft(find.byKey(const ValueKey('first'))).dx;
    }

    final enLeft = await measureFirstItemLeft(const Locale('en'));
    final urLeft = await measureFirstItemLeft(const Locale('ur'));
    final sdLeft = await measureFirstItemLeft(const Locale('sd'));

    expect(enLeft, 0.0);
    expect(urLeft, greaterThan(enLeft));
    expect(sdLeft, urLeft);
  });
}
