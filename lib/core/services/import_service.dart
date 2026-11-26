import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:sqlite_async/sqlite_async.dart';
import '../constants/enums.dart';
import 'autosave_service.dart';
import 'backup_crypto.dart';

typedef PassphrasePrompt = Future<String?> Function();
typedef RestoreConfirmPrompt = Future<bool> Function();

class ImportService {
  static const int maxBackupBytes = 10 * 1024 * 1024; // 10 MB guard

  final SqliteDatabase db;

  ImportService(this.db);

  Future<bool> importDatabase({
    PassphrasePrompt? onPassphraseRequired,
    RestoreConfirmPrompt? onConfirmRestore,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return false;

    final picked = result.files.single;
    final String content;
    if (picked.bytes != null) {
      if (picked.bytes!.length > maxBackupBytes) {
        throw Exception('Backup file exceeds maximum supported size (10 MB)');
      }
      content = utf8.decode(picked.bytes!);
    } else if (picked.path != null) {
      final file = File(picked.path!);
      final fileSize = await file.length();
      if (fileSize > maxBackupBytes) {
        throw Exception('Backup file exceeds maximum supported size (10 MB)');
      }
      content = await file.readAsString();
    } else {
      return false;
    }

    var jsonToParse = content;
    if (BackupCrypto.isEncryptedEnvelope(content)) {
      final passphrase = await onPassphraseRequired?.call();
      if (passphrase == null || passphrase.isEmpty) {
        return false;
      }
      jsonToParse = BackupCrypto.decryptJson(content, passphrase);
    }

    final parsed = parseAndValidateBackup(jsonToParse);

    if (onConfirmRestore != null) {
      final confirmed = await onConfirmRestore();
      if (!confirmed) return false;
    }

    // Take a local safety snapshot before replacing tables.
    await AutoSaveService(db).triggerBackup(force: true);
    await restoreValidatedPayload(parsed);

    return true;
  }

  Future<void> restoreFromJsonString(
    String content, {
    bool replaceExisting = true,
  }) async {
    final parsed = parseAndValidateBackup(content);
    await restoreValidatedPayload(parsed, replaceExisting: replaceExisting);
  }

  Future<void> restoreValidatedPayload(
    ({
      List<Map<String, dynamic>> seasons,
      List<Map<String, dynamic>> transactions,
      List<Map<String, dynamic>> yieldLogs,
      List<Map<String, dynamic>> lands,
    }) parsed, {
    bool replaceExisting = true,
  }) async {
    // Use ON CONFLICT DO UPDATE (never INSERT OR REPLACE) so SQLite foreign-key
    // ON DELETE CASCADE never wipes child transactions/yields during merge restores.
    await db.writeTransaction((tx) async {
      if (replaceExisting) {
        await tx.execute('DELETE FROM yield_logs');
        await tx.execute('DELETE FROM transactions');
        await tx.execute('DELETE FROM seasons');
        await tx.execute('DELETE FROM lands');
      }
      for (final season in parsed.seasons) {
        await tx.execute(
          '''
          INSERT INTO seasons(id, name, crop_type, land_area, start_date, end_date, status, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            name = excluded.name,
            crop_type = excluded.crop_type,
            land_area = excluded.land_area,
            start_date = excluded.start_date,
            end_date = excluded.end_date,
            status = excluded.status,
            created_at = excluded.created_at,
            updated_at = excluded.updated_at
          ''',
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

      for (final txn in parsed.transactions) {
        await tx.execute(
          '''
          INSERT INTO transactions(id, season_id, amount, category, date, type, notes, quantity, buyer_name, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            season_id = excluded.season_id,
            amount = excluded.amount,
            category = excluded.category,
            date = excluded.date,
            type = excluded.type,
            notes = excluded.notes,
            quantity = excluded.quantity,
            buyer_name = excluded.buyer_name,
            created_at = excluded.created_at,
            updated_at = excluded.updated_at
          ''',
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

      for (final log in parsed.yieldLogs) {
        await tx.execute(
          '''
          INSERT INTO yield_logs(id, season_id, total_weight, unit, disposition, sale_price, destination, transaction_id, date, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            season_id = excluded.season_id,
            total_weight = excluded.total_weight,
            unit = excluded.unit,
            disposition = excluded.disposition,
            sale_price = excluded.sale_price,
            destination = excluded.destination,
            transaction_id = excluded.transaction_id,
            date = excluded.date,
            created_at = excluded.created_at,
            updated_at = excluded.updated_at
          ''',
          [
            log['id'],
            log['season_id'],
            log['total_weight'],
            log['unit'],
            log['disposition'],
            log['sale_price'],
            log['destination'],
            log['transaction_id'],
            log['date'],
            log['created_at'],
            log['updated_at'],
          ],
        );
      }

      for (final land in parsed.lands) {
        await tx.execute(
          '''
          INSERT INTO lands(id, name, area, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            name = excluded.name,
            area = excluded.area,
            created_at = excluded.created_at,
            updated_at = excluded.updated_at
          ''',
          [
            land['id'],
            land['name'],
            land['area'],
            land['created_at'],
            land['updated_at'],
          ],
        );
      }
    });
  }

  static ({
    List<Map<String, dynamic>> seasons,
    List<Map<String, dynamic>> transactions,
    List<Map<String, dynamic>> yieldLogs,
    List<Map<String, dynamic>> lands,
  }) parseAndValidateBackup(String content) {
    final data = jsonDecode(content);

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid backup: Root is not a JSON object');
    }

    if (data['version'] != 1) {
      throw Exception('Unsupported backup version: ${data['version']}');
    }

    if (data['seasons'] is! List || data['transactions'] is! List) {
      throw Exception(
          'Invalid backup format: missing seasons or transactions lists');
    }

    final seasonsOut = <Map<String, dynamic>>[];
    for (final season in data['seasons'] as List<dynamic>) {
      if (season is! Map<String, dynamic>) continue;
      final cropType = validateEnum(
        season['crop_type'],
        CropType.values.map((e) => e.value).toSet(),
        'Crop Type',
      );
      final status = validateEnum(
        season['status'],
        SeasonStatus.values.map((e) => e.value).toSet(),
        'Status',
      );
      final landArea = validatePositiveNum(season['land_area'], 'Land Area');
      seasonsOut.add({
        'id': validateString(season['id'], 'Season ID'),
        'name': validateString(season['name'], 'Season Name'),
        'crop_type': cropType,
        'land_area': landArea,
        'start_date': validateIsoDate(season['start_date'], 'Start Date'),
        'end_date': season['end_date'] != null
            ? validateIsoDate(season['end_date'], 'End Date')
            : null,
        'status': status,
        'created_at': validateIsoDate(season['created_at'], 'Created At'),
        'updated_at': validateIsoDate(season['updated_at'], 'Updated At'),
      });
    }

    final seasonIds = seasonsOut.map((s) => s['id'] as String).toSet();
    final txOut = <Map<String, dynamic>>[];
    for (final txn in data['transactions'] as List<dynamic>) {
      if (txn is! Map<String, dynamic>) continue;
      final amount = validateNonNegativeNum(txn['amount'], 'Amount');
      final type = validateEnum(
        txn['type'],
        TransactionType.values.map((e) => e.value).toSet(),
        'Type',
      );
      final seasonId = validateString(txn['season_id'], 'Season ID');
      if (!seasonIds.contains(seasonId)) {
        throw Exception(
            'Orphaned transaction references unknown season "$seasonId"');
      }
      txOut.add({
        'id': validateString(txn['id'], 'Transaction ID'),
        'season_id': seasonId,
        'amount': amount,
        'category': txn['category']?.toString() ?? 'Other',
        'date': validateIsoDate(txn['date'], 'Date'),
        'type': type,
        'notes': txn['notes']?.toString(),
        'quantity': txn['quantity'] != null
            ? validateNonNegativeNum(txn['quantity'], 'Quantity')
            : null,
        'buyer_name': txn['buyer_name']?.toString(),
        'created_at': validateIsoDate(txn['created_at'], 'Created At'),
        'updated_at': validateIsoDate(txn['updated_at'], 'Updated At'),
      });
    }

    final txIds = txOut.map((t) => t['id'] as String).toSet();
    final yieldOut = <Map<String, dynamic>>[];
    final rawYields = (data['yield_logs'] as List<dynamic>?) ?? [];
    for (final log in rawYields) {
      if (log is! Map<String, dynamic>) continue;
      final totalWeight =
          validatePositiveNum(log['total_weight'], 'Total Weight');
      final unit = validateEnum(
        log['unit'],
        YieldUnit.values.map((e) => e.value).toSet(),
        'Unit',
      );
      final disposition = validateEnum(
        log['disposition'] ?? YieldDisposition.sold.value,
        YieldDisposition.values.map((e) => e.value).toSet(),
        'Disposition',
      );
      final seasonId = validateString(log['season_id'], 'Season ID');
      if (!seasonIds.contains(seasonId)) {
        throw Exception(
            'Orphaned yield log references unknown season "$seasonId"');
      }
      final linkedTxId = log['transaction_id']?.toString();
      if (linkedTxId != null &&
          linkedTxId.isNotEmpty &&
          !txIds.contains(linkedTxId)) {
        throw Exception(
            'Yield log references missing transaction "$linkedTxId"');
      }
      yieldOut.add({
        'id': validateString(log['id'], 'Yield Log ID'),
        'season_id': seasonId,
        'total_weight': totalWeight,
        'unit': unit,
        'disposition': disposition,
        'sale_price': log['sale_price'] != null
            ? validateNonNegativeNum(log['sale_price'], 'Sale Price')
            : null,
        'destination': log['destination']?.toString(),
        'transaction_id':
            (linkedTxId != null && linkedTxId.isNotEmpty) ? linkedTxId : null,
        'date': validateIsoDate(log['date'], 'Date'),
        'created_at': validateIsoDate(log['created_at'], 'Created At'),
        'updated_at': validateIsoDate(log['updated_at'], 'Updated At'),
      });
    }

    final landsOut = <Map<String, dynamic>>[];
    final rawLands = (data['lands'] as List<dynamic>?) ?? [];
    for (final land in rawLands) {
      if (land is! Map<String, dynamic>) continue;
      landsOut.add({
        'id': validateString(land['id'], 'Land ID'),
        'name': validateString(land['name'], 'Land Name'),
        'area': validatePositiveNum(land['area'], 'Land Area'),
        'created_at': validateIsoDate(land['created_at'], 'Created At'),
        'updated_at': validateIsoDate(land['updated_at'], 'Updated At'),
      });
    }

    return (
      seasons: seasonsOut,
      transactions: txOut,
      yieldLogs: yieldOut,
      lands: landsOut,
    );
  }

  static String validateString(dynamic value, String fieldName) {
    if (value is! String || value.trim().isEmpty) {
      throw Exception('Invalid or missing $fieldName in backup');
    }
    return value;
  }

  static double validatePositiveNum(dynamic value, String fieldName) {
    if (value is! num || !value.isFinite || value <= 0) {
      throw Exception('Invalid or non-positive $fieldName in backup');
    }
    return value.toDouble();
  }

  static double validateNonNegativeNum(dynamic value, String fieldName) {
    if (value is! num || !value.isFinite || value < 0) {
      throw Exception('Invalid or negative $fieldName in backup');
    }
    return value.toDouble();
  }

  static String validateEnum(
      dynamic value, Set<String> allowed, String fieldName) {
    final s = validateString(value, fieldName);
    if (!allowed.contains(s)) {
      throw Exception('Unsupported $fieldName value "$s" in backup');
    }
    return s;
  }

  static String validateIsoDate(dynamic value, String fieldName) {
    final s = validateString(value, fieldName);
    if (DateTime.tryParse(s) == null) {
      throw Exception('Invalid date format for $fieldName in backup');
    }
    return s;
  }
}
