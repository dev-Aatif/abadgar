import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/transaction_repository_provider.dart';
import '../../../../core/utils/season_resolver.dart';
import '../../../../core/utils/notifications.dart';
import 'form_shared.dart';
import '../../../../core/constants/enums.dart';

class YieldForm extends ConsumerStatefulWidget {
  final String seasonId;
  const YieldForm({super.key, required this.seasonId});

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

      await ref.read(transactionRepositoryProvider).saveYieldLog(
        seasonId: seasonId,
        totalWeight: weight,
        unit: _unit.value,
        disposition: _disposition.value,
        salePrice: totalSalePrice,
        destination: _disposition == YieldDisposition.stored ? _destinationController.text : null,
        date: DateTime.now(),
      );

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
        const Text('HOW MUCH WAS HARVESTED?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: SharedAmountField(
                controller: _weightController,
                prefix: 'Weight',
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
        const Text('WHAT DID YOU DO WITH IT?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 12),
        SegmentedButton<YieldDisposition>(
          segments: const [
            ButtonSegment(value: YieldDisposition.sold, label: Text('Sold'), icon: Icon(Icons.monetization_on_rounded, size: 16)),
            ButtonSegment(value: YieldDisposition.stored, label: Text('Stored'), icon: Icon(Icons.inventory_2_rounded, size: 16)),
            ButtonSegment(value: YieldDisposition.personal, label: Text('Home'), icon: Icon(Icons.home_rounded, size: 16)),
          ],
          selected: {_disposition},
          onSelectionChanged: (set) => setState(() => _disposition = set.first),
        ),
        const SizedBox(height: 24),
        if (_disposition == YieldDisposition.sold) ...[
          TextField(
            controller: _pricePerUnitController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Price per ${_unit.value}',
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
                const Text('Total Estimated Revenue:', style: TextStyle(fontWeight: FontWeight.w500)),
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
              labelText: 'Where is it stored?',
              prefixIcon: const Icon(Icons.location_on_rounded),
              hintText: 'Home, Warehouse, etc.',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
        const SizedBox(height: 32),
        SharedSaveButton(
          onPressed: isValid ? _save : null,
          label: 'Save Harvest',
        ),
      ],
    );
  }
}
