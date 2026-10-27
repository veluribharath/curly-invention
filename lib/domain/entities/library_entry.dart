import 'package:reel/domain/entities/media_title.dart';
import 'package:reel/domain/entities/media_type.dart';

/// How a watched title landed. Favorite is a separate flag on the entry.
enum Rating {
  disliked,
  liked,
  loved;

  static Rating? parse(Object? value) {
    for (final rating in values) {
      if (rating.name == value) return rating;
    }
    return null;
  }

  String get label => switch (this) {
    Rating.disliked => "Didn't like it",
    Rating.liked => 'Liked it',
    Rating.loved => 'Loved it',
  };
}

/// One viewing. A title watched twice has two.
class WatchEvent {
  final DateTime watchedAt;
  final Rating? rating;
  final String? note;

  /// False for "seen it at some point", e.g. a swipe in setup: [watchedAt]
  /// is then when it was logged, not when it was watched.
  final bool dateKnown;

  const WatchEvent({required this.watchedAt, this.rating, this.note, this.dateKnown = true});

  @override
  bool operator ==(Object other) =>
      other is WatchEvent &&
      other.watchedAt == watchedAt &&
      other.rating == rating &&
      other.note == note &&
      other.dateKnown == dateKnown;

  @override
  int get hashCode => Object.hash(watchedAt, rating, note, dateKnown);
}

/// A title in your library: on the watchlist, watched, or both.
///
/// [snapshot] keeps the title's details from when it was saved, as
/// resonance's `SwipeRecord` does, so the library and taste analysis work
/// without fetching from TMDB again.
class LibraryEntry {
  final MediaTitle snapshot;
  final bool onWatchlist;
  final bool favorite;

  /// Oldest first. Empty when not watched.
  final List<WatchEvent> watches;
  final DateTime addedAt;
  final DateTime updatedAt;

  const LibraryEntry({
    required this.snapshot,
    this.onWatchlist = false,
    this.favorite = false,
    this.watches = const [],
    required this.addedAt,
    required this.updatedAt,
  });

  TitleId get id => snapshot.id;

  bool get watched => watches.isNotEmpty;

  /// The rating of the most recent watch that has one.
  Rating? get latestRating {
    for (final watch in watches.reversed) {
      if (watch.rating != null) return watch.rating;
    }
    return null;
  }

  DateTime? get lastWatchedAt => watches.isEmpty ? null : watches.last.watchedAt;

  /// An entry that holds nothing any more and can be deleted.
  bool get isEmpty => !onWatchlist && !favorite && watches.isEmpty;

  /// A new entry for [title], with nothing set yet.
  factory LibraryEntry.empty(MediaTitle title, {required DateTime now}) =>
      LibraryEntry(snapshot: title, addedAt: now, updatedAt: now);

  LibraryEntry copyWith({
    MediaTitle? snapshot,
    bool? onWatchlist,
    bool? favorite,
    List<WatchEvent>? watches,
    DateTime? addedAt,
    DateTime? updatedAt,
  }) {
    return LibraryEntry(
      snapshot: snapshot ?? this.snapshot,
      onWatchlist: onWatchlist ?? this.onWatchlist,
      favorite: favorite ?? this.favorite,
      watches: watches ?? this.watches,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Logs a watch, kept in date order, and takes the title off the watchlist.
  LibraryEntry logWatch(WatchEvent watch, {required DateTime now}) {
    final watches = [...this.watches, watch]..sort((a, b) => a.watchedAt.compareTo(b.watchedAt));
    return copyWith(watches: List.unmodifiable(watches), onWatchlist: false, updatedAt: now);
  }

  /// Replaces the watch at [index] (in [watches] order).
  LibraryEntry editWatch(int index, WatchEvent watch, {required DateTime now}) {
    final watches = [...this.watches]..[index] = watch;
    watches.sort((a, b) => a.watchedAt.compareTo(b.watchedAt));
    return copyWith(watches: List.unmodifiable(watches), updatedAt: now);
  }

  /// Removes the watch at [index]. Removing the last one also clears the
  /// favorite, which only means something on a watched title.
  LibraryEntry removeWatch(int index, {required DateTime now}) {
    final watches = [...this.watches]..removeAt(index);
    return copyWith(watches: List.unmodifiable(watches), favorite: watches.isEmpty ? false : favorite, updatedAt: now);
  }

  /// Refreshes the saved details, keeping credits the new copy lacks: list
  /// endpoints don't return them.
  LibraryEntry withSnapshot(MediaTitle title, {required DateTime now}) {
    final merged = title.copyWith(
      cast: title.cast.isEmpty ? snapshot.cast : null,
      directors: title.directors.isEmpty ? snapshot.directors : null,
      runtimeMinutes: title.runtimeMinutes ?? snapshot.runtimeMinutes,
      seasonCount: title.seasonCount ?? snapshot.seasonCount,
      videos: const [],
    );
    return copyWith(snapshot: merged, updatedAt: now);
  }
}
