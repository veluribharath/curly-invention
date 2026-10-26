enum VideoKind { trailer, teaser, clip, featurette, other }

/// A video TMDB lists for a title. Only YouTube videos can be played.
class Video {
  final String key;
  final String site;
  final VideoKind kind;
  final bool official;

  /// ISO 639-1, e.g. "en".
  final String language;
  final String name;

  /// Length in seconds, when known. TMDB doesn't say; see `pickClip`.
  final int? durationSeconds;

  const Video({
    required this.key,
    this.site = 'YouTube',
    required this.kind,
    this.official = true,
    this.language = 'en',
    this.name = '',
    this.durationSeconds,
  });

  bool get isYouTube => site.toLowerCase() == 'youtube';

  static VideoKind parseKind(Object? type) => switch ('$type'.toLowerCase()) {
    'trailer' => VideoKind.trailer,
    'teaser' => VideoKind.teaser,
    'clip' => VideoKind.clip,
    'featurette' => VideoKind.featurette,
    _ => VideoKind.other,
  };
}
