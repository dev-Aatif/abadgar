import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

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

  Future<void> saveYieldLog({
    required String seasonId,
    required double totalWeight,
    required String unit,
    required DateTime date,
  }) async {
    final now = DateTime.now().toIso8601String();
    final id = _uuid.v4();

    await _db.execute(
      '''
      INSERT INTO yield_logs (id, season_id, total_weight, unit, date, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        id,
        seasonId,
        totalWeight,
        unit,
        date.toIso8601String(),
        now,
        now,
      ],
    );
  }
}
