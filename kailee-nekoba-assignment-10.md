# ASSIGNMENT #10 — COMPLETE AI DEV PIPELINE

**Student Name:** Kailee Nekoba
**Capstone Game Title:** Sponsor Me, Slayers!

**Game Concept Brief:**
A top-down twin-stick arcade shooter built in Unreal Editor for Fortnite (UEFN)
in the Verse language. The player is a contestant on a dystopian televised game
show, fighting waves of cybernetic hostiles inside a single-room stadium arena.
Movement is decoupled from aiming, so you run one way and shoot another. Killing
hostiles showers the arena with cash and retro appliances, collecting them fills
a Hype Meter, and crossing a Hype threshold makes the simulated audience
parachute supply crates in. The pipeline's job is the numbers behind that fight:
the stat ladders that decide how tough each wave of hostiles is.

---

## DELIVERABLE 1: PLAYABLE LINK

**Playable Game Link:** https://knekoba.itch.io/sponsor-me-slayers

The game is a Fortnite island, so it cannot be a WebGL build or a downloadable
zip. The itch.io page carries a 90-second gameplay walkthrough video instead.
This is the route the instructor approved in Class 13 for a project that could
not be web-playable: publish the page, embed the walkthrough.

**Why there is no island code alongside it.** Two gates, neither of them the
build. First, publishing an island into Fortnite requires signing the Fortnite
Developer Terms, and that carries a cost I cannot cover this week. Second,
publishing puts the island in front of Epic's own review before anyone else can
launch it, and I need sign-off from my studio before I put anything out under
those terms. That request is in.

Neither gate is a statement about the game. The island is complete and playable
and runs end to end every time it is launched from the editor, which is what the
video shows. When both clear, the same island publishes and the code goes onto
this same page, which is why the page is the link being submitted rather than a
code that does not exist yet.

**Prototype note (also on the itch page):** this is the 1 September build. It is
playable end to end and it has one known bug, described on the page.

---

## DELIVERABLE 2: PIPELINE SOURCE CODE & ENGINE INTEGRATION

**Pipeline Repository Link:** https://github.com/knekoba1/SponsorMeSlayers_v2

**Pipeline Run Video Link:** https://knekoba.itch.io/sponsor-me-slayers

Two runs are on that page, under Downloads:

- **Pipeline run - GER refiner and circuit breaker.** The Cyber-Boar ladder is
  re-checked against a 5.0 m/s player run speed instead of the assumed 6.0, so a
  real card fails a real rule. The Evaluator cites GDD 5.5, GDD 2.2 and Amendment
  8 by name for each break, the Refiner repairs the ladder to 10/10, and a
  stubborn stand-in generator then trips the circuit breaker after three
  attempts and escalates rather than looping. Ends with both guardrails PROVEN
  and the repaired ladder printed.
- **Pipeline run - Style Guide crew.** A Sponsor Aid card scores 2/10, the local
  checker catches the banned generic words 'magic', 'hero' and 'monster', and the
  Refiner rewrites it into the show's own voice until it clears.

The repository holds both the game and the agents, in the same tree, so a
prompt change and the code it produced are version-controlled together:

| Where | What it is |
|---|---|
| `pipelines/assignment-06-ger/` | The GER pipeline: Generator, Evaluator, Refiner, circuit breaker |
| `pipelines/assignment-07-style/` | The Style Guide crew: Proposer, Adversarial Critic, Judge, Evaluator, Refiner |
| `pipelines/assignment-09-adversarial/` | Adversarial QA: ten attacks against ten written invariants |
| `pipelines/announcer-bark/` | The bark database and its triggers. Deliberately has no language model in it |
| `.claude/agents/` | The four in-project agent roles: Gameplay Systems, Simulated Audience, Announcer Bark, Playtest QA |
| `Content/*.verse` | The 24 Verse scripts the agents wrote and the designer approved |

### Integration breakdown

**Target Game Engine:** Unreal Editor for Fortnite (UEFN), Verse.

**Automated flow description.**
The GER pipeline reads the GDD and the recorded amendments, generates fifteen
hostile stat cards, and writes `output/tier-cards.csv` — one row per card, with
health, walk / run / sprint speed, and how many of that type may be alive at
once. The Evaluator then re-derives every number in plain Python and rejects any
card that breaks a rule traceable to a sentence in the GDD: 8% difficulty per
tier compounded, no card past Escalation Tier 21, never more than 40 hostiles
alive, sprint speed always below the player's run speed. Rejected cards go back
to the Refiner with the failing rule attached, and a circuit breaker stops the
loop rather than letting it spin.

The numbers land in the engine two ways. Wave pacing, concurrency and the tier
ramp are read directly by `Content/WaveManager.verse`, which drives the four
spawners at runtime — no reformatting, the script consumes the pipeline's own
shape. Per-hostile health and movement speed live on UEFN
`npc_character_definition` assets, and those are editor assets, so the CSV row
is entered against the asset by hand.

**That is the one remaining manual step, and it is documented rather than
hidden.** See Deliverable 3.

---

## DELIVERABLE 3: PIPELINE AUDIT & COST ANALYSIS

### Pipeline production and functionality

**What did the pipeline produce that is in the playable build?**

- **Fifteen hostile stat cards**, five each for the Cyber-Boar, the Ranged
  Sentinel and the Ranged Tank — three enemy types the GDD names and the game
  did not have. Their health, speed and concurrency ladders across Escalation
  Tiers 1 to 21 are the pipeline's output, and all three types fight you in the
  build.
- **The wave pacing and concurrency ramp** consumed by `WaveManager.verse`: how
  many hostiles a wave contains, how many may be alive at once, and how both
  scale per tier.
