import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/analytics_provider.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(comparativeAnalyticsProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'PKR ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights & Comparisons'),
      ),
      body: analytics.isEmpty 
        ? const Center(child: Text('Not enough data for comparison yet.'))
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: analytics.length,
            itemBuilder: (context, index) {
              final data = analytics[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.analytics_rounded, color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(width: 16),
                          Text(data.category, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ...data.yearlyTotals.entries.map((yearEntry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(yearEntry.key.toString(), style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                              Text(currencyFormat.format(yearEntry.value), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        );
                      }).toList(),
                      const Divider(height: 32),
                      _buildTrend(data.yearlyTotals),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  Widget _buildTrend(Map<int, double> yearlyTotals) {
    if (yearlyTotals.length < 2) return const SizedBox.shrink();
    
    final years = yearlyTotals.keys.toList()..sort();
    final latestYear = years.last;
    final previousYear = years[years.length - 2];
    
    final latestVal = yearlyTotals[latestYear]!;
    final prevVal = yearlyTotals[previousYear]!;
    
    // Guard against division by zero
    if (prevVal == 0) {
      return Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.grey, size: 16),
          const SizedBox(width: 8),
          Text(
            'No data for $previousYear to compare',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      );
    }

    final percentChange = ((latestVal - prevVal) / prevVal) * 100;
    final isDegrading = percentChange > 0;

    return Row(
      children: [
        Icon(
          isDegrading ? Icons.trending_up : Icons.trending_down, 
          color: isDegrading ? Colors.redAccent : Colors.greenAccent,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          '${percentChange.abs().toStringAsFixed(1)}% ${isDegrading ? 'higher' : 'lower'} than $previousYear',
          style: TextStyle(
            color: isDegrading ? Colors.redAccent : Colors.greenAccent,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
