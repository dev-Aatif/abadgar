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
    final data = jsonDecode(content);
    
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid backup: Root is not a JSON object');
    }

    if (data['version'] != 1) {
      throw Exception('Unsupported backup version: ${data['version']}');
    }

    if (data['seasons'] is! List || data['transactions'] is! List) {
      throw Exception('Invalid backup format: missing seasons or transactions lists');
    }

    final seasons = data['seasons'] as List<dynamic>;
    final transactions = data['transactions'] as List<dynamic>;
    final yieldLogs = (data['yield_logs'] as List<dynamic>?) ?? [];

    await db.writeTransaction((tx) async {
      for (var season in seasons) {
        if (season is! Map<String, dynamic>) continue;
        
        final id = _validateString(season['id'], 'Season ID');
        final name = _validateString(season['name'], 'Season Name');
        final cropType = _validateString(season['crop_type'], 'Crop Type');
        final status = _validateString(season['status'], 'Status');
        final landArea = _validateNum(season['land_area'], 'Land Area').toDouble();
        final startDate = _validateString(season['start_date'], 'Start Date');
        final createdAt = _validateString(season['created_at'], 'Created At');
        final updatedAt = _validateString(season['updated_at'], 'Updated At');

        await tx.execute(
          'INSERT OR REPLACE INTO seasons(id, name, crop_type, land_area, start_date, end_date, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            id,
            name,
            cropType,
            landArea,
            startDate,
            season['end_date']?.toString(),
            status,
            createdAt,
            updatedAt,
          ],
        );
      }

      for (var txn in transactions) {
        if (txn is! Map<String, dynamic>) continue;
        
        final id = _validateString(txn['id'], 'Transaction ID');
        final seasonId = _validateString(txn['season_id'], 'Season ID');
        final amount = _validateNum(txn['amount'], 'Amount').toDouble();
        final date = _validateString(txn['date'], 'Date');
        final type = _validateString(txn['type'], 'Type');
        final createdAt = _validateString(txn['created_at'], 'Created At');
        final updatedAt = _validateString(txn['updated_at'], 'Updated At');

        await tx.execute(
          'INSERT OR REPLACE INTO transactions(id, season_id, amount, category, date, type, notes, quantity, buyer_name, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            id,
            seasonId,
            amount,
            txn['category']?.toString(),
            date,
            type,
            txn['notes']?.toString(),
            txn['quantity'] != null ? _validateNum(txn['quantity'], 'Quantity').toDouble() : null,
            txn['buyer_name']?.toString(),
            createdAt,
            updatedAt,
          ],
        );
      }

      for (var log in yieldLogs) {
        if (log is! Map<String, dynamic>) continue;
        
        final id = _validateString(log['id'], 'Yield Log ID');
        final seasonId = _validateString(log['season_id'], 'Season ID');
        final totalWeight = _validateNum(log['total_weight'], 'Total Weight').toDouble();
        final unit = _validateString(log['unit'], 'Unit');
        final date = _validateString(log['date'], 'Date');
        final createdAt = _validateString(log['created_at'], 'Created At');
        final updatedAt = _validateString(log['updated_at'], 'Updated At');

        await tx.execute(
          'INSERT OR REPLACE INTO yield_logs(id, season_id, total_weight, unit, date, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
          [
            id,
            seasonId,
            totalWeight,
            unit,
            date,
            createdAt,
            updatedAt,
          ],
        );
      }
    });

    return true;
  }

  String _validateString(dynamic value, String fieldName) {
    if (value is! String || value.isEmpty) {
      throw Exception('Invalid or missing $fieldName in backup');
    }
    return value;
  }

  num _validateNum(dynamic value, String fieldName) {
    if (value is! num) {
      throw Exception('Invalid or missing $fieldName in backup: Expected numeric value');
    }
    return value;
  }
}
