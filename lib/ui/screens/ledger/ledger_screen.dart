import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/transactions_provider.dart';

class LedgerScreen extends ConsumerWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(activeSeasonTransactionsProvider);

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return const Center(child: Text('No transactions yet.'));
        }

        return ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final tx = transactions[index];
            final isExpense = tx.type == 'Expense';
            final color = isExpense ? Colors.red : Colors.green;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(
                  isExpense ? Icons.remove : Icons.add,
                  color: color,
                ),
              ),
              title: Text(
                tx.category ?? 'Uncategorized',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(
                '${DateFormat('dd MMM yyyy').format(tx.date)} ${tx.notes != null ? "• ${tx.notes}" : ""}',
              ),
              trailing: Text(
                '${isExpense ? "-" : "+"}\$${tx.amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
