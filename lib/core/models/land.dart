import 'package:freezed_annotation/freezed_annotation.dart';

part 'land.freezed.dart';
part 'land.g.dart';

@freezed
class Land with _$Land {
  const factory Land({
    required String id,
    required String name,
    required double area,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Land;

  factory Land.fromJson(Map<String, dynamic> json) => _$LandFromJson(json);

  // PowerSync format: from local sqlite row
  factory Land.fromRow(Map<String, dynamic> row) {
    return Land(
      id: row['id'] as String,
      name: row['name'] as String,
      area: (row['area'] as num).toDouble(),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  static Map<String, dynamic> toRow(Land land) {
    return {
      'id': land.id,
      'name': land.name,
      'area': land.area,
      'created_at': land.createdAt.toIso8601String(),
      'updated_at': land.updatedAt.toIso8601String(),
    };
  }
}
