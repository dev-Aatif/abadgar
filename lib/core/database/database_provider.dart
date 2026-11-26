import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';
import 'app_schema.dart';
import 'supabase_bootstrap.dart';
import 'supabase_connector.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
Future<PowerSyncDatabase> powerSyncDatabase(PowerSyncDatabaseRef ref) async {
  final dir = await getApplicationSupportDirectory();
  final path = join(dir.path, 'abadgar.db');

  final db = PowerSyncDatabase(
    schema: schema,
    path: path,
  );

  var disposed = false;
  ref.onDispose(() {
    disposed = true;
    unawaited(db.close());
  });

  await db.initialize().timeout(const Duration(seconds: 10));

  // Connect to Supabase once initialized (allows instant local-first startup).
  unawaited(
    SupabaseBootstrap.ready.then((initialized) async {
      if (!initialized || disposed) return;
      try {
        final supabase = Supabase.instance.client;
        if (!db.connected) {
          await db.connect(connector: SupabaseConnector(supabase));
        }
      } catch (e, st) {
        appLogger.w(
          'Supabase unavailable; running PowerSync in local-only mode',
          error: e,
          stackTrace: st,
        );
      }
    }),
  );

  return db;
}
