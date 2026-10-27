# CLAUDE.md

Reel: a free Flutter app (iOS and Android) to track movies and series, keep a watchlist, and discover what streams on your own services. Product, screens and plan are in `docs/` (start at `docs/README.md`); decisions in `docs/07-open-questions.md`.

## Layout

Clean Architecture, package `reel`:

- `lib/core/`: `AppConfig` (dart-defines), theme, TMDB image URLs.
- `lib/domain/`: pure Dart. Entities (`MediaTitle`, `TitleId` as `movie:1` / doc id `movie_1`, `LibraryEntry` with `WatchEvent`s (`dateKnown` false for "seen before", e.g. setup swipes), `Availability`), repository interfaces, use cases (`query_library`, `build_diary`, `discover_feed`, `personalized_feed`, `analyze_taste`, `pick_clip`, `export_library`).
- `lib/data/`: TMDB client and mapper, mock catalog, local and Firestore repositories, `AuthService`.
- `lib/presentation/`: Riverpod providers (`providers/`), go_router (`router/app_router.dart`, a `StatefulShellRoute` with Discover, Search, Library, You), screens and widgets.

Availability is behind `AvailabilityRepository` (TMDB watch providers first), so another source can replace it.

## Conventions

- Riverpod 3 `Notifier`s. Providers nobody listens to are paused, so a notifier that needs another provider kept live uses `ref.listen` in `build`.
- Mock mode when `TMDB_API_KEY` is empty; Firebase only with `USE_FIREBASE=true` plus the `FIREBASE_*` defines (`--dart-define-from-file=.env`).
- Page width 120, single quotes, `unawaited_futures` on.
- Nothing may be drawn over the YouTube player (YouTube terms).

## Tests

```bash
dart format --set-exit-if-changed lib test
flutter analyze --no-fatal-infos
flutter test
```

Widget tests use `testOverrides(...)` from `test/support/fakes.dart`, override `videoEmbedsEnabledProvider` to false (no web view), and set a phone-sized view when they tap below the fold. Firestore rules tests in `firestore-tests/` need the emulator and aren't in CI.