- **Crate pickup cards** from the Style Guide crew (Assignment 7): the pickup
  text shown when a supply crate is opened, held to the show's voice by an
  adversarial critic and a deterministic checker.
- **The adversarial QA findings** (Assignment 9) that drove real fixes: ten
  scripted attacks that push the contestant through every wall, under the floor,
  thirty metres up and onto each spawner, checked against ten written
  invariants.

**What manual steps remain?**

1. **Entering a stat card onto its `npc_character_definition` asset.** Fifteen
   rows, typed against fifteen editor assets.
2. **Placing devices in the map.** Spawners, audio players, the crate pad.
3. **Writing the announcer's barks.** This one is manual on purpose and is not a
   gap in the pipeline. The revision log fixes the sarcastic commentator's lines
   as hand-written by the designer, so the bark pipeline structures, maps and
   plays the lines but never generates their text.

**What would it take to eliminate them?**

Steps 1 and 2 are blocked by the engine, not by the pipeline. Verse cannot create
or edit a UEFN asset, and it cannot place an actor in the map; both are editor
operations with no scripting surface. Two things would close it:

- **Nearest-term, and worth doing:** stop emitting a CSV a human retypes and
  emit a Verse source file instead — a typed array of stat structs the compiler
  reads directly. The numbers would then land in the build with no reformatting
  and no retyping. This does not need anything Epic has not shipped; it is a
  change to the pipeline's output format, described again below.
- **To close it fully:** an MCP server for UEFN that can write `.uasset`
  property values and place actors. Unreal 5.8's Model Context Protocol is the
  shape of this, and UEFN does not expose it yet.

Step 3 stays manual by design and should not be automated.

### Architectural reflection

**Current architectural decision to change:**
Making the pipeline's deliverable a spreadsheet. `output/tier-cards.csv` is easy
to read and easy to grade, and it was the obvious artefact to produce. But a
spreadsheet is not something a game engine can eat. It made a human the transport
layer between a validated number and the asset that uses it, which is exactly the
manual step this assignment asks about, and it means the pipeline's guarantees
stop at the file boundary: the Evaluator can prove a card is legal and still have
a typo enter the game.

**Specific alternative:**
Emit `Content/HostileStatCards.verse` instead of, or alongside, the CSV — a
generated Verse file containing a `hostile_stat_card` struct and a typed array of
fifteen literals, with a header comment naming the pipeline run that produced it.
`WaveManager.verse` reads that array the same way it already reads its other
tables. The Verse compiler then becomes a second, free evaluator: a malformed row
fails the build instead of reaching a playtest. Regenerating is a pipeline run
and a Build Verse Code, with nothing typed by hand, and the manual step for
health and speed disappears for every hostile type at once.

### Cost analysis

**Total actual run cost: $0.00 in metered charges.**
Every pipeline run for this capstone executed through Claude Code against a
Claude subscription on this machine. There is no API key wired into any of the
four pipelines, so no run was billed per token. The honest full figure is the
subscription itself: one $20/month Claude plan, across the seven weeks of the
course. A separate $5 of Anthropic API credit was bought on 25 August for the
optional Assignment 8 narrative engine, which is a standalone project outside
this repository and is not part of the capstone pipeline.

**Most expensive pipeline step:**
The Refiner round in the Style Guide crew. Everything else in that pipeline is
either a single batched call or free: the hard checks are plain Python, and the
Proposer returns eight variations in one JSON reply. But a card that fails
verification costs a complete evaluate-and-refine round trip, with the card, the
failing rule and the style guide all back in context, and a card can fail more
than once. It is the only step whose cost scales with how badly the model did.

**Solo / small-team sustainability: yes, and specifically because of the split.**
The rule is that nothing a computer can decide arithmetically is ever asked of a
model. The Evaluator that enforces 8% per tier, the 40-hostile ceiling and the
speed rule contains no AI at all; it is arithmetic that runs locally and costs
nothing per check, and it runs first, before any model is called. The model is
paid for judgement and voice, which is the part it is actually good at. That
keeps the bill flat as the content grows: doubling the number of stat cards
doubles the free arithmetic and adds one batched call, not fifty. On a $20
subscription this pipeline is sustainable for a solo developer indefinitely.

### Mid-project cost-reduction change

**Strategy / prompting approach**

- **Before:** the Proposer was asked for one card at a time, and the model was
  also asked to check its own arithmetic against the GDD rules. Every card cost
  its own round trip, and the verification cost another one on top.
- **After:** the Proposer returns a whole batch of variations in a single JSON
  reply, and the arithmetic check was taken away from the model entirely and
  rewritten as plain Python that runs locally. The model is now asked only for
  the things arithmetic cannot settle: whether a line sounds like the show, and
  whether a card is interesting.

**Token / API cost**

Measured in model round trips per batch, which is what the project logged; the
runs were on a subscription rather than a metered key, so there is no
per-run dollar figure to quote and inventing one would be dishonest.

- **Before:** 8 generation round trips per batch of 8, plus 1 verification round
  trip per card. 16 model calls to land a batch of 8.
- **After:** 1 batched generation round trip, plus 0 verification calls, because
  verification moved to local Python. 1 model call to land a batch of 8, plus a
  refine round only for the cards that actually failed.

A batch of 8 with two failures now costs 3 model calls where it used to cost 16.

---

## Known bug in the 1 September build, stated plainly

The match ends itself when the arena is momentarily empty of hostiles. The island
is configured as Free For All, so Fortnite counts the robots as rival
contestants and calls the show over the instant the last one dies. This was
diagnosed on 1 September, the cause is in the island's team setup rather than in
any Verse code, and the fix is in progress for the 8 September capstone build.
