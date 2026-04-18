// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'season.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SeasonImpl _$$SeasonImplFromJson(Map<String, dynamic> json) => _$SeasonImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      cropType: $enumDecode(_$CropTypeEnumMap, json['cropType']),
      landArea: (json['landArea'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      status: $enumDecode(_$SeasonStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$SeasonImplToJson(_$SeasonImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'cropType': _$CropTypeEnumMap[instance.cropType]!,
      'landArea': instance.landArea,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'status': _$SeasonStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$CropTypeEnumMap = {
  CropType.wheat: 'wheat',
  CropType.rice: 'rice',
};

const _$SeasonStatusEnumMap = {
  SeasonStatus.planned: 'planned',
  SeasonStatus.active: 'active',
  SeasonStatus.completed: 'completed',
};
