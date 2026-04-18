import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'transactions_provider.dart';
import '../models/transaction.dart';

part 'analytics_provider.g.dart';

class CategoryYearData {
  final String category;
  final Map<int, double> yearlyTotals;
  CategoryYearData({required this.category, required this.yearlyTotals});
}

@riverpod
List<CategoryYearData> comparativeAnalytics(ComparativeAnalyticsRef ref) {
  final transactions = ref.watch(allTransactionsProvider).valueOrNull ?? [];
  
  // category -> year -> total
  final Map<String, Map<int, double>> groupings = {};

  for (final tx in transactions) {
    if (tx.category == null) continue;
    final year = tx.date.year;
    final cat = tx.category!;
    
    groupings.putIfAbsent(cat, () => {});
    groupings[cat]![year] = (groupings[cat]![year] ?? 0) + tx.amount;
  }

  return groupings.entries.map((e) => CategoryYearData(
    category: e.key,
    yearlyTotals: e.value,
  )).toList();
}
