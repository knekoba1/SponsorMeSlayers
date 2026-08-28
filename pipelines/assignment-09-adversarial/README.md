# Assignment 9 — Adversarial QA Agent

**Kailee Nekoba**
**Game:** *Sponsor Me, Slayers!* — a top-down twin-stick arcade shooter built in UEFN
**Harvested:** 2026-08-28, one editor log holding **two runs**, 01:39 to 02:03
**Result:** 302 raw findings, **148 rows** after folding repeats, across five systems

---

## What it is

An agent that lives inside the game and spends the whole match trying to break it.

It runs as a Verse device, `AdversarialTester.verse`, placed in the arena. It is not
playing badly on purpose; for most of its cycle it is not playing at all. It runs **twelve
attacks** on a loop and watches **eleven invariants** continuously, and the two halves are
independent, so a fault the ordinary game causes on its own is caught alongside the ones the
attacks provoke.

### The twelve attacks

| Code | What it does |
|---|---|
| A-01 to A-04 | Puts the contestant four metres past each of the four walls and leaves them there |
| A-05 | Drops them on all four corners, exactly on the line where two walls meet |
| A-06 | Puts them five metres under the floor |
| A-07 | Puts them thirty metres above the arena and watches the landing |
| A-08 | Stands them on each robot spawner in turn |
| A-09 | Teleports them side to side twenty times in two seconds |
| A-11 | **Walks** a full lap of the arena just inside the walls, in 120 cm steps |
| A-12 | **Sweeps** the whole floor lane by lane, collecting whatever is on it |
| A-13 | Returns them to the middle, so one attack never poisons the next |

A-11 and A-12 are the movement and the interaction. They were added after watching a run:
everything else blinks the contestant somewhere illegal, which is boundary-probing and
nothing else. A-11 travels legally at speed and brushes every wall on the way past. A-12 is
how the agent *interacts* — cash is collected on contact (GDD 2.3) and a crate opens on
contact (GDD 3.2), so covering the floor touches everything on it without needing a list of
what is lying about. Both run with the "I am attacking" flag **off**, so they are held to
every invariant rather than excused from them.

### What "broken" means

Eleven invariants, each one a promise the GDD or a project house rule already makes. This is
the agent's strategy: it never judges whether something *looked* wrong. It checks a written
promise and reports the promise that failed.

| Check | The promise | Source |
|---|---|---|
| INV-01 | No hostile is outside the arena | GDD 1.1, a single room |
| INV-02 | No hostile stands still indefinitely | stuck state |
| INV-03 | Never more than 40 hostiles alive | GDD 5.5 hard cap |
| INV-04 | Hype stays between 0 and 100 | GDD 3.1 |
| INV-05 | The contestant never *remains* outside | GDD 1.1 |
| INV-06 | Health never exceeds its maximum | exploit tell |
| INV-07 | The Escalation Tier never passes 21 | GDD 5.5 hard cap |
| INV-08 | Nothing spawns within 3 metres of the contestant | GDD 5.5 |
| INV-09 | The run score never goes backwards | accounting break |
| INV-10 | The tier never goes backwards mid-run | accounting break |
| INV-11 | Cash is never claimed from out of bounds | exploit |

### How a finding gets out

Verse cannot write a file. Each finding is one pipe-delimited line in the UEFN session log
behind an `ADVQA` marker, and `harvest.py` reads the log and writes `report.json` and
`report.csv`. Every row carries **location**, **error type** and **game context**, plus the
check that fired, a severity, the system to blame, which run it came from, and how many
seconds in it happened.

Two things the harvester does that matter for reading the report:

- **It splits runs.** UEFN keeps one log per *editor session*, not per playtest, so one log
  held both runs. Every row is tagged `session 1` or `session 2`.
- **It folds repeats.** Some invariants describe a *state*, not an instant: while the
  contestant is outside the room, INV-05 is true at every look. Left alone that is hundreds
  of rows for what a developer would call one escape. Consecutive repeats of the same check
  collapse into one row with `occurrences` and the seconds it ran from and to — 302 raw
  lines become 148 rows.

---

## What the agent found

**148 findings across five systems.** Every one high severity.

| Error type | Rows |
|---|---|
| `BOUNDARY_BREAK` | 124 |
| `OUT_OF_WORLD` | 13 |
| `SAFETY_RADIUS_BREACH` | 8 |
| `OUT_OF_BOUNDS_PICKUP` | 3 |

### 1. Robots spawn on top of the player. GDD 5.5's safety radius is not enforced.

The strongest finding, and nothing else had caught it. GDD 5.5 blocks a spawn within a
**3-metre safety radius** of the player. While A-08 stood the contestant on the Swarmer
spawner, eight robots appeared inside that radius. The distances, in centimetres:

