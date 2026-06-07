import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';
import '../../../../core/providers/transactions_provider.dart';
import '../../../../core/utils/notifications.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/utils/season_resolver.dart';
import '../../../../core/models/transaction.dart';
import 'form_shared.dart';

class GenericTransactionForm extends ConsumerStatefulWidget {
  final String seasonId;
  final TransactionType type;
  final Transaction? transaction;

  const GenericTransactionForm({
    super.key, 
    required this.seasonId, 
    required this.type,
    this.transaction,
  });

  @override
  ConsumerState<GenericTransactionForm> createState() => _GenericTransactionFormState();
}

class _GenericTransactionFormState extends ConsumerState<GenericTransactionForm> {
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  late final List<String> _categories;

  @override
  void initState() {
    super.initState();
    _categories = widget.type == TransactionType.expense 
      ? ['Seed', 'Fertilizer', 'Labor', 'Fuel', 'Pesticide', 'Other']
      : ['Harvest Sale', 'Subsidy', 'Other'];

    if (widget.transaction != null) {
      _amountController = TextEditingController(text: widget.transaction!.amount.toString());
      _notesController = TextEditingController(text: widget.transaction!.notes ?? '');
      _selectedCategory = widget.transaction!.category;
      _selectedDate = widget.transaction!.date;
    } else {
      _amountController = TextEditingController();
      _notesController = TextEditingController();
    }
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
      AppNotification.show(context, 'No active season selected.', isError: true);
      return;
    }

    try {
      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) {
        AppNotification.show(context, 'Please enter a valid amount.', isError: true);
        return;
      }

      if (_selectedCategory == null) {
        AppNotification.show(context, 'Please select a category.', isError: true);
        return;
      }

      if (widget.transaction != null) {
        await ref.read(transactionsNotifierProvider.notifier).updateTransaction(
          id: widget.transaction!.id,
          amount: amount,
          type: widget.type.value,
          category: _selectedCategory!,
          notes: _notesController.text,
          date: _selectedDate,
        );
      } else {
        await ref.read(transactionsNotifierProvider.notifier).addTransaction(
          seasonId: seasonId,
          amount: amount,
          type: widget.type.value,
          category: _selectedCategory!,
          notes: _notesController.text,
          date: _selectedDate,
        );
      }
      
      if (mounted) {
        AppNotification.show(context, '${widget.type == TransactionType.expense ? "Expense" : "Revenue"} saved successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppNotification.show(context, 'Failed to save transaction: $e', isError: true);
      }
    }
  }

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

    final amount = double.tryParse(_amountController.text) ?? 0;
    final isValid = amount > 0 && _selectedCategory != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SharedAmountField(controller: _amountController),
        const SizedBox(height: 24),
        Text('Category', style: Theme.of(context).textTheme.labelLarge),
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
        SharedSaveButton(
          onPressed: (isValid && !ref.watch(transactionsNotifierProvider).isLoading) ? _save : null,
          label: ref.watch(transactionsNotifierProvider).isLoading ? 'Saving...' : l10n.save,
        ),
      ],
    );
  }
}
