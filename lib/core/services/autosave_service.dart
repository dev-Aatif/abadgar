import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'export_service.dart';

class AutoSaveService {
  final PowerSyncDatabase db;
  
  AutoSaveService(this.db);

  /// Saves a backup to the application's document directory.
  /// Note: This is still deleted on app uninstall, but provides protection 
  /// against database corruption or local storage issues.
  /// For cross-uninstall protection, Cloud Sync is required.
  Future<void> triggerBackup() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDocDir.path}/backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final fileName = 'abadgar_autosave_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${backupDir.path}/$fileName');
      
      final exportService = ExportService(db);
      final data = await exportService.getBackupData();
      await file.writeAsString(data);
      
      // Cleanup old backups (keep last 5)
      final files = backupDir.listSync().toList()
        ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      
      if (files.length > 5) {
        for (var i = 5; i < files.length; i++) {
          await files[i].delete();
        }
      }
    } catch (e) {
      // Silent fail for autosave
      print('Autosave failed: $e');
    }
  }
}
