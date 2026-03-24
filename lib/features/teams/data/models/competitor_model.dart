import 'package:json_annotation/json_annotation.dart';

part 'competitor_model.g.dart';

@JsonSerializable()
class CompetitorModel {
  final String id;
  final String name;
  final String? country;
  @JsonKey(name: 'country_code')
  final String? countryCode;
  final String? abbreviation;

  CompetitorModel({
    required this.id,
    required this.name,
    this.country,
    this.countryCode,
    this.abbreviation,
  });

  factory CompetitorModel.fromJson(Map<String, dynamic> json) =>
      _$CompetitorModelFromJson(json);

  Map<String, dynamic> toJson() => _$CompetitorModelToJson(this);
}

class CompetitorsResponse {
  final List<CompetitorModel> competitors;

  CompetitorsResponse({required this.competitors});

  factory CompetitorsResponse.fromJson(Map<String, dynamic> json) {
    final rawCompetitors =
        json['competitors'] ??
        json['season_competitors'] ??
        json['competitor'] ??
        (json['season'] is Map<String, dynamic>
            ? (json['season'] as Map<String, dynamic>)['competitors']
            : null);

    if (rawCompetitors is List) {
      return CompetitorsResponse(
        competitors: rawCompetitors
            .whereType<Map<String, dynamic>>()
            .map(CompetitorModel.fromJson)
            .toList(),
      );
    }

    if (rawCompetitors is Map<String, dynamic>) {
      final nestedCompetitors =
          rawCompetitors['competitors'] ?? rawCompetitors['competitor'];
      if (nestedCompetitors is List) {
        return CompetitorsResponse(
          competitors: nestedCompetitors
              .whereType<Map<String, dynamic>>()
              .map(CompetitorModel.fromJson)
              .toList(),
        );
      }
    }

    return CompetitorsResponse(competitors: []);
  }

  Map<String, dynamic> toJson() => {'competitors': competitors};
}
