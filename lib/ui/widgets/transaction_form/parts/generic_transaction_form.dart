import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/categories.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/models/transaction.dart';
import '../../../../core/providers/active_season_provider.dart';
import '../../../../core/providers/transactions_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n_helpers.dart';
import '../../../../core/utils/notifications.dart';
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
  ConsumerState<GenericTransactionForm> createState() =>
      _GenericTransactionFormState();
}

class _GenericTransactionFormState
    extends ConsumerState<GenericTransactionForm> {
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  final FocusNode _amountFocusNode = FocusNode();
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _amountController = TextEditingController(
        text: widget.transaction!.amount ==
                widget.transaction!.amount.roundToDouble()
            ? widget.transaction!.amount.toInt().toString()
            : widget.transaction!.amount.toString(),
      );
      _notesController =
          TextEditingController(text: widget.transaction!.notes ?? '');
      _selectedCategory = widget.transaction!.category;
      _selectedDate = widget.transaction!.date;
    } else {
      _amountController = TextEditingController();
      _notesController = TextEditingController();
    }
    _amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _notesController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<bool> _saveTransaction() async {
    final l10n = AppLocalizations.of(context)!;
    final seasonId = widget.seasonId;
    if (seasonId.isEmpty) {
      AppNotification.show(context, l10n.noActiveSeason, isError: true);
      return false;
    }

    try {
      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0 || _selectedCategory == null) {
        return false;
      }

      if (widget.transaction != null) {
        await ref.read(transactionsNotifierProvider.notifier).updateTransaction(
              id: widget.transaction!.id,
              amount: amount,
              type: widget.type.value,
              category: _selectedCategory!,
              notes: _notesController.text.trim(),
              date: _selectedDate,
            );
      } else {
        await ref.read(transactionsNotifierProvider.notifier).addTransaction(
              seasonId: seasonId,
              amount: amount,
              type: widget.type.value,
              category: _selectedCategory!,
              notes: _notesController.text.trim(),
              date: _selectedDate,
            );
      }
      return true;
    } catch (e) {
      if (mounted) {
        AppNotification.show(context, l10n.errorGeneral(e.toString()),
            isError: true);
      }
      return false;
    }
  }

  void _saveAndClose() async {
    final success = await _saveTransaction();
    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  void _saveAndAddAnother() async {
    final l10n = AppLocalizations.of(context)!;
    final success = await _saveTransaction();
    if (success && mounted) {
      AppNotification.show(context, l10n.saveAndAddAnother);
      setState(() {
        _amountController.clear();
        _notesController.clear();
        _selectedDate = DateTime.now();
      });
      _amountFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeSeason = ref.watch(activeSeasonProvider).valueOrNull;
    final categories = List<String>.of(
      widget.type == TransactionType.expense
          ? AppCategories.expenses
          : AppCategories.revenueForCrop(activeSeason?.cropType),
    );

    if (widget.transaction != null &&
        _selectedCategory != null &&
        !categories.contains(_selectedCategory)) {
      categories.insert(0, _selectedCategory!);
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    final isValid = amount > 0 && _selectedCategory != null;
    final isLoading = ref.watch(transactionsNotifierProvider).isLoading;
    final isEditing = widget.transaction != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SharedAmountField(
          controller: _amountController,
          focusNode: _amountFocusNode,
          autofocus: !isEditing,
        ),
        const SizedBox(height: AppSpace.lg),
        Text(l10n.category, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpace.xs),
        Wrap(
          spacing: AppSpace.xs,
          runSpacing: AppSpace.xs,
          children: categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return ChoiceChip(
              avatar: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.forCategory(cat),
                  shape: BoxShape.circle,
                ),
              ),
              label: Text(L10nHelpers.categoryLabel(context, cat)),
              selected: isSelected,
              showCheckmark: false,
              onSelected: (val) {
                HapticFeedback.selectionClick();
                FocusScope.of(context).unfocus();
                setState(() => _selectedCategory = val ? cat : null);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpace.lg),
        Text(l10n.dateLabel, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpace.xs),
        QuickDateSelector(
          selectedDate: _selectedDate,
          onDateChanged: (d) => setState(() => _selectedDate = d),
        ),
        const SizedBox(height: AppSpace.md),
        TextField(
          controller: _notesController,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: l10n.notes,
            prefixIcon: const Icon(Icons.notes_rounded, size: 20),
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        SharedSaveButton(
          onPressed: isValid ? _saveAndClose : null,
          isLoading: isLoading,
          label: isLoading ? l10n.saving : l10n.save,
        ),
        if (!isEditing) ...[
          const SizedBox(height: AppSpace.xs),
          TextButton(
            onPressed: (isValid && !isLoading) ? _saveAndAddAnother : null,
            child: Text(l10n.saveAndAddAnother),
          ),
        ],
      ],
    );
  }
}
