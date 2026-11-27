import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite_async/sqlite_async.dart';
import 'package:abadgar/core/database/database_provider.dart';
import 'package:abadgar/core/database/local_migrations.dart';
import 'package:abadgar/core/database/transaction_repository.dart';
import 'package:abadgar/core/providers/active_season_provider.dart';
import 'package:abadgar/core/providers/comparison_provider.dart';
import 'package:abadgar/core/providers/seasons_provider.dart';

void main() {
  late Directory tempDir;
  late SqliteDatabase db;
  late TransactionRepository repo;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('abadgar_analytics_test_');
    db = SqliteDatabase(path: p.join(tempDir.path, 'analytics.db'));
    await db.initialize();
    await db.execute('PRAGMA foreign_keys = ON;');
    await localMigrations.migrate(db);
    repo = TransactionRepository(db);

    container = ProviderContainer(
      overrides: [
        localDatabaseProvider.overrideWith((ref) async => db),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Analytics & Season Lifecycle Providers', () {
    test('multiYearTrend aggregates completed seasons in SQL chronologically',
        () async {
      final s1Time = DateTime(2024, 1, 1).toIso8601String();
      final s2Time = DateTime(2025, 1, 1).toIso8601String();
      final s3Time = DateTime(2026, 1, 1).toIso8601String();

      await db.execute(
        '''
        INSERT INTO seasons(id, name, crop_type, land_area, start_date, status, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          's1',
          'Wheat 2024',
          'Wheat',
          10.0,
          s1Time,
          'Completed',
          s1Time,
          s1Time
        ],
      );
      await db.execute(
        '''
        INSERT INTO seasons(id, name, crop_type, land_area, start_date, status, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          's2',
          'Wheat 2025',
          'Wheat',
          10.0,
          s2Time,
          'Completed',
          s2Time,
          s2Time
        ],
      );
      await db.execute(
        '''
        INSERT INTO seasons(id, name, crop_type, land_area, start_date, status, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        ['s3', 'Rice 2026', 'Rice', 8.0, s3Time, 'Active', s3Time, s3Time],
      );

      await repo.saveTransaction(
        seasonId: 's1',
        amount: 50000,
        type: 'Revenue',
        category: 'Wheat Sale',
        date: DateTime(2024, 4, 10),
      );
      await repo.saveTransaction(
        seasonId: 's1',
        amount: 20000,
        type: 'Expense',
        category: 'Fertilizer',
        date: DateTime(2024, 2, 10),
      );
      await repo.saveTransaction(
        seasonId: 's2',
        amount: 65000,
        type: 'Revenue',
        category: 'Wheat Sale',
        date: DateTime(2025, 4, 10),
      );
      await repo.saveTransaction(
        seasonId: 's2',
        amount: 20000,
        type: 'Expense',
        category: 'Seed',
        date: DateTime(2025, 2, 10),
      );

      final trend = await container.read(multiYearTrendProvider.future);
      expect(trend.length, 2);
      expect(trend[0].season.id, 's1');
      expect(trend[0].summary.profit, 30000.0);
      expect(trend[1].season.id, 's2');
      expect(trend[1].summary.profit, 45000.0);

      final comparison =
          await container.read(seasonComparisonProvider('s2').future);
      expect(comparison?.previousSeason?.id, 's1');
      expect(comparison?.profitVariance, closeTo(0.5, 0.001));
    });

    test('deleteSeason falls back to remaining season instead of clearing all',
        () async {
      final s1Time = DateTime(2025, 1, 1).toIso8601String();
      final s2Time = DateTime(2026, 1, 1).toIso8601String();

      await db.execute(
        '''
        INSERT INTO seasons(id, name, crop_type, land_area, start_date, status, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          's1',
          'Wheat 2025',
          'Wheat',
          10.0,
          s1Time,
          'Completed',
          s1Time,
          s1Time
        ],
      );
      await db.execute(
        '''
        INSERT INTO seasons(id, name, crop_type, land_area, start_date, status, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        ['s2', 'Wheat 2026', 'Wheat', 10.0, s2Time, 'Active', s2Time, s2Time],
      );

      await container.read(activeSeasonIdProvider.notifier).set('s2');
      expect(container.read(activeSeasonIdProvider), 's2');

      await container.read(seasonsNotifierProvider.notifier).deleteSeason('s2');
      expect(container.read(activeSeasonIdProvider), 's1');

      await container.read(seasonsNotifierProvider.notifier).deleteSeason('s1');
      expect(container.read(activeSeasonIdProvider), isNull);
    });
  });
}
