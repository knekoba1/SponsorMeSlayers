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

### Two things the class asked for, and where they are

**A fresh context for the Evaluator (Class 8).** The instructor's generator-evaluator
contract is that the agent which wrote the content must never be the agent that reviews
it, because "the agent that created the initial code has all the generation process still
in its memory" and will approve its own work. Every call in this pipeline is a separate
invocation with no shared conversation, so the Generator, the Evaluator and the Refiner
each start from nothing and see only what they are handed. No agent here ever grades its
own draft.

**Deterministic checks before the model (Class 10).** "Run all of your deterministic tests
first, even before the verification runs. Why waste tokens if you can just have a unit test
catch the same sort of bug?" That is what the local checker is: line shape, character
counts, exclamation marks, banned words and wrong slots are plain Python, costing nothing.
They run before the model call and their findings are handed to it as facts.

The one place this pipeline deliberately departs from that advice: it does not *skip* the
model call when a local check has already failed. The assignment requires a written REASON
on every evaluation, and the Refiner has nothing else to work from, so the model is asked
for its reasoning even on a card the checker has already condemned. The saving is in
correctness rather than tokens: the checker's verdict overrides the model's, so no card can
pass on a generous opinion.

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

## The agents, and the contract each one works to

Five agents, each a separate call with a fresh context. None of them can see any
other's reasoning, only the text it is handed. Every one has a stated output
contract, because a stage that returns free-form prose cannot be parsed and cannot
be trusted.

| Agent | Input | Output contract | File |
|---|---|---|---|
| **Proposer** | Style guide + one item's true behaviour | JSON: `{"proposals": [{item, slot, plug, effect}, ...]}`, exactly 8 | `proposer.py` |
| **Adversarial Critic** | Style guide + all 8 proposals | One numbered paragraph per proposal, instructed to attack and never praise | `proposer.py` |
| **Judge** | Style guide + 8 proposals + the critic's objections | JSON: `{"scores": [{proposal, score, note}], "winner": N, "why_the_winner": "..."}` | `proposer.py` |
| **Evaluator** | Style guide + one card + the local checker's findings | Exactly `SCORE: [X/10]` then `REASON: [...]`, parsed by regex | `evaluator.py` |
| **Refiner** | Style guide + the failing card + the Evaluator's REASON | The four card lines only, no commentary | `refiner.py` |

The Generator in `generator.py` is a sixth role used only by the demonstrations,
where the point is to produce something off-brand on purpose.

**Why the roles are split across calls.** Class 8's generator-evaluator contract:
an agent that just wrote something "has all the generation process still in its
memory" and will wave its own work through. Nothing here reviews its own draft.

---

## Token conservation tactics

1. **The local checker runs before the model, and it is free.** Line shape,
   character counts, exclamation marks, banned words, wrong slots and shouted
   capitals are plain Python. None of that ever costs a token, and it catches the
   majority of first-draft faults.
2. **Eight proposals arrive in one call, not eight.** The Proposer returns all
   variations in a single JSON reply, so "generate 8" costs one round trip.
3. **The Critic reviews all eight in one call too**, and so does the Judge. The
   whole Propose-Critique-Judge panel is three calls per item, not seventeen.
4. **The Refiner works from the best attempt, never the latest.** Before this, a
   regression meant every later rewrite built on a worse card and the tokens were
   spent going backwards.
5. **The Refiner is told to aim short**, at about 78 characters against a
   90-character ceiling, because a card that misses the limit by one character
   costs a whole extra evaluate-and-refine round.
6. **The circuit breaker stops at eight tries** and hands the card back rather
   than looping on a judgement call forever.
7. **The pass mark is 9, not 10.** The last point is an opinion about whether a
   joke lands, and chasing it would burn tokens indefinitely.
8. **Replay costs nothing.** `--replay` reads a recorded run from disk, so the
   loop can be demonstrated any number of times without a single call.

---

## Honest self-assessment: do these outputs actually sound like my game?

Now, yes. They did not at first, and the record of that is worth more than a
claim that it worked first time.

