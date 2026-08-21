# Assignment 7, Style Guide Agent

**Game:** *Sponsor Me, Slayers!*, a top-down twin-stick arcade shooter built in
Unreal Editor for Fortnite (UEFN) using the Verse language.

**Author:** Kailee Nekoba

---

## Pipeline connection

This Style Guide Agent runs immediately after the Simulated Audience decides which
item a paraglider crate is carrying, checking and correcting that item's four-line
pickup card before the text is typed into the UEFN HUD device.

---

## What content this agent governs

**Crate pickup cards.** GDD 3.2 says supply crates "trigger instantly upon player
collision to maintain momentum", so the readout naming what was just grabbed is on
screen for a moment and then gone. Nine items exist across the four crate tiers,
and not one of them had its pickup text written.

These are user interface item cards. They are deliberately **not** announcer
barks: the 25 sarcastic commentator lines are hand-written by the designer, and no
agent in this project is permitted to draft or rewrite them.

A card looks like this:

```
ITEM: Sponsor Aegis
SLOT: Shield
PLUG: Three whole hits of protection, generously donated by people watching you die.
EFFECT: Absorbs exactly 3 hostile hits, with no timer, then pops.
```

---

## The capstone-anchored style guide

Every rule traces to a sentence in `Kailee_Nekoba_GDD_Final_Draft.pdf` or a dated
ruling in `GDD_AMENDMENTS.md`. Nothing was invented for this assignment. The
machine-readable version lives in [`settings.py`](settings.py), which is the single
copy both the Evaluator and the Refiner read, so the two can never drift apart.

### Constraint type 1: game vocabulary and lore accuracy

| Rule | Source |
|---|---|
| Items, hostiles and systems use their exact in-world names (Sponsor Aegis, Sponsor Aid, Icy Rounds, Cyber-Swarmer, Cyber-Boar, Ranged Sentinel, Hype Call, Escalation Tier, Death Save) | GDD 3.3, GDD 5.4 |
| The person playing is "the contestant"; the organisation is "the Network" | GDD 1, Contestant and Enemy Lore |
| The four slot names are Weapon, Consumable, Shield, Ammo Modifier | GDD 3.2 |
| The EFFECT line must agree with the item's real behaviour, down to the numbers | GDD 3.3, amendments 38 to 44 |
| Twenty-two generic fantasy and shooter words are banned outright, including potion, mana, hero, monster, hit points, buff and power-up | The rubric's Specificity rule, read against GDD 1 |

The banned list is the direct answer to "if a stranger can't tell exactly what game
the rules are for". A televised debt-collection blood sport does not sell potions.

### Constraint type 2: tone and voice

| Rule | Source |
|---|---|
| The PLUG line is the Network's own advertising copy: upbeat and salesy about something plainly terrible for the contestant | GDD 1, "corporate hostility and glitz are played for laughs" |
| Never sincere, never heartfelt, never earnest | GDD 1, "the Network notoriously never pays survivors" |
| Comedy, never menace, horror or gore | GDD 1, "broad, self-aware game-show comedy in the tradition of Smash TV and Total Carnage" |
| No heroic or epic register; the contestant is a debtor on television | GDD 1, contestants volunteer "to escape crushing financial debt" |
| The EFFECT line is the opposite voice: flat, factual, exact. The joke is the gap between the two lines | House rule derived from the two above |

### Constraint type 3: format and length

| Rule | Source |
|---|---|
| Exactly four lines: ITEM, SLOT, PLUG, EFFECT, in that order | GDD 2.4, written "to prevent HUD clutter" |
| PLUG and EFFECT are one sentence each, at most 90 characters | GDD 3.2, the pickup is instant, so the card must read at a glance mid-fight |
| At most one exclamation mark on the whole card | GDD 5.2, which protects comedic timing |
| No em dashes, bullets, markdown, emoji, or shouted capitals inside the prose | House formatting rule |

---

## The Evaluator and Refiner loop

```
Generator  ->  Evaluator  ->  passed?  ->  yes  ->  card accepted
                   ^                |
                   |                no
                   |                v
                   +----------  Refiner
```

