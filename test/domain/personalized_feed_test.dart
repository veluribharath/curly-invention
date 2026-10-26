import 'package:flutter_test/flutter_test.dart';
import 'package:reel/data/repositories/mock_catalog_repository.dart';
import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/entities/user_settings.dart';
import 'package:reel/domain/usecases/analyze_taste.dart';
import 'package:reel/domain/usecases/discover_feed.dart';
import 'package:reel/domain/usecases/personalized_feed.dart';

void main() {
  final now = DateTime(2026, 10, 26);
  // Everything on the mock catalog's main services.
  const settings = UserSettings(country: 'US', serviceIds: {8, 9, 337, 1899, 15, 350});

  LibraryEntry rated(TitleId id, Rating rating) => LibraryEntry.empty(MockCatalog.byId(id)!, now: now).logWatch(
    WatchEvent(watchedAt: now, rating: rating),
    now: now,
  );

  Future<List<FeedCard>> feedFor(List<LibraryEntry> library) async {
    final taste = analyzeTaste(library: library, now: now);
    final built = personalizedFeed(
      catalog: const MockCatalogRepository(),
      filter: const FeedFilter(),
      settings: settings,
      library: library,
      taste: taste,
      isWatchlistPlayable: (_) => true,
      isPlayableNow: (_) async => true,
      now: now,
    );
    final watched = {for (final e in library) e.id};
    final pager = FeedPager(sources: built.sources, score: built.score, isExcluded: (t) => watched.contains(t.id));
    return pager.loadMore();
  }

  test('two people with different tastes get clearly different feeds', () async {
    final sciFiFan = await feedFor([
      rated(const TitleId.movie(27205), Rating.loved),
      rated(const TitleId.movie(603), Rating.loved),
      rated(const TitleId.movie(238), Rating.disliked),
      rated(const TitleId.tv(2316), Rating.disliked),
    ]);
    final crimeFan = await feedFor([
      rated(const TitleId.movie(238), Rating.loved),
      rated(const TitleId.movie(680), Rating.loved),
      rated(const TitleId.movie(27205), Rating.disliked),
      rated(const TitleId.movie(603), Rating.disliked),
    ]);

    final sciFiTop = sciFiFan.take(4).map((c) => c.title.name).toSet();
    final crimeTop = crimeFan.take(4).map((c) => c.title.name).toSet();
    expect(sciFiTop.intersection(crimeTop).length, lessThanOrEqualTo(1), reason: '$sciFiTop vs $crimeTop');
    expect(sciFiFan.first.title.genres, contains('Science Fiction'));
    expect(crimeFan.take(3).any((c) => c.title.genres.contains('Crime')), isTrue);
  });

  test('cards say why they are there', () async {
    final feed = await feedFor([
      rated(const TitleId.movie(27205), Rating.loved),
      rated(const TitleId.movie(155), Rating.loved),
      rated(const TitleId.movie(603), Rating.liked),
    ]);
    final reasons = feed.map((c) => c.reason).toSet();
    expect(
      reasons.any((r) => r.startsWith('Because you loved') || r.startsWith('From') || r.startsWith('Because you like')),
      isTrue,
      reason: '$reasons',
    );
  });
}
