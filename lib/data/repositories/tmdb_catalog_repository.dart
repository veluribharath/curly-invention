import 'package:reel/data/models/tmdb_mapper.dart';
import 'package:reel/data/services/tmdb_client.dart';
import 'package:reel/domain/entities/media_title.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/entities/streaming.dart';
import 'package:reel/domain/repositories/catalog_repository.dart';

class TmdbCatalogRepository implements CatalogRepository {
  final TmdbClient _client;

  /// TMDB language for names and overviews, e.g. "en-US".
  final String language;

  TmdbCatalogRepository(this._client, {this.language = 'en-US'});

  @override
  Future<TitlePage> search(String query, {int page = 1}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return TitlePage.empty;
    final json = await _client.get('/search/multi', {
      'query': trimmed,
      'page': '$page',
      'language': language,
      'include_adult': 'false',
    });
    final result = TmdbMapper.page(json);
    // A person's best-known titles stand in for the person.
    final seen = {for (final t in result.titles) t.id};
    final knownFor = <MediaTitle>[];
    for (final raw in (json['results'] as List? ?? const [])) {
      if (raw is! Map || raw['media_type'] != 'person') continue;
      for (final title in TmdbMapper.titles(raw['known_for'])) {
        if (seen.add(title.id)) knownFor.add(title);
      }
    }
    return TitlePage(titles: [...result.titles, ...knownFor], page: result.page, hasMore: result.hasMore);
  }

  @override
  Future<MediaTitle> details(TitleId id) async {
    final append = id.type == MediaType.movie ? 'credits,videos' : 'aggregate_credits,videos';
    final json = await _client.get('/${id.type.name}/${id.tmdbId}', {
      'language': language,
      'append_to_response': append,
      // Videos in the UI language, plus ones with no language set.
      'include_video_language': '${language.split('-').first},en,null',
    });
    final title = TmdbMapper.title(json, type: id.type);
    if (title == null) throw TmdbException('No details for $id');
    return title;
  }

  @override
  Future<TitlePage> discover(DiscoverQuery query) async {
    final type = query.type;
    final genreIds = TmdbGenres.ids(type, query.genres);
    // A genre this type doesn't have (series have no Horror or Romance)
    // matches nothing; leaving the filter out would return everything.
    if (query.genres.isNotEmpty && genreIds.isEmpty) return TitlePage(titles: const [], page: query.page);
    final withoutIds = TmdbGenres.ids(type, query.withoutGenres);
    final dateField = type == MediaType.movie ? 'primary_release_date' : 'first_air_date';
    final params = <String, String>{
      'language': language,
      'page': '${query.page.clamp(1, TmdbClient.maxPage)}',
      'include_adult': 'false',
      'sort_by': switch (query.sort) {
        DiscoverSort.popular => 'popularity.desc',
        DiscoverSort.topRated => 'vote_average.desc',
        DiscoverSort.newest => '$dateField.desc',
      },
      // "|" means any of the genres; "," would need all of them.
      if (genreIds.isNotEmpty) 'with_genres': genreIds.join('|'),
      if (withoutIds.isNotEmpty) 'without_genres': withoutIds.join(','),
      if (query.minVotes > 0) 'vote_count.gte': '${query.minVotes}',
      if (query.people.isNotEmpty) 'with_people': query.people.join('|'),
      if (query.releasedAfter != null) '$dateField.gte': _date(query.releasedAfter!),
      // Newest first would otherwise lead with announced, unreleased titles.
      if (query.sort == DiscoverSort.newest) '$dateField.lte': _date(DateTime.now()),
      if (query.region != null) ...{
        'watch_region': query.region!,
        if (query.providerIds.isNotEmpty) 'with_watch_providers': query.providerIds.join('|'),
        if (query.monetization.isNotEmpty)
          'with_watch_monetization_types': query.monetization.map(_monetization).join('|'),
      },
    };
    // People filters only exist on movie discover; TV ignores the param.
    if (type == MediaType.tv) params.remove('with_people');
    final json = await _client.get('/discover/${type.name}', params);
    return TmdbMapper.page(json, type: type);
  }

  @override
  Future<TitlePage> trending({int page = 1}) async {
    final json = await _client.get('/trending/all/week', {'language': language, 'page': '$page'});
    return TmdbMapper.page(json);
  }

  @override
  Future<List<MediaTitle>> similar(TitleId id) async {
    final json = await _client.get('/${id.type.name}/${id.tmdbId}/recommendations', {'language': language});
    return TmdbMapper.titles(json['results'], type: id.type);
  }

  @override
  Future<List<MediaTitle>> byPerson(String personId) async {
    final json = await _client.get('/person/${Uri.encodeComponent(personId)}/combined_credits', {'language': language});
    final crew = [
      for (final raw in (json['crew'] as List? ?? const []))
        if (raw is Map && (raw['job'] == 'Director' || raw['job'] == 'Creator')) raw,
    ];
    final titles = <TitleId, MediaTitle>{};
    for (final title in TmdbMapper.titles([...(json['cast'] as List? ?? const []), ...crew])) {
      titles.putIfAbsent(title.id, () => title);
    }
    return titles.values.toList()..sort((a, b) => (b.popularity ?? 0).compareTo(a.popularity ?? 0));
  }

  @override
  Future<List<StreamingService>> services(String country) async {
    final params = {'language': language, 'watch_region': country};
    final results = await Future.wait([
      _client.get('/watch/providers/movie', params),
      _client.get('/watch/providers/tv', params),
    ]);
    final byId = <int, StreamingService>{};
    for (final json in results) {
      for (final service in TmdbMapper.services(json['results'], country: country)) {
        final seen = byId[service.providerId];
        if (seen == null || service.displayPriority < seen.displayPriority) byId[service.providerId] = service;
      }
    }
    return byId.values.toList()..sort((a, b) => a.displayPriority.compareTo(b.displayPriority));
  }

  @override
  Future<Map<String, String>> regions() async {
    final json = await _client.get('/watch/providers/regions', {'language': language});
    final regions = <String, String>{
      for (final raw in (json['results'] as List? ?? const []))
        if (raw is Map && raw['iso_3166_1'] is String)
          raw['iso_3166_1'] as String: (raw['english_name'] ?? raw['native_name'] ?? raw['iso_3166_1']).toString(),
    };
    final sorted = regions.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    return Map.fromEntries(sorted);
  }

  static String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static String _monetization(OfferType type) => switch (type) {
    OfferType.subscription => 'flatrate',
    OfferType.free => 'free',
    OfferType.ads => 'ads',
    OfferType.rent => 'rent',
    OfferType.buy => 'buy',
  };
}
