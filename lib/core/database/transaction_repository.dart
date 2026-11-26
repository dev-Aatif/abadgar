import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart' as model;
import '../models/yield_log.dart';

class TransactionRepository {
  final PowerSyncDatabase _db;
  final _uuid = const Uuid();

  TransactionRepository(this._db);

  Future<void> saveTransaction({
    required String seasonId,
    required double amount,
    required String type,
    String? category,
    String? notes,
    double? quantity,
    String? buyerName,
    required DateTime date,
  }) async {
    final now = DateTime.now().toIso8601String();
    final id = _uuid.v4();

    await _db.execute(
      '''
      INSERT INTO transactions (id, season_id, amount, type, date, category, notes, quantity, buyer_name, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        id,
        seasonId,
        amount,
        type,
        date.toIso8601String(),
        category,
        notes,
        quantity,
        buyerName,
        now,
        now,
      ],
    );
  }

  Future<void> updateTransaction({
    required String id,
    required double amount,
    required String type,
    String? category,
    String? notes,
    double? quantity,
    String? buyerName,
    required DateTime date,
  }) async {
    final now = DateTime.now().toIso8601String();
    final isoDate = date.toIso8601String();

    await _db.writeTransaction((tx) async {
      await tx.execute(
        '''
        UPDATE transactions 
        SET amount = ?, type = ?, date = ?, category = ?, notes = ?, quantity = ?, buyer_name = ?, updated_at = ?
        WHERE id = ?
        ''',
        [
          amount,
          type,
          isoDate,
          category,
          notes,
          quantity,
          buyerName,
          now,
          id,
        ],
      );

      // Keep any harvest log linked to this transaction consistent.
      if (type == 'Revenue') {
        await tx.execute(
          '''
          UPDATE yield_logs
          SET sale_price = ?, date = ?, updated_at = ?
          WHERE transaction_id = ?
          ''',
          [amount, isoDate, now, id],
        );
      } else {
        await tx.execute(
          'UPDATE yield_logs SET transaction_id = NULL, updated_at = ? WHERE transaction_id = ?',
          [now, id],
        );
      }
    });
  }

  Future<void> saveYieldLog({
    required String seasonId,
    required double totalWeight,
    required String unit,
    required String disposition,
    double? salePrice,
    String? destination,
    required DateTime date,
  }) async {
    final now = DateTime.now().toIso8601String();
    final yieldId = _uuid.v4();
    final shouldLinkRevenue =
        disposition == 'Sold' && salePrice != null && salePrice > 0;
    final transactionId = shouldLinkRevenue ? _uuid.v4() : null;

    await _db.writeTransaction((tx) async {
      if (transactionId != null) {
        await tx.execute(
          '''
          INSERT INTO transactions (id, season_id, amount, type, date, category, notes, quantity, buyer_name, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            transactionId,
            seasonId,
            salePrice,
            'Revenue',
            date.toIso8601String(),
            'Harvest Sale',
            'Yield: $totalWeight $unit',
            null,
            null,
            now,
            now,
          ],
        );
      }

