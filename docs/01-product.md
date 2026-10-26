# 01. Product

## Vision

"Know what you've seen, and find something good you can watch tonight without
opening five apps."

Streaming catalogs are split across services and change every month. People
lose track of what they've watched and what they meant to watch, and then spend
twenty minutes scrolling. Reel keeps a personal record and turns it into a short,
fun feed of things that are on *your* services today.

## What changes from resonance

| resonance (Movie Vibe) | Reel |
|---|---|
| Swipe deck to rate movies | Kept, but only as an optional onboarding "seed your taste" step |
| Friends, requests, Vibe Score, friend profiles, genre comparison | Removed |
| Push notifications for friend events | Removed (may return for "leaving soon" alerts later) |
| Movies only | Movies, series and documentaries |
| Recommendations from genres, people, friends' likes | Genres, people, favorites, implicit reel signals, filtered to your services |
| Like / dislike / watchlist as swipe actions | A library with watched, favorite and watchlist states |

## The two surfaces

### Surface 1: Library (your record)

- **Watchlist**: things you want to watch. Each item shows whether it's
  available on one of your services right now, so the watchlist doubles as a
  "what can I start tonight" list.
- **Watched**: things you've seen, with an optional date, rating and note. A
  title can be watched more than once (rewatches are logged, not duplicated).
- **Favorites**: a flag on a watched title. Favorites are the strongest taste
  signal we have.

### Surface 2: Discover (watch right now)

- A vertical, full-screen feed. One title per card.
- The card autoplays a muted 20 to 30 second stretch of the trailer, picked to
  skip studio logos and slow openings, and loops it.
- Filters at the top: All, Movies, Series, Documentaries. A "My services" toggle
  is on by default; turning it off shows anything, labeled with where it streams
  or rents.
- Actions on each card: Add to watchlist, Watched it, Not for me, Details, and
  "Open in Netflix" (or whichever service has it).

## Users and core stories

Primary user: someone with two to four streaming subscriptions who watches a few
times a week and doesn't want a social app.

1. As a new user I pick my country and my subscriptions in under a minute.
2. As a user I can find any movie or show and add it to my watchlist or mark it
   watched in two taps.
3. As a user I open Discover and the first few cards are things I can actually
   play on my services, that fit my taste.
4. As a user I can see which of my watchlist titles are streamable on my
   services right now.
5. As a user my library is safe if I change phones.
6. As a user I can see simple stats: how much I watched this month, my top
   genres, people I keep coming back to.

## MVP scope

In: onboarding (country, services, optional taste seed), search, title details
with where-to-watch, library (watchlist, watched, favorites, ratings), Discover
feed with trailer clips and service filtering, sign-in and cloud backup, basic
stats.

Out for MVP: episode-level tracking for series, import from Letterboxd/Trakt/
IMDb, "leaving soon" push alerts, home screen widgets, tablets/web, any social
feature.

## Success measures

- Onboarding completion rate above 80%.
- Share of Discover sessions that end with at least one save or "watched".
- Weekly active users who log at least one watch.
- Discover card-to-"open in service" rate (once deep links exist).