The first pass came back polite. It was technically on-brand, "self-aware
game-show comedy", and it read like a press release. The second pass was cruel but
sincere, stating grim facts flatly, which is menace rather than comedy. The third
was sarcastic but harmless, insincere praise with no jab in it. Only the fourth
pass, once the tone rule demanded sarcasm and cruelty in the *same sentence* with
the jab aimed at the contestant's debt, produced lines like "a complimentary turkey
leg, billed to the debt you came here to escape" and "three hits, generously
prepaid, and the invoice clears long before you do." Those sound like the show.

**What the pipeline cannot do.** The Evaluator can tell whether a card obeys the
rules and whether it matches the register. It cannot tell whether a joke is
actually funny. The 9-out-of-10 pass mark is honest about that: the last point is
reserved for a judgement no agent in this pipeline is qualified to make.

**The weakness I found, and what was done about it.** The money jab was the default
for every card, and reading four in a row you can feel the shape coming: "billed to
the debt you came here to escape", "the invoice clears long before you do", "we
billed you for the shots you will miss". Each one works alone; nine in a row is one
joke told nine times.

So the jab now has four possible targets, all drawn from the same lore: money,
second-hand gear off contestants who died using it, the Network's cheerful
paperwork, and an audience that voted for this and wants it to continue. Each item
is assigned an angle in `settings.py`, and the assignment rotates so no two
consecutive cards share one. Money is still the most common, because debt is what
the premise turns on.

**The weakness still standing.** The assignment is fixed by hand rather than tracked
as the run proceeds, so adding a tenth item means choosing its angle deliberately. A
facts ledger of jokes already spent, in the shape Class 10 described, is the honest
next step.

**Where the human stayed in the loop.** Not inside the loop, which is unassisted by
design, but around it. The tone rules were rejected three times by the designer
before they were right, and every rejection is recorded as amendment 53 in
`GDD_AMENDMENTS.md`. The circuit breaker escalates to the designer rather than
shipping a card at 8.

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
python run.py               the three graded demonstrations
python run.py --production  the nine real cards only
python run.py --all         both, demonstrations first
python run.py --replay      replay a recorded run, no credentials needed
python run.py --report      rebuild before-after.md from a recorded run
```

### Reaching Claude, three ways

1. **`ANTHROPIC_API_KEY` set**: the official `anthropic` Python SDK, on
   `claude-opus-5`. Run `pip install anthropic` first.
2. **Otherwise**: the `claude` command line tool, already installed and signed in
   on the author's machine. No API key, no per-call cost. This is the transport
   assignment 6 used.
3. **`--replay`**: no credentials at all. It reads `output/transcript.json`, the
   machine-readable record of a real run, and walks the whole loop back: every
   draft, every score, every written reason, in order. Nothing in replay can
   invent a result, because no model is involved.

**For anyone marking this.** Option 3 is the one that needs nothing from you.
`--replay` shows the loop working end to end, and `output/before-after.md` is the
same material as a document. `--report` rebuilds that document from the transcript,
which is also why improving the write-up never costs a token.

Nothing in this folder touches the game. The finished cards are typed into UEFN by
hand, which keeps the designer as the checkpoint GDD 4.1 demands.

---

## Files

| File | What it is |
|---|---|
| `settings.py` | The style guide as data: the rules, the banned words, the nine items, the joke angles, the three demonstration cases. The only file to edit to change what is enforced |
| `styleguide.py` | Renders `settings.py` into the text every agent is given, so no two agents can drift apart |
| `proposer.py` | The Proposer, the Adversarial Critic and the Judge |
| `generator.py` | The off-brand Generator used by the demonstrations, plus the three transports that reach Claude |
| `evaluator.py` | The Evaluator: local checks first, then the Claude judgement, returning SCORE and REASON |
| `refiner.py` | The Refiner, which rewrites from the Evaluator's reason alone |
| `run.py` | The loop, the circuit breaker, and the report writers |
| `output/before-after.md` | The three graded demonstrations, with the rule that caught each one |
| `output/crate-cards.txt` | The finished cards, from `--production` or `--all` |
| `output/evaluator-log.txt` | Every score and reason from the run, as raw text |
| `output/transcript.json` | The same run, machine-readable. What `--replay` and `--report` read |
| `output/proposal-panel.json` | All eight proposals per item, the Critic's objections, and every Judge score, so the pruning is auditable |
| `output/style-guide-as-the-agents-see-it.txt` | The guide exactly as the agents receive it, generated from `settings.py`, so the rules enforced are provably the rules written down |
