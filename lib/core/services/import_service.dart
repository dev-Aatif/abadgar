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

    final seasons = data['seasons'] as List<dynamic>;
    final transactions = data['transactions'] as List<dynamic>;

    await db.writeTransaction((tx) async {
      for (var season in seasons) {
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
        await tx.execute(
          'INSERT OR REPLACE INTO transactions(id, season_id, amount, category, date, type, notes, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            txn['id'],
            txn['season_id'],
            txn['amount'],
            txn['category'],
            txn['date'],
            txn['type'],
            txn['notes'],
            txn['created_at'],
            txn['updated_at'],
          ],
        );
      }
    });

    return true;
  }
}
