import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/financial_summary_provider.dart';
import '../../../core/providers/active_season_provider.dart';
import '../../../core/providers/transactions_provider.dart';
import '../../../core/providers/comparison_provider.dart';
import '../../../core/constants/enums.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/season.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/seasons_provider.dart';
import '../../../core/providers/ui_state_providers.dart';
import '../../../core/utils/notifications.dart';
import 'package:flutter/services.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(financialSummaryProvider);
    final activeSeason = ref.watch(activeSeasonProvider).valueOrNull;
    final transactions = ref.watch(activeSeasonTransactionsProvider).valueOrNull ?? [];
    final isAuthenticated = ref.watch(authStateProvider) != null;
    final isOfflineVisible = ref.watch(isOfflineAlertVisibleProvider);
    final seasonsList = ref.watch(seasonsProvider).valueOrNull ?? [];
    final comparisonAsync = activeSeason != null ? ref.watch(seasonComparisonProvider(activeSeason.id)) : null;
    
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);

    if (seasonsList.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.eco_rounded, size: 80, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.welcomeTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.welcomeSubtext,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                ElevatedButton.icon(
                  onPressed: () => context.push('/seasons'),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(AppLocalizations.of(context)!.startNewSeason),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            await Future.delayed(const Duration(milliseconds: 800));
          },
          child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.fieldOverview,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (seasonsList.isNotEmpty && activeSeason != null)
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: activeSeason.id,
                                isDense: true,
                                isExpanded: true,
                                icon: Icon(Icons.arrow_drop_down_rounded, color: Theme.of(context).colorScheme.onSurface),
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                                items: seasonsList.map((s) {
                                  return DropdownMenuItem<String>(
                                    value: s.id,
                                    child: Text(s.displayName),
                                  );
                                }).toList(),
                                onChanged: (newId) {
                                  if (newId != null && newId != activeSeason.id) {
                                    ref.read(activeSeasonIdProvider.notifier).set(newId);
                                  }
                                },
                              ),
                            )
                          else
                            Text(
                              AppLocalizations.of(context)!.noActiveSeason,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (!isAuthenticated) ...[
                          Tooltip(
                            message: AppLocalizations.of(context)!.offlineAlert,
                            child: Icon(Icons.cloud_off_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(width: 16),
                        ],
                        IconButton.filledTonal(
                          tooltip: AppLocalizations.of(context)!.changeSeason,
                          onPressed: () => context.push('/seasons'),
                          icon: const Icon(Icons.list_alt_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Metrics Summary
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: _QuickSummaryCard(activeSeason: activeSeason, summary: summary),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Metrics Grid
            SliverPadding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 20.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.4, // Slightly taller for regional scripts
                ),
                delegate: SliverChildListDelegate([
                    _MetricCard(
                    title: AppLocalizations.of(context)!.totalRevenue,
                    value: currencyFormat.format(summary?.totalRevenue ?? 0),
                    color: AppColors.revenue,
                    icon: Icons.trending_up_rounded,
                  ),
                  _MetricCard(
                    title: AppLocalizations.of(context)!.totalExpenses,
                    value: currencyFormat.format(summary?.totalExpenses ?? 0),
                    color: AppColors.expense,
                    icon: Icons.trending_down_rounded,
                  ),
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Season Comparison Card
            if (comparisonAsync != null)
              SliverToBoxAdapter(
                child: comparisonAsync.when(
                  data: (comparison) {
                    if (comparison == null || comparison.previousSeason == null) return const SizedBox.shrink();
                    final variance = comparison.profitVariance;
                    final isUp = variance >= 0;
                    final pct = (variance.abs() * 100).toStringAsFixed(1);
                    final prevName = comparison.previousSeason!.name;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isUp
                              ? [AppColors.revenue.withOpacity(0.08), AppColors.revenue.withOpacity(0.02)]
                              : [AppColors.expense.withOpacity(0.08), AppColors.expense.withOpacity(0.02)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: (isUp ? AppColors.revenue : AppColors.expense).withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (isUp ? AppColors.revenue : AppColors.expense).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                color: isUp ? AppColors.revenue : AppColors.expense,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isUp
                                      ? AppLocalizations.of(context)!.profitVarianceUp(pct, prevName)
                                      : AppLocalizations.of(context)!.profitVarianceDown(pct, prevName),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isUp ? AppColors.revenue : AppColors.expense,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${AppLocalizations.of(context)!.netProfit}: ${currencyFormat.format(comparison.currentSummary.profit)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Chart Section
            if (summary != null && summary.expenseByCategory.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)!.totalExpenses, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 4,
                                centerSpaceRadius: 40,
                                sections: summary.expenseByCategory.entries.map((e) {
                                  return PieChartSectionData(
                                    color: AppColors.forCategory(e.key),
                                    value: e.value,
                                    title: '',
                                    radius: 50,
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: summary.expenseByCategory.keys.map((cat) {
                               return Row(
                                 mainAxisSize: MainAxisSize.min,
                                 children: [
                                   Container(width: 12, height: 12, decoration: BoxDecoration(color: AppColors.forCategory(cat), shape: BoxShape.circle)),
                                   const SizedBox(width: 4),
                                   Text(cat, style: const TextStyle(fontSize: 12)),
                                 ],
                               );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Recent Transactions
            SliverPadding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 20.0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocalizations.of(context)!.ledger, style: Theme.of(context).textTheme.titleLarge),
                    TextButton(onPressed: () => context.go('/ledger'), child: Text(AppLocalizations.of(context)!.seeAll)),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 20.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tx = transactions[index];
                    return Dismissible(
                      key: ValueKey(tx.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsetsDirectional.only(end: 20),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(AppLocalizations.of(context)!.confirmDeleteTransactionTitle),
                              content: const Text('Are you sure you want to delete this transaction?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(AppLocalizations.of(context)!.cancel)),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true), 
                                  child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.redAccent)),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) {
                        ref.read(transactionsNotifierProvider.notifier).deleteTransaction(tx.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context)!.transactionDeleted)),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _showEditTransactionSheet(context, tx),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: tx.type == TransactionType.revenue ? AppColors.revenue.withOpacity(0.1) : AppColors.expense.withOpacity(0.1),
                              child: Icon(
                                tx.type == TransactionType.revenue ? Icons.add_rounded : Icons.remove_rounded,
                                color: tx.type == TransactionType.revenue ? AppColors.revenue : AppColors.expense,
                              ),
                            ),
                            title: Text(tx.category ?? 'Other', style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(DateFormat.yMMMd().format(tx.date)),
                            trailing: Text(
                              currencyFormat.format(tx.amount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: tx.type == TransactionType.revenue ? AppColors.revenue : AppColors.expense,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: transactions.length > 5 ? 5 : transactions.length,
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
        ),
      ),
    );
  }

  // Category colors now centralized in AppColors.forCategory()

  void _showEditTransactionSheet(BuildContext context, Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionBottomSheet(transaction: transaction),
    );
  }
}



class _QuickSummaryCard extends StatelessWidget {
  final Season? activeSeason;
  final FinancialSummary? summary;

  const _QuickSummaryCard({this.activeSeason, this.summary});

  @override
  Widget build(BuildContext context) {
    final curFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);
    final profit = summary?.profit ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SEASON PROFIT', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text(
                    curFormat.format(profit),
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  activeSeason?.cropType.value ?? 'N/A',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniStat(label: AppLocalizations.of(context)!.revenue, value: curFormat.format(summary?.totalRevenue ?? 0)),
              _MiniStat(label: AppLocalizations.of(context)!.expenses, value: curFormat.format(summary?.totalExpenses ?? 0)),
              _MiniStat(label: AppLocalizations.of(context)!.areaLabel, value: '${activeSeason?.landArea ?? 0} ${AppLocalizations.of(context)!.acresUnitShort}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final bool isWide;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isWide ? 20 : 16,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
