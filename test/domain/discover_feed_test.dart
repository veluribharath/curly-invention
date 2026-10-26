import 'package:flutter_test/flutter_test.dart';
import 'package:reel/data/repositories/mock_catalog_repository.dart';
import 'package:reel/domain/entities/media_title.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/entities/streaming.dart';
import 'package:reel/domain/entities/user_settings.dart';
import 'package:reel/domain/usecases/discover_feed.dart';
import 'package:reel/domain/usecases/query_library.dart';

void main() {
  const settings = UserSettings(country: 'US', serviceIds: {8, 1899}, includeFreeWithAds: true);
  const subscriptionsOnly = UserSettings(country: 'US', serviceIds: {8, 1899});

  group('feedQueries', () {
    test('all covers movies and series on your services, plus free ones anywhere', () {
      final queries = feedQueries(const FeedFilter(), settings);
      expect(queries.map((q) => q.type), [MediaType.movie, MediaType.movie, MediaType.tv, MediaType.tv]);
      expect(queries.every((q) => q.region == 'US'), isTrue);
      expect(queries.first.providerIds, {8, 1899});
      expect(queries.first.monetization, {OfferType.subscription});
      expect(queries[1].providerIds, isEmpty);
      expect(queries[1].monetization, {OfferType.free, OfferType.ads});
    });

    test('without free titles, only your subscriptions', () {
      final queries = feedQueries(const FeedFilter(), subscriptionsOnly);
      expect(queries.map((q) => q.type), [MediaType.movie, MediaType.tv]);
      expect(queries.map((q) => q.monetization), everyElement({OfferType.subscription}));
    });

    test('with no services picked, free titles only, not every subscription', () {
      final queries = feedQueries(const FeedFilter(), const UserSettings(country: 'US', includeFreeWithAds: true));
      expect(queries, hasLength(2));
      for (final q in queries) {
        expect(q.providerIds, isEmpty);
        expect(q.monetization, {OfferType.free, OfferType.ads});
      }
    });

    test('movies leave out docs; docs ask for them on both types', () {
      expect(feedQueries(const FeedFilter(kind: KindFilter.movies), subscriptionsOnly).single.withoutGenres, [
        'Documentary',
      ]);
      final docs = feedQueries(const FeedFilter(kind: KindFilter.documentaries), subscriptionsOnly);
      expect(docs.map((q) => q.genres), [
        ['Documentary'],
        ['Documentary'],
      ]);
    });

    test('everything mode has no region filter', () {
      expect(feedQueries(const FeedFilter(myServicesOnly: false), settings).first.region, isNull);
    });

    test('people filters only go to movies', () {
      expect(feedQueries(const FeedFilter(), subscriptionsOnly, people: ['525']).map((q) => q.type), [MediaType.movie]);
    });
  });

  test('the pager skips excluded and already-dealt titles and ranks by source', () async {
    final catalog = const MockCatalogRepository();
    final watchlisted = MockCatalog.byId(const TitleId.movie(238))!;
    final pager = FeedPager(
      sources: [
        ListCandidateSource([FeedCandidate(watchlisted, FeedSource.watchlist, 'On your watchlist')]),
        DiscoverCandidateSource(
          catalog,
          source: FeedSource.popular,
          reason: (_) => 'Popular',
          queries: feedQueries(const FeedFilter(myServicesOnly: false), settings),
        ),
      ],
      isExcluded: (t) => t.id == const TitleId.tv(1396),
    );
    final first = await pager.loadMore();
    final ids = first.map((c) => c.id).toSet();
    expect(ids, contains(watchlisted.id));
    expect(ids, isNot(contains(const TitleId.tv(1396))));
    expect(first.where((c) => c.id == watchlisted.id).single.reason, 'On your watchlist');
    expect(first.first.source, FeedSource.watchlist);

    final second = await pager.loadMore();
    expect(second.where((c) => ids.contains(c.id)), isEmpty);
    expect(pager.exhausted, isTrue);
  });

  test('diversify breaks up runs of a genre, type and franchise', () {
    FeedCard card(int id, String name, MediaType type, String genre, double score) => FeedCard(
      title: MediaTitle(id: TitleId(type, id), name: name, genres: [genre]),
      source: FeedSource.popular,
      reason: '',
      score: score,
    );
    final ranked = [
      card(1, 'John Wick', MediaType.movie, 'Action', 10),
      card(2, 'John Wick: Chapter 4', MediaType.movie, 'Action', 9),
      card(3, 'Heat', MediaType.movie, 'Action', 8),
      card(4, 'The Bear', MediaType.tv, 'Comedy', 7),
    ];
    final names = diversify(ranked).map((c) => c.title.name).toList();
    expect(names, ['John Wick', 'Heat', 'The Bear', 'John Wick: Chapter 4']);
  });

  test('quality trusts averages with more votes', () {
    const fewVotes = MediaTitle(id: TitleId.movie(1), name: 'A', voteAverage: 10, voteCount: 5);
    const manyVotes = MediaTitle(id: TitleId.movie(2), name: 'B', voteAverage: 8.5, voteCount: 20000);
    expect(qualityScore(manyVotes), greaterThan(qualityScore(fewVotes)));
  });
}
