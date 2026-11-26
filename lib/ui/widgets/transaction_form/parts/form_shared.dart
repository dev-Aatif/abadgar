import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n_helpers.dart';

/// Normalizes Urdu/Persian (۰-۹) and Arabic-Indic (٠-٩) digits to ASCII 0-9
/// and enforces at most 2 decimal places.
class NormalizedDecimalFormatter extends TextInputFormatter {
  static final _decimalPattern = RegExp(r'^\d*\.?\d{0,2}$');

  static String normalizeDigits(String input) {
    final buf = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        buf.writeCharCode(0x30 + (rune - 0x0660));
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        buf.writeCharCode(0x30 + (rune - 0x06F0));
      } else if (rune == 0x066B || rune == 0x060C) {
        buf.write('.');
      } else {
        buf.writeCharCode(rune);
      }
    }
    return buf.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = normalizeDigits(newValue.text);
    if (normalized.isEmpty || _decimalPattern.hasMatch(normalized)) {
      return newValue.copyWith(
        text: normalized,
        selection: TextSelection.collapsed(
          offset: normalized.length < newValue.selection.end
              ? normalized.length
              : newValue.selection.end,
        ),
      );
    }
    return oldValue;
  }
}

class SharedAmountField extends StatefulWidget {
  final TextEditingController controller;
  final String prefix;
  final String hint;
  final bool autofocus;
  final FocusNode? focusNode;

  const SharedAmountField({
    super.key,
    required this.controller,
    this.prefix = 'Rs',
    this.hint = '0',
    this.autofocus = true,
    this.focusNode,
  });

  @override
  State<SharedAmountField> createState() => _SharedAmountFieldState();
}

class _SharedAmountFieldState extends State<SharedAmountField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final hasText = widget.controller.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md, vertical: AppSpace.xs),
      decoration: BoxDecoration(
        color: tokens.well,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: tokens.hairline, width: 1),
      ),
      child: Row(
        children: [
          Text(
            widget.prefix,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              autofocus: widget.autofocus,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [NormalizedDecimalFormatter()],
              style: AppTheme.tabular(
                Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppTheme.tabular(
                  Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: tokens.inkMuted.withValues(alpha: 0.35),
                      ),
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: AppSpace.xs),
              ),
            ),
          ),
          if (hasText)
            IconButton(
              tooltip: AppLocalizations.of(context)!.clear,
              onPressed: () {
                widget.controller.clear();
                widget.focusNode?.requestFocus();
              },
              icon: Icon(Icons.close_rounded, size: 18, color: tokens.inkMuted),
            ),
        ],
      ),
    );
  }
}

/// 1-tap Today / Yesterday / Pick date selector for rapid field entry.
class QuickDateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const QuickDateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final picked =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    final isToday = _isSameDay(picked, today);
    final isYesterday = _isSameDay(picked, yesterday);
    final isCustom = !isToday && !isYesterday;

    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: Center(child: Text(l10n.today)),
            selected: isToday,
            showCheckmark: false,
            onSelected: (_) {
              HapticFeedback.selectionClick();
              onDateChanged(today);
            },
          ),
        ),
        const SizedBox(width: AppSpace.xs),
        Expanded(
          child: ChoiceChip(
            label: Center(child: Text(l10n.yesterday)),
            selected: isYesterday,
            showCheckmark: false,
            onSelected: (_) {
              HapticFeedback.selectionClick();
              onDateChanged(yesterday);
            },
          ),
        ),
        const SizedBox(width: AppSpace.xs),
        Expanded(
          child: ChoiceChip(
            label: Center(
              child: Text(
                isCustom
                    ? DateFormat('d MMM', L10nHelpers.intlLocaleFor(context))
                        .format(picked)
                    : l10n.otherDate,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            selected: isCustom,
            showCheckmark: false,
            onSelected: (_) async {
              FocusScope.of(context).unfocus();
              final firstDate =
                  picked.isBefore(DateTime(2020)) ? picked : DateTime(2020);
              final lastDate = picked.isAfter(today) ? picked : today;
              final date = await showDatePicker(
                context: context,
                initialDate: picked,
                firstDate: firstDate,
                lastDate: lastDate,
              );
              if (date != null) {
                onDateChanged(date);
              }
            },
          ),
        ),
      ],
    );
  }
}

class SharedSaveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;

  const SharedSaveButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onPressed != null && !isLoading
            ? () {
                HapticFeedback.mediumImpact();
                onPressed!();
              }
            : null,
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Text(label),
                ],
              )
            : Text(label),
      ),
    );
  }
}
