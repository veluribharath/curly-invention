import 'package:reel/domain/entities/media_title.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/repositories/catalog_repository.dart';
import 'package:reel/domain/usecases/query_library.dart';

/// Well-known titles of one kind, page after page, for rating and adding to
/// the library. Movies and series alternate; documentaries are left out of
/// both unless [kind] asks for them.
class BrowsePager {
  final CatalogRepository catalog;
  final KindFilter kind;

  /// Skips obscure titles, which people are unlikely to have seen.
  final int minVotes;

  final _nextPage = <MediaType, int>{};
  final _done = <MediaType>{};
  final _dealt = <TitleId>{};

  BrowsePager({required this.catalog, required this.kind, this.minVotes = 100});

  List<MediaType> get _types => switch (kind) {
    KindFilter.movies => const [MediaType.movie],
    KindFilter.series => const [MediaType.tv],
    KindFilter.all || KindFilter.documentaries => MediaType.values,
  };

  bool get hasMore => _types.any((t) => !_done.contains(t));

  DiscoverQuery _query(MediaType type, int page) => DiscoverQuery(
    type: type,
    page: page,
    genres: kind == KindFilter.documentaries ? const [MediaTitle.documentaryGenre] : const [],
    withoutGenres: kind == KindFilter.movies || kind == KindFilter.series
        ? const [MediaTitle.documentaryGenre]
        : const [],
    minVotes: minVotes,
  );

  /// The next titles, none dealt before and none in [skip]. Fetches more
  /// pages while a page brings nothing new, up to a few at a time.
  Future<List<MediaTitle>> next({Set<TitleId> skip = const {}}) async {
    for (var attempt = 0; attempt < 5 && hasMore; attempt++) {
      final types = [
        for (final t in _types)
          if (!_done.contains(t)) t,
      ];
      final pages = await Future.wait([for (final t in types) catalog.discover(_query(t, _nextPage[t] ?? 1))]);
      final lists = <List<MediaTitle>>[];
      for (var i = 0; i < types.length; i++) {
        final page = pages[i];
        _nextPage[types[i]] = (_nextPage[types[i]] ?? 1) + 1;
        if (!page.hasMore || page.titles.isEmpty) _done.add(types[i]);
        lists.add(page.titles);
      }
      final fresh = <MediaTitle>[];
      for (var i = 0; lists.any((l) => i < l.length); i++) {
        for (final list in lists) {
          if (i < list.length && !skip.contains(list[i].id) && _dealt.add(list[i].id)) fresh.add(list[i]);
        }
      }
      if (fresh.isNotEmpty) return fresh;
    }
    return const [];
  }
}
