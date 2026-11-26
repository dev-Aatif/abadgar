import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/season.dart';
import '../../../core/providers/active_season_provider.dart';
import '../../../core/providers/backup_providers.dart';
import '../../../core/providers/comparison_provider.dart';
import '../../../core/providers/financial_summary_provider.dart';
import '../../../core/providers/seasons_provider.dart';
import '../../../core/providers/transactions_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_helpers.dart';
import '../../widgets/app_controls.dart';
import '../../widgets/app_selector.dart';
import '../../widgets/app_surface.dart';
import '../../widgets/transaction_actions.dart';
import '../../widgets/transaction_form/transaction_bottom_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final summary = ref.watch(financialSummaryProvider);
    final activeSeason = ref.watch(activeSeasonProvider).valueOrNull;
    final transactions =
        ref.watch(activeSeasonTransactionsProvider).valueOrNull ?? [];
    final seasonsAsync = ref.watch(seasonsProvider);
    final comparisonAsync = activeSeason != null
        ? ref.watch(seasonComparisonProvider(activeSeason.id))
        : null;

    final currencyFormat = NumberFormat.currency(
      locale: L10nHelpers.intlLocaleFor(context),
      symbol: 'Rs ',
      decimalDigits: 0,
    );

    return seasonsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.xl),
            child: Text(
              l10n.errorGeneral(err.toString()),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (seasonsList) {
        if (seasonsList.isEmpty) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpace.xl),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AbadgarLogoBadge(size: 76, radius: AppRadius.lg),
                        const SizedBox(height: AppSpace.xl),
                        Text(
                          l10n.welcomeTitle,
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpace.xs),
                        Text(
                          l10n.welcomeSubtext,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpace.xl),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => context.push('/seasons'),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(l10n.startNewSeason),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                HapticFeedback.lightImpact();
                ref.invalidate(activeSeasonTransactionsProvider);
                ref.invalidate(financialSummaryProvider);
                await Future.delayed(const Duration(milliseconds: 450));
              },
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  // Compact Console Top Bar: Season Selector + Sync + Seasons
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.md,
                        AppSpace.sm,
                        AppSpace.md,
                        AppSpace.sm,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SeasonSelectorControl(
                              activeSeason: activeSeason,
                              seasonsList: seasonsList,
                            ),
                          ),
                          const SizedBox(width: AppSpace.xs),
                          _LocalStatusBadge(
                            onTap: () => context.go('/settings'),
                          ),
                          const SizedBox(width: AppSpace.xxs),
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: Material(
                              color: tokens.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                                side: BorderSide(
                                    color: tokens.hairline, width: 1),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => context.push('/seasons'),
                                child: Tooltip(
                                  message: l10n.changeSeason,
                                  child: Icon(
                                    Icons.agriculture_outlined,
                                    size: 18,
                                    color: tokens.ink,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Signature Console Margin & Cash-Flow Instrument Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.md,
                        AppSpace.xxs,
                        AppSpace.md,
                        AppSpace.sm,
                      ),
                      child: _ConsoleInstrumentCard(
                        activeSeason: activeSeason,
                        summary: summary,
                        comparisonAsync: comparisonAsync,
                        currencyFormat: currencyFormat,
                      ),
                    ),
                  ),

                  // Compact 1-Tap Action Strip
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.md,
                        0,
                        AppSpace.md,
                        AppSpace.lg,
                      ),
                      child: _QuickActionStrip(
                        onExpense: () => showTransactionSheet(
                          context,
                          initialMode: TransactionMode.expense,
                        ),
                        onRevenue: () => showTransactionSheet(
                          context,
                          initialMode: TransactionMode.revenue,
                        ),
                        onHarvest: () => showTransactionSheet(
                          context,
                          initialMode: TransactionMode.harvest,
                        ),
                      ),
                    ),
                  ),

                  // Compact Spend Distribution Panel
                  if (summary != null &&
                      summary.expenseByCategory.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: AppSpace.md),
                        child: AppSectionHeader(
                          title: l10n.expenseBreakdown,
                          trailing: TextButton(
                            onPressed: () => context.go('/analytics'),
                            child: Text(l10n.seeAll),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpace.md,
                          AppSpace.xxs,
                          AppSpace.md,
                          AppSpace.lg,
                        ),
                        child: _SpendProportionPanel(
                          summary: summary,
                          currencyFormat: currencyFormat,
                        ),
                      ),
                    ),
                  ],

                  // Recent Activity Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpace.md),
                      child: AppSectionHeader(
                        title: l10n.ledger,
                        trailing: TextButton(
                          onPressed: () => context.go('/ledger'),
                          child: Text(l10n.seeAll),
                        ),
                      ),
                    ),
                  ),

                  // Dense Hairline Ledger Rows
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.md,
                      AppSpace.xxs,
                      AppSpace.md,
                      32,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: transactions.isEmpty
                          ? AppCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpace.md,
                                vertical: AppSpace.md,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      l10n.noRecentEntries,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        showTransactionSheet(context),
                                    child: Text(l10n.addFirstEntry),
                                  ),
                                ],
                              ),
                            )
                          : AppCard(
                              child: Column(
                                children: [
                                  for (int i = 0;
                                      i <
                                          (transactions.length > 5
                                              ? 5
                                              : transactions.length);
                                      i++)
                                    TransactionTile(
                                      transaction: transactions[i],
                                      currencyFormat: currencyFormat,
                                      horizontalPadding: AppSpace.md,
                                      showDivider: i <
                                          (transactions.length > 5
                                              ? 4
                                              : transactions.length - 1),
                                      onTap: () => showTransactionSheet(
                                        context,
                                        transaction: transactions[i],
                                      ),
                                      onDelete: () => deleteTransactionWithUndo(
                                        context,
                                        ref,
                                        transactions[i],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SeasonSelectorControl extends ConsumerWidget {
  final Season? activeSeason;
  final List<Season> seasonsList;

  const _SeasonSelectorControl({
    required this.activeSeason,
    required this.seasonsList,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: AppSelectorTrigger(
        compact: true,
        leading: activeSeason != null
            ? CropGlyph(cropType: activeSeason!.cropType, size: 15)
            : null,
        label: activeSeason != null
            ? '${L10nHelpers.cropLabel(context, activeSeason!.cropType)} ${activeSeason!.startDate.year}'
            : l10n.noActiveSeason,
        onTap: () async {
          final picked = await showAppSelectorSheet<String>(
            context: context,
            title: l10n.whichSeason,
            selectedValue: activeSeason?.id,
            headerAction: TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push('/seasons');
              },
              icon: const Icon(Icons.tune_rounded, size: 15),
              label: Text(l10n.seasons),
            ),
            options: seasonsList.map((s) {
              return AppSelectorOption<String>(
                value: s.id,
                label:
                    '${L10nHelpers.cropLabel(context, s.cropType)} ${s.startDate.year}',
                subtitle:
                    '${l10n.seasonStarted} ${DateFormat.yMMMd(L10nHelpers.intlLocaleFor(context)).format(s.startDate)}',
                badge: '${s.landArea} ${l10n.acresUnitShort}',
                leading: CropGlyph(cropType: s.cropType, size: 18),
              );
            }).toList(),
          );
          if (picked != null && picked != activeSeason?.id) {
            ref.read(activeSeasonIdProvider.notifier).set(picked);
          }
        },
      ),
    );
  }
}

class _ConsoleInstrumentCard extends StatelessWidget {
  final Season? activeSeason;
  final FinancialSummary? summary;
  final AsyncValue<SeasonComparison?>? comparisonAsync;
  final NumberFormat currencyFormat;

  const _ConsoleInstrumentCard({
    required this.activeSeason,
    required this.summary,
    required this.comparisonAsync,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final revenue = summary?.totalRevenue ?? 0;
    final expenses = summary?.totalExpenses ?? 0;
    final profit = summary?.profit ?? 0;
    final isNegative = profit < 0;
    final profitColor = isNegative ? AppColors.expenseFor(context) : tokens.ink;
    final acres = activeSeason?.landArea ?? 0;

    return AppCard(
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.netProfit,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (activeSeason != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.well,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    border: Border.all(color: tokens.hairline, width: 1),
                  ),
                  child: Text(
                    '${activeSeason!.landArea} ${l10n.acresUnitShort}',
                    style: AppTheme.tabular(
                      Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: tokens.ink,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.xxs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              '${isNegative ? '−' : ''}${currencyFormat.format(profit.abs())}',
              style: AppTheme.tabular(
                Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: profitColor,
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.9,
                    ),
              ),
            ),
          ),
          if (comparisonAsync != null)
            comparisonAsync!.maybeWhen(
              data: (comparison) {
                if (comparison == null || comparison.previousSeason == null) {
                  return const SizedBox.shrink();
                }
                final variance = comparison.profitVariance;
                final isUp = variance >= 0;
                final pct = (variance.abs() * 100).toStringAsFixed(1);
                final trendColor = isUp
                    ? AppColors.revenueFor(context)
                    : AppColors.expenseFor(context);
                final prevName =
                    '${L10nHelpers.cropLabel(context, comparison.previousSeason!.cropType)} ${comparison.previousSeason!.startDate.year}';

                return Padding(
                  padding: const EdgeInsets.only(top: AppSpace.xxs),
                  child: InkWell(
                    onTap: () => context.go('/analytics'),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isUp
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            size: 15,
                            color: trendColor,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              isUp
                                  ? l10n.profitVarianceUp(pct, prevName)
                                  : l10n.profitVarianceDown(pct, prevName),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: trendColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          const SizedBox(height: AppSpace.sm),
          PrecisionRatioBar(revenue: revenue, expenses: expenses),
          const SizedBox(height: AppSpace.sm),
          Divider(height: 1, color: tokens.hairline),
          const SizedBox(height: AppSpace.sm),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _MetricPair(
                    label: l10n.revenue,
                    value: '+${currencyFormat.format(revenue)}',
                    valueColor: AppColors.revenueFor(context),
                  ),
                ),
                VerticalDivider(width: AppSpace.md, color: tokens.hairline),
                Expanded(
                  child: _MetricPair(
                    label: l10n.expenses,
                    value: '−${currencyFormat.format(expenses)}',
                    valueColor: AppColors.expenseFor(context),
                  ),
                ),
                if (acres > 0) ...[
                  VerticalDivider(width: AppSpace.md, color: tokens.hairline),
                  Expanded(
                    child: _MetricPair(
                      label: l10n.profitPerAcre,
                      value: currencyFormat.format(profit / acres),
                      valueColor: isNegative
                          ? AppColors.expenseFor(context)
                          : tokens.instrument,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricPair extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _MetricPair({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
    );
  }
}

class _QuickActionStrip extends StatelessWidget {
  final VoidCallback onExpense;
  final VoidCallback onRevenue;
  final VoidCallback onHarvest;

  const _QuickActionStrip({
    required this.onExpense,
    required this.onRevenue,
    required this.onHarvest,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;

    return AppCard(
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _StripItem(
                label: l10n.expense,
                icon: Icons.remove_rounded,
                tint: AppColors.expenseFor(context),
                onTap: onExpense,
              ),
            ),
            VerticalDivider(width: 1, color: tokens.hairline),
            Expanded(
              child: _StripItem(
                label: l10n.revenue,
                icon: Icons.add_rounded,
                tint: AppColors.revenueFor(context),
                onTap: onRevenue,
              ),
            ),
            VerticalDivider(width: 1, color: tokens.hairline),
            Expanded(
              child: _StripItem(
                label: l10n.harvest,
                icon: Icons.eco_outlined,
                tint: AppColors.wheatFor(context),
                onTap: onHarvest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StripItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;

  const _StripItem({
    required this.label,
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: tint),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontSize: 12.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpendProportionPanel extends StatelessWidget {
  final FinancialSummary summary;
  final NumberFormat currencyFormat;

  const _SpendProportionPanel({
    required this.summary,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final entries = summary.expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = summary.totalExpenses > 0 ? summary.totalExpenses : 1.0;
    final topEntries = entries.take(4).toList();

    return AppCard(
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  for (int i = 0; i < entries.length; i++)
                    Expanded(
                      flex: (entries[i].value * 100 / total)
                          .round()
                          .clamp(1, 100),
                      child: Container(
                        margin: EdgeInsetsDirectional.only(
                          end: i < entries.length - 1 ? 2 : 0,
                        ),
                        color: AppColors.forCategory(entries[i].key),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          for (int i = 0; i < topEntries.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.forCategory(topEntries[i].key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      L10nHelpers.categoryLabel(context, topEntries[i].key),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: tokens.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${((topEntries[i].value / total) * 100).round()}%',
                    style: AppTheme.tabular(
                      Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    currencyFormat.format(topEntries[i].value),
                    style: AppTheme.tabular(
                      Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: tokens.ink,
                            fontSize: 12,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            if (i < topEntries.length - 1)
              Divider(height: 1, color: tokens.hairline),
          ],
        ],
      ),
    );
  }
}

class _LocalStatusBadge extends ConsumerWidget {
  final VoidCallback onTap;

  const _LocalStatusBadge({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final backupStatus = ref.watch(backupStatusNotifierProvider).valueOrNull;
    final overdue = backupStatus?.isExternalBackupOverdue ?? false;
    final tint = overdue ? AppColors.wheatFor(context) : tokens.instrument;

    return Tooltip(
      message: overdue ? l10n.backupGuideSubtitle : l10n.syncLocalOnly,
      child: Material(
        color: tokens.well,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(color: tokens.hairline, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 36,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    overdue
                        ? Icons.shield_outlined
                        : Icons.verified_user_outlined,
                    size: 13,
                    color: tint,
                  ),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 105),
                    child: Text(
                      overdue ? l10n.backupDue : l10n.syncLocalOnly,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: overdue ? tint : tokens.ink,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
