import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:powersync/powersync.dart' hide Column;
import 'package:abadgar/l10n/generated/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/enums.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/supabase_connector.dart';
import '../../../core/models/season.dart';
import '../../../core/providers/active_season_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/comparison_provider.dart';
import '../../../core/providers/financial_summary_provider.dart';
import '../../../core/providers/seasons_provider.dart';
import '../../../core/providers/transactions_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_helpers.dart';
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
    final isAuthenticated = ref.watch(authStateProvider) != null;
    final seasonsList = ref.watch(seasonsProvider).valueOrNull ?? [];
    final comparisonAsync = activeSeason != null
        ? ref.watch(seasonComparisonProvider(activeSeason.id))
        : null;

    final currencyFormat = NumberFormat.currency(
      locale: L10nHelpers.intlLocaleFor(context),
      symbol: 'Rs ',
      decimalDigits: 0,
    );

    if (seasonsList.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sheet),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 88,
                    height: 88,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.eco_rounded,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.xl),
                Text(
                  l10n.welcomeTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  l10n.welcomeSubtext,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpace.xxl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.push('/seasons'),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.startNewSeason),
                  ),
                ),
              ],
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
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // Editorial Top Bar: Custom Season Selector + Sync Status + Seasons
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SeasonSelectorControl(
                          activeSeason: activeSeason,
                          seasonsList: seasonsList,
                        ),
                      ),
                      const SizedBox(width: AppSpace.xs),
                      _SyncStatusBadge(
                        isAuthenticated: isAuthenticated,
                        db: ref.watch(powerSyncDatabaseProvider).valueOrNull,
                        onTap: () => context.push('/auth'),
                      ),
                      const SizedBox(width: 2),
                      IconButton(
                        tooltip: l10n.changeSeason,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => context.push('/seasons'),
                        icon:
                            Icon(Icons.agriculture_outlined, color: tokens.ink),
                      ),
                    ],
                  ),
                ),
              ),

              // Open Typographic Hero Ledger Band (unboxed, directly on canvas)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.md),
                  child: _HeroLedgerBand(
                    activeSeason: activeSeason,
                    summary: summary,
                    comparisonAsync: comparisonAsync,
                    currencyFormat: currencyFormat,
                  ),
                ),
              ),

              // Unified 1-Tap Action Strip (single segmented bar, zero floating tiles)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpace.lg, 0, AppSpace.lg, AppSpace.xl),
                  child: _QuickActionStrip(
                    onExpense: () => showTransactionSheet(context,
                        initialMode: TransactionMode.expense),
                    onRevenue: () => showTransactionSheet(context,
                        initialMode: TransactionMode.revenue),
                    onHarvest: () => showTransactionSheet(context,
                        initialMode: TransactionMode.harvest),
                  ),
                ),
              ),

              // Unboxed Proportional Spend Section
              if (summary != null && summary.expenseByCategory.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpace.lg),
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
                        AppSpace.lg, AppSpace.xs, AppSpace.lg, AppSpace.xl),
                    child: _SpendProportionStrip(
                      summary: summary,
                      currencyFormat: currencyFormat,
                    ),
                  ),
                ),
              ],

              // Recent Activity Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                  child: AppSectionHeader(
                    title: l10n.ledger,
                    trailing: TextButton(
                      onPressed: () => context.go('/ledger'),
                      child: Text(l10n.seeAll),
                    ),
                  ),
                ),
              ),

              // Flat Hairline Ledger Rows (unboxed, edge-aligned)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpace.lg, AppSpace.xs, AppSpace.lg, 48),
                sliver: SliverToBoxAdapter(
                  child: transactions.isEmpty
                      ? Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: AppSpace.lg),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: tokens.hairline),
                              bottom: BorderSide(color: tokens.hairline),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.noRecentEntries,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              TextButton(
                                onPressed: () => showTransactionSheet(context),
                                child: Text(l10n.addFirstEntry),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: tokens.hairline),
                              bottom: BorderSide(color: tokens.hairline),
                            ),
                          ),
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
                                  horizontalPadding: 0,
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
    final cropColor = activeSeason?.cropType == CropType.wheat
        ? AppColors.wheatFor(context)
        : AppColors.riceFor(context);

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: AppSelectorTrigger(
        leading: activeSeason != null
            ? Icon(
                activeSeason!.cropType == CropType.wheat
                    ? Icons.grass_rounded
                    : Icons.water_drop_rounded,
                size: 17,
                color: cropColor,
              )
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
              icon: const Icon(Icons.tune_rounded, size: 16),
              label: Text(l10n.seasons),
            ),
            options: seasonsList.map((s) {
              final sColor = s.cropType == CropType.wheat
                  ? AppColors.wheatFor(context)
                  : AppColors.riceFor(context);
              return AppSelectorOption<String>(
                value: s.id,
                label:
                    '${L10nHelpers.cropLabel(context, s.cropType)} ${s.startDate.year}',
                subtitle:
                    '${l10n.seasonStarted} ${DateFormat.yMMMd(L10nHelpers.intlLocaleFor(context)).format(s.startDate)}',
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
          if (picked != null && picked != activeSeason?.id) {
            ref.read(activeSeasonIdProvider.notifier).set(picked);
          }
        },
      ),
    );
  }
}

