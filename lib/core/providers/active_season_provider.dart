import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/season.dart';
import '../database/database_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('active_season_id');
    final db = await ref.watch(powerSyncDatabaseProvider.future);
    
    if (savedId != null) {
      final exists = await db.getAll('SELECT id FROM seasons WHERE id = ?', [savedId]);
      if (exists.isNotEmpty) {
        state = savedId;
        return;
      }
    }

    final results = await db.getAll("SELECT id FROM seasons WHERE status = 'active' ORDER BY created_at DESC LIMIT 1");
    if (results.isNotEmpty && state == null) {
      state = results.first['id'] as String;
      prefs.setString('active_season_id', state!);
    } else if (state == null) {
      // If no active season, just pick the last one created
      final lastSeason = await db.getAll('SELECT id FROM seasons ORDER BY created_at DESC LIMIT 1');
      if (lastSeason.isNotEmpty) {
        state = lastSeason.first['id'] as String;
        prefs.setString('active_season_id', state!);
      }
    }
  }

  Future<void> set(String id) async {
    state = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_season_id', id);
  }

  Future<void> clear() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_season_id');
  }
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
