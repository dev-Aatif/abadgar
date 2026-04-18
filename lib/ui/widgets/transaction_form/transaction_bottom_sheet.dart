import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/active_season_provider.dart';
import '../../../core/providers/seasons_provider.dart';
import 'parts/expense_form.dart';
import 'parts/revenue_form.dart';
import 'parts/yield_form.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';

enum TransactionMode { expense, revenue, yield }

class TransactionBottomSheet extends ConsumerStatefulWidget {
  const TransactionBottomSheet({super.key});

  @override
  ConsumerState<TransactionBottomSheet> createState() => _TransactionBottomSheetState();
}

class _TransactionBottomSheetState extends ConsumerState<TransactionBottomSheet> {
  TransactionMode _mode = TransactionMode.expense;
  String? _sessionSeasonId;
  bool _selectingSeason = true;

  @override
  void initState() {
    super.initState();
    _sessionSeasonId = ref.read(activeSeasonIdProvider);
    if (_sessionSeasonId != null) {
      _selectingSeason = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        start: 24,
        end: 24,
        top: 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          if (_selectingSeason) ...[
            _buildSeasonSelector(),
          ] else ...[
            _buildHeaderNavigator(),
            const SizedBox(height: 16),
            _buildModeToggle(),
            const SizedBox(height: 24),
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildForm(seasonId: _sessionSeasonId!),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderNavigator() {
    final seasons = ref.watch(seasonsProvider).valueOrNull ?? [];
    final selectedSeason = seasons.firstWhere((s) => s.id == _sessionSeasonId, orElse: () => seasons.first);
    return InkWell(
      onTap: () => setState(() => _selectingSeason = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.agriculture_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(selectedSeason.name, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonSelector() {
    final seasons = ref.watch(seasonsProvider).valueOrNull ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Which crop/year is this for?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (seasons.isEmpty) 
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('No active crops found. Please start a season first.', textAlign: TextAlign.center),
          ),
        ...seasons.map((s) => ListTile(
          leading: Icon(s.cropType.value == 'Wheat' ? Icons.grass : Icons.water_drop, color: Theme.of(context).colorScheme.primary),
          title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${s.cropType.value} • Started ${DateFormat.yMMMd().format(s.startDate)}'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            ref.read(activeSeasonIdProvider.notifier).set(s.id);
            setState(() {
              _sessionSeasonId = s.id;
              _selectingSeason = false;
            });
          },
        )),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildModeToggle() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: TransactionMode.values.map((mode) {
          final isSelected = _mode == mode;
          String label;
          switch(mode) {
            case TransactionMode.expense: label = l10n.totalExpenses; break;
            case TransactionMode.revenue: label = l10n.totalRevenue; break;
            case TransactionMode.yield: label = l10n.yield; break;
          }
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _mode = mode);
                HapticFeedback.mediumImpact();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ] : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  label.split(' ').last.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildForm({required String seasonId}) {
    switch (_mode) {
      case TransactionMode.expense:
        return ExpenseForm(key: const ValueKey('expense'), seasonId: seasonId);
      case TransactionMode.revenue:
        return RevenueForm(key: const ValueKey('revenue'), seasonId: seasonId);
      case TransactionMode.yield:
        return YieldForm(key: const ValueKey('yield'), seasonId: seasonId);
    }
  }
}
