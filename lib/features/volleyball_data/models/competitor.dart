class Competitor {
  const Competitor({
    required this.id,
    required this.name,
    this.abbreviation,
    this.country,
    this.countryCode,
    this.gender,
    this.ageGroup,
    this.categoryName,
    this.qualifier,
  });

  final String id;
  final String name;
  final String? abbreviation;
  final String? country;
  final String? countryCode;
  final String? gender;
  final String? ageGroup;
  final String? categoryName;
  final String? qualifier;

  factory Competitor.fromJson(
    Map<String, dynamic> json, {
    String? categoryName,
  }) {
    return Competitor(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown competitor',
      abbreviation: json['abbreviation']?.toString(),
      country: json['country']?.toString(),
      countryCode: json['country_code']?.toString(),
      gender: json['gender']?.toString(),
      ageGroup: json['age_group']?.toString(),
      categoryName: categoryName,
      qualifier: json['qualifier']?.toString(),
    );
  }
}
