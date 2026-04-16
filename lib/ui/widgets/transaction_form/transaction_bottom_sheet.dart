import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildForm(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SegmentedButton<TransactionMode>(
      style: SegmentedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        minimumSize: const Size(0, 56),
      ),
      segments: const [
        ButtonSegment(
          value: TransactionMode.expense,
          label: Text('EXPENSE', style: TextStyle(fontWeight: FontWeight.bold)),
          icon: Icon(Icons.remove_circle_outline),
        ),
        ButtonSegment(
          value: TransactionMode.revenue,
          label: Text('REVENUE', style: TextStyle(fontWeight: FontWeight.bold)),
          icon: Icon(Icons.add_circle_outline),
        ),
        ButtonSegment(
          value: TransactionMode.yield,
          label: Text('YIELD', style: TextStyle(fontWeight: FontWeight.bold)),
          icon: Icon(Icons.agriculture),
        ),
      ],
      selected: {_mode},
      onSelectionChanged: (Set<TransactionMode> newSelection) {
        setState(() {
          _mode = newSelection.first;
        });
        HapticFeedback.lightImpact();
      },
    );
  }

  Widget _buildForm() {
    switch (_mode) {
      case TransactionMode.expense:
        return const _ExpenseForm();
      case TransactionMode.revenue:
        return const _RevenueForm();
      case TransactionMode.yield:
        return const _YieldForm();
    }
  }
}

class _ExpenseForm extends ConsumerStatefulWidget {
  const _ExpenseForm();

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
        TextFormField(
          controller: _amountController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32),
          decoration: const InputDecoration(
            labelText: 'Enter Amount',
            prefixText: '\$ ',
            hintText: '0.00',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 24),
        Text('Category', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCategory = selected ? cat : null);
                HapticFeedback.selectionClick();
              },
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        ListTile(
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text('Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
        ),
        const SizedBox(height: 32),
        _buildSaveButton(onPressed: _save),
      ],
    );
  }

  void _save() async {
    final activeSeasonId = ref.read(activeSeasonIdProvider);
    if (activeSeasonId == null) {
      _showError('You must select an Active Season first!');
      return;
    }

    try {
      await ref.read(transactionRepositoryProvider).saveTransaction(
        seasonId: activeSeasonId,
        amount: double.parse(_amountController.text),
        type: 'Expense',
        category: _selectedCategory,
        notes: _notesController.text,
        date: _selectedDate,
      );
      _onSuccess();
    } catch (e) {
      _showError('Failed to save transaction');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onSuccess() {
    HapticFeedback.heavyImpact();
    Navigator.pop(context);
  }

  Widget _buildSaveButton({required VoidCallback onPressed}) {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final isValid = amount > 0 && _selectedCategory != null;

    return ElevatedButton(
      onPressed: isValid ? onPressed : null,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: const Text('SAVE RECORD', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
    );
  }
}

class _RevenueForm extends ConsumerStatefulWidget {
  const _RevenueForm();

  @override
  ConsumerState<_RevenueForm> createState() => _RevenueFormState();
}

class _RevenueFormState extends ConsumerState<_RevenueForm> {
  final _amountController = TextEditingController();
  final _quantityController = TextEditingController();
  final _buyerController = TextEditingController();
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  final List<String> _categories = ['Primary Sale', 'Byproduct', 'Subsidy'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount Earned', prefixText: '\$ '),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Qty (Kg)', hintText: '0'),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Revenue Source', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCategory = selected ? cat : null);
                HapticFeedback.selectionClick();
              },
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _buyerController,
          decoration: const InputDecoration(labelText: 'Buyer Name (Optional)', hintText: 'Enter name'),
        ),
        const SizedBox(height: 32),
        _buildSaveButton(onPressed: _save),
      ],
    );
  }

  void _save() async {
    final activeSeasonId = ref.read(activeSeasonIdProvider);
    if (activeSeasonId == null) {
      _showError('You must select an Active Season first!');
      return;
    }

    try {
      await ref.read(transactionRepositoryProvider).saveTransaction(
        seasonId: activeSeasonId,
        amount: double.parse(_amountController.text),
        type: 'Revenue',
        category: _selectedCategory,
        quantity: double.tryParse(_quantityController.text),
        buyerName: _buyerController.text,
        date: _selectedDate,
      );
      _onSuccess();
    } catch (e) {
      _showError('Failed to save record');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _onSuccess() {
    HapticFeedback.heavyImpact();
    Navigator.pop(context);
  }

  Widget _buildSaveButton({required VoidCallback onPressed}) {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final qty = double.tryParse(_quantityController.text) ?? 0;
    final isValid = amount > 0 && qty > 0 && _selectedCategory != null;

    return ElevatedButton(
      onPressed: isValid ? onPressed : null,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 64),
      ),
      child: const Text('SAVE REVENUE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
    );
  }
}

class _YieldForm extends ConsumerStatefulWidget {
  const _YieldForm();

  @override
  ConsumerState<_YieldForm> createState() => _YieldFormState();
}

class _YieldFormState extends ConsumerState<_YieldForm> {
  final _weightController = TextEditingController();
  String _unit = 'Kg';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _weightController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32),
          decoration: const InputDecoration(labelText: 'Total Weight Harvested', hintText: '0.00'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 24),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'Kg', label: Text('Kgs')),
            ButtonSegment(value: 'Tons', label: Text('Tons')),
          ],
          selected: {_unit},
          onSelectionChanged: (set) => setState(() => _unit = set.first),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: (double.tryParse(_weightController.text) ?? 0) > 0 ? _save : null,
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 64)),
          child: const Text('SAVE YIELD LOG', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }

  void _save() async {
    final activeSeasonId = ref.read(activeSeasonIdProvider);
    if (activeSeasonId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must select an Active Season first!'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await ref.read(transactionRepositoryProvider).saveYieldLog(
        seasonId: activeSeasonId,
        totalWeight: double.parse(_weightController.text),
        unit: _unit,
        date: DateTime.now(),
      );
      HapticFeedback.heavyImpact();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save yield'), backgroundColor: Colors.red),
      );
    }
  }
}
