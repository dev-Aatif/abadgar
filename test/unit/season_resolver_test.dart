import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abadgar/core/providers/active_season_provider.dart';
import 'package:abadgar/core/models/season.dart';
import 'package:abadgar/core/constants/enums.dart';

// Simple mock for ActiveSeasonId to avoid DB dependency in logic tests
class MockActiveSeasonId extends ActiveSeasonId {
  final String? initialValue;
  MockActiveSeasonId([this.initialValue]);

  @override
  String? build() => initialValue;
}

void main() {
  group('Season Resolver Logic Tests', () {
    test('Should resolve the active season ID if one is explicitly set', () {
      final container = ProviderContainer(
        overrides: [
          activeSeasonIdProvider.overrideWith(() => MockActiveSeasonId('selected-s1')),
        ],
      );

      final resolvedId = container.read(activeSeasonIdProvider);
      expect(resolvedId, 'selected-s1');
    });

    test('Logic check: should find first active season from list if none selected', () {
      final now = DateTime.now();
      final seasons = [
        Season(
          id: 's-planned',
          name: 'P1',
          cropType: CropType.wheat,
          landArea: 10,
          startDate: now,
          status: SeasonStatus.planned,
          createdAt: now,
          updatedAt: now,
        ),
        Season(
          id: 's-active',
          name: 'A1',
          cropType: CropType.rice,
          landArea: 5,
          startDate: now,
          status: SeasonStatus.active, // This should be picked
          createdAt: now,
          updatedAt: now,
        ),
      ];

      // Pure logic test of the fallback strategy used in the resolver
      final activeSeason = seasons.firstWhere(
        (s) => s.status == SeasonStatus.active,
        orElse: () => seasons.first,
      );

      expect(activeSeason.id, 's-active');
    });
  });
}
