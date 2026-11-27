import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqlite_async/sqlite_async.dart';
import 'active_season_provider.dart';
import 'seasons_provider.dart';
import 'financial_summary_provider.dart';
import '../models/season.dart';
import '../models/transaction.dart';
import '../models/yield_log.dart';
import '../database/database_provider.dart';
import '../constants/enums.dart';

export 'financial_summary_provider.dart' show summarizeSeasonRows;

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

  double get profitVariance =>
      (previousSummary != null && previousSummary!.profit != 0)
          ? (currentSummary.profit - previousSummary!.profit) /
              previousSummary!.profit.abs()
          : 0;

  double get yieldVariance => (previousSummary != null &&
          previousSummary!.totalYieldWeight > 0)
      ? (currentSummary.totalYieldWeight - previousSummary!.totalYieldWeight) /
          previousSummary!.totalYieldWeight
      : 0;
}

@riverpod
Future<SeasonComparison?> seasonComparison(
    SeasonComparisonRef ref, String seasonId) async {
  final activeId = ref.watch(activeSeasonIdProvider);
  final activeSummary =
      seasonId == activeId ? ref.watch(financialSummaryProvider) : null;
  final seasonsFuture = ref.watch(seasonsProvider.future);
  final currentSummaryFuture = activeSummary == null
      ? ref.watch(seasonSummaryProvider(seasonId).future)
      : null;
  final dbFuture = ref.watch(localDatabaseProvider.future);

  final seasons = await seasonsFuture;
  if (seasons.isEmpty) return null;

  final currentSeason = seasons.where((s) => s.id == seasonId).firstOrNull;
  if (currentSeason == null) return null;

  // Find previous season of the SAME crop (tie-break same startDate by createdAt)
  final previousSeason = seasons
      .where(
        (s) =>
            s.id != currentSeason.id &&
            s.cropType == currentSeason.cropType &&
            (s.startDate.isBefore(currentSeason.startDate) ||
                (s.startDate.isAtSameMomentAs(currentSeason.startDate) &&
                    s.createdAt.isBefore(currentSeason.createdAt))),
      )
      .firstOrNull;

  final FinancialSummary currentSummary =
      activeSummary ?? await currentSummaryFuture!;
  FinancialSummary? previousSummary;
  if (previousSeason != null) {
    final db = await dbFuture;
    previousSummary = await _loadSeasonSummaryOnce(db, previousSeason.id);
  }

  return SeasonComparison(
    currentSeason: currentSeason,
    previousSeason: previousSeason,
    currentSummary: currentSummary,
    previousSummary: previousSummary,
  );
}

Future<FinancialSummary> _loadSeasonSummaryOnce(
    SqliteDatabase db, String seasonId) async {
  final txRows = await db.getAll(
    'SELECT * FROM transactions WHERE season_id = ?',
    [seasonId],
  );
  final yieldRows = await db.getAll(
    'SELECT * FROM yield_logs WHERE season_id = ?',
    [seasonId],
  );
  return summarizeSeasonRows(
    txRows.map(Transaction.fromRow).toList(),
    yieldRows.map(YieldLog.fromRow).toList(),
  );
}

Stream<FinancialSummary> _watchSeasonSummary(
    SqliteDatabase db, String seasonId) {
  late StreamController<FinancialSummary> controller;
  StreamSubscription? txSub;
  StreamSubscription? yieldSub;

  List<Transaction> latestTransactions = const [];
  List<YieldLog> latestYields = const [];
  var hasTx = false;
  var hasYield = false;

  void emitIfReady() {
    if (hasTx && hasYield && !controller.isClosed) {
      controller.add(summarizeSeasonRows(latestTransactions, latestYields));
    }
  }

  controller = StreamController<FinancialSummary>(
    onListen: () {
      txSub = db.watch('SELECT * FROM transactions WHERE season_id = ?',
          parameters: [seasonId]).listen(
        (rows) {
          latestTransactions = rows.map(Transaction.fromRow).toList();
          hasTx = true;
          emitIfReady();
        },
        onError: (Object e, StackTrace st) {
          if (!controller.isClosed) controller.addError(e, st);
        },
      );
      yieldSub = db.watch('SELECT * FROM yield_logs WHERE season_id = ?',
          parameters: [seasonId]).listen(
        (rows) {
          latestYields = rows.map(YieldLog.fromRow).toList();
          hasYield = true;
          emitIfReady();
        },
        onError: (Object e, StackTrace st) {
          if (!controller.isClosed) controller.addError(e, st);
        },
      );
    },
    onCancel: () async {
      await txSub?.cancel();
      await yieldSub?.cancel();
    },
  );

  return controller.stream;
}

// Generalized summary provider watching both transactions and yield logs
@riverpod
Stream<FinancialSummary> seasonSummary(
    SeasonSummaryRef ref, String seasonId) async* {
  final db = await ref.watch(localDatabaseProvider.future);
  yield* _watchSeasonSummary(db, seasonId);
}

class SeasonTrendData {
  final Season season;
  final FinancialSummary summary;

  SeasonTrendData(this.season, this.summary);
}

@riverpod
Stream<List<SeasonTrendData>> multiYearTrend(MultiYearTrendRef ref) async* {
  final db = await ref.watch(localDatabaseProvider.future);

  Future<List<SeasonTrendData>> load() async {
    final seasonRows = await db.getAll(
      "SELECT * FROM seasons WHERE status = ? ORDER BY start_date ASC",
      [SeasonStatus.completed.value],
    );
    if (seasonRows.isEmpty) return [];

    final completedSeasons = seasonRows.map(Season.fromRow).toList();
    final txAggRows = await db.getAll('''
      SELECT season_id,
             SUM(CASE WHEN type IN ('Revenue', 'Yield') THEN amount ELSE 0 END) AS total_revenue,
             SUM(CASE WHEN type NOT IN ('Revenue', 'Yield') THEN amount ELSE 0 END) AS total_expenses,
             COUNT(*) AS tx_count
      FROM transactions
      GROUP BY season_id
    ''');

    final Map<String, Map<String, num>> txBySeason = {
      for (final row in txAggRows)
        row['season_id'] as String: {
          'rev': (row['total_revenue'] as num?) ?? 0,
          'exp': (row['total_expenses'] as num?) ?? 0,
          'cnt': (row['tx_count'] as num?) ?? 0,
        },
    };

    return completedSeasons.map((season) {
      final agg = txBySeason[season.id];
      final summary = FinancialSummary(
        totalRevenue: (agg?['rev'] ?? 0).toDouble(),
        totalExpenses: (agg?['exp'] ?? 0).toDouble(),
        expenseByCategory: const {},
        transactionCount: (agg?['cnt'] ?? 0).toInt(),
      );
      return SeasonTrendData(season, summary);
    }).toList();
  }

  yield await load();
  await for (final _ in db.onChange(
    const {'seasons', 'transactions'},
    triggerImmediately: false,
  )) {
    yield await load();
  }
}
