import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class ExportService {
  final PowerSyncDatabase db;

  ExportService(this.db);

  Future<void> exportDatabase() async {
    final seasons = await db.getAll('SELECT * FROM seasons');
    final transactions = await db.getAll('SELECT * FROM transactions');

    final data = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'seasons': seasons,
      'transactions': transactions,
    };

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
}
