import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class SupabaseConnector extends PowerSyncBackendConnector {
  /// Exposes the most recent non-retryable sync failure so UI can warn the user
  /// instead of discarding blocked batches silently.
  static final ValueNotifier<String?> lastSyncWarning =
      ValueNotifier<String?>(null);

  static const Set<String> _nonRetryablePostgresCodes = {
    '22003', // numeric_value_out_of_range
    '23502', // not_null_violation
    '23503', // foreign_key_violation
    '23505', // unique_violation
    '23514', // check_violation
    '42501', // insufficient_privilege / RLS violation
    '42P01', // undefined_table
    'PGRST204', // schema cache column not found
  };

  final SupabaseClient supabase;

  SupabaseConnector(this.supabase);

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    final session = supabase.auth.currentSession;
    if (session == null) return null;

    final token = session.accessToken;
    final powersyncUrl = dotenv.isInitialized
        ? (dotenv.env['POWERSYNC_URL'] ??
            const String.fromEnvironment('POWERSYNC_URL'))
        : const String.fromEnvironment('POWERSYNC_URL');

    final uri = Uri.tryParse(powersyncUrl);
    if (powersyncUrl.isEmpty ||
        uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty) {
      appLogger.w(
          'Invalid or missing POWERSYNC_URL; skipping PowerSync connection.');
      return null;
    }

    return PowerSyncCredentials(
      endpoint: powersyncUrl,
      token: token,
    );
  }

  @override
  Future<void> uploadData(PowerSyncDatabase db) async {
    final transaction = await db.getNextCrudTransaction();
    if (transaction == null) return;

    try {
      for (var op in transaction.crud) {
        final table = supabase.from(op.table);
        switch (op.op) {
          case UpdateType.put:
            final opData = op.opData;
            if (opData == null) {
              appLogger
                  .w('Skipping put operation with null opData on ${op.table}');
              continue;
            }
            final data = Map<String, dynamic>.from(opData);
            data['id'] = op.id;
            await table.upsert(data);
            break;
          case UpdateType.patch:
            final opData = op.opData;
            if (opData == null || opData.isEmpty) {
              appLogger.w('Skipping empty patch operation on ${op.table}');
              continue;
            }
            await table.update(opData).eq('id', op.id);
            break;
          case UpdateType.delete:
            await table.delete().eq('id', op.id);
            break;
        }
      }
      await transaction.complete();
      lastSyncWarning.value = null;
    } on PostgrestException catch (e, st) {
      if (_nonRetryablePostgresCodes.contains(e.code)) {
        // Persistent errors (constraint/schema/RLS) -> unblock FIFO queue, log, and notify UI.
        appLogger.e(
          'Persistent sync error (${e.code}) on upload batch; unblocking queue.',
          error: e,
          stackTrace: st,
        );
        lastSyncWarning.value = e.code ?? 'SYNC_REJECTED';
        await transaction.complete();
      } else {
        appLogger.w('Transient sync error (${e.code}); will retry.');
        rethrow;
      }
    } catch (e, st) {
      appLogger.e('Sync upload failed; will retry.', error: e, stackTrace: st);
      rethrow;
    }
  }
}
