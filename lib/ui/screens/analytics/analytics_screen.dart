import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/enums.dart';
import '../../../core/providers/analytics_selection_provider.dart';
import '../../../core/providers/comparison_provider.dart';
import '../../../core/providers/seasons_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_helpers.dart';
import '../../widgets/app_selector.dart';
import '../../widgets/app_surface.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final seasonsAsync = ref.watch(seasonsProvider);
    final selectedSeasonId = ref.watch(analyticsSeasonSelectionProvider);
    final comparisonAsync = selectedSeasonId != null
        ? ref.watch(seasonComparisonProvider(selectedSeasonId))
        : const AsyncValue<SeasonComparison?>.data(null);
    final currencyFormat = NumberFormat.currency(
      locale: L10nHelpers.intlLocaleFor(context),
      symbol: 'Rs ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.seasonInsights),
        actions: [
          if (comparisonAsync.value != null)
            IconButton(
              tooltip: l10n.exportData,
              icon: const Icon(Icons.share_outlined),
              onPressed: () => _shareReport(context, comparisonAsync.value),
            ),
          seasonsAsync.when(
            data: (seasons) {
              if (seasons.isEmpty) return const SizedBox.shrink();
              final current = seasons.firstWhere(
                (s) => s.id == selectedSeasonId,
                orElse: () => seasons.first,
              );
              final cropColor = current.cropType == CropType.wheat
                  ? AppColors.wheatFor(context)
                  : AppColors.riceFor(context);

              return Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpace.sm),
                child: Center(
                  child: AppSelectorTrigger(
                    compact: true,
                    leading: Icon(
                      current.cropType == CropType.wheat
                          ? Icons.grass_rounded
                          : Icons.water_drop_rounded,
                      size: 15,
                      color: cropColor,
                    ),
                    label:
                        '${L10nHelpers.cropLabel(context, current.cropType)} ${current.startDate.year}',
                    onTap: () async {
                      final picked = await showAppSelectorSheet<String>(
                        context: context,
                        title: l10n.whichSeason,
                        selectedValue: current.id,
                        options: seasons.map((s) {
                          final sColor = s.cropType == CropType.wheat
                              ? AppColors.wheatFor(context)
                              : AppColors.riceFor(context);
                          return AppSelectorOption<String>(
                            value: s.id,
                            label:
                                '${L10nHelpers.cropLabel(context, s.cropType)} ${s.startDate.year}',
                            badge: '${s.landArea} ${l10n.acresUnitShort}',
                            leading: Icon(
                              s.cropType == CropType.wheat
                                  ? Icons.grass_rounded
                                  : Icons.water_drop_rounded,
                              color: sColor,
                              size: 20,
                            ),
                          );
                        }).toList(),
                      );
                      if (picked != null) {
                        ref
                            .read(analyticsSeasonSelectionProvider.notifier)
                            .setSeason(picked);
                      }
                    },
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: selectedSeasonId == null
          ? AppEmptyState(
              icon: Icons.insights_outlined,
              title: l10n.selectSeasonForAnalytics,
            )
          : comparisonAsync.when(
              data: (comparison) => comparison == null
                  ? AppEmptyState(
                      icon: Icons.insights_outlined,
                      title: l10n.noDataFoundForSeason,
                    )
                  : _AnalyticsBody(
                      comparison: comparison,
                      currencyFormat: currencyFormat,
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) =>
                  Center(child: Text(l10n.errorGeneral(err.toString()))),
            ),
    );
  }

  void _shareReport(BuildContext context, SeasonComparison? comparison) {
    if (comparison == null) return;
    final l10n = AppLocalizations.of(context)!;
    final intlLocale = L10nHelpers.intlLocaleFor(context);
    final format = NumberFormat.currency(
        locale: intlLocale, symbol: 'Rs ', decimalDigits: 0);
    final weightFormat = NumberFormat.decimalPattern(intlLocale);
    final summary = comparison.currentSummary;
    final season = comparison.currentSeason;
    final acres = season.landArea > 0 ? season.landArea : 1.0;

    final text = '''
*${l10n.appTitle} — ${L10nHelpers.cropLabel(context, season.cropType)} ${season.startDate.year}*
${l10n.areaLabel}: ${season.landArea} ${l10n.acresUnit}

${l10n.totalRevenue}: ${format.format(summary.totalRevenue)}
${l10n.totalExpenses}: ${format.format(summary.totalExpenses)}
${l10n.netProfit}: ${format.format(summary.profit)}

${l10n.costPerAcre}: ${format.format(summary.totalExpenses / acres)}
${l10n.revenuePerAcre}: ${format.format(summary.totalRevenue / acres)}
${l10n.yieldPerAcre}: ${weightFormat.format(summary.totalYieldWeight / acres)}

${l10n.expenseBreakdown}:
${summary.expenseByCategory.entries.map((e) => '- ${L10nHelpers.categoryLabel(context, e.key)}: ${format.format(e.value)}').join('\n')}
''';
    Share.share(text);
  }
}

class _AnalyticsBody extends ConsumerWidget {
  final SeasonComparison comparison;
  final NumberFormat currencyFormat;

  const _AnalyticsBody({
    required this.comparison,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final summary = comparison.currentSummary;
    final acres = comparison.currentSeason.landArea > 0
        ? comparison.currentSeason.landArea
        : 1.0;
    final weightFormat =
        NumberFormat.decimalPattern(L10nHelpers.intlLocaleFor(context));

    final sortedExpenses = summary.expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding:
          const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Season header
          Text(
            '${L10nHelpers.cropLabel(context, comparison.currentSeason.cropType)} ${comparison.currentSeason.startDate.year}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpace.xxs),
          Text(
            '${comparison.currentSeason.landArea} ${l10n.acresUnit}',
            style: AppTheme.tabular(Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(height: AppSpace.lg),

          // Unit Economics 2x2 hairline ledger grid
          AppCard(
            child: Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _UnitCell(
                          label: l10n.costPerAcre,
                          value: currencyFormat
                              .format(summary.totalExpenses / acres),
                          valueColor: AppColors.expenseFor(context),
                        ),
                      ),
                      VerticalDivider(width: 1, color: tokens.hairline),
                      Expanded(
                        child: _UnitCell(
                          label: l10n.revenuePerAcre,
                          value: currencyFormat
                              .format(summary.totalRevenue / acres),
                          valueColor: AppColors.revenueFor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: tokens.hairline),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _UnitCell(
                          label: l10n.profitPerAcre,
                          value: currencyFormat.format(summary.profit / acres),
                          valueColor: summary.profit >= 0
                              ? AppColors.profitFor(context)
                              : AppColors.expenseFor(context),
                        ),
                      ),
                      VerticalDivider(width: 1, color: tokens.hairline),
                      Expanded(
                        child: _UnitCell(
                          label: l10n.yieldPerAcre,
                          value: weightFormat
                              .format(summary.totalYieldWeight / acres),
                          valueColor: tokens.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xl),

          // Season Comparison
          AppSectionHeader(title: l10n.yoyComparison),
          const SizedBox(height: AppSpace.sm),
          if (comparison.previousSeason == null)
            AppCard(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Text(
                l10n.seasonComparisonEmpty,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else ...[
            _ComparisonCard(comparison: comparison),
            if (comparison.previousSummary != null) ...[
              const SizedBox(height: AppSpace.md),
              _ComparisonBarChart(comparison: comparison),
            ],
          ],
          const SizedBox(height: AppSpace.xl),

          // Expense Breakdown
          AppSectionHeader(title: l10n.expenseBreakdown),
          const SizedBox(height: AppSpace.sm),
          if (sortedExpenses.isEmpty)
            AppCard(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Text(l10n.noExpenses,
                  style: Theme.of(context).textTheme.bodyMedium),
            )
          else
            AppCard(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Column(
                children: [
                  for (int i = 0; i < sortedExpenses.length; i++) ...[
                    _ExpenseRow(
                      category: sortedExpenses[i].key,
                      amount: sortedExpenses[i].value,
                      total: summary.totalExpenses > 0
                          ? summary.totalExpenses
                          : 1.0,
                      format: currencyFormat,
                    ),
                    if (i < sortedExpenses.length - 1)
                      const SizedBox(height: AppSpace.md),
                  ],
                ],
              ),
            ),

          // Multi-year Trend
          const SizedBox(height: AppSpace.xl),
          _MultiYearTrendSection(),
        ],
      ),
    );
  }
}

class _UnitCell extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _UnitCell({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpace.xxs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: AppTheme.tabular(
                Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: valueColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final SeasonComparison comparison;

  const _ComparisonCard({required this.comparison});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isUp = comparison.profitVariance >= 0;
    final pct = (comparison.profitVariance * 100).abs().toStringAsFixed(1);
    final prevName =
        '${L10nHelpers.cropLabel(context, comparison.previousSeason!.cropType)} ${comparison.previousSeason!.startDate.year}';
    final trendColor =
        isUp ? AppColors.revenueFor(context) : AppColors.expenseFor(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpace.md),
      child: Row(
        children: [
          Icon(
            isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: trendColor,
            size: 22,
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              isUp
                  ? l10n.profitVarianceUp(pct, prevName)
                  : l10n.profitVarianceDown(pct, prevName),
              style:
                  Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonBarChart extends StatelessWidget {
  final SeasonComparison comparison;

  const _ComparisonBarChart({required this.comparison});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final cur = comparison.currentSummary;
    final prev = comparison.previousSummary!;
    final curLabel =
        '${L10nHelpers.cropLabel(context, comparison.currentSeason.cropType)} ${comparison.currentSeason.startDate.year}';
    final prevLabel =
        '${L10nHelpers.cropLabel(context, comparison.previousSeason!.cropType)} ${comparison.previousSeason!.startDate.year}';

    final maxY = [
      cur.totalRevenue,
      cur.totalExpenses,
      prev.totalRevenue,
      prev.totalExpenses,
    ].reduce((a, b) => a > b ? a : b);

    if (maxY == 0) return const SizedBox.shrink();

    final revColor = AppColors.revenueFor(context);
    final expColor = AppColors.expenseFor(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        children: [
          SizedBox(
            height: 210,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final text = value.toInt() == 0 ? prevLabel : curLabel;
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(text,
                              style: Theme.of(context).textTheme.bodySmall),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          NumberFormat.compact(
                                  locale: L10nHelpers.intlLocaleFor(context))
                              .format(value),
                          style: AppTheme.tabular(
                              Theme.of(context).textTheme.bodySmall),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: tokens.hairline, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barsSpace: 6,
                    barRods: [
                      BarChartRodData(
                          toY: prev.totalRevenue,
                          color: revColor,
                          width: 16,
                          borderRadius: BorderRadius.circular(4)),
                      BarChartRodData(
                          toY: prev.totalExpenses,
                          color: expColor,
                          width: 16,
                          borderRadius: BorderRadius.circular(4)),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barsSpace: 6,
                    barRods: [
                      BarChartRodData(
                          toY: cur.totalRevenue,
                          color: revColor,
                          width: 16,
                          borderRadius: BorderRadius.circular(4)),
                      BarChartRodData(
                          toY: cur.totalExpenses,
                          color: expColor,
                          width: 16,
                          borderRadius: BorderRadius.circular(4)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: revColor, label: l10n.revenue),
              const SizedBox(width: AppSpace.md),
              _LegendDot(color: expColor, label: l10n.expenses),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  final String category;
  final double amount;
  final double total;
  final NumberFormat format;

  const _ExpenseRow({
    required this.category,
    required this.amount,
    required this.total,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final pct = (amount / total).clamp(0.0, 1.0);
    final catColor = AppColors.forCategory(category);

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: catColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpace.xs),
            Expanded(
              child: Text(
                L10nHelpers.categoryLabel(context, category),
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: tokens.ink),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${(pct * 100).round()}%',
              style: AppTheme.tabular(Theme.of(context).textTheme.bodySmall),
            ),
            const SizedBox(width: AppSpace.sm),
            Text(
              format.format(amount),
              style: AppTheme.tabular(Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: tokens.ink)),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            valueColor: AlwaysStoppedAnimation(catColor),
            backgroundColor: tokens.well,
          ),
        ),
      ],
    );
  }
}

class _MultiYearTrendSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final trendAsync = ref.watch(multiYearTrendProvider);

    return trendAsync.when(
      data: (trendData) {
        if (trendData.length < 2) return const SizedBox.shrink();

        final spots = trendData
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.summary.profit))
            .toList();

        final maxProfit = trendData
            .map((e) => e.summary.profit)
            .reduce((a, b) => a > b ? a : b);
        final minProfit = trendData
            .map((e) => e.summary.profit)
            .reduce((a, b) => a < b ? a : b);
        final highest = maxProfit.abs() > minProfit.abs()
            ? maxProfit.abs()
            : minProfit.abs();
        final maxY = highest == 0 ? 1.0 : highest * 1.2;
        final minY = minProfit >= 0 ? 0.0 : (highest == 0 ? -1.0 : -maxY);
        final gridInterval =
            ((maxY - minY) / 4).abs().clamp(0.25, double.infinity);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(title: l10n.multiYearTrend),
            const SizedBox(height: AppSpace.sm),
            AppCard(
              padding: const EdgeInsets.all(AppSpace.md),
              child: SizedBox(
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
                        barWidth: 2.5,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.08),
                        ),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= trendData.length) {
                              return const SizedBox.shrink();
                            }
                            final s = trendData[idx].season;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '${s.startDate.year}',
                                style: AppTheme.tabular(
                                    Theme.of(context).textTheme.bodySmall),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 52,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) {
                              return Text('0',
                                  style: AppTheme.tabular(
                                      Theme.of(context).textTheme.bodySmall));
                            }
                            return Text(
                              NumberFormat.compact(
                                      locale:
                                          L10nHelpers.intlLocaleFor(context))
                                  .format(value),
                              style: AppTheme.tabular(
                                  Theme.of(context).textTheme.bodySmall),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: gridInterval,
                      getDrawingHorizontalLine: (_) =>
                          FlLine(color: tokens.hairline, strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text(l10n.errorLoadingTrends(e.toString()))),
    );
  }
}
