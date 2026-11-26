import 'package:flutter/material.dart';
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
import '../../widgets/app_controls.dart';
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
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpace.md,
        start: AppSpace.md,
        end: AppSpace.md,
        top: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        border: Border(top: BorderSide(color: tokens.hairline, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 3.5,
              decoration: BoxDecoration(
                color: tokens.hairlineStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          if (_selectingSeason)
            _buildSeasonSelector()
          else ...[
            _buildHeaderNavigator(),
            const SizedBox(height: AppSpace.xs),
            _buildModeToggle(),
            const SizedBox(height: AppSpace.md),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: AnimatedSwitcher(
                  duration: AppMotion.short,
                  switchInCurve: AppMotion.curve,
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

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Material(
        color: tokens.well,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
          side: BorderSide(color: tokens.hairline, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: (widget.transaction != null || widget.yieldLog != null)
              ? null
              : () => setState(() => _selectingSeason = true),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CropGlyph(cropType: selectedSeason.cropType, size: 15),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${L10nHelpers.cropLabel(context, selectedSeason.cropType)} ${selectedSeason.startDate.year}',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: tokens.ink,
                        ),
                  ),
                ),
                if (widget.transaction == null && widget.yieldLog == null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.unfold_more_rounded,
                    size: 15,
                    color: tokens.inkMuted,
                  ),
                ],
              ],
            ),
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
        const SizedBox(height: AppSpace.xs),
        Divider(height: 1, color: tokens.hairline),
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
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CropGlyph(cropType: s.cropType, size: 18),
                  title: Text(
                    '${L10nHelpers.cropLabel(context, s.cropType)} ${s.startDate.year}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    '${s.landArea} ${l10n.acresUnit}, ${DateFormat.yMMMd(L10nHelpers.intlLocaleFor(context)).format(s.startDate)}',
                    style: AppTheme.tabular(
                      Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  trailing: Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    color: tokens.inkMuted,
                    size: 18,
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

    return AppSegmentedControl<TransactionMode>(
      compact: true,
      enabled: !isLocked,
      selected: _mode,
      segments: [
        AppSegment(
          value: TransactionMode.expense,
          label: l10n.expense,
          activeColor: AppColors.expenseFor(context),
        ),
        AppSegment(
          value: TransactionMode.revenue,
          label: l10n.revenue,
          activeColor: AppColors.revenueFor(context),
        ),
        AppSegment(
          value: TransactionMode.harvest,
          label: l10n.harvest,
          activeColor: AppColors.wheatFor(context),
        ),
      ],
      onChanged: (next) => setState(() => _mode = next),
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
