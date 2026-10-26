/// Movies and TV series live in separate TMDB id spaces.
enum MediaType {
  movie,
  tv;

  static MediaType? parse(Object? value) {
    for (final type in values) {
      if (type.name == value) return type;
    }
    return null;
  }

  String get label => switch (this) {
    MediaType.movie => 'Movie',
    MediaType.tv => 'Series',
  };
}

/// Identifies a title across the movie and TV id spaces, e.g. `movie:693134`.
class TitleId implements Comparable<TitleId> {
  final MediaType type;
  final int tmdbId;

  const TitleId(this.type, this.tmdbId);

  const TitleId.movie(this.tmdbId) : type = MediaType.movie;
  const TitleId.tv(this.tmdbId) : type = MediaType.tv;

  /// `movie:693134`, used in routes and on-device storage.
  String encode() => '${type.name}:$tmdbId';

  /// `movie_693134`, used as a Firestore document id.
  String get docId => '${type.name}_$tmdbId';

  /// Parses [encode] or [docId] output; null when malformed.
  static TitleId? tryParse(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(RegExp('[:_]'));
    if (parts.length != 2) return null;
    final type = MediaType.parse(parts[0]);
    final id = int.tryParse(parts[1]);
    if (type == null || id == null || id <= 0) return null;
    return TitleId(type, id);
  }

  @override
  bool operator ==(Object other) => other is TitleId && other.type == type && other.tmdbId == tmdbId;

  @override
  int get hashCode => Object.hash(type, tmdbId);

  @override
  int compareTo(TitleId other) {
    final byType = type.index.compareTo(other.type.index);
    return byType != 0 ? byType : tmdbId.compareTo(other.tmdbId);
  }

  @override
  String toString() => encode();
}
