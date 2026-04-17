import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/active_season_provider.dart';
import '../../../core/providers/transaction_repository_provider.dart';

enum TransactionMode { expense, revenue, yield }

class TransactionBottomSheet extends ConsumerStatefulWidget {
  const TransactionBottomSheet({super.key});

  @override
  ConsumerState<TransactionBottomSheet> createState() => _TransactionBottomSheetState();
}

class _TransactionBottomSheetState extends ConsumerState<TransactionBottomSheet> {
  TransactionMode _mode = TransactionMode.expense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
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
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildModeToggle(),
          const SizedBox(height: 32),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
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
                  mode.name.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildForm() {
    switch (_mode) {
      case TransactionMode.expense:
        return _ExpenseForm(key: const ValueKey('expense'));
      case TransactionMode.revenue:
        return _RevenueForm(key: const ValueKey('revenue'));
      case TransactionMode.yield:
        return _YieldForm(key: const ValueKey('yield'));
    }
  }
}

class _ExpenseForm extends ConsumerStatefulWidget {
  const _ExpenseForm({super.key});
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
            hintText: '0',
            prefixText: 'PKR ',
            prefixStyle: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
        const SizedBox(height: 24),
        Text('Category', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return ChoiceChip(
              label: Text(cat),
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

  void _save() async {
    final seasonId = ref.read(activeSeasonIdProvider);
    if (seasonId == null) return;
    try {
      await ref.read(transactionRepositoryProvider).saveTransaction(
        seasonId: seasonId,
        amount: double.parse(_amountController.text),
        type: 'Expense',
        category: _selectedCategory,
        notes: _notesController.text,
        date: _selectedDate,
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Widget _buildSaveButton({required VoidCallback onPressed}) {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final isValid = amount > 0 && _selectedCategory != null;
    return ElevatedButton(
      onPressed: isValid ? onPressed : null,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: const Text('Save Expense', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _RevenueForm extends ConsumerStatefulWidget {
  const _RevenueForm({super.key});
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _amountController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900),
          decoration: const InputDecoration(hintText: '0', prefixText: 'PKR ', border: InputBorder.none),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
             Expanded(
               child: TextField(
                 controller: _qtyController,
                 keyboardType: TextInputType.number,
                 decoration: const InputDecoration(labelText: 'Quantity (Kg)', prefixIcon: Icon(Icons.scale_rounded)),
               ),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: TextField(
                 controller: _buyerController,
                 decoration: const InputDecoration(labelText: 'Buyer', prefixIcon: Icon(Icons.person_rounded)),
               ),
             ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Revenue Source', style: Theme.of(context).textTheme.labelLarge),
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
          child: const Text('Save Revenue', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _save() async {
    final seasonId = ref.read(activeSeasonIdProvider);
    if (seasonId == null) return;
    try {
      await ref.read(transactionRepositoryProvider).saveTransaction(
        seasonId: seasonId,
        amount: double.parse(_amountController.text),
        type: 'Revenue',
        category: _selectedCategory,
        quantity: double.tryParse(_qtyController.text),
        buyerName: _buyerController.text,
        date: _selectedDate,
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}

class _YieldForm extends ConsumerStatefulWidget {
  const _YieldForm({super.key});
  @override
  ConsumerState<_YieldForm> createState() => _YieldFormState();
}

class _YieldFormState extends ConsumerState<_YieldForm> {
  final _yieldController = TextEditingController();
  String _unit = 'Mund (40kg)';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _yieldController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900),
          decoration: const InputDecoration(hintText: '0', suffixText: ' Harvested', border: InputBorder.none),
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

  void _save() async {
    final seasonId = ref.read(activeSeasonIdProvider);
    if (seasonId == null) return;
    try {
      await ref.read(transactionRepositoryProvider).saveYieldLog(
        seasonId: seasonId,
        totalWeight: double.parse(_yieldController.text),
        unit: _unit,
        date: DateTime.now(),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
