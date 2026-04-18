import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../models/season.dart';
import '../database/database_provider.dart';
import '../constants/enums.dart';
import 'active_season_provider.dart';

part 'seasons_provider.g.dart';

@riverpod
Stream<List<Season>> seasons(SeasonsRef ref) async* {
  final db = await ref.watch(powerSyncDatabaseProvider.future);
  yield* db
      .watch('SELECT * FROM seasons ORDER BY start_date DESC')
      .map((rows) => rows.map((row) => Season.fromRow(row)).toList());
}

@riverpod
class SeasonsNotifier extends _$SeasonsNotifier {
  @override
  FutureOr<void> build() async {}

  Future<void> addSeason({
    required String name,
    required CropType cropType,
    required double landArea,
    required DateTime startDate,
  }) async {
    state = const AsyncValue.loading();
    try {
      final db = await ref.read(powerSyncDatabaseProvider.future);
      final id = const Uuid().v4();
      final now = DateTime.now();
      
      final season = Season(
        id: id,
        name: name,
        cropType: cropType,
        landArea: landArea,
        startDate: startDate,
        status: SeasonStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      await db.execute(
        'INSERT INTO seasons(id, name, crop_type, land_area, start_date, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [
          season.id,
          season.name,
          season.cropType.value,
          season.landArea,
          season.startDate.toIso8601String(),
          season.status.value,
          season.createdAt.toIso8601String(),
          season.updatedAt.toIso8601String(),
        ],
      );
      
      // Auto-set as active
      ref.read(activeSeasonIdProvider.notifier).set(id);
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStatus(String id, SeasonStatus status) async {
    final db = await ref.read(powerSyncDatabaseProvider.future);
    final isCompleted = status == SeasonStatus.completed;
    await db.execute(
      'UPDATE seasons SET status = ?, updated_at = ?, end_date = ? WHERE id = ?',
      [
        status.value, 
        DateTime.now().toIso8601String(), 
        isCompleted ? DateTime.now().toIso8601String() : null,
        id
      ],
    );
  }
}
