import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'transactions_provider.dart';

part 'financial_summary_provider.g.dart';

class FinancialSummary {
  final double totalRevenue;
  final double totalExpenses;
  double get profit => totalRevenue - totalExpenses;

  FinancialSummary({required this.totalRevenue, required this.totalExpenses});
}

@riverpod
FinancialSummary? financialSummary(FinancialSummaryRef ref) {
  final transactionsAsync = ref.watch(activeSeasonTransactionsProvider);
  
  return transactionsAsync.when(
    data: (transactions) {
      double revenue = 0;
      double expenses = 0;
      
      for (final tx in transactions) {
        if (tx.type == 'Revenue') {
          revenue += tx.amount;
        } else {
          expenses += tx.amount;
        }
      }
      
      return FinancialSummary(totalRevenue: revenue, totalExpenses: expenses);
    },
    loading: () => null,
    error: (_, __) => null,
  );
}