      await tx.execute(
        '''
        INSERT INTO yield_logs (id, season_id, total_weight, unit, disposition, sale_price, destination, transaction_id, date, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          yieldId,
          seasonId,
          totalWeight,
          unit,
          disposition,
          salePrice,
          destination,
          transactionId,
          date.toIso8601String(),
          now,
          now,
        ],
      );
    });
  }

  Future<String?> deleteTransaction(String id) async {
    String? linkedYieldId;
    await _db.writeTransaction((tx) async {
      final linkedRows = await tx.getAll(
        'SELECT id FROM yield_logs WHERE transaction_id = ? LIMIT 1',
        [id],
      );
      if (linkedRows.isNotEmpty) {
        linkedYieldId = linkedRows.first['id'] as String?;
      }
      await tx.execute(
        'UPDATE yield_logs SET transaction_id = NULL WHERE transaction_id = ?',
        [id],
      );
      await tx.execute('DELETE FROM transactions WHERE id = ?', [id]);
    });
    return linkedYieldId;
  }

  Future<void> restoreTransaction({
    required model.Transaction transaction,
    String? linkedYieldLogId,
  }) async {
    await _db.writeTransaction((tx) async {
      await tx.execute(
        '''
        INSERT OR REPLACE INTO transactions (id, season_id, amount, type, date, category, notes, quantity, buyer_name, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          transaction.id,
          transaction.seasonId,
          transaction.amount,
          transaction.type.value,
          transaction.date.toIso8601String(),
          transaction.category,
          transaction.notes,
          transaction.quantity,
          transaction.buyerName,
          transaction.createdAt.toIso8601String(),
          DateTime.now().toIso8601String(),
        ],
      );
      if (linkedYieldLogId != null) {
        await tx.execute(
          'UPDATE yield_logs SET transaction_id = ? WHERE id = ?',
          [transaction.id, linkedYieldLogId],
        );
      }
    });
  }

  Future<void> updateYieldLog({
    required String id,
    required double totalWeight,
    required String unit,
    required String disposition,
    double? salePrice,
    String? destination,
    required DateTime date,
  }) async {
    final now = DateTime.now().toIso8601String();
    final shouldLinkRevenue =
        disposition == 'Sold' && salePrice != null && salePrice > 0;

    await _db.writeTransaction((tx) async {
      final rows = await tx.getAll(
        'SELECT season_id, transaction_id FROM yield_logs WHERE id = ?',
        [id],
      );
      if (rows.isEmpty) return;

      final seasonId = rows.first['season_id'] as String;
      var transactionId = rows.first['transaction_id'] as String?;

      if (shouldLinkRevenue) {
        if (transactionId != null) {
          await tx.execute(
            '''
            UPDATE transactions
            SET amount = ?, notes = ?, date = ?, updated_at = ?
            WHERE id = ?
            ''',
            [
              salePrice,
              'Yield: $totalWeight $unit',
              date.toIso8601String(),
              now,
              transactionId,
            ],
          );
        } else {
          transactionId = _uuid.v4();
          await tx.execute(
            '''
            INSERT INTO transactions (id, season_id, amount, type, date, category, notes, quantity, buyer_name, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''',
            [
              transactionId,
              seasonId,
              salePrice,
              'Revenue',
              date.toIso8601String(),
              'Harvest Sale',
              'Yield: $totalWeight $unit',
              null,
              null,
              now,
              now,
            ],
          );
        }
      } else if (transactionId != null) {
        await tx
            .execute('DELETE FROM transactions WHERE id = ?', [transactionId]);
        transactionId = null;
      }

      await tx.execute(
        '''
        UPDATE yield_logs 
        SET total_weight = ?, unit = ?, disposition = ?, sale_price = ?, destination = ?, transaction_id = ?, date = ?, updated_at = ?
        WHERE id = ?
        ''',
        [
          totalWeight,
          unit,
          disposition,
          salePrice,
          destination,
          transactionId,
          date.toIso8601String(),
          now,
          id,
        ],
      );
    });
  }

  Future<model.Transaction?> deleteYieldLog(String id) async {
    model.Transaction? linkedTransaction;
    await _db.writeTransaction((tx) async {
      final rows = await tx.getAll(
        'SELECT transaction_id FROM yield_logs WHERE id = ?',
        [id],
      );
      final transactionId =
          rows.isNotEmpty ? rows.first['transaction_id'] as String? : null;

      if (transactionId != null) {
        final txRows = await tx.getAll(
          'SELECT * FROM transactions WHERE id = ? LIMIT 1',
          [transactionId],
        );
        if (txRows.isNotEmpty) {
          linkedTransaction = model.Transaction.fromRow(txRows.first);
        }
      }

      await tx.execute('DELETE FROM yield_logs WHERE id = ?', [id]);
      if (transactionId != null) {
        await tx
            .execute('DELETE FROM transactions WHERE id = ?', [transactionId]);
      }
    });
    return linkedTransaction;
  }

  Future<void> restoreYieldLog({
    required YieldLog log,
    model.Transaction? linkedTransaction,
  }) async {
    final now = DateTime.now().toIso8601String();
    await _db.writeTransaction((tx) async {
      if (linkedTransaction != null) {
        await tx.execute(
          '''
          INSERT OR REPLACE INTO transactions (id, season_id, amount, type, date, category, notes, quantity, buyer_name, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            linkedTransaction.id,
            linkedTransaction.seasonId,
            linkedTransaction.amount,
            linkedTransaction.type.value,
            linkedTransaction.date.toIso8601String(),
            linkedTransaction.category,
            linkedTransaction.notes,
            linkedTransaction.quantity,
            linkedTransaction.buyerName,
            linkedTransaction.createdAt.toIso8601String(),
            now,
          ],
        );
      }

      await tx.execute(
        '''
        INSERT OR REPLACE INTO yield_logs (id, season_id, total_weight, unit, disposition, sale_price, destination, transaction_id, date, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          log.id,
          log.seasonId,
          log.totalWeight,
          log.unit.value,
          log.disposition.value,
          log.salePrice,
          log.destination,
          linkedTransaction?.id,
          log.date.toIso8601String(),
          log.createdAt.toIso8601String(),
          now,
        ],
      );
    });
  }
}
