import 'package:flutter_test/flutter_test.dart';
import 'package:reel/data/repositories/mock_catalog_repository.dart';
import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/usecases/query_library.dart';

void main() {
  LibraryEntry entry(
    TitleId id, {
    bool watchlist = false,
    DateTime? watched,
    Rating? rating,
    bool favorite = false,
    int added = 1,
  }) {
    var e = LibraryEntry.empty(MockCatalog.byId(id)!, now: DateTime(2026, 1, added)).copyWith(onWatchlist: watchlist);
    if (watched != null) {
      e = e.logWatch(
        WatchEvent(watchedAt: watched, rating: rating),
        now: watched,
      );
    }
    return e.copyWith(favorite: favorite, onWatchlist: watchlist);
  }

  final inception = entry(const TitleId.movie(27205), watchlist: true, added: 3);
  final breakingBad = entry(const TitleId.tv(1396), watchlist: true, added: 5);
  final freeSolo = entry(const TitleId.movie(515042), watchlist: true, added: 4);
  final godfather = entry(const TitleId.movie(238), watched: DateTime(2025), rating: Rating.loved);
  final matrix = entry(const TitleId.movie(603), watched: DateTime(2026), rating: Rating.disliked);
  final office = entry(const TitleId.tv(2316), watched: DateTime(2024), favorite: true);
  final all = [inception, breakingBad, freeSolo, godfather, matrix, office];

  List<String> names(LibraryQuery q, {bool Function(TitleId)? playable}) =>
      queryLibrary(all, q, isPlayable: playable).map((e) => e.snapshot.name).toList();

  test('the watchlist is newest first', () {
    expect(names(const LibraryQuery()), ['Breaking Bad', 'Free Solo', 'Inception']);
  });

  test('kind filters keep documentaries apart', () {
    expect(names(const LibraryQuery(kind: KindFilter.movies)), ['Inception']);
    expect(names(const LibraryQuery(kind: KindFilter.documentaries)), ['Free Solo']);
    expect(names(const LibraryQuery(kind: KindFilter.series)), ['Breaking Bad']);
  });

  test('watched sorts by rating with favorites on top', () {
    expect(names(const LibraryQuery(segment: LibrarySegment.watched, sort: LibrarySort.rating)), [
      'The Office',
      'The Godfather',
      'The Matrix',
    ]);
  });

  test('watched sorts by last watch, newest first', () {
    expect(names(const LibraryQuery(segment: LibrarySegment.watched, sort: LibrarySort.dateWatched)), [
      'The Matrix',
      'The Godfather',
      'The Office',
    ]);
  });

  test('genre and service filters', () {
    expect(names(const LibraryQuery(genre: 'Crime')), ['Breaking Bad']);
    expect(names(const LibraryQuery(onMyServicesOnly: true), playable: (id) => id == const TitleId.movie(27205)), [
      'Inception',
    ]);
  });

  test('genres are listed most common first', () {
    expect(libraryGenres([inception, freeSolo]).first, 'Adventure');
  });
}
