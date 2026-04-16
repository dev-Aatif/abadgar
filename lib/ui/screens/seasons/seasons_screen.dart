import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/seasons_provider.dart';
import '../../../core/providers/active_season_provider.dart';

class SeasonsScreen extends ConsumerWidget {
  const SeasonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonsAsync = ref.watch(seasonsProvider);
    final activeSeasonId = ref.watch(activeSeasonIdProvider);

    return Scaffold(
      body: seasonsAsync.when(
        data: (seasonsList) {
          if (seasonsList.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'Start your first Wheat or Rice cycle!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: seasonsList.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final season = seasonsList[index];
              final isActive = season.id == activeSeasonId;

              return Card(
                elevation: isActive ? 6 : 1,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: isActive 
                    ? BorderSide(color: Theme.of(context).primaryColor, width: 3)
                    : BorderSide.none,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(20),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: isActive ? Theme.of(context).primaryColor : Colors.grey[200],
                    child: Icon(
                      season.cropType == 'Wheat' ? Icons.grass : Icons.water_drop,
                      color: isActive ? Colors.white : Colors.grey[700],
                      size: 32,
                    ),
                  ),
                  title: Text(
                    season.name,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
                  ),
                  subtitle: Text(
                    '${season.cropType} • ${season.landArea} Acres\nStarted: ${season.startDate.day}/${season.startDate.month}/${season.startDate.year}',
                    style: const TextStyle(height: 1.5, fontWeight: FontWeight.bold),
                  ),
                  trailing: isActive 
                    ? const Icon(Icons.check_circle, color: Colors.green, size: 40)
                    : OutlinedButton(
                        onPressed: () {
                          ref.read(activeSeasonIdProvider.notifier).set(season.id);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: const Text('ACTIVATE'),
                      ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSeasonSheet(context),
        label: const Text('NEW CYCLE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        icon: const Icon(Icons.add, size: 28),
      ),
    );
  }

  void _showCreateSeasonSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => const CreateSeasonSheet(),
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
  String _cropType = 'Wheat';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.all(Radius.circular(10))),
            ),
          ),
          const SizedBox(height: 24),
          Text('New Harvest Cycle', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 24),
          
          Text('Select Crop', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            style: SegmentedButton.styleFrom(minimumSize: const Size(0, 64)),
            segments: const [
              ButtonSegment(
                value: 'Wheat', 
                label: Text('WHEAT', style: TextStyle(fontWeight: FontWeight.bold)),
                icon: Icon(Icons.grass),
              ),
              ButtonSegment(
                value: 'Rice', 
                label: Text('RICE', style: TextStyle(fontWeight: FontWeight.bold)),
                icon: Icon(Icons.water_drop),
              ),
            ],
            selected: {_cropType},
            onSelectionChanged: (set) => setState(() => _cropType = set.first),
          ),
          const SizedBox(height: 24),
          
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Season Name',
              hintText: 'e.g. Winter 2024',
              prefixIcon: Icon(Icons.edit),
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _areaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Land Area (Acres)',
              hintText: '0.0',
              prefixIcon: Icon(Icons.square_foot),
            ),
          ),
          
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 72),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('START CYCLE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _save() async {
    final name = _nameController.text;
    final area = double.tryParse(_areaController.text) ?? 0.0;

    if (name.isNotEmpty && area > 0) {
      await ref.read(seasonsNotifierProvider.notifier).addSeason(
        name: name,
        cropType: _cropType,
        landArea: area,
        startDate: DateTime.now(),
      );
      if (mounted) Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid name and land area')),
      );
    }
  }
}
