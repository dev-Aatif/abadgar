import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'locale_provider.g.dart';

@Riverpod(keepAlive: true)
class LocaleNotifier extends _$LocaleNotifier {
  static const _key = 'app_locale';
  static const supportedCodes = {'en', 'ur', 'sd'};

  @override
  Future<Locale> build() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null && supportedCodes.contains(code)) {
      return Locale(code);
    }
    return const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    final safeLocale = supportedCodes.contains(locale.languageCode)
        ? Locale(locale.languageCode)
        : const Locale('en');
    state = AsyncData(safeLocale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, safeLocale.languageCode);
  }
}
