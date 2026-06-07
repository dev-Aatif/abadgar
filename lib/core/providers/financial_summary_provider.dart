import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'transactions_provider.dart';
import '../models/transaction.dart';
import '../models/yield_log.dart';
import '../constants/enums.dart';

part 'financial_summary_provider.g.dart';

class FinancialSummary {
  final double totalRevenue;
  final double totalExpenses;
  final Map<String, double> expenseByCategory;
  final int transactionCount;
  final double totalYieldWeight;
  
  double get profit => totalRevenue - totalExpenses;

  FinancialSummary({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.expenseByCategory,
    required this.transactionCount,
    this.totalYieldWeight = 0,
  });
}

@riverpod
FinancialSummary? financialSummary(FinancialSummaryRef ref) {
  final transactionsAsync = ref.watch(activeSeasonTransactionsProvider);
  final yieldLogsAsync = ref.watch(activeSeasonYieldLogsProvider);
  
  if (transactionsAsync is! AsyncData || yieldLogsAsync is! AsyncData) {
    return null;
  }

  final List<Transaction> transactions = transactionsAsync.value ?? [];
  final List<YieldLog> yieldLogs = yieldLogsAsync.value ?? [];

  double revenue = 0;
  double expenses = 0;
  final Map<String, double> catExpenses = {};
  
  for (final tx in transactions) {
    if (tx.type == TransactionType.revenue || tx.type == TransactionType.yield_) {
      revenue += tx.amount;
    } else {
      expenses += tx.amount;
      catExpenses[tx.category ?? 'Other'] = (catExpenses[tx.category ?? 'Other'] ?? 0) + tx.amount;
    }
  }

  // NOTE: We no longer add yieldLogs.salePrice here because the Log Harvest workflow 
  // already creates a corresponding 'revenue' transaction to ensure ledger consistency.
  // YieldLogs are now strictly for physical harvest tracking.
  
  double totalWeight = 0;
  for (final yl in yieldLogs) {
    totalWeight += yl.totalWeight;
  }
  
  return FinancialSummary(
    totalRevenue: revenue,
    totalExpenses: expenses,
    expenseByCategory: catExpenses,
    transactionCount: transactions.length + yieldLogs.length,
    totalYieldWeight: totalWeight,
  );
}
