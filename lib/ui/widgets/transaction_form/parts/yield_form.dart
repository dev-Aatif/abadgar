import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/yield_log.dart';
import '../../../../core/providers/transactions_provider.dart';
import '../../../../core/utils/season_resolver.dart';
import '../../../../core/utils/notifications.dart';
import 'form_shared.dart';
import '../../../../core/constants/enums.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';

class YieldForm extends ConsumerStatefulWidget {
  final String seasonId;
  final YieldLog? yieldLog;
  const YieldForm({super.key, required this.seasonId, this.yieldLog});

  @override
  ConsumerState<YieldForm> createState() => _YieldFormState();
}

class _YieldFormState extends ConsumerState<YieldForm> {
  final _weightController = TextEditingController();
  final _pricePerUnitController = TextEditingController();
  final _destinationController = TextEditingController();
  YieldUnit _unit = YieldUnit.mund;
  YieldDisposition _disposition = YieldDisposition.sold;

  @override
  void initState() {
    super.initState();
    if (widget.yieldLog != null) {
      _weightController.text = widget.yieldLog!.totalWeight.toString();
      if (widget.yieldLog!.salePrice != null) {
        // Calculate price per unit
        _pricePerUnitController.text = (widget.yieldLog!.salePrice! / widget.yieldLog!.totalWeight).toString();
      }
      _destinationController.text = widget.yieldLog!.destination ?? '';
      _unit = widget.yieldLog!.unit;
      _disposition = widget.yieldLog!.disposition;
    }

    _weightController.addListener(_updateState);
    _pricePerUnitController.addListener(_updateState);
  }

  void _updateState() => setState(() {});

  @override
  void dispose() {
    _weightController.dispose();
    _pricePerUnitController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  double get _totalPrice {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final pricePerUnit = double.tryParse(_pricePerUnitController.text) ?? 0;
    return weight * pricePerUnit;
  }

  void _save() async {
    final seasonId = resolveSeasonId(ref);
    if (seasonId == null) {
      AppNotification.show(context, 'No active season selected.', isError: true);
      return;
    }

    try {
      final weight = double.tryParse(_weightController.text);
      if (weight == null || weight <= 0) {
        AppNotification.show(context, 'Please enter a valid weight.', isError: true);
        return;
      }

      final totalSalePrice = _disposition == YieldDisposition.sold ? _totalPrice : null;

      // 1. Add or Update the Yield Log (Harvest tracking)
      if (widget.yieldLog != null) {
        await ref.read(transactionsNotifierProvider.notifier).updateYieldLog(
          id: widget.yieldLog!.id,
          totalWeight: weight,
          unit: _unit.value,
          disposition: _disposition.value,
          salePrice: totalSalePrice,
          destination: _disposition == YieldDisposition.stored ? _destinationController.text : null,
          date: widget.yieldLog!.date,
        );
      } else {
        await ref.read(transactionsNotifierProvider.notifier).addYieldLog(
          seasonId: seasonId,
          totalWeight: weight,
          unit: _unit.value,
          disposition: _disposition.value,
          salePrice: totalSalePrice,
          destination: _disposition == YieldDisposition.stored ? _destinationController.text : null,
          date: DateTime.now(),
        );

        // 2. If sold, automatically create a Revenue transaction for the ledger (only on creation)
        if (_disposition == YieldDisposition.sold && totalSalePrice != null && totalSalePrice > 0) {
          await ref.read(transactionsNotifierProvider.notifier).addTransaction(
            seasonId: seasonId,
            amount: totalSalePrice,
            category: 'Harvest Sale',
            date: DateTime.now(),
            type: TransactionType.revenue.value,
            notes: 'Yield: $weight ${_unit.value}',
          );
        }
      }

      // Successfully saved
      if (mounted) {
        AppNotification.show(context, 'Harvest logged successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppNotification.show(context, 'Failed to save harvest: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final isValid = weight > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(AppLocalizations.of(context)!.howMuchHarvested, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: SharedAmountField(
                controller: _weightController,
                prefix: AppLocalizations.of(context)!.yield,
                hint: '0.0',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<YieldUnit>(
                value: _unit,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: YieldUnit.values.map((u) => DropdownMenuItem(value: u, child: Text(u.value))).toList(),
                onChanged: (val) => setState(() => _unit = val!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(AppLocalizations.of(context)!.whatDidYouDo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 12),
        SegmentedButton<YieldDisposition>(
          segments: [
            ButtonSegment(value: YieldDisposition.sold, label: Text(AppLocalizations.of(context)!.sold), icon: const Icon(Icons.monetization_on_rounded, size: 16)),
            ButtonSegment(value: YieldDisposition.stored, label: Text(AppLocalizations.of(context)!.stored), icon: const Icon(Icons.inventory_2_rounded, size: 16)),
            ButtonSegment(value: YieldDisposition.personal, label: Text(AppLocalizations.of(context)!.home), icon: const Icon(Icons.home_rounded, size: 16)),
          ],
          selected: {_disposition},
          onSelectionChanged: (set) => setState(() => _disposition = set.first),
        ),
        const SizedBox(height: 24),
        if (_disposition == YieldDisposition.sold) ...[
          TextField(
            controller: _pricePerUnitController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.pricePer(_unit.value),
              prefixIcon: const Icon(Icons.attach_money_rounded),
              suffixText: 'Rs',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.totalEstimatedRevenue, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  'Rs ${_totalPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_disposition == YieldDisposition.stored) ...[
          TextField(
            controller: _destinationController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.whereStored,
              prefixIcon: const Icon(Icons.location_on_rounded),
              hintText: 'Home, Warehouse, etc.',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
        const SizedBox(height: 32),
        SharedSaveButton(
          onPressed: (isValid && !ref.watch(transactionsNotifierProvider).isLoading) ? _save : null,
          label: ref.watch(transactionsNotifierProvider).isLoading ? AppLocalizations.of(context)!.loggingHarvest : AppLocalizations.of(context)!.saveHarvest,
        ),
      ],
    );
  }
}
