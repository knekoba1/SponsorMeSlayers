# GDD Amendments to Decide

Places where the build has diverged from `Kailee_Nekoba_GDD_Final_Draft.pdf`, or where
the GDD disagrees with itself.

Each entry states what the GDD says, what was actually built, and why. **No
recommendations.** Which way each one resolves, amend the GDD or change the build, is
Kai's call.

Items 12 onward are a different kind. They are **open questions**: places where the GDD
does not diverge from the build, but leaves something undecided or contradicts itself.
Each is marked **BLOCKS THE BUILD** or **DOCUMENTATION ONLY**.

**NO OPEN QUESTION MAY STILL BE OPEN WHEN THE GAME SHIPS.** Kai's rule, 2026-08-16.
Every item below must read RESOLVED, with the ruling and its date recorded, before the
capstone is submitted. This is the last gate in `BUILD_ORDER.md`.

Opened 2026-08-15.

---

## 1. Physics-simulated prize drops

**What the GDD says.** Section 2.1, core-loop step 1: hostiles burst "into a physical
shower of coins, cash bundles, and retro household appliances (toasters, TVs) **with
physics simulation**." Section 2.3 repeats the physical-loot description.

**What was built.** A scripted launch arc. Each drop is teleported along a parabola
about 33 times a second until it returns to the floor. No engine physics is involved at
any point.

**Why.** Engine physics is not reachable for spawned props. `SetDynamic(true)` and
`ApplyLinearImpulse` only do anything on a prop whose asset carries a physics body, and
a Content Browser search found no `creative_prop_asset` in the library that has one. The
only physics items available are `physics_boulder_device` and `physics_tree_device`,
which are placed devices (FortPlaysetItemDefinitions) and cannot be spawned from Verse.
Both calls return `void` and fail silently, so the drops simply never moved.

The visible result matches the GDD's intent, loot that bursts outward and lands. The
mechanism does not match its wording.

---

## 2. The melee Swarmer

**What the GDD says.** Section 5.4 commits to "2 cybernetic hostile models (**melee
Swarmer**, heavy Ranged Tank)." Section 2.4 puts "weak melee Cyber-Swarmers only" in
Room-Loop 1.

**What was built.** `CyberSwarmerMelee`, a Guard with 40/40 health, raised movement
speed and the lowest accuracy setting. It is armed, not melee. It pressures the player
by closing distance fast and shooting badly.

**Why.** Adding an Inventory Modifier to a Guard to remove its weapon makes it
completely passive: it will not chase and it will not attack. A genuinely weaponless
melee enemy is not achievable that way. The fast, inaccurate, armed version reads as
melee pressure in play without the passivity.

A true melee hostile would need a different approach entirely, not another attempt at
Inventory Modifiers.

---

## 3. The Playtest QA agent

**What the GDD says.** Section 4 defines the Playtest QA agent as one that "parses raw
output logs (**qa_log.txt**) and code diffs from manual playtests using a free,
**locally-hosted Llama-3 model** to isolate navigation-mesh errors and crash vectors."

**What was built.** `.claude/agents/playtest-qa.md`, a Claude Code subagent with
read-only tools. It reads the newest UEFN session log from
`C:\Users\kaile\AppData\Local\UnrealEditorFortnite\Saved\Logs` and reports failures,
broken invariants and anomalies. It does not parse code diffs.

**Why.** Three parts of the GDD's description do not match the build: the model is
Claude rather than a locally-hosted Llama-3, the source is the UEFN session log rather
than a `qa_log.txt`, and code-diff parsing is not implemented. The agent's purpose,
isolating faults from manual playtests without touching the code, is unchanged, and
GDD 4.1's rule that the agent reports only to the human designer is enforced by giving
it no tools that can modify anything.

---

## 4. The enemy roster contradicts itself

**This one is internal to the GDD.** It is not a build divergence.

**What Section 3.3 says.** The weapon table names three hostile types in its tactical
effects: "Cyber-Swarmers" (Submachine Gun row), "armored **Cyber-Boars**" (Shotgun row),
and "distant, stationary **Ranged Sentinels**" (Sponsor Sniper row).

**What Section 5.4 says.** The MVP asset ceiling funds "2 cybernetic hostile models
(melee Swarmer, **heavy Ranged Tank**)."

**The conflict.** Cyber-Boars have no model budgeted anywhere in the document. The
ranged enemy is called "Ranged Sentinels" in 3.3 and "heavy Ranged Tank" in 5.4, which
may be two names for one enemy or two different enemies. Three weapon effects in 3.3,
the Shotgun's chain knockback in particular, are written against enemies the MVP does
not fund.

