# 07. Open questions

Each has the default these docs assume. Changing a default mostly changes
milestones, not architecture.

| # | Question | Default assumed | What changes if different |
|---|---|---|---|
| 1 | Is this a commercial app (paid, ads, subscription) or free/personal? | **Decided (2026-10-26):** free, non-commercial | Commercial needs a TMDB commercial license and makes a paid availability API more attractive early. |
| 2 | Free TMDB availability data first, or pay for deep links ("Open in Netflix") from day one? | **Decided (2026-10-26):** TMDB first, paid source after launch | Paying early moves the Cloud Functions proxy into M2 and adds a monthly API cost. |
| 3 | Launch countries | Any country TMDB has provider data for; test with US and India | A single-country launch simplifies QA and curated clip overrides. |
| 4 | Accounts: optional sign-in (anonymous first) or required? | Optional; anonymous first, upgrade to Apple/Google | Required sign-in simplifies sync logic but adds a wall at first launch. |
| 5 | Rating scale for watched titles | Three levels: didn't like / liked / loved, plus favorite | Five stars or half stars only changes the entity and the taste weights. |
| 6 | Series tracking depth | Whole show only in MVP | Episode tracking is a sizable feature (M6+). |
| 7 | Reel layout: info below the video (embed-safe) vs full-bleed video with overlays | Info below, blurred backdrop around | Full-bleed requires licensed video files, not YouTube embeds. |
| 8 | App name and bundle ID | "Reel" placeholder | Needed before M5 store setup; ideally before M0 for the bundle ID. |
| 9 | Should the swipe deck from resonance stay as a mode, not just onboarding? | Onboarding only, plus a "Rate more" entry in You | Keeping it as a tab adds a fifth tab. |
| 10 | Separate Firebase project from resonance? | Yes, separate | Sharing one is possible but couples rules, quotas and billing. |
