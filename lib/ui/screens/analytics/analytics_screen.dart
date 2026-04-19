import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/comparison_provider.dart';
import '../../../core/providers/seasons_provider.dart';
import '../../../core/providers/analytics_selection_provider.dart';

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
        title: const Text('Season Insights', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          seasonsAsync.when(
            data: (seasons) => seasons.isEmpty 
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(right: 8.0),
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
            error: (err, _) => Center(child: Text('Error loading insights: $err')),
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
          const SizedBox(height: 32),
          _buildExpenseBreakdown(context, comparison, format),
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
          'Detailed performance report for this season',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, SeasonComparison comparison, NumberFormat format) {
    final summary = comparison.currentSummary;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(context, 'Total Revenue', format.format(summary.totalRevenue), Icons.payments_rounded, Colors.green),
        _buildStatCard(context, 'Total Expenses', format.format(summary.totalExpenses), Icons.shopping_basket_rounded, Colors.orange),
        _buildStatCard(context, 'Net Profit', format.format(summary.profit), Icons.account_balance_rounded, Colors.blue),
        _buildStatCard(context, 'Cost / Acre', format.format(summary.totalExpenses / (comparison.currentSeason.landArea > 0 ? comparison.currentSeason.landArea : 1)), Icons.landscape_rounded, Colors.brown),
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
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded),
            SizedBox(width: 12),
            Expanded(child: Text('Add another season of this crop to see direct comparisons.')),
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
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Smart Comparison', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Your profit is ${comparison.profitVariance >= 0 ? 'up' : 'down'} by ${(comparison.profitVariance * 100).abs().toStringAsFixed(1)}% compared to ${comparison.previousSeason!.displayName}.',
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
        const Text('Expense Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        if (expenses.isEmpty)
           const Center(child: Text('No expenses recorded yet.'))
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Select a season from the top menu to view analytics.'),
        ],
      ),
    );
  }

  Widget _buildNoDataState(BuildContext context) {
    return const Center(child: Text('No data found for this season.'));
  }
}
