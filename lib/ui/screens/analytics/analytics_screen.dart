import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/analytics_selection_provider.dart';
import '../../../core/providers/comparison_provider.dart';
import '../../../core/providers/seasons_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_helpers.dart';
import '../../widgets/app_controls.dart';
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
          if (comparisonAsync.valueOrNull != null)
            IconButton(
              tooltip: l10n.exportData,
              icon: const Icon(Icons.share_outlined, size: 20),
              onPressed: () =>
                  _shareReport(context, comparisonAsync.valueOrNull),
            ),
          seasonsAsync.when(
            data: (seasons) {
              if (seasons.isEmpty) return const SizedBox.shrink();
              final current = seasons.firstWhere(
                (s) => s.id == selectedSeasonId,
                orElse: () => seasons.first,
              );

              return Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpace.sm),
                child: Center(
                  child: AppSelectorTrigger(
                    compact: true,
                    leading: CropGlyph(cropType: current.cropType, size: 15),
                    label:
                        '${L10nHelpers.cropLabel(context, current.cropType)} ${current.startDate.year}',
                    onTap: () async {
                      final picked = await showAppSelectorSheet<String>(
                        context: context,
                        title: l10n.whichSeason,
                        selectedValue: current.id,
                        options: seasons.map((s) {
                          return AppSelectorOption<String>(
                            value: s.id,
                            label:
                                '${L10nHelpers.cropLabel(context, s.cropType)} ${s.startDate.year}',
                            badge: '${s.landArea} ${l10n.acresUnitShort}',
                            leading: CropGlyph(cropType: s.cropType, size: 18),
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
      locale: intlLocale,
      symbol: 'Rs ',
      decimalDigits: 0,
    );
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
${l10n.yieldPerAcre}: ${weightFormat.format(summary.totalYieldWeight / acres)} ${l10n.unitKg}

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
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.xs,
        AppSpace.md,
        48,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Season Identity + Totals Summary Strip
          AppCard(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CropGlyph(
                      cropType: comparison.currentSeason.cropType,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Expanded(
                      child: Text(
                        '${L10nHelpers.cropLabel(context, comparison.currentSeason.cropType)} ${comparison.currentSeason.startDate.year}',
                        style: Theme.of(context).textTheme.headlineSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.well,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                        border: Border.all(color: tokens.hairline),
                      ),
                      child: Text(
                        '${comparison.currentSeason.landArea} ${l10n.acresUnit}',
                        style: AppTheme.tabular(
                          Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                PrecisionRatioBar(
                  revenue: summary.totalRevenue,
                  expenses: summary.totalExpenses,
                ),
                const SizedBox(height: AppSpace.sm),
                Divider(height: 1, color: tokens.hairline),
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
                          value:
                              '${weightFormat.format(summary.totalYieldWeight / acres)} ${l10n.unitKg}',
                          valueColor: tokens.instrument,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),

          // Season Comparison
          AppSectionHeader(title: l10n.yoyComparison),
          const SizedBox(height: AppSpace.xs),
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
              const SizedBox(height: AppSpace.sm),
              _ComparisonBarChart(
                comparison: comparison,
                currencyFormat: currencyFormat,
              ),
            ],
          ],
          const SizedBox(height: AppSpace.lg),

          // Expense Breakdown
          AppSectionHeader(title: l10n.expenseBreakdown),
          const SizedBox(height: AppSpace.xs),
          if (sortedExpenses.isEmpty)
            AppCard(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Text(
                l10n.noExpenses,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
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
                      const SizedBox(height: AppSpace.sm),
                  ],
                ],
              ),
            ),

          // Multi-year Trend
          const SizedBox(height: AppSpace.lg),
          _MultiYearTrendSection(currencyFormat: currencyFormat),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.compact,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: AppTheme.tabular(
                Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: valueColor,
                      fontWeight: FontWeight.w600,
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
            size: 20,
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              isUp
                  ? l10n.profitVarianceUp(pct, prevName)
                  : l10n.profitVarianceDown(pct, prevName),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 14,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonBarChart extends StatelessWidget {
  final SeasonComparison comparison;
  final NumberFormat currencyFormat;

  const _ComparisonBarChart({
    required this.comparison,
    required this.currencyFormat,
  });

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
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.5);

    return AppCard(
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        children: [
          SizedBox(
            height: 196 * textScale.clamp(1.0, 1.25),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY * 1.18,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => tokens.surfaceDeep,
                    tooltipBorder: BorderSide(color: tokens.hairlineStrong),
                    tooltipRoundedRadius: AppRadius.xs,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        currencyFormat.format(rod.toY),
                        AppTheme.tabular(
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: tokens.ink,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28 * textScale,
                      getTitlesWidget: (value, meta) {
                        final text = value.toInt() == 0 ? prevLabel : curLabel;
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            text,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52 * textScale,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          NumberFormat.compact(
                            locale: L10nHelpers.intlLocaleFor(context),
                          ).format(value),
                          style: AppTheme.tabular(
                            Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
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
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        toY: prev.totalRevenue,
                        color: revColor,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2),
                        ),
                      ),
                      BarChartRodData(
                        toY: prev.totalExpenses,
                        color: expColor,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        toY: cur.totalRevenue,
                        color: revColor,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2),
                        ),
                      ),
                      BarChartRodData(
                        toY: cur.totalExpenses,
                        color: expColor,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2),
                        ),
                      ),
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
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
              width: 8,
              height: 8,
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
              style: AppTheme.tabular(
                Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: tokens.ink),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2.5),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 5,
            valueColor: AlwaysStoppedAnimation(catColor),
            backgroundColor: tokens.well,
          ),
        ),
      ],
    );
  }
}

