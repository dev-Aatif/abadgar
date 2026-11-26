import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'app.dart';
import 'core/database/supabase_bootstrap.dart';
import 'core/utils/logger.dart';

void main() async {
  runZonedGuarded(() async {
    final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    appLogger.i('Startup: Step 1 (Widgets initialized)');

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      appLogger.e('Flutter Error',
          error: details.exception, stackTrace: details.stack);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      appLogger.e('Platform Dispatcher Error', error: error, stackTrace: stack);
      return true;
    };

    var supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
    var supabaseKey = const String.fromEnvironment('SUPABASE_ANON_KEY');

    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      try {
        await dotenv.load(fileName: '.env');
        supabaseUrl = supabaseUrl.isNotEmpty
            ? supabaseUrl
            : (dotenv.env['SUPABASE_URL'] ?? '');
        supabaseKey = supabaseKey.isNotEmpty
            ? supabaseKey
            : (dotenv.env['SUPABASE_ANON_KEY'] ?? '');
      } catch (_) {
        // .env is optional; local-only mode works without it.
      }
    }

    // Initialize Supabase asynchronously so offline/slow networks never block frame 1.
    unawaited(
      SupabaseBootstrap.initialize(url: supabaseUrl, anonKey: supabaseKey),
    );

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
    appLogger.e('Unhandled Exception ZonedGuarded',
        error: error, stackTrace: stackTrace);
  });
}
