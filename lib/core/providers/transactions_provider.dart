import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../database/database_provider.dart';
import 'active_season_provider.dart';

part 'transactions_provider.g.dart';

@riverpod
Stream<List<Transaction>> activeSeasonTransactions(ActiveSeasonTransactionsRef ref) async* {
  final seasonId = ref.watch(activeSeasonIdProvider);
  if (seasonId == null) {
    yield [];
    return;
  }

  final db = await ref.watch(powerSyncDatabaseProvider.future);
  yield* db
      .watch('SELECT * FROM transactions WHERE season_id = ? ORDER BY date DESC', parameters: [seasonId])
      .map((rows) => rows.map((row) => Transaction.fromRow(row)).toList());
}

@riverpod
class TransactionsNotifier extends _$TransactionsNotifier {
  @override
  FutureOr<void> build() async {}

  Future<void> addTransaction({
    required String seasonId,
    required double amount,
    required String category,
    required DateTime date,
    required String type,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final db = await ref.read(powerSyncDatabaseProvider.future);
      final id = const Uuid().v4();
      final now = DateTime.now();

      await db.execute(
        'INSERT INTO transactions(id, season_id, amount, category, date, type, notes, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          id,
          seasonId,
          amount,
          category,
          date.toIso8601String(),
          type,
          notes,
          now.toIso8601String(),
          now.toIso8601String(),
        ],
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTransaction(String id) async {
    state = const AsyncValue.loading();
    try {
      final db = await ref.read(powerSyncDatabaseProvider.future);
      await db.execute('DELETE FROM transactions WHERE id = ?', [id]);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
