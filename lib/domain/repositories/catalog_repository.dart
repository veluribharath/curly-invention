import 'package:reel/domain/entities/media_title.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/entities/streaming.dart';

enum DiscoverSort { popular, topRated, newest }

/// A filtered list of movies or series, as TMDB's discover endpoints take it.
class DiscoverQuery {
  final MediaType type;
  final int page;

  /// Titles in any of these genres.
  final List<String> genres;

  /// Titles in none of these genres.
  final List<String> withoutGenres;
  final DiscoverSort sort;

  /// Limits to titles on any of [providerIds] in [region] with one of
  /// [monetization]. Ignored without a region.
  final String? region;
  final Set<int> providerIds;
  final Set<OfferType> monetization;

  /// TMDB person ids; titles with any of them.
  final List<String> people;

  /// Released on or after this date.
  final DateTime? releasedAfter;

  /// Skips titles with fewer votes, so obscure titles with a few perfect
  /// votes don't come first.
  final int minVotes;

  const DiscoverQuery({
    required this.type,
    this.page = 1,
    this.genres = const [],
    this.withoutGenres = const [],
    this.sort = DiscoverSort.popular,
    this.region,
    this.providerIds = const {},
    this.monetization = const {OfferType.subscription},
    this.people = const [],
    this.releasedAfter,
    this.minVotes = 0,
  });

  DiscoverQuery copyWith({int? page}) => DiscoverQuery(
    type: type,
    page: page ?? this.page,
    genres: genres,
    withoutGenres: withoutGenres,
    sort: sort,
    region: region,
    providerIds: providerIds,
    monetization: monetization,
    people: people,
    releasedAfter: releasedAfter,
    minVotes: minVotes,
  );
}

/// Titles, people and services from the catalog (TMDB, or mock data).
abstract class CatalogRepository {
  /// Movies and series matching [query], most relevant first.
  Future<TitlePage> search(String query, {int page = 1});

  /// Full details, with credits and videos.
  Future<MediaTitle> details(TitleId id);

  Future<TitlePage> discover(DiscoverQuery query);

  /// Trending movies and series this week.
  Future<TitlePage> trending({int page = 1});

  /// Titles TMDB recommends for people who liked [id].
  Future<List<MediaTitle>> similar(TitleId id);

  /// Titles a person acted in, directed or created, most popular first.
  Future<List<MediaTitle>> byPerson(String personId);

  /// Services with watch provider data in [country], most popular first.
  Future<List<StreamingService>> services(String country);

  /// Countries with watch provider data, as ISO code to English name.
  Future<Map<String, String>> regions();
}
