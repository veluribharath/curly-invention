import 'package:reel/domain/entities/media_title.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/entities/person.dart';
import 'package:reel/domain/entities/streaming.dart';
import 'package:reel/domain/entities/video.dart';

/// Genre names used across the app, and their TMDB ids per media type.
///
/// Movie genre names are the vocabulary. TV's compound genres ("Action &
/// Adventure", "Sci-Fi & Fantasy", "War & Politics") are split into the
/// movie names so taste carries across movies and series.
class TmdbGenres {
  const TmdbGenres._();

  static const Map<int, List<String>> _movie = {
    28: ['Action'],
    12: ['Adventure'],
    16: ['Animation'],
    35: ['Comedy'],
    80: ['Crime'],
    99: ['Documentary'],
    18: ['Drama'],
    10751: ['Family'],
    14: ['Fantasy'],
    36: ['History'],
    27: ['Horror'],
    10402: ['Music'],
    9648: ['Mystery'],
    10749: ['Romance'],
    878: ['Science Fiction'],
    10770: ['TV Movie'],
    53: ['Thriller'],
    10752: ['War'],
    37: ['Western'],
  };

  static const Map<int, List<String>> _tv = {
    10759: ['Action', 'Adventure'],
    16: ['Animation'],
    35: ['Comedy'],
    80: ['Crime'],
    99: ['Documentary'],
    18: ['Drama'],
    10751: ['Family'],
    10762: ['Kids'],
    9648: ['Mystery'],
    10763: ['News'],
    10764: ['Reality'],
    10765: ['Science Fiction', 'Fantasy'],
    10766: ['Soap'],
    10767: ['Talk'],
    10768: ['War', 'Politics'],
    37: ['Western'],
  };

  /// Genres shown as filters, in display order.
  static const List<String> common = [
    'Action',
    'Adventure',
    'Animation',
    'Comedy',
    'Crime',
    'Documentary',
    'Drama',
    'Family',
    'Fantasy',
    'History',
    'Horror',
    'Music',
    'Mystery',
    'Romance',
    'Science Fiction',
    'Thriller',
    'War',
    'Western',
  ];

  static Map<int, List<String>> _table(MediaType type) => type == MediaType.movie ? _movie : _tv;

  /// Genre names for TMDB ids, each once, unknown ids skipped.
  static List<String> names(MediaType type, Iterable<Object?> ids) {
    final table = _table(type);
    final names = <String>{};
    for (final id in ids) {
      if (id is num) names.addAll(table[id.toInt()] ?? const []);
    }
    return List.unmodifiable(names);
  }

  /// TMDB ids for genre names; names with no id for [type] are skipped.
  static List<int> ids(MediaType type, Iterable<String> names) {
    final wanted = names.toSet();
    return [
      for (final entry in _table(type).entries)
        if (entry.value.any(wanted.contains)) entry.key,
    ];
  }
}

/// Maps TMDB JSON to domain entities.
class TmdbMapper {
  const TmdbMapper._();

  static const maxCast = 8;
  static const maxDirectors = 3;

  /// A title from a list, search or details response. [type] is required
  /// unless the JSON carries `media_type`; returns null for people and
  /// entries without an id.
  static MediaTitle? title(Map<String, dynamic> json, {MediaType? type}) {
    final resolved = type ?? MediaType.parse(json['media_type']);
    final id = json['id'];
    if (resolved == null || id is! num) return null;

    final dateText = (json['release_date'] ?? json['first_air_date'])?.toString() ?? '';
    final date = DateTime.tryParse(dateText);
    final genreIds = json['genre_ids'] is List
        ? json['genre_ids'] as List
        : [
            for (final g in (json['genres'] as List? ?? const []))
              if (g is Map) g['id'],
          ];

    final runtime = switch (resolved) {
      MediaType.movie => (json['runtime'] as num?)?.toInt(),
      MediaType.tv => _episodeRuntime(json),
    };

    final videosJson = json['videos'];
    return MediaTitle(
      id: TitleId(resolved, id.toInt()),
      name: (json['title'] ?? json['name'] ?? 'Untitled').toString(),
      year: date?.year,
      genres: TmdbGenres.names(resolved, genreIds),
      posterPath: _path(json['poster_path']),
      backdropPath: _path(json['backdrop_path']),
      overview: json['overview']?.toString() ?? '',
      runtimeMinutes: runtime != null && runtime > 0 ? runtime : null,
      seasonCount: (json['number_of_seasons'] as num?)?.toInt(),
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      voteCount: (json['vote_count'] as num?)?.toInt(),
      popularity: (json['popularity'] as num?)?.toDouble(),
      releaseDate: date,
      originalLanguage: json['original_language']?.toString(),
      cast: _cast(json),
      directors: _directors(json, resolved),
      videos: videosJson is Map ? videos(videosJson['results']) : const [],
    );
  }