class _MultiYearTrendSection extends ConsumerWidget {
  final NumberFormat currencyFormat;

  const _MultiYearTrendSection({required this.currencyFormat});

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
        final textScale =
            MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.5);
        final xStep = (trendData.length / 4).ceil().clamp(1, trendData.length);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(title: l10n.multiYearTrend),
            const SizedBox(height: AppSpace.xs),
            AppCard(
              padding: const EdgeInsets.all(AppSpace.md),
              child: SizedBox(
                height: 192 * textScale.clamp(1.0, 1.25),
                child: LineChart(
                  LineChartData(
                    minY: minY,
                    maxY: maxY,
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => tokens.surfaceDeep,
                        tooltipBorder: BorderSide(color: tokens.hairlineStrong),
                        tooltipRoundedRadius: AppRadius.xs,
                        getTooltipItems: (touchedSpots) => touchedSpots
                            .map(
                              (s) => LineTooltipItem(
                                currencyFormat.format(s.y),
                                AppTheme.tabular(
                                  Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: tokens.ink,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: tokens.instrument,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (_, __, ___, ____) =>
                              FlDotCirclePainter(
                            radius: 3.5,
                            color: tokens.instrument,
                            strokeWidth: 1.5,
                            strokeColor: tokens.surface,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: tokens.instrument.withValues(alpha: 0.08),
                        ),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28 * textScale,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= trendData.length) {
                              return const SizedBox.shrink();
                            }
                            if (idx % xStep != 0 &&
                                idx != trendData.length - 1) {
                              return const SizedBox.shrink();
                            }
                            final s = trendData[idx].season;
                            final shortYear = (s.startDate.year % 100)
                                .toString()
                                .padLeft(2, '0');
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '${L10nHelpers.cropLabel(context, s.cropType)} \'$shortYear',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.tabular(
                                  Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 52 * textScale,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) {
                              return Text(
                                '0',
                                style: AppTheme.tabular(
                                  Theme.of(context).textTheme.bodySmall,
                                ),
                              );
                            }
                            return Text(
                              NumberFormat.compact(
                                locale: L10nHelpers.intlLocaleFor(context),
                              ).format(value),
                              style: AppTheme.tabular(
                                Theme.of(context).textTheme.bodySmall,
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
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
