import '../models/merge_mapping.dart';
import '../repositories/other_feed_repository.dart';

class OtherFeedService {
  OtherFeedService(this._repository);

  final OtherFeedRepository _repository;
  List<MergeMapping>? _mergeMappingsCache;

  Future<List<MergeMapping>> fetchCompetitorMergeMappings() async {
    _mergeMappingsCache ??= await _repository.fetchCompetitorMergeMappings();
    return _mergeMappingsCache!;
  }
}
