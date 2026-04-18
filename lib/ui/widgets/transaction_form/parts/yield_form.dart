import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/transaction_repository_provider.dart';
import '../../../../core/utils/season_resolver.dart';
import 'form_shared.dart';

class YieldForm extends ConsumerStatefulWidget {
  final String seasonId;
  const YieldForm({super.key, required this.seasonId});

  @override
  ConsumerState<YieldForm> createState() => _YieldFormState();
}

class _YieldFormState extends ConsumerState<YieldForm> {
  final _yieldController = TextEditingController();
  String _unit = 'Mund (40kg)';

  @override
  void dispose() {
    _yieldController.dispose();
    super.dispose();
  }

  void _save() async {
    final seasonId = resolveSeasonId(ref);
    if (seasonId == null) return;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final weight = double.tryParse(_yieldController.text) ?? 0;
    final isValid = weight > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SharedAmountField(
          controller: _yieldController,
          prefix: _unit.split(' ').first,
          hint: '0.0',
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          value: _unit,
          decoration: const InputDecoration(labelText: 'Unit', prefixIcon: Icon(Icons.straighten_rounded)),
          items: ['Kg', 'Mund (40kg)', 'Tons'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
          onChanged: (val) => setState(() => _unit = val!),
        ),
        const SizedBox(height: 32),
        SharedSaveButton(
          onPressed: isValid ? _save : null,
          label: 'Log Yield',
        ),
      ],
    );
  }
}
