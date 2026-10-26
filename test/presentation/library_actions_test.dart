import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel/data/repositories/mock_catalog_repository.dart';
import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/presentation/providers/providers.dart';

import '../support/fakes.dart';

void main() {
  final inception = MockCatalog.byId(const TitleId.movie(27205))!;

  test('watchlist, watched and favorite flow', () async {
    final repo = MemoryLibraryRepository();
    final container = ProviderContainer(overrides: testOverrides(library: repo));
    addTearDown(container.dispose);
    container.listen(libraryProvider, (_, _) {});
    await container.read(libraryProvider.future);
    final actions = container.read(libraryActionsProvider);

    await actions.toggleWatchlist(inception);
    await pumpEventQueue();
    expect(repo.entries[inception.id]!.onWatchlist, isTrue);

    await actions.setFavorite(inception, true);
    await pumpEventQueue();
    final entry = repo.entries[inception.id]!;
    expect(entry.favorite, isTrue);
    expect(entry.watched, isTrue, reason: 'favoriting logs a watch');
    expect(entry.onWatchlist, isFalse);

    await actions.remove(inception.id);
    expect(repo.entries, isEmpty);
  });

  test('editing a watch and its favorite flag is one save', () async {
    final repo = _CountingLibraryRepository();
    final container = ProviderContainer(overrides: testOverrides(library: repo));
    addTearDown(container.dispose);
    container.listen(libraryProvider, (_, _) {});
    await container.read(libraryProvider.future);
    await pumpEventQueue();
    final actions = container.read(libraryActionsProvider);

    await actions.markWatched(inception);
    await pumpEventQueue();
    repo.saves = 0;
    await actions.editWatch(inception, 0, WatchEvent(watchedAt: fixedNow, rating: Rating.loved), favorite: true);
    expect(repo.saves, 1);
    final entry = repo.entries[inception.id]!;
    expect(entry.favorite, isTrue);
    expect(entry.latestRating, Rating.loved);
  });
}

class _CountingLibraryRepository extends MemoryLibraryRepository {
  int saves = 0;

  @override
  Future<void> save(LibraryEntry entry) {
    saves++;
    return super.save(entry);
  }
}
