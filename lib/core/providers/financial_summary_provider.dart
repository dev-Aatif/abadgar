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

FinancialSummary summarizeSeasonRows(
  List<Transaction> transactions,
  List<YieldLog> yieldLogs,
) {
  double revenue = 0;
  double expenses = 0;
  final Map<String, double> catExpenses = {};

  for (final tx in transactions) {
    if (tx.type == TransactionType.revenue ||
        tx.type == TransactionType.yield_) {
      revenue += tx.amount;
    } else {
      expenses += tx.amount;
      final cat = tx.category ?? 'Other';
      catExpenses[cat] = (catExpenses[cat] ?? 0) + tx.amount;
    }
  }

  // YieldLogs track physical harvest output; revenue is recorded via linked transactions.
  double totalWeightKg = 0;
  for (final yl in yieldLogs) {
    totalWeightKg += yl.unit.toKg(yl.totalWeight);
  }

  return FinancialSummary(
    totalRevenue: revenue,
    totalExpenses: expenses,
    expenseByCategory: catExpenses,
    transactionCount: transactions.length + yieldLogs.length,
    totalYieldWeight: totalWeightKg,
  );
}

@riverpod
FinancialSummary? financialSummary(FinancialSummaryRef ref) {
  final transactionsAsync = ref.watch(activeSeasonTransactionsProvider);
  final yieldLogsAsync = ref.watch(activeSeasonYieldLogsProvider);

  if (transactionsAsync is! AsyncData || yieldLogsAsync is! AsyncData) {
    return null;
  }

  return summarizeSeasonRows(
    transactionsAsync.value ?? const [],
    yieldLogsAsync.value ?? const [],
  );
}
