import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/financial_summary_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(financialSummaryProvider);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _MetricCard(
                title: 'Revenue',
                value: '\$${summary?.totalRevenue.toStringAsFixed(2) ?? "0.00"}',
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              _MetricCard(
                title: 'Expenses',
                value: '\$${summary?.totalExpenses.toStringAsFixed(2) ?? "0.00"}',
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              _MetricCard(
                title: 'Profit',
                value: '\$${summary?.profit.toStringAsFixed(2) ?? "0.00"}',
                color: Colors.blue,
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MetricCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodyLarge),
          Text(value, style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: color)),
        ],
      ),
    );
  }
}
