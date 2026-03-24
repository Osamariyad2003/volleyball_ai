class MergeMapping {
  const MergeMapping({
    required this.mergedId,
    required this.retainedId,
    this.mergedName,
    this.retainedName,
    this.createdAt,
  });

  final String mergedId;
  final String retainedId;
  final String? mergedName;
  final String? retainedName;
  final DateTime? createdAt;

  factory MergeMapping.fromJson(Map<String, dynamic> json) {
    return MergeMapping(
      mergedId:
          json['merged_id']?.toString() ?? json['source_id']?.toString() ?? '',
      retainedId:
          json['retained_id']?.toString() ??
          json['target_id']?.toString() ??
          '',
      mergedName: json['merged_name']?.toString(),
      retainedName: json['retained_name']?.toString(),
      createdAt: DateTime.tryParse(
        json['created_at']?.toString() ?? json['updated_at']?.toString() ?? '',
      ),
    );
  }
}
