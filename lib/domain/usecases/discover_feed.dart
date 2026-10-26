import 'dart:math' as math;

import 'package:reel/domain/entities/media_title.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/entities/streaming.dart';
import 'package:reel/domain/entities/user_settings.dart';
import 'package:reel/domain/repositories/catalog_repository.dart';
import 'package:reel/domain/usecases/query_library.dart';

/// Where a Discover card came from, strongest first. The order is also the
/// ranking boost: a watchlist title beats a genre pick of equal fit.
enum FeedSource { watchlist, becauseYouLiked, people, genre, fresh, popular, wildcard }

/// A title one of the sources suggested, before ranking.
class FeedCandidate {
  final MediaTitle title;
  final FeedSource source;

  /// One line on why, e.g. "On your watchlist".
  final String reason;

  const FeedCandidate(this.title, this.source, this.reason);
}

/// A ranked card in the feed.
class FeedCard {
  final MediaTitle title;
  final FeedSource source;
  final String reason;
  final double score;

  const FeedCard({required this.title, required this.source, required this.reason, required this.score});

  TitleId get id => title.id;
}

/// What the feed shows: the kind chips and the "My services" toggle.
class FeedFilter {
  final KindFilter kind;
  final bool myServicesOnly;

  const FeedFilter({this.kind = KindFilter.all, this.myServicesOnly = true});

  FeedFilter copyWith({KindFilter? kind, bool? myServicesOnly}) =>
      FeedFilter(kind: kind ?? this.kind, myServicesOnly: myServicesOnly ?? this.myServicesOnly);

  @override
  bool operator ==(Object other) => other is FeedFilter && other.kind == kind && other.myServicesOnly == myServicesOnly;

  @override
  int get hashCode => Object.hash(kind, myServicesOnly);
}

/// Something that hands out candidates a batch at a time.
abstract class CandidateSource {
  bool get exhausted;

  Future<List<FeedCandidate>> next();
}

/// A fixed list, handed out a few at a time so it doesn't crowd a page.
class ListCandidateSource implements CandidateSource {
  final List<FeedCandidate> _items;
  final int perBatch;
  int _offset = 0;

  ListCandidateSource(List<FeedCandidate> items, {this.perBatch = 2}) : _items = items;

  @override
  bool get exhausted => _offset >= _items.length;

  @override
  Future<List<FeedCandidate>> next() async {
    final batch = _items.skip(_offset).take(perBatch).toList();
    _offset += batch.length;
    return batch;
  }
}

/// Pages through one or more discover queries, one page of each per batch.
class DiscoverCandidateSource implements CandidateSource {
  final CatalogRepository _catalog;
  final FeedSource source;
  final String Function(MediaTitle title) reason;
  final List<DiscoverQuery> _queries;

  /// Stop after this many pages per query; deep pages are rarely good.
  final int maxPages;

  DiscoverCandidateSource(
    this._catalog, {
    required List<DiscoverQuery> queries,
    required this.source,
    required this.reason,
    this.maxPages = 10,
  }) : _queries = [...queries];

  @override
  bool get exhausted => _queries.isEmpty;

  @override
  Future<List<FeedCandidate>> next() async {
    final pages = await Future.wait([for (final q in _queries) _catalog.discover(q)]);
    final candidates = <FeedCandidate>[];
    final remaining = <DiscoverQuery>[];
    for (var i = 0; i < pages.length; i++) {
      final query = _queries[i];
      final page = pages[i];
      candidates.addAll([for (final t in page.titles) FeedCandidate(t, source, reason(t))]);
      if (page.hasMore && query.page < maxPages) remaining.add(query.copyWith(page: query.page + 1));
    }
    _queries
      ..clear()
      ..addAll(remaining);
    return _interleave(candidates);
  }

  // Alternate movies and series so neither floods a batch.
  static List<FeedCandidate> _interleave(List<FeedCandidate> candidates) {
    final movies = [
      for (final c in candidates)
        if (c.title.type == MediaType.movie) c,
    ];
    final shows = [
      for (final c in candidates)
        if (c.title.type == MediaType.tv) c,
    ];
    return [
      for (var i = 0; i < math.max(movies.length, shows.length); i++) ...[
        if (i < movies.length) movies[i],
        if (i < shows.length) shows[i],
      ],
    ];
  }
}

