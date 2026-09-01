# Where we are, 2026-09-01, 3am

Written at the end of a long night. Read this before touching anything.

## The bug we are chasing

Every match ends itself after 6 to 27 seconds and dumps the contestant back
into Edit Mode in third person. It always ends within about 15 milliseconds of
a robot being eliminated.

It is NOT: the network, the Verse cleanup, the Island Settings, or memory.
All four were checked and cleared, with evidence, below.

## When it started

Matches ran for minutes on 2026-08-30. The last good one was 598 seconds,
ending 22:59 local that evening. Every match since has been under 30 seconds.
So the cause is in the changes made between then and the following morning.

Measured from the UEFN logs, which record `MinigameStateChanged` for
`InProgress` and `PostGameEnd`. That is the reliable way to time a match; do
not go by feel.

## What has been ruled OUT, with evidence

- **The network.** The original "failed to connect to beacon" errors were DNS:
  `libcurl error: 6 (Could not resolve hostname)` against `*.ol.epicgames.com`,
  five sessions in one day. Both adapters were moved from the router to
  Cloudflare (1.1.1.1 / 1.0.0.1) and the name lookup failures went to zero.
  See [[kicks-and-beacon-timeouts-are-dns]].
- **The Verse-removal test.** The 24 scripts moved to `_verse_backup` are all
  back and byte-identical to the commit before the move. The 6-second matches
  began four hours BEFORE that move happened.
- **Island Settings.** Unchanged between the last good match and the first bad
  one. Verified with `git diff --name-status 6385864 661b18f` over the actor
  file `Content/__ExternalActors__/SponsorMeSlayers_v2/C/R3/W1IFAY9ONE4UTS5YWOQ6M4.uasset`.
  "AI Enemy Eliminations to End" is unticked with a greyed 1 beside it, and it
  cannot be set to 0, so leave it alone. That was a wrong guess of mine.
- **Memory.** The island runs at 15,366 of a 100,000 budget. Not close.
- **Nothing in the Verse code ends a match.** The only `end_game_device`
  activation is `GameOverScreen.LeaveTheShow`, retired by amendment 86, and
  nothing calls it.

## What has been ruled out BY PLAYTEST

Each of these was built as a real test point and played:

| Test point | Result |
|---|---|
| `6385864` alone, the last good Sunday version | 4+ minutes, no end |
| `6385864` + the 51 voice-line audio devices from `661b18f` | 168 seconds |
| the above + the announcer's face and moving mouth from `895c518` | 190 seconds |

So the voice lines, all 51 audio devices, and the whole announcer face and
mouth are innocent.

## What is still under suspicion

Two things, both from Sunday night:

1. **The stream chat rework** (`StreamChatManager.verse`, plus the
   `GetScreenTop` accessor added to `HypeMeterManager.verse`).
2. **The announcer caption rework** (`AnnouncerManager.verse`, plus
   `IsShowing` on `GameOverScreen.verse`).

The commits between good and bad, oldest first:

    fb72b06  08-30 23:03  A content folder is a Verse name, and Face was taken
    895c518  08-30 23:06  Give the announcer a face, and a mouth that moves   <- cleared
    e452e94  08-30 23:13  Move the caption to the top centre lane
    bb3aa02  08-30 23:18  Give the chat a real lane
    587963f  08-30 23:19  Two stale mentions of the line count
    56b582d  08-30 23:20  Keep our own list of what the chat is showing
    137317b  08-30 23:28  Give both HUD panels a floor as well as a ceiling
    66cfd4a  08-30 23:28  The band lost the widget it was a band for
    661b18f  08-31 10:28  Kai's recorded voice lines, and the face pictures   <- cleared

## Where the test stopped

The chat rework was built as the next test point and never got a verdict. The
session hung twice on "Cooking for client platforms finished, waiting on Server
platforms", with no Verse output at all, so the island never ran. That is a
Fortnite client or Epic-side hang, not our code failing. Retry it before
reading anything into it.

## Two traps that cost time tonight, do not repeat them

1. **UEFN must be fully closed before any file is moved, added or restored.**
   It works from a stale file list, so a correct fix looks like it failed. The
   process is `UnrealEditorFortnite-Win64-Shipping`, not `UnrealEditorFortnite`.
2. **A mixture of two commits is not a version that ever existed.** Borrowing
   `Content/Face` from a later commit to make an earlier one compile produced a
   name clash (script error 3588: a content folder called Face becomes a Verse
   module, and the older code uses `Face` as a local). Every test point has to
   be internally consistent.

## How to resume

Everything is safe. `main` holds all the real work and is pushed to GitHub.
Branches `known-good-aug30`, `bisect-test` and `test-audio-only` are scratch.

To rebuild the chat test point, with UEFN closed:

    git checkout -B test-chat 6385864
    git checkout 661b18f -- Content/Announcer Content/__ExternalActors__
    git checkout 895c518 -- Content/AnnouncerManager.verse Content/GameOverScreen.verse
    git checkout 661b18f -- Content/Face
    git checkout 66cfd4a -- Content/StreamChatManager.verse Content/HypeMeterManager.verse

To test the caption instead, swap that last line for:

    git checkout 66cfd4a -- Content/AnnouncerManager.verse Content/GameOverScreen.verse

To go back to the real project at any time:

    git checkout main

## Also noticed, not urgent

- `Content/testroom_DefaultHLODLayer.uasset` is an orphan. It was added by
  `5d03a7e` and there is no `testroom` level. Junk, but harmless.
- Matchmaking in `SponsorMeSlayers_v2.uefnproject` drifts from 1 team of 1 to
  16 of 16 on its own, twice tonight. UEFN rewrites it on save. Put it back to
  1 and 1 whenever it is spotted.
- Two HUD jobs are agreed and unbuilt: the cash counter split onto two lines
  (CASH above, the number below) and the caption wrap fix, where the strip
  reserves its full width for the words and then the face is placed beside them
  in that same strip, squeezing the text into one word per line.
