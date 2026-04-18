import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/active_season_provider.dart';
import '../providers/seasons_provider.dart';
import '../constants/enums.dart';

/// Resolves the current season ID, falling back to finding the first active
/// season if none is currently selected. Extracted to eliminate triplication
/// across ExpenseForm, RevenueForm, and YieldForm.
String? resolveSeasonId(WidgetRef ref) {
  var seasonId = ref.read(activeSeasonIdProvider);
  if (seasonId != null) return seasonId;

  final seasons = ref.read(seasonsProvider).valueOrNull ?? [];
  if (seasons.isEmpty) return null;

  final activeSeason = seasons.firstWhere(
    (s) => s.status == SeasonStatus.active.value,
    orElse: () => seasons.first,
  );
  seasonId = activeSeason.id;
  ref.read(activeSeasonIdProvider.notifier).set(seasonId);
  return seasonId;
}
