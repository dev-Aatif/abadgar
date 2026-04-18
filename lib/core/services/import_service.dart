import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:powersync/powersync.dart';

class ImportService {
  final PowerSyncDatabase db;

  ImportService(this.db);

  Future<bool> importDatabase() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) return false;

    final file = File(result.files.single.path!);
    final content = await file.readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;

    if (data['version'] != 1) {
      throw Exception('Unsupported backup version');
    }

    if (data['seasons'] is! List || data['transactions'] is! List) {
      throw Exception('Invalid backup format: missing seasons or transactions');
    }

    final seasons = data['seasons'] as List<dynamic>;
    final transactions = data['transactions'] as List<dynamic>;
    final yieldLogs = (data['yield_logs'] as List<dynamic>?) ?? [];

    await db.writeTransaction((tx) async {
      for (var season in seasons) {
        if (season is! Map<String, dynamic> || season['id'] == null) continue;
        await tx.execute(
          'INSERT OR REPLACE INTO seasons(id, name, crop_type, land_area, start_date, end_date, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            season['id'],
            season['name'],
            season['crop_type'],
            season['land_area'],
            season['start_date'],
            season['end_date'],
            season['status'],
            season['created_at'],
            season['updated_at'],
          ],
        );
      }

      for (var txn in transactions) {
        if (txn is! Map<String, dynamic> || txn['id'] == null) continue;
        await tx.execute(
          'INSERT OR REPLACE INTO transactions(id, season_id, amount, category, date, type, notes, quantity, buyer_name, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            txn['id'],
            txn['season_id'],
            txn['amount'],
            txn['category'],
            txn['date'],
            txn['type'],
            txn['notes'],
            txn['quantity'],
            txn['buyer_name'],
            txn['created_at'],
            txn['updated_at'],
          ],
        );
      }

      for (var log in yieldLogs) {
        if (log is! Map<String, dynamic> || log['id'] == null) continue;
        await tx.execute(
          'INSERT OR REPLACE INTO yield_logs(id, season_id, total_weight, unit, date, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
          [
            log['id'],
            log['season_id'],
            log['total_weight'],
            log['unit'],
            log['date'],
            log['created_at'],
            log['updated_at'],
          ],
        );
      }
    });

    return true;
  }
}
