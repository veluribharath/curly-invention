import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/domain/entities/media_title.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/entities/person.dart';

/// Maps library entries to and from `users/{uid}/library/{type_tmdbId}`
/// documents and the JSON kept on the device. Both use the same fields;
/// Firestore stores dates as timestamps, JSON as ISO 8601 strings.
class LibraryEntryMapper {
  const LibraryEntryMapper._();

  static Map<String, dynamic> toFirestore(LibraryEntry entry) => _toMap(entry, Timestamp.fromDate);

  static LibraryEntry? fromFirestore(Map<String, dynamic> data) => _fromMap(data, _readTimestamp);

  static Map<String, dynamic> toJson(LibraryEntry entry) => _toMap(entry, (d) => d.toUtc().toIso8601String());

  static LibraryEntry? fromJson(Map<String, dynamic> data) => _fromMap(data, _readIso);

  static Map<String, dynamic> _toMap(LibraryEntry entry, Object Function(DateTime) date) {
    final t = entry.snapshot;
    return {
      'type': t.type.name,
      'tmdbId': t.id.tmdbId,
      'onWatchlist': entry.onWatchlist,
      'favorite': entry.favorite,
      'watches': [
        for (final watch in entry.watches)
          {
            'watchedAt': date(watch.watchedAt),
            if (watch.rating != null) 'rating': watch.rating!.name,
            if (watch.note != null && watch.note!.isNotEmpty) 'note': watch.note,
          },
      ],
      'addedAt': date(entry.addedAt),
      'updatedAt': date(entry.updatedAt),
      'title': t.name,
      if (t.year != null) 'year': t.year,
      'genres': t.genres,
      if (t.posterPath != null) 'posterPath': t.posterPath,
      if (t.backdropPath != null) 'backdropPath': t.backdropPath,
      if (t.runtimeMinutes != null) 'runtime': t.runtimeMinutes,
      if (t.seasonCount != null) 'seasonCount': t.seasonCount,
      if (t.voteAverage != null) 'voteAverage': t.voteAverage,
      if (t.originalLanguage != null) 'originalLanguage': t.originalLanguage,
      if (t.cast.isNotEmpty) 'cast': PeopleJson.toJson(t.cast),
      if (t.directors.isNotEmpty) 'directors': PeopleJson.toJson(t.directors),
    };
  }

  /// Null when the type or id is missing or unknown.
  static LibraryEntry? _fromMap(Map<String, dynamic> data, DateTime? Function(Object?) readDate) {
    final type = MediaType.parse(data['type']);
    final tmdbId = data['tmdbId'];
    if (type == null || tmdbId is! num) return null;

    final now = DateTime.now();
    final watches = <WatchEvent>[
      for (final raw in (data['watches'] is List ? data['watches'] as List : const []))
        if (raw is Map && readDate(raw['watchedAt']) != null)
          WatchEvent(
            watchedAt: readDate(raw['watchedAt'])!,
            rating: Rating.parse(raw['rating']),
            note: raw['note'] is String ? raw['note'] as String : null,
          ),
    ]..sort((a, b) => a.watchedAt.compareTo(b.watchedAt));

    final genres = data['genres'];
    return LibraryEntry(
      snapshot: MediaTitle(
        id: TitleId(type, tmdbId.toInt()),
        name: data['title'] is String ? data['title'] as String : 'Untitled',
        year: (data['year'] as num?)?.toInt(),
        genres: genres is List ? List.unmodifiable(genres.whereType<String>()) : const [],
        posterPath: data['posterPath'] as String?,
        backdropPath: data['backdropPath'] as String?,
        runtimeMinutes: (data['runtime'] as num?)?.toInt(),
        seasonCount: (data['seasonCount'] as num?)?.toInt(),
        voteAverage: (data['voteAverage'] as num?)?.toDouble(),
        originalLanguage: data['originalLanguage'] as String?,
        cast: PeopleJson.fromJson(data['cast']),
        directors: PeopleJson.fromJson(data['directors']),
      ),
      onWatchlist: data['onWatchlist'] == true,
      favorite: data['favorite'] == true,
      watches: List.unmodifiable(watches),
      addedAt: readDate(data['addedAt']) ?? now,
      updatedAt: readDate(data['updatedAt']) ?? now,
    );
  }

  static DateTime? _readTimestamp(Object? value) => switch (value) {
    Timestamp() => value.toDate(),
    DateTime() => value,
    _ => null,
  };

  static DateTime? _readIso(Object? value) => value is String ? DateTime.tryParse(value)?.toLocal() : null;
}
