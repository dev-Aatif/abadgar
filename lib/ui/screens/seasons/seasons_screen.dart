import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/seasons_provider.dart';
import '../../../core/providers/active_season_provider.dart';
import '../../../core/models/season.dart';
import '../../../core/constants/enums.dart';
import 'package:abadgar/l10n/generated/app_localizations.dart';

class SeasonsScreen extends ConsumerWidget {
  const SeasonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonsAsync = ref.watch(seasonsProvider);
    final activeSeasonId = ref.watch(activeSeasonIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.harvestCycles),
        actions: [
          IconButton(
            onPressed: () => _showCreateSeasonSheet(context),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      body: seasonsAsync.when(
        data: (seasonsList) {
          if (seasonsList.isEmpty) {
            return _buildEmptyState(context);
          }

          final activeSeason = seasonsList.firstWhere(
            (s) => s.id == activeSeasonId,
            orElse: () => seasonsList.firstWhere((s) => s.status == SeasonStatus.active, orElse: () => seasonsList.first),
          );
          
          final completedSeasons = seasonsList.where((s) => s.status == SeasonStatus.completed || (s.id != activeSeason.id && s.status != SeasonStatus.active)).toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.activeSeason.toUpperCase(), style: Theme.of(context).textTheme.labelLarge?.copyWith(letterSpacing: 1.5, color: Theme.of(context).colorScheme.primary)),
                      const SizedBox(height: 16),
                      _ActiveSeasonCard(season: activeSeason),
                    ],
                  ),
                ),
              ),
              if (completedSeasons.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                      child: Text(AppLocalizations.of(context)!.previousHarvests.toUpperCase(), style: Theme.of(context).textTheme.labelLarge?.copyWith(letterSpacing: 1.5, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final season = completedSeasons[index];
                      return _CompletedSeasonTile(season: season);
                    },
                    childCount: completedSeasons.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.agriculture_rounded, size: 100, color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context)!.emptyCycles, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.startCycle, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showCreateSeasonSheet(context),
            icon: const Icon(Icons.add),
            label: Text(AppLocalizations.of(context)!.newCycle),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateSeasonSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateSeasonSheet(),
    );
  }
}

class _ActiveSeasonCard extends ConsumerWidget {
  final Season season;
  const _ActiveSeasonCard({required this.season});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWheat = season.cropType == CropType.wheat;
    final gradient = isWheat 
        ? const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)])
        : const LinearGradient(colors: [Color(0xFF0D7377), Color(0xFF14B8A6)]);

    return Card(
      child: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: Text(season.cropType.value.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                  const Icon(Icons.eco_rounded, color: Colors.white),
                ],
              ),
              const SizedBox(height: 16),
              Text(season.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${season.landArea} Acres • Started ${DateFormat.yMMMd().format(season.startDate)}', style: TextStyle(color: Colors.white.withOpacity(0.8))),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                         final confirm = await showDialog<bool>(
                           context: context,
                           builder: (context) => AlertDialog(
                             title: Text(AppLocalizations.of(context)!.completeSeasonTitle),
                             content: Text(AppLocalizations.of(context)!.completeSeasonContent),
                             actions: [
                               TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context)!.cancel)),
                               TextButton(onPressed: () => Navigator.pop(context, true), child: Text(AppLocalizations.of(context)!.save)), // or complete
                             ],
                           ),
                         );
                         if (confirm == true) {
                           ref.read(seasonsNotifierProvider.notifier).updateStatus(season.id, SeasonStatus.completed);
                         }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: isWheat ? const Color(0xFFD97706) : const Color(0xFF0D7377),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(AppLocalizations.of(context)!.completeSeason),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletedSeasonTile extends ConsumerWidget {
  final Season season;
  const _CompletedSeasonTile({required this.season});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(season.cropType == CropType.wheat ? Icons.grass_rounded : Icons.water_drop_rounded, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(season.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${season.cropType.value} • ${season.landArea} Acres'),
            if (season.status == SeasonStatus.completed)
               Text('Finished: ${DateFormat.yMMMd().format(season.endDate ?? season.startDate)}', style: const TextStyle(fontSize: 11)),
          ],
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
        onTap: () {
          ref.read(activeSeasonIdProvider.notifier).set(season.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Switched focus to ${season.name}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        },
      ),
    );
  }
}

class CreateSeasonSheet extends ConsumerStatefulWidget {
  const CreateSeasonSheet({super.key});

  @override
  ConsumerState<CreateSeasonSheet> createState() => _CreateSeasonSheetState();
}

class _CreateSeasonSheetState extends ConsumerState<CreateSeasonSheet> {
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  CropType _cropType = CropType.wheat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        start: 24,
        end: 24,
        top: 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context)!.newCycle, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _PillToggle(label: 'Wheat', icon: Icons.grass, isSelected: _cropType == CropType.wheat, onTap: () => setState(() => _cropType = CropType.wheat))),
              const SizedBox(width: 12),
              Expanded(child: _PillToggle(label: 'Rice', icon: Icons.water_drop, isSelected: _cropType == CropType.rice, onTap: () => setState(() => _cropType = CropType.rice))),
            ],
          ),
          const SizedBox(height: 24),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Season Name (e.g. Rabi 2024)', prefixIcon: Icon(Icons.title))),
          const SizedBox(height: 16),
          TextField(
            controller: _areaController, 
            keyboardType: const TextInputType.numberWithOptions(decimal: true), 
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.totalArea, 
              prefixIcon: const Icon(Icons.square_foot),
              suffixText: 'Acres',
              suffixStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  void _save() async {
    final name = _nameController.text;
    final area = double.tryParse(_areaController.text) ?? 0.0;

    if (name.isNotEmpty && area > 0) {
      await ref.read(seasonsNotifierProvider.notifier).addSeason(name: name, cropType: _cropType, landArea: area, startDate: DateTime.now());
      if (mounted) Navigator.pop(context);
    }
  }
}

class _PillToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PillToggle({required this.label, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceVariant;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(isSelected ? 0.1 : 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: isSelected ? color : Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
