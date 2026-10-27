import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:reel/domain/entities/media_title.dart';
import 'package:reel/domain/usecases/browse_titles.dart';
import 'package:reel/domain/usecases/query_library.dart';
import 'package:reel/presentation/providers/providers.dart';

class BrowseState {
  final KindFilter kind;
  final List<MediaTitle> titles;
  final bool loading;
  final bool hasMore;
  final Object? error;

  const BrowseState({
    this.kind = KindFilter.all,
    this.titles = const [],
    this.loading = false,
    this.hasMore = true,
    this.error,
  });

  BrowseState copyWith({List<MediaTitle>? titles, bool? loading, bool? hasMore, Object? Function()? error}) =>
      BrowseState(
        kind: kind,
        titles: titles ?? this.titles,
        loading: loading ?? this.loading,
        hasMore: hasMore ?? this.hasMore,
        error: error == null ? this.error : error(),
      );
}

/// The endless list on Rate titles: well-known titles not in your library
/// when they're fetched, page by page. Titles you rate stay in place.
class BrowseFeed extends Notifier<BrowseState> {
  BrowsePager? _pager;

  @override
  BrowseState build() {
    ref.watch(catalogRepositoryProvider);
    _pager = null;
    return const BrowseState();
  }

  void setKind(KindFilter kind) {
    if (kind == state.kind) return;
    _pager = null;
    state = BrowseState(kind: kind);
    unawaited(loadMore());
  }

  /// Fetches the next titles unless a fetch is running or there are no more.
  Future<void> loadMore() async {
    if (state.loading || !state.hasMore) return;
    final pager = _pager ??= BrowsePager(catalog: ref.read(catalogRepositoryProvider), kind: state.kind);
    state = state.copyWith(loading: true, error: () => null);
    final skip = {...?ref.read(libraryProvider).value?.keys};
    try {
      final more = await pager.next(skip: skip);
      if (!ref.mounted || !identical(pager, _pager)) return;
      state = state.copyWith(titles: [...state.titles, ...more], loading: false, hasMore: pager.hasMore);
    } catch (e) {
      if (!ref.mounted || !identical(pager, _pager)) return;
      state = state.copyWith(loading: false, error: () => e);
    }
  }
}

final browseFeedProvider = NotifierProvider.autoDispose<BrowseFeed, BrowseState>(BrowseFeed.new);
