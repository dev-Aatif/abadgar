// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yield_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$YieldLogImpl _$$YieldLogImplFromJson(Map<String, dynamic> json) =>
    _$YieldLogImpl(
      id: json['id'] as String,
      seasonId: json['seasonId'] as String,
      totalWeight: (json['totalWeight'] as num).toDouble(),
      unit: $enumDecode(_$YieldUnitEnumMap, json['unit']),
      disposition: $enumDecode(_$YieldDispositionEnumMap, json['disposition']),
      salePrice: (json['salePrice'] as num?)?.toDouble(),
      destination: json['destination'] as String?,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$YieldLogImplToJson(_$YieldLogImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'seasonId': instance.seasonId,
      'totalWeight': instance.totalWeight,
      'unit': _$YieldUnitEnumMap[instance.unit]!,
      'disposition': _$YieldDispositionEnumMap[instance.disposition]!,
      'salePrice': instance.salePrice,
      'destination': instance.destination,
      'date': instance.date.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$YieldUnitEnumMap = {
  YieldUnit.kg: 'kg',
  YieldUnit.mund: 'mund',
  YieldUnit.tons: 'tons',
};

const _$YieldDispositionEnumMap = {
  YieldDisposition.sold: 'sold',
  YieldDisposition.stored: 'stored',
  YieldDisposition.personal: 'personal',
};
