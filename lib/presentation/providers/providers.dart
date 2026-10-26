import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:reel/core/config/app_config.dart';
import 'package:reel/data/repositories/availability_repositories.dart';
import 'package:reel/data/repositories/firestore_library_repository.dart';
import 'package:reel/data/repositories/local_library_repository.dart';
import 'package:reel/data/repositories/mock_catalog_repository.dart';
import 'package:reel/data/repositories/settings_repositories.dart';
import 'package:reel/data/repositories/tmdb_catalog_repository.dart';
import 'package:reel/data/services/auth_service.dart';
import 'package:reel/data/services/tmdb_client.dart';
import 'package:reel/domain/entities/library_entry.dart';
import 'package:reel/domain/entities/media_title.dart';
import 'package:reel/domain/entities/media_type.dart';
import 'package:reel/domain/entities/streaming.dart';
import 'package:reel/domain/entities/user_settings.dart';
import 'package:reel/domain/repositories/catalog_repository.dart';
import 'package:reel/domain/repositories/availability_repository.dart';
import 'package:reel/domain/repositories/library_repository.dart';
import 'package:reel/domain/repositories/settings_repository.dart';

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

// ---------------------------------------------------------------------------
// Settings and availability

/// The device's country, for settings before any are saved.
final deviceCountryProvider = Provider<String>((ref) {
  final code = PlatformDispatcher.instance.locale.countryCode;
  return code == null || code.length != 2 ? 'US' : code.toUpperCase();
});

/// Firestore for the signed-in account, the device otherwise. Null while
/// signing in.
final settingsRepositoryProvider = Provider<SettingsRepository?>((ref) {
  if (!ref.watch(firebaseEnabledProvider)) return LocalSettingsRepository();
  final uid = ref.watch(authUidProvider).value;
  return uid == null ? null : FirestoreSettingsRepository(uid: uid);
});

final settingsProvider = StreamProvider<UserSettings>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchSettings(fallback: UserSettings(country: ref.watch(deviceCountryProvider)));
});

final settingsActionsProvider = Provider<SettingsActions>((ref) => SettingsActions(ref));

class SettingsActions {
  final Ref _ref;

  SettingsActions(this._ref);

  UserSettings get _current =>
      _ref.read(settingsProvider).value ?? UserSettings(country: _ref.read(deviceCountryProvider));

  Future<void> _save(UserSettings settings) async {
    final repo = _ref.read(settingsRepositoryProvider);
    if (repo == null) throw StateError('Still signing in');
    await repo.save(settings);
  }

  /// Changing country keeps only the services it also has, which the
  /// caller passes in [keepServices]; otherwise services stay as they are.
  Future<void> setCountry(String country, {Set<int>? keepServices}) => _save(
    UserSettings(
      country: country,
      serviceIds: keepServices ?? _current.serviceIds,
      includeFreeWithAds: _current.includeFreeWithAds,
      onboardedAt: _current.onboardedAt,
    ),
  );

  Future<void> setServices(Set<int> serviceIds) => _save(_current.copyWith(serviceIds: serviceIds));

  Future<void> setIncludeFree(bool include) => _save(_current.copyWith(includeFreeWithAds: include));

  Future<void> finishOnboarding() => _save(_current.copyWith(onboardedAt: _ref.read(clockProvider)()));
}

final availabilityRepositoryProvider = Provider<AvailabilityRepository>((ref) {
  if (AppConfig.hasTmdbKey) {
    return TmdbAvailabilityRepository(TmdbClient(apiKey: AppConfig.tmdbApiKey));
  }
  return const MockAvailabilityRepository();
});

/// Where a title streams in your country. Kept for the session: TMDB
/// refreshes this data about daily.
final availabilityProvider = FutureProvider.family<Availability, TitleId>((ref, id) async {
  final country = await ref.watch(settingsProvider.selectAsync((s) => s.country));
  return ref.watch(availabilityRepositoryProvider).forTitle(id, country);
});

/// Offers you can start now on your services, best first; empty while
/// loading or when there are none.
final playableOffersProvider = Provider.family<List<Offer>, TitleId>((ref, id) {
  final settings = ref.watch(settingsProvider).value;
  final availability = ref.watch(availabilityProvider(id)).value;
  if (settings == null || availability == null) return const [];
  return availability.playableOn(settings.serviceIds, includeFree: settings.includeFreeWithAds);
});

/// Services available in your country, most popular first.
final countryServicesProvider = FutureProvider.family<List<StreamingService>, String>((ref, country) {
  return ref.watch(catalogRepositoryProvider).services(country);
});

final regionsProvider = FutureProvider<Map<String, String>>((ref) {
  return ref.watch(catalogRepositoryProvider).regions();
});

/// Availability of each watchlist title, fetched a few at a time, as it
/// arrives.
final watchlistAvailabilityProvider = StreamProvider<Map<TitleId, Availability>>((ref) async* {
  final ids = ref.watch(
    libraryProvider.select(
      (library) => [
        for (final entry in library.value?.values ?? const <LibraryEntry>[])
          if (entry.onWatchlist) entry.id,
      ]..sort(),
    ),
  );
  // Refetch when the country changes.
  ref.watch(settingsProvider.select((s) => s.value?.country));
  final results = <TitleId, Availability>{};
  if (ids.isEmpty) {
    yield const {};
    return;
  }
  const batchSize = 6;
  for (var i = 0; i < ids.length; i += batchSize) {
    final batch = ids.skip(i).take(batchSize);
    final fetched = await Future.wait([
      for (final id in batch)
        ref.read(availabilityProvider(id).future).then<Availability?>((a) => a).catchError((Object _) => null),
    ]);
    for (final availability in fetched) {
      if (availability != null) results[availability.id] = availability;
    }
    yield Map.unmodifiable(results);
  }
});
