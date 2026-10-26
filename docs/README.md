# Design and planning

A personal movie and series tracker for iOS and Android, built in Flutter. It is
the single-user sibling of [resonance](https://github.com/veluribharath/resonance)
(Movie Vibe): no friends, no Vibe Score, no social graph. Working name below is
**Reel** until we pick a real one.

| Doc | What it covers |
|-----|----------------|
| [01-product.md](01-product.md) | Vision, the two surfaces, user stories, MVP scope |
| [02-screens.md](02-screens.md) | Navigation, every screen, the reels card layout |
| [03-architecture.md](03-architecture.md) | Flutter stack, layers, data model, what we reuse from resonance |
| [04-data-sources.md](04-data-sources.md) | TMDB, streaming availability providers, trailer clips, licensing |
| [05-recommendations.md](05-recommendations.md) | How the "watch right now" feed is generated and ranked |
| [06-milestones.md](06-milestones.md) | Delivery plan, M0 to M5, and what comes after |
| [07-open-questions.md](07-open-questions.md) | Product decisions that need an owner, with the default we assume |

## In one paragraph

The app has two surfaces. **Library** is where you keep your own record: what
you've watched (with an optional rating and date), your favorites, and what you
want to watch. **Discover** is a full-screen, vertically swiped feed, like
Instagram Reels, of movies, series and documentaries you can stream *right now*
on the services you actually pay for. Each card plays a short, catchy stretch of
the title's trailer, shows what it is and where to watch it, and lets you save
it, mark it watched, or say "not for me". Everything you do on either surface
feeds the recommendations.
