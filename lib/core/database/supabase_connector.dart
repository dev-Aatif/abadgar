import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConnector extends PowerSyncBackendConnector {
  final SupabaseClient supabase;

  SupabaseConnector(this.supabase);

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    final session = supabase.auth.currentSession;
    if (session == null) return null;

    final token = session.accessToken;
    final powersyncUrl = dotenv.env['POWERSYNC_URL'] ?? 'http://localhost:8080';

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
        try {
          final table = supabase.from(op.table);
          switch (op.op) {
            case UpdateType.put:
              final data = Map<String, dynamic>.from(op.opData!);
              data['id'] = op.id;
              await table.upsert(data);
              break;
            case UpdateType.patch:
              await table.update(op.opData!).eq('id', op.id);
              break;
            case UpdateType.delete:
              await table.delete().eq('id', op.id);
              break;
          }
        } catch (e) {
          debugPrint('Sync error for ${op.table}/${op.id}: $e');
          // Continue with remaining operations instead of aborting the batch
        }
      }
      await transaction.complete();
    } catch (e) {
      debugPrint('Fatal sync error: $e');
      // Allow PowerSync to retry this batch on next cycle
      rethrow;
    }
  }
}
