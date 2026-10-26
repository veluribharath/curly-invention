import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:reel/core/config/app_config.dart';
import 'package:reel/data/repositories/mock_catalog_repository.dart';
import 'package:reel/data/repositories/tmdb_catalog_repository.dart';
import 'package:reel/data/services/tmdb_client.dart';
import 'package:reel/domain/repositories/catalog_repository.dart';

/// TMDB when a key is set, the built-in mock catalog otherwise.
final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  if (AppConfig.hasTmdbKey) {
    return TmdbCatalogRepository(TmdbClient(apiKey: AppConfig.tmdbApiKey));
  }
  return const MockCatalogRepository(latency: Duration(milliseconds: 300));
});
