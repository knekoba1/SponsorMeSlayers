# CLAUDE.md — Sponsor Me, Slayers!

House rules for this project. Read this first, every session.

---

## 0. Standing rules for Claude (read before anything else)

These three override convenience, speed, and any assumption about "what's obviously
needed." They come from the human designer, not from the GDD.

**1. Kailee is a beginner with no coding background. Explain everything in plain English.**
Never assume Verse, Unreal, or general programming knowledge. When introducing a term,
define it in the same breath. Describe what code *does* in terms of what the player sees
or feels, not in terms of language features. Avoid jargon; when it's unavoidable, gloss it.
A correct answer that isn't understood is a failed answer.

**2. Kailee is the human checkpoint. Ask before changing files.**
Show proposed changes and wait for approval before writing, editing, or deleting anything.
This is not politeness, it is the project's actual architecture: GDD Section 4.1 makes the
human designer "an absolute checkpoint between handoffs," and specifies that output is
"manually audited, approved, and integrated by the designer." Explain what will change and
why, then stop and wait.

**3. Announcer dialogue is written by Kailee. Never auto-generate it.**
GDD Section 4 and the revision log (feedback from Josh Rose) are explicit: the sarcastic
commentator lines are hand-written by the human designer. Claude may structure the bark
*database*, map barks to triggers, and handle the loading and playback code. Claude must
never invent, draft, rewrite, or "improve" the dialogue text itself. If bark text is
missing, leave a clearly marked placeholder and ask.

---

## 1. What this game is

**Sponsor Me, Slayers!** is a top-down twin-stick arcade shooter built in UEFN using the
Verse language. The player is a contestant on a dystopian televised gladiatorial game show,
fighting waves of cybernetic hostiles inside a single-room stadium arena.

Contestants volunteer to escape crushing debt. The Network never pays out, because nobody
has ever finished a run alive. The enemies are rejected pilot-episode robots and bankrupt
former contestants who took mechanical chassis mods as a severance package.

The tone is broad, self-aware game-show comedy in the tradition of **Smash TV** and
**Total Carnage**. Corporate hostility played for laughs. Visual references: Paper Boy,
Toobin', Smash TV, with Vampire Survivors as the model for low-fidelity, high-readability
assets.

The defining mechanic is twin-stick control: movement (WASD, 8 directions) is fully
decoupled from aiming (mouse cursor). Running one way while firing another is the point,
enabling circular "kiting" and evasion.

Author: Kailee Nekoba. Solo development, 6-week schedule, capstone project.

---

## 2. The core loop

Six steps, in order (GDD 2.1):

1. **Defeat hostiles and collect cash.** Enemies burst into a physics-simulated shower of
   coins, cash bundles, and retro household appliances (toasters, TVs).
2. **Surge the Hype Meter.** Collecting drops and high-skill maneuvers fill the vertical
   HUD meter.
3. **Trigger paraglider drops.** Crossing Hype thresholds makes the simulated audience
   parachute supply crates into the arena.
4. **Equip weapons and upgrades.** Touching a crate instantly equips its contents.
5. **Survive escalating waves.** Denser, faster, more aggressive enemies.
6. **Accumulate exponential bankroll.** Clearing waves yields windfalls that save locally
   and feed the persistent cosmetic rank.

---

## 3. Hype Meter rules (GDD 3.1)

A vertical, thermometer-style HUD bar that tracks player *style*.

| Rule | Value |
|---|---|
| Hype sources | Rapid multi-kills, close-shave dodges, prize pickups |
| Underdog Boost | Health below 40% grants **+50% Hype generation** |
| Decay | **5% every 10 seconds** of inactivity |
| Manual Hype Call | Hold the key **1 second**, grants an instant burst |
| Hype Call cooldown | **10 seconds** |
| What Hype controls | The **quality tier** of falling paraglider crates |

Crate quality tiers, lowest to highest: **Underdog → Rising Star → Superstar**.

---

## 4. Cash, prize drops, and crates

