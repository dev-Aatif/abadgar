import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:supabase_flutter/supabase_flutter.dart' as sb show AuthState;
import '../database/database_provider.dart';
import '../database/supabase_bootstrap.dart';
import '../database/supabase_connector.dart';
import '../utils/logger.dart';
import 'active_season_provider.dart';
import 'analytics_selection_provider.dart';
import 'comparison_provider.dart';
import 'lands_provider.dart';
import 'seasons_provider.dart';
import 'transactions_provider.dart';

part 'auth_provider.g.dart';

@riverpod
class AuthState extends _$AuthState {
  StreamSubscription<sb.AuthState>? _sub;
  bool _disposed = false;

  @override
  Session? build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _sub?.cancel();
      _sub = null;
    });

    final attached = _attachSupabaseListener();
    if (!attached) {
      unawaited(
        SupabaseBootstrap.ready.then((initialized) {
          if (initialized && !_disposed) {
            _attachSupabaseListener();
          }
        }),
      );
      return null;
    }

    return Supabase.instance.client.auth.currentSession;
  }

  bool _attachSupabaseListener() {
    if (_sub != null) return true;
    final SupabaseClient supabase;
    try {
      supabase = Supabase.instance.client;
    } catch (_) {
      return false;
    }

    _sub = supabase.auth.onAuthStateChange.listen((data) {
      if (_disposed) return;
      if (data.session != state) {
        state = data.session;
      }
      if (data.event == AuthChangeEvent.signedIn && data.session != null) {
        _reconnectSync(supabase);
      }
    });

    final current = supabase.auth.currentSession;
    if (current != state) {
      state = current;
    }
    return true;
  }

  Future<void> _reconnectSync(SupabaseClient supabase) async {
    try {
      final db = await ref.read(powerSyncDatabaseProvider.future);
      if (!db.connected) {
        await db.connect(connector: SupabaseConnector(supabase));
      }
    } catch (e, st) {
      appLogger.w('Failed to reconnect PowerSync after sign-in',
          error: e, stackTrace: st);
    }
  }

  Future<void> signOut() async {
    try {
      final db = await ref.read(powerSyncDatabaseProvider.future);
      await db.disconnectAndClear();
    } catch (e, st) {
      appLogger.e('Failed to clear local PowerSync cache on signOut',
          error: e, stackTrace: st);
    }

    await ref.read(activeSeasonIdProvider.notifier).clear();
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e, st) {
      appLogger.w('Supabase signOut failed', error: e, stackTrace: st);
    }

    state = null;
    ref.invalidate(seasonsProvider);
    ref.invalidate(landsProvider);
    ref.invalidate(allTransactionsProvider);
    ref.invalidate(multiYearTrendProvider);
    ref.invalidate(analyticsSeasonSelectionProvider);
  }

  bool get isAuthenticated => state != null;
  User? get user => state?.user;
}
