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

### Accounts and sync (optional)

Without Firebase, the library lives on the device. To sync it, create a Firebase project, enable Anonymous, Apple and Google sign-in, fill in the `FIREBASE_*` values in `.env`, set `USE_FIREBASE=true`, and deploy the rules:

```bash
firebase deploy --only firestore:rules
```

Everyone starts signed in anonymously. Linking Apple or Google in **You** keeps the same library; signing in to an account that already exists merges this phone's library into it. Apple and Google sign-in also need the usual platform setup (Sign in with Apple capability on iOS, SHA fingerprints for Google on Android).

Rules tests run against the emulator:

```bash
cd firestore-tests && npm install && firebase emulators:exec --only firestore "npm test"
```

## Credits

Title data, images and streaming availability come from [TMDB](https://www.themoviedb.org/), with availability provided by [JustWatch](https://www.justwatch.com/). This product uses the TMDB API but is not endorsed or certified by TMDB. Clips play through the official YouTube player.

## Checks

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

CI runs the same on every pull request, on the mock catalog.
