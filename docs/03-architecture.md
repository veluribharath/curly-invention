# 03. Architecture

## Stack

| Concern | Choice | Notes |
|---|---|---|
| Framework | Flutter (current stable, Dart 3.7+) | One codebase for iOS and Android. CI pins the version, as resonance does (3.47.7 today). |
| State | `flutter_riverpod` | Same as resonance. |
| Routing | `go_router` with `StatefulShellRoute` | Same package as resonance; shell route gives per-tab stacks. |
| HTTP | `http` | Same as resonance's `TMDBService`. |
| Images | `cached_network_image` | Same. |
| Video | `youtube_player_iframe` | Already used in resonance's details screen. See [04-data-sources.md](04-data-sources.md). |
| Swipe deck (onboarding) | `swipable_stack` | Reused from resonance. |
| Charts | `fl_chart` | Reused from resonance. |
| Auth | Firebase Auth: anonymous, then Apple and Google | Apple sign-in is mandatory on iOS once Google sign-in is offered. |
| Data | Cloud Firestore with offline persistence | Works offline, syncs across devices. Same patterns as resonance's `FirestoreService`. |
| Backend | Cloud Functions (Node 22) | Proxy and cache for the paid availability API, if we use one; keeps keys off the device. |
| Local prefs | `shared_preferences` | Filter state, mute preference. |
| Config | `--dart-define` + `AppConfig` | Same as resonance: no keys in source. |
| Crash/analytics | Firebase Crashlytics + Analytics | New. Needed for the success measures. |

Why Firestore and not a local database first: resonance already has working
Firestore sync, offline persistence gives us a local cache for free, and
anonymous auth means no sign-in wall. A user who never signs in still has their
data on the device; signing in links the anonymous account so nothing is lost.

## Layers

Same Clean Architecture split as resonance:

```
lib/
├── core/            config, theme, constants
├── domain/          pure Dart: entities, repository interfaces, use cases
├── data/            TMDB service, availability service, Firestore, mappers
└── presentation/    screens, widgets, Riverpod providers
```

Domain stays free of Flutter imports, as in resonance's CLAUDE.md.

## Domain model

```dart
enum MediaType { movie, tv }

/// Identifies a title across movie and TV ID spaces, e.g. "movie:693134".
class TitleId { final MediaType type; final int tmdbId; }

class Title {
  final TitleId id;
  final String name;
  final int? year;
  final List<String> genres;       // "Documentary" makes it a doc
  final String? posterUrl;
  final String? backdropUrl;
  final int? runtimeMinutes;       // movies; average episode length for TV
  final int? seasonCount;          // TV only
  final double? voteAverage;
  final List<Person> cast;         // from resonance's Person
  final List<Person> directors;    // creators for TV
  bool get isDocumentary => genres.contains('Documentary');
}

enum Rating { disliked, liked, loved }

class WatchEvent { final DateTime watchedAt; final Rating? rating; final String? note; }

class LibraryEntry {
  final TitleId id;
  final bool onWatchlist;
  final bool favorite;
  final List<WatchEvent> watches;  // empty = not watched; >1 = rewatches
  final DateTime addedAt;
  final DateTime updatedAt;
  final Title snapshot;            // details at save time, like resonance's SwipeRecord
  bool get watched => watches.isNotEmpty;
  Rating? get latestRating => ...;
}

class StreamingService { final int providerId; final String name; final String logoUrl; }

enum OfferType { subscription, free, ads, rent, buy }

class Offer {
  final StreamingService service;
  final OfferType type;
  final Uri? deepLink;             // null when the source doesn't provide one
  final DateTime? leavingAt;       // only from paid sources
}

class Availability { final TitleId id; final String country; final List<Offer> offers; final DateTime fetchedAt; }

class UserSettings {
  final String country;                 // ISO 3166-1, e.g. "US"
  final Set<int> serviceIds;            // TMDB provider IDs
  final bool includeFreeWithAds;
}

/// Something that happened on a reel, used as an implicit taste signal.
class FeedSignal { final TitleId id; final FeedSignalType type; final DateTime at; }
enum FeedSignalType { notInterested, skippedFast, watchedClip, unmuted, openedDetails, openedService }
```

`LibraryEntry.snapshot` follows resonance's lesson from `SwipeRecord`: store the
title details with the entry so the library and taste analysis work without
re-fetching from TMDB.

## Repository interfaces

