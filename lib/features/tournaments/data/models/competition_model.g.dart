// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'competition_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompetitionModel _$CompetitionModelFromJson(Map<String, dynamic> json) =>
    CompetitionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      alternativeName: json['alternative_name'] as String?,
      gender: json['gender'] as String?,
      type: json['type'] as String?,
    );

Map<String, dynamic> _$CompetitionModelToJson(CompetitionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'alternative_name': instance.alternativeName,
      'gender': instance.gender,
      'type': instance.type,
    };

CompetitionsResponse _$CompetitionsResponseFromJson(
  Map<String, dynamic> json,
) => CompetitionsResponse(
  competitions: (json['competitions'] as List<dynamic>)
      .map((e) => CompetitionModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  generatedAt: json['generated_at'] as String,
);

Map<String, dynamic> _$CompetitionsResponseToJson(
  CompetitionsResponse instance,
) => <String, dynamic>{
  'competitions': instance.competitions,
  'generated_at': instance.generatedAt,
};
