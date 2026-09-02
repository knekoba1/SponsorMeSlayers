# ASSIGNMENT #10 — COMPLETE AI DEV PIPELINE

**STATUS:** Mandatory
**DUE DATE:** 1 Sept 2026, 11:59 PM ET

---

## STUDENT & GAME OVERVIEW

**Student Name:** Kailee Nekoba

**Capstone Game Title:** Sponsor Me, Slayers!

**Game Concept Brief:**
A top-down twin-stick arcade shooter built in Unreal Editor for Fortnite (UEFN)
in the Verse language. The player is a contestant on a dystopian televised game
show, fighting waves of cybernetic hostiles inside a single-room stadium arena.
Movement is decoupled from aiming, so you run one way and shoot another, and
circling and kiting is the whole game. Killing a hostile bursts it into cash and
retro appliances; collecting those fills a Hype Meter; crossing a Hype threshold
makes the simulated audience parachute a supply crate in. The pipeline's job is
the numbers behind that fight: the stat ladders that decide how tough each wave
of hostiles is, which is what makes the Pipeline-to-Game connection checkable.

---

## DELIVERABLE 1: PLAYABLE LINK

**Playable Game Link:** https://knekoba.itch.io/sponsor-me-slayers

The page carries a 90-second gameplay walkthrough of the 1 September build. The
game is a Fortnite island, so it cannot be a WebGL build or a Windows download.
This is the route the instructor approved in Class 13 for a project that could
not be web-playable: publish the page, put the walkthrough on it.

**Why there is no island code alongside it.** Two gates, neither of them the
build. Publishing an island into Fortnite requires signing the Fortnite Developer
Terms, which carries a cost I cannot cover this week, and publishing puts the
island in front of Epic's own review before anyone can launch it. I also need
sign-off from my studio before putting anything out under those terms, and that
request is in. The island itself is complete and runs end to end every time it is
launched from the editor, which is what the video shows. When both gates clear,
the same island publishes and the code goes onto this same page.

---

## DELIVERABLE 2: PIPELINE SOURCE CODE & ENGINE INTEGRATION

**Pipeline Repository Link:** https://github.com/knekoba1/SponsorMeSlayers

**Pipeline Run Video Link:** https://knekoba.itch.io/sponsor-me-slayers
(two run recordings, under Downloads on that page)

- **Pipeline run - GER refiner and circuit breaker.** The Cyber-Boar ladder is
  re-checked against a 5.0 m/s player run speed instead of the assumed 6.0, so a
  real card fails a real rule. The Evaluator cites GDD 5.5, GDD 2.2 and Amendment
  8 by name for each of nine breaks, the Refiner repairs the ladder to 10/10, and
  a stubborn stand-in generator then trips the circuit breaker after three
  attempts and escalates instead of looping. It ends with both guardrails PROVEN
  and the repaired ladder printed.
- **Pipeline run - Style Guide crew.** A Sponsor Aid card scores 2/10, the local
  checker catches the banned generic words 'magic', 'hero' and 'monster', and the
  Refiner rewrites the card into the show's own voice until it clears.

The repository holds the game and the agents in the same tree, so a prompt change
and the code it produced are version-controlled together:

| Where | What it is |
|---|---|
| `pipelines/assignment-06-ger/` | The GER pipeline: Generator, Evaluator, Refiner, circuit breaker |
| `pipelines/assignment-07-style/` | The Style Guide crew: Proposer, Adversarial Critic, Judge, Evaluator, Refiner |
| `pipelines/assignment-09-adversarial/` | Adversarial QA: twelve attacks and eleven continuously-watched invariants |
| `pipelines/announcer-bark/` | The bark database and its triggers. Deliberately has no language model in it |
| `.claude/agents/` | The four in-project agent roles: Gameplay Systems, Simulated Audience, Announcer Bark, Playtest QA |
| `Content/*.verse` | The 24 Verse scripts the agents wrote and the designer approved |

### INTEGRATION BREAKDOWN

**Target Game Engine:** Unreal Editor for Fortnite (UEFN), Verse.

**Automated Flow Description:**
The GER pipeline reads the GDD and the recorded amendments, generates fifteen
hostile stat cards, and writes `output/tier-cards.csv` — one row per card, with
health, walk / run / sprint speed, and how many of that type may be alive at
once. The Evaluator then re-derives every number in plain Python and rejects any
card that breaks a rule traceable to a sentence in the GDD: 8% difficulty per
tier compounded, no card past Escalation Tier 21, never more than 40 hostiles
alive, sprint speed always below the player's run speed. Rejected cards go back
to the Refiner with the failing rule attached, and a circuit breaker stops the
loop rather than letting it spin.

