import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/enums.dart';
import '../../../core/models/season.dart';
import '../../../core/providers/active_season_provider.dart';
import '../../../core/providers/analytics_selection_provider.dart';
import '../../../core/providers/lands_provider.dart';
import '../../../core/providers/seasons_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_helpers.dart';
import '../../../core/utils/notifications.dart';
import '../../widgets/app_controls.dart';
import '../../widgets/app_selector.dart';
import '../../widgets/app_surface.dart';
import '../../widgets/transaction_form/parts/form_shared.dart';

class SeasonsScreen extends ConsumerWidget {
  const SeasonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final seasonsAsync = ref.watch(seasonsProvider);
    final activeSeasonId = ref.watch(activeSeasonIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.harvestCycles),
        actions: [
          IconButton(
            tooltip: l10n.newCycle,
            onPressed: () => _showCreateSeasonSheet(context),
            icon: const Icon(Icons.add_rounded, size: 22),
          ),
        ],
      ),
      body: seasonsAsync.when(
        data: (seasonsList) {
          if (seasonsList.isEmpty) {
            return AppEmptyState(
              icon: Icons.agriculture_outlined,
              title: l10n.emptyCycles,
              subtitle: l10n.startCycle,
              actionLabel: l10n.newCycle,
              onAction: () => _showCreateSeasonSheet(context),
            );
          }

          final activeSeason = seasonsList.firstWhere(
            (s) => s.id == activeSeasonId,
            orElse: () => seasonsList.firstWhere(
              (s) => s.status == SeasonStatus.active,
              orElse: () => seasonsList.first,
            ),
          );

          final otherSeasons =
              seasonsList.where((s) => s.id != activeSeason.id).toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.md,
                    AppSpace.xs,
                    AppSpace.md,
                    AppSpace.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSectionHeader(title: l10n.activeSeason),
                      const SizedBox(height: AppSpace.xs),
                      _ActiveSeasonCard(season: activeSeason),
                    ],
                  ),
                ),
              ),
              if (otherSeasons.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpace.md),
                    child: AppSectionHeader(title: l10n.previousHarvests),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.md,
                    AppSpace.xs,
                    AppSpace.md,
                    48,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: AppCard(
                      child: Column(
                        children: [
                          for (int i = 0; i < otherSeasons.length; i++)
                            _SeasonListRow(
                              season: otherSeasons[i],
                              showDivider: i < otherSeasons.length - 1,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) =>
            Center(child: Text(l10n.errorGeneral(err.toString()))),
      ),
    );
  }

  void _showCreateSeasonSheet(BuildContext context, [Season? season]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateSeasonSheet(season: season),
    );
  }
}

class _ActiveSeasonCard extends ConsumerWidget {
  final Season season;
  const _ActiveSeasonCard({required this.season});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final isWheat = season.cropType == CropType.wheat;
    final cropColor =
        isWheat ? AppColors.wheatFor(context) : AppColors.riceFor(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpace.md),
      borderColor: cropColor.withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cropColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CropGlyph(cropType: season.cropType, size: 13),
                    const SizedBox(width: 5),
                    Text(
                      L10nHelpers.cropLabel(context, season.cropType),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: cropColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_horiz_rounded,
                  color: tokens.inkMuted,
                  size: 20,
                ),
                onSelected: (value) => _handleMenuAction(context, ref, value),
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      l10n.delete,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            '${L10nHelpers.cropLabel(context, season.cropType)} ${season.startDate.year}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 2),
          Text(
            '${season.landArea} ${l10n.acresUnit} · ${l10n.seasonStarted} ${DateFormat.yMMMd(L10nHelpers.intlLocaleFor(context)).format(season.startDate)}',
            style: AppTheme.tabular(Theme.of(context).textTheme.bodyMedium),
          ),
          if (season.status != SeasonStatus.completed) ...[
            const SizedBox(height: AppSpace.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _confirmComplete(context, ref),
                child: Text(l10n.completeSeason),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmComplete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.completeSeasonTitle),
        content: Text(l10n.completeSeasonContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.completeSeason),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await ref
          .read(seasonsNotifierProvider.notifier)
          .updateStatus(season.id, SeasonStatus.completed);
      ref.read(analyticsSeasonSelectionProvider.notifier).setSeason(season.id);
      if (context.mounted) context.go('/analytics');
    }
  }

  Future<void> _handleMenuAction(
      BuildContext context, WidgetRef ref, String value) async {
    final l10n = AppLocalizations.of(context)!;
    if (value == 'edit') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => CreateSeasonSheet(season: season),
      );
    } else if (value == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.confirmDelete),
          content: Text(l10n.deleteConfirmation),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                l10n.delete,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      );
      if (confirm == true && context.mounted) {
        try {
          await ref
              .read(seasonsNotifierProvider.notifier)
              .deleteSeason(season.id);
        } catch (e) {
          if (context.mounted) {
            AppNotification.show(
              context,
              l10n.errorGeneral(e.toString()),
              isError: true,
            );
          }
        }
      }
    }
  }
}

