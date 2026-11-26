import 'dart:convert';
import 'dart:io';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:sqlite_async/sqlite_async.dart';
import '../utils/logger.dart';

final localMigrations = SqliteMigrations()
  ..add(
    SqliteMigration(1, (tx) async {
      await tx.execute('''
        CREATE TABLE IF NOT EXISTS seasons (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          crop_type TEXT NOT NULL,
          land_area REAL NOT NULL CHECK (land_area > 0),
          start_date TEXT NOT NULL,
          end_date TEXT,
          status TEXT NOT NULL DEFAULT 'Active',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      await tx.execute('''
        CREATE TABLE IF NOT EXISTS transactions (
          id TEXT PRIMARY KEY,
          season_id TEXT NOT NULL REFERENCES seasons(id) ON DELETE CASCADE,
          amount REAL NOT NULL CHECK (amount >= 0),
          type TEXT NOT NULL,
          date TEXT NOT NULL,
          category TEXT,
          notes TEXT,
          quantity REAL,
          buyer_name TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      await tx.execute('''
        CREATE TABLE IF NOT EXISTS yield_logs (
          id TEXT PRIMARY KEY,
          season_id TEXT NOT NULL REFERENCES seasons(id) ON DELETE CASCADE,
          total_weight REAL NOT NULL CHECK (total_weight > 0),
          unit TEXT NOT NULL,
          disposition TEXT NOT NULL DEFAULT 'Sold',
          sale_price REAL,
          destination TEXT,
          transaction_id TEXT REFERENCES transactions(id) ON DELETE SET NULL,
          date TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      await tx.execute('''
        CREATE TABLE IF NOT EXISTS lands (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          area REAL NOT NULL CHECK (area > 0),
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      await tx.execute(
        'CREATE INDEX IF NOT EXISTS idx_seasons_status_created ON seasons (status ASC, created_at DESC)',
      );
      await tx.execute(
        'CREATE INDEX IF NOT EXISTS idx_seasons_start_date ON seasons (start_date DESC)',
      );
      await tx.execute(
        'CREATE INDEX IF NOT EXISTS idx_transactions_season_date ON transactions (season_id ASC, date DESC)',
      );
      await tx.execute(
        'CREATE INDEX IF NOT EXISTS idx_yield_logs_season_date ON yield_logs (season_id ASC, date DESC)',
      );
      await tx.execute(
        'CREATE INDEX IF NOT EXISTS idx_yield_logs_tx ON yield_logs (transaction_id)',
      );
      await tx.execute(
        'CREATE INDEX IF NOT EXISTS idx_lands_name ON lands (name ASC)',
      );
    }),
  );

/// One-time migration from an older PowerSync `abadgar.db` if present on disk.
Future<void> migrateLegacyPowerSyncIfPresent(
  SqliteDatabase db,
  String legacyDbPath,
) async {
  final legacyFile = File(legacyDbPath);
  if (!await legacyFile.exists()) return;

  final existingSeasons = await db.getAll('SELECT id FROM seasons LIMIT 1');
  final existingLands = await db.getAll('SELECT id FROM lands LIMIT 1');
  if (existingSeasons.isNotEmpty || existingLands.isNotEmpty) return;

  sqlite.Database? legacy;
  try {
    legacy = sqlite.sqlite3.open(legacyDbPath, mode: sqlite.OpenMode.readOnly);
    final tables = legacy
        .select("SELECT name FROM sqlite_master WHERE type='table'")
        .map((r) => r['name'] as String)
        .toSet();

    List<Map<String, dynamic>> readLegacyTable(String rawTable) {
      if (!tables.contains(rawTable)) return const [];
      final rows = legacy!.select('SELECT id, data FROM $rawTable');
      final out = <Map<String, dynamic>>[];
      for (final row in rows) {
        final id = row['id'] as String?;
        final rawData = row['data'] as String?;
        if (id == null || rawData == null) continue;
        final decoded = jsonDecode(rawData);
        if (decoded is Map<String, dynamic>) {
          out.add({'id': id, ...decoded});
        }
      }
      return out;
    }

    final seasons = readLegacyTable('ps_data__seasons');
    final transactions = readLegacyTable('ps_data__transactions');
    final yieldLogs = readLegacyTable('ps_data__yield_logs');
    final lands = readLegacyTable('ps_data__lands');

    if (seasons.isEmpty &&
        transactions.isEmpty &&
        yieldLogs.isEmpty &&
        lands.isEmpty) {
      return;
    }

    await db.writeTransaction((tx) async {
      for (final s in seasons) {
        await tx.execute(
          '''
          INSERT OR IGNORE INTO seasons(id, name, crop_type, land_area, start_date, end_date, status, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            s['id'],
            s['name'],
            s['crop_type'],
            s['land_area'],
            s['start_date'],
            s['end_date'],
            s['status'] ?? 'Active',
            s['created_at'],
            s['updated_at'],
          ],
        );
      }
      for (final t in transactions) {
        await tx.execute(
          '''
          INSERT OR IGNORE INTO transactions(id, season_id, amount, type, date, category, notes, quantity, buyer_name, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            t['id'],
            t['season_id'],
            t['amount'],
            t['type'],
            t['date'],
            t['category'],
            t['notes'],
            t['quantity'],
            t['buyer_name'],
            t['created_at'],
            t['updated_at'],
          ],
        );
      }
      for (final y in yieldLogs) {
        await tx.execute(
          '''
          INSERT OR IGNORE INTO yield_logs(id, season_id, total_weight, unit, disposition, sale_price, destination, transaction_id, date, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            y['id'],
            y['season_id'],
            y['total_weight'],
            y['unit'],
            y['disposition'] ?? 'Sold',
            y['sale_price'],
            y['destination'],
            y['transaction_id'],
            y['date'],
            y['created_at'],
            y['updated_at'],
          ],
        );
      }
      for (final l in lands) {
        await tx.execute(
          '''
          INSERT OR IGNORE INTO lands(id, name, area, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?)
          ''',
          [
            l['id'],
            l['name'],
            l['area'],
            l['created_at'],
            l['updated_at'],
          ],
        );
      }
    });

    appLogger.i(
        'Migrated legacy local data (${seasons.length} seasons, ${transactions.length} transactions).');
  } catch (e, st) {
    appLogger.w('Skipped legacy PowerSync DB migration',
        error: e, stackTrace: st);
  } finally {
    legacy?.close();
  }
}