Nothing has been built either way. The Shotgun and Sniper are not implemented yet, so
this is undecided rather than diverged.

---

## 5. The orthographic camera

**What the GDD says.** Section 1.1, Look and Feel: the visual perspective is "a locked
top-down camera with a bird's-eye **orthographic** perspective (objects maintain constant
scale regardless of position, removing lens distortion)." The camera "is anchored at a
fixed height above the flat stadium floor, providing a complete view of incoming
threats."

**What was built.** A Fixed Angle Camera device set to a narrow field of view. That is a
normal lens camera, not an orthographic one, so scale is not perfectly constant across
the arena floor and a small amount of outward lean remains toward the edges of the
screen. Narrowing the field of view reduces both, which is why it is narrow. Everything
else Section 1.1 asks for is unchanged: the camera is locked, it is top-down, it is
anchored at a fixed height, and it holds the whole arena in view.

**Why.** UEFN's only true orthographic camera is a Scene Graph camera component, and
Epic's documentation states of that feature: "You cannot publish a project that uses
Scene Graph camera components at this time." A capstone that has to be published cannot
use it. See [Cameras in Unreal Editor for
Fortnite](https://dev.epicgames.com/documentation/fortnite/cameras-in-unreal-editor-for-fortnite).

Of the camera devices that can be published, the Fixed Angle Camera is the one Epic
describes as able to "move to follow the player, but doesn't rotate," and calls "great
for top down games, side scrollers, and more." It exposes a field of view setting and has
no orthographic mode. See [Using Fixed Angle Camera Devices in Fortnite
Creative](https://dev.epicgames.com/documentation/en-us/fortnite/using-fixed-angle-camera-devices-in-fortnite-creative).

---

## 6. The rear firing arc

**What the GDD says.** Section 2.2, Controls & Twin-Stick Aiming: "Movement is
controlled using the standard WASD keys in eight directions. Weapon aiming is entirely
independent, tracked dynamically via the mouse cursor. This twin-stick structure allows
players to run in one direction while continuously firing in another, enabling key
circular 'kiting' and evasion techniques." Section 5.7 names "the twin-stick aiming
controls" among the features that "remain strictly uncuttable."

**What was built.** Everything Section 2.2 asks for by name. Movement is on WASD in
eight directions. Aiming is entirely independent of it and is tracked by the mouse
cursor. Shots go to the cursor. Running in one direction while firing in another works,
and kiting works.

What Section 2.2 does not mention, and what does not work, is the character's legs. They
never turn toward the cursor. They hold the direction of the last WASD input, and the
torso twists toward the cursor on top of them. That twist has a limit, and past it the
character's own model sits between the barrel and the target, so the shot cannot be
taken.

The result is an arc behind the player, measured from the direction they last moved,
that cannot be fired into. Aiming into it is possible. Hitting anything in it is not. A
player who wants to shoot something behind them has to run toward it first.

The Third Person Controls device's Facing Direction option exists to solve exactly this,
and has no observable effect. Set to Twin Stick, with either Target Cursor or Dial
Aiming, the behaviour is identical to the Movement default.

**Why.** The circle test isolates it. Standing completely still with no WASD input, the
cursor was moved slowly through a full circle around the character, once holding the
pistol and once with empty hands. The feet never moved at all. Only the torso twisted,
to its limit, and stopped. Nothing about the cursor reaches the legs.

Ruled out first, each on a fresh Launch Session: applying the controls via Verse AddTo
alone; applying via Add to Players on Start alone; Priority above 0; camera Angle Pitch
at -90 and at -80; camera Angle Yaw at 0 and at 180; Targeting Assistance and Targeting
Lock On both off; all four Turn Speed Multipliers confirmed at 1.0x. Only one Third
Person Controls device exists in the map, confirmed in the Outliner and by the startup
DEBUG line printing exactly once per match start across four match starts.

This is the symptom of Epic ticket FORT-1110974, "Third Person Controls Device Broken
Player Facing mode," added to Epic's backlog on 1 June 2026 and unresolved. The nearest
related report, [Character Facing and Aiming Direction Stuck, Doesn't Follow
Cursor](https://forums.unrealengine.com/t/character-facing-and-aiming-direction-stuck-doesnt-follow-cursor-twin-stick-third-person-controls/2673933),
was closed by Epic as unable to reproduce. No supported workaround appears in Epic's
documentation or the device reference, and no shipped UEFN top-down twin-stick island
was found that documents one. See [Using Third Person Controls Devices in Fortnite
Creative](https://dev.epicgames.com/documentation/en-us/fortnite/using-third-person-controls-devices-in-fortnite-creative).

The remove-and-re-add workaround other creators use is implemented in
`Content/TwinStickController.verse` and has not changed the behaviour.

One test is outstanding. Setting Movement Speed Multiplier on the same device to a value
obviously different from 1.0 would show whether the device is reaching the player at
all. If speed changes, only Facing Direction is inert. If it does not, the device is not
being applied despite AddTo reporting success. Either way the rear arc described above
is present.

---

## 7. The starting loadout — RESOLVED 2026-08-16

**Resolved.** The player now spawns with the pistol equipped in hand, and the melee slot
is gone. Kept in this file because the route to that answer was long and wrong twice, and
the two cautions below are worth more than the resolution.

**What the GDD says.** Section 2.4, First-Life Onboarding Ramp, Room-Loop 1: "Basic WASD
movement, independent mouse aiming, standard Pulse Blaster weapon, and weak melee
Cyber-Swarmers only." The ramp exists "to flatten the learning curve and prevent HUD
clutter."

**What was built.** A Class Designer device with Class Identifier set to Class Slot 1 and
an Item List holding one entry, the Combat Pistol (`WID_Pistol_Tactical_Athena_C`),
quantity 1. Island Settings, Mode tab, Default Class Identifier set to 1. That pairing is
what makes the pistol appear at all; without it the Class Designer does nothing.

One gap against the above. The player spawns with the pistol in their inventory but not
in their hands, and has to press 1 to draw it before they can fire.

**There is no pickaxe, and there never was.** Earlier drafts of this item listed an
unremovable pickaxe as a second gap. That was wrong twice over. Island Settings,
Player > Equipment, has **Start With Pickaxe**, and it was already unticked. The Class
Designer's Item List replaces the whole loadout in any case.

What is visible in the HUD is an empty harvest slot, not a pickaxe, and Island Settings,
Player > Equipment, **Disable Harvest Slot** is the setting that removes the slot itself.
Ticked and playtested: the melee slot is gone.

Recorded because the closed route below spent real effort chasing a pickaxe that did not
exist, and because it is an easy mistake to make twice.

**Why.** No device in UEFN 5.8 exposes either setting.

The Class Designer in 5.8 has, in full: General (Class Identifier, Class Name, Class
Description, Visible During Game, Visible in UI), User Options (Item List), and User
Options - Functions (Show/Hide in UI When Received from Func). The Team Settings &
Inventory device was searched on the All tab for "equip", "pickaxe" and "respawn" and has
no loadout options either.

The Verse digest agrees. `class_designer_device` exposes only `GetClassMembers` and
`IsOfClass`, and a search across the whole Fortnite digest finds no equip-on-spawn
function on any device.

CAUTION FOR A FUTURE SESSION. Epic's web documentation for the Class Designer describes
`Equip Granted Item`, `Grant Items On Respawn` and `Start With Pickaxe`. **None of the
three is on the Class Designer in 5.8.** That page documents an older build. `Start With
Pickaxe` does exist, but in Island Settings, not on that device; the other two were never
located on any device. The digests, which UEFN regenerates to match the installed
version, are the ground truth:
`C:\Users\kaile\AppData\Local\UnrealEditorFortnite\Saved\VerseProject\SponsorMeSlayers_v2\`.

SECOND CAUTION, AND THE MORE USEFUL ONE. **Island Settings is where player equipment
rules live.** Both `Start With Pickaxe` and `Disable Harvest Slot` are there, under
Player > Equipment. The Class Designer, the Team Settings & Inventory device and the Item
Granter were each searched panel by panel, on the All tab, before anyone opened Island
Settings. That cost most of a session. The dividing line that would have saved it:
Island Settings governs rules about the player, devices govern things that happen to the
player. Anything phrased as "the player always/never has X" belongs to Island Settings,
and it is not visible in the Verse digest, so it has to be looked at by hand.

**The Verse route was built, and it does not work.**
`Content/StartingLoadoutManager.verse` was written, compiled clean, and playtested on
2026-08-16. It has never succeeded. Across two match starts and five retry cycles it gave
up every time with "Pistol equipped: no. Pickaxe removed: no."

The log names the failing step by omission. `GetFortCharacter` and `GetEntity` succeeded
on every attempt. The two lines that print only when a container is found, "weapon hotbar
found" and "harvest tool inventory found", never printed once in the entire session. So
`FindDescendantComponents` returns no `fort_inventory_weapon_hotbar_component` and no
`fort_inventory_harvest_tool_component` on the player's entity.

That is a measured result rather than an inference, and it rules out timing. The retry
loop paced correctly at 20 attempts over 5.0 seconds, and the containers were absent at
attempt 1 and still absent at attempt 20.

| Step | Digest and line | Result |
|---|---|---|
| `Agent.GetFortCharacter[]` | Fortnite:8455 | succeeded, every attempt |
| `.GetEntity[]` | Fortnite:8437 | succeeded, every attempt |
| `.FindDescendantComponents(component_type)` | Verse:481 | **returned nothing, every attempt** |
| `fort_inventory_weapon_hotbar_component` | Fortnite:8201 | never found |
| `fort_inventory_harvest_tool_component` | Fortnite:8209 | never found |

**Why, and why no other starting point or search direction would help.** The
`fort_inventory_*` components are the creator-built item system, not the inventory a
Fortnite player already carries. In the digest they appear only as class declarations.
Nothing returns one, nothing takes one as a parameter, and nothing states that a player
has one. They sit directly beneath `pistol_template`, `assault_rifle_template`,
`sub_machine_gun_template` and `shotgun_template`, each described as "the entity prefab
for a creator customizable" weapon, and the module comment notes that if new inventories
are added the creator has to build their own HUD for them. They are components a creator
adds to entities they assemble.

The Class Designer's pistol goes into the classic Fortnite inventory, which this API does
not expose. `GetInteractorInventory` (Fortnite:8259) and `GetParentInventory`
(UnrealEngine:553) are the only two inventory accessors in the entire API surface across
all three digests, and neither is a route from a player to their own inventory. The first
is a method on a component the creator must place, and its own comment says it expects
the agent to have a subentity with an `inventory_component`, which is an assumption about
a creator-built setup. The second requires already holding the item, which is the thing
that cannot be found. `FindAncestorComponents`, a different starting entity, or any other
search would find nothing either. The component is not there to be found.

**Two things that were checked and were not the cause.**

The version gates. `Equip`, `RemoveItem` and `AddItem` require
`MinUploadedAtFNVersion := 3800` and `GetComponent` requires `3200`. This build is
Fortnite Release-41.30, version 4130, and the digest itself carries APIs gated at 4120.

The respawn hook, which works. `fort_playspace` has no spawn or respawn event at all,
only `PlayerAddedEvent` and `PlayerRemovedEvent`, which fire on joining and leaving the
match, so respawns have to come from a device. `player_spawner_device.SpawnedEvent`
(Fortnite:2215) and `team_settings_and_inventory_device.TeamMemberSpawnedEvent`
(Fortnite:4497) both signal a spawn and hand back the agent. Both were wired, and the log
shows retry cycles beginning mid-match with no new match start before them, so the hook
fires. Wiring both runs the work twice per spawn, harmlessly.

**What is being tried instead, unverified.** `StartingLoadoutManager.verse` has been
rewritten rather than deleted. The component walk is gone. It now drives a placed Item
Granter device, which holds the Combat Pistol with Equip Granted Item ticked, by calling
`item_granter_device.GrantItem` (Fortnite:3824) with the specific agent handed back by
the spawn hook, after a short editable delay.

The granter's own "Grant on Game Start" option was tried first and did not work: the
pistol was still not in hand on spawn, almost certainly because it fires before the
player's character exists. Driving it from the spawn hook is an attempt to grant at a
moment when the character definitely exists. Receiving Players must be set to Triggering
Player rather than All Players, or a grant aimed at one player arms every agent on the
island.

The file keeps a header recording the closed component-walk route, so that nobody
rebuilds it.

**Playtested and confirmed working.** The pistol is equipped in hand on spawn. With
`Disable Harvest Slot` also ticked in Island Settings, the melee slot is gone. Both parts
of this item are closed and the build now matches Section 2.4's Room-Loop 1 loadout.

---

## 8. Hostile movement speed scaling -- A CLARIFICATION OF 5.5, NOT A DEPARTURE

**What the GDD says.** Section 5.5: "Completing a room cleared wave escalates difficulty
by exactly 8% per tier. Hostile maximum health pools, movement speeds, and spawn
densities scale up incrementally." Section 2.2 names "circular 'kiting' and evasion
techniques" as what the control scheme exists to enable. Section 5.7 lists twin-stick
aiming among the features that "remain strictly uncuttable."

**The decision, made by Kailee on 2026-08-16.** Hostile movement speed scales every tier,
as 5.5 requires. It scales at a gentler rate than 8%, chosen so it never exceeds the
player's speed. Health pools and spawn densities stay at the full 8% per tier, untouched.

**Why a literal 8% cannot be what 5.5 means.** Compounded over twenty tiers, 8% per tier
takes a 4.0 m/s Cyber-Swarmer to roughly 19 m/s at Tier 21, over three times the player's
speed. Two things elsewhere in the GDD break at that point, and neither is optional:

  * **Kiting becomes physically impossible.** A player cannot circle an enemy that closes
    faster than they can retreat. GDD 2.2's stated purpose for the entire twin-stick
    scheme stops functioning, and 5.7 forbids cutting it.

  * **The Career Sponsor Rank ladder in 2.6 flattens.** When hostiles outrun everybody,
    every run ends at the same tier regardless of skill. The highest-tier-reached record
    stops moving, and one of the two thresholds that advance the rank is dead. 2.6
    depends on runs ending at different tiers for different players.

Read as a difficulty target rather than a literal speed multiplier, 5.5 is fully
satisfied: health and density carry the full 8% while speed climbs gently underneath.
That is the reading adopted here, which is why this is a clarification and not a cut.

**Precedent.** Horde survivor games escalate through health and density, not by making
ordinary enemies outrun the player. Where a run needs a hard ending, the genre reaches
for a single dedicated finisher rather than a fleet-footed rank and file.

**The rate: 2.1% per tier**, applied to the sprint value, with run held at 87.5% of
sprint and walk at 62.5%, the ratios the T1 card already used.

| Card | Tiers | walk / run / sprint | Exact sprint | Status |
|---|---|---|---|---|
| `CyberSwarmerMelee` | 1-4 | 2.5 / 3.5 / 4.0 | 4.000 | Safe. Build now |
| `CyberSwarmerMelee_T2` | 5-8 | 2.7 / 3.8 / 4.3 | 4.347 | Safe. Build now |
| `CyberSwarmerMelee_T3` | 9-12 | 3.0 / 4.1 / 4.7 | 4.724 | **PROVISIONAL** |
| `CyberSwarmerMelee_T4` | 13-16 | 3.2 / 4.5 / 5.1 | 5.133 | **PROVISIONAL** |
| `CyberSwarmerMelee_T5` | 17-21 | 3.5 / 4.9 / 5.6 | 5.578 | **PROVISIONAL** |

Health is unchanged at 40 / 54 / 74 / 101 / 137, which is the full 8% per tier compounded
across blocks of four. Spawn density is unchanged and still scales in `WaveManager.verse`.

### MEASURE THE PLAYER'S RUN SPEED BEFORE BUILDING T3, T4 OR T5

**T3 to T5 are provisional and must not be built until the player's actual run speed has
been measured.** They rest on an estimate, and if the estimate is wrong they cause the
exact failure this amendment exists to prevent.

The whole table assumes the player runs at **6.0 m/s**, from an assumed Fortnite base of
about 5.0 m/s times the Movement Speed Multiplier of 1.2 on the Third Person Controls
device. **The 5.0 base has never been measured.** If the real figure is nearer 5.0 than
6.0, then T4 at 5.1 and T5 at 5.6 both outrun the player outright and T3 at 4.7 is
marginal. T1 at 4.0 and T2 at 4.3 stay safely under either figure, so nothing is blocked
today.

**How to measure it.** `fort_character.GetLinearVelocity()` (Fortnite digest 8440)
returns the character's velocity and its own comment gives the units as **metres per
second**, the same units the character cards use. So the two are directly comparable with
no conversion. Print its length once a second while running in a straight line at full
speed, the same shape as `AimRotationProbe.verse`, and read the number off the log.

Once measured, rebuild the table from the real figure and drop the PROVISIONAL marks.

### The rest of the reasoning

**SPEED STEPS EVERY FOUR TIERS, NOT EVERY TIER, AND THAT IS AN ENGINE LIMIT.** Movement
speed lives on the npc_character_definition and cannot be set at runtime, which
`WaveManager.verse` already records. With five cards and MaxTier 21 the wave manager
splits the range into blocks of four, so the ladder above is a five-step staircase
approximating a smooth 2.1% curve. The rate is per tier; the delivery is per block.

**The player has no sprint at all.** Sprinting is switched off in Island Settings,
Player > Locomotion, because sprinting lowers the weapon and GDD 2.2 requires continuous
fire while moving. So the ceiling the hostiles must stay under is the player's ordinary
run speed, not a sprint.

**Why the curve is not extended to Tier 21 itself.** At 2.1% per tier the continuous
curve reaches 6.061 m/s at Tier 21, which would just pass the player. It never arrives,
because the fifth card takes effect at Tier 17 and holds through Tier 21, capping the
speed actually encountered at 5.578. The staircase is what keeps the promise; the curve
alone would break it in the last four tiers.

**The chase test, which settles all of this.** Let one Swarmer chase you and run in a
straight line. The gap must open slowly at Tier 1 and still open, barely, at Tier 21. If
a Tier 21 Swarmer closes on you, lower the top card. Do not raise the player.

---

## BACKLOG

Not to be built now. Recorded so the reasoning is not lost.

**A dedicated run-terminator hostile.** If playtesting shows a skilled player can survive
Tier 21 indefinitely, the answer is a single dedicated finisher enemy, not faster
ordinary hostiles. Raising rank-and-file speed re-breaks kiting (2.2, uncuttable per 5.7)
and re-flattens the Career Rank ladder (2.6), which is the whole reason for item 8 above.
See item 8 before proposing anything else here.

---

## 9. The Death Save grayscale is a built-in effect, not a custom material

**What the GDD says.** Section 3.4: taking a fatal blow means "the screen desaturates to
grayscale."

**What satisfies it.** The Post Process Device's **Post Process Effect** slot, set to the
built-in **`PP_FilmNoir_C`**. Nothing is built by hand and no material is authored.

**Why it took finding.** UEFN ships 35 built-in post process effects and **none of them is
named grayscale.** Searching the list for "gray", "black" and "sat" all return nothing, or
return `PP_Blackout_C`, which blacks the screen out entirely and is not what 3.4 asks for.
The black-and-white effect is called `PP_FilmNoir_C`, because film noir is black and white.
Found by reading the full A-G list rather than searching it.

**Backups if it reads wrong in play:** `PP_ComicNoir_C`, `PP_Desolate_C`.

**A correction to how the device works.** `DeathSaveManager.verse` originally said the
grayscale look is "configured on the placed device, exactly like the camera and controls
devices." That is wrong. The Post Process Device has **no saturation, colour or contrast
settings at all.** Its complete User Options are Enabled During Phase, Post Process Effect
and Effect Duration, plus Priority, Starting Strength, Blend in Strength, Blend in
Duration, Blend Out Duration, Applies to Team and Applies to Class under Advanced. The look
lives entirely in the effect asset dropped into that one slot. The device is a player, not
a mixing desk.

**Still open from 3.4:** the slow motion. There is no time dilation anywhere in the three
digests, and no ruling has been made on a substitute. The grayscale carries the moment
alone until there is one.

---

## 10. The Death Save slow motion becomes a longer real countdown

**What the GDD says.** Section 3.4: "Taking a fatal blow triggers a 3-second 'Death Save'
slow-motion countdown. Gameplay slows to a crawl, the screen desaturates to grayscale."

**What was built.** A 5-second countdown at normal speed. The grayscale is unchanged and
works; see item 9.

**Why. The slow motion cannot be built at all.** There is no time dilation anywhere in the
Fortnite, UnrealEngine or Verse digests. Not a device, not a function, not a setting: zero
mentions across all three. This is not a limitation that can be worked around from Verse,
because the capability does not exist to reach.

**Why 5 seconds rather than 3.** Slow motion in 3.4 is a means, not an end. Its job is to
make three seconds *feel* like long enough to see what happened, find the Sponsor Aid and
run to it. Playtested at 3 seconds and real time, it is not long enough: the window is
spent registering that something happened rather than reacting to it. Extending the real
countdown delivers 3.4's intent through the only mechanism the engine offers.

**Kailee's ruling, 2026-08-16.** The number is `CountdownSeconds` on the placed device and
stays tunable. If a substitute for the slow motion is ever found, this should come back
down towards 3.

**What is NOT changed.** Everything else in 3.4 stands: once per run, the grayscale, the
Sponsor Aid always spawning within easy walking distance, and the Hype Call rescue
teleport when the Hype meter grows tiers.

---

## 11. Player health is 200, and the GDD never specified it

**What the GDD says.** Nothing. Searched end to end: the document never states a player
health value, never states enemy damage, and never gives the player a starting shield.

Everything it does say about health is relative, and all of it depends on a pool size the
document leaves open: the Underdog Boost at "below 40%" (3.1), the Sponsor Aid restoring
"25% of the contestant's maximum health pool" (3.3), and the loss state when health "is
depleted to zero" (2.5). The nearest hint is 5.3 blocking spawns within 3 metres "to
prevent instant collision damage", which implies contact damage was expected to hurt.

**What was set. Max Health 200**, in Island Settings, Player. Kailee's call, 2026-08-16.

**Measured, not guessed.** A hit-logging line was added to `DeathSaveManager.verse` and a
playtest recorded every drop in health. **Every hostile hit does exactly 20 damage**, with
no variation at all:

```
250 -> 230 -> 210 -> 190 -> 170 -> 150 -> 130 -> 110 -> 90 -> 70 -> 50 -> 30 -> 10
```

So 200 health is exactly **10 hits**. 100, Fortnite's default, was 5.

**Why 10.** Twin-stick shooters split two ways. Arcade ones, Smash TV and Robotron, kill
in one or two hits but hand out three lives a credit. Horde survivors, which GDD 1.1 names
as this game's model via Vampire Survivors, give a large pool and let enemies chip at it,
so survival is crowd management rather than never being touched.

This game is the second kind and stricter than either, because GDD 3.4 grants **one** Death
Save per run and there are no lives at all. At 100 health a run could end in seconds. At
200 a single mistake costs real health without ending the run, being surrounded is
genuinely dangerous, and the 40% Underdog Boost threshold sits at 80 health, four hits from
the end, so it becomes a state the player fights inside rather than a number they flash
past on the way down.

---

# OPEN QUESTIONS FROM THE GDD REVIEW, 2026-08-16

A full read of `Kailee_Nekoba_GDD_Final_Draft.pdf` against the build. Twelve findings,
split by whether they stop work or only need the document tidied.

**None of these may still be open when the game ships.** Mark each RESOLVED here as it is
answered, with the ruling and its date.

| # | Question | Status |
|---|---|---|
| 12 | Career Sponsor Rank thresholds | **BLOCKS THE BUILD** — open |
| 13 | Hype tier boundaries | **BLOCKS THE BUILD** — open |
| 14 | Sponsor Aid heal vs the anti-chain rule | **BLOCKS THE BUILD** — open |
| 15 | Weapon damage values | **BLOCKS THE BUILD** — open |
| 16 | Eight on-paper contradictions (a-h) | DOCUMENTATION ONLY — open |

---

## 12. Career Sponsor Rank has five titles and no thresholds — BLOCKS THE BUILD

**What the GDD says.** Section 2.6 names the full ladder: Debt-Ridden Rookie, Undercard
Filler, Fan Favorite, Ratings Magnet, The Network's Sweetheart. At run termination the
game "compares the final score and highest tier reached against the player's saved
records," and "beating either threshold advances the rank."

**What is missing.** The thresholds. The GDD never states what score, or what Escalation
Tier, moves the player from one title to the next. It gives no number for any of the five.

**Why it blocks the build.** Career Sponsor Rank is named uncuttable in 5.7 and is the
Week 4 item in the 5.6 timeline. It cannot be written without four sets of numbers, since
Rookie is the starting state and four promotions follow. "Beating either threshold" is
separately ambiguous: it can mean clearing a fixed ladder value, or beating the player's
own previous best. Those are two different features with two different save files.

**What Kai needs to decide.** Whether promotion is measured against fixed numbers or
against the player's own record; and the four score-and-tier pairs that trigger each
promotion.

---

## 13. The Hype tiers have no boundaries — BLOCKS THE BUILD

**What the GDD says.** Underdog, Rising Star and Superstar appear three times: in 3.1 as
what "active Hype levels determine," in 3.2 as the paraglider crate quality tiers, and in
3.4 as the Death Save survival rates, 35% at Underdog, 50% at Rising Star, 65% at
Superstar.

**What is missing.** The Hype values that separate them. Section 3.1 defines the meter's
sources, its Underdog Boost, its 5%-per-10-seconds decay and its manual Call, but never
says which meter reading counts as which tier.

**Why it blocks the build.** Two unbuilt systems read these tiers: crate quality in 3.2
and rescue odds in 3.4. `HypeMeterManager.verse` currently tracks a single 0-to-100 value
with no concept of a tier at all. Nothing that consumes a tier can be written until the
bands exist.

**What Kai needs to decide.** The two cut points on the 0-to-100 meter that divide the
three tiers.

---

## 14. Sponsor Aid heals to exactly the number the anti-chain rule kills at — BLOCKS THE BUILD

**This one is internal to the GDD.** It is not a build divergence.

**What Section 3.3 says.** Sponsor Aid "restores 25% of the contestant's maximum health
pool immediately upon collision pickup."

**What Section 3.4 says.** "A second fatal blow taken before the player's health
regenerates above 25% results in instant run termination."

**The collision.** A Death Save revive *is* a Sponsor Aid pickup. At Max Health 200, set
in item 11 of this file, it puts the player on exactly 50 health, which is exactly 25%.
That is not *above* 25%. Read literally, every successful rescue lands the player in the
state the anti-chain rule treats as instant death, and leaves them there. The GDD
describes no other source of healing, and mentions health regeneration nowhere else,
despite 3.4 leaning on the word "regenerates."

**Why it blocks the build.** Both halves are unwritten. Whoever writes them has to pick a
reading, and the two readings produce opposite games: one where a rescue buys real
breathing room, one where it buys none.

**What Kai needs to decide.** Which number moves: the size of the heal, the 25% threshold,
or the comparison from "above" to "at or above". And separately, whether health
regenerates at all, since 3.4 assumes something that nothing else in the GDD provides.

---

## 15. No weapon does a stated amount of damage — BLOCKS THE BUILD

**What the GDD says.** Section 3.3 describes all four weapons closely: fire rates,
magazine sizes, reload times, colours, sounds, tactical roles. The Submachine Gun's bleed
is "5 damage/second over 3 seconds."

**What is missing.** Every other damage number. The Pulse Blaster, the Shotgun's five
pellets, the Sniper's piercing beam and the Flaming Ammo burn tick all have behaviour
described and no value attached. That bleed figure is the only hard damage number in the
entire document.

**Why it blocks the build.** The three crate weapons are the Week 2 item in 5.6 and are
not built. Item 11 of this file settled the other side of the combat math by measurement:
the player has 200 health and every hostile hit does exactly 20. The player's own output
is still open, and unlike enemy damage it cannot be measured, because the weapons do not
exist yet to measure.

**What Kai needs to decide.** How many hits each weapon should take to kill a 40-health
Swarmer. That is the readable way to set this; the per-shot numbers fall out of it.

---

## 16. Eight places where the GDD disagrees with itself on paper — DOCUMENTATION ONLY

**None of these changes what gets built.** Each is a wording or bookkeeping conflict
inside the document. They are grouped as one item deliberately: they are clearable in a
single editing pass over the GDD, and none of them needs a design decision.

**a. Section 4 forbids in 4.1 what it shows in 4.2.** 4.1 says the four agents are
"strictly prohibited from communicating or prompting one another directly," with the
designer as "an absolute checkpoint." 4.2's table then shows Playtest QA sending "Code
Patch Diffs" to Gameplay Systems, and Simulated Audience firing "#DeathSaveTriggered" at
Announcer Bark. 4.2 is describing the finished game's systems talking at runtime, which is
not agents prompting each other, but every row is labelled "Agent," so it reads as a
direct violation of the rule one paragraph above. The fix is in the labels, not the design.

**b. The stream chat widget holds three statuses at once.** 3.5 calls it a stretch goal.
5.7 makes it cut number 1. 5.4 lists it as one of exactly 3 required MVP HUD widgets, and
2.4 builds Room-Loop 5 around unlocking it. Performing cut 1, as the GDD instructs, breaks
the MVP list and deletes an onboarding step.

**c. The MVP boost count only reaches 4 by counting a stretch goal.** 5.4 commits to "4
boost profiles." The four are Sponsor Aid, Sponsor Aegis, Flaming Ammo and Icy Rounds, and
3.3 labels Icy Rounds "Stretch Goal." Performing cut 2 drops the count to 3, below the
stated MVP.

**d. Room-Loop 3 does not exist.** The 2.4 onboarding ramp lists Room-Loop 1, 2, 4 and 5.
Loop 3 is skipped without comment.

**e. The win state resets obstacles that nothing else in the GDD ever moves.** 2.5 says
that on a room win "environmental coordinates and concrete obstacles reset." That describes
a shifting arena layout. No such system appears in 5.4's asset list, in 5.6's timeline, or
in any agent's duties in Section 4. This is the one entry in this group that could turn out
to be real work rather than wording, depending on what "reset" was meant to mean.

**f. The first-life ramp removes one of the two Death Save escapes.** 2.4 deactivates Hype
systems for Room-Loop 1. 3.4 makes the Hype Call rescue teleport one of the two ways to
survive a fatal blow. A first-life Room-Loop 1 death therefore has only the manual turkey
leg run available. The GDD never says so. This becomes a build question only if the
onboarding ramp is built.

**g. The timeline is a week shorter than the course.** 5.6 runs six weeks and ships Sep 1.
The class runs seven. The GDD is planning against less runway than actually exists.

**h. The token budget reserves 20% for a system that costs nothing.** 5.7 splits 4,500,000
cloud tokens with 20% to QA, then states in the same paragraph that the QA log parser
"utilizes a free, locally-hosted Llama-3 model." Item 3 of this file already records that
the QA agent was built on Claude instead, which changes the reasoning but not the
arithmetic.

**Enemy damage does not scale with tier**, and that matches the GDD. Section 5.5 scales
hostile health pools, movement speeds and spawn densities. It never mentions their damage.
So 20 per hit holds from Tier 1 to Tier 21, and the late game gets harder through more
hostiles that are harder to kill, not through harder hits.

**Still no starting shield, deliberately.** The GDD's only shield is Sponsor Aegis (3.3),
a crate pickup that "absorbs up to 3 hostile hits". It is one of the four upgrade slots in
3.2, something earned mid-run, not starting equipment.
