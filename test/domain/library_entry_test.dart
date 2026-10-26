import 'package:flutter_test/flutter_test.dart';
import 'package:reel/data/repositories/mock_catalog_repository.dart';
import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/domain/entities/media_type.dart';

void main() {
  final title = MockCatalog.byId(const TitleId.movie(27205))!;
  final now = DateTime(2026, 10, 26);

  test('logging a watch takes the title off the watchlist', () {
    final entry = LibraryEntry.empty(title, now: now).copyWith(onWatchlist: true);
    final watched = entry.logWatch(
      WatchEvent(watchedAt: now, rating: Rating.loved),
      now: now,
    );
    expect(watched.onWatchlist, isFalse);
    expect(watched.watched, isTrue);
    expect(watched.latestRating, Rating.loved);
  });

  test('rewatches are kept in date order and the latest rating wins', () {
    var entry = LibraryEntry.empty(title, now: now);
    entry = entry.logWatch(
      WatchEvent(watchedAt: DateTime(2024), rating: Rating.liked),
      now: now,
    );
    entry = entry.logWatch(
      WatchEvent(watchedAt: DateTime(2020), rating: Rating.disliked),
      now: now,
    );
    entry = entry.logWatch(WatchEvent(watchedAt: DateTime(2025)), now: now);
    expect(entry.watches.map((w) => w.watchedAt.year), [2020, 2024, 2025]);
    expect(entry.latestRating, Rating.liked);
    expect(entry.lastWatchedAt, DateTime(2025));
  });

  test('removing the last watch clears the favorite', () {
    final entry = LibraryEntry.empty(
      title,
      now: now,
    ).logWatch(WatchEvent(watchedAt: now), now: now).copyWith(favorite: true);
    final removed = entry.removeWatch(0, now: now);
    expect(removed.favorite, isFalse);
    expect(removed.isEmpty, isTrue);
  });

  test('a list copy of the title keeps the saved credits', () {
    final entry = LibraryEntry.empty(title, now: now);
    final bare = title.copyWith(cast: const [], directors: const [], name: 'Inception (2010)');
    final updated = entry.withSnapshot(bare, now: now);
    expect(updated.snapshot.name, 'Inception (2010)');
    expect(updated.snapshot.directors, title.directors);
  });
}
