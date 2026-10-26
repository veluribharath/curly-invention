import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/entities/person.dart';
import 'package:reel/domain/entities/video.dart';

/// A movie or series. Named `MediaTitle` because Flutter already has a
/// `Title` widget.
///
/// List endpoints fill only the basics; [CatalogRepository.details] adds
/// runtime, seasons, credits and videos.
class MediaTitle {
  static const documentaryGenre = 'Documentary';

  final TitleId id;
  final String name;
  final int? year;
  final List<String> genres;

  /// TMDB image paths, e.g. "/abc.jpg"; see `TmdbImages` for URLs.
  final String? posterPath;
  final String? backdropPath;
  final String overview;

  /// Movie length, or the typical episode length for a series.
  final int? runtimeMinutes;

  /// Series only.
  final int? seasonCount;
  final double? voteAverage;
  final int? voteCount;
  final double? popularity;
  final DateTime? releaseDate;
  final String? originalLanguage;

  /// Top-billed cast, in billing order.
  final List<Person> cast;

  /// Directors for a movie, creators for a series.
  final List<Person> directors;
  final List<Video> videos;

  const MediaTitle({
    required this.id,
    required this.name,
    this.year,
    this.genres = const [],
    this.posterPath,
    this.backdropPath,
    this.overview = '',
    this.runtimeMinutes,
    this.seasonCount,
    this.voteAverage,
    this.voteCount,
    this.popularity,
    this.releaseDate,
    this.originalLanguage,
    this.cast = const [],
    this.directors = const [],
    this.videos = const [],
  });

  MediaType get type => id.type;

  bool get isDocumentary => genres.contains(documentaryGenre);

  bool get hasCredits => cast.isNotEmpty || directors.isNotEmpty;

  /// "Movie", "Series" or "Documentary".
  String get kindLabel => isDocumentary ? 'Documentary' : type.label;

  MediaTitle copyWith({
    String? name,
    int? year,
    List<String>? genres,
    String? posterPath,
    String? backdropPath,
    String? overview,
    int? runtimeMinutes,
    int? seasonCount,
    double? voteAverage,
    int? voteCount,
    double? popularity,
    DateTime? releaseDate,
    String? originalLanguage,
    List<Person>? cast,
    List<Person>? directors,
    List<Video>? videos,
  }) {
    return MediaTitle(
      id: id,
      name: name ?? this.name,
      year: year ?? this.year,
      genres: genres ?? this.genres,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      overview: overview ?? this.overview,
      runtimeMinutes: runtimeMinutes ?? this.runtimeMinutes,
      seasonCount: seasonCount ?? this.seasonCount,
      voteAverage: voteAverage ?? this.voteAverage,
      voteCount: voteCount ?? this.voteCount,
      popularity: popularity ?? this.popularity,
      releaseDate: releaseDate ?? this.releaseDate,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      cast: cast ?? this.cast,
      directors: directors ?? this.directors,
      videos: videos ?? this.videos,
    );
  }

  @override
  String toString() => 'MediaTitle($id, $name)';
}

/// One page of a list or search.
class TitlePage {
  final List<MediaTitle> titles;
  final int page;
  final bool hasMore;

  const TitlePage({required this.titles, this.page = 1, this.hasMore = false});

  static const empty = TitlePage(titles: []);
}
