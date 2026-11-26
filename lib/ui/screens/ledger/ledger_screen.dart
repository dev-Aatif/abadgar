import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/enums.dart';
import '../../../core/models/transaction.dart';
import '../../../core/models/yield_log.dart';
import '../../../core/providers/active_season_provider.dart';
import '../../../core/providers/transactions_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_helpers.dart';
import '../../widgets/app_surface.dart';
import '../../widgets/transaction_actions.dart';
import '../../widgets/transaction_form/transaction_bottom_sheet.dart';

final ledgerFilterProvider = StateProvider<TransactionType?>((ref) => null);
final ledgerSearchQueryProvider = StateProvider<String>((ref) => '');
final ledgerIsSearchingProvider = StateProvider<bool>((ref) => false);

class LedgerScreen extends ConsumerWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activeSeason = ref.watch(activeSeasonProvider).valueOrNull;
    final transactionsAsync = ref.watch(activeSeasonTransactionsProvider);
    final filter = ref.watch(ledgerFilterProvider);
    final isSearching = ref.watch(ledgerIsSearchingProvider);
    final searchQuery = ref.watch(ledgerSearchQueryProvider);
    final currencyFormat = NumberFormat.currency(
      locale: L10nHelpers.intlLocaleFor(context),
      symbol: 'Rs ',
      decimalDigits: 0,
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: isSearching
              ? TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n.search,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) =>
                      ref.read(ledgerSearchQueryProvider.notifier).state = val,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.ledger),
                    if (activeSeason != null)
                      Text(
                        '${L10nHelpers.cropLabel(context, activeSeason.cropType)} ${activeSeason.startDate.year}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
          actions: [
            IconButton(
              icon: Icon(
                  isSearching ? Icons.close_rounded : Icons.search_rounded),
              onPressed: () {
                if (isSearching) {
                  ref.read(ledgerIsSearchingProvider.notifier).state = false;
                  ref.read(ledgerSearchQueryProvider.notifier).state = '';
                } else {
                  ref.read(ledgerIsSearchingProvider.notifier).state = true;
                }
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.financials),
              Tab(text: l10n.harvests),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _FinancialsTab(
              transactionsAsync: transactionsAsync,
              filter: filter,
              searchQuery: searchQuery,
              currencyFormat: currencyFormat,
            ),
            _HarvestsTab(
              searchQuery: searchQuery,
              currencyFormat: currencyFormat,
            ),
          ],
        ),
      ),
    );
  }
}

class _FinancialsTab extends ConsumerWidget {
  final AsyncValue<List<Transaction>> transactionsAsync;
  final TransactionType? filter;
  final String searchQuery;
  final NumberFormat currencyFormat;