### Cash and retro prize drops (GDD 2.3)
Hostiles burst into physical loot: gold coins, cash bundles, and nostalgic household
appliance props (retro TVs, toasters). Walking over a prop triggers an **immediate
collision pickup**, plays the upbeat **'ding-ding-ding!'** audio stinger, and increments
the run score. No pickup button; contact is the interaction.

### Paraglider supply crates (GDD 3.2)
Crates parachute from the stadium ceiling with **high-contrast colored paragliders that
denote their quality tier**. They trigger **instantly on player collision**, deliberately,
to maintain momentum.

The player has **four upgrade slots**: Weapon, Consumable, Shield, Ammo Modifier.

**Duplicate pickups refresh the active duration rather than stacking.** This is an
anti-exploit rule, not an optimization. Do not "fix" it into stacking.

---

## 5. Win and loss conditions (GDD 2.5)

**Win (Room Won):** the player eliminates all spawned waves in the active Escalation Tier.
A loud game-show buzzer sounds, environmental coordinates and concrete obstacles reset, and
the next Escalation Tier begins.

**Loss (Run Lost):** a run ends permanently when health hits zero **and** the player fails
to collect a Sponsor Aid turkey leg before the **3-second Death Save countdown** expires.

### The Death Save window (GDD 3.4)
A fatal blow triggers 3 seconds of slow motion, the screen desaturates to grayscale, and
the commentator screams for a sponsor rescue. Two ways out:

- **Hype Call rescue teleport.** A fatal blow instantly resets the Hype Call cooldown.
  Success rate scales with Hype tier: **35% Underdog, 50% Rising Star, 65% Superstar.**
  On success a Sponsor Aid item spawns at the player's feet.
- **The manual run.** A physical Sponsor Aid turkey leg *always* spawns within easy walking
  distance, whether or not the Hype Call was used or succeeded.

**Anti-chain rule:** Death Save is limited to **once per life**. A second fatal blow taken
before health regenerates above **25%** ends the run instantly.

---

## 6. Career Sponsor Rank (GDD 2.6)

A lightweight, **locally saved** statistic that survives between runs.

At run termination, the game compares final score and highest Escalation Tier reached
against saved records. Beating **either** threshold advances the rank through five
sarcastic titles:

1. Debt-Ridden Rookie
2. Undercard Filler
3. Fan Favorite
4. Ratings Magnet
5. The Network's Sweetheart

Advancing unlocks a cosmetic holographic host title card on the main menu and triggers a
custom commentator bark at match start.

**Career Rank is purely cosmetic. It has zero effect on combat math or enemy difficulty.**
That is deliberate, both for design reasons and because it keeps the feature cheap to
build. Never wire it into balance.

---

## 7. Uncuttable features (GDD 5.7)

These ship no matter what. Do not propose cutting, deferring, or simplifying them away:

- **Twin-stick aiming controls**
- **Wave spawning loops**
- **Win/Loss resolution conditions**
- **Career Sponsor Rank**

---

## 8. Scope-cut order (GDD 5.7)

If the schedule slips, cut in **exactly this order**. Never cut out of order, and never
invent a new cut without asking:

1. **Simulated Stream Chat HUD widget**, entirely. (Announcer barks carry the game-show
   commentary narrative on their own.)
2. **Icy Rounds modifier.** (Ammo modifiers collapse to Flaming Ammo only.)
3. **Flaming Ammo modifier**, entirely. (Weapons collapse to the standard sidearm plus the
   3 basic weapons.)
4. **Tiered paraglider crate scaling.** (Supply drops collapse to a single flat crate
   quality.)

---

## 9. Hard technical constraints (GDD 5.3, 5.5)

These are platform and performance limits, not preferences:

- UEFN allows roughly **100 active props**. Budget against this.
- Wave spawner caps concurrent active hostiles at **40 bots**.
- Spawns are blocked within a **3-metre safety radius** of the player.
- Bullet props, cash bundles, and expired visual FX despawn **exactly 5 seconds** after
  generation.
