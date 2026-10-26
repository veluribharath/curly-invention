import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/domain/entities/media_title.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/entities/user_settings.dart';
import 'package:reel/domain/repositories/catalog_repository.dart';
import 'package:reel/domain/usecases/analyze_taste.dart';
import 'package:reel/domain/usecases/discover_feed.dart';

/// Candidates from a source that can't filter by service itself (TMDB's
/// recommendations), checked one by one.
class CheckedCandidateSource implements CandidateSource {
  final CandidateSource _inner;
  final Future<bool> Function(MediaTitle title) _keep;

  CheckedCandidateSource(this._inner, this._keep);

  @override
  bool get exhausted => _inner.exhausted;

  @override
  Future<List<FeedCandidate>> next() async {
    final batch = await _inner.next();
    final kept = await Future.wait([for (final c in batch) _keep(c.title).catchError((Object _) => false)]);
    return [
      for (var i = 0; i < batch.length; i++)
        if (kept[i]) batch[i],
    ];
  }
}

/// Recommendations for each anchor title, an anchor per batch.
class SimilarCandidateSource implements CandidateSource {
  final CatalogRepository _catalog;
  final List<MediaTitle> _anchors;
  final String Function(MediaTitle anchor) reason;
  final int perAnchor;

  SimilarCandidateSource(this._catalog, List<MediaTitle> anchors, {required this.reason, this.perAnchor = 8})
    : _anchors = [...anchors];

  @override
  bool get exhausted => _anchors.isEmpty;

  @override
  Future<List<FeedCandidate>> next() async {
    final anchor = _anchors.removeAt(0);
    final similar = await _catalog.similar(anchor.id);
    return [
      for (final title in similar.take(perAnchor)) FeedCandidate(title, FeedSource.becauseYouLiked, reason(anchor)),
    ];
  }
}

/// Takes at most [perBatch] from each batch of [_inner], so a source like
/// the wildcard stays about one card in eight.
class ThrottledCandidateSource implements CandidateSource {
  final CandidateSource _inner;
  final int perBatch;
  final List<FeedCandidate> _buffer = [];

  ThrottledCandidateSource(this._inner, {this.perBatch = 1});

  @override
  bool get exhausted => _buffer.isEmpty && _inner.exhausted;

  @override
  Future<List<FeedCandidate>> next() async {
    if (_buffer.length < perBatch && !_inner.exhausted) _buffer.addAll(await _inner.next());
    final take = _buffer.take(perBatch).toList();
    _buffer.removeRange(0, take.length);
    return take;
  }
}

/// All six sources from docs/05-recommendations.md, falling back to popular
/// on your services while there's no taste to go on.
({List<CandidateSource> sources, FeedScorer score}) personalizedFeed({
  required CatalogRepository catalog,
  required FeedFilter filter,
  required UserSettings settings,
  required Iterable<LibraryEntry> library,
  required TasteProfile taste,
  required bool Function(TitleId id) isWatchlistPlayable,
  required Future<bool> Function(MediaTitle title) isPlayableNow,
  required DateTime now,
}) {
  final genres = topGenres(taste);
  final people = topPeople(taste);
  final anchors = likedAnchors(library);

  final watchlist = [
    for (final entry in library)
      if (entry.onWatchlist &&
          filter.kind.matches(entry.snapshot.type, isDocumentary: entry.snapshot.isDocumentary) &&
          (!filter.myServicesOnly || isWatchlistPlayable(entry.id)))
        FeedCandidate(entry.snapshot, FeedSource.watchlist, 'On your watchlist'),
  ]..shuffle();

  bool kindMatches(MediaTitle t) => filter.kind.matches(t.type, isDocumentary: t.isDocumentary);

  final sources = <CandidateSource>[
    ListCandidateSource(watchlist),
    if (anchors.isNotEmpty)
      CheckedCandidateSource(
        SimilarCandidateSource(catalog, anchors, reason: (a) => 'Because you loved ${a.name}'),
        (t) async => kindMatches(t) && (!filter.myServicesOnly || await isPlayableNow(t)),
      ),
    for (final person in people)
      DiscoverCandidateSource(
        catalog,
        source: FeedSource.people,
        reason: (_) => person.role == PersonRole.director ? 'From ${person.person.name}' : 'With ${person.person.name}',
        queries: feedQueries(filter, settings, people: [person.person.id]),
        maxPages: 2,
      ),
    if (genres.isNotEmpty)
      DiscoverCandidateSource(
        catalog,
        source: FeedSource.genre,
        reason: (t) {
          final matched = t.genres.where(genres.contains).toList();
          return 'Because you like ${(matched.isEmpty ? genres : matched).take(2).join(' & ')}';
        },
        queries: feedQueries(filter, settings, genres: genres, minVotes: 200),
      )
    else
      DiscoverCandidateSource(
        catalog,
        source: FeedSource.popular,
        reason: (t) => _reasonFor(t, taste, filter.myServicesOnly ? 'Popular on your services' : 'Popular right now'),
        queries: feedQueries(filter, settings, minVotes: 100),
      ),
    DiscoverCandidateSource(
      catalog,
      source: FeedSource.fresh,
      reason: (t) => taste.hasTaste ? _reasonFor(t, taste, 'New this season') : 'New this season',
      queries: feedQueries(
        filter,
        settings,
        sort: DiscoverSort.newest,
        releasedAfter: now.subtract(const Duration(days: 90)),
        minVotes: 10,
      ),
      maxPages: 3,
    ),
    if (genres.isNotEmpty)
      ThrottledCandidateSource(
        DiscoverCandidateSource(
          catalog,
          source: FeedSource.wildcard,
          reason: (_) => 'Something different',
          queries: feedQueries(filter, settings, sort: DiscoverSort.topRated, withoutGenres: genres, minVotes: 500),
          maxPages: 5,
        ),
      ),
  ];

  double score(FeedCandidate candidate) {
    final fit = tasteFit(candidate.title, taste);
    // The wildcard is meant to sit outside your taste; don't punish it.
    final fitScore = candidate.source == FeedSource.wildcard ? 0.0 : fit.score;
    return baseScore(candidate) + fitScore + _runtimeFit(candidate.title, taste) + _freshness(candidate.title, now);
  }

  return (sources: sources, score: score);
}

/// [fallback], or what matched your taste when there's a clear match.
String _reasonFor(MediaTitle title, TasteProfile taste, String fallback) {
  final fit = tasteFit(title, taste);
  if (fit.person != null) return 'With ${fit.person}';
  if (fit.genres.isNotEmpty) return 'Because you like ${fit.genres.take(2).join(' & ')}';
  return fallback;
}

double _runtimeFit(MediaTitle title, TasteProfile taste) {
  final band = taste.likedRuntime;
  final runtime = title.runtimeMinutes;
  if (band == null || runtime == null || title.type != MediaType.movie) return 0;
  return runtime >= band.$1 - 15 && runtime <= band.$2 + 15 ? 0.05 : -0.05;
}

/// A small lift for titles out in the last year.
double _freshness(MediaTitle title, DateTime now) {
  final released = title.releaseDate;
  if (released == null) return 0;
  final days = now.difference(released).inDays;
  return days >= 0 && days < 365 ? 0.1 * (1 - days / 365) : 0;
}
