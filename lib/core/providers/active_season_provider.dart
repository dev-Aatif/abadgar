import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/season.dart';
import '../database/database_provider.dart';

part 'active_season_provider.g.dart';

@riverpod
class ActiveSeasonId extends _$ActiveSeasonId {
  @override
  String? build() {
    // We try to find the most recent active season on startup
    _initialize();
    return null;
  }

  Future<void> _initialize() async {
    final db = await ref.watch(powerSyncDatabaseProvider.future);
    final results = await db.getAll('SELECT id FROM seasons WHERE status = "active" ORDER BY created_at DESC LIMIT 1');
    if (results.isNotEmpty && state == null) {
      state = results.first['id'] as String;
    } else if (state == null) {
      // If no active season, just pick the last one created
      final lastSeason = await db.getAll('SELECT id FROM seasons ORDER BY created_at DESC LIMIT 1');
      if (lastSeason.isNotEmpty) {
        state = lastSeason.first['id'] as String;
      }
    }
  }

  void set(String id) => state = id;
  void clear() => state = null;
}

@riverpod
Stream<Season?> activeSeason(ActiveSeasonRef ref) async* {
  final id = ref.watch(activeSeasonIdProvider);
  if (id == null) {
    yield null;
    return;
  }

  final db = await ref.watch(powerSyncDatabaseProvider.future);
  yield* db
      .watch('SELECT * FROM seasons WHERE id = ?', parameters: [id])
      .map((rows) => rows.isEmpty ? null : Season.fromRow(rows.first));
}