class _HeroLedgerBand extends StatelessWidget {
  final Season? activeSeason;
  final FinancialSummary? summary;
  final AsyncValue<SeasonComparison?>? comparisonAsync;
  final NumberFormat currencyFormat;

  const _HeroLedgerBand({
    required this.activeSeason,
    required this.summary,
    required this.comparisonAsync,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final profit = summary?.profit ?? 0;
    final isNegative = profit < 0;
    final profitColor = isNegative ? AppColors.expenseFor(context) : tokens.ink;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                l10n.netProfit,
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (activeSeason != null)
              Text(
                '${activeSeason!.landArea} ${l10n.acresUnitShort}',
                style: AppTheme.tabular(Theme.of(context).textTheme.bodySmall),
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
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.0,
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
                padding: const EdgeInsets.only(top: AppSpace.xs),
                child: InkWell(
                  onTap: () => context.go('/analytics'),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUp
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 16,
                          color: trendColor,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            isUp
                                ? l10n.profitVarianceUp(pct, prevName)
                                : l10n.profitVarianceDown(pct, prevName),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: trendColor,
                                      fontWeight: FontWeight.w600,
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
        const SizedBox(height: AppSpace.md),
        Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: tokens.hairline),
              bottom: BorderSide(color: tokens.hairline),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.revenue,
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          '+${currencyFormat.format(summary?.totalRevenue ?? 0)}',
                          style: AppTheme.tabular(
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.revenueFor(context),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                VerticalDivider(width: AppSpace.lg, color: tokens.hairline),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.expenses,
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          '−${currencyFormat.format(summary?.totalExpenses ?? 0)}',
                          style: AppTheme.tabular(
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.expenseFor(context),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
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

class _SpendProportionStrip extends StatelessWidget {
  final FinancialSummary summary;
  final NumberFormat currencyFormat;

  const _SpendProportionStrip({
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

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                for (int i = 0; i < entries.length; i++)
                  Expanded(
                    flex:
                        (entries[i].value * 100 / total).round().clamp(1, 100),
                    child: Container(
                      margin: EdgeInsetsDirectional.only(
                          end: i < entries.length - 1 ? 2 : 0),
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
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.forCategory(topEntries[i].key),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: Text(
                    L10nHelpers.categoryLabel(context, topEntries[i].key),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: tokens.ink),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${((topEntries[i].value / total) * 100).round()}%',
                  style:
                      AppTheme.tabular(Theme.of(context).textTheme.bodySmall),
                ),
                const SizedBox(width: AppSpace.md),
                Text(
                  currencyFormat.format(topEntries[i].value),
                  style: AppTheme.tabular(Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: tokens.ink)),
                ),
              ],
            ),
          ),
          if (i < topEntries.length - 1)
            Divider(height: 1, color: tokens.hairline),
        ],
      ],
    );
  }
}

class _SyncStatusBadge extends StatelessWidget {
  final bool isAuthenticated;
  final PowerSyncDatabase? db;
  final VoidCallback onTap;

  const _SyncStatusBadge({
    required this.isAuthenticated,
    required this.db,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;

    if (!isAuthenticated || db == null) {
      return Tooltip(
        message: l10n.offlineAlert,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: tokens.well,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: tokens.hairline, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.phone_android_rounded,
                    size: 14, color: tokens.inkMuted),
                const SizedBox(width: 4),
                Text(
                  l10n.offline,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ValueListenableBuilder<String?>(
      valueListenable: SupabaseConnector.lastSyncWarning,
      builder: (context, syncWarning, _) {
        return StreamBuilder<SyncStatus>(
          stream: db!.statusStream,
          initialData: db!.currentStatus,
          builder: (context, snapshot) {
            final status = snapshot.data;
            final isSyncing = (status?.connecting ?? false) ||
                (status?.downloading ?? false) ||
                (status?.uploading ?? false);
            final isConnected = status?.connected ?? false;

            final IconData icon;
            final String label;
            final Color color;

            if (syncWarning != null) {
              icon = Icons.sync_problem_rounded;
              label = l10n.offline;
              color = AppColors.expenseFor(context);
            } else if (isSyncing) {
              icon = Icons.sync_rounded;
              label = l10n.connecting;
              color = Theme.of(context).colorScheme.primary;
            } else if (isConnected) {
              icon = Icons.cloud_done_rounded;
              label = l10n.connected;
              color = AppColors.revenueFor(context);
            } else {
              icon = Icons.cloud_off_rounded;
              label = l10n.offline;
              color = tokens.inkMuted;
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: tokens.well,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: tokens.hairline, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: color),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