Wave pacing, concurrency and the tier ramp are then read directly by
`Content/WaveManager.verse`, which drives the four spawners at runtime with no
reformatting: the script consumes the pipeline's own shape and it functions in
the scene as shipped.

**On the data path from pipeline output to build there is exactly one manual
step, documented rather than hidden:** typing a validated stat row onto its
`npc_character_definition` asset, because per-hostile health and movement speed
live on a UEFN editor asset and Verse cannot write one. The other two manual jobs
listed below are not on that path: placing devices is level construction, and
writing the announcer's lines is hand-authored on purpose.

---

## DELIVERABLE 3: PIPELINE AUDIT & COST ANALYSIS

### Pipeline Production & Functionality

**What did the pipeline produce?**

- **Fifteen hostile stat cards**, five each for the Cyber-Boar, the Ranged
  Sentinel and the Ranged Tank — three enemy types the GDD names and the game did
  not have. Their health, speed and concurrency ladders across Escalation Tiers
  1 to 21 are the pipeline's output, and all three types fight you in the build.
  The evaluator earned its place on these: it failed the Cyber-Boar Tier 5 card
  against Amendment 8 by 0.02 m/s at a 5.0 m/s player run speed, a margin no
  playtest would ever feel but which decides whether kiting survives on a slower
  build.
- **The wave pacing and concurrency ramp** consumed by `WaveManager.verse`: how
  many hostiles a wave contains, how many may be alive at once, and how both
  scale per tier.
- **Crate pickup cards** from the Style Guide crew: the text shown when a supply
  crate is opened, held to the show's voice by an adversarial critic and a
  deterministic checker. Every rule the crew enforces traces to the GDD or a
  dated amendment, including the never-comfort rule, where a line that would
  genuinely reassure a contestant is an automatic failure because the Network's
  cruelty dressed as generosity is the joke. The loop re-scans rather than
  filtering once: on one card a corrected line still contained the banned word
  'brave' and tripped the checker again on the second pass.
- **Adversarial QA findings** that drove real fixes. Twelve scripted attacks
  push the contestant through every wall, under the floor, thirty metres up and
  onto each spawner, while eleven invariants are watched continuously and
  independently. The run produced 148 high-severity findings, and two of them
  are live defects in the build the grader can see named here rather than
  discovered later: GDD 5.5's three-metre spawn safety radius is not enforced at
  all, with eight robots spawning inside it and one at 124cm, because nothing in
  the WaveManager loop checks distance; and cash is collectable from outside the
  arena wall.

**What manual steps remain?**

1. **Entering a stat card onto its `npc_character_definition` asset.** Fifteen
   rows, typed against fifteen editor assets. This is the one on the data path.
2. **Placing devices in the map.** Spawners, audio players, the crate pad.
3. **Writing the announcer's barks.** Manual on purpose, not a gap. The revision
   log fixes the commentator's lines as hand-written by the designer, so the bark
   pipeline structures, maps and plays them but never generates their text.

**What would it take to eliminate them?**

Steps 1 and 2 are blocked by the engine, not by the pipeline: Verse cannot create
or edit a UEFN asset and cannot place an actor, and both are editor operations
with no scripting surface. Two things would close it:

- **Nearest-term, and worth doing:** stop emitting a CSV a human retypes and emit
  a Verse source file instead, a typed array of stat structs the compiler reads
  directly. The numbers then land in the build with no reformatting and no
  retyping. This needs nothing Epic has not already shipped.
- **To close it fully:** an MCP server for UEFN that can write `.uasset` property
  values and place actors. Unreal 5.8's Model Context Protocol is the shape of
  this, and UEFN does not expose it yet.

Step 3 stays manual by design and should not be automated.

**Two weaknesses in the pipeline itself, carried in from instructor feedback on
earlier submissions and named here rather than left for the grader to find.**
First, the Evaluator's most important rule leans on an assumption: the player's
run speed is a constant in the settings file, defaulted to 6.0 and re-tested at
5.0, rather than a number read out of the player controller. The Evaluator can
therefore pass a card that fails in the live build. The fix is to read that value
from the game at build time and feed it in, which turns the speed rule from an
assumption into a measurement. Second, the adversarial QA report ranks by
severity but not by cause, so 124 boundary-break rows crowd out the two findings
that actually matter; collapsing them to the handful of distinct walls and
corners producing them would put the safety-radius and cash defects at the top
where they belong.