  const _FinancialsTab({
    required this.transactionsAsync,
    required this.filter,
    required this.searchQuery,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Inline 1-tap filter strip
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(
              AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.xs),
          child: Row(
            children: [
              ChoiceChip(
                label: Text(l10n.filterAll),
                selected: filter == null,
                showCheckmark: false,
                onSelected: (_) =>
                    ref.read(ledgerFilterProvider.notifier).state = null,
              ),
              const SizedBox(width: AppSpace.xs),
              ChoiceChip(
                label: Text(l10n.filterExpenses),
                selected: filter == TransactionType.expense,
                showCheckmark: false,
                onSelected: (_) => ref
                    .read(ledgerFilterProvider.notifier)
                    .state = TransactionType.expense,
              ),
              const SizedBox(width: AppSpace.xs),
              ChoiceChip(
                label: Text(l10n.filterRevenue),
                selected: filter == TransactionType.revenue,
                showCheckmark: false,
                onSelected: (_) => ref
                    .read(ledgerFilterProvider.notifier)
                    .state = TransactionType.revenue,
              ),
            ],
          ),
        ),
        Expanded(
          child: transactionsAsync.when(
            data: (transactions) {
              final filtered = transactions.where((t) {
                if (filter != null && t.type != filter) return false;
                if (searchQuery.isNotEmpty) {
                  final q = searchQuery.toLowerCase();
                  final matchCat =
                      (t.category?.toLowerCase().contains(q) ?? false) ||
                          L10nHelpers.categoryLabel(context, t.category)
                              .toLowerCase()
                              .contains(q);
                  final matchNote = t.notes?.toLowerCase().contains(q) ?? false;
                  final matchAmount = t.amount.toString().contains(q);
                  if (!matchCat && !matchNote && !matchAmount) return false;
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                final hasActiveFilter =
                    filter != null || searchQuery.isNotEmpty;
                return AppEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: hasActiveFilter
                      ? l10n.noTransactionsFilter
                      : l10n.noTransactions,
                  actionLabel:
                      hasActiveFilter ? l10n.clear : l10n.addFirstEntry,
                  onAction: () {
                    if (hasActiveFilter) {
                      ref.read(ledgerFilterProvider.notifier).state = null;
                      ref.read(ledgerSearchQueryProvider.notifier).state = '';
                      ref.read(ledgerIsSearchingProvider.notifier).state =
                          false;
                    } else {
                      showTransactionSheet(context);
                    }
                  },
                );
              }

              final localeCode = L10nHelpers.intlLocaleFor(context);
              final monthFormat = DateFormat('MMMM yyyy', localeCode);
              final Map<String, List<Transaction>> grouped = {};
              for (final tx in filtered) {
                final month = monthFormat.format(tx.date);
                grouped.putIfAbsent(month, () => []).add(tx);
              }

              // Flatten grouped months into lazy list items so large ledgers render smoothly
              final flatItems = <_LedgerItem>[];
              for (final entry in grouped.entries) {
                final monthNet = entry.value.fold<double>(0, (sum, tx) {
                  final isRev = tx.type == TransactionType.revenue ||
                      tx.type == TransactionType.yield_;
                  return sum + (isRev ? tx.amount : -tx.amount);
                });
                flatItems.add(_LedgerHeaderItem(
                  title: entry.key,
                  net: monthNet,
                  isFirst: flatItems.isEmpty,
                ));
                for (int i = 0; i < entry.value.length; i++) {
                  flatItems.add(_LedgerTxItem(
                    tx: entry.value[i],
                    isFirstInGroup: i == 0,
                    isLastInGroup: i == entry.value.length - 1,
                  ));
                }
              }

              return RefreshIndicator(
                onRefresh: () async {
                  HapticFeedback.lightImpact();
                  ref.invalidate(activeSeasonTransactionsProvider);
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(
                      AppSpace.lg, AppSpace.xs, AppSpace.lg, 100),
                  itemCount: flatItems.length,
                  itemBuilder: (context, index) {
                    final item = flatItems[index];
                    if (item is _LedgerHeaderItem) {
                      return Padding(
                        padding: EdgeInsets.only(
                          top: item.isFirst ? AppSpace.xs : AppSpace.lg,
                          bottom: AppSpace.xs,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item.title,
                                style: Theme.of(context).textTheme.titleSmall),
                            Text(
                              '${item.net >= 0 ? '+' : '−'}${currencyFormat.format(item.net.abs())}',
                              style: AppTheme.tabular(
                                Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: item.net >= 0
                                          ? AppColors.revenueFor(context)
                                          : AppColors.expenseFor(context),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final txItem = item as _LedgerTxItem;
                    final tokens = context.tokens;
                    final topRadius = txItem.isFirstInGroup
                        ? const Radius.circular(AppRadius.lg)
                        : Radius.zero;
                    final bottomRadius = txItem.isLastInGroup
                        ? const Radius.circular(AppRadius.lg)
                        : Radius.zero;

                    return Container(
                      decoration: BoxDecoration(
                        color: tokens.surface,
                        borderRadius: BorderRadius.vertical(
                            top: topRadius, bottom: bottomRadius),
                        border: Border(
                          left: BorderSide(color: tokens.hairline),
                          right: BorderSide(color: tokens.hairline),
                          top: txItem.isFirstInGroup
                              ? BorderSide(color: tokens.hairline)
                              : BorderSide.none,
                          bottom: txItem.isLastInGroup
                              ? BorderSide(color: tokens.hairline)
                              : BorderSide.none,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: TransactionTile(
                        transaction: txItem.tx,
                        currencyFormat: currencyFormat,
                        showDivider: !txItem.isLastInGroup,
                        onTap: () => showTransactionSheet(
                          context,
                          transaction: txItem.tx,
                        ),
                        onDelete: () => deleteTransactionWithUndo(
                          context,
                          ref,
                          txItem.tx,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) =>
                Center(child: Text(l10n.errorGeneral(err.toString()))),
          ),
        ),
      ],
    );
  }
}

class _HarvestsTab extends ConsumerWidget {
  final String searchQuery;
  final NumberFormat currencyFormat;

  const _HarvestsTab({
    required this.searchQuery,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final yieldLogsAsync = ref.watch(activeSeasonYieldLogsProvider);

    return yieldLogsAsync.when(
      data: (allYieldLogs) {
        final yieldLogs = allYieldLogs.where((yl) {
          if (searchQuery.isNotEmpty) {
            final q = searchQuery.toLowerCase();
            final matchDest =
                yl.destination?.toLowerCase().contains(q) ?? false;
            final matchDisp = yl.disposition.value.toLowerCase().contains(q) ||
                L10nHelpers.dispositionLabel(context, yl.disposition)
                    .toLowerCase()
                    .contains(q);
            final matchUnit = yl.unit.value.toLowerCase().contains(q);
            final matchAmount = yl.totalWeight.toString().contains(q) ||
                (yl.salePrice?.toString().contains(q) ?? false);
            if (!matchDest && !matchDisp && !matchUnit && !matchAmount) {
              return false;
            }
          }
          return true;
        }).toList();

        if (yieldLogs.isEmpty) {
          return AppEmptyState(
            icon: Icons.eco_outlined,
            title: l10n.noHarvestsLogged,
            actionLabel: l10n.harvest,
            onAction: () => showTransactionSheet(context,
                initialMode: TransactionMode.harvest),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.lightImpact();
            ref.invalidate(activeSeasonYieldLogsProvider);
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(
                AppSpace.lg, AppSpace.md, AppSpace.lg, 100),
            children: [
              AppCard(
                child: Column(
                  children: [
                    for (int i = 0; i < yieldLogs.length; i++)
                      _HarvestTile(
                        log: yieldLogs[i],
                        currencyFormat: currencyFormat,
                        showDivider: i < yieldLogs.length - 1,
                        onTap: () => showTransactionSheet(context,
                            yieldLog: yieldLogs[i]),
                        onDelete: () =>
                            deleteYieldLogWithUndo(context, ref, yieldLogs[i]),
                        hairlineColor: tokens.hairline,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) =>
          Center(child: Text(l10n.errorLoadingHarvests(err.toString()))),
    );
  }
}

class _HarvestTile extends StatelessWidget {
  final YieldLog log;
  final NumberFormat currencyFormat;
  final bool showDivider;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Color hairlineColor;

  const _HarvestTile({
    required this.log,
    required this.currencyFormat,
    required this.showDivider,
    required this.onTap,
    required this.onDelete,
    required this.hairlineColor,
  });

  @override
  Widget build(BuildContext context) {
    final dispositionText =
        L10nHelpers.dispositionLabel(context, log.disposition);
    final localeCode = L10nHelpers.intlLocaleFor(context);
    final dateText = DateFormat('d MMM yyyy', localeCode).format(log.date);
    final detail = log.destination != null && log.destination!.isNotEmpty
        ? '$dateText — $dispositionText (${log.destination})'
        : '$dateText — $dispositionText';

    return Dismissible(
      key: ValueKey(log.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: AppSpace.lg),
        color: AppColors.expenseFor(context),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.md, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.wheatFor(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${NumberFormat.decimalPattern(localeCode).format(log.totalWeight)} ${L10nHelpers.yieldUnitLabel(context, log.unit)}',
                          style: AppTheme.tabular(
                              Theme.of(context).textTheme.titleMedium),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          detail,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (log.salePrice != null && log.salePrice! > 0) ...[
                    const SizedBox(width: AppSpace.sm),
                    Text(
                      currencyFormat.format(log.salePrice!),
                      style: AppTheme.tabular(
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.revenueFor(context),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (showDivider)
            Divider(
                height: 1,
                indent: AppSpace.md,
                endIndent: AppSpace.md,
                color: hairlineColor),
        ],
      ),
    );
  }
}

sealed class _LedgerItem {
  const _LedgerItem();
}

class _LedgerHeaderItem extends _LedgerItem {
  final String title;
  final double net;
  final bool isFirst;

  const _LedgerHeaderItem({
    required this.title,
    required this.net,
    required this.isFirst,
  });
}

class _LedgerTxItem extends _LedgerItem {
  final Transaction tx;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const _LedgerTxItem({
    required this.tx,
    required this.isFirstInGroup,
    required this.isLastInGroup,
  });
}
