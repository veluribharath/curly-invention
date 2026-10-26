# 02. Screens and flows

## Navigation

Bottom navigation with four tabs, built with `go_router`'s `StatefulShellRoute`
so each tab keeps its own stack:

| Tab | Route | Purpose |
|-----|-------|---------|
| Discover | `/discover` | The reels feed. Default tab after onboarding. |
| Search | `/search` | Find any title, movie or series |
| Library | `/library` | Watchlist, Watched, Favorites |
| You | `/you` | Stats, services, country, account, settings |

Pushed routes on top of any tab:

| Route | Screen |
|-------|--------|
| `/title/:type/:id` | Title details (`type` is `movie` or `tv`) |
| `/onboarding/*` | First-run flow |
| `/you/services` | Edit subscriptions |

The ID always carries the media type because TMDB movie and TV IDs overlap.

## Onboarding (first run)

1. **Welcome**: one line on what the app does, "Get started", and "I already
   have an account".
2. **Country**: preselected from the device locale, changeable. Availability is
   per country, so this matters.
3. **Your services**: a grid of provider logos for that country (from TMDB's
   provider list), sorted by popularity. Multi-select. "Also show free with ads"
   toggle (Tubi, Pluto, etc.).
4. **Seed your taste (optional, skippable)**: the resonance swipe deck, reused.
   Popular titles; right = seen and liked, left = seen and didn't like, up =
   want to watch, down = haven't seen. Ten to twenty cards is enough. This fills
   the library and gives Discover a head start.
5. Lands on Discover.

Sign-in is not required to start: an anonymous account is created silently and
can be upgraded to Apple or Google sign-in from You at any time (see
[03-architecture.md](03-architecture.md)).

## Discover (the reels feed)

Vertical `PageView`, one card per page, full screen under a transparent app bar.

```
┌──────────────────────────────┐
│  All  Movies  Series  Docs   │  ← filter chips, "My services" toggle
│                              │
│  ░░░░ blurred backdrop ░░░░  │
│ ┌──────────────────────────┐ │
│ │                          │ │
│ │   trailer clip (16:9)    │ │  ← YouTube player, muted, looping
│ │                          │ │
│ └──────────────────────────┘ │
│                              │
│  Dune: Part Two       2024   │
│  Movie · 2h 46m · ★ 8.2      │
│  Sci-Fi · Adventure          │
│  "Because you loved Arrival" │
│                              │
│  [N] Netflix  [M] Max        │  ← your services highlighted
│                              │
│  ＋ Watchlist  ✓ Watched  ✕  │
│  [ Open in Netflix ]   ⓘ     │
└──────────────────────────────┘
```

Behavior:

- Only the card on screen has a live video player. The next card is pre-loaded
  (metadata, backdrop, video ID resolved, player created but paused) so the swipe
  feels instant. Cards more than one away are torn down.
- Muted by default; tap the clip to unmute (the preference sticks for the
  session).
- Title info and actions sit **outside** the video frame, not overlaid on it.
  YouTube's terms forbid covering the player, and this layout also keeps text
  readable. The blurred backdrop fills the rest of the screen so it still feels
  immersive. If we later license clips from a source that allows overlays, the
  layout can switch to full-bleed video.
- No trailer: the card falls back to a slow pan over backdrop images.
- "✕ Not for me" removes the card and is a negative signal. Swiping past quickly
  is a weak negative signal; watching the full clip or unmuting is a weak
  positive one.
- Pull-down at the top refreshes the feed.

## Title details

Reuses and extends resonance's `MovieDetailsScreen`.

- Trailer player (full controls), backdrop, title, year, runtime or seasons,
  rating, genres, overview.
- **Where to watch** for your country: grouped into Stream / Free / Rent / Buy,
  your services first and highlighted, with the required JustWatch attribution.
- Cast and director (tappable, shows their other titles).
- Library actions: Watchlist toggle, "Log a watch" (opens a sheet: date,
  rating, favorite, note), favorite heart.
- For series: seasons list (read-only in MVP).
- "More like this" row.
- Share (resonance's `build_movie_share` reused).

## Search

- Single field, searches movies and series together (TMDB `/search/multi`),
  people results show their known titles.
- Recent searches and "Trending this week" when the field is empty.
- Each result row has a quick "+ Watchlist" and a "Watched" button.

## Library

- Segmented control: **Watchlist** · **Watched** · **Favorites**.
- Filters: type (movie / series / doc), "On my services now", genre.
- Sort: date added, date watched, rating, title, release year.
- Grid of posters by default, list view toggle.
- Watchlist rows show service logos when available now; a banner reads "7 of
  your watchlist are on your services".
- Swipe a row to remove or to mark watched.

## You

- Stats: watched this month/year, hours watched (from runtimes), top genres and
  people, weekly activity chart (resonance's `taste_charts.dart` and
  `analyze_taste.dart` reused).
- My services and country.
- Account: sign in with Apple / Google to back up, sign out, delete account.
- Data: export library as CSV/JSON.
- About: TMDB and JustWatch attribution, licenses.

## Design language

Start from resonance's look but darker and more cinematic, since the reels feed
is video-first:

- Material 3, dark theme by default (light available), seed color kept from
  resonance's indigo so the two apps feel related.
- Posters and backdrops via `cached_network_image` as in resonance.
- Large, bold titles on Discover; compact rows in Library.
- Provider logos always shown at the same size with their official artwork from
  TMDB.
- Haptics on save / watched.
