import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/router/app_router.dart';

class AbadgarApp extends ConsumerWidget {
  const AbadgarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeNotifierProvider).value ?? ThemeMode.system;
    final locale = ref.watch(localeNotifierProvider).value ?? const Locale('en');

    return MaterialApp.router(
      title: 'Abadgar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      routerConfig: ref.watch(appRouterProvider),
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
    );
  }
}

class FallbackMaterialLocalizationDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    if (locale.languageCode == 'sd') {
      return GlobalMaterialLocalizations.delegate.load(const Locale('ur'));
    }
    return GlobalMaterialLocalizations.delegate.load(locale);
  }

  @override
  bool shouldReload(FallbackMaterialLocalizationDelegate old) => false;
}

class FallbackCupertinoLocalizationDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) async {
    if (locale.languageCode == 'sd') {
      return GlobalCupertinoLocalizations.delegate.load(const Locale('ur'));
    }
    return GlobalCupertinoLocalizations.delegate.load(locale);
  }

  @override
  bool shouldReload(FallbackCupertinoLocalizationDelegate old) => false;
}
