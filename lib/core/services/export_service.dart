import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

class ExportService {
  final PowerSyncDatabase db;

  ExportService(this.db);

  Future<Map<String, dynamic>> _prepareData() async {
    final seasons = await db.getAll('SELECT * FROM seasons');
    final transactions = await db.getAll('SELECT * FROM transactions');
    final yieldLogs = await db.getAll('SELECT * FROM yield_logs');

    return {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'seasons': seasons,
      'transactions': transactions,
      'yield_logs': yieldLogs,
    };
  }

  Future<void> exportDatabase() async {
    final data = await _prepareData();
    final jsonString = jsonEncode(data);
    
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${tempDir.path}/abadgar_backup_$timestamp.json');
    
    await file.writeAsString(jsonString);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Abadgar Data Backup $timestamp',
    );
  }

  Future<void> downloadDatabase() async {
    final data = await _prepareData();
    final jsonString = jsonEncode(data);
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    
    final fileName = 'abadgar_backup_$timestamp.json';
    
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Backup',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: utf8.encode(jsonString),
    );

    if (result != null) {
      // On some platforms saveFile returns the path and we might need to write manually
      // but if bytes was provided, it might have been saved already.
      // To be safe, we check if the file exists at the returned path.
      final file = File(result);
      if (!await file.exists()) {
        await file.writeAsString(jsonString);
      }
    }
  }
}
