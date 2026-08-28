# Assignment 9 — Adversarial QA Agent

**Kailee Nekoba**
**Game:** *Sponsor Me, Slayers!* — a top-down twin-stick arcade shooter built in UEFN
**Run harvested:** 2026-08-28, a 34-second session, 37 findings

---

## What it is

An agent that lives inside the game and spends the whole match trying to break it.

It runs as a Verse device, `Content/AdversarialTester.verse`, placed in the arena. It is
not playing badly on purpose; it is not playing at all. It cycles ten attacks forever and
watches ten invariants continuously, and the two halves are independent, so a fault the
ordinary game causes on its own gets caught alongside the ones the attacks provoke.

### The ten attacks

| Code | What it does |
|---|---|
| A-01 to A-04 | Puts the contestant four metres past each of the four walls and leaves them there |
| A-05 | Drops them on all four corners, exactly on the line where two walls meet |
| A-06 | Puts them five metres under the floor |
| A-07 | Puts them thirty metres above the arena and watches the landing |
| A-08 | Stands them on each robot spawner in turn |
| A-09 | Teleports them side to side twenty times in two seconds |
| A-10 | Returns them to the middle, so one attack never poisons the next |

### What "broken" means

Ten invariants, each one a promise the GDD or a project house rule already makes. This is
the agent's strategy: it does not guess at whether something looked wrong, it checks a
written promise and reports the promise that failed.

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

### How a finding gets out

Verse cannot write a file. Each finding is one pipe-delimited line in the UEFN session log
behind an `ADVQA` marker, and `harvest.py` reads the log and writes `report.json` and
`report.csv`. Every row carries **location**, **error type** and **game context**, plus the
check that fired, a severity, the system to blame, and how many seconds into the run it
happened.

---

## What the agent found

**37 findings in 34 seconds, across four systems. Every one of them high severity.**

### 1. Robots spawn on top of the player. GDD 5.5's safety radius is not enforced.

The strongest finding, and the one nothing else had caught. GDD 5.5 blocks a spawn within a
**3-metre safety radius** of the player. While A-08 was standing the contestant on the
Swarmer spawner, four robots appeared inside that radius in the space of two seconds:

```
7.4s   123.5 cm from the contestant
7.9s   125.3 cm
8.4s   176.8 cm
9.6s   231.1 cm
```

123 cm is a metre and a bit. The rule is not being applied at all — nothing in the wave
spawn loop checks the distance to the player before asking for a hostile.

*System:* `WaveManager` spawn loop. *Check:* INV-08.

### 2. None of the four walls hold the player.

A-01 through A-04 put the contestant four metres past each wall and waited a second and a
half. **All four sides failed.** The contestant was still outside every time, and INV-05
then kept reporting them out there for as long as they were left, 21 further times.

This is the honest reading of those 21: they are the *same* excursion the attack created,
not 21 separate escapes, because nothing moves the contestant back until the next attack.
The finding is that the game never recovers on its own, which it should.

*System:* arena collision. *Checks:* A-01, A-02, A-03, A-04, INV-05.

### 3. Under the floor, you fall forever.

A-06 put the contestant five metres below the floor. Thirty seconds into the run they were
at **Z = -3,163** and still going, on 175 health of 300. Nothing killed them, nothing
returned them, and the run simply continued with the contestant gone.

*System:* arena floor collision. *Check:* A-06.

### 4. Robots outside the arena, confirmed independently.

INV-01 caught hostiles standing at five distinct spots outside the west wall, around
X = -1,360. This one was already suspected from an earlier playtest; what matters here is
that the agent found it **without being told to look**, from a rule rather than a hunch.

*System:* `SwarmerSpawner` / `WaveManager`. *Check:* INV-01.

### What did not break, which is also a result

- **A-05, the corners.** Four corner drops, no escape. Corner collision is sound.
- **A-07, the thirty-metre fall.** Fall damage applied. No free traversal.
- **A-09, twenty teleports in two seconds.** Nothing miscounted, nothing desynced.
- **INV-03, INV-04, INV-06, INV-07, INV-09, INV-10.** The caps and counters all held: no
  more than 40 alive, Hype stayed in range, health never exceeded its maximum, the tier
  never passed 21, and neither the score nor the tier ever went backwards.

---

## Were the findings a surprise?

**Yes — the safety radius one.** In Kai's words: *"the safety radius one, I thought that was
working."*

It was written into the GDD from the start and never questioned again, so it had quietly
become an assumption rather than a fact. Nothing in the game announces that it failed: a
robot appearing a metre away during a busy wave reads as a robot that walked there. It took
an agent standing deliberately on the spawner — something no player would ever do — to make
the failure visible, and even then it only showed up because a *number* was being checked
against a *written rule* rather than because anything looked wrong on screen.

The walls were less of a surprise, since a robot getting stuck outside the arena had already
cost a playtest that same day. What was new was the scale: it is not one weak spot on the
west side, it is **all four walls and the floor**.

---

## The files

| File | What it is |
|---|---|
| `../../Content/AdversarialTester.verse` | The agent. Ten attacks, ten invariants, runs inside the game |
| `harvest.py` | Reads the newest UEFN log and writes the report |
| `report.json` | The structured report from the run described above |
| `report.csv` | The same findings as a spreadsheet |

Run it with:

```
python harvest.py
```

The agent is switched **off** by default. `RunAdversarialTest` on the placed device turns it
on, and it must stay off for an ordinary playtest, because the agent drives the contestant
and nobody can aim while it does.
