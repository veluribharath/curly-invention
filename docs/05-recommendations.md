# 05. Recommendations: the Discover feed

Goal: every card in the first screenful is something the user can play now and
plausibly wants to. Built on resonance's `recommend_movies.dart` and
`analyze_taste.dart`, minus the friends term, plus availability filtering and
reel signals.

## Inputs

| Signal | Strength | Source |
|---|---|---|
| Favorite | strong + | Library |
| Watched, loved | strong + | Library |
| Watched, liked | + | Library |
| Watched, disliked | strong − | Library |
| On watchlist | + (and the title itself is a candidate) | Library |
| Watched full clip, unmuted, opened details | weak + | Feed signals |
| Swiped past in under ~2s | weak − | Feed signals |
| Not for me | strong − (title never shown again) | Feed signals |
| Onboarding taste seed | same as library | Library |

From these, `TasteProfile` holds affinity per genre, per person (actors,
directors, creators), per media type, and a preferred runtime band.

## Candidate generation

Each feed page pulls from several sources, all restricted to the user's services
and country via TMDB's `with_watch_providers` / `watch_region` /
`with_watch_monetization_types`:

1. **Watchlist, available now**: titles you saved that are on your services.
   A few per page, never all at once.
2. **Because you liked X**: `/recommendations` of recent favorites and loved
   titles, then checked for availability.
3. **People you like**: discover with `with_people` for top actors and
   directors (resonance's `topPeople`).
4. **Genre picks**: discover by your top genres, sorted by popularity and vote
   average, with a minimum vote count to avoid obscure noise.
5. **Fresh on your services**: discover sorted by release date, last 90 days.
6. **Wildcard**: highly rated outside your top genres, about 1 in 8 cards, so
   the feed doesn't narrow into a rut.

Excluded: anything watched, anything marked not for me, anything without a
playable offer (when "My services" is on), and anything shown in the last
N sessions without interaction.

## Ranking

Score per candidate (weights to tune):

```
score = genreAffinity + peopleAffinity + typeAffinity
      + sourceBoost (watchlist > because-you-liked > people > genre > fresh)
      + quality (vote average, damped by vote count)
      + freshness
      − recentlyShownPenalty
```

Then a diversity pass: no more than two of the same primary genre or the same
media type in a row, and no two from the same franchise back to back.

Every card carries a one-line reason, as resonance's `Recommendation.reason`
does: "Because you loved Arrival", "Denis Villeneuve", "On your watchlist",
"New on Max".

## Cold start

No library yet: fall back to "popular on your services this week", mixed across
the selected media types, and lean on the onboarding taste seed if it was used.
Reel signals start shaping the feed after the first dozen cards.

## Where it runs

On the device for MVP. Inputs are small (a few hundred library entries), and
TMDB does the heavy filtering. If we later want cross-user signals (what people
with similar taste loved), that moves to a backend job; nothing in the client
API needs to change because `discoverFeedProvider` only sees a stream of ranked
cards.
