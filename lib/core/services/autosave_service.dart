import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
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

      final filesWithStat = <({File file, DateTime modified})>[];
      await for (final entity in backupDir.list()) {
        if (entity is File && entity.path.endsWith('.json')) {
          final stat = await entity.stat();
          filesWithStat.add((file: entity, modified: stat.modified));
        }
      }
      filesWithStat.sort((a, b) => b.modified.compareTo(a.modified));

      if (filesWithStat.length > maxSnapshots) {
        for (var i = maxSnapshots; i < filesWithStat.length; i++) {
          await filesWithStat[i].file.delete();
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
    final filesWithStat = <({File file, DateTime modified, int size})>[];
    await for (final entity in backupDir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        final stat = await entity.stat();
        filesWithStat
            .add((file: entity, modified: stat.modified, size: stat.size));
      }
    }
    filesWithStat.sort((a, b) => b.modified.compareTo(a.modified));

    final entries = <AutoBackupEntry>[];
    for (final item in filesWithStat) {
      try {
        final raw = await item.file.readAsString();
        final summary = await Isolate.run(() => _parseBackupSummary(raw));
        if (summary == null) continue;
        entries.add(
          AutoBackupEntry(
            file: item.file,
            createdAt: summary.exportedAt ?? item.modified,
            seasonCount: summary.seasonCount,
            transactionCount: summary.transactionCount,
            yieldCount: summary.yieldCount,
            sizeBytes: item.size,
          ),
        );
      } catch (_) {
        // Skip unreadable/corrupted snapshot files cleanly.
      }
    }
    return entries;
  }

  static ({
    DateTime? exportedAt,
    int seasonCount,
    int transactionCount,
    int yieldCount,
  })? _parseBackupSummary(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return (
      exportedAt: DateTime.tryParse(decoded['exported_at']?.toString() ?? ''),
      seasonCount: (decoded['seasons'] as List<dynamic>?)?.length ?? 0,
      transactionCount:
          (decoded['transactions'] as List<dynamic>?)?.length ?? 0,
      yieldCount: (decoded['yield_logs'] as List<dynamic>?)?.length ?? 0,
    );
  }

  Future<void> restoreBackup(File file) async {
    final content = await file.readAsString();
    await ImportService(db).restoreFromJsonString(content);
  }
}
