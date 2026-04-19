import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'active_season_provider.dart';

part 'analytics_selection_provider.g.dart';

@riverpod
class AnalyticsSeasonSelection extends _$AnalyticsSeasonSelection {
  @override
  String? build() {
    // Default to the active season if available
    return ref.watch(activeSeasonIdProvider);
  }

  void setSeason(String id) {
    state = id;
  }
}
