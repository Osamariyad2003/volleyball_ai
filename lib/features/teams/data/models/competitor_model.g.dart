// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'competitor_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompetitorModel _$CompetitorModelFromJson(Map<String, dynamic> json) =>
    CompetitorModel(
      id: json['id'] as String,
      name: json['name'] as String,
      country: json['country'] as String?,
      countryCode: json['country_code'] as String?,
      abbreviation: json['abbreviation'] as String?,
    );

Map<String, dynamic> _$CompetitorModelToJson(CompetitorModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'country': instance.country,
      'country_code': instance.countryCode,
      'abbreviation': instance.abbreviation,
    };
