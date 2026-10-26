import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/domain/entities/media_type.dart';

enum LibrarySegment {
  watchlist,
  watched,
  favorites;

  String get label => switch (this) {
    LibrarySegment.watchlist => 'Watchlist',
    LibrarySegment.watched => 'Watched',
    LibrarySegment.favorites => 'Favorites',
  };
}

/// Movies, series or documentaries. Documentaries are left out of the other
/// two, as on Discover.
enum KindFilter {
  all,
  movies,
  series,
  documentaries;

  String get label => switch (this) {
    KindFilter.all => 'All',
    KindFilter.movies => 'Movies',
    KindFilter.series => 'Series',
    KindFilter.documentaries => 'Docs',
  };

  bool matches(MediaType type, {required bool isDocumentary}) => switch (this) {
    KindFilter.all => true,
    KindFilter.movies => type == MediaType.movie && !isDocumentary,
    KindFilter.series => type == MediaType.tv && !isDocumentary,
    KindFilter.documentaries => isDocumentary,
  };
}

enum LibrarySort {
  dateAdded,
  dateWatched,
  rating,
  title,
  releaseYear;

  String get label => switch (this) {
    LibrarySort.dateAdded => 'Date added',
    LibrarySort.dateWatched => 'Date watched',
    LibrarySort.rating => 'Rating',
    LibrarySort.title => 'Title',
    LibrarySort.releaseYear => 'Release year',
  };
}

class LibraryQuery {
  final LibrarySegment segment;
  final KindFilter kind;

  /// Only titles in this genre; null for any.
  final String? genre;
  final LibrarySort sort;

  /// Only titles that stream on your services right now.
  final bool onMyServicesOnly;

  const LibraryQuery({
    this.segment = LibrarySegment.watchlist,
    this.kind = KindFilter.all,
    this.genre,
    this.sort = LibrarySort.dateAdded,
    this.onMyServicesOnly = false,
  });

  LibraryQuery copyWith({
    LibrarySegment? segment,
    KindFilter? kind,
    String? Function()? genre,
    LibrarySort? sort,
    bool? onMyServicesOnly,
  }) {
    return LibraryQuery(
      segment: segment ?? this.segment,
      kind: kind ?? this.kind,
      genre: genre == null ? this.genre : genre(),
      sort: sort ?? this.sort,
      onMyServicesOnly: onMyServicesOnly ?? this.onMyServicesOnly,
    );
  }
}

bool inSegment(LibraryEntry entry, LibrarySegment segment) => switch (segment) {
  LibrarySegment.watchlist => entry.onWatchlist,
  LibrarySegment.watched => entry.watched,
  LibrarySegment.favorites => entry.favorite,
};

/// The entries [query] selects, sorted. Newest first for dates, best first
/// for ratings, A to Z for titles; ties go by title.
///
/// [isPlayable] says whether a title streams on your services now; it's
/// only asked when [LibraryQuery.onMyServicesOnly] is set.
List<LibraryEntry> queryLibrary(
  Iterable<LibraryEntry> entries,
  LibraryQuery query, {
  bool Function(TitleId id)? isPlayable,
}) {
  final results = entries.where((entry) {
    final title = entry.snapshot;
    if (!inSegment(entry, query.segment)) return false;
    if (!query.kind.matches(title.type, isDocumentary: title.isDocumentary)) return false;
    if (query.genre != null && !title.genres.contains(query.genre)) return false;
    if (query.onMyServicesOnly && isPlayable != null && !isPlayable(entry.id)) return false;
    return true;
  }).toList();

  int byTitle(LibraryEntry a, LibraryEntry b) => a.snapshot.name.toLowerCase().compareTo(b.snapshot.name.toLowerCase());
  int newestFirst(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }

  results.sort((a, b) {
    final primary = switch (query.sort) {
      LibrarySort.dateAdded => b.addedAt.compareTo(a.addedAt),
      LibrarySort.dateWatched => newestFirst(a.lastWatchedAt, b.lastWatchedAt),
      LibrarySort.rating => _ratingRank(b).compareTo(_ratingRank(a)),
      LibrarySort.title => 0,
      LibrarySort.releaseYear => (b.snapshot.year ?? 0).compareTo(a.snapshot.year ?? 0),
    };
    return primary != 0 ? primary : byTitle(a, b);
  });
  return results;
}

/// Favorites rank above loved, then liked, unrated, disliked.
int _ratingRank(LibraryEntry entry) {
  if (entry.favorite) return 4;
  return switch (entry.latestRating) {
    Rating.loved => 3,
    Rating.liked => 2,
    null => 1,
    Rating.disliked => 0,
  };
}

/// Genres present in [entries], most common first.
List<String> libraryGenres(Iterable<LibraryEntry> entries) {
  final counts = <String, int>{};
  for (final entry in entries) {
    for (final genre in entry.snapshot.genres) {
      counts[genre] = (counts[genre] ?? 0) + 1;
    }
  }
  return counts.keys.toList()..sort((a, b) {
    final byCount = counts[b]!.compareTo(counts[a]!);
    return byCount != 0 ? byCount : a.compareTo(b);
  });
}
