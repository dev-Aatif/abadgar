import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/transactions_provider.dart';
import '../../../core/providers/active_season_provider.dart';
import '../../../core/constants/enums.dart';

// State for filtering
final ledgerFilterProvider = StateProvider<TransactionType?>((ref) => null);

class LedgerScreen extends ConsumerWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSeason = ref.watch(activeSeasonProvider).valueOrNull;
    final transactionsAsync = ref.watch(activeSeasonTransactionsProvider);
    final filter = ref.watch(ledgerFilterProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ledger', style: TextStyle(fontWeight: FontWeight.bold)),
            if (activeSeason != null)
              Text(
                activeSeason.displayName,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              color: filter != null ? Theme.of(context).colorScheme.primary : null,
            ),
            onPressed: () => _showFilterDialog(context, ref),
          ),
        ],
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          final filtered = filter == null 
              ? transactions 
              : transactions.where((t) => t.type == filter).toList();

          if (filtered.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final tx = filtered[index];
              final isRevenue = tx.type == TransactionType.revenue || tx.type == TransactionType.yield_;
              final color = isRevenue ? Colors.green : Colors.red;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.1),
                    child: Icon(
                      isRevenue ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      color: color,
                    ),
                  ),
                  title: Text(tx.category ?? 'Other', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(DateFormat('dd MMM').format(tx.date)),
                  trailing: Text(
                    '${isRevenue ? "+" : "-"}${currencyFormat.format(tx.amount)}',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showFilterDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter Transactions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: ref.watch(ledgerFilterProvider) == null,
                  onSelected: (_) {
                    ref.read(ledgerFilterProvider.notifier).state = null;
                    Navigator.pop(context);
                  },
                ),
                FilterChip(
                  label: const Text('Expenses'),
                  selected: ref.watch(ledgerFilterProvider) == TransactionType.expense,
                  onSelected: (_) {
                    ref.read(ledgerFilterProvider.notifier).state = TransactionType.expense;
                    Navigator.pop(context);
                  },
                ),
                FilterChip(
                  label: const Text('Revenue'),
                  selected: ref.watch(ledgerFilterProvider) == TransactionType.revenue,
                  onSelected: (_) {
                    ref.read(ledgerFilterProvider.notifier).state = TransactionType.revenue;
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No transactions found under this filter.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
