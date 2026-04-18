import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';
import '../../../../core/providers/transaction_repository_provider.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/utils/season_resolver.dart';
import 'form_shared.dart';

class RevenueForm extends ConsumerStatefulWidget {
  final String seasonId;
  const RevenueForm({super.key, required this.seasonId});

  @override
  ConsumerState<RevenueForm> createState() => _RevenueFormState();
}

class _RevenueFormState extends ConsumerState<RevenueForm> {
  final _amountController = TextEditingController();
  final _qtyController = TextEditingController();
  final _buyerController = TextEditingController();
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  final List<String> _categories = ['Primary Sale', 'Byproduct', 'Subsidy'];

  @override
  void dispose() {
    _amountController.dispose();
    _qtyController.dispose();
    _buyerController.dispose();
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
        type: TransactionType.revenue.value,
        category: _selectedCategory,
        quantity: double.tryParse(_qtyController.text),
        buyerName: _buyerController.text,
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
    final amount = double.tryParse(_amountController.text) ?? 0;
    final isValid = amount > 0 && _selectedCategory != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SharedAmountField(controller: _amountController),
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
                decoration: const InputDecoration(labelText: 'Buyer', prefixIcon: Icon(Icons.person_rounded)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            showCheckmark: false,
          )).toList(),
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
