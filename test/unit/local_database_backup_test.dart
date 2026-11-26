import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite_async/sqlite_async.dart';
import 'package:abadgar/core/database/local_migrations.dart';
import 'package:abadgar/core/database/transaction_repository.dart';
import 'package:abadgar/core/models/transaction.dart';
import 'package:abadgar/core/models/yield_log.dart';
import 'package:abadgar/core/services/autosave_service.dart';
import 'package:abadgar/core/services/backup_crypto.dart';
import 'package:abadgar/core/services/export_service.dart';
import 'package:abadgar/core/services/import_service.dart';

void main() {
  late Directory tempDir;
  late SqliteDatabase db;
  late TransactionRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('abadgar_db_test_');
    db = SqliteDatabase(path: p.join(tempDir.path, 'test.db'));
    await db.initialize();
    await db.execute('PRAGMA foreign_keys = ON;');
    await localMigrations.migrate(db);
    repo = TransactionRepository(db);

    final now = DateTime(2026, 5, 1).toIso8601String();
    await db.execute(
      '''
      INSERT INTO seasons(id, name, crop_type, land_area, start_date, status, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      ['s1', 'Wheat 2026', 'Wheat', 10.0, now, 'Active', now, now],
    );
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('TransactionRepository + local SQLite integrity', () {
    test(
        'saveYieldLog links revenue transaction, updateTransaction syncs sale_price, and Undo restores exact link',
        () async {
      final date = DateTime(2026, 5, 10);
      await repo.saveYieldLog(
        seasonId: 's1',
        totalWeight: 20,
        unit: 'Mund (40kg)',
        disposition: 'Sold',
        salePrice: 80000,
        date: date,
      );

      final yields = await db.getAll('SELECT * FROM yield_logs');
      final txns = await db.getAll('SELECT * FROM transactions');
      expect(yields.length, 1);
      expect(txns.length, 1);
      final yieldRow = YieldLog.fromRow(yields.first);
      final txRow = Transaction.fromRow(txns.first);
      expect(yields.first['transaction_id'], txRow.id);

      // Update transaction amount -> linked yield_log sale_price stays in sync
      await repo.updateTransaction(
        id: txRow.id,
        amount: 85000,
        type: 'Revenue',
        category: txRow.category,
        notes: txRow.notes,
        date: date,
      );
      final updatedYield = await db.getAll(
          'SELECT sale_price FROM yield_logs WHERE id = ?', [yieldRow.id]);
      expect(updatedYield.first['sale_price'], 85000.0);

      // Delete transaction and Undo -> exact ID & link restored
      final linkedYieldId = await repo.deleteTransaction(txRow.id);
      expect(linkedYieldId, yieldRow.id);
      expect(await db.getAll('SELECT * FROM transactions'), isEmpty);

      await repo.restoreTransaction(
        transaction: txRow.copyWith(amount: 85000),
        linkedYieldLogId: linkedYieldId,
      );
      final restoredYield = await db.getAll(
          'SELECT transaction_id FROM yield_logs WHERE id = ?', [yieldRow.id]);
      expect(restoredYield.first['transaction_id'], txRow.id);

      // Delete yield log and Undo -> both yield log and linked transaction restored
      final deletedLinkedTx = await repo.deleteYieldLog(yieldRow.id);
      expect(deletedLinkedTx?.id, txRow.id);
      expect(await db.getAll('SELECT * FROM yield_logs'), isEmpty);
      expect(await db.getAll('SELECT * FROM transactions'), isEmpty);

      await repo.restoreYieldLog(
          log: yieldRow, linkedTransaction: deletedLinkedTx);
      expect((await db.getAll('SELECT * FROM yield_logs')).length, 1);
      expect((await db.getAll('SELECT * FROM transactions')).length, 1);
    });

    test(
        'AutoSaveService writes snapshots, rotates at maxSnapshots, and restores cleanly without cascading deletes',
        () async {
      await repo.saveTransaction(
        seasonId: 's1',
        amount: 5000,
        type: 'Expense',
        category: 'Fertilizer',
        date: DateTime(2026, 5, 2),
      );

      final autoSave =
          AutoSaveService(db, directoryOverride: () async => tempDir);
      final wrote = await autoSave.triggerBackup();
      expect(wrote, isTrue);

      final backups = await autoSave.listBackups();
      expect(backups.length, 1);
      expect(backups.first.seasonCount, 1);
      expect(backups.first.transactionCount, 1);

      // Wipe transactions and verify restore brings them back via ON CONFLICT DO UPDATE
      await db.execute('DELETE FROM transactions');
      expect(await db.getAll('SELECT * FROM transactions'), isEmpty);

      await autoSave.restoreBackup(backups.first.file);
      expect((await db.getAll('SELECT * FROM transactions')).length, 1);

      // Verify point-in-time restore removes post-backup transactions atomically
      await repo.saveTransaction(
        seasonId: 's1',
        amount: 9999,
        type: 'Expense',
        category: 'Fuel',
        date: DateTime(2026, 5, 3),
      );
      expect((await db.getAll('SELECT * FROM transactions')).length, 2);

      final raw = await backups.first.file.readAsString();
      await ImportService(db).restoreFromJsonString(raw);
      final restoredTxns = await db.getAll('SELECT * FROM transactions');
      expect(restoredTxns.length, 1);
      expect(restoredTxns.first['amount'], 5000.0);
    });

    test('ExportService encrypted backup round-trips cleanly via Isolate',
        () async {
      await repo.saveYieldLog(
        seasonId: 's1',
        totalWeight: 12,
        unit: 'Kharrar (800kg)',
        disposition: 'Sold',
        salePrice: 240000,
        date: DateTime(2026, 5, 15),
      );

      final encrypted =
          await ExportService(db).getBackupData(passphrase: 'secret-123');
      expect(BackupCrypto.isEncryptedEnvelope(encrypted), isTrue);

      await db.execute('DELETE FROM seasons');
      expect(await db.getAll('SELECT * FROM transactions'), isEmpty);

      final decrypted =
          await BackupCrypto.decryptJsonAsync(encrypted, 'secret-123');
      await ImportService(db).restoreFromJsonString(decrypted);

      expect((await db.getAll('SELECT * FROM seasons')).length, 1);
      expect((await db.getAll('SELECT * FROM yield_logs')).length, 1);
      expect((await db.getAll('SELECT * FROM transactions')).length, 1);
    });
  });
}
