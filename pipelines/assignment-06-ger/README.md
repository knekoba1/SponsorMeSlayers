# Assignment 6 — GER Pipeline

**Game:** *Sponsor Me, Slayers!* — a top-down twin-stick arcade shooter built in
Unreal Editor for Fortnite (UEFN) using the Verse language.

**Author:** Kailee Nekoba

---

## Pre-Build Declaration

Submitted before any code was written. Full text in
[`PRE-BUILD-DECLARATION.md`](PRE-BUILD-DECLARATION.md); the three answers are:

**1. What content does my game generate manually, inconsistently, or not at all?**
Hostile stat cards. Each card sets an enemy's health, movement speed and spawn
density for a block of Escalation Tiers. My five Cyber-Swarmer cards were made
by hand, one at a time. The second hostile promised in GDD 5.4 was never built
at all, and I am adding three types (Ranged Tank, Ranged Sentinel, Cyber-Boar).
That is fifteen more cards.

**2. What specific GDD rule must every card satisfy?**
GDD 5.5: difficulty rises by exactly 8% per tier, hard-capped at Escalation
Tier 21. GDD 5.3: never more than 40 hostiles alive at once. Plus my recorded
clarification of 5.5: movement speed must stay below the player's run speed.

**3. What does failure look like, concretely?**
A card that outruns the player. Kiting becomes impossible (GDD 2.2), and the
Career Sponsor Rank ladder flattens (GDD 2.6) because every run then ends at the
same tier regardless of skill.

---

## What the pipeline generates

Fifteen hostile stat cards: a five-card difficulty ladder for each of three
enemy types the GDD names but the game does not yet have.

Movement speed lives on the `npc_character_definition` and cannot be changed
while the game is running, so five cards cover all 21 Escalation Tiers in blocks
of four — the same structure the existing Cyber-Swarmer ladder uses.

Output is a spreadsheet (`output/tier-cards.csv`) with one row per card:
health, walk / run / sprint speed, and how many may be alive at once.

---

## What the Evaluator enforces

The Evaluator contains **no AI**. It is arithmetic, run locally, costing nothing
per check. Every rule traces to a sentence a grader can find in the project's own
documents:

| Rule | Source |
|---|---|
| Health rises by **exactly 8% per tier**, compounded | `Kailee_Nekoba_GDD_Final_Draft.pdf` §5.5 |
| No card reaches past **Escalation Tier 21** | GDD §5.5 |
| Never more than **40 hostiles** alive at once | GDD §5.3 |
| Sprint speed stays **below the player's run speed** | `GDD_AMENDMENTS.md` item 8 |
| Speed scales at **2.1% per tier**, compounded | `GDD_AMENDMENTS.md` item 8 |
| Run is **87.5%** of sprint, walk is **62.5%** | `GDD_AMENDMENTS.md` item 8 |

The Evaluator returns a **score out of 10 and a written reason**, not a bare
pass/fail, so the Refiner has something specific to act on.

---

## The four parts

| Part | File | What it does |
|---|---|---|
| **Generator** | `generator.py` | Asks Claude for a five-card ladder for one hostile |
| **Evaluator** | `evaluator.py` | Checks it against the GDD rules above. No AI. |
| **Refiner** | `refiner.py` | Hands Claude the failures and asks for a fix |
| **Circuit Breaker** | `run.py` | After 3 failed repairs, stops and escalates to the designer instead of writing a broken card |

`settings.py` holds every tunable number. Nothing is buried in the code.

---

## How to run it

```
python run.py
```

Claude is reached through the `claude` command line tool already installed and
logged in on this machine, so there is no API key and no per-run cost.

Two files are written to `output/`:

- `tier-cards.csv` — the cards, opens in Excel
- `evaluator-report.txt` — every check, every failure, every repair

---

## How the output reaches the game

The pipeline **cannot touch the game**. It writes a spreadsheet and stops.

Integration is by hand, which is deliberate: GDD §4.1 makes the human designer
"an absolute checkpoint between handoffs," with output "manually audited,
approved, and integrated by the designer." The steps are:

1. Run the pipeline.
2. Open `tier-cards.csv` and read it.
3. In UEFN, create a new `npc_character_definition` per card.
4. Type the health and speed values in.
5. Wire a spawner per hostile type — `WaveManager.verse:424` records that
   `SetNPCCharacterDefinition` fails when the character type differs, so each
   type needs its own spawner rather than sharing `TierDefinitions`.

---

## A known limitation, stated up front

**The player's run speed has never been measured.** `settings.PLAYER_RUN_SPEED`
is set to 6.0 m/s, an assumption recorded in `GDD_AMENDMENTS.md` item 8: a
Fortnite base of about 5.0 m/s times the 1.2 Movement Speed Multiplier on the
Third Person Controls device.

Every speed ceiling in this pipeline rests on that number. When it is measured,
changing the single value in `settings.py` and re-running corrects all fifteen
cards in seconds. Doing that by hand would mean recomputing sixty numbers.

---

## What the pipeline caught

*(Filled in after the first run — see `output/evaluator-report.txt` for the
complete log.)*

---

## Scope note

`PRE-BUILD-DECLARATION.md` commits to four hostile types where GDD §5.4 budgets
two. That is a deliberate divergence, decided by the designer on 2026-08-16, and
it needs its own entry in `GDD_AMENDMENTS.md`.
