import 'package:freezed_annotation/freezed_annotation.dart';

part 'yield_log.freezed.dart';
part 'yield_log.g.dart';

@freezed
class YieldLog with _$YieldLog {
  const factory YieldLog({
    required String id,
    required String seasonId,
    required double totalWeight,
    required String unit, // Kg or Tons
    required DateTime date,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _YieldLog;

  factory YieldLog.fromJson(Map<String, dynamic> json) => _$YieldLogFromJson(json);
}
