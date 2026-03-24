// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'season_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SeasonModel _$SeasonModelFromJson(Map<String, dynamic> json) => SeasonModel(
  id: json['id'] as String,
  name: json['name'] as String,
  startDate: json['start_date'] as String?,
  endDate: json['end_date'] as String?,
  year: json['year'] as String?,
  competitionId: json['competition_id'] as String?,
);

Map<String, dynamic> _$SeasonModelToJson(SeasonModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'start_date': instance.startDate,
      'end_date': instance.endDate,
      'year': instance.year,
      'competition_id': instance.competitionId,
    };

SeasonsResponse _$SeasonsResponseFromJson(Map<String, dynamic> json) =>
    SeasonsResponse(
      seasons: (json['seasons'] as List<dynamic>)
          .map((e) => SeasonModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SeasonsResponseToJson(SeasonsResponse instance) =>
    <String, dynamic>{'seasons': instance.seasons};
