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
| Sprint speed stays **below the player's run speed** | Amendment 8, included as [`GDD-AMENDMENT-08-EXCERPT.md`](GDD-AMENDMENT-08-EXCERPT.md) |
| Speed scales at **2.1% per tier**, compounded | Amendment 8, same file |
| Run is **87.5%** of sprint, walk is **62.5%** | Amendment 8, same file |

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

`demo.py` proves the Refiner and the Circuit Breaker actually run, using the
real loop in `run.py`. See "Proof the Refiner and the Circuit Breaker run" below.

---

## How to run it

```
python run.py
```

Claude is reached through the `claude` command line tool already installed and
logged in on this machine, so there is no API key and no per-run cost.

Two files are written to `output/`:

- `tier-cards.csv` — the cards, opens in Excel
- `evaluator-report.txt` — every check the Evaluator made on this run

All three ladders passed first time, so that report contains no failures and no
repairs. To see the Refiner and the Circuit Breaker actually run, use `demo.py`,
described below.

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

All three ladders passed on the first attempt at the assumed player run speed of
6.0 m/s. The Generator produced correct 8%-per-tier compounding across all
fifteen cards, and the Evaluator confirmed it without spending a token.

The useful finding came from re-running the same fifteen cards against a
different assumption. `GDD_AMENDMENTS.md` item 8 records that the player's run
speed has never been measured, and names the risk: "If the real figure is nearer
5.0 than 6.0, then T4 at 5.1 and T5 at 5.6 both outrun the player outright."

Re-running the Evaluator with `PLAYER_RUN_SPEED = 5.0`:

```
===== if the player's real run speed is 6.0 m/s =====
PASS  Heavy Ranged Tank  (10/10)
PASS  Ranged Sentinel    (10/10)
PASS  Cyber-Boar         (10/10)

===== if the player's real run speed is 5.0 m/s =====
PASS  Heavy Ranged Tank  (10/10)
PASS  Ranged Sentinel    (10/10)
FAIL  Cyber-Boar          (6/10)
       CyberBoar_T5: sprint 5.02 m/s is at or above the player's run speed
       of 5.0 m/s. Kiting becomes impossible (GDD 2.2), and the Career
       Sponsor Rank ladder flattens (GDD 2.6).
```

**The Cyber-Boar's top card misses by 0.02 m/s.**

The finding is not that the Generator made an arithmetic mistake. It did not.
It is that one of the three new hostiles is balanced on a number nobody has
measured, and it fails by two hundredths of a metre per second. The Ranged Tank
tops out at 3.068 and the Sentinel at 0.837; both have room either way. The
Cyber-Boar does not.

By hand this is fifteen cards against two assumptions, with the failure margin
0.02 wide. The pipeline answered it in under a second, and re-checking after the
real measurement is a one-number change.

**Consequence:** the Ranged Tank and Ranged Sentinel ladders are safe to build
in UEFN now. The Cyber-Boar ladder is not, until the player's run speed is
measured with `fort_character.GetLinearVelocity()` as Amendment 8 describes.

---

## Proof the Refiner and the Circuit Breaker run

All three ladders passed first time, which is good for the game and bad for
evidence: `evaluator-report.txt` shows the Generator and the Evaluator working,
and nothing else. `demo.py` exercises the other two parts. It calls the real
loop inside `run.py` rather than a copy of it, so what is proven is the shipped
code.

    python demo.py

Output: `output/demo-refiner-and-breaker.txt`.

### Part 1, the Refiner repairing a real failure

The real Cyber-Boar ladder from `tier-cards.csv`, checked against a 5.0 m/s
player run speed instead of the assumed 6.0. The Evaluator fails it at 6/10 on
the 5.020 top card. The Refiner gets one real Claude call and fixes it on the
first attempt:

| Card | Sprint before | Sprint after | Health before | Health after |
|---|---|---|---|---|
| T1 | 3.600 | 3.500 | 75 | 75 |
| T2 | 3.912 | 3.803 | 102 | 102 |
| T3 | 4.251 | 4.133 | 139 | 139 |
| T4 | 4.620 | 4.491 | 189 | 189 |
| T5 | **5.020** | **4.881** | 257 | 257 |

It lowered the Tier 1 speed by a tenth and recomputed the ladder from there,
leaving health untouched. It did not flatten the difficulty curve and it did not
raise the player's speed, which are the two lazy fixes the Refiner prompt
explicitly forbids.

These are not replacement cards. The player's run speed is still unmeasured, so
the shipped ladder in `tier-cards.csv` stands. This is what the pipeline would
produce the moment that number is measured at 5.0.

### Part 2, the Circuit Breaker escalating

A circuit breaker only fires when the loop cannot self-correct, and every rule in
this game is satisfiable, so a fair run will never trip it. Part 2 therefore uses
a stubborn stand-in generator that hands back the same broken ladder every time
it is asked to fix it. No Claude calls, no cost, identical result on every run.

That is the failure a circuit breaker exists for: not a bad rule, but an AI that
keeps confidently returning the same wrong answer.

The loop fails at 3/10 with nine named violations, tries three repairs, gets the
identical 3/10 back each time, and stops:

    CIRCUIT BREAKER TRIPPED after 3 refine attempts.
    Escalated to Kai. No cards written for this hostile.

Nothing was written to the spreadsheet for that hostile, which is the point. The
pipeline hands the problem back rather than ship a card that breaks GDD 5.5.

---

## Scope note

`PRE-BUILD-DECLARATION.md` commits to four hostile types where GDD §5.4 budgets
two. That is a deliberate divergence, decided by the designer on 2026-08-16, and
it needs its own entry in `GDD_AMENDMENTS.md`.
