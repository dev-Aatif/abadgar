import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/models/yield_log.dart';
import '../../../../core/providers/transactions_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n_helpers.dart';
import '../../../../core/utils/notifications.dart';
import 'form_shared.dart';

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
  final _weightFocusNode = FocusNode();
  YieldUnit _unit = YieldUnit.mund;
  YieldDisposition _disposition = YieldDisposition.sold;
  DateTime _selectedDate = DateTime.now();
  String? _initialWeightText;
  String? _initialPriceText;

  @override
  void initState() {
    super.initState();
    if (widget.yieldLog != null) {
      _weightController.text = widget.yieldLog!.totalWeight.toString();
      if (widget.yieldLog!.salePrice != null &&
          widget.yieldLog!.totalWeight > 0) {
        final unitPrice =
            widget.yieldLog!.salePrice! / widget.yieldLog!.totalWeight;
        _pricePerUnitController.text = unitPrice == unitPrice.roundToDouble()
            ? unitPrice.toInt().toString()
            : unitPrice.toStringAsFixed(2);
      }
      _destinationController.text = widget.yieldLog!.destination ?? '';
      _unit = widget.yieldLog!.unit;
      _disposition = widget.yieldLog!.disposition;
      _selectedDate = widget.yieldLog!.date;
      _initialWeightText = _weightController.text;
      _initialPriceText = _pricePerUnitController.text;
    }

    _weightController.addListener(_updateState);
    _pricePerUnitController.addListener(_updateState);
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _weightController.removeListener(_updateState);
    _pricePerUnitController.removeListener(_updateState);
    _weightController.dispose();
    _pricePerUnitController.dispose();
    _destinationController.dispose();
    _weightFocusNode.dispose();
    super.dispose();
  }

  double get _totalPrice {
    if (widget.yieldLog != null &&
        widget.yieldLog!.salePrice != null &&
        _weightController.text == _initialWeightText &&
        _pricePerUnitController.text == _initialPriceText) {
      return widget.yieldLog!.salePrice!;
    }
    final weight = double.tryParse(_weightController.text) ?? 0;
    final pricePerUnit = double.tryParse(_pricePerUnitController.text) ?? 0;
    return weight * pricePerUnit;
  }

  Future<bool> _saveYieldLog() async {
    final l10n = AppLocalizations.of(context)!;
    final seasonId = widget.seasonId;
    if (seasonId.isEmpty) {
      AppNotification.show(context, l10n.noActiveSeason, isError: true);
      return false;
    }

    try {
      final weight = double.tryParse(_weightController.text);
      if (weight == null || weight <= 0) return false;

      final totalSalePrice =
          _disposition == YieldDisposition.sold && _totalPrice > 0
              ? _totalPrice
              : null;
      final destination = _disposition == YieldDisposition.stored
          ? _destinationController.text.trim()
          : null;

      if (widget.yieldLog != null) {
        await ref.read(transactionsNotifierProvider.notifier).updateYieldLog(
              id: widget.yieldLog!.id,
              totalWeight: weight,
              unit: _unit.value,
              disposition: _disposition.value,
              salePrice: totalSalePrice,
              destination: destination,
              date: _selectedDate,
            );
      } else {
        await ref.read(transactionsNotifierProvider.notifier).addYieldLog(
              seasonId: seasonId,
              totalWeight: weight,
              unit: _unit.value,
              disposition: _disposition.value,
              salePrice: totalSalePrice,
              destination: destination,
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
    final success = await _saveYieldLog();
    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  void _saveAndAddAnother() async {
    final l10n = AppLocalizations.of(context)!;
    final success = await _saveYieldLog();
    if (success && mounted) {
      AppNotification.show(context, l10n.saveAndAddAnother);
      setState(() {
        _weightController.clear();
        _pricePerUnitController.clear();
        _destinationController.clear();
        _selectedDate = DateTime.now();
      });
      _weightFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final weight = double.tryParse(_weightController.text) ?? 0;
    final isValid = weight > 0;
    final isLoading = ref.watch(transactionsNotifierProvider).isLoading;
    final currencyFormat = NumberFormat.currency(
      locale: L10nHelpers.intlLocaleFor(context),
      symbol: 'Rs ',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.yield, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpace.xs),
        SharedAmountField(
          controller: _weightController,
          focusNode: _weightFocusNode,
          autofocus: widget.yieldLog == null,
          prefix: L10nHelpers.yieldUnitLabel(context, _unit),
          hint: '0',
        ),
        const SizedBox(height: AppSpace.sm),
        SegmentedButton<YieldUnit>(
          showSelectedIcon: false,
          segments: YieldUnit.values
              .map((u) => ButtonSegment<YieldUnit>(
                    value: u,
                    label: Text(
                      L10nHelpers.yieldUnitLabel(context, u),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          selected: {_unit},
          onSelectionChanged: (set) {
            HapticFeedback.selectionClick();
            setState(() => _unit = set.first);
          },
        ),
        const SizedBox(height: AppSpace.lg),
        SegmentedButton<YieldDisposition>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: YieldDisposition.sold, label: Text(l10n.sold)),
            ButtonSegment(
                value: YieldDisposition.stored, label: Text(l10n.stored)),
            ButtonSegment(
                value: YieldDisposition.personal,
                label: Text(l10n.personalUse)),
          ],
          selected: {_disposition},
          onSelectionChanged: (set) {
            HapticFeedback.selectionClick();
            setState(() => _disposition = set.first);
          },
        ),
        const SizedBox(height: AppSpace.md),
        if (_disposition == YieldDisposition.sold) ...[
          TextField(
            controller: _pricePerUnitController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [NormalizedDecimalFormatter()],
            decoration: InputDecoration(
              labelText:
                  l10n.pricePer(L10nHelpers.yieldUnitLabel(context, _unit)),
              suffixText: 'Rs',
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md, vertical: AppSpace.sm),
            decoration: BoxDecoration(
              color: tokens.well,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: tokens.hairline, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.totalEstimatedRevenue,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Text(
                  currencyFormat.format(_totalPrice),
                  style: AppTheme.tabular(
                    Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
        ],
        if (_disposition == YieldDisposition.stored) ...[
          TextField(
            controller: _destinationController,
            decoration: InputDecoration(
              labelText: l10n.whereStored,
              prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
            ),
          ),
          const SizedBox(height: AppSpace.md),
        ],
        Text(l10n.dateLabel, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpace.xs),
        QuickDateSelector(
          selectedDate: _selectedDate,
          onDateChanged: (d) => setState(() => _selectedDate = d),
        ),
        const SizedBox(height: AppSpace.xl),
        SharedSaveButton(
          onPressed: isValid ? _saveAndClose : null,
          isLoading: isLoading,
          label: isLoading ? l10n.loggingHarvest : l10n.saveHarvest,
        ),
        if (widget.yieldLog == null) ...[
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
