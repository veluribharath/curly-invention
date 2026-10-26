import 'package:flutter_test/flutter_test.dart';
import 'package:reel/data/repositories/mock_catalog_repository.dart';
import 'package:reel/domain/entities/feed_signal.dart';
import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/usecases/analyze_taste.dart';

void main() {
  final now = DateTime(2026, 10, 26, 20);

  LibraryEntry watched(TitleId id, Rating? rating, {DateTime? at, bool favorite = false}) =>
      LibraryEntry.empty(MockCatalog.byId(id)!, now: now)
          .logWatch(
            WatchEvent(watchedAt: at ?? now, rating: rating),
            now: now,
          )
          .copyWith(favorite: favorite);

  test('loved sci-fi and a disliked comedy shape genre and people taste', () {
    final taste = analyzeTaste(
      library: [
        watched(const TitleId.movie(27205), Rating.loved),
        watched(const TitleId.movie(157336), Rating.liked, favorite: true),
        watched(const TitleId.tv(2316), Rating.disliked),
      ],
      now: now,
    );
    expect(taste.genre('Science Fiction').score, greaterThan(0.5));
    expect(taste.genre('Comedy').score, lessThan(0));
    expect(taste.directors.first.person.name, 'Christopher Nolan');
    expect(topGenres(taste), contains('Science Fiction'));
    expect(topPeople(taste).first.person.name, 'Christopher Nolan');
    expect(taste.hasTaste, isTrue);
  });

  test('signals count only for titles that can be looked up and are not in the library', () {
    final breakingBad = MockCatalog.byId(const TitleId.tv(1396))!;
    final taste = analyzeTaste(
      library: const [],
      signals: [
        FeedSignal(id: breakingBad.id, type: FeedSignalType.notInterested, at: now),
        FeedSignal(id: const TitleId.movie(999), type: FeedSignalType.watchedClip, at: now),
      ],
      lookup: (id) => id == breakingBad.id ? breakingBad : null,
      now: now,
    );
    expect(taste.genre('Crime').score, lessThan(0));
    expect(taste.genres.map((g) => g.genre), unorderedEquals(['Drama', 'Crime']));
  });

  test('stats count watches this month and year, hours and weeks', () {
    final taste = analyzeTaste(
      library: [
        watched(const TitleId.movie(27205), null, at: DateTime(2026, 10, 20)),
        watched(const TitleId.movie(603), null, at: DateTime(2026, 3, 1)),
        watched(const TitleId.movie(238), null, at: DateTime(2025, 12, 31)),
      ],
      now: now,
    );
    expect(taste.watchedThisMonth, 1);
    expect(taste.watchedThisYear, 2);
    expect(taste.titlesWatched, 3);
    expect(taste.minutesWatched, 148 + 136 + 175);
    expect(taste.weeks, hasLength(12));
    // Oct 20 is in the week before the one starting Monday Oct 26.
    expect(taste.weeks[10].watches, 1);
    expect(taste.weeks.last.watches, 0);
    expect(formatHours(taste.minutesWatched), '8');
  });
}
