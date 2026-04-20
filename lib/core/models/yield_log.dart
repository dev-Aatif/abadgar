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
    required YieldDisposition disposition,
    double? salePrice,
    String? destination,
    required DateTime date,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _YieldLog;

  factory YieldLog.fromJson(Map<String, dynamic> json) => _$YieldLogFromJson(json);

  factory YieldLog.fromRow(Map<String, dynamic> row) {
    try {
      return YieldLog(
        id: row['id'] as String,
        seasonId: row['season_id'] as String,
        totalWeight: (row['total_weight'] as num?)?.toDouble() ?? 0.0,
        unit: YieldUnit.fromString(row['unit'] as String? ?? 'Kg'),
        disposition: YieldDisposition.fromString(row['disposition'] as String? ?? 'Sold'),
        salePrice: (row['sale_price'] as num?)?.toDouble(),
        destination: row['destination'] as String?,
        date: DateTime.tryParse(row['date'] as String? ?? '') ?? DateTime.now(),
        createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      return YieldLog(
        id: row['id'] as String? ?? 'error',
        seasonId: row['season_id'] as String? ?? '',
        totalWeight: 0.0,
        unit: YieldUnit.kg,
        disposition: YieldDisposition.sold,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  static Map<String, dynamic> toRow(YieldLog log) {
    return {
      'id': log.id,
      'season_id': log.seasonId,
      'total_weight': log.totalWeight,
      'unit': log.unit.value,
      'disposition': log.disposition.value,
      'sale_price': log.salePrice,
      'destination': log.destination,
      'date': log.date.toIso8601String(),
      'created_at': log.createdAt.toIso8601String(),
      'updated_at': log.updatedAt.toIso8601String(),
    };
  }
}
