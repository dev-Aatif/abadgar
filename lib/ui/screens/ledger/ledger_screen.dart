import 'package:flutter/material.dart';

class LedgerScreen extends StatelessWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
          title: Text('Transaction $index', style: Theme.of(context).textTheme.bodyLarge),
          subtitle: const Text('Category • Note placeholder'),
          trailing: Text('\$100.00', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red)),
        );
      },
    );
  }
}
