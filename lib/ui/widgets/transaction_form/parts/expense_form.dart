import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';
import '../../../../core/providers/transaction_repository_provider.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/utils/season_resolver.dart';
import 'form_shared.dart';

class ExpenseForm extends ConsumerStatefulWidget {
  final String seasonId;
  const ExpenseForm({super.key, required this.seasonId});

  @override
  ConsumerState<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<ExpenseForm> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  final List<String> _categories = ['Seed', 'Fertilizer', 'Labor', 'Fuel', 'Pesticide', 'Other'];

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() async {
    final seasonId = resolveSeasonId(ref);
    if (seasonId == null) return;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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
        Text(l10n.categoryOther, style: Theme.of(context).textTheme.labelLarge),
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
          onPressed: isValid ? _save : null,
          label: l10n.save,
        ),
      ],
    );
  }
}
