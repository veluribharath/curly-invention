# 08. Reels spike (M0)

The riskiest piece of the plan is whether YouTube embeds can carry a
reels-style feed. The app ships a throwaway screen to find out before Discover
is built on it.

## How to run it

```bash
flutter run --release -d <device>     # no keys needed
```

Open the **You** tab and tap **Reels spike** (debug and profile builds show it;
release builds too until Discover lands), or go to `/spike`.

Five trailers in a vertical `PageView`. Only the card on screen has a live
player; the others show the YouTube thumbnail. Each plays muted from an offset
for 25 seconds and loops. The mute toggle sits below the player because
YouTube's terms forbid covering it.

## What to check, on a real iPhone and a mid-range Android

| Check | Pass when |
|---|---|
| Muted autoplay starts by itself | Video plays within about 2 s of the card settling, no tap needed |
| Inline playback on iOS | Plays inside the card, doesn't jump to the fullscreen player |
| Start offset and loop | Starts at the given second, loops back after 25 s |
| Swiping | Flicking to the next card stays smooth while video plays |
| Teardown | Swiping away stops the audio of the previous card at once |
| Memory | 50 swipes back and forth don't crash or slow down the phone |
| Unmute | Tapping the speaker unmutes, and sound respects the silent switch on iOS |
| Branding | YouTube logo and title bar stay visible; nothing overlaps the player |

## Findings

To fill in after running on devices. Discover (M3) is built so that a bad
result here only changes the clip player widget, not the feed.

| Device | OS | Result | Notes |
|---|---|---|---|
| | | | |
