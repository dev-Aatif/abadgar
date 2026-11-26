import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite_async/sqlite_async.dart';
import 'backup_crypto.dart';

class ExportService {
  static const String lastExternalBackupKey = 'last_external_backup_at';

  final SqliteDatabase db;

  ExportService(this.db);

  Future<Map<String, dynamic>> prepareData() async {
    return db.readTransaction((tx) async {
      final seasons = await tx.getAll('SELECT * FROM seasons');
      final transactions = await tx.getAll('SELECT * FROM transactions');
      final yieldLogs = await tx.getAll('SELECT * FROM yield_logs');
      final lands = await tx.getAll('SELECT * FROM lands');

      return {
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'seasons': seasons,
        'transactions': transactions,
        'yield_logs': yieldLogs,
        'lands': lands,
      };
    });
  }

  Future<String> getBackupData({String? passphrase}) async {
    final data = await prepareData();
    final plainJson = jsonEncode(data);
    if (passphrase != null && passphrase.isNotEmpty) {
      return BackupCrypto.encryptJsonAsync(plainJson, passphrase);
    }
    return plainJson;
  }

  Future<void> exportDatabase({String? passphrase}) async {
    final payload = await getBackupData(passphrase: passphrase);
    final isEncrypted = passphrase != null && passphrase.isNotEmpty;
    final ext = isEncrypted ? 'abadgar' : 'json';

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${tempDir.path}/abadgar_backup_$timestamp.$ext');

    await for (final entity in tempDir.list()) {
      if (entity is File &&
          entity.path.contains('abadgar_backup_') &&
          entity.path != file.path) {
        await entity.delete();
      }
    }

    await file.writeAsString(payload);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Abadgar Backup $timestamp',
    );
    await _recordExternalBackupTimestamp();
  }

  Future<bool> downloadDatabase({String? passphrase}) async {
    final payload = await getBackupData(passphrase: passphrase);
    final isEncrypted = passphrase != null && passphrase.isNotEmpty;
    final ext = isEncrypted ? 'abadgar' : 'json';
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'abadgar_backup_$timestamp.$ext';

    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Backup',
      fileName: fileName,
      type: FileType.any,
      bytes: utf8.encode(payload),
    );

    if (result == null) return false;

    if (!result.startsWith('content://')) {
      final file = File(result);
      if (!await file.exists()) {
        await file.writeAsString(payload);
      }
    }
    await _recordExternalBackupTimestamp();
    return true;
  }

  Future<void> _recordExternalBackupTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      lastExternalBackupKey,
      DateTime.now().toIso8601String(),
    );
  }
}
