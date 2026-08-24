# The Announcer Bark Agent

**Game:** *Sponsor Me, Slayers!*, a top-down twin-stick arcade shooter built in
Unreal Editor for Fortnite (UEFN) using the Verse language.

**Author:** Kailee Nekoba

---

## What it is for

GDD Section 4 gives this agent one line of job description:

> Structures and compiles the sarcastic game-show commentator dialogue database
> in Verse, mapping barks to triggers. Creative dialogue is written manually by
> the human.

So it does exactly two things. It decides which moments in the game get a line
and how many, and it turns the lines Kailee writes into a Verse device the game
can read.

## There is no language model in it

That is the whole design, not an omission. CLAUDE.md standing rule 3 and the
revision log both say the commentator's lines are hand-written by the designer,
so this agent is built without the ability to write one. There is no generator,
no critic and no refiner, because a critic that says "this line is off-tone" is
already reaching for the pen.

What it checks instead is countable: which slots are empty, whether the trigger
split still fits GDD 5.3's 25-bark budget, whether a line repeats another word
for word, and whether one is long enough to talk over the next thing that
happens. None of that is an opinion about the writing.

## The files

| File | What it is |
|---|---|
| `settings.py` | The trigger list, the 25-bark budget and the word cap. The only design file |
| `barks.py` | Kailee's lines. Hers alone. Every slot starts empty |
| `check.py` | Reports empty slots, budget breaks, repeats and over-long lines |
| `compile_verse.py` | Writes `Content/BarkDatabase.verse` |
| `run.py` | Checks, then compiles |

## How to use it

```
python run.py --check     what is still to write
python run.py             check, then compile
```

Open `barks.py`, replace an empty `""` with a line, and run it again. A trigger
with nothing written compiles to an empty list and the commentator simply stays
quiet at that moment, so a half-written database is always safe to ship.

The Verse file is not created at all until at least one line exists. An untested
generated file sitting in `Content/` can only break the UEFN build.

## The triggers, and where each one fires

Kailee's ruling, 2026-08-24. Every trigger names a system that already exists
and already reaches that moment, so the mapping is checkable rather than hoped
for.

| Trigger | Lines | Fired by |
|---|---|---|
| MatchStart | 2 | StartingLoadoutManager, on the first spawn |
| RankUp | 1 | CareerRankManager, GDD 2.6's rank advance |
| WaveCleared | 2 | WaveManager, GDD 2.5's Room Won |
| TierEscalation | 2 | WaveManager, the next Escalation Tier starting |
| MultiKill | 3 | HypeMeterManager, its CLUSTER KILL |
| CloseShave | 2 | HypeMeterManager, its CLOSE SHAVE |
| HypeRisingStar | 1 | SimulatedAudience, crossing RisingStarAt |
| HypeSuperstar | 1 | SimulatedAudience, crossing SuperstarAt |
| HypePrimeTime | 1 | SimulatedAudience, crossing PrimeTimeAt |
| CrateLanded | 2 | CrateManager, a crate reaching its hover height |
| CrateOpened | 2 | CrateManager, a crate shot open |
| DeathSaveOpened | 2 | DeathSaveManager, GDD 4.2's #DeathSaveTriggered |
| DeathSaveSurvived | 1 | DeathSaveManager, the med kit reached in time |
| RunLost | 3 | DeathSaveManager, GDD 2.5's Run Lost |

Twenty-five exactly, which is the whole budget.

## What is not built yet

Playback. The database and its lookup are here; wiring `GetBark` to an audio
device, and deciding whether a bark is spoken, written on screen or both, is the
next job and is not this agent's.
