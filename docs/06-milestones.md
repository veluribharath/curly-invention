# 06. Milestones

Sizes assume one developer working with Claude, and are rough.

## M0. Bootstrap (about 3 days)

- `flutter create` for iOS and Android only, package name decided, app name
  placeholder.
- Folder structure, Riverpod, go_router shell with four empty tabs, dark theme.
- Copy `TMDBService`, `Person`, `AppConfig` from resonance; add `MediaType`,
  `TitleId`, `Title`.
- CI: analyze, format check, test, in mock mode.
- **Spike**: a throwaway vertical `PageView` of five YouTube embeds with muted
  autoplay from an offset, run on a real iPhone and a mid-range Android. This
  tells us early whether the reels idea works with embeds.

Done when: app runs on both platforms, CI is green, spike findings written up.

## M1. Library (about 1.5 weeks)

- Firebase project, anonymous auth, Firestore with offline persistence, rules
  and rules tests.
- Search (movies and series), title details with trailer, cast, seasons.
- Watchlist, log a watch (date, rating, note), favorites, rewatches.
- Library tab with segments, filters, sorts, grid/list.

Done when: you can build and use your library end to end, offline too.

## M2. Services and availability (about 1 week)

- Onboarding: welcome, country, services grid.
- `AvailabilityRepository` on TMDB watch providers; Where to watch on details.
- "On my services now" filter and banner in the watchlist.
- You tab: edit services and country.

Done when: library and details know what's streamable for you.

## M3. Discover v1 (about 2 weeks)

- Feed pager with candidate sources 1, 4 and 5 and simple ranking.
- Reels card: single live player, pre-load next, muted autoplay, tap to unmute,
  clip window picker (prefer clips/teasers, skip trailer openings), fallbacks.
- Filter chips and My services toggle.
- Card actions: watchlist, watched, not for me, details, open service (to app
  home/search for now).
- Feed signals recorded.

Done when: Discover is usable daily and feels smooth on a mid-range Android.

## M4. Personalization (about 1.5 weeks)

- Taste profile from library and signals (adapted `analyzeTaste`).
- All six candidate sources, full ranking, diversity pass, reasons on cards.
- Onboarding taste seed (resonance swipe deck).
- Curated clip overrides collection.
- You tab stats (reused charts).

Done when: two test users with different tastes get clearly different feeds.

## M5. Accounts, polish, release (about 1.5 weeks)

- Apple and Google sign-in, link anonymous account, sign out, delete account.
- Export library.
- Crashlytics, Analytics events for the success measures.
- Attribution screens (TMDB, JustWatch), privacy policy, App Store and Play
  listings, screenshots.
- TestFlight and Play internal testing.

Done when: build is in testers' hands on both stores.

**Total to first testers: roughly 9 to 10 weeks.**

## After launch (not scheduled)

- Paid availability source (Streaming Availability or Watchmode) through a
  Cloud Functions cache: true "Open in Netflix" deep links, "leaving soon".
- Push: "3 titles on your watchlist leave Netflix this week."
- Episode tracking for series ("next up").
- Import from Letterboxd, Trakt, IMDb CSV.
- Home screen widget: "Tonight's pick".
- Smarter clip windows from audio/scene analysis.
