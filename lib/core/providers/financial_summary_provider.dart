import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'transactions_provider.dart';

part 'financial_summary_provider.g.dart';

class FinancialSummary {
  final double totalRevenue;
  final double totalExpenses;
  final Map<String, double> expenseByCategory;
  final int transactionCount;
  
  double get profit => totalRevenue - totalExpenses;

  FinancialSummary({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.expenseByCategory,
    required this.transactionCount,
  });
}

@riverpod
FinancialSummary? financialSummary(FinancialSummaryRef ref) {
  final transactionsAsync = ref.watch(activeSeasonTransactionsProvider);
  
  return transactionsAsync.when(
    data: (transactions) {
      double revenue = 0;
      double expenses = 0;
      final Map<String, double> catExpenses = {};
      
      for (final tx in transactions) {
        if (tx.type == 'Revenue' || tx.type == 'Yield') {
          revenue += tx.amount;
        } else {
          expenses += tx.amount;
          catExpenses[tx.category ?? 'Other'] = (catExpenses[tx.category ?? 'Other'] ?? 0) + tx.amount;
        }
      }
      
      return FinancialSummary(
        totalRevenue: revenue,
        totalExpenses: expenses,
        expenseByCategory: catExpenses,
        transactionCount: transactions.length,
      );
    },
    loading: () => null,
    error: (_, __) => null,
  );
}
