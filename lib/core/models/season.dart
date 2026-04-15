import 'package:freezed_annotation/freezed_annotation.dart';

part 'season.freezed.dart';
part 'season.g.dart';

@freezed
class Season with _$Season {
  const factory Season({
    required String id,
    required String name,
    required String cropType, // 'Rice' | 'Wheat'
    required double landArea,
    required DateTime startDate,
    DateTime? endDate,
    required String status, // 'Planned' | 'Active' | 'Completed'
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Season;

  factory Season.fromJson(Map<String, dynamic> json) => _$SeasonFromJson(json);

  // PowerSync format: from local sqlite row
  factory Season.fromRow(Map<String, dynamic> row) {
    return Season(
      id: row['id'] as String,
      name: row['name'] as String,
      cropType: row['crop_type'] as String,
      landArea: (row['land_area'] as num).toDouble(),
      startDate: DateTime.parse(row['start_date'] as String),
      endDate: row['end_date'] != null ? DateTime.parse(row['end_date'] as String) : null,
      status: row['status'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  // To Map for local sqlite / supabase insert
  static Map<String, dynamic> toRow(Season season) {
    return {
      'id': season.id,
      'name': season.name,
      'crop_type': season.cropType,
      'land_area': season.landArea,
      'start_date': season.startDate.toIso8601String(),
      'end_date': season.endDate?.toIso8601String(),
      'status': season.status,
      'created_at': season.createdAt.toIso8601String(),
      'updated_at': season.updatedAt.toIso8601String(),
    };
  }
}