/// Discover queries for [filter]: one per media type it covers, limited to
/// your services when the toggle is on.
List<DiscoverQuery> feedQueries(
  FeedFilter filter,
  UserSettings settings, {
  DiscoverSort sort = DiscoverSort.popular,
  List<String> genres = const [],
  List<String> withoutGenres = const [],
  List<String> people = const [],
  DateTime? releasedAfter,
  int minVotes = 0,
}) {
  final docs = filter.kind == KindFilter.documentaries;
  final types = switch (filter.kind) {
    KindFilter.movies => [MediaType.movie],
    KindFilter.series => [MediaType.tv],
    _ => MediaType.values,
  };
  final monetization = {
    OfferType.subscription,
    if (settings.includeFreeWithAds) ...[OfferType.free, OfferType.ads],
  };
  return [
    for (final type in types)
      // TMDB's TV discover has no people filter.
      if (people.isEmpty || type == MediaType.movie)
        DiscoverQuery(
          type: type,
          sort: sort,
          genres: docs ? const [MediaTitle.documentaryGenre] : genres,
          withoutGenres: [
            ...withoutGenres,
            if (filter.kind == KindFilter.movies || filter.kind == KindFilter.series) MediaTitle.documentaryGenre,
          ],
          people: people,
          releasedAfter: releasedAfter,
          minVotes: minVotes,
          region: filter.myServicesOnly ? settings.country : null,
          providerIds: filter.myServicesOnly ? settings.serviceIds : const {},
          monetization: monetization,
        ),
  ];
}

/// How a candidate scores before the diversity pass. Higher is better.
typedef FeedScorer = double Function(FeedCandidate candidate);

/// Rank by source, then by quality: a vote average damped by how many votes
/// it rests on.
double baseScore(FeedCandidate candidate) {
  final title = candidate.title;
  final sourceBoost = (FeedSource.values.length - candidate.source.index) * 0.15;
  return sourceBoost + qualityScore(title);
}

/// 0 to 1: the vote average out of 10, pulled toward 0.6 when few voted.
double qualityScore(MediaTitle title) {
  final average = (title.voteAverage ?? 0) / 10;
  final votes = (title.voteCount ?? 0).toDouble();
  final weight = votes / (votes + 200);
  return average * weight + 0.6 * (1 - weight);
}

/// Pages the Discover feed: pulls a batch from every source, drops what's
/// excluded or already dealt, ranks, and spreads out genres and types.
class FeedPager {
  final List<CandidateSource> sources;
  final bool Function(MediaTitle title) isExcluded;
  final FeedScorer score;

  /// Fetch more batches while a load has fewer new cards than this, so a
  /// run of excluded titles doesn't stall the feed.
  final int minPerLoad;
  final int maxBatchesPerLoad;

  final Set<TitleId> _dealt = {};

  FeedPager({
    required this.sources,
    required this.isExcluded,
    this.score = baseScore,
    this.minPerLoad = 8,
    this.maxBatchesPerLoad = 4,
  });

  bool get exhausted => sources.every((s) => s.exhausted);

  Future<List<FeedCard>> loadMore() async {
    final cards = <TitleId, FeedCard>{};
    for (var batch = 0; batch < maxBatchesPerLoad && cards.length < minPerLoad && !exhausted; batch++) {
      final results = await Future.wait([
        for (final source in sources)
          if (!source.exhausted) source.next(),
      ]);
      for (final candidate in results.expand((r) => r)) {
        final id = candidate.title.id;
        if (_dealt.contains(id) || isExcluded(candidate.title)) continue;
        final card = FeedCard(
          title: candidate.title,
          source: candidate.source,
          reason: candidate.reason,
          score: score(candidate),
        );
        // The same title from two sources keeps its stronger reason.
        final seen = cards[id];
        if (seen == null || card.score > seen.score) cards[id] = card;
      }
    }
    _dealt.addAll(cards.keys);
    final ranked = cards.values.toList()..sort((a, b) => b.score.compareTo(a.score));
    return diversify(ranked);
  }
}

/// Reorders [ranked] (best first) so that no more than [maxRun] cards in a
/// row share a primary genre or a media type, and no two in a row share a
/// franchise. Takes the best card that fits at each step; when none fits,
/// the best one left.
List<FeedCard> diversify(List<FeedCard> ranked, {int maxRun = 2}) {
  final remaining = [...ranked];
  final result = <FeedCard>[];

  bool fits(FeedCard card) {
    if (result.isEmpty) return true;
    final last = result.last;
    if (franchiseKey(last.title) == franchiseKey(card.title)) return false;
    final recent = result.reversed.take(maxRun).toList();
    if (recent.length < maxRun) return true;
    final genre = card.title.genres.firstOrNull;
    final sameGenre = genre != null && recent.every((c) => c.title.genres.firstOrNull == genre);
    final sameType = recent.every((c) => c.title.type == card.title.type);
    return !sameGenre && !sameType;
  }

  while (remaining.isNotEmpty) {
    final index = remaining.indexWhere(fits);
    result.add(remaining.removeAt(index < 0 ? 0 : index));
  }
  return result;
}

/// A rough franchise key: the name before a colon or a sequel number, so
/// "John Wick: Chapter 4" and "John Wick" match.
String franchiseKey(MediaTitle title) {
  final name = title.name.toLowerCase();
  final colon = name.indexOf(':');
  final base = colon > 0 ? name.substring(0, colon) : name;
  return base.replaceAll(RegExp(r'\s+(\d+|ii|iii|iv|part \w+)$'), '').trim();
}
