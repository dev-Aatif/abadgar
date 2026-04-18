import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/transaction.dart';
import '../database/database_provider.dart';
import 'active_season_provider.dart';
import 'transaction_repository_provider.dart';

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
Stream<List<Transaction>> allTransactions(AllTransactionsRef ref) async* {
  final db = await ref.watch(powerSyncDatabaseProvider.future);
  yield* db
      .watch('SELECT * FROM transactions ORDER BY date DESC')
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
      await ref.read(transactionRepositoryProvider).saveTransaction(
        seasonId: seasonId,
        amount: amount,
        category: category,
        date: date,
        type: type,
        notes: notes,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTransaction(String id) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(transactionRepositoryProvider).deleteTransaction(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
