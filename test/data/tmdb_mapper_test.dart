import 'package:flutter_test/flutter_test.dart';
import 'package:reel/data/models/tmdb_mapper.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/entities/person.dart';
import 'package:reel/domain/entities/streaming.dart';
import 'package:reel/domain/entities/video.dart';

void main() {
  group('TmdbGenres', () {
    test('splits compound TV genres into movie names', () {
      expect(TmdbGenres.names(MediaType.tv, [10759, 10765, 18]), [
        'Action',
        'Adventure',
        'Science Fiction',
        'Fantasy',
        'Drama',
      ]);
    });

    test('maps names back to the ids each media type knows', () {
      expect(TmdbGenres.ids(MediaType.movie, ['Action', 'Documentary']), [28, 99]);
      expect(TmdbGenres.ids(MediaType.tv, ['Action', 'Adventure']), [10759]);
      expect(TmdbGenres.ids(MediaType.tv, ['Horror']), isEmpty);
    });
  });

  group('TmdbMapper.title', () {
    test('reads a movie from a details response', () {
      final title = TmdbMapper.title({
        'id': 27205,
        'title': 'Inception',
        'release_date': '2010-07-15',
        'genres': [
          {'id': 878, 'name': 'Science Fiction'},
        ],
        'poster_path': '/p.jpg',
        'runtime': 148,
        'vote_average': 8.4,
        'credits': {
          'cast': [
            {'id': 2, 'name': 'Second', 'order': 1},
            {'id': 1, 'name': 'First', 'order': 0},
          ],
          'crew': [
            {'id': 525, 'name': 'Christopher Nolan', 'job': 'Director'},
            {'id': 9, 'name': 'Someone', 'job': 'Writer'},
          ],
        },
        'videos': {
          'results': [
            {'key': 'abc', 'site': 'YouTube', 'type': 'Trailer', 'official': true, 'iso_639_1': 'en'},
            {'key': 'vim', 'site': 'Vimeo', 'type': 'Trailer'},
          ],
        },
      }, type: MediaType.movie)!;

      expect(title.id, const TitleId.movie(27205));
      expect(title.year, 2010);
      expect(title.genres, ['Science Fiction']);
      expect(title.runtimeMinutes, 148);
      expect(title.cast.map((p) => p.name), ['First', 'Second']);
      expect(title.directors, [const Person(id: '525', name: 'Christopher Nolan')]);
      expect(title.videos.single.key, 'abc');
      expect(title.videos.single.kind, VideoKind.trailer);
    });

    test('reads a series with creators and episode runtime', () {
      final title = TmdbMapper.title({
        'id': 1396,
        'name': 'Breaking Bad',
        'first_air_date': '2008-01-20',
        'genre_ids': [18, 80],
        'episode_run_time': [],
        'last_episode_to_air': {'runtime': 47},
        'number_of_seasons': 5,
        'created_by': [
          {'id': 66633, 'name': 'Vince Gilligan'},
        ],
      }, type: MediaType.tv)!;
      expect(title.name, 'Breaking Bad');
      expect(title.runtimeMinutes, 47);
      expect(title.seasonCount, 5);
      expect(title.directors.single.name, 'Vince Gilligan');
    });

    test('uses media_type from multi search and skips people', () {
      final titles = TmdbMapper.titles([
        {'id': 1, 'media_type': 'movie', 'title': 'A'},
        {'id': 2, 'media_type': 'person', 'name': 'B'},
        {
          'id': 3,
          'media_type': 'tv',
          'name': 'C',
          'genre_ids': [99],
        },
      ]);
      expect(titles.map((t) => t.id.encode()), ['movie:1', 'tv:3']);
      expect(titles.last.isDocumentary, isTrue);
    });
  });

  test('availability groups offers by type for the country', () {
    final availability = TmdbMapper.availability(const TitleId.movie(1), 'US', {
      'results': {
        'US': {
          'link': 'https://www.themoviedb.org/movie/1/watch?locale=US',
          'flatrate': [
            {'provider_id': 8, 'provider_name': 'Netflix', 'logo_path': '/n.jpg', 'display_priority': 2},
          ],
          'rent': [
            {'provider_id': 2, 'provider_name': 'Apple TV', 'display_priority': 1},
          ],
        },
        'GB': {
          'flatrate': [
            {'provider_id': 9, 'provider_name': 'Prime'},
          ],
        },
      },
    }, fetchedAt: DateTime(2026));
    expect(availability.offers.map((o) => '${o.type.name}:${o.service.name}'), [
      'subscription:Netflix',
      'rent:Apple TV',
    ]);
    expect(availability.link, isNotNull);
    expect(availability.isPlayableOn({8}), isTrue);
    expect(availability.isPlayableOn({2}), isFalse);
  });

  test('a country with no data has no offers', () {
    final availability = TmdbMapper.availability(const TitleId.movie(1), 'IN', {
      'results': {},
    }, fetchedAt: DateTime(2026));
    expect(availability.isEmpty, isTrue);
  });

  test('playable offers include free ones only when asked, each service once', () {
    const netflix = StreamingService(providerId: 8, name: 'Netflix');
    const tubi = StreamingService(providerId: 73, name: 'Tubi');
    final availability = Availability(
      id: const TitleId.movie(1),
      country: 'US',
      offers: const [
        Offer(service: tubi, type: OfferType.ads),
        Offer(service: netflix, type: OfferType.ads),
        Offer(service: netflix, type: OfferType.subscription),
      ],
      fetchedAt: DateTime(2026),
    );
    expect(availability.playableOn({8}).map((o) => o.type), [OfferType.subscription]);
    expect(availability.playableOn({8}, includeFree: true).map((o) => o.service.name), ['Netflix', 'Tubi']);
  });
}
