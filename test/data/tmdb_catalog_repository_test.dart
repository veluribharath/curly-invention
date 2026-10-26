import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:reel/data/repositories/tmdb_catalog_repository.dart';
import 'package:reel/data/services/tmdb_client.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/entities/streaming.dart';
import 'package:reel/domain/repositories/catalog_repository.dart';

void main() {
  late List<http.Request> requests;
  late Map<String, Object> responses;

  TmdbCatalogRepository repo({String key = '0123456789abcdef0123456789abcdef'}) {
    final client = MockClient((request) async {
      requests.add(request);
      final body = responses[request.url.path] ?? {'results': []};
      return http.Response(json.encode(body), 200);
    });
    return TmdbCatalogRepository(TmdbClient(apiKey: key, httpClient: client));
  }

  setUp(() {
    requests = [];
    responses = {};
  });

  test('a v3 key goes in the query, a v4 token in the header', () async {
    await repo().trending();
    expect(requests.single.url.queryParameters['api_key'], hasLength(32));
    expect(requests.single.headers['Authorization'], isNull);

    requests.clear();
    await repo(key: 'eyJhbGciOi.token').trending();
    expect(requests.single.url.queryParameters.containsKey('api_key'), isFalse);
    expect(requests.single.headers['Authorization'], 'Bearer eyJhbGciOi.token');
  });

  test('errors carry the TMDB status message', () async {
    final client = MockClient((_) async => http.Response('{"status_message":"Invalid API key"}', 401));
    final failing = TmdbCatalogRepository(TmdbClient(apiKey: 'k', httpClient: client));
    expect(
      failing.trending(),
      throwsA(
        isA<TmdbException>()
            .having((e) => e.statusCode, 'status', 401)
            .having((e) => e.message, 'message', 'Invalid API key'),
      ),
    );
  });

  test('discover filters by services, genres and votes', () async {
    await repo().discover(
      const DiscoverQuery(
        type: MediaType.movie,
        genres: ['Action', 'Comedy'],
        withoutGenres: ['Documentary'],
        region: 'US',
        providerIds: {8, 9},
        monetization: {OfferType.subscription, OfferType.ads},
        minVotes: 200,
        sort: DiscoverSort.topRated,
      ),
    );
    final query = requests.single.url.queryParameters;
    expect(requests.single.url.path, '/3/discover/movie');
    expect(query['with_genres'], '28|35');
    expect(query['without_genres'], '99');
    expect(query['watch_region'], 'US');
    expect(query['with_watch_providers'], '8|9');
    expect(query['with_watch_monetization_types'], 'flatrate|ads');
    expect(query['vote_count.gte'], '200');
    expect(query['sort_by'], 'vote_average.desc');
  });

  test('a genre series lack matches no series instead of all of them', () async {
    final page = await repo().discover(const DiscoverQuery(type: MediaType.tv, genres: ['Horror', 'Romance']));
    expect(page.titles, isEmpty);
    expect(requests, isEmpty);

    await repo().discover(const DiscoverQuery(type: MediaType.tv, genres: ['Horror', 'Science Fiction']));
    expect(requests.single.url.queryParameters['with_genres'], '10765');
  });

  test('search adds the known titles of people found', () async {
    responses['/3/search/multi'] = {
      'page': 1,
      'total_pages': 1,
      'results': [
        {'id': 1, 'media_type': 'movie', 'title': 'Direct hit'},
        {
          'id': 50,
          'media_type': 'person',
          'name': 'Someone',
          'known_for': [
            {'id': 1, 'media_type': 'movie', 'title': 'Direct hit'},
            {'id': 7, 'media_type': 'tv', 'name': 'Their show'},
          ],
        },
      ],
    };
    final page = await repo().search('some');
    expect(page.titles.map((t) => t.name), ['Direct hit', 'Their show']);
  });

  test('services merge movie and TV lists by provider', () async {
    responses['/3/watch/providers/movie'] = {
      'results': [
        {
          'provider_id': 8,
          'provider_name': 'Netflix',
          'display_priorities': {'US': 3},
        },
      ],
    };
    responses['/3/watch/providers/tv'] = {
      'results': [
        {
          'provider_id': 8,
          'provider_name': 'Netflix',
          'display_priorities': {'US': 1},
        },
        {
          'provider_id': 15,
          'provider_name': 'Hulu',
          'display_priorities': {'US': 2},
        },
      ],
    };
    final services = await repo().services('US');
    expect(services.map((s) => '${s.name}:${s.displayPriority}'), ['Netflix:1', 'Hulu:2']);
  });
}
