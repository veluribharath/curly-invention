import 'package:flutter_test/flutter_test.dart';
import 'package:reel/domain/entities/media_title.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/repositories/catalog_repository.dart';
import 'package:reel/domain/usecases/browse_titles.dart';
import 'package:reel/domain/usecases/query_library.dart';

/// Ten pages of movies and three of series; records the queries.
class _PagedCatalog implements CatalogRepository {
  final queries = <DiscoverQuery>[];

  @override
  Future<TitlePage> discover(DiscoverQuery query) async {
    queries.add(query);
    final last = query.type == MediaType.movie ? 10 : 3;
    if (query.page > last) return TitlePage(titles: const [], page: query.page);
    final base = query.page * 10;
    return TitlePage(
      titles: [
        for (var i = 0; i < 2; i++)
          MediaTitle(
            id: query.type == MediaType.movie ? TitleId.movie(base + i) : TitleId.tv(base + i),
            name: '${query.type.name} ${base + i}',
          ),
      ],
      page: query.page,
      hasMore: query.page < last,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test('alternates movies and series, page after page', () async {
    final catalog = _PagedCatalog();
    final pager = BrowsePager(catalog: catalog, kind: KindFilter.all);
    final first = await pager.next();
    expect([for (final t in first) t.name], ['movie 10', 'tv 10', 'movie 11', 'tv 11']);
    final second = await pager.next();
    expect(second.first.name, 'movie 20');
  });

  test('keeps going with movies after the series run out', () async {
    final pager = BrowsePager(catalog: _PagedCatalog(), kind: KindFilter.all);
    final names = <String>[];
    while (pager.hasMore) {
      names.addAll([for (final t in await pager.next()) t.name]);
    }
    expect(names.where((n) => n.startsWith('movie')), hasLength(20));
    expect(names.where((n) => n.startsWith('tv')), hasLength(6));
    expect(names.toSet(), hasLength(names.length));
  });

  test('skips titles already in the library, fetching on if a page is all skipped', () async {
    final pager = BrowsePager(catalog: _PagedCatalog(), kind: KindFilter.movies);
    final titles = await pager.next(skip: {const TitleId.movie(10), const TitleId.movie(11)});
    expect([for (final t in titles) t.name], ['movie 20', 'movie 21']);
  });

  test('asks for documentaries, or leaves them out', () async {
    final catalog = _PagedCatalog();
    await BrowsePager(catalog: catalog, kind: KindFilter.documentaries).next();
    expect(catalog.queries.map((q) => q.type).toSet(), MediaType.values.toSet());
    expect(catalog.queries.every((q) => q.genres.contains(MediaTitle.documentaryGenre)), isTrue);

    catalog.queries.clear();
    await BrowsePager(catalog: catalog, kind: KindFilter.series).next();
    expect(catalog.queries.single.type, MediaType.tv);
    expect(catalog.queries.single.withoutGenres, [MediaTitle.documentaryGenre]);
  });
}
