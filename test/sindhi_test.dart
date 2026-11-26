import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:abadgar/app.dart';
import 'package:abadgar/core/constants/enums.dart';
import 'package:abadgar/core/utils/l10n_helpers.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('ur'), Locale('sd')]) {
    testWidgets(
        'Loads ${locale.languageCode} localizations and helpers cleanly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            FallbackMaterialLocalizationDelegate(),
            FallbackCupertinoLocalizationDelegate(),
            GlobalWidgetsLocalizations.delegate,
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
              if (locale.languageCode == 'sd') {
                expect(unit, 'مڻ (40 ڪلو)');
              } else if (locale.languageCode == 'ur') {
                expect(unit, 'من (40 کلو)');
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
}