### Architectural Reflection

**Current Architectural Decision to Change:**
Making the pipeline's deliverable a spreadsheet. `output/tier-cards.csv` is easy
to read and easy to grade, and it was the obvious artefact to produce. But a
spreadsheet is not something a game engine can eat. It made a human the transport
layer between a validated number and the asset that uses it, which is exactly the
manual friction this assignment asks about, and it means the pipeline's
guarantees stop at the file boundary: the Evaluator can prove a card is legal and
a typo can still enter the game.

**Specific Alternative:**
Emit `Content/HostileStatCards.verse` instead of, or alongside, the CSV: a
generated Verse file containing a `hostile_stat_card` struct and a typed array of
fifteen literals, with a header comment naming the run that produced it.
`WaveManager.verse` reads that array the way it already reads its other tables.
The Verse compiler then becomes a second, free evaluator, because a malformed row
fails the build instead of reaching a playtest. Regenerating becomes a pipeline
run plus Build Verse Code, with nothing typed by hand, and the manual step
disappears for every hostile type at once.

### Cost Analysis

**Total Actual Run Cost:** **$0.00 in metered charges.** Every pipeline run for
this capstone, including the two recorded tonight, executed through Claude Code
against a Claude subscription on this machine. No API key is wired into any of
the four pipelines, so no run was billed per token. The honest full figure is the
subscription itself: one $20/month Claude plan across the seven weeks. A separate
$5 of Anthropic API credit was bought on 25 August for the optional Assignment 8
narrative engine, which is a standalone project outside this repository and not
part of the capstone pipeline.

**Most Expensive Pipeline Step:** The Refiner round in the Style Guide crew.
Everything else there is either a single batched call or free: the hard checks
are plain Python, and the Proposer returns eight variations in one JSON reply.
But a card that fails verification costs a complete evaluate-and-refine round
trip, with the card, the failing rule and the style guide all back in context,
and a card can fail more than once. It is the only step whose cost scales with
how badly the model did. Tonight's recording shows exactly that: a card at 2/10
needing two rewrites before it cleared. The instrumentation this is missing, and
the next thing to add, is a log of which specific rule each rewrite closed, which
would show whether the Refiner fixes violations in a stable order or thrashes
between them. That is the difference between knowing this step is the most
expensive and knowing why.

**Solo/Small-Team Sustainability:** Yes, and specifically because of the split.
Nothing a computer can decide arithmetically is ever asked of a model. The
Evaluator that enforces 8% per tier, the 40-hostile ceiling and the speed rule
contains no AI at all; it is arithmetic that runs locally, costs nothing per
check, and runs first, before any model is called. The model is paid for
judgement and voice, which is the part it is good at. That keeps the bill flat as
content grows: doubling the number of stat cards doubles the free arithmetic and
adds one batched call, not fifty. On a $20 subscription this is sustainable for a
solo developer indefinitely.

### Mid-Project Cost-Reduction Change

**Strategy/Prompting Approach — Before:** The Proposer was asked for one card at
a time, and the model was also asked to check its own arithmetic against the GDD
rules. Every card cost its own round trip, and verification cost another on top.

**Strategy/Prompting Approach — After:** The Proposer returns a whole batch of
variations in a single JSON reply, and the arithmetic check was taken away from
the model entirely and rewritten as plain Python that runs locally. The model is
now asked only for what arithmetic cannot settle: whether a line sounds like the
show, and whether a card is interesting.

**Token / API Cost — Before:** 8 generation round trips per batch of 8, plus 1
verification round trip per card: **16 model calls to land a batch of 8.**

**Token / API Cost — After:** 1 batched generation round trip, plus 0
verification calls because verification moved to local Python, plus a refine
round only for cards that actually failed: **3 model calls to land the same batch
of 8 with two failures.**

Measured in model round trips, which is what this project logged. The runs were
on a subscription rather than a metered key, so there is no per-run dollar figure
to quote and inventing one would be dishonest.

---

## Known bug in the 1 September build, stated plainly

The match ends itself when the arena is momentarily empty of hostiles. The island
is configured as Free For All, so Fortnite counts the robots as rival contestants
and calls the show over the instant the last one dies. Diagnosed on 1 September;
the cause is the island's team setup rather than any Verse code, and the fix is
in progress for the 8 September capstone build. It is also noted on the itch
page.
