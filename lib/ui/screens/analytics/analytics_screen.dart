import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/providers/comparison_provider.dart';
import '../../../core/providers/seasons_provider.dart';
import '../../../core/providers/analytics_selection_provider.dart';
import '../../../core/constants/app_colors.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonsAsync = ref.watch(seasonsProvider);
    final selectedSeasonId = ref.watch(analyticsSeasonSelectionProvider);
    
    final comparisonAsync = selectedSeasonId != null 
        ? ref.watch(seasonComparisonProvider(selectedSeasonId))
        : const AsyncValue<SeasonComparison?>.data(null);
    
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.seasonInsights, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (comparisonAsync.value != null)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: () => _shareReport(context, comparisonAsync.value),
            ),
          seasonsAsync.when(
            data: (seasons) => seasons.isEmpty 
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8.0),
                  child: DropdownButton<String>(
                    value: selectedSeasonId,
                    underline: const SizedBox.shrink(),
                    icon: const Icon(Icons.filter_list_rounded),
                    items: seasons.map((s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(s.displayName),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(analyticsSeasonSelectionProvider.notifier).setSeason(val);
                      }
                    },
                  ),
                ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: selectedSeasonId == null
        ? _buildNoSeasonState(context)
        : comparisonAsync.when(
            data: (comparison) => comparison == null 
              ? _buildNoDataState(context)
              : _buildAnalyticsBody(context, comparison, currencyFormat, ref),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text(AppLocalizations.of(context)!.errorGeneral(err.toString()))),
          ),
    );
  }

  Widget _buildAnalyticsBody(BuildContext context, SeasonComparison comparison, NumberFormat format, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSeasonHeader(context, comparison.currentSeason),
          const SizedBox(height: 24),
          _buildStatsGrid(context, comparison, format),
          const SizedBox(height: 32),
          _buildComparisonCard(context, comparison, format),
          if (comparison.previousSeason != null && comparison.previousSummary != null)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: _buildPerformanceGraph(context, comparison, format),
            ),
          const SizedBox(height: 32),
          _buildExpenseBreakdown(context, comparison, format),
          const SizedBox(height: 32),
          _buildMultiYearTrendGraph(context, ref),
          const SizedBox(height: 100), // Spacing for navbar
        ],
      ),
    );
  }

  Widget _buildSeasonHeader(BuildContext context, dynamic season) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          season.displayName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          AppLocalizations.of(context)!.detailedReport,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, SeasonComparison comparison, NumberFormat format) {
    final summary = comparison.currentSummary;
    final acres = comparison.currentSeason.landArea > 0 ? comparison.currentSeason.landArea : 1.0;
    final weightFormat = NumberFormat.decimalPattern();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(context, AppLocalizations.of(context)!.totalRevenue, format.format(summary.totalRevenue), Icons.payments_rounded, AppColors.revenue),
        _buildStatCard(context, AppLocalizations.of(context)!.totalExpenses, format.format(summary.totalExpenses), Icons.shopping_basket_rounded, AppColors.expense),
        _buildStatCard(context, AppLocalizations.of(context)!.netProfit, format.format(summary.profit), Icons.account_balance_rounded, summary.profit >= 0 ? AppColors.profit : AppColors.loss),
        _buildStatCard(context, AppLocalizations.of(context)!.costPerAcre, format.format(summary.totalExpenses / acres), Icons.landscape_rounded, Colors.brown),
        _buildStatCard(context, AppLocalizations.of(context)!.revenuePerAcre, format.format(summary.totalRevenue / acres), Icons.monetization_on_rounded, AppColors.revenue),
        _buildStatCard(context, AppLocalizations.of(context)!.yieldPerAcre, '${weightFormat.format(summary.totalYieldWeight / acres)} Unit', Icons.eco_rounded, AppColors.wheat),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(BuildContext context, SeasonComparison comparison, NumberFormat format) {
    if (comparison.previousSeason == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded),
            const SizedBox(width: 12),
            Expanded(child: Text(AppLocalizations.of(context)!.addAnotherSeason)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.smartComparison, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            comparison.profitVariance >= 0
                ? AppLocalizations.of(context)!.profitVarianceUp(
                    (comparison.profitVariance * 100).abs().toStringAsFixed(1),
                    comparison.previousSeason!.displayName)
                : AppLocalizations.of(context)!.profitVarianceDown(
                    (comparison.profitVariance * 100).abs().toStringAsFixed(1),
                    comparison.previousSeason!.displayName),
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseBreakdown(BuildContext context, SeasonComparison comparison, NumberFormat format) {
    final expenses = comparison.currentSummary.expenseByCategory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.expenseBreakdown, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        if (expenses.isEmpty)
           Center(child: Text(AppLocalizations.of(context)!.noExpenses))
        else
          ...expenses.entries.map((e) => _buildExpenseItem(context, e.key, e.value, comparison.currentSummary.totalExpenses, format)).toList(),
      ],
    );
  }

  Widget _buildExpenseItem(BuildContext context, String cat, double val, double total, NumberFormat format) {
    final percent = val / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(cat, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(format.format(val), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percent,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildNoSeasonState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.selectSeasonForAnalytics),
        ],
      ),
    );
  }

  Widget _buildNoDataState(BuildContext context) {
    return Center(child: Text(AppLocalizations.of(context)!.noDataFoundForSeason));
  }

  Widget _buildPerformanceGraph(BuildContext context, SeasonComparison comparison, NumberFormat format) {
    final curSummary = comparison.currentSummary;
    final prevSummary = comparison.previousSummary!;
    final curName = comparison.currentSeason.displayName;
    final prevName = comparison.previousSeason!.displayName;

    final maxY = [
      curSummary.totalRevenue,
      curSummary.totalExpenses,
      prevSummary.totalRevenue,
      prevSummary.totalExpenses,
    ].reduce((a, b) => a > b ? a : b);

    // If everything is 0, don't show graph
    if (maxY == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Year-over-Year Performance', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 24),
        SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY * 1.2,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      const style = TextStyle(fontSize: 12, fontWeight: FontWeight.bold);
                      Widget text;
                      switch (value.toInt()) {
                        case 0: text = Text(prevName, style: style); break;
                        case 1: text = Text(curName, style: style); break;
                        default: text = const Text(''); break;
                      }
                      return SideTitleWidget(axisSide: meta.axisSide, child: text);
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Text(
                        NumberFormat.compact().format(value),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(toY: prevSummary.totalRevenue, color: AppColors.revenue, width: 16, borderRadius: BorderRadius.circular(4)),
                    BarChartRodData(toY: prevSummary.totalExpenses, color: AppColors.expense, width: 16, borderRadius: BorderRadius.circular(4)),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(toY: curSummary.totalRevenue, color: AppColors.revenue, width: 16, borderRadius: BorderRadius.circular(4)),
                    BarChartRodData(toY: curSummary.totalExpenses, color: AppColors.expense, width: 16, borderRadius: BorderRadius.circular(4)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 12, height: 12, color: AppColors.revenue),
            const SizedBox(width: 4),
            const Text('Revenue', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 16),
            Container(width: 12, height: 12, color: AppColors.expense),
            const SizedBox(width: 4),
            const Text('Expenses', style: TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  void _shareReport(BuildContext context, SeasonComparison? comparison) {
    if (comparison == null) return;
    final format = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);
    final summary = comparison.currentSummary;
    final season = comparison.currentSeason;
    
    final text = '''
*Abadgar Season Report*
Season: ${season.displayName}
Crop: ${season.cropType.value}
Area: ${season.landArea} ${AppLocalizations.of(context)!.acresUnit}
Status: ${season.status.value}

*Financial Summary*
Total Revenue: ${format.format(summary.totalRevenue)}
Total Expenses: ${format.format(summary.totalExpenses)}
Net Profit: ${format.format(summary.profit)}

*Performance Metrics*
Cost / Acre: ${format.format(summary.totalExpenses / (season.landArea > 0 ? season.landArea : 1))}
Revenue / Acre: ${format.format(summary.totalRevenue / (season.landArea > 0 ? season.landArea : 1))}
Total Yield: ${NumberFormat.decimalPattern().format(summary.totalYieldWeight)}
Yield / Acre: ${NumberFormat.decimalPattern().format(summary.totalYieldWeight / (season.landArea > 0 ? season.landArea : 1))}

*Expense Breakdown*
${summary.expenseByCategory.entries.map((e) => '- ${e.key}: ${format.format(e.value)}').join('\n')}

Generated via Abadgar App.
''';
    Share.share(text);
  }
  Widget _buildMultiYearTrendGraph(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(multiYearTrendProvider);

    return trendAsync.when(
      data: (trendData) {
        if (trendData.length < 2) return const SizedBox.shrink(); // Not enough data for trend

        final spots = trendData.asMap().entries.map((e) {
          return FlSpot(e.key.toDouble(), e.value.summary.profit);
        }).toList();

        final maxProfit = trendData.map((e) => e.summary.profit).reduce((a, b) => a > b ? a : b);
        final minProfit = trendData.map((e) => e.summary.profit).reduce((a, b) => a < b ? a : b);
        
        final highestValue = maxProfit.abs() > minProfit.abs() ? maxProfit.abs() : minProfit.abs();
        final maxY = highestValue * 1.2;
        final minY = highestValue == 0 ? -1.0 : -maxY;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.multiYearTrend, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final int index = value.toInt();
                          if (index < 0 || index >= trendData.length) return const SizedBox.shrink();
                          final seasonName = trendData[index].season.displayName;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              seasonName.length > 5 ? seasonName.substring(0, 5) + '..' : seasonName,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                        reservedSize: 24,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const Text('0', style: TextStyle(fontSize: 10));
                          final formatted = NumberFormat.compact().format(value);
                          return Text(formatted, style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY / 2) == 0 ? 1 : maxY / 2,
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(AppLocalizations.of(context)!.errorLoadingTrends(e.toString()))),
    );
  }
}
