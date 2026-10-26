# curly-invention (Reel)

A personal movie and series tracker for iOS and Android, built in Flutter. Keep a record of what you have watched, your favorites and your watchlist, and discover what you can stream right now on your own subscriptions.

Design and planning docs are in [docs/](docs/README.md).

## Running

Needs Flutter 3.47 (Dart 3.13) or newer.

```bash
flutter pub get
flutter run                                   # mock catalog, no keys needed
```

With real data, copy `.env.example` to `.env`, fill in `TMDB_API_KEY` (a v3 key or a v4 read access token), and run:

```bash
flutter run --dart-define-from-file=.env
```

## Checks

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

CI runs the same on every pull request, on the mock catalog.
