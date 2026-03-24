class CompetitionInfoModel {
  const CompetitionInfoModel({
    required this.id,
    required this.name,
    this.gender,
    this.categoryName,
  });

  final String id;
  final String name;
  final String? gender;
  final String? categoryName;

  factory CompetitionInfoModel.fromJson(Map<String, dynamic> json) {
    final competition =
        (json['competition'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final category =
        (competition['category'] as Map?)?.cast<String, dynamic>() ??
        (json['category'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    return CompetitionInfoModel(
      id: competition['id']?.toString() ?? '',
      name: competition['name']?.toString() ?? '',
      gender: competition['gender']?.toString(),
      categoryName: category['name']?.toString(),
    );
  }
}
