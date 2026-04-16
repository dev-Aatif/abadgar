import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/active_season_provider.dart';
import '../widgets/transaction_form/transaction_bottom_sheet.dart';

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSeason = ref.watch(activeSeasonProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          activeSeason?.name ?? 'No Active Season',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        centerTitle: false,
        actions: [
          if (navigationShell.currentIndex == 1) // Ledger
            IconButton(
              iconSize: 32,
              onPressed: () {},
              icon: const Icon(Icons.filter_list),
            ),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard, size: 32),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long, size: 32),
            label: 'Ledger',
          ),
          NavigationDestination(
            icon: Icon(Icons.agriculture, size: 32),
            label: 'Seasons',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings, size: 32),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(top: 32),
        height: 72,
        width: 72,
        child: FloatingActionButton(
          onPressed: () => _showNewTransactionForm(context),
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 40),
        ),
      ),
    );
  }

  void _showNewTransactionForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const TransactionBottomSheet(),
    );
  }
}