```dart
abstract class CatalogRepository {           // TMDB
  Future<List<Title>> search(String query, {int page = 1});
  Future<Title> details(TitleId id);          // with credits, videos
  Future<List<Video>> videos(TitleId id);
  Future<TitlePage> discover(DiscoverQuery q);
  Future<List<Title>> similar(TitleId id);
  Future<List<Title>> byPerson(String personId);
  Future<List<StreamingService>> services(String country);
}

abstract class AvailabilityRepository {      // TMDB watch providers first, swappable
  Future<Availability> forTitle(TitleId id, String country);
}

abstract class LibraryRepository {           // Firestore
  Stream<Map<TitleId, LibraryEntry>> watchLibrary();
  Future<void> save(LibraryEntry entry);
  Future<void> remove(TitleId id);
}

abstract class SettingsRepository { ... }
abstract class FeedSignalRepository { ... }
```

`AvailabilityRepository` is the seam that lets us start on free TMDB data and
move to a paid source with deep links without touching the UI.

## Firestore layout

```
users/{uid}
  country, serviceIds[], includeFreeWithAds, createdAt, onboardedAt
users/{uid}/library/{type_tmdbId}            e.g. "movie_693134"
  type, tmdbId, onWatchlist, favorite, watches[{watchedAt, rating, note}],
  addedAt, updatedAt, title, year, genres[], posterPath, backdropPath,
  runtime, seasonCount, cast[{id,name}], directors[{id,name}]
users/{uid}/signals/{autoId}
  type, tmdbId, signal, at                    (TTL policy: 90 days)
availabilityCache/{country}_{type}_{tmdbId}   (written by Functions only)
  offers[], fetchedAt
```

Security rules: a user reads and writes only `users/{uid}/**`;
`availabilityCache` is read-only to clients. Resonance's `firestore.rules` and
`firestore-tests/` setup can be adapted with all the friend rules removed.

## Providers (Riverpod)

- `settingsProvider`: country and services, streamed from Firestore.
- `libraryProvider`: `StreamProvider` of library entries; derived
  `watchlistProvider`, `watchedProvider`, `favoritesProvider`.
- `tasteProfileProvider`: from library entries plus signals (adapted
  `analyzeTaste`).
- `availabilityProvider.family(TitleId)`: cached per session.
- `discoverFeedProvider`: `StateNotifier` that pages candidates, like
  resonance's `swipeDeckProvider` / `DeckPager`.
- `activeClipProvider`: which card owns the single live video player.

## Reuse map from resonance

| resonance file | Use in Reel |
|---|---|
| `data/services/tmdb_service.dart` | Base for `TmdbService`; add TV, `/search/multi`, `/discover/tv`, watch providers, videos. Keep the v3/v4 key detection and timeout handling. |
| `domain/entities/person.dart` | As is. |
| `domain/entities/movie.dart`, `swipe_record.dart` | Become `Title` and `LibraryEntry` (adds media type, backdrop, runtime, watch events). |
| `data/models/swipe_record_mapper.dart` | Pattern for `LibraryEntryMapper`. |
| `domain/usecases/analyze_taste.dart` | Adapt to library entries (ratings + favorites instead of swipes). |
| `domain/usecases/recommend_movies.dart` | Keep genre and people affinity scoring, drop the `FriendLikes` term. |
| `domain/usecases/deck_pager.dart` | Pattern for the Discover feed pager. |
| `domain/usecases/build_movie_share.dart` | As is. |
| `presentation/screens/movie_details_screen.dart` | Base for title details; move its inline TMDB call into the repository. |
| `presentation/screens/home_screen.dart`, `widgets/movie_card.dart` | Onboarding taste seed. |
| `presentation/widgets/taste_charts.dart` | You tab stats. |
| `data/services/auth_service.dart` | Keep anonymous, Google; add Apple; drop email verification if we don't offer email. |
| `data/services/firestore_service.dart` | Pattern only; much smaller without friends. |
| `functions/` | Replace notifications with availability proxy. |
| Friends, friend requests, profile sharing, push notifications, Vibe Score, genre comparison | Not carried over. |

We copy and adapt rather than share a package: the two apps' models diverge
(media types, library states), and a shared package would slow both down.

## Testing and CI

- Unit tests for every use case (taste, ranking, feed pager, clip offset
  picker) with fake repositories.
- Widget tests for Discover card states (loading, playing, no trailer, no
  availability), library filters, onboarding.
- Firestore rules tests with the emulator, as in resonance.
- GitHub Actions: `flutter analyze`, `flutter test`, `dart format --set-exit-if-changed`,
  and `npm test` for Functions. Mock mode (no keys) for CI, as in resonance.
- Release builds via Codemagic or Fastlane to TestFlight and Play internal
  testing (decide in M5).
