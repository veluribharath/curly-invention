import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:reel/data/repositories/feed_signal_repositories.dart';
import 'package:reel/domain/entities/feed_signal.dart';
import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/domain/entities/media_title.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/entities/user_settings.dart';
import 'package:reel/domain/repositories/catalog_repository.dart';
import 'package:reel/domain/repositories/feed_signal_repository.dart';
import 'package:reel/domain/usecases/discover_feed.dart';
import 'package:reel/presentation/providers/providers.dart';

// ---------------------------------------------------------------------------
// Feed signals

final feedSignalRepositoryProvider = Provider<FeedSignalRepository?>((ref) {
  if (!ref.watch(firebaseEnabledProvider)) return LocalFeedSignalRepository();
  final uid = ref.watch(authUidProvider).value;
  return uid == null ? null : FirestoreFeedSignalRepository(uid: uid);
});

/// Signals from the last 90 days plus this session's, oldest first.
class FeedSignals extends Notifier<List<FeedSignal>> {
  @override
  List<FeedSignal> build() {
    final repo = ref.watch(feedSignalRepositoryProvider);
    if (repo != null) unawaited(_load(repo));
    return const [];
  }

  Future<void> _load(FeedSignalRepository repo) async {
    try {
      final loaded = await repo.since(ref.read(clockProvider)().subtract(signalLifetime));
      if (ref.mounted) state = [...loaded, ...state];
    } catch (_) {
      // Signals only tune the feed; carry on without the old ones.
    }
  }

  Future<void> record(TitleId id, FeedSignalType type) async {
    final signal = FeedSignal(id: id, type: type, at: ref.read(clockProvider)());
    state = [...state, signal];
    try {
      await ref.read(feedSignalRepositoryProvider)?.record(signal);
    } catch (_) {
      // Kept for this session at least.
    }
  }
}

final feedSignalsProvider = NotifierProvider<FeedSignals, List<FeedSignal>>(FeedSignals.new);

// ---------------------------------------------------------------------------
// Feed

/// The kind chips and "My services" toggle on Discover.
class DiscoverFilter extends Notifier<FeedFilter> {
  @override
  FeedFilter build() => const FeedFilter();

  void set(FeedFilter filter) => state = filter;
}

final discoverFilterProvider = NotifierProvider<DiscoverFilter, FeedFilter>(DiscoverFilter.new);

/// Sound on Discover; off until you turn it on, then on for the session.
class ReelMuted extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool muted) => state = muted;
}

final reelMutedProvider = NotifierProvider<ReelMuted, bool>(ReelMuted.new);

/// What a feed is built from, read when it starts.
class FeedInputs {
  final CatalogRepository catalog;
  final FeedFilter filter;
  final UserSettings settings;
  final Map<TitleId, LibraryEntry> library;
  final List<FeedSignal> signals;

  /// Availability of watchlist titles, by id.
  final bool Function(TitleId id) isPlayable;
  final DateTime now;

  const FeedInputs({
    required this.catalog,
    required this.filter,
    required this.settings,
    required this.library,
    required this.signals,
    required this.isPlayable,
    required this.now,
  });
}

/// The candidate sources and scorer for a feed. Replaced as personalization
/// grows; see [defaultFeedSources].
typedef FeedBuilder = ({List<CandidateSource> sources, FeedScorer score}) Function(FeedInputs inputs);

final feedBuilderProvider = Provider<FeedBuilder>((ref) => defaultFeedSources);

/// Watchlist titles you can play now, popular on your services, and fresh
/// releases.
({List<CandidateSource> sources, FeedScorer score}) defaultFeedSources(FeedInputs inputs) {
  final filter = inputs.filter;
  final settings = inputs.settings;
  final watchlist = [
    for (final entry in inputs.library.values)
      if (entry.onWatchlist &&
          filter.kind.matches(entry.snapshot.type, isDocumentary: entry.snapshot.isDocumentary) &&
          (!filter.myServicesOnly || inputs.isPlayable(entry.id)))
        FeedCandidate(entry.snapshot, FeedSource.watchlist, 'On your watchlist'),
  ]..shuffle();
  return (
    sources: [
      ListCandidateSource(watchlist),
      DiscoverCandidateSource(
        inputs.catalog,
        source: FeedSource.popular,
        reason: (_) => filter.myServicesOnly ? 'Popular on your services' : 'Popular right now',
        queries: feedQueries(filter, settings, minVotes: 100),
      ),
      DiscoverCandidateSource(
        inputs.catalog,
        source: FeedSource.fresh,
        reason: (_) => 'New this season',
        queries: feedQueries(
          filter,
          settings,
          sort: DiscoverSort.newest,
          releasedAfter: inputs.now.subtract(const Duration(days: 90)),
          minVotes: 10,
        ),
        maxPages: 3,
      ),
    ],
    score: baseScore,
  );
}

