import 'package:reel/data/models/tmdb_mapper.dart';
import 'package:reel/data/repositories/mock_catalog_repository.dart';
import 'package:reel/data/services/tmdb_client.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/entities/streaming.dart';
import 'package:reel/domain/repositories/availability_repository.dart';

const _justWatchAttribution = 'Streaming data from JustWatch, via TMDB';

/// TMDB's `watch/providers`, which JustWatch powers. No deep links and no
/// leaving dates; JustWatch must be credited wherever it's shown.
class TmdbAvailabilityRepository implements AvailabilityRepository {
  final TmdbClient _client;
  final DateTime Function() _now;

  TmdbAvailabilityRepository(this._client, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  @override
  bool get hasDeepLinks => false;

  @override
  String get attribution => _justWatchAttribution;

  @override
  Future<Availability> forTitle(TitleId id, String country) async {
    final json = await _client.get('/${id.type.name}/${id.tmdbId}/watch/providers');
    return TmdbMapper.availability(id, country, json, fetchedAt: _now());
  }
}

/// The mock catalog's offers, the same in every country.
class MockAvailabilityRepository implements AvailabilityRepository {
  const MockAvailabilityRepository();

  @override
  bool get hasDeepLinks => false;

  @override
  String get attribution => _justWatchAttribution;

  @override
  Future<Availability> forTitle(TitleId id, String country) async {
    return Availability(
      id: id,
      country: country,
      offers: MockCatalog.offers[id] ?? const [],
      link: Uri.https('www.themoviedb.org', '/${id.type.name}/${id.tmdbId}/watch'),
      fetchedAt: DateTime.now(),
    );
  }
}
