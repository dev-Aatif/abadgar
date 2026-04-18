import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/season.dart';
import '../database/database_provider.dart';

part 'active_season_provider.g.dart';

@riverpod
class ActiveSeasonId extends _$ActiveSeasonId {
  @override
  String? build() {
    // We can't use ref.watch(seasonsProvider) here directly as it's a stream
    // Instead, the UI or the SeasionNotifier will set it.
    return null;
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
