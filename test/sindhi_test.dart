import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';
import 'package:abadgar/app.dart';

void main() {
  testWidgets('Sindhi test', (WidgetTester tester) async {
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
        locale: const Locale('sd'),
        home: Builder(
          builder: (context) {
            final loc = AppLocalizations.of(context)!;
            return Text(loc.dashboard);
          },
        ),
      ),
    );
  });
}