```
124  124  125  125  125  125  177  231
```

124 cm is a metre and a bit. The rule is not being applied at all — nothing in the wave spawn
loop checks the distance to the player before asking for a hostile.

*System:* `WaveManager` spawn loop. *Check:* INV-08. **Not yet fixed.**

### 2. Cash can be collected from outside the arena.

INV-11 caught the score rising from 0 to 10, 10 to 20, and 20 to 30 while the contestant was
standing **outside the west wall**. A pickup in this game is a collision (GDD 2.3), so cash
is both dropping outside the room and being claimable from there. It is a small exploit and a
real one: score without risk.

*System:* `cash_drop_manager`. *Check:* INV-11.

### 3. Nothing brings the player back, and under the floor they fall forever.

A-01 through A-04 put the contestant four metres past each wall and waited. **All four sides
reported**, and A-06 dropped them under the floor thirteen times, reaching **Z = -3,825** and
still going, with the run carrying on as though the contestant were still in the room.

**The honest reading, which matters.** The agent got out by *teleporting*, and no player can
teleport. A-11's perimeter lap walked the entire boundary twice in 120 cm steps and never
escaped once, so **the walls do hold against walking.** The real finding is not that the room
leaks, it is that the game has no recovery: however you end up outside — a rocket blast, the
shotgun's own chain knockback, a fall through the floor — nothing ever puts you back.

*System:* arena collision and floor collision. *Checks:* A-01 to A-04, A-06, INV-05.
**Fixed as a result:** a containment guard now checks the contestant four times a second and
clamps them back just inside the nearest wall.

### 4. Robots outside the arena, found from a rule rather than a hunch.

INV-01 caught hostiles standing outside the west wall twelve times. This one was already
suspected from an earlier playtest. What matters is that the agent found it **without being
told to look there**, because a written promise failed rather than because anything looked
odd on screen.

*System:* `SwarmerSpawner` / `WaveManager`. *Check:* INV-01.

### What did not break, which is also a result

- **A-05, the corners.** Corner drops in both runs, no escape.
- **A-07, the thirty-metre fall.** Fall damage applied every time.
- **A-09, twenty teleports in two seconds.** Nothing miscounted or desynced.
- **A-11, the perimeter lap.** Two full circuits walked, nothing.
- **A-12, the floor sweep.** Whole floor covered, no double-claim, no crate misfire.
- **INV-02, 03, 04, 06, 07, 09, 10 never fired.** No stuck hostiles this time, never more
  than 40 alive, Hype stayed in range, health never exceeded its maximum, the tier never
  passed 21, and neither the score nor the tier ever went backwards.

---

## Were the findings a surprise?

**Yes — the safety radius one.** In Kai's words: *"the safety radius one, I thought that was
working."*

It went into the GDD at the start and was never questioned again, so it had quietly become an
assumption rather than a fact. Nothing on screen announces that it failed: a robot appearing
a metre away during a busy wave just reads as a robot that walked there. It took an agent
standing deliberately on the spawner — something no player would ever do — to make it
visible, and even then it only showed because a *number* was being compared to a *written
rule* rather than because anything looked wrong.

The out-of-bounds pickup was a smaller surprise of the same kind. Nobody had asked whether
cash could be reached from outside the room, because nobody had considered being outside the
room.

The walls were the least surprising, since a robot getting stuck outside the arena had
already cost a playtest that same day. What was new was the *scale*: not one weak spot on the
west side but all four walls and the floor, and no recovery from any of them. That one is
already fixed.

### What the agent taught me about writing a QA agent

The findings that mattered came from **invariants, not attacks**. The attacks were only there
to put the game somewhere unusual; every genuinely new bug — the safety radius, the
out-of-bounds pickup, the robots outside the room — was caught by a rule being checked, not by
something looking broken. Writing down what "broken" means, before writing the agent, was the
part that did the work.

---

## The files

| File | What it is |
|---|---|
| `AdversarialTester.verse` | The agent. Twelve attacks, eleven invariants, runs inside the game |
| `harvest.py` | Reads the newest UEFN log, splits runs, folds repeats, writes the report |
| `report.json` | The structured report from the two runs described above |
| `report.csv` | The same rows as a spreadsheet |

Run it with:

```
python harvest.py
```

The agent is switched **off** by default. `RunAdversarialTest` on the placed device turns it
on, and it must stay off for an ordinary playtest, because the agent drives the contestant
and nobody can aim while it does.

### Known limitation

INV-05 reports once per look while the contestant is outside rather than once per escape, and
the folding in `harvest.py` is what makes the report readable. Latching it in the agent itself
would be the better fix and is not done.
