import 'package:flutter_test/flutter_test.dart';
import 'package:reel/data/repositories/mock_catalog_repository.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/repositories/catalog_repository.dart';

void main() {
  const repo = MockCatalogRepository();

  test('every mock title has offers and a unique id', () {
    final ids = MockCatalog.titles.map((t) => t.id).toSet();
    expect(ids, hasLength(MockCatalog.titles.length));
    expect(MockCatalog.offers.keys.toSet(), ids);
  });

  test('discover limits to the services asked for', () async {
    final page = await repo.discover(const DiscoverQuery(type: MediaType.tv, region: 'US', providerIds: {8}));
    expect(page.titles.map((t) => t.name), containsAll(['Breaking Bad', 'Stranger Things']));
    expect(page.titles.every((t) => t.type == MediaType.tv), isTrue);
  });

  test('documentaries can be left out', () async {
    final page = await repo.discover(const DiscoverQuery(type: MediaType.movie, withoutGenres: ['Documentary']));
    expect(page.titles.any((t) => t.isDocumentary), isFalse);
  });

  test('search matches titles and people', () async {
    expect((await repo.search('nolan')).titles.map((t) => t.name), containsAll(['Inception', 'Interstellar']));
  });
}
