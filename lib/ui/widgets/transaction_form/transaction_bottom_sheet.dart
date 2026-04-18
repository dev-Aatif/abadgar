import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/active_season_provider.dart';
import '../../../core/providers/seasons_provider.dart';
import '../../../core/providers/transaction_repository_provider.dart';
import '../../../core/constants/enums.dart';
import '../../../core/utils/season_resolver.dart';
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
    // If we already have an active season, skip selection unless clarified
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
          leading: Icon(s.cropType == 'Wheat' ? Icons.grass : Icons.water_drop, color: Theme.of(context).colorScheme.primary),
          title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${s.cropType} • Started ${DateFormat.yMMMd().format(s.startDate)}'),
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
        return _ExpenseForm(key: const ValueKey('expense'), seasonId: seasonId);
      case TransactionMode.revenue:
        return _RevenueForm(key: const ValueKey('revenue'), seasonId: seasonId);
      case TransactionMode.yield:
        return _YieldForm(key: const ValueKey('yield'), seasonId: seasonId);
    }
  }
}

class _ExpenseForm extends ConsumerStatefulWidget {
  final String seasonId;
  const _ExpenseForm({super.key, required this.seasonId});
  @override
  ConsumerState<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<_ExpenseForm> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  final List<String> _categories = ['Seed', 'Fertilizer', 'Labor', 'Fuel', 'Pesticide', 'Other'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final Map<String, String> categoryLabels = {
      'Seed': l10n.categorySeed,
      'Fertilizer': l10n.categoryFertilizer,
      'Labor': l10n.categoryLabor,
      'Fuel': l10n.categoryFuel,
      'Pesticide': l10n.categoryPesticide,
      'Other': l10n.categoryOther,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _amountController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
            prefixIcon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('PKR', style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900)),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
        const SizedBox(height: 24),
        Text(l10n.categoryOther, style: Theme.of(context).textTheme.labelLarge), // Using categoryOther for "Category" label foundation
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return ChoiceChip(
              label: Text(categoryLabels[cat] ?? cat),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedCategory = val ? cat : null),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              showCheckmark: false,
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 20),
                const SizedBox(width: 12),
                Text('Date: ${DateFormat.yMMMd().format(_selectedDate)}'),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(labelText: 'Notes', prefixIcon: Icon(Icons.notes_rounded)),
        ),
        const SizedBox(height: 32),
        _buildSaveButton(onPressed: _save),
      ],
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() async {
    final seasonId = resolveSeasonId(ref);
    if (seasonId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an active season first'), backgroundColor: Colors.redAccent),
        );
      }
      return;
    }
    try {
      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) return;
      
      await ref.read(transactionRepositoryProvider).saveTransaction(
        seasonId: seasonId,
        amount: amount,
        type: TransactionType.expense.value,
        category: _selectedCategory,
        notes: _notesController.text,
        date: _selectedDate,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Widget _buildSaveButton({required VoidCallback onPressed}) {
    final l10n = AppLocalizations.of(context)!;
    final amount = double.tryParse(_amountController.text) ?? 0;
    final isValid = amount > 0 && _selectedCategory != null;
    return ElevatedButton(
      onPressed: isValid ? onPressed : null,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(l10n.save, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _RevenueForm extends ConsumerStatefulWidget {
  final String seasonId;
  const _RevenueForm({super.key, required this.seasonId});
  @override
  ConsumerState<_RevenueForm> createState() => _RevenueFormState();
}

class _RevenueFormState extends ConsumerState<_RevenueForm> {
  final _amountController = TextEditingController();
  final _qtyController = TextEditingController();
  final _buyerController = TextEditingController();
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  final List<String> _categories = ['Primary Sale', 'Byproduct', 'Subsidy'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _amountController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
            prefixIcon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('PKR', style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900)),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            border: InputBorder.none,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
             Expanded(
               child: TextField(
                 controller: _qtyController,
                 keyboardType: TextInputType.number,
                 decoration: InputDecoration(labelText: '${l10n.categoryOther} (Kg)', prefixIcon: const Icon(Icons.scale_rounded)),
               ),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: TextField(
                 controller: _buyerController,
                 decoration: const InputDecoration(labelText: 'Buyer', prefixIcon: Icon(Icons.person_rounded)), // Localize Buyer later
               ),
             ),
          ],
        ),
        const SizedBox(height: 24),
        Text(l10n.totalRevenue, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _categories.map((cat) => ChoiceChip(
            label: Text(cat),
            selected: _selectedCategory == cat,
            onSelected: (val) => setState(() => _selectedCategory = val ? cat : null),
          )).toList(),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(l10n.save, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _qtyController.dispose();
    _buyerController.dispose();
    super.dispose();
  }

  void _save() async {
    final seasonId = resolveSeasonId(ref);
    if (seasonId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an active season first'), backgroundColor: Colors.redAccent),
        );
      }
      return;
    }
    try {
      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) return;

      await ref.read(transactionRepositoryProvider).saveTransaction(
        seasonId: seasonId,
        amount: amount,
        type: TransactionType.revenue.value,
        category: _selectedCategory,
        quantity: double.tryParse(_qtyController.text),
        buyerName: _buyerController.text,
        date: _selectedDate,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }
}

class _YieldForm extends ConsumerStatefulWidget {
  final String seasonId;
  const _YieldForm({super.key, required this.seasonId});
  @override
  ConsumerState<_YieldForm> createState() => _YieldFormState();
}

class _YieldFormState extends ConsumerState<_YieldForm> {
  final _yieldController = TextEditingController();
  String _unit = 'Mund (40kg)';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _yieldController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900),
          decoration: InputDecoration(
            hintText: '0.0',
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
            suffix: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(_unit.split(' ').first, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary.withOpacity(0.5), fontWeight: FontWeight.bold)),
            ),
            border: InputBorder.none,
          ),
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          value: _unit,
          decoration: const InputDecoration(labelText: 'Unit', prefixIcon: Icon(Icons.straighten_rounded)),
          items: ['Kg', 'Mund (40kg)', 'Tons'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
          onChanged: (val) => setState(() => _unit = val!),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('Log Yield', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _yieldController.dispose();
    super.dispose();
  }

  void _save() async {
    final seasonId = resolveSeasonId(ref);
    if (seasonId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an active season first'), backgroundColor: Colors.redAccent),
        );
      }
      return;
    }
    try {
      final weight = double.tryParse(_yieldController.text);
      if (weight == null || weight <= 0) return;

      await ref.read(transactionRepositoryProvider).saveYieldLog(
        seasonId: seasonId,
        totalWeight: weight,
        unit: _unit,
        date: DateTime.now(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }
}
