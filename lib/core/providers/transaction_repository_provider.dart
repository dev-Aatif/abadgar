import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../database/database_provider.dart';
import '../database/transaction_repository.dart';

part 'transaction_repository_provider.g.dart';

@riverpod
TransactionRepository transactionRepository(TransactionRepositoryRef ref) {
  final db = ref.watch(powerSyncDatabaseProvider).valueOrNull;
  if (db == null) throw Exception('Database not initialized');
  return TransactionRepository(db);
}