  static List<MediaTitle> titles(Object? results, {MediaType? type}) => [
    for (final raw in (results is List ? results : const []))
      if (raw is Map<String, dynamic>) ?title(raw, type: type),
  ];

  static TitlePage page(Map<String, dynamic> json, {MediaType? type, int maxPage = 500}) {
    final page = (json['page'] as num?)?.toInt() ?? 1;
    final totalPages = (json['total_pages'] as num?)?.toInt() ?? page;
    return TitlePage(
      titles: titles(json['results'], type: type),
      page: page,
      hasMore: page < totalPages && page < maxPage,
    );
  }

  /// YouTube videos only, in TMDB's order.
  static List<Video> videos(Object? results) => [
    for (final raw in (results is List ? results : const []))
      if (raw is Map && raw['key'] is String && '${raw['site']}'.toLowerCase() == 'youtube')
        Video(
          key: raw['key'] as String,
          kind: Video.parseKind(raw['type']),
          official: raw['official'] == true,
          language: raw['iso_639_1']?.toString() ?? '',
          name: raw['name']?.toString() ?? '',
        ),
  ];

  static List<StreamingService> services(Object? results, {String? country}) {
    final services = <StreamingService>[
      for (final raw in (results is List ? results : const []))
        if (raw is Map && raw['provider_id'] is num) service(raw, country: country),
    ];
    services.sort((a, b) => a.displayPriority.compareTo(b.displayPriority));
    return services;
  }

  static StreamingService service(Map raw, {String? country}) {
    final priorities = raw['display_priorities'];
    final priority = country != null && priorities is Map && priorities[country] is num
        ? (priorities[country] as num).toInt()
        : (raw['display_priority'] as num?)?.toInt() ?? 999;
    return StreamingService(
      providerId: (raw['provider_id'] as num).toInt(),
      name: raw['provider_name']?.toString() ?? 'Unknown',
      logoPath: _path(raw['logo_path']),
      displayPriority: priority,
    );
  }

  /// Offers from a `watch/providers` response for one country.
  static Availability availability(
    TitleId id,
    String country,
    Map<String, dynamic>? json, {
    required DateTime fetchedAt,
  }) {
    final results = json?['results'];
    final forCountry = results is Map ? results[country] : null;
    if (forCountry is! Map) {
      return Availability(id: id, country: country, offers: const [], fetchedAt: fetchedAt);
    }
    final offers = <Offer>[];
    const keys = {
      'flatrate': OfferType.subscription,
      'free': OfferType.free,
      'ads': OfferType.ads,
      'rent': OfferType.rent,
      'buy': OfferType.buy,
    };
    for (final entry in keys.entries) {
      for (final service in services(forCountry[entry.key])) {
        offers.add(Offer(service: service, type: entry.value));
      }
    }
    final link = forCountry['link'];
    return Availability(
      id: id,
      country: country,
      offers: offers,
      link: link is String ? Uri.tryParse(link) : null,
      fetchedAt: fetchedAt,
    );
  }

  static String? _path(Object? value) => value is String && value.isNotEmpty ? value : null;

  static int? _episodeRuntime(Map<String, dynamic> json) {
    final runtimes = json['episode_run_time'];
    if (runtimes is List && runtimes.isNotEmpty && runtimes.first is num) {
      return (runtimes.first as num).toInt();
    }
    final last = json['last_episode_to_air'];
    if (last is Map && last['runtime'] is num) return (last['runtime'] as num).toInt();
    return null;
  }

  static List<Person> _cast(Map<String, dynamic> json) {
    final credits = json['aggregate_credits'] ?? json['credits'];
    if (credits is! Map) return const [];
    final cast = [
      for (final raw in (credits['cast'] as List? ?? const []))
        if (raw is Map<String, dynamic>) raw,
    ]..sort((a, b) => ((a['order'] as num?) ?? 999).compareTo((b['order'] as num?) ?? 999));
    return _people(cast).take(maxCast).toList();
  }

  static List<Person> _directors(Map<String, dynamic> json, MediaType type) {
    if (type == MediaType.tv && json['created_by'] is List) {
      final creators = [
        for (final raw in json['created_by'] as List)
          if (raw is Map<String, dynamic>) raw,
      ];
      if (creators.isNotEmpty) return _people(creators).take(maxDirectors).toList();
    }
    final credits = json['credits'];
    if (credits is! Map) return const [];
    final directors = [
      for (final raw in (credits['crew'] as List? ?? const []))
        if (raw is Map<String, dynamic> && raw['job'] == 'Director') raw,
    ];
    return _people(directors).take(maxDirectors).toList();
  }

  // Each person once, skipping entries without an id or name.
  static Iterable<Person> _people(Iterable<Map<String, dynamic>> raw) sync* {
    final seen = <String>{};
    for (final entry in raw) {
      final id = entry['id'];
      final name = entry['name'];
      if (id is! num || name is! String || name.isEmpty) continue;
      if (seen.add('$id')) yield Person(id: '$id', name: name);
    }
  }
}
