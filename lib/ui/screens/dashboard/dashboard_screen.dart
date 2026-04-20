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
import '../../../core/providers/lands_provider.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/ui_state_providers.dart';
import '../../../core/utils/notifications.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(financialSummaryProvider);
    final activeSeason = ref.watch(activeSeasonProvider).valueOrNull;
    final transactions = ref.watch(activeSeasonTransactionsProvider).valueOrNull ?? [];
    final isAuthenticated = ref.watch(authStateProvider) != null;
    final isOfflineVisible = ref.watch(isOfflineAlertVisibleProvider);
    
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

            if (!isAuthenticated && isOfflineVisible)
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
                            ref.read(isOfflineAlertVisibleProvider.notifier).state = false;
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
      builder: (context) => const _ManageLandsSheet(),
    );
  }
}

class _ManageLandsSheet extends ConsumerStatefulWidget {
  const _ManageLandsSheet();

  @override
  ConsumerState<_ManageLandsSheet> createState() => _ManageLandsSheetState();
}

class _ManageLandsSheetState extends ConsumerState<_ManageLandsSheet> {
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _submit() async {
    final name = _nameController.text.trim();
    final area = double.tryParse(_areaController.text) ?? 0;

    if (name.isEmpty || area <= 0) {
      AppNotification.show(context, 'Please enter valid name and area.', isError: true);
      return;
    }

    try {
      await ref.read(landsNotifierProvider.notifier).addLand(name: name, area: area);
      if (mounted) {
        setState(() {
          _isAdding = false;
          _nameController.clear();
          _areaController.clear();
        });
        AppNotification.show(context, 'Field added successfully!');
      }
    } catch (e) {
      if (mounted) {
        AppNotification.show(context, 'Failed to add field.', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final landsAsync = ref.watch(landsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isAdding ? 'Add New Field' : 'Field Management',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () {
                  if (_isAdding) {
                    setState(() => _isAdding = false);
                  } else {
                    Navigator.pop(context);
                  }
                },
                icon: Icon(_isAdding ? Icons.arrow_back_rounded : Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isAdding) ...[
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Field Name',
                prefixIcon: Icon(Icons.badge_rounded),
                hintText: 'e.g. North Side 40',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _areaController,
              decoration: const InputDecoration(
                labelText: 'Total Area (Acres)',
                prefixIcon: Icon(Icons.square_foot_rounded),
                hintText: 'e.g. 10.5',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('SAVE FIELD'),
            ),
          ] else ...[
            Expanded(
              child: landsAsync.when(
                data: (lands) {
                  if (lands.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.landscape_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No fields added yet.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: lands.length,
                    itemBuilder: (context, index) {
                      final land = lands[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            child: Icon(Icons.terrain_rounded, color: Theme.of(context).colorScheme.primary),
                          ),
                          title: Text(land.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${land.area} Acres'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                            onPressed: () => ref.read(landsNotifierProvider.notifier).deleteLand(land.id),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() => _isAdding = true),
              icon: const Icon(Icons.add_rounded),
              label: const Text('ADD NEW FIELD'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ],
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
