// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'yield_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

YieldLog _$YieldLogFromJson(Map<String, dynamic> json) {
  return _YieldLog.fromJson(json);
}

/// @nodoc
mixin _$YieldLog {
  String get id => throw _privateConstructorUsedError;
  String get seasonId => throw _privateConstructorUsedError;
  double get totalWeight => throw _privateConstructorUsedError;
  String get unit => throw _privateConstructorUsedError; // Kg or Tons
  DateTime get date => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $YieldLogCopyWith<YieldLog> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $YieldLogCopyWith<$Res> {
  factory $YieldLogCopyWith(YieldLog value, $Res Function(YieldLog) then) =
      _$YieldLogCopyWithImpl<$Res, YieldLog>;
  @useResult
  $Res call(
      {String id,
      String seasonId,
      double totalWeight,
      String unit,
      DateTime date,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$YieldLogCopyWithImpl<$Res, $Val extends YieldLog>
    implements $YieldLogCopyWith<$Res> {
  _$YieldLogCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? seasonId = null,
    Object? totalWeight = null,
    Object? unit = null,
    Object? date = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      seasonId: null == seasonId
          ? _value.seasonId
          : seasonId // ignore: cast_nullable_to_non_nullable
              as String,
      totalWeight: null == totalWeight
          ? _value.totalWeight
          : totalWeight // ignore: cast_nullable_to_non_nullable
              as double,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$YieldLogImplCopyWith<$Res>
    implements $YieldLogCopyWith<$Res> {
  factory _$$YieldLogImplCopyWith(
          _$YieldLogImpl value, $Res Function(_$YieldLogImpl) then) =
      __$$YieldLogImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String seasonId,
      double totalWeight,
      String unit,
      DateTime date,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$$YieldLogImplCopyWithImpl<$Res>
    extends _$YieldLogCopyWithImpl<$Res, _$YieldLogImpl>
    implements _$$YieldLogImplCopyWith<$Res> {
  __$$YieldLogImplCopyWithImpl(
      _$YieldLogImpl _value, $Res Function(_$YieldLogImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? seasonId = null,
    Object? totalWeight = null,
    Object? unit = null,
    Object? date = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$YieldLogImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      seasonId: null == seasonId
          ? _value.seasonId
          : seasonId // ignore: cast_nullable_to_non_nullable
              as String,
      totalWeight: null == totalWeight
          ? _value.totalWeight
          : totalWeight // ignore: cast_nullable_to_non_nullable
              as double,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$YieldLogImpl implements _YieldLog {
  const _$YieldLogImpl(
      {required this.id,
      required this.seasonId,
      required this.totalWeight,
      required this.unit,
      required this.date,
      required this.createdAt,
      required this.updatedAt});

  factory _$YieldLogImpl.fromJson(Map<String, dynamic> json) =>
      _$$YieldLogImplFromJson(json);

  @override
  final String id;
  @override
  final String seasonId;
  @override
  final double totalWeight;
  @override
  final String unit;
// Kg or Tons
  @override
  final DateTime date;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'YieldLog(id: $id, seasonId: $seasonId, totalWeight: $totalWeight, unit: $unit, date: $date, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$YieldLogImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.seasonId, seasonId) ||
                other.seasonId == seasonId) &&
            (identical(other.totalWeight, totalWeight) ||
                other.totalWeight == totalWeight) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, seasonId, totalWeight, unit, date, createdAt, updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$YieldLogImplCopyWith<_$YieldLogImpl> get copyWith =>
      __$$YieldLogImplCopyWithImpl<_$YieldLogImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$YieldLogImplToJson(
      this,
    );
  }
}

abstract class _YieldLog implements YieldLog {
  const factory _YieldLog(
      {required final String id,
      required final String seasonId,
      required final double totalWeight,
      required final String unit,
      required final DateTime date,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$YieldLogImpl;

  factory _YieldLog.fromJson(Map<String, dynamic> json) =
      _$YieldLogImpl.fromJson;

  @override
  String get id;
  @override
  String get seasonId;
  @override
  double get totalWeight;
  @override
  String get unit;
  @override // Kg or Tons
  DateTime get date;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$YieldLogImplCopyWith<_$YieldLogImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
