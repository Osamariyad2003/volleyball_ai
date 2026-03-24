import 'package:json_annotation/json_annotation.dart';

part 'competition_model.g.dart';

@JsonSerializable()
class CompetitionModel {
  final String id;
  final String name;
  @JsonKey(name: 'alternative_name')
  final String? alternativeName;
  final String? gender;
  final String? type;

  CompetitionModel({
    required this.id,
    required this.name,
    this.alternativeName,
    this.gender,
    this.type,
  });

  factory CompetitionModel.fromJson(Map<String, dynamic> json) =>
      _$CompetitionModelFromJson(json);

  Map<String, dynamic> toJson() => _$CompetitionModelToJson(this);
}

@JsonSerializable()
class CompetitionsResponse {
  final List<CompetitionModel> competitions;
  @JsonKey(name: 'generated_at')
  final String generatedAt;

  CompetitionsResponse({
    required this.competitions,
    required this.generatedAt,
  });

  factory CompetitionsResponse.fromJson(Map<String, dynamic> json) =>
      _$CompetitionsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CompetitionsResponseToJson(this);
}
