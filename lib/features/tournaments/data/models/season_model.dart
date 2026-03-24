import 'package:json_annotation/json_annotation.dart';

part 'season_model.g.dart';

@JsonSerializable()
class SeasonModel {
  final String id;
  final String name;
  @JsonKey(name: 'start_date')
  final String? startDate;
  @JsonKey(name: 'end_date')
  final String? endDate;
  final String? year;
  @JsonKey(name: 'competition_id')
  final String? competitionId;

  SeasonModel({
    required this.id,
    required this.name,
    this.startDate,
    this.endDate,
    this.year,
    this.competitionId,
  });

  factory SeasonModel.fromJson(Map<String, dynamic> json) =>
      _$SeasonModelFromJson(json);

  Map<String, dynamic> toJson() => _$SeasonModelToJson(this);
}

@JsonSerializable()
class SeasonsResponse {
  final List<SeasonModel> seasons;

  SeasonsResponse({
    required this.seasons,
  });

  factory SeasonsResponse.fromJson(Map<String, dynamic> json) =>
      _$SeasonsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SeasonsResponseToJson(this);
}
