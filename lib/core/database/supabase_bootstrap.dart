import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

/// Coordinates non-blocking Supabase initialization so local SQLite renders
/// frame 1 immediately in offline/rural conditions.
class SupabaseBootstrap {
  SupabaseBootstrap._();

  static Completer<bool> _readyCompleter = Completer<bool>();

  static Future<bool> get ready => _readyCompleter.future;

  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    if (_readyCompleter.isCompleted) {
      _readyCompleter = Completer<bool>();
    }

    if (url.isEmpty || anonKey.isEmpty) {
      appLogger.w('Supabase credentials missing; cloud sync disabled.');
      if (!_readyCompleter.isCompleted) _readyCompleter.complete(false);
      return;
    }

    try {
      appLogger.i('Startup: Initializing Supabase...');
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      ).timeout(const Duration(seconds: 5));
      appLogger.i('Startup: Supabase ready');
      if (!_readyCompleter.isCompleted) _readyCompleter.complete(true);
    } catch (e, stack) {
      appLogger.e('Supabase init failed; continuing offline',
          error: e, stackTrace: stack);
      if (!_readyCompleter.isCompleted) _readyCompleter.complete(false);
    }
  }
}
