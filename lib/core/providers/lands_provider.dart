import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../models/land.dart';
import '../database/database_provider.dart';

part 'lands_provider.g.dart';

@riverpod
Stream<List<Land>> lands(LandsRef ref) async* {
  final db = await ref.watch(powerSyncDatabaseProvider.future);
  yield* db
      .watch('SELECT * FROM lands ORDER BY name ASC')
      .map((rows) => rows.map((row) => Land.fromRow(row)).toList());
}

@riverpod
class LandsNotifier extends _$LandsNotifier {
  @override
  FutureOr<void> build() async {}

  Future<void> addLand({
    required String name,
    required double area,
  }) async {
    state = const AsyncValue.loading();
    try {
      final db = await ref.read(powerSyncDatabaseProvider.future);
      final id = const Uuid().v4();
      final now = DateTime.now();
      
      final land = Land(
        id: id,
        name: name,
        area: area,
        createdAt: now,
        updatedAt: now,
      );

      await db.execute(
        'INSERT INTO lands(id, name, area, created_at, updated_at) VALUES (?, ?, ?, ?, ?)',
        [
          land.id,
          land.name,
          land.area,
          land.createdAt.toIso8601String(),
          land.updatedAt.toIso8601String(),
        ],
      );
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteLand(String id) async {
    final db = await ref.read(powerSyncDatabaseProvider.future);
    await db.execute('DELETE FROM lands WHERE id = ?', [id]);
  }
}
