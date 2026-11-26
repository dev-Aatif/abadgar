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
import '../../widgets/app_controls.dart';
import '../../widgets/app_surface.dart';
import '../../widgets/transaction_actions.dart';
import '../../widgets/transaction_form/transaction_bottom_sheet.dart';

final ledgerFilterProvider = StateProvider<TransactionType?>((ref) => null);
final ledgerCategoryFilterProvider = StateProvider<String?>((ref) => null);
final ledgerSearchQueryProvider = StateProvider<String>((ref) => '');
final ledgerIsSearchingProvider = StateProvider<bool>((ref) => false);

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _tabIndex) {
        setState(() => _tabIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final activeSeason = ref.watch(activeSeasonProvider).valueOrNull;
    final transactionsAsync = ref.watch(activeSeasonTransactionsProvider);
    final filter = ref.watch(ledgerFilterProvider);
    final categoryFilter = ref.watch(ledgerCategoryFilterProvider);
    final isSearching = ref.watch(ledgerIsSearchingProvider);
    final searchQuery = ref.watch(ledgerSearchQueryProvider);
    final currencyFormat = NumberFormat.currency(
      locale: L10nHelpers.intlLocaleFor(context),
      symbol: 'Rs ',
      decimalDigits: 0,
    );

    return Scaffold(
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
            : Row(
                children: [
                  Text(l10n.ledger),
                  if (activeSeason != null) ...[
                    const SizedBox(width: AppSpace.xs),
                    Flexible(
                      child: Container(
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
                          '${L10nHelpers.cropLabel(context, activeSeason.cropType)} ${activeSeason.startDate.year}',
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(
              isSearching ? Icons.close_rounded : Icons.search_rounded,
              size: 20,
            ),
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
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.md,
              AppSpace.xxs,
              AppSpace.md,
              AppSpace.xs,
            ),
            child: AppSegmentedControl<int>(
              compact: true,
              selected: _tabIndex,
              segments: [
                AppSegment(value: 0, label: l10n.financials),
                AppSegment(value: 1, label: l10n.harvests),
              ],
              onChanged: (idx) {
                _tabController.animateTo(idx);
                setState(() => _tabIndex = idx);
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _FinancialsTab(
                  transactionsAsync: transactionsAsync,
                  filter: filter,
                  categoryFilter: categoryFilter,
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
        ],
      ),
    );
  }
}

class _FinancialsTab extends ConsumerWidget {
  final AsyncValue<List<Transaction>> transactionsAsync;
  final TransactionType? filter;
  final String? categoryFilter;
  final String searchQuery;
  final NumberFormat currencyFormat;

  const _FinancialsTab({
    required this.transactionsAsync,
    required this.filter,
    required this.categoryFilter,
    required this.searchQuery,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;

    final allTx = transactionsAsync.valueOrNull ?? [];
    final availableCategories = <String>{
      for (final tx in allTx)
        if ((filter == null || tx.type == filter) &&
            (tx.category?.isNotEmpty ?? false))
          tx.category!,
    }.toList()
      ..sort();

    return Column(
      children: [
        // Compact 1-tap type + category filter rail
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(
            AppSpace.md,
            AppSpace.xxs,
            AppSpace.md,
            AppSpace.xs,
          ),
          child: Row(
            children: [
              AppFilterPill(
                label: l10n.filterAll,
                selected: filter == null,
                onTap: () {
                  ref.read(ledgerFilterProvider.notifier).state = null;
                  ref.read(ledgerCategoryFilterProvider.notifier).state = null;
                },
              ),
              const SizedBox(width: 6),
              AppFilterPill(
                label: l10n.filterExpenses,
                dotColor: AppColors.expenseFor(context),
                selected: filter == TransactionType.expense,
                onTap: () {
                  ref.read(ledgerFilterProvider.notifier).state =
                      TransactionType.expense;
                  ref.read(ledgerCategoryFilterProvider.notifier).state = null;
                },
              ),
              const SizedBox(width: 6),
              AppFilterPill(
                label: l10n.filterRevenue,
                dotColor: AppColors.revenueFor(context),
                selected: filter == TransactionType.revenue,
                onTap: () {
                  ref.read(ledgerFilterProvider.notifier).state =
                      TransactionType.revenue;
                  ref.read(ledgerCategoryFilterProvider.notifier).state = null;
                },
              ),
              if (availableCategories.length > 1) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    height: 18,
                    child: VerticalDivider(width: 1, color: tokens.hairline),
                  ),
                ),
                for (final cat in availableCategories) ...[
                  AppFilterPill(
                    label: L10nHelpers.categoryLabel(context, cat),
                    dotColor: AppColors.forCategory(cat),
                    selected: categoryFilter == cat,
                    onTap: () {
                      final notifier =
                          ref.read(ledgerCategoryFilterProvider.notifier);
                      notifier.state = notifier.state == cat ? null : cat;
                    },
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ],
          ),
        ),
        Expanded(
          child: transactionsAsync.when(
            data: (transactions) {
              final filtered = transactions.where((t) {
                if (filter != null && t.type != filter) return false;
                if (categoryFilter != null && t.category != categoryFilter) {
                  return false;
                }
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
                final hasActiveFilter = filter != null ||
                    categoryFilter != null ||
                    searchQuery.isNotEmpty;
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
                      ref.read(ledgerCategoryFilterProvider.notifier).state =
                          null;
                      ref.read(ledgerSearchQueryProvider.notifier).state = '';
                      ref.read(ledgerIsSearchingProvider.notifier).state =
                          false;
                    } else {
                      showTransactionSheet(context);
                    }
                  },
                );
              }

              final filteredNet = filtered.fold<double>(0, (sum, tx) {
                final isRev = tx.type == TransactionType.revenue ||
                    tx.type == TransactionType.yield_;
                return sum + (isRev ? tx.amount : -tx.amount);
              });

              final localeCode = L10nHelpers.intlLocaleFor(context);
              final monthFormat = DateFormat('MMMM yyyy', localeCode);
              final Map<String, List<Transaction>> grouped = {};
              for (final tx in filtered) {
                final month = monthFormat.format(tx.date);
                grouped.putIfAbsent(month, () => []).add(tx);
              }

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

              return Column(
                children: [
                  // Granular live-tally bar for current filter
                  Container(
                    margin: const EdgeInsets.fromLTRB(
                      AppSpace.md,
                      0,
                      AppSpace.md,
                      AppSpace.xs,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.sm,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.well,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                      border: Border.all(color: tokens.hairline, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${filtered.length}',
                          style: AppTheme.tabular(
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: tokens.ink,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        Text(
                          '${filteredNet >= 0 ? '+' : '−'}${currencyFormat.format(filteredNet.abs())}',
                          style: AppTheme.tabular(
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: filteredNet >= 0
                                      ? AppColors.revenueFor(context)
                                      : AppColors.expenseFor(context),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        HapticFeedback.lightImpact();
                        ref.invalidate(activeSeasonTransactionsProvider);
                        await Future.delayed(const Duration(milliseconds: 450));
                      },
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpace.md,
                          0,
                          AppSpace.md,
                          80,
                        ),
                        itemCount: flatItems.length,
                        itemBuilder: (context, index) {
                          final item = flatItems[index];
                          if (item is _LedgerHeaderItem) {
                            return Padding(
                              padding: EdgeInsets.only(
                                top: item.isFirst ? AppSpace.xs : AppSpace.md,
                                bottom: 6,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.title,
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
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
                                top: topRadius,
                                bottom: bottomRadius,
                              ),
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
                    ),
                  ),
                ],
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
            onAction: () => showTransactionSheet(
              context,
              initialMode: TransactionMode.harvest,
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.lightImpact();
            ref.invalidate(activeSeasonYieldLogsProvider);
            await Future.delayed(const Duration(milliseconds: 450));
          },
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(
              AppSpace.md,
              AppSpace.xs,
              AppSpace.md,
              80,
            ),
            children: [
              AppCard(
                child: Column(
                  children: [
                    for (int i = 0; i < yieldLogs.length; i++)
                      _HarvestTile(
                        log: yieldLogs[i],
                        currencyFormat: currencyFormat,
                        showDivider: i < yieldLogs.length - 1,
                        onTap: () => showTransactionSheet(
                          context,
                          yieldLog: yieldLogs[i],
                        ),
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
        ? '$dateText · $dispositionText (${log.destination})'
        : '$dateText · $dispositionText';

    return Dismissible(
      key: ValueKey(log.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: AppSpace.lg),
        color: AppColors.expenseFor(context),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Color(0xFFFDFCF9),
          size: 20,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: 11,
              ),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.wheatFor(context),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                  const SizedBox(width: AppSpace.compact),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${NumberFormat.decimalPattern(localeCode).format(log.totalWeight)} ${L10nHelpers.yieldUnitLabel(context, log.unit)}',
                          style: AppTheme.tabular(
                            Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: 1),
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
                              fontWeight: FontWeight.w600,
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
              color: hairlineColor,
            ),
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