/// Titles Discover leaves out: watched ones, "not for me", and ones you
/// skipped quickly in the last week.
bool Function(MediaTitle title) feedExclusions(FeedInputs inputs) {
  final weekAgo = inputs.now.subtract(const Duration(days: 7));
  final hidden = <TitleId>{
    for (final s in inputs.signals)
      if (s.type == FeedSignalType.notInterested || (s.type == FeedSignalType.skippedFast && s.at.isAfter(weekAgo)))
        s.id,
  };
  return (title) => hidden.contains(title.id) || (inputs.library[title.id]?.watched ?? false);
}

class DiscoverState {
  final List<FeedCard> cards;
  final bool loading;
  final Object? error;
  final bool exhausted;

  /// The filter is on but no services are picked, so there's nothing to show.
  final bool needsServices;

  const DiscoverState({
    this.cards = const [],
    this.loading = false,
    this.error,
    this.exhausted = false,
    this.needsServices = false,
  });

  DiscoverState copyWith({List<FeedCard>? cards, bool? loading, Object? Function()? error, bool? exhausted}) {
    return DiscoverState(
      cards: cards ?? this.cards,
      loading: loading ?? this.loading,
      error: error == null ? this.error : error(),
      exhausted: exhausted ?? this.exhausted,
      needsServices: needsServices,
    );
  }
}

/// The Discover feed. Starts over when the filter, country or services
/// change; library changes only affect cards not yet dealt.
class DiscoverFeed extends Notifier<DiscoverState> {
  FeedPager? _pager;
  int _generation = 0;
  bool _busy = false;

  @override
  DiscoverState build() {
    final filter = ref.watch(discoverFilterProvider);
    final settings = ref.watch(settingsProvider.select((s) => s.value));
    // Listened, not watched: these keep the providers running (Riverpod
    // pauses unlistened ones) without restarting the feed on every change.
    ref.listen(libraryProvider, (_, _) {});
    ref.listen(watchlistAvailabilityProvider, (_, _) {});
    ref.listen(feedSignalsProvider, (_, _) {});
    _pager = null;
    _busy = false;
    _generation++;
    if (settings == null) return const DiscoverState(loading: true);
    if (filter.myServicesOnly && settings.serviceIds.isEmpty && !settings.includeFreeWithAds) {
      return const DiscoverState(needsServices: true, exhausted: true);
    }
    final generation = _generation;
    // Start once the library and watchlist availability are in, so the
    // first page can include watchlist titles and skip watched ones.
    unawaited(_start(filter, settings, generation));
    return const DiscoverState(loading: true);
  }

  Future<void> _start(FeedFilter filter, UserSettings settings, int generation) async {
    try {
      final library = await ref.read(libraryProvider.future);
      if (filter.myServicesOnly) {
        await ref
            .read(watchlistAvailabilityProvider.future)
            .timeout(const Duration(seconds: 4), onTimeout: () => const {});
      }
      if (generation != _generation || !ref.mounted) return;
      final availability = ref.read(watchlistAvailabilityProvider).value ?? const {};
      final inputs = FeedInputs(
        catalog: ref.read(catalogRepositoryProvider),
        filter: filter,
        settings: settings,
        library: library,
        signals: ref.read(feedSignalsProvider),
        isPlayable: (id) =>
            availability[id]?.isPlayableOn(settings.serviceIds, includeFree: settings.includeFreeWithAds) ?? false,
        now: ref.read(clockProvider)(),
      );
      final built = ref.read(feedBuilderProvider)(inputs);
      final exclusions = feedExclusions(inputs);
      _pager = FeedPager(
        sources: built.sources,
        score: built.score,
        // Read live, so titles watched or dismissed since the feed started
        // aren't dealt later.
        isExcluded: (title) => exclusions(title) || _excludedNow(title.id),
      );
      await loadMore();
    } catch (e) {
      if (generation == _generation && ref.mounted) state = DiscoverState(error: e);
    }
  }

  bool _excludedNow(TitleId id) {
    if (ref.read(libraryProvider).value?[id]?.watched ?? false) return true;
    return ref.read(feedSignalsProvider).any((s) => s.id == id && s.type == FeedSignalType.notInterested);
  }

  /// Adds the next page of cards. Does nothing while loading or at the end.
  Future<void> loadMore() async {
    final pager = _pager;
    if (pager == null || _busy || state.exhausted) return;
    final generation = _generation;
    _busy = true;
    state = state.copyWith(loading: true, error: () => null);
    try {
      final cards = await pager.loadMore();
      if (generation != _generation || !ref.mounted) return;
      state = state.copyWith(cards: [...state.cards, ...cards], loading: false, exhausted: pager.exhausted);
    } catch (e) {
      if (generation != _generation || !ref.mounted) return;
      state = state.copyWith(loading: false, error: () => e);
    } finally {
      if (generation == _generation) _busy = false;
    }
  }

  /// Starts the feed over, e.g. on pull to refresh.
  void refresh() => ref.invalidateSelf();

  /// Takes a card out of the feed, e.g. after "Not for me".
  void dismiss(TitleId id) {
    state = state.copyWith(
      cards: [
        for (final c in state.cards)
          if (c.id != id) c,
      ],
    );
  }
}

final discoverFeedProvider = NotifierProvider<DiscoverFeed, DiscoverState>(DiscoverFeed.new);
