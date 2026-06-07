import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/transactions_provider.dart';
import '../../../core/providers/active_season_provider.dart';
import '../../../core/constants/enums.dart';
import '../../../core/models/transaction.dart';
import '../../widgets/transaction_form/transaction_bottom_sheet.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';

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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.ledger, style: const TextStyle(fontWeight: FontWeight.bold)),
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
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Financials'),
            Tab(text: 'Harvests'),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          _buildFinancialsTab(context, ref, transactionsAsync, filter, currencyFormat),
          _buildHarvestsTab(context, ref),
        ],
      ),
    );
  }

  Widget _buildFinancialsTab(
    BuildContext context, 
    WidgetRef ref, 
    AsyncValue<List<Transaction>> transactionsAsync, 
    TransactionType? filter, 
    NumberFormat currencyFormat,
  ) {
    return transactionsAsync.when(
        data: (transactions) {
          final filtered = filter == null 
              ? transactions 
              : transactions.where((t) => t.type == filter).toList();

          if (filtered.isEmpty) {
            return _buildEmptyState(context);
          }

          final Map<String, List<Transaction>> grouped = {};
          for (var tx in filtered) {
            final month = DateFormat('MMMM yyyy').format(tx.date);
            grouped.putIfAbsent(month, () => []).add(tx);
          }

          final groupedEntries = grouped.entries.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedEntries.length,
            itemBuilder: (context, index) {
              final entry = groupedEntries[index];
              final monthString = entry.key;
              final monthTransactions = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8, bottom: 8, top: index == 0 ? 0 : 16),
                    child: Text(
                      monthString.toUpperCase(),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  ...monthTransactions.map((tx) {
                    final isRevenue = tx.type == TransactionType.revenue || tx.type == TransactionType.yield_;
                    final color = isRevenue ? Colors.green : Colors.red;

                    return Dismissible(
                      key: ValueKey(tx.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsetsDirectional.only(end: 20),
                        margin: const EdgeInsets.only(bottom: 12),
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
                              title: const Text('Confirm Delete'),
                              content: const Text('Are you sure you want to delete this transaction?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true), 
                                  child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) {
                        ref.read(transactionsNotifierProvider.notifier).deleteTransaction(tx.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Transaction deleted')),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: InkWell(
                          onTap: () => _showEditTransactionSheet(context, tx),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: color.withOpacity(0.1),
                              child: Icon(
                                isRevenue ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                color: color,
                              ),
                            ),
                            title: Text(tx.category ?? AppLocalizations.of(context)!.other, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(DateFormat('dd MMM').format(tx.date)),
                            trailing: Text(
                              '${isRevenue ? "+" : "-"}${currencyFormat.format(tx.amount)}',
                              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(AppLocalizations.of(context)!.errorGeneral(err.toString()))),
      );
  }

  Widget _buildHarvestsTab(BuildContext context, WidgetRef ref) {
    final yieldLogsAsync = ref.watch(activeSeasonYieldLogsProvider);

    return yieldLogsAsync.when(
      data: (yieldLogs) {
        if (yieldLogs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.eco_rounded, size: 64, color: Colors.grey.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text('No harvests logged yet.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: yieldLogs.length,
          itemBuilder: (context, index) {
            final log = yieldLogs[index];
            final color = Colors.amber.shade700;

            return Dismissible(
              key: ValueKey(log.id),
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
                      title: const Text('Confirm Delete'),
                      content: const Text('Are you sure you want to delete this harvest record?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true), 
                          child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    );
                  },
                );
              },
              onDismissed: (direction) {
                ref.read(transactionsNotifierProvider.notifier).deleteYieldLog(log.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Harvest record deleted')),
                );
              },
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  onTap: () => _showEditYieldLogSheet(context, log),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.1),
                      child: Icon(Icons.eco_rounded, color: color),
                    ),
                    title: Text('${log.totalWeight} ${log.unit}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${DateFormat('dd MMM').format(log.date)} • ${log.disposition.toUpperCase()}'),
                    trailing: log.salePrice != null
                        ? Text(
                            'Rs ${log.salePrice!.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                          )
                        : null,
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading harvests: $err')),
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
            Text(AppLocalizations.of(context)!.filterTransactions, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: Text(AppLocalizations.of(context)!.filterAll),
                  selected: ref.watch(ledgerFilterProvider) == null,
                  onSelected: (_) {
                    ref.read(ledgerFilterProvider.notifier).state = null;
                    Navigator.pop(context);
                  },
                ),
                FilterChip(
                  label: Text(AppLocalizations.of(context)!.filterExpenses),
                  selected: ref.watch(ledgerFilterProvider) == TransactionType.expense,
                  onSelected: (_) {
                    ref.read(ledgerFilterProvider.notifier).state = TransactionType.expense;
                    Navigator.pop(context);
                  },
                ),
                FilterChip(
                  label: Text(AppLocalizations.of(context)!.filterRevenue),
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

  void _showEditTransactionSheet(BuildContext context, Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionBottomSheet(transaction: transaction),
    );
  }

  void _showEditYieldLogSheet(BuildContext context, dynamic yieldLog) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionBottomSheet(yieldLog: yieldLog),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.noTransactionsFilter, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
