import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/financial_summary_provider.dart';
import '../../../core/providers/active_season_provider.dart';
import '../../../core/providers/transactions_provider.dart';
import '../../../core/constants/enums.dart';
import '../../../core/models/season.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/notifications.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(financialSummaryProvider);
    final activeSeason = ref.watch(activeSeasonProvider).valueOrNull;
    final transactions = ref.watch(activeSeasonTransactionsProvider).valueOrNull ?? [];
    final isAuthenticated = ref.watch(authStateProvider) != null;
    
    final currencyFormat = NumberFormat.currency(symbol: 'PKR ', decimalDigits: 0);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => context.push('/seasons'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Field Overview',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activeSeason?.displayName ?? 'No Active Season',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Manage Land',
                      onPressed: () => _showManageLandsSheet(context, ref),
                      icon: const Icon(Icons.landscape_rounded),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Change Season',
                      onPressed: () => context.push('/seasons'),
                      icon: const Icon(Icons.swap_horiz_rounded),
                    ),
                  ],
                ),
              ),
            ),

            if (!isAuthenticated)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_off_rounded, color: Theme.of(context).colorScheme.error, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Offline Mode. Sign in for backup.',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/auth'),
                          child: const Text('SIGN IN', style: TextStyle(fontSize: 10)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          onPressed: () {
                            // In a real app we'd save this preference.
                            // For now, we'll just implement the visual button.
                            AppNotification.show(context, 'Alert hidden for this session.');
                          },
                        ),
                      ],
                    ),
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
                    color: const Color(0xFF10B981), // Emerald
                    icon: Icons.trending_up_rounded,
                  ),
                  _MetricCard(
                    title: AppLocalizations.of(context)!.totalExpenses,
                    value: currencyFormat.format(summary?.totalExpenses ?? 0),
                    color: const Color(0xFFF59E0B), // Amber/Orange
                    icon: Icons.trending_down_rounded,
                  ),
                ]),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            
            // Profit Card
            SliverPadding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 20.0),
              sliver: SliverToBoxAdapter(
                child: _MetricCard(
                  title: AppLocalizations.of(context)!.netProfit,
                  value: currencyFormat.format(summary?.profit ?? 0),
                  color: Theme.of(context).colorScheme.primary,
                  icon: Icons.account_balance_wallet_rounded,
                  isWide: true,
                ),
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
                                    color: _getCategoryColor(e.key),
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
                                   Container(width: 12, height: 12, decoration: BoxDecoration(color: _getCategoryColor(cat), shape: BoxShape.circle)),
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
                    TextButton(onPressed: () {}, child: const Text('See All')), // To localize later
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
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: tx.type == TransactionType.revenue ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFF59E0B).withOpacity(0.1),
                          child: Icon(
                            tx.type == TransactionType.revenue ? Icons.add_rounded : Icons.remove_rounded,
                            color: tx.type == TransactionType.revenue ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          ),
                        ),
                        title: Text(tx.category ?? 'Other', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(DateFormat.yMMMd().format(tx.date)),
                        trailing: Text(
                          currencyFormat.format(tx.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: tx.type == TransactionType.revenue ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
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
    );
  }

  Color _getCategoryColor(String category) {
    final colors = [Colors.teal, const Color(0xFFFF6B6B), Colors.amber, Colors.indigo, Colors.brown, Colors.pink];
    return colors[category.hashCode % colors.length];
  }

  void _showManageLandsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Field Management', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 24),
              const Expanded(
                child: Center(child: Text('Land data list will appear here.')),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Add Land Logic
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('ADD NEW FIELD'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
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
              _MiniStat(label: 'Revenue', value: curFormat.format(summary?.totalRevenue ?? 0)),
              _MiniStat(label: 'Expenses', value: curFormat.format(summary?.totalExpenses ?? 0)),
              _MiniStat(label: 'Area', value: '${activeSeason?.landArea ?? 0} Acr'),
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
