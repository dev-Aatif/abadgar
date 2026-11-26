import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqlite_async/sqlite_async.dart';
import 'local_migrations.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
Future<SqliteDatabase> localDatabase(LocalDatabaseRef ref) async {
  final dir = await getApplicationSupportDirectory();
  final path = join(dir.path, 'abadgar_local.db');
  final legacyPath = join(dir.path, 'abadgar.db');

  final db = SqliteDatabase(path: path);

  ref.onDispose(() {
    unawaited(db.close());
  });

  await db.initialize().timeout(const Duration(seconds: 10));
  await db.execute('PRAGMA foreign_keys = ON;');
  await localMigrations.migrate(db);
  await migrateLegacyPowerSyncIfPresent(db, legacyPath);

  return db;
}
