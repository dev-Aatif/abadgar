import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/utils/logger.dart';

void main() async {
  runZonedGuarded(() async {
    final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    appLogger.i('Startup: Widgets initialized (Local-First)');

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      appLogger.e(
        'Flutter Error',
        error: details.exception,
        stackTrace: details.stack,
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      appLogger.e('Platform Dispatcher Error', error: error, stackTrace: stack);
      return true;
    };

    runApp(
      const ProviderScope(
        child: AbadgarApp(),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      appLogger.i('Startup: Splash removed');
    });
  }, (error, stackTrace) {
    appLogger.e(
      'Unhandled Exception ZonedGuarded',
      error: error,
      stackTrace: stackTrace,
    );
  });
}