class _SeasonListRow extends ConsumerWidget {
  final Season season;
  final bool showDivider;

  const _SeasonListRow({
    required this.season,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;

    final subtitleParts = ['${season.landArea} ${l10n.acresUnit}'];
    if (season.status == SeasonStatus.completed) {
      subtitleParts.add(
        '${l10n.seasonFinished} ${DateFormat.yMMMd(L10nHelpers.intlLocaleFor(context)).format(season.endDate ?? season.startDate)}',
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(activeSeasonIdProvider.notifier).set(season.id);
            AppNotification.show(
              context,
              l10n.switchedFocus(
                '${L10nHelpers.cropLabel(context, season.cropType)} ${season.startDate.year}',
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: 11,
            ),
            child: Row(
              children: [
                CropGlyph(cropType: season.cropType, size: 18),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${L10nHelpers.cropLabel(context, season.cropType)} ${season.startDate.year}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitleParts.join(' · '),
                        style: AppTheme.tabular(
                          Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: tokens.inkMuted,
                    size: 18,
                  ),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => CreateSeasonSheet(season: season),
                      );
                    } else if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(l10n.confirmDelete),
                          content: Text(l10n.deleteConfirmation),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(l10n.cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(
                                l10n.delete,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        try {
                          await ref
                              .read(seasonsNotifierProvider.notifier)
                              .deleteSeason(season.id);
                        } catch (e) {
                          if (context.mounted) {
                            AppNotification.show(
                              context,
                              l10n.errorGeneral(e.toString()),
                              isError: true,
                            );
                          }
                        }
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        l10n.delete,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: AppSpace.md,
            endIndent: AppSpace.md,
            color: tokens.hairline,
          ),
      ],
    );
  }
}

class CreateSeasonSheet extends ConsumerStatefulWidget {
  final Season? season;
  const CreateSeasonSheet({super.key, this.season});

  @override
  ConsumerState<CreateSeasonSheet> createState() => _CreateSeasonSheetState();
}

class _CreateSeasonSheetState extends ConsumerState<CreateSeasonSheet> {
  int _selectedYear = DateTime.now().year;
  late CropType _cropType;
  final _areaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.season?.startDate.year ?? DateTime.now().year;
    _cropType = widget.season?.cropType ?? CropType.wheat;
    if (widget.season != null) {
      _areaController.text = widget.season!.landArea.toString();
    }
  }

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final area = double.tryParse(_areaController.text);
    return area != null && area > 0;
  }

  void _nudgeArea(double delta) {
    final current = double.tryParse(_areaController.text) ?? 0;
    final next = (current + delta).clamp(0.5, 9999.0);
    setState(() {
      _areaController.text = next == next.roundToDouble()
          ? next.toInt().toString()
          : next.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final lands = ref.watch(landsProvider).valueOrNull ?? [];

    return Container(
      padding: EdgeInsetsDirectional.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpace.lg,
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
      child: SingleChildScrollView(
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
            Text(
              widget.season != null ? l10n.edit : l10n.newCycle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpace.md),
            AppSegmentedControl<CropType>(
              selected: _cropType,
              segments: [
                AppSegment(
                  value: CropType.wheat,
                  label: l10n.wheat,
                  icon: Icons.grass_rounded,
                  activeColor: AppColors.wheatFor(context),
                ),
                AppSegment(
                  value: CropType.rice,
                  label: l10n.rice,
                  icon: Icons.water_drop_rounded,
                  activeColor: AppColors.riceFor(context),
                ),
              ],
              onChanged: (crop) => setState(() => _cropType = crop),
            ),
            const SizedBox(height: AppSpace.md),
            Text(l10n.year, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            _YearSelectorRow(
              selectedYear: _selectedYear,
              onChanged: (y) => setState(() => _selectedYear = y),
            ),
            const SizedBox(height: AppSpace.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _areaController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [NormalizedDecimalFormatter()],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n.totalArea,
                      prefixIcon:
                          const Icon(Icons.square_foot_rounded, size: 18),
                      suffixText: l10n.acresUnitShort,
                      hintText: '12.5',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                CompactStepperCluster(
                  stepLabel: '0.5',
                  onDecrement: () => _nudgeArea(-0.5),
                  onIncrement: () => _nudgeArea(0.5),
                ),
              ],
            ),
            if (lands.isNotEmpty) ...[
              const SizedBox(height: AppSpace.sm),
              Text(l10n.savedLands,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: lands.map((land) {
                  return AppFilterPill(
                    label: '${land.name} (${land.area} ${l10n.acresUnitShort})',
                    selected: _areaController.text == land.area.toString(),
                    onTap: () {
                      setState(() {
                        _areaController.text = land.area.toString();
                      });
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: AppSpace.lg),
            SizedBox(
              height: 46,
              child: FilledButton(
                onPressed: _isValid ? _save : null,
                child: Text(l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final area = double.tryParse(_areaController.text) ?? 0;
    if (area <= 0) return;

    final seasonName = '${_cropType.value} $_selectedYear';

    try {
      if (widget.season != null) {
        await ref.read(seasonsNotifierProvider.notifier).updateSeason(
              id: widget.season!.id,
              name: seasonName,
              cropType: _cropType,
              landArea: area,
              startDate: DateTime(_selectedYear),
            );
      } else {
        await ref.read(seasonsNotifierProvider.notifier).addSeason(
              name: seasonName,
              cropType: _cropType,
              landArea: area,
              startDate: DateTime(_selectedYear),
            );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        AppNotification.show(
          context,
          l10n.saveFailed(e.toString()),
          isError: true,
        );
      }
    }
  }
}

class _YearSelectorRow extends StatelessWidget {
  final int selectedYear;
  final ValueChanged<int> onChanged;

  const _YearSelectorRow({
    required this.selectedYear,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentYear = DateTime.now().year;
    final quickYears = [currentYear - 1, currentYear, currentYear + 1];
    final isQuick = quickYears.contains(selectedYear);

    return Row(
      children: [
        for (final year in quickYears) ...[
          Expanded(
            child: AppFilterPill(
              label: '$year',
              selected: selectedYear == year,
              onTap: () => onChanged(year),
            ),
          ),
          const SizedBox(width: 6),
        ],
        AppSelectorTrigger(
          compact: true,
          label: isQuick ? l10n.other : '$selectedYear',
          onTap: () async {
            final allYears = List.generate(20, (i) => currentYear - 5 + i);
            final picked = await showAppSelectorSheet<int>(
              context: context,
              title: l10n.year,
              selectedValue: selectedYear,
              options: allYears
                  .map((y) => AppSelectorOption<int>(value: y, label: '$y'))
                  .toList(),
            );
            if (picked != null) onChanged(picked);
          },
        ),
      ],
    );
  }
}
