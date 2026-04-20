import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'app.dart';
import 'core/utils/logger.dart';

void main() async {
  runZonedGuarded(() async {
    final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    appLogger.i("🚀 Startup: Step 1 (Widgets initialized)");

    // Flutter framework error handler - Local Logging
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      appLogger.e("Flutter Error", error: details.exception, stackTrace: details.stack);
    };

    // Asynchronous error handler - Local Logging
    PlatformDispatcher.instance.onError = (error, stack) {
      appLogger.e("Platform Dispatcher Error", error: error, stackTrace: stack);
      return true;
    };

    // Load environment variables
    try {
      await dotenv.load(fileName: ".env");
      appLogger.i("🚀 Startup: Step 2 (.env loaded)");
    } catch (e) {
      appLogger.w("⚠️ Warning: .env file not found.");
    }

    // Initialize Supabase - safely handle missing .env
    final supabaseUrl = dotenv.isInitialized ? (dotenv.env['SUPABASE_URL'] ?? '') : '';
    final supabaseKey = dotenv.isInitialized ? (dotenv.env['SUPABASE_ANON_KEY'] ?? '') : '';

    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      appLogger.w("⚠️ Warning: Supabase credentials missing. Cloud sync will be disabled.");
    }

    try {
      appLogger.i("🚀 Startup: Step 3 (Initializing Supabase...)");
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
      ).timeout(const Duration(seconds: 10));
      appLogger.i("🚀 Startup: Step 4 (Supabase Ready)");
    } catch (e, stack) {
      appLogger.e("❌ Supabase Init Failed", error: e, stackTrace: stack);
    }

    runApp(
      const ProviderScope(
        child: AbadgarApp(),
      ),
    );

    // Remove splash after a tiny delay to ensure first frame is painted
    Future.delayed(const Duration(milliseconds: 500), () {
      FlutterNativeSplash.remove();
      appLogger.i("🚀 Startup: Step 5 (Splash Removed)");
    });
  }, (error, stackTrace) {
    appLogger.e("Unhandled Exception ZonedGuarded", error: error, stackTrace: stackTrace);
  });
}
