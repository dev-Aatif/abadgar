import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:abadgar/l10n/generated/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/enums.dart';
import '../../../core/models/transaction.dart';
import '../../../core/models/yield_log.dart';
import '../../../core/providers/active_season_provider.dart';
import '../../../core/providers/seasons_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_helpers.dart';
import 'parts/generic_transaction_form.dart';
import 'parts/yield_form.dart';

enum TransactionMode { expense, revenue, harvest }

class TransactionBottomSheet extends ConsumerStatefulWidget {
  final Transaction? transaction;
  final YieldLog? yieldLog;
  final TransactionMode? initialMode;

  const TransactionBottomSheet({
    super.key,
    this.transaction,
    this.yieldLog,
    this.initialMode,
  });

  @override
  ConsumerState<TransactionBottomSheet> createState() =>
      _TransactionBottomSheetState();
}

class _TransactionBottomSheetState
    extends ConsumerState<TransactionBottomSheet> {
  late TransactionMode _mode;
  String? _sessionSeasonId;
  bool _selectingSeason = true;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _sessionSeasonId = widget.transaction!.seasonId;
      _selectingSeason = false;
      _mode = widget.transaction!.type == TransactionType.revenue
          ? TransactionMode.revenue
          : TransactionMode.expense;
    } else if (widget.yieldLog != null) {
      _sessionSeasonId = widget.yieldLog!.seasonId;
      _selectingSeason = false;
      _mode = TransactionMode.harvest;
    } else {
      _mode = widget.initialMode ?? TransactionMode.expense;
      _sessionSeasonId = ref.read(activeSeasonIdProvider);
      if (_sessionSeasonId != null) {
        _selectingSeason = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      padding: EdgeInsetsDirectional.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpace.xl,
        start: AppSpace.lg,
        end: AppSpace.lg,
        top: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: tokens.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          if (_selectingSeason)
            _buildSeasonSelector()
          else ...[
            _buildHeaderNavigator(),
            const SizedBox(height: AppSpace.sm),
            _buildModeToggle(),
            const SizedBox(height: AppSpace.lg),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _buildForm(seasonId: _sessionSeasonId!),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderNavigator() {
    final seasons = ref.read(seasonsProvider).valueOrNull ?? [];
    if (seasons.isEmpty) return const SizedBox.shrink();

    final selectedSeason = seasons.firstWhere(
      (s) => s.id == _sessionSeasonId,
      orElse: () => seasons.first,
    );
    final tokens = context.tokens;
    final cropColor = selectedSeason.cropType == CropType.wheat
        ? AppColors.wheatFor(context)
        : AppColors.riceFor(context);

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: InkWell(
        onTap: (widget.transaction != null || widget.yieldLog != null)
            ? null
            : () => setState(() => _selectingSeason = true),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: tokens.well,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: tokens.hairline, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selectedSeason.cropType == CropType.wheat
                    ? Icons.grass_rounded
                    : Icons.water_drop_rounded,
                size: 16,
                color: cropColor,
              ),
              const SizedBox(width: AppSpace.xs),
              Flexible(
                child: Text(
                  '${L10nHelpers.cropLabel(context, selectedSeason.cropType)} ${selectedSeason.startDate.year}',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              if (widget.transaction == null && widget.yieldLog == null) ...[
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: tokens.inkMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeasonSelector() {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final seasons = ref.watch(seasonsProvider).valueOrNull ?? [];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.whichSeason, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpace.sm),
        if (seasons.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Text(l10n.emptyCycles, textAlign: TextAlign.center),
          )
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: seasons.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: tokens.hairline),
              itemBuilder: (_, index) {
                final s = seasons[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    s.cropType == CropType.wheat
                        ? Icons.grass_rounded
                        : Icons.water_drop_rounded,
                    color: s.cropType == CropType.wheat
                        ? AppColors.wheatFor(context)
                        : AppColors.riceFor(context),
                  ),
                  title: Text(
                    '${L10nHelpers.cropLabel(context, s.cropType)} ${s.startDate.year}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    '${s.landArea} ${l10n.acresUnit}, ${DateFormat.yMMMd(L10nHelpers.intlLocaleFor(context)).format(s.startDate)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    color: tokens.inkMuted,
                  ),
                  onTap: () {
                    ref.read(activeSeasonIdProvider.notifier).set(s.id);
                    setState(() {
                      _sessionSeasonId = s.id;
                      _selectingSeason = false;
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildModeToggle() {
    final l10n = AppLocalizations.of(context)!;
    final isLocked = widget.transaction != null || widget.yieldLog != null;

    return SegmentedButton<TransactionMode>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: TransactionMode.expense,
          label: Text(l10n.expense),
        ),
        ButtonSegment(
          value: TransactionMode.revenue,
          label: Text(l10n.revenue),
        ),
        ButtonSegment(
          value: TransactionMode.harvest,
          label: Text(l10n.harvest),
        ),
      ],
      selected: {_mode},
      onSelectionChanged: isLocked
          ? null
          : (selection) {
              HapticFeedback.selectionClick();
              setState(() => _mode = selection.first);
            },
    );
  }

  Widget _buildForm({required String seasonId}) {
    switch (_mode) {
      case TransactionMode.expense:
        return GenericTransactionForm(
          key: const ValueKey('expense'),
          seasonId: seasonId,
          type: TransactionType.expense,
          transaction: widget.transaction,
        );
      case TransactionMode.revenue:
        return GenericTransactionForm(
          key: const ValueKey('revenue'),
          seasonId: seasonId,
          type: TransactionType.revenue,
          transaction: widget.transaction,
        );
      case TransactionMode.harvest:
        return YieldForm(
          key: const ValueKey('harvest'),
          seasonId: seasonId,
          yieldLog: widget.yieldLog,
        );
    }
  }
}
