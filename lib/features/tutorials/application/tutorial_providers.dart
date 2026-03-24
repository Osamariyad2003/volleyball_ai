import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tutorial_catalog_repository.dart';
import '../data/models/tutorial_models.dart';

final tutorialCatalogRepositoryProvider = Provider<TutorialCatalogRepository>((
  ref,
) {
  return TutorialCatalogRepository();
});

final tutorialCatalogProvider = FutureProvider<TutorialCatalog>((ref) async {
  return ref.read(tutorialCatalogRepositoryProvider).loadCatalog();
});
