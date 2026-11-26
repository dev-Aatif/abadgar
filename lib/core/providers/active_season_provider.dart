import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../constants/enums.dart';
import '../models/season.dart';
import '../database/database_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'active_season_provider.g.dart';

@riverpod
class ActiveSeasonId extends _$ActiveSeasonId {
  bool _userMutated = false;
  bool _disposed = false;

  @override
  String? build() {
    _userMutated = false;
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    // Find the most recent active season on startup
    _initialize();
    return null;
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    if (_disposed || _userMutated) return;

    final savedId = prefs.getString('active_season_id');
    final db = await ref.read(localDatabaseProvider.future);
    if (_disposed || _userMutated) return;

    if (savedId != null) {
      final exists =
          await db.getAll('SELECT id FROM seasons WHERE id = ?', [savedId]);
      if (_disposed || _userMutated) return;
      if (exists.isNotEmpty) {
        state = savedId;
        return;
      }
    }

    final results = await db.getAll(
      'SELECT id FROM seasons WHERE status = ? ORDER BY created_at DESC LIMIT 1',
      [SeasonStatus.active.value],
    );
    if (_disposed || _userMutated) return;

    if (results.isNotEmpty && state == null) {
      state = results.first['id'] as String;
      await prefs.setString('active_season_id', state!);
    } else if (state == null) {
      // If no active season, pick the last one created
      final lastSeason = await db
          .getAll('SELECT id FROM seasons ORDER BY created_at DESC LIMIT 1');
      if (_disposed || _userMutated) return;
      if (lastSeason.isNotEmpty) {
        state = lastSeason.first['id'] as String;
        await prefs.setString('active_season_id', state!);
      }
    }
  }

  Future<void> set(String id) async {
    _userMutated = true;
    state = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_season_id', id);
  }

  Future<void> clear() async {
    _userMutated = true;
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

  final db = await ref.watch(localDatabaseProvider.future);
  yield* db.watch('SELECT * FROM seasons WHERE id = ?', parameters: [id]).map(
      (rows) => rows.isEmpty ? null : Season.fromRow(rows.first));
}