Nobody steps in. The Refiner works only from the Evaluator's written reason, and
the loop runs until the card passes or the circuit breaker trips.

### The Evaluator returns a score and a reason, never a pass or a fail

It has two halves, on purpose:

1. **Hard checks**, run locally in plain Python with no AI and no cost. Line shape,
   character counts, exclamation marks, banned words, wrong slot, shouted capitals.
   These are facts, and a language model has no business having an opinion about
   them.
2. **The judgement**, run by Claude. Tone, voice, whether the copy sounds like the
   Network selling to a contestant it fully expects to die, and whether the EFFECT
   line agrees with the item's true behaviour.

The hard findings are handed to Claude so its written reason includes them, and
they also act as a floor: while a mechanical rule is broken the card cannot pass,
however generous the model feels. That capping is recorded in the reason text
whenever it happens.

### The Refiner

It receives the failing card and the Evaluator's REASON, and rewrites the card to
score a perfect 10. It never regenerates from scratch, so whatever was already
working survives.

### The circuit breaker

Three refine attempts. After that the card is handed back to the designer rather
than shipped off-brand. This is the same human checkpoint GDD 4.1 requires between
every agent handoff.

A card is accepted at **9 out of 10**, not 10. The last point is a judgement call
about whether a joke actually lands, and looping forever chasing it would burn
tokens for nothing. The Refiner is still asked for a 10 every time.

The Refiner is also told to aim for about 78 characters rather than the 90-character
ceiling. Language models cannot count characters reliably, and on a first run a card
was lost to the circuit breaker at 91 characters against a ceiling of 90. Aiming
short leaves room for the miscount, and the local checker still enforces the real
ceiling exactly.

---

## The three demonstrations

Each one steers the Generator into a **different** rule. On these three runs the
Generator is not shown the style guide, so the loop has to find the problem on its
own.

Examples 1 and 2 are handed the bare four-line card shape and nothing else, no tone
rules and no vocabulary list. That is deliberate: it isolates the violation, so
example 1 fails purely on tone and example 2 purely on vocabulary. Example 3 is
given no shape at all, which is how it fails on format and length.

| Example | Violation class | Item | How the Generator was misled |
|---|---|---|---|
| 1 | Tone and voice | Sponsor Aid | Told to write with genuine warmth, like a hospital charity describing emergency relief |
| 2 | Game vocabulary and lore accuracy | Sponsor Aegis | Told to use fantasy role-playing language: magic barrier, the hero, monsters, hit points |
| 3 | Format and length | Rocket Launcher | Told to write three flowing paragraphs of atmospheric prose with plenty of exclamation marks |

Every before, every score, every written reason, every intermediate rewrite and
every after is in [`output/before-after.md`](output/before-after.md). The raw
evaluator transcript is in `output/evaluator-log.txt`.

---

## How to run it

```
python run.py          the three graded demonstrations
python run.py --all    the demonstrations, then a finished card for all nine items
```

Claude is reached through the `claude` command line tool already installed on this
machine, so there is no API key and no per-call cost. This is the same transport
assignment 6 used.

`--all` writes the nine finished cards to `output/crate-cards.txt`. Nothing in this
folder touches the game: the cards are typed into UEFN by hand, which keeps the
designer as the checkpoint GDD 4.1 demands.

---

## Files

| File | What it is |
|---|---|
| `settings.py` | The style guide as data. The only file to edit to change what is enforced |
| `styleguide.py` | Renders the style guide into the text both agents are given, so they cannot drift |
| `generator.py` | The Generator, plus the one function that talks to Claude |
| `evaluator.py` | The Evaluator: local hard checks, then the Claude judgement, returning SCORE and REASON |
| `refiner.py` | The Refiner, which rewrites from the reason alone |
| `run.py` | The loop and the circuit breaker |
| `output/before-after.md` | The three graded demonstrations |
| `output/crate-cards.txt` | The nine finished cards, from `--all` |
| `output/evaluator-log.txt` | Every score and reason from the run |
| `output/style-guide-as-the-agents-see-it.txt` | The guide exactly as both agents receive it, generated from `settings.py`, so the rules enforced are provably the rules written down |
