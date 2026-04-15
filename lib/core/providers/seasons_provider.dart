import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../models/season.dart';
import '../database/database_provider.dart';

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
    required String cropType,
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
        status: 'Active',
        createdAt: now,
        updatedAt: now,
      );

      await db.execute(
        'INSERT INTO seasons(id, name, crop_type, land_area, start_date, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [
          season.id,
          season.name,
          season.cropType,
          season.landArea,
          season.startDate.toIso8601String(),
          season.status,
          season.createdAt.toIso8601String(),
          season.updatedAt.toIso8601String(),
        ],
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStatus(String id, String status) async {
    final db = await ref.read(powerSyncDatabaseProvider.future);
    await db.execute(
      'UPDATE seasons SET status = ?, updated_at = ? WHERE id = ?',
      [status, DateTime.now().toIso8601String(), id],
    );
  }
}
