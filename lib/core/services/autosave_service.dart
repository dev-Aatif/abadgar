import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite_async/sqlite_async.dart';
import '../utils/logger.dart';
import 'export_service.dart';
import 'import_service.dart';

class AutoBackupEntry {
  final File file;
  final DateTime createdAt;
  final int seasonCount;
  final int transactionCount;
  final int yieldCount;
  final int sizeBytes;

  const AutoBackupEntry({
    required this.file,
    required this.createdAt,
    required this.seasonCount,
    required this.transactionCount,
    required this.yieldCount,
    required this.sizeBytes,
  });
}

class AutoSaveService {
  static const String autoBackupEnabledKey = 'auto_backup_enabled';
  static const String lastAutoBackupKey = 'last_auto_backup_at';
  static const int maxSnapshots = 7;

  final SqliteDatabase db;
  final Future<Directory> Function()? directoryOverride;

  AutoSaveService(this.db, {this.directoryOverride});

  Future<Directory> _backupsDir() async {
    final root = directoryOverride != null
        ? await directoryOverride!()
        : await getApplicationDocumentsDirectory();
    final backupDir = Directory('${root.path}/backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  /// Saves a rolling local JSON snapshot in app documents storage.
  /// Returns true if a snapshot was written.
  Future<bool> triggerBackup({bool force = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(autoBackupEnabledKey) ?? true;
      if (!force && !enabled) return false;

      final exportService = ExportService(db);
      final mapData = await exportService.prepareData();
      final seasons = mapData['seasons'] as List<dynamic>;
      final transactions = mapData['transactions'] as List<dynamic>;
      final yields = mapData['yield_logs'] as List<dynamic>;
      final lands = mapData['lands'] as List<dynamic>;

      if (!force &&
          seasons.isEmpty &&
          transactions.isEmpty &&
          yields.isEmpty &&
          lands.isEmpty) {
        return false;
      }

      final backupDir = await _backupsDir();
      final now = DateTime.now();
      final fileName = 'abadgar_autosave_${now.millisecondsSinceEpoch}.json';
      final file = File('${backupDir.path}/$fileName');

      await file.writeAsString(jsonEncode(mapData));
      await prefs.setString(lastAutoBackupKey, now.toIso8601String());

      final files = backupDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort(
            (a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      if (files.length > maxSnapshots) {
        for (var i = maxSnapshots; i < files.length; i++) {
          await files[i].delete();
        }
      }
      return true;
    } catch (e, st) {
      appLogger.w('Autosave failed', error: e, stackTrace: st);
      return false;
    }
  }

  Future<List<AutoBackupEntry>> listBackups() async {
    final backupDir = await _backupsDir();
    final files = backupDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    final entries = <AutoBackupEntry>[];
    for (final file in files) {
      try {
        final raw = await file.readAsString();
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) continue;
        final exportedAt =
            DateTime.tryParse(decoded['exported_at']?.toString() ?? '');
        final stat = await file.stat();
        entries.add(
          AutoBackupEntry(
            file: file,
            createdAt: exportedAt ?? stat.modified,
            seasonCount: (decoded['seasons'] as List<dynamic>?)?.length ?? 0,
            transactionCount:
                (decoded['transactions'] as List<dynamic>?)?.length ?? 0,
            yieldCount: (decoded['yield_logs'] as List<dynamic>?)?.length ?? 0,
            sizeBytes: stat.size,
          ),
        );
      } catch (_) {
        // Skip unreadable/corrupted snapshot files cleanly.
      }
    }
    return entries;
  }

  Future<void> restoreBackup(File file) async {
    final content = await file.readAsString();
    await ImportService(db).restoreFromJsonString(content);
  }
}
