import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_schema.dart';
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

  try {
    await db.initialize().timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint("Database initialization failed or timed out: $e");
  }

  // Connect to Supabase
  final supabase = Supabase.instance.client;
  final connector = SupabaseConnector(supabase);
  
  // Connect background sync
  db.connect(connector: connector);

  ref.onDispose(() => db.close());
  
  return db;
}