- Difficulty escalates **8% per tier**, hard-capped at **Escalation Tier 21** (~5x starting
  difficulty).
- All **25 announcer barks** load into memory at runtime. Never stream dialogue over the
  network; it caused stutter and ruined comedic timing (GDD 5.2).
- Target: locked **60 FPS**. Secondary VFX, particles, and HUD counters run asynchronously
  via Verse structured concurrency (`spawn`, `branch`).

---

## 10. Verse naming and code style

This is the house style for the project. Follow it in every new file.

No Verse scripts exist in this project yet. Two scripts will be ported over from the
reference project when the time comes, `cash_drop_manager` and `hype_meter_manager`, and
they already follow the conventions below.

### Naming
| Thing | Convention | Example |
|---|---|---|
| Class names | `snake_case` | `cash_drop_manager`, `hype_meter_manager` |
| Manager classes | end in `_manager` | `hype_meter_manager` |
| Filenames | `PascalCase`, matching the class | `CashDropManager.verse` |
| `@editable` fields | `PascalCase` | `HostileSpawner`, `CashPickupPool` |
| Mutable state | `var` + `PascalCase` | `var RunScore : int = 0` |
| Constants | `PascalCase`, typed | `MaxBarHeight : float = 300.0` |
| Event handlers | `On` + past-tense event | `OnHostileEliminated`, `OnCashCollected` |

**New Verse files use PascalCase filenames that match the class they contain.**
`CashDropManager.verse` holds `cash_drop_manager`.

### File structure
Every file opens with a header comment: the filename, a blank comment line, then which GDD
section it implements. For example:

```
# HypeMeterManager.verse
#
# GDD Section 3.1 "Hype Meter" -- real Hype value now, driven by kills.
```

Then the `using { ... }` block, then the class.

### Patterns to follow
- Classes extend `creative_device`.
- `@editable` fields are typed with a default: `HostileSpawner : npc_spawner_device = npc_spawner_device{}`.
- Event subscriptions all happen in `OnBegin<override>()<suspends>:void =`.
- Optional values use `?type = false` and `option{Value}`, unwrapped with `if (X := Maybe?)`.
- Failable operations are wrapped in `if (X := ...)` with an explicit `else` branch.
- Long-running work is launched with `spawn{ }`.
- `Print()` is used for logging. Diagnostic lines are prefixed `DEBUG:`.
- Indentation is **4 spaces**.
- Values worth tuning by hand belong in `@editable` fields so they can be adjusted in UEFN
  without editing code.

### One note on the GDD
The GDD refers to Verse files as `.vs`. The real extension is `.verse`. The GDD is slightly
wrong here; follow the code.

---

## 11. Project layout and workflow

- Project root: `C:\GameDev\SponsorMeSlayers_v2` (this folder). **This is the live
  project.** UEFN opens from here and all work happens here.
- `Content/` holds the map, assets, and `.verse` scripts.
- `Content/__ExternalActors__/` holds one file per object placed in the map. Machine-managed.
- `.lore/` is UEFN's own revision store. **Git-ignored on purpose.** Do not commit it.
- Git tracks this folder. Commit after each working change, with a message saying what
  changed and why.

### Read-only locations. Never edit these.

- **`C:\GameDev\SponsorMeSlayers`** is the **reference project**. It is kept for reference
  only and **must never be edited**. It is the predecessor to this project.
- **`C:\Users\kaile\OneDrive\Documents\Fortnite Projects\SponsorMeSlayers`** is an older
  copy. Also **read-only. Never edit.**

Reading from either location is fine, and expected when porting work across. Writing to
either is not. If a task seems to require changing something in the reference project,
stop and ask.

---

## 12. Not yet built

The four AI agent roles described in GDD Section 4 (Gameplay Systems, Simulated Audience,
Announcer Bark, Playtest QA) are **not set up**, by Kailee's instruction. Do not create
agent definition files until asked.

Per GDD 4.1, those agents are "strictly prohibited from communicating or prompting one
another directly." Any future setup must preserve the human designer as the sole checkpoint
between handoffs.
