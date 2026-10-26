import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:reel/core/config/app_config.dart';
import 'package:reel/data/repositories/firestore_library_repository.dart';
import 'package:reel/data/repositories/local_library_repository.dart';
import 'package:reel/data/repositories/mock_catalog_repository.dart';
import 'package:reel/data/repositories/tmdb_catalog_repository.dart';
import 'package:reel/data/services/auth_service.dart';
import 'package:reel/data/services/tmdb_client.dart';
import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/domain/entities/media_title.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/repositories/catalog_repository.dart';
import 'package:reel/domain/repositories/library_repository.dart';

/// Whether YouTube players can be created. Off in widget tests, where there
/// is no web view; screens show the video's thumbnail instead.
final videoEmbedsEnabledProvider = Provider<bool>((ref) => true);

/// The current time; overridden in tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// TMDB when a key is set, the built-in mock catalog otherwise.
final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  if (AppConfig.hasTmdbKey) {
    return TmdbCatalogRepository(TmdbClient(apiKey: AppConfig.tmdbApiKey));
  }
  return const MockCatalogRepository(latency: Duration(milliseconds: 300));
});

// ---------------------------------------------------------------------------
// Account

/// Whether Firebase came up at launch. Set in `main`; false when
/// `USE_FIREBASE` is off or initialization failed.
final firebaseEnabledProvider = Provider<bool>((ref) => false);

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// The Firebase user id, or null when Firebase is off. Loading while the
/// anonymous sign-in runs.
final authUidProvider = StreamProvider<String?>((ref) {
  if (!ref.watch(firebaseEnabledProvider)) return Stream.value(null);
  return ref.watch(authServiceProvider).uidChanges();
});

// ---------------------------------------------------------------------------
// Library

final localLibraryRepositoryProvider = Provider<LocalLibraryRepository>((ref) => LocalLibraryRepository());

/// Firestore for the signed-in account, the device otherwise. Null while
/// signing in.
final libraryRepositoryProvider = Provider<LibraryRepository?>((ref) {
  if (!ref.watch(firebaseEnabledProvider)) return ref.watch(localLibraryRepositoryProvider);
  final uid = ref.watch(authUidProvider).value;
  return uid == null ? null : FirestoreLibraryRepository(uid: uid);
});

final libraryProvider = StreamProvider<Map<TitleId, LibraryEntry>>((ref) {
  final repo = ref.watch(libraryRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchLibrary();
});

/// One title's entry, or null when it's not in the library.
final libraryEntryProvider = Provider.family<LibraryEntry?, TitleId>((ref, id) {
  return ref.watch(libraryProvider.select((library) => library.value?[id]));
});

final libraryActionsProvider = Provider<LibraryActions>((ref) => LibraryActions(ref));

/// Changes to the library. Each takes the title as shown, so its details are
/// saved with the entry.
class LibraryActions {
  final Ref _ref;

  LibraryActions(this._ref);

  DateTime get _now => _ref.read(clockProvider)();

  LibraryEntry _entryFor(MediaTitle title) {
    final existing = _ref.read(libraryProvider).value?[title.id];
    if (existing == null) return LibraryEntry.empty(title, now: _now);
    // Keep the richer copy of the details.
    return title.hasCredits || !existing.snapshot.hasCredits ? existing.withSnapshot(title, now: _now) : existing;
  }

  Future<void> _save(LibraryEntry entry) async {
    final repo = _ref.read(libraryRepositoryProvider);
    if (repo == null) throw StateError('Still signing in');
    await repo.save(entry);
  }

  Future<void> setWatchlist(MediaTitle title, bool onWatchlist) =>
      _save(_entryFor(title).copyWith(onWatchlist: onWatchlist, updatedAt: _now));

  Future<void> toggleWatchlist(MediaTitle title) =>
      setWatchlist(title, !(_ref.read(libraryProvider).value?[title.id]?.onWatchlist ?? false));

  /// Logs a watch; [favorite] sets the favorite flag too when given.
  Future<void> logWatch(MediaTitle title, WatchEvent watch, {bool? favorite}) {
    final entry = _entryFor(title).logWatch(watch, now: _now);
    return _save(favorite == null ? entry : entry.copyWith(favorite: favorite));
  }

  /// A watch today with no rating, for one-tap "Watched".
  Future<void> markWatched(MediaTitle title) => logWatch(title, WatchEvent(watchedAt: _now));

  Future<void> editWatch(MediaTitle title, int index, WatchEvent watch) =>
      _save(_entryFor(title).editWatch(index, watch, now: _now));

  Future<void> removeWatch(MediaTitle title, int index) => _save(_entryFor(title).removeWatch(index, now: _now));

  /// Favorites are watched titles; favoriting an unwatched one logs a watch.
  Future<void> setFavorite(MediaTitle title, bool favorite) {
    var entry = _entryFor(title);
    if (favorite && !entry.watched) entry = entry.logWatch(WatchEvent(watchedAt: _now), now: _now);
    return _save(entry.copyWith(favorite: favorite, updatedAt: _now));
  }

  Future<void> remove(TitleId id) async {
    final repo = _ref.read(libraryRepositoryProvider);
    if (repo == null) throw StateError('Still signing in');
    await repo.remove(id);
  }

  /// Puts back an entry removed a moment ago, for "Undo".
  Future<void> restore(LibraryEntry entry) => _save(entry);
}

// ---------------------------------------------------------------------------
// Catalog

final titleDetailsProvider = FutureProvider.autoDispose.family<MediaTitle, TitleId>((ref, id) {
  return ref.watch(catalogRepositoryProvider).details(id);
});

final similarTitlesProvider = FutureProvider.autoDispose.family<List<MediaTitle>, TitleId>((ref, id) {
  return ref.watch(catalogRepositoryProvider).similar(id);
});

final personTitlesProvider = FutureProvider.autoDispose.family<List<MediaTitle>, String>((ref, personId) {
  return ref.watch(catalogRepositoryProvider).byPerson(personId);
});

final trendingProvider = FutureProvider.autoDispose<List<MediaTitle>>((ref) async {
  return (await ref.watch(catalogRepositoryProvider).trending()).titles;
});

final searchResultsProvider = FutureProvider.autoDispose.family<List<MediaTitle>, String>((ref, query) async {
  if (query.trim().isEmpty) return const [];
  return (await ref.watch(catalogRepositoryProvider).search(query)).titles;
});
