import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'seasons_provider.dart';
import 'transactions_provider.dart';
import 'financial_summary_provider.dart';
import '../models/season.dart';
import '../models/transaction.dart';
import '../database/database_provider.dart';
import '../constants/enums.dart';

part 'comparison_provider.g.dart';

class SeasonComparison {
  final Season currentSeason;
  final Season? previousSeason;
  final FinancialSummary currentSummary;
  final FinancialSummary? previousSummary;

  SeasonComparison({
    required this.currentSeason,
    this.previousSeason,
    required this.currentSummary,
    this.previousSummary,
  });

  double get profitVariance => (previousSummary != null && previousSummary!.profit != 0)
      ? (currentSummary.profit - previousSummary!.profit) / previousSummary!.profit.abs()
      : 0;

  double get yieldVariance => (previousSummary != null && previousSummary!.transactionCount > 0)
      ? (currentSummary.transactionCount - previousSummary!.transactionCount).toDouble() // Simplified for now
      : 0;
}

@riverpod
Future<SeasonComparison?> seasonComparison(SeasonComparisonRef ref, String seasonId) async {
  final seasons = await ref.watch(seasonsProvider.future);
  if (seasons.isEmpty) return null;

  final currentSeason = seasons.firstWhere((s) => s.id == seasonId);
  
  // Find previous season of the SAME crop
  final previousSeason = seasons.where((s) => 
    s.cropType == currentSeason.cropType && 
    s.startDate.isBefore(currentSeason.startDate)
  ).toList().firstOrNull;

  // We need a helper to get summary for a SPECIFIC season
  // Since financialSummary only watches ACTIVE season, we need to generalize it.
  
  final currentSummary = await ref.watch(seasonSummaryProvider(seasonId).future);
  FinancialSummary? previousSummary;
  if (previousSeason != null) {
    previousSummary = await ref.watch(seasonSummaryProvider(previousSeason.id).future);
  }

  return SeasonComparison(
    currentSeason: currentSeason,
    previousSeason: previousSeason,
    currentSummary: currentSummary,
    previousSummary: previousSummary,
  );
}

// Generalized summary provider
@riverpod
Stream<FinancialSummary> seasonSummary(SeasonSummaryRef ref, String seasonId) async* {
  final db = await ref.watch(powerSyncDatabaseProvider.future);
  
  yield* db.watch('SELECT * FROM transactions WHERE season_id = ?', parameters: [seasonId]).map((rows) {
    final transactions = rows.map((row) => Transaction.fromRow(row)).toList();
    
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
      
    return FinancialSummary(
      totalRevenue: revenue,
      totalExpenses: expenses,
      expenseByCategory: catExpenses,
      transactionCount: transactions.length,
    );
  });
}
