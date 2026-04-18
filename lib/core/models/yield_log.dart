import 'package:freezed_annotation/freezed_annotation.dart';
import '../constants/enums.dart';

part 'yield_log.freezed.dart';
part 'yield_log.g.dart';

@freezed
class YieldLog with _$YieldLog {
  const factory YieldLog({
    required String id,
    required String seasonId,
    required double totalWeight,
    required YieldUnit unit,
    required DateTime date,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _YieldLog;

  factory YieldLog.fromJson(Map<String, dynamic> json) => _$YieldLogFromJson(json);

  factory YieldLog.fromRow(Map<String, dynamic> row) {
    return YieldLog(
      id: row['id'] as String,
      seasonId: row['season_id'] as String,
      totalWeight: (row['total_weight'] as num).toDouble(),
      unit: YieldUnit.fromString(row['unit'] as String),
      date: DateTime.parse(row['date'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  static Map<String, dynamic> toRow(YieldLog log) {
    return {
      'id': log.id,
      'season_id': log.seasonId,
      'total_weight': log.totalWeight,
      'unit': log.unit.value,
      'date': log.date.toIso8601String(),
      'created_at': log.createdAt.toIso8601String(),
      'updated_at': log.updatedAt.toIso8601String(),
    };
  }
}
