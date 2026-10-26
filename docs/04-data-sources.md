# 04. Data sources

Three kinds of data: the catalog (what titles exist), availability (where each
one streams in your country), and clips (the video on each reel).

## Catalog: TMDB

Already integrated in resonance. Endpoints we need:

| Need | Endpoint |
|---|---|
| Search movies and series together | `GET /search/multi` |
| Details, credits, videos in one call | `GET /movie/{id}?append_to_response=credits,videos,watch/providers,recommendations` and the same for `/tv/{id}` (with `aggregate_credits`) |
| Feed candidates | `GET /discover/movie`, `GET /discover/tv` |
| Trending for empty search | `GET /trending/all/week` |
| Similar titles | `GET /{type}/{id}/recommendations` |
| A person's titles | `GET /person/{id}/combined_credits` |
| Provider list for onboarding | `GET /watch/providers/movie?watch_region=XX` and `/watch/providers/tv` |
| Countries with provider data | `GET /watch/providers/regions` |

Documentaries are genre `99` for both movies and TV, so the Docs filter is just
`with_genres=99`; the Movies and Series filters exclude it.

**Licensing**: the TMDB API is free for non-commercial use with attribution
("This product uses the TMDB API but is not endorsed or certified by TMDB" plus
the logo). Commercial use (paid app, ads, subscriptions) needs a commercial
agreement with TMDB. See [07-open-questions.md](07-open-questions.md).

## Availability: where can I watch it right now?

This is what makes "tailored to my subscriptions" work. Options:

### Option A: TMDB watch providers (powered by JustWatch). Recommended for MVP.

- `GET /{type}/{id}/watch/providers` returns, per country, lists of providers
  under `flatrate` (subscription), `free`, `ads`, `rent`, `buy`.
- `GET /discover/movie?watch_region=US&with_watch_providers=8|9|1899&with_watch_monetization_types=flatrate|free|ads`
  returns only titles streamable on the given services. This is the core query
  for Discover, done in one call, no extra cost.
- Free, already the API we use, roughly 140 countries.
- Limits:
  - **No per-service deep links.** The response has one JustWatch page URL per
    title, not "open this in Netflix". We can open the service's app to its
    search or home screen instead, which is weaker.
  - No "leaving soon" dates.
  - Data is refreshed daily-ish; occasionally stale.
  - JustWatch attribution is required wherever provider data is shown.

### Option B: Streaming Availability API (Movie of the Night)

- Per-service deep links (open the exact title in Netflix, Prime, etc.), leaving
  and newly-added dates, about 60 countries, search by service and filters.
- Paid beyond a small free tier, sold through RapidAPI and directly. Pricing to
  be confirmed when we decide.

### Option C: Watchmode API

- Deep links for iOS, Android and web, 200+ services, "new on" and "leaving"
  lists.
- Free tier is small (on the order of 1,000 calls a month); paid plans above
  that. Pricing to be confirmed.

### Plan

Start with **A** behind `AvailabilityRepository`. It covers filtering, which is
the core promise. Add **B or C** in a later milestone for deep links and
leaving-soon, called through a Cloud Function that caches results per
title/country in Firestore for 24 hours so cost scales with distinct titles,
not with users. Candidate generation stays on TMDB discover either way.

JustWatch itself has no public API; scraping it is against their terms, so it's
not an option.

## Clips: the reel video

### Source

TMDB's `videos` lists the YouTube trailers, teasers, clips and featurettes
studios publish, with `type`, `official`, `site`, `key` and language. We play
them through YouTube's embedded player, which is what resonance's details
screen already does with `youtube_player_iframe`.

Downloading, trimming or re-hosting trailers is not allowed (YouTube terms and
studio copyright), so every "clip" is the official embed played from an offset.

### Picking the catchy part

The embed accepts `start` and `end` (seconds), so a "clip" is a window into a
trailer. Strategy, in order:

1. **Prefer short official videos**: an official `Clip` or `Teaser` is usually
   a self-contained scene and works from second 0.
2. **Trailers: skip the opening.** Trailers open with studio logos and slow
   setup. Default window: start at about 15% of the trailer's length (minimum
   20s), play 25s, loop. Length comes from the YouTube Data API
   (`videos.list?part=contentDetails`, 1 quota unit per call, batched 50 at a
   time) and is cached with the title.
3. **Curated overrides**: a small Firestore collection of hand-picked start
   times for popular titles, editable without an app release. Overrides win.
4. **Later, smarter**: score windows by audio energy or scene-cut density,
   offline in a Cloud Function, and store the best start time. Only if 1 to 3
   feel weak in testing.

Language: prefer the user's language, then English, then any.

### Player constraints that shape the design

- YouTube's terms say the player must not be covered or obscured, its branding
  stays visible, and we can't autoplay with sound. So: autoplay **muted**,
  title info **below** the player rather than overlaid, tap to unmute.
- Each player is a web view. Only one live player at a time, one pre-loaded,
  the rest torn down, to keep memory and battery sane on older phones.
- Some trailers are blocked from embedding or region-locked. The player reports
  an error; we fall back to the next video in the list, then to backdrop images.
- iOS needs inline playback enabled (the package handles it); test on a real
  device early, in M0, because this is the riskiest technical piece.

### Alternatives if YouTube embeds don't feel good enough

- A licensed trailer feed with direct video files (several vendors sell these to
  streaming guides). Allows full-bleed video, overlays and precise clips, at a
  cost. Worth pricing only if the embed experience disappoints in M3.
