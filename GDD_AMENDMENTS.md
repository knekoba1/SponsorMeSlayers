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

## 4. The enemy roster contradicts itself — RESOLVED 2026-08-17

**Resolved.** Four hostile types ship: the melee Cyber-Swarmer, the heavy Ranged Tank,
the Ranged Sentinel and the armored Cyber-Boar. The Ranged Tank and the Ranged Sentinel
are **two different enemies**, not two names for one.

**What Section 3.3 says.** The weapon table names three hostile types in its tactical
effects: "Cyber-Swarmers" (Submachine Gun row), "armored **Cyber-Boars**" (Shotgun row),
and "distant, stationary **Ranged Sentinels**" (Sponsor Sniper row).

**What Section 5.4 says.** The MVP asset ceiling funds "2 cybernetic hostile models
(melee Swarmer, **heavy Ranged Tank**)."

**The conflict.** Cyber-Boars had no model budgeted anywhere in the document. The ranged
enemy is called "Ranged Sentinels" in 3.3 and "heavy Ranged Tank" in 5.4, which could
have been two names for one enemy or two different enemies. Three weapon effects in 3.3,
the Shotgun's chain knockback in particular, were written against enemies the MVP did
not fund.

**Kailee's ruling, 2026-08-17.** Four types, and the two ranged enemies are separate.
This raises Section 5.4's ceiling from 2 cybernetic hostile models to 4, and it makes
3.3's weapon effects buildable as written: the Shotgun's chain knockback needs
Cyber-Boars, and the Sponsor Sniper's piercing beam needs Ranged Sentinels.

**What the ruling costs.** Almost nothing in art. The one hostile built so far,
`CyberSwarmerMelee`, is a Guard with adjusted health and speed (item 2), so a new type
is a new `npc_character_definition` asset rather than a new model, and four types do not
spend four models' worth of 5.4's art budget. The real cost is one `npc_spawner_device`
per type: `WaveManager.verse` records that `SetNPCCharacterDefinition` is refused when
the character type differs, so the four cannot share a spawner. Four spawners count
against the prop budget in GDD 5.3, and the 40-bot concurrency cap is shared across all
of them.

**What is built.** Nothing yet in UEFN. The stat cards exist as data only, fifteen cards
across the three new types, in `pipelines/assignment-06-ger/output/tier-cards.csv`. The
Ranged Tank and Ranged Sentinel ladders are safe to build now. **The Cyber-Boar ladder is
not**, until the player's run speed is measured: its top card fails by 0.02 m/s if the
real figure turns out to be 5.0 m/s rather than the assumed 6.0. See item 8.

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
| 12 | Career Sponsor Rank thresholds | **RESOLVED 2026-08-16** |
| 13 | Hype tier boundaries | **RESOLVED 2026-08-18** |
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

### KAILEE'S RULING, 2026-08-16

Eight questions were worked one at a time before any code was written. The rulings:

**Promotion is measured against fixed targets, not the player's own record.**

| Rank | Tier threshold | Best-run score threshold |
|---|---|---|
| Debt-Ridden Rookie | starting rank | starting rank |
| Undercard Filler | 3 | 1,000 |
| Fan Favorite | 7 | 2,500 |
| Ratings Magnet | 13 | 6,500 |
| The Network's Sweetheart | 21 | 15,000 |

All eight numbers ship as `@editable` and must be mirrored back into the script when tuned,
per the house rule in CLAUDE.md section 10.

*Why fixed rather than personal-best.* The five titles are the Network's opinion of the
contestant, and status in a show's eyes implies a standard everyone is measured against.
Under a personal-best ladder every player reaches The Network's Sweetheart in roughly five
runs and the title stops meaning anything; 2.6 makes the rank purely cosmetic, and a
cosmetic badge only carries weight if it is hard to get. **The literal wording of 2.6,
"against the player's saved records," arguably supports the personal-best reading. This is
a deliberate departure from it on design grounds, not a claim that the GDD said so.**

*Why these numbers.* Tier 3 is reachable within a couple of rooms, so no player stalls at
Rookie, which matters because 2.6's stated purpose is to incentivise repeat play. Tier 21 is
the hard cap in 5.5, so the top title means reaching the ceiling. The score column
approximates the drops collected on the way to each tier (`WaveSize` 10 at Tier 1,
`ItemsPerKill` 3, both scaling 8% per tier), so neither route is the soft option.

*The score rate was measured, not assumed.* The first draft of these thresholds guessed 100
points per pickup and was ten times too large. `hello_world_device.verse` line 303 awards
**10 per pickup** (`set RunScore += 10`), and the table above is corrected to match. The
same investigation found that the `score_manager_device` route has never worked at all;
see `BUILD_ORDER.md` item 25.

**Rank is set by the best single run. The lifetime bankroll is tracked and displayed, but
does not drive the rank.**

2.1 step 6 and 2.6 describe two different systems. "Accumulate" and "increment" mean a
lifetime total; "final score compared against saved records" means a personal best. Both
sentences stay true under this ruling: the bankroll accumulates and is shown on the title
card as career earnings, while the rank is driven by the best run. The only clause that no
longer holds is 2.1's claim that the bankroll is what *increments* the rank.

*The decisive argument against a lifetime total.* Highest-tier-reached cannot accumulate; it
is inherently a best-ever number. If score were a lifetime total it would cross every
threshold eventually regardless of skill, at which point the tier half of the ladder would
never fire again and half the system would be dead.

**One promotion per run, maximum.** A run qualifying for several ranks advances one, and
banked records keep paying out one promotion per subsequent run until the rank catches up.
**This requires a saved current rank held separately from the saved best records.** It costs
a strong player short-term accuracy and buys every player seeing all five title cards and
hearing all their barks rather than skipping past content that was paid for.

**Rank never falls.** The GDD only ever says "advances." A career record is cumulative by
definition, and rank derives from best-ever numbers, which cannot decrease; demotion would
need a second "current form" concept fighting the first. The comedy of a hostile Network is
delivered by having the commentator mock a rank rather than remove it.

**Per player.** Each player carries their own rank against their own Epic account, which is
what UEFN persistence gives by default. See item 19 on why more than one player should not
arise.

**The match-start bark is wired now, with a clearly marked empty slot.** Per CLAUDE.md
standing rule 3, Kai writes every line and Claude never drafts one. Four lines are needed,
one per promotion, or five with a Debt-Ridden Rookie opener. These count against the
25-bark budget in 5.4, leaving twenty or twenty-one for everything else.

---

## 13. The Hype tiers have no boundaries — RESOLVED 2026-08-18

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

### KAILEE'S RULING, 2026-08-18

The cut points on the 0-to-100 meter are **40, 75 and 95**. There are **four** tiers,
not three; the fourth is a deliberate departure, recorded as amendment 24.

| Tier | Hype range | Death Save rescue |
|---|---|---|
| Underdog | 0 to 39 | 35% |
| Rising Star | 40 to 74 | 50% |
| Superstar | 75 to 94 | 65% |
| Prime Time | 95 to 100 | 80% |

**Why 40 and 75 rather than even thirds.** Decay runs only during inactivity, and a
player in a fight is never inactive, so Hype trends upward across a room. Even thirds
would park the player in the top tier for most of a match, devaluing the best crate and
handing out the highest rescue odds as the default. GDD 5.7 names Win/Loss resolution
uncuttable, and a rescue that usually works undermines it. The 50/85 alternative was
rejected as the opposite failure: the top tiers would be so rare that the tiered crate
art would seldom be seen.

**What this unblocks.** Crate quality tiers (GDD 3.2, build items 3, 4 and 20) and the
Death Save rescue teleport (GDD 3.4, build item 13). It does **not** settle what makes a
crate fall in the first place, which is still open.

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

**One item off this list, 2026-08-19.** The Flaming Ammo burn tick is settled by
amendment 44 at 5 a second for 3 seconds. The Pulse Blaster, Shotgun and Sniper are
still open, so this still blocks the build.

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

---

## 17. "Locally saved" is not something UEFN can do

**What the GDD says.** Section 2.6 calls Career Sponsor Rank a "**locally-saved**
statistic." Section 2.1, core-loop step 6, repeats it: cash windfalls "**save locally**."

**What is actually true.** This project's Verse digest declares:

```
player := class<unique><persistent><module_scoped_var_weak_map_key>
```

with the note that a `player` may be used as a module-scoped `var` `weak_map` key while
they have joined and not yet left. That is UEFN's only persistence mechanism: a
module-scoped `weak_map` keyed on the player, **saved by Epic to their servers against the
player's Epic account.** There is no writing to the player's disk. Searched the digests for
any file or network capability and found none. "Locally saved" describes something the
engine cannot do; it is not a design choice the GDD made.

**Kailee's ruling, 2026-08-16.** Strike "locally" from 2.6 and 2.1. Persistence is
Epic-account cloud save. Three consequences accepted:

- The rank follows the Epic account across machines, which is arguably better than local.
- The player cannot wipe or edit it, because it is not a file on their drive.
- **A developer-only reset is added**, because a rank accumulates while testing and the
  early ranks would otherwise be untestable after the first few runs.

---

## 18. There is no main menu to put the title card on

**What the GDD says.** Section 2.6: advancing "unlocks a cosmetic holographic host title
card **on the main menu**."

**What is actually true.** UEFN islands have no main menu. There is no title screen and no
options screen to navigate before playing. What exists is the pre-game lobby phase, the
round itself, and HUD widgets drawn from Verse.

**Kailee's ruling, 2026-08-16.** The title card is a **HUD card shown at match start**,
staged together with the commentator bark that 2.6 already pairs with it. This keeps both
halves of the reward in one moment rather than splitting them across two screens, and it
needs no main menu to exist.

The card can be built now. The bark half waits on the bark system, which is Priority 5 item
19 in `BUILD_ORDER.md`, so this ships in two stages and the first depends on nothing
unbuilt.

*Rejected alternatives.* The pre-game lobby is closest to "main menu" in spirit but is
short and easily missed. A permanent holographic billboard in the arena has real support in
1.1's "flashing scoreboard visuals" and may be added later as a second display, but should
not be the primary one: a billboard you walk past is not a reward moment.

**Kailee's further ruling, 2026-08-17.** The card appears at match start **only in the
run following a promotion**. 2.6 makes the card what advancing "unlocks", so showing it
every match start hands an unearned title to a player who has done nothing yet. Between
promotions the rank is checked on demand with the show-card key, now bound to Creative
Input Action Custom 16 (Emote).

---

## 19. The game is single-player

**What the GDD says.** Nothing explicit. It assumes throughout: "**a** contestant," "**the**
player," a "single-room stadium arena," and 5.4 budgets "1 playable contestant model."
Everything is singular and nothing is ever stated as a rule.

**Why it needed deciding.** UEFN islands accept joiners by default, so the question gets
answered by accident if it is not answered on purpose. Three systems are currently built for
exactly one player:

- **`DeathSaveManager.verse` ends the run with an `end_game_device`**, which ends the
  **round**, for everybody. A second player's healthy run would be killed by the first
  player's death, with no Death Save of their own.
- **`WaveManager.verse` scales hostile density by tier, not by headcount.** Two players
  against a one-player wave halves the difficulty.
- **`HypeMeterManager.verse` draws a bar for every player but tracks a single shared
  value.** Two players would fill and spend the same meter.

**Kailee's ruling, 2026-08-16.** Single-player, stated explicitly. Cap the island at one
player in Island Settings. **That field has not been verified to exist and must be confirmed
in UEFN rather than assumed.** Settings of this kind live in Island Settings and are
invisible to the Verse digest, so they cannot be checked from code.

This turns all three faults above into non-issues rather than requiring three systems the
GDD never asked for. Nothing in the document requests multiplayer: 5.4's asset ceilings,
2.5's win/loss conditions and 3.4's whole Death Save design are written for one contestant.

**Enemy damage does not scale with tier**, and that matches the GDD. Section 5.5 scales
hostile health pools, movement speeds and spawn densities. It never mentions their damage.
So 20 per hit holds from Tier 1 to Tier 21, and the late game gets harder through more
hostiles that are harder to kill, not through harder hits.

**Still no starting shield, deliberately.** The GDD's only shield is Sponsor Aegis (3.3),
a crate pickup that "absorbs up to 3 hostile hits". It is one of the four upgrade slots in
3.2, something earned mid-run, not starting equipment.

---

## 20. The score is counted and never shown

**What the GDD says.** 2.3 says walking over loot plays the stinger and "increments the
player's run score". 5.4 then commits to exactly three HUD widgets: the vertical Hype
Meter bar, the Death Save slow-motion overlay, and the simulated streaming text chat
widget. A score readout is not among them, and 2.4 introduces systems gradually to
"prevent HUD clutter".

**Why it needed deciding.** The score has been counted correctly on every pickup since
the cash system was built, and the player has never been able to see it. Showing it adds
a fourth HUD widget, which exceeds a stated MVP ceiling, so it is a change to the design
rather than a missing piece of it.

**Kailee's ruling, 2026-08-17.** Add it. A permanent gold readout in the top-left corner
reading WINNINGS: $0, climbing by 10 per pickup. 1.1 already asks for "flashing
scoreboard visuals", and Smash TV and Total Carnage, the GDD's two stated references,
both keep the score on screen permanently. The stream chat widget is cut number 1 in 5.7,
so the widget count is likely to return to three on its own.

**Related, and left alone.** The same playtest showed loot vanishing before it could be
collected after a busy fight. That is 5.3 working as written: drops despawn "exactly 5
seconds after generation" to protect UEFN's ~100-prop limit. Kai's ruling, 2026-08-17:
leave it at 5 seconds. Collecting as you fight is the twitchier read, and the late game,
which runs about five times denser, has no headroom for a longer timer.

---

## 21. The pistol's "infinite ammo" is one shared pouch, not a property of the gun

**What the GDD says.** Section 3.3 gives the Standard Pulse Blaster as the "Default
infinite ammo weapon. Reliable fallback option when special weapons run out of ammo."
The same table gives the Submachine Gun a "50-round magazine with a 1.2s reload", the
Shotgun a "5-shell tube" and the Sponsor Sniper a "1-round chamber". So 3.3 assumes each
weapon carries its own ammunition, and that the pistol's is bottomless.

**Why it needed deciding.** Fortnite does not track ammunition per weapon. It keeps one
pouch per **ammo type**, Light, Medium, Heavy and Shells, shared by every weapon that
fires that type. There is no per-weapon infinite ammo switch a creator can reach:
`SetShotAmmoCost` belongs to the creator-built weapon system that item 7 above closed
off. So "infinite ammo for the pistol and not for the others" is not something the engine
can express directly. It has to be arranged.

**The Island Settings route, checked and rejected.** Island Settings holds four ammo
options: Auto Pickup Ammo, Infinite Reserve Ammo, Infinite Magazine Ammo and Display
Empty Ammo Slots. **Infinite Reserve Ammo** stops the carried pouch depleting.
**Infinite Magazine Ammo** removes reloading entirely. Both are island-wide and apply to
every weapon in the map, which would feed the crate weapons too and delete 3.3's "when
special weapons run out of ammo" outright. **Kailee's ruling, 2026-08-17: both stay off.**

This was checked first on purpose. Item 7 above records a session mostly lost to searching
device panels for a rule that lived in Island Settings, and "the player never runs out of
ammo" is exactly that shape of rule. This time it was read before any code was proposed,
and it turned out to be the wrong tool for a reason worth recording rather than a right
tool that was missed.

**What was built instead.** `StartingLoadoutManager.verse` drives a second placed Item
Granter, holding Light Ammo, on a repeating timer. Every `AmmoTopUpSeconds` it grants
Light Ammo to every player. It asks rather than checks, because the code cannot see how
much ammo a player is carrying, and Fortnite's own carrying cap absorbs a top-up that was
not needed. **Kailee's call, 2026-08-17: every 5 seconds.**

**The consequence, and the ruling that contains it.** The top-up fills the Light Ammo
pouch, not the pistol. Any weapon firing Light Ammo is fed by it. Of the three crate
weapons in 3.3, the Shotgun (Shells) and the Sponsor Sniper (Heavy) are untouched and
still run dry as written. A stock Fortnite submachine gun fires Light Ammo and would not.

**Kailee's ruling, 2026-08-17: the crate SMG uses Medium Ammo.** 3.3 describes that
weapon by behaviour, rapid parallel yellow laser fire, a 50-round magazine, a 1.2s reload
and the bleed status effect, and never by which Fortnite weapon category it belongs to, so
a Medium-ammo weapon satisfies every word of it. Building it on Light Ammo would hand it
infinite ammo silently, and the fault would present as "the SMG is just better than the
pistol forever" rather than as an ammo bug. Recorded on `BUILD_ORDER.md` item 5, which is
not yet started, so this costs nothing now.

**Auto Pickup Ammo is on. Kailee's ruling, 2026-08-17.** A top-up handed to a player
already at the carrying cap may drop the surplus on the floor, and floor props count
against 5.3's roughly 100-prop budget, every five seconds, for a whole match. Auto pickup
returns the surplus on contact instead of letting it pile up. It also matches 2.3, where
there is no pickup button and contact is the interaction.

**What the settings actually turned out to be, read by hand in UEFN 5.8 on 2026-08-17.**
Auto Pickup Ammo is a dropdown, not a tickbox: No, Yes, Auto Only, Default. Set to
**Yes**, since Default leaves the behaviour inherited and unknown, which is the thing
being removed. Infinite Magazine Ammo is a tickbox and is clear. An Item Granter **will**
hold ammo: Light Ammo is in the Item Definition picker, quantity 100 per grant.

**The two granter settings that would have broken this silently.** Equip Granted Item
must be UNTICKED, or every top-up snatches at the player's hands. **On Grant Action must
be Keep All**; its other three options are Clear Inventory, Clear Items and Clear
Resources, and any of them would strip the crate weapon this top-up exists to back up,
every five seconds, for a whole match. Neither fault would look like an ammo fault.

**Playtested and confirmed working, 2026-08-17.** The pistol never ran dry under
sustained fire. No ammo accumulated on the arena floor, so the surplus is either
discarded silently or returned instantly by Auto Pickup Ammo, and either way 5.3's prop
budget is not being spent on it. Nothing snatched at the weapon in hand on the five
second beat, which clears Equip Granted Item and On Grant Action as correctly set. This
half of 3.3 is closed.

**The one thing still unverified**, and it cannot be tested until item 5 exists: whether
the crate weapons' ammo types are as assumed above. Each weapon's ammo type is visible in
UEFN when the weapon is chosen, and must be read there rather than assumed. The Medium
Ammo ruling stands or falls on it.

---

## 22. The Career Rank save never survives, because the project has no valid domain — OPEN

**What the GDD says.** Section 2.6 makes Career Sponsor Rank persist between runs, and
5.7 names it one of four uncuttable features.

**The logic works. This was proven, not assumed.** On 2026-08-18 at 00:47 UTC the game
printed:

    DEBUG: Promoted to Undercard Filler. Records qualify for Undercard Filler, so 0 further promotion(s) are banked.
    DEBUG: Career saved -- rank 1, best tier 3, best score 640, lifetime 640

A run reached Tier 3, ended, and the ladder in `CareerRankManager.verse` promoted
correctly and banked the result. Item 1 of `BUILD_ORDER.md` had been waiting to see that
happen, and it had already happened.

**The save does not survive. Every run loads a blank record.** Five saves across four
editor sessions, read out of the UEFN logs:

| Time (UTC) | What was saved | What it should have said |
|---|---|---|
| 2026-08-17 04:41 | best tier 2, lifetime 250 | first record |
| 2026-08-17 23:52 | tier 1, score 200, lifetime 200 | tier 2, lifetime 450 |
| 2026-08-18 00:21 | tier 1, score 90, lifetime 90 | tier 2, lifetime 540 |
| 2026-08-18 00:47 | rank 1, tier 3, score 640, lifetime 640 | lifetime 730 |
| 2026-08-18 02:07 | rank 0, tier 1, score 0, lifetime 0 | rank 1, tier 3, lifetime 1370 |

Three of those are inside a single editor session, so this is not only lost when UEFN
closes. It is lost between playtests. The last row is decisive on its own: the rank fell
from 1 to 0, and `RankIndex` is only ever written upward, so nothing overwrote it. It was
not there to read.

This also explains the "Career earnings: $0" line seen on the title card. That was never
a display fault.

**Why. The project has no valid Verse domain.** `SponsorMeSlayers_v2.uplugin` declares
`"VersePath": "/invaliddomain/SponsorMeSlayers_v2"`, and `SponsorMeSlayers_v2.uefnproject`
leaves `projectVersePath` empty. Every playtest the engine then logs:

    LogVerseSaveService: VOS: FVerseSaveService::OnPersistentMapConstructed called.
    Path=[invaliddomain/SponsorMeSlayers_v2.CareerRecords]

`CareerRecords` is the module-scoped `weak_map` in `CareerRankManager.verse`. It is being
constructed under a domain the engine itself calls invalid, and it comes back empty every
time.

**This is not a fault in this project.** `C:\GameDev\SponsorMeSlayers` and the frozen
OneDrive backup both carry the same `/invaliddomain/` Verse path. It is the normal state
of a UEFN project that has never been published. A project is given its real domain under
the creator's name when it is published.

**Two things ruled out first, so nobody re-checks them.** The developer reset cannot be
the cause: `DevResetEnabled` is `false` in the script and is not overridden on the placed
device, and the reset trigger is only subscribed to when it is true. And the save format
has never changed: `career_record` has carried the same five fields since commit
`62f3a5e`, so no old save was ever invalidated by a schema change.

**What is NOT confirmed.** That publishing fixes it. That is an inference from the
evidence above, and the only way to know is to publish a private version and repeat the
test. Kai's Epic account is enrolled in the Island Creator Program, confirmed 2026-08-17,
so the route is open.

**OPEN. This blocks verification of an uncuttable feature and must be closed before
submission**, per the ship gate. What needs deciding is whether to publish a private
version to prove persistence, and when.

**Where to look again.** UEFN logs live in
`C:\Users\kaile\AppData\Local\UnrealEditorFortnite\Saved\Logs\`. Search them for
`Career saved` and `OnPersistentMapConstructed`.

---

## 23. The buzzer, the second buzzer, and what "reset" means — RESOLVED 2026-08-17

**What the GDD says.** Section 2.5's Win State: a room is cleared when the player
"eliminates all spawned waves in the active Escalation Tier. A loud game-show buzzer
sounds, environmental coordinates and concrete obstacles reset, and the next Escalation
Tier begins." Section 1.1 lists under Audio FX "a satirical game-show buzzer at wave
completion". Section 5.4 budgets "2 game-show buzzer sound effects".

**Four things needed deciding before any of it could be built.**

**1. One wave is one room. Recorded, not decided.** `WaveManager.verse` advances the
Escalation Tier after every cleared wave, so a tier holds exactly one wave. That makes
1.1's "wave completion" and 2.5's "room cleared" the same instant, and both buzzer
descriptions land together. 2.5's plural, "all spawned wave**s**", implies more than one
wave per tier, which the build does not do. Nothing is broken by this today. It matters
only if a tier ever gains a second wave, at which point the two descriptions split.

**2. The buzzer sounds at Tier 21. Kailee's ruling, 2026-08-17.** Tier 21 is the hard cap
in 5.5. Past it waves keep coming at the same size and the tier stops climbing, so 2.5's
"the next Escalation Tier begins" never happens again. The buzzer still sounds for every
cleared wave. 1.1 ties it to wave completion and never mentions tiers, and a reward sound
that vanished exactly when the player is doing best would read as a fault.

**3. The second buzzer is the Run Lost buzzer. Kailee's ruling, 2026-08-17.** 5.4 pays
for two and the GDD gives only one a job. 2.5 presents Win State and Loss State as the two
halves of one section, and the Loss State had no sound of its own: 3.4 gives the Death
Save window a commentator scream, but the moment the run actually ends is silent. It is
sounded from `DeathSaveManager.EndRun`, a different and uglier sound from the win.

**4. "Environmental coordinates and concrete obstacles reset" means the obstacles return
to where they started, undamaged. Kailee's ruling, 2026-08-17.**

This has a cost that should be stated plainly. **GDD 1.1 calls the obstacles static.** A
static, indestructible obstacle has nothing to reset, so this ruling requires them to be
damageable or movable during a fight. That is a departure from 1.1's wording, made
deliberately so 2.5's sentence describes a real feature rather than flavour text.

The two rejected readings, recorded so they are not re-proposed: that the arena
**rearranges** into a new layout each tier, which is the most interesting version and best
for repeat play but spends heavily against 5.3's roughly 100-prop ceiling and the 6-week
schedule; and that **nothing physically moves** and the line is flavour, which is cheapest
and honest about "static" but deletes a stated feature.

**What was built, and what was not.** The buzzers are built. `WaveManager.CompleteWave`
sounds the win buzzer, `DeathSaveManager.EndRun` sounds the losing one, each driven by a
placed Audio Player device.

**The reset is not built, and could not be.** The two obstacle types of 1.1, electrical
power grids and broken concrete debris, are `BUILD_ORDER.md` item 14 and do not exist.
There is nothing in the arena to reset. Kailee's ruling, 2026-08-17: build the buzzers now
and move the reset to sit with item 14, so it lands when the obstacles do.

**Unverified until playtested.** Whether the losing buzzer is cut off by the match ending
immediately after it. If it is clipped, a short pause before `RunEnder.Activate` is the
fix.


---

## 24. A fourth Hype tier, "Prime Time" — KAILEE'S RULING, 2026-08-18

**This is a departure from the GDD, not a gap in it.** Sections 3.1, 3.2 and 3.4 each
name exactly three Hype tiers, and 3.4 gives exactly three rescue percentages to match.
Kai asked for a fourth, deliberately hard to reach, and ruled it in on 2026-08-18 after
the cost was stated plainly. The four bands are tabled under question 13.

**Why 95 to 100.** The meter decays 5% per 10 seconds of inactivity only, so from a full
meter one quiet tick leaves the player still inside the band and two knocks them out.
That is the narrowest window that can still be enjoyed for a beat. Rejected: 99 to 100,
lost on the first tick and reading as a flicker rather than an achievement; and 90 to
100, comfortably holdable but squeezing Superstar down to fifteen points.

**Why 80%.** The GDD's own three rescue rates climb in even steps of fifteen, 35, 50, 65.
80 continues that pattern and still leaves roughly one death in five that no amount of
showboating survives. Rejected: 90% and a flat 100%, both of which turn the top tier into
a get-out-of-death-free card, held in check only by 3.4's once-per-life rule.

**What this costs.** A fourth paraglider colour and a fourth grade of crate, on top of
the three GDD 3.2 already asks for. Tiered crate scaling is cut 4 in GDD 5.7, the last of
the four cuts, so this is the least exposed place in the game to add work. If that cut is
ever performed, all four tiers collapse together and nothing here needs unpicking.

**Naming.** "Prime Time" is Kai's, chosen 2026-08-18 from a shortlist, and deliberately
kept clear of the Career Sponsor Rank titles in 2.6 so the two ladders do not blur.

---

## 25. When a paraglider crate falls — KAILEE'S RULING, 2026-08-18

**What the GDD says.** 2.1 step 3: "Crossing Hype thresholds prompts the simulated,
televised streaming audience to parachute supply crates directly into the arena." 3.1:
"Active Hype levels determine the quality tier of falling paraglider supply crates."

**Why it needed deciding.** Read literally, a crate falls only when a threshold is
crossed. There are three thresholds, and the meter rarely falls far enough to re-cross
one, so a whole run would deliver three or four crates. 2.1 calls the loop "recursive"
and makes equipping crates step 4 of six; at three crates a run, two of the six steps
barely happen.

**Kailee's ruling, 2026-08-18: both triggers.** A crate falls on climbing into a higher
tier, graded at the tier just entered, which is 2.1's threshold crossing kept exactly as
written. A further crate falls on a repeating trickle, graded at whatever tier the player
is in when it lands. The trickle default is **25 seconds**, an `@editable` meant to be
tuned by feel.

**Rejected.** Timer only, which makes crossing a threshold meaningless and departs from
2.1. And crossing only, which is faithful and leaves the core loop running at four of six
steps.

**Where it lives.** `SimulatedAudience.verse`. The meter is not spent when a crate drops,
so there is nothing to farm: crossings only pay upward.

---

## 26. What is inside a paraglider crate — KAILEE'S RULING, 2026-08-18

**What the GDD says.** 3.2: crates "trigger instantly upon player collision", the player
"features four upgrade slots: Weapon, Consumable, Shield, and Ammo Modifier", and the
paragliders are "high-contrast colored" to "denote their quality tier".

**What is missing.** Whether one crate holds one item or a set, and what "quality tier"
actually buys. The GDD never says either.

**Kailee's ruling, 2026-08-18.** **One item per crate, always. The tier decides how good
that item is.** A low-tier crate draws from the weaker end of 3.3's list, a Prime Time
crate from the best.

**Rejected, and why.** *Potency scaling*, where any item can come from any crate but hits
harder at higher tiers: Fortnite may not let a creator change a weapon's damage at all
(see item 7), so it could half-work. *More items at higher tiers*: a Prime Time crate
handing over a full re-kit would flatten the room it dropped into and turn the top tier
into a win button.

**Engine note, checked 2026-08-18.** `supply_drop_spawner_device` is the right device and
does what 3.2 describes, with one wrinkle each way. Its Supply FXColor is a colour
picker, so 3.2's colour coding is achievable with one device per tier. Its contents are an
Item List set in the editor and unreachable from Verse, and its crates are opened by
holding a key rather than by collision, which 3.2 forbids. Both are solved the same way:
leave the Item List **empty**, use the crate as the delivery vehicle, and grant the item
from Verse on contact. `Open(Agent)` and `DestroySpawnedDrops()` are both callable, and
Spawn Delay must be set to **Off** or a crate falls at match start.

---

## 27. A crate does not take the pistol away — CONFIRMED BY KAILEE, 2026-08-18

**The contradiction.** 2.1 step 4 says touching a crate "instantly equips specialized
weapons or shields into the player's active slots, **replacing standard gear**". 3.3 calls
the Standard Pulse Blaster the "**reliable fallback option when special weapons run out of
ammo**". If a crate replaces it, there is no fallback to run out of ammo into.

**The ruling, 2026-08-18.** The pistol stays. "Replacing standard gear" is loose wording
and describes the upgrade slots filling, not the sidearm being removed.

**Why this was already settled in practice.** Amendment 21 puts the crate SMG on Medium
Ammo specifically so the Light Ammo top-up does not feed it, and so 3.3's "when special
weapons run out of ammo" stays true. That reasoning only holds if the pistol is still in
the player's hands. Fortnite also keeps both weapons in the inventory by default, so the
engine agrees.

---

## 28. Ordinary kills generate no Hype — KAILEE'S RULING, 2026-08-18

**What the GDD says.** 3.1: "Rapid multi-kills, close-shave dodges, and prize pickups
generate Hype." It never lists plain kills.

**What was built, and why it was wrong.** `HypeMeterManager.verse` paid a flat 15 for
every kill. Two faults followed. Seven kills filled the entire meter, so the player topped
out inside the first wave. And because 3.1's decay only runs during *inactivity*, and a
player in a fight is never inactive, the meter ratcheted to 100 and parked there, which
flattened all four crate tiers from amendment 13 into a single permanent Prime Time.

**Kai's objection, which reshaped the answer.** Two rounds of smaller numbers were both
rejected on the grounds that at Smash TV and Vampire Survivors density "you'll be killing
one after another". That is correct, and it is fatal to the whole approach: if constant
killing is the baseline, counting kills in a window cannot distinguish style from ordinary
play at any threshold.

**Kailee's ruling, 2026-08-18.**

| Event | Hype |
|---|---|
| Cluster kill: 4 hostiles inside 0.4 seconds | **+2** |
| Taking one hostile hit | **-10** |
| Any single kill | **nothing** |

The 0.4-second window is deliberately shorter than the gap between two sequential pistol
kills, so only something that wipes a group at once can reach it. That makes the cluster a
reward for the crate weapons in 3.3 rather than something the sidearm can farm.

**The hit penalty is the important half.** It is what makes the meter fall as well as
rise, and it is why playing safe cannot climb it.

**Genre grounding, researched 2026-08-18.** The mechanic this is modelled on is the
**graze** of Touhou and the CAVE shooters, which exists specifically to reward "surviving
as dangerously as possible", and **Geometry Wars**, which ties its multiplier to chaining
kills *without taking damage*. Both reward risk rather than volume. Sources:
en.touhouwiki.net/wiki/Graze, tvtropes.org "Close-Contact Danger Benefit",
hardcoregaming101.net/graze-counter.

**Still to build: close shaves**, which 3.1 names and which are intended to be the main
earner, because they work at any density and cannot be farmed by killing. Enemy bullets
are not visible to Verse, so a close shave has to mean a hostile physically closed on the
player and was escaped without a hit. `BUILD_ORDER.md` item 9.

---

## 29. The Hype meter always bleeds — KAILEE'S RULING, 2026-08-18

**What the GDD says.** 3.1, one rate only: "The meter decays by 5% every 10 seconds of
**inactivity**."

**Why one rate was not enough.** Kai asked whether the meter could always fall, and it is
the right instinct: with earning tied to inactivity alone, a steady drip of Hype resets
the decay clock forever and the meter never comes down.

**Kailee's ruling, 2026-08-18: both rates.**

| Condition | Rate |
|---|---|
| Always | **-2 every 10 seconds** |
| Nothing earned for 10 seconds | **-5 every 10 seconds**, GDD 3.1's own figure |

On a 0-to-100 meter, 3.1's "5%" is read as 5 points. The constant 2 is the departure and
is what forces the player to out-earn the bleed to climb at all. The GDD's idle rate is
unchanged and still applies as written.

---

## 30. Wave length is fixed; the 8% moves onto density — KAILEE'S RULING, 2026-08-18

**REVERSED 2026-08-22. See amendment 61.** Fixing the head count did the opposite of
what it was for. A fixed count against a crowd that grows 8% a tier means more targets
in reach, so later waves finished FASTER than early ones. Kai spotted it on 2026-08-22.
Wave length is the dial now and it escalates on purpose, under a 2m30 ceiling.

**What the GDD says.** 5.3: "difficulty escalates 8% per tier", hard-capped at Tier 21 at
about 5x starting difficulty. It says **difficulty** escalates. It never says wave size
does.

**Kai's requirement, 2026-08-18.** Every wave should run **1m40 to 2m40**, at every tier.

**Why that conflicts with what was built.** `WaveSize` grew 8% a tier alongside
concurrency. Kai asked for waves of a hundred or more; at 8% compounding, a 250-hostile
Tier 1 wave becomes about 1,100 by Tier 21, which is a ten-minute wave. Fixed length and
growing size cannot both hold.

**Kailee's ruling.** Wave size is **fixed and no longer scales**. The 8% applies to the
concurrent target only, so waves stay the same length and get busier and nastier instead.
Since 5.3 only ever claimed difficulty escalates, nothing departs from the document.

**The numbers, and where they came from.**

| Value | Was | Now | Source |
|---|---|---|---|
| `WaveSize` | 10, scaling | **250, fixed** | measured, see below |
| `ConcurrentAtTier1` | 3 | **20**, then **10** on 2026-08-19 | Kai's ruling on genre density, then on play |
| `SpawnIntervalSeconds` | 0.5 | **0.25** | 2/s could only just match the kill rate |

250 is measured, not guessed. 88 logged kills give a median of 1 kill a second while
throttled by 3-at-once, and 3.3 a second in bursts when targets are actually available.
At 20 on screen the player is rarely waiting, so about 2 a second, which puts 250 at
roughly two minutes.

**Why 3 became 20.** The GDD's stated references are Smash TV and Total Carnage, which
flood the screen, and 3 at a time is a queue rather than a rush. The old 3 came from a
playtest that found five unsurvivable, but that test predates the 2026-08-17 fix that
stopped the pistol running dry, so it judged a fight in which the player could be caught
in a crowd with an empty gun. Every hostile in the map is melee, and GDD 2.2's kiting
exists to handle crowds.

**A device setting was capping all of this, found 2026-08-18.** The NPC Spawner's own
Spawn Count sat at 5 and silently overrode everything Verse asked for; the arena peaked
at 5 alive against a target of 20. Raised to 20. Total Spawn Limit is greyed out and not
in effect. **Any future change to density has to be made in both places.**

**RESOLVED 2026-08-19: down to 10, and explicitly temporary.** At 20 on screen with only
the pistol, the measured kill rate collapsed to **0.18 a second** against the 2 a second
the 250 was sized on: 22 seconds of play produced 4 kills. Kai played it again on
2026-08-19, could not get around the crowd, and asked to be made faster. Speed was not the
fault; amendment 31 measured 11.90 m/s against a hostile top speed of 5.6. Kai ruled the
drop to **10**, changed in the script and on the placed device. It rises again once the
crate weapons exist, because the arsenal is the bottleneck, not the density. It also makes
the four-kills-in-0.4-seconds cluster reachable, which matters because that is the only
Hype source built, so the upper crate tiers were unreachable in play. The NPC Spawner's
own Spawn Count stays at 20: it is a ceiling, not a target, so a target of 10 fits under
it untouched.

**Still open.** Once the tougher hostile definitions engage, kill rate falls and waves
will run past 2m40, which is trimmed by lowering `WaveSize`.

---

## 31. The player's run speed, measured at last — 11.90 m/s, 2026-08-18

**What amendment 8 assumed.** 6.0 m/s, from "an assumed Fortnite base of about 5.0 m/s
times the Movement Speed Multiplier of 1.2". It states plainly: "The 5.0 base has never
been measured," and marks the T3, T4 and T5 hostile cards **PROVISIONAL** because of it.

**The measurement.** `fort_character.GetLinearVelocity()`, whose own comment gives the
units as metres per second (Fortnite digest 8440), sampled ten times a second and reported
on each new maximum. Added to the existing `AimRotationProbe.verse` rather than a new
device, since it is already placed and already read-only. Playtested 2026-08-18 by running
flat out in a straight line.

**The result: 11.90 m/s.** Nearly double the assumption.

**What it settles.** Every hostile card is safe by a wide margin, T5 included at 5.6 m/s.
GDD 2.2's kiting is in no danger, and 2.6's rank ladder cannot flatten the way amendment 8
feared. **The PROVISIONAL marks come off.** There is also substantial headroom to make
hostiles faster than amendment 8's cautious table if the late game needs it.

**It also answers a different question.** Kai reported feeling slow. At 11.90 m/s against
a fastest enemy of 5.6 that is not a speed problem; it is being swarmed by twenty hostiles
with a weapon that kills one at a time. See item 30.

---

## 32. The slow motion CAN be built. Amendment 10's conclusion is superseded — 2026-08-18

**What amendment 10 concluded.** That GDD 3.4's slow motion "cannot be built at all"
because "there is no time dilation anywhere in the Fortnite, UnrealEngine or Verse
digests", and that 3 seconds of slowed time should be delivered as 5 real seconds instead.

**What it got right, and what it missed.** It is correct that there is no time dilation. It
only ever looked at slowing the world, and never at the two halves of the relative effect:
**the hostiles can be slowed and the player can be sped up.**

**What is available, checked 2026-08-18.**

  * `GetNavigatable()` on a `fort_character` is **public**, and the interface it returns
    carries `SetMovementSpeedMultiplier`, documented as "clamped between 0.5 and 2". So
    hostile movement can be halved from Verse. 0.5 is the floor.
  * `movement_modulator_device`, "used to temporarily modify the speed of agents", takes
    `Activate(Agent)` and `Deactivate(Agent)`, so the player can be boosted for exactly
    the length of the window.

**Kai's idea and ruling, 2026-08-18.** Do both. Hostiles to **0.5x**, player to **1.5x**
via a placed Movement Modulator, giving the player **three times** the hostiles' speed for
the duration. Seen from a locked overhead camera, that reads as slow motion.

**So `CountdownSeconds` returns to 3**, GDD 3.4's own figure. Amendment 10 asked for
exactly this: "If a substitute for the slow motion is ever found, this should come back
down towards 3." The stretch to 5 was the workaround, not the design.

**The honest limit.** It slows hostile *movement* only. Attacks, animations and any
projectile still run at full speed, so a ranged hostile would not feel slowed in any way
that matters. None are built, so this costs nothing today and should be re-examined with
build item 17.

**Implementation note.** The slow is re-applied every 0.25s from inside the existing race
in `DeathSaveManager.RunDeathSave`, because at the new spawn interval a 3-second window
can admit a dozen hostiles at full speed. Riding in the race means it is cancelled exactly
when the window closes.

**Proven in playtest, 2026-08-18.** The log shows the window opening at 3 seconds, the
turkey leg landing, the save succeeding with 50 health restored, and a second fatal blow
correctly refused. Kai confirms the hostiles visibly slowed.

---

## 33. GDD 5.3's "~100 active props" does not exist — CORRECTION, 2026-08-18

**What the GDD says.** 5.3: "To remain within UEFN's strict ~100-active-prop platform
memory limit, the wave spawner caps concurrent active hostiles at 40 bots." CLAUDE.md
section 9 repeats it as "UEFN allows roughly 100 active props."

**What Epic actually publishes.** A memory budget of **100,000 memory units**, shown as a
thermometer in the editor, where every asset costs a different amount towards the total. A
project may exceed it while being built and only has to fit when published. It is not a
count of objects, and no published limit of "100 props" exists anywhere.

Sources: dev.epicgames.com "Memory Management in Unreal Editor for Fortnite" and "Memory
and Optimization in Unreal Editor for Fortnite".

**What this changes.** The stated justification for the 40-bot cap is void, as is the
arithmetic that treated 3 loot drops per kill as spending against a ceiling of 100. Loot
also self-limits: drops despawn after 5 seconds, so at 2 kills a second about 30 pieces
sit on the floor at any moment regardless of wave size.

**What it does not change.** 40 may still be the right cap, but for **frame rate** rather
than memory. Forty Fortnite characters pathfinding at once is expensive and 5.1 commits to
a locked 60 FPS. 5.3 conflated a memory limit with a performance limit; the performance
one is real and unmeasured. **Playtesting for stutter is the test, not arithmetic.** At 20
concurrent on 2026-08-18, Kai reported no stutter.

**Also fix CLAUDE.md section 9**, which carries the same wrong number.

---

## 34. The ship date is 2026-09-04 — KAILEE'S RULING, 2026-08-18

**What the GDD says.** 5.6's schedule runs six weeks and ends **2026-09-01**.

**What is actually true.** The capstone is due **2026-09-08**. Kai ruled on 2026-08-18
that the target is **Thursday 2026-09-04**, deliberately keeping a four-day cushion before
the real deadline. Plan every remaining item against the 4th.

The GDD's schedule is the original plan and is a week short of the course, which is also
recorded as item 16g. This settles which date governs. **Do not re-ask.**

## 35. There are four hostile types, not two — KAILEE'S RULING, 2026-08-19

**What the GDD says, twice, differently.** 5.4's asset ceiling commits to **2 cybernetic
hostile models (melee Swarmer, heavy Ranged Tank)**. The weapons table in 3.3 names
**four**: Cyber-Swarmers, Cyber-Boars, Ranged Sentinels, and heavy elite tanks. The
document contradicts itself and never reconciles the two lists.

**The ruling.** Kai ruled on 2026-08-19 that the game ships with **four hostile types**.
5.4's count of two is superseded. The four names in 3.3 are the roster.

**Consequence for the build.** The wave manager currently drives ONE placed NPC Spawner
and swaps its character definition as the tier climbs. Epic's own documentation says
`SetNPCCharacterDefinition` is refused when the new definition is a different character
type from the current one, so four genuinely different hostiles cannot all come out of
one spawner. Extra spawner devices are expected. How many, and whether the types share
the arena at once or take turns by tier, is NOT settled here.

## 36. The colour palette — KAILEE'S RULING, 2026-08-19

**REPLACED 2026-08-22. See amendment 62.** Every hex below is dead. Kai supplied a new
ten-colour retro-futuristic palette and ruled that it replaces this one. The structure and
the reasoning here are still worth reading, and amendment 62 lists what this covered that
the new palette does not.

**What the GDD says.** Nothing. 3.2 asks for "high-contrast colored paragliders that
denote their quality tier" and never names a colour. No other section fixes one either.

**The ruling.** Kai supplied the palette below on 2026-08-19. It is authoritative. The
three layers are a hierarchy: Layer 3 colours mean exactly one thing each and are never
reused as decoration.

### Layer 1: The World
Dirty, desaturated, boring on purpose. Never used for anything the player must react to.

- `#2B303B` Floor Base -- main arena floor tile, cold gray-blue concrete
- `#333A47` Floor Alt Tile -- every other tile, so the floor is not one flat slab
- `#21252E` Grime / Oil Stain -- splotches and scorch marks
- `#7D838F` Broken Concrete -- barrier chunks, lighter than the floor so they read
- `#4A4F59` Dull Metal -- fence posts, floodlight rigging, structural junk
- `#6B4A32` Rust -- streaks on metal, the biggest "dishevelled" lever
- `#C9A21A` Faded Hazard Yellow -- fence stripes, deliberately dirty, not bright
- `#0E1016` Stage Black -- hazard stripe dark half, deep shadow, outside the fence

### Layer 2: The Show
TV set dressing. Bright, but decorative only. Nothing here can hurt or help the player.

- `#B31E6E` Sign Pink (dimmed) -- wall neon, held back so the shield owns bright pink
- `#0E8FA6` Sign Cyan (dimmed) -- scoreboard and signage glow, held back from player blue
- `#FFE9A8` Floodlight Warm -- blinking stadium floodlights and their pools of light
- `#7A2E8C` Broadcast Purple -- HUD panel backgrounds, chat widget frame, title cards

### Layer 3: Gameplay (reserved colours)
Maximum saturation. Each colour means exactly ONE thing, forever.

- `#4DD0FF` YOU -- the contestant. Nothing else is ever this colour
- `#29B6FF` Your Bullets -- Pulse Blaster plasma. Blue always means "came from me"
- `#FFEE33` SMG Laser -- and this is why the fence yellow got dirtied
- `#FF4D4D` THREAT -- Swarmers, enemy bullets, damage flash. Red = will hurt you
- `#B3261E` Cyber-Boar -- the same red darkened, for the armoured charger. Ruled
  2026-08-19. It stays inside the hostile family so it still reads as danger, and it
  reads as heavier without claiming a hue something else would then be short of
- The Ranged Sentinel has NO colour of its own. Ruled 2026-08-19: it wears THREAT red
  like the Swarmer and is known instead by the red laser sight it paints before firing.
  A telegraph warns the player in time to break line of sight; a shade never could
- `#B04DFF` Heavy Enemy -- Ranged Tank. Purple reads as "the big one" at a glance
- `#FFC53D` MONEY -- coins, cash bundles, score numbers, prize props
- `#3BE07A` HEALING -- Sponsor Aid turkey leg and its glow. Green only ever means health
- `#1E8F4E` Healing Deep -- the same green darkened, for the core of a healing glow where
  one flat colour reads as a blob. Ruled 2026-08-19, after Kai pushed back on using a
  single green. A second shade of a reserved colour is allowed and gives depth; reusing
  the hue on anything decorative is not
- `#FF69D4` SHIELD -- Sponsor Aegis bubble. Bright pink is reserved for this
- `#FF7A1A` Flaming Ammo -- burn trails and burn ticks
- `#9FE8FF` Icy Rounds -- frost trails and slowed enemies. Stretch goal

### Crate paraglider tiers
The classic medal ladder, so it reads instantly with no explanation.

- `#CD7F32` Underdog -- bronze paraglider
- `#A8B0BC` Rising Star -- silver paraglider, dimmed from `#D8DEE9` on 2026-08-19
  because at near-white it was unreadable against Prime Time's pure white
- `#FFD700` Superstar -- gold paraglider, plus sparkle FX so it never reads as loose cash
- `#FFFFFF` Prime Time -- pure white, ruled 2026-08-19. Amendment 24 added this fourth
  tier after the palette's medal ladder was drawn, and white is the one strong colour
  nothing else in the game claims

**Two clashes to watch in playtest, not to pre-solve.** Superstar gold `#FFD700` sits
close to MONEY `#FFC53D`, which the sparkle FX is there to separate. Rising Star silver
`#D8DEE9` sat close to Prime Time white `#FFFFFF`, the two tiers furthest apart in value.
Kai called it on sight, 2026-08-19, before it ever reached a playtest, and the silver was
dimmed to `#A8B0BC`. The gold-against-money pair is still unproven and rides on the
sparkle FX.

## 37. Icy Rounds ships, and comes off the cut list — KAILEE'S RULING, 2026-08-19

**What the GDD says.** 3.3 labels Icy Rounds "Modifier - Stretch Goal" and 5.7 makes it
the second thing cut if the schedule slips, after the stream chat widget.

**The ruling.** Kai ruled on 2026-08-19 that Icy Rounds ships. It leaves the cut list
entirely, so Flaming Ammo becomes cut 2 and tiered crate scaling becomes cut 3. It is no
longer a stretch goal. Do not propose cutting it again.

**Why it is affordable.** Its whole effect is a stacking -20% movement-speed debuff, max
3 stacks, on hostiles that are hit. Amendment 32 already proved hostile movement speed can
be driven from Verse via `GetNavigatable[]` and `SetMovementSpeedMultiplier`, for the
Death Save slow motion, so the mechanism exists and is playtested. The floor clamp of 0.5
found there also caps what three stacks can do, which is a limit to design around rather
than a blocker.

**The frost visual is buildable too.** `vfx_creator_device` has a *Stick to Player* mode
and a `Begin(Agent)` overload, so one device tinted to the palette's `#9FE8FF` can be
started on a hostile and will follow it while the slow lasts.

**Settled 2026-08-19 by amendment 43.** The debuff does stack to 3. GDD 3.2's no-stacking
rule governs the player's own upgrade slots, not effects sitting on a hostile.

## 38. Which item each crate tier hands out — KAILEE'S RULING, 2026-08-19

**What the GDD says.** 3.3 lists the seven rewards and 3.2 tiers the crates, and nothing
anywhere maps one to the other. Amendment 26 settled that a crate holds one item and the
tier decides how good it is, but never said which item sits at which tier.

**The ruling, 2026-08-19.**

| Tier | Pool |
|---|---|
| Underdog | SMG, Shotgun |
| Rising Star | Shotgun, Sniper, Sponsor Aid |
| Superstar | Sniper, Sponsor Aegis, Sponsor Aid |
| Prime Time | Sponsor Aegis, Flaming Ammo, Icy Rounds |

**Why every tier contains a weapon.** The first proposal gave Underdog the Sponsor Aid
heal alone. Research killed it: the named pitfall is **Power-Up Letdown**, a pickup that
fires the instant it is touched at a moment when it does nothing, and a heal-only crate
collected at full health is exactly that. A weapon is never a dud, so no tier can now hand
over nothing.

**Why the heal sits in the middle and not at the bottom.** GDD 3.1's Underdog Boost gives
+50% Hype generation below 40% health, and Hype sets crate quality, so a hurt player
climbs to better crates faster. The heal belongs where a hurt player will actually be.

**Why Risk of Rain 2's model was not copied.** There the cheap tier matters because
dozens of them stack. GDD 3.2 forbids that outright: duplicates refresh the active
duration rather than stacking.

**Engine note.** Only the SMG, Shotgun and Sniper are real Fortnite items an Item Granter
can hold. The Sponsor Aid heal, the Sponsor Aegis, Flaming Ammo and Icy Rounds all have to
be built in Verse, the same way the Death Save's turkey leg already is.

**Sources.** TV Tropes, "Timed Power-Up", on Power-Up Letdown:
https://tvtropes.org/pmwiki/pmwiki.php/Main/TimedPowerUp . SLYNYRD, "Pixelblog 32, Shmup
Design Part 2", on pickups needing distinct meaning and varied rarity:
https://www.slynyrd.com/blog/2021/2/15/pixelblog-32-shmup-design-part-2 . Risk of Rain 2
Wiki, item tiers: https://riskofrain2.wiki.gg/wiki/Items

## 39. A fourth crate weapon, the Rocket Launcher — KAILEE'S RULING, 2026-08-19

**What the GDD says.** 5.4's asset ceiling commits to "1 standard Pulse Blaster default
sidearm, 3 crates weapons (SMG, Shotgun, Sniper)". There is no rocket launcher anywhere
in the document.

**The ruling.** Kai ruled on 2026-08-19 that a Rocket Launcher is added as a fourth crate
weapon, sitting in the **Prime Time** pool. 5.4's count of three is superseded.

**Why Prime Time.** It is the strongest thing on the list, it suits the Smash TV
crowd-clearing fantasy the tone is built on, and it is the only real Fortnite item in that
pool. Without it Prime Time hands out nothing at all until the Aegis and both ammo
modifiers are built in Verse, which makes the top tier the last one testable.

**THE GUARDRAIL: SIX ROCKETS, NO RESUPPLY -- RULED 2026-08-19.** Kai's condition was that
the launcher must not end runs unfairly, since Fortnite rockets damage whoever fired them
and this arena is one room the player kites around at close quarters.

**There is no self-damage setting.** Island Settings was read in full on 2026-08-19. The
nearest options are Invincibility, which would break the whole game, and Allow Friendly
Fire, which governs other players and not your own rocket. So the guardrail is scarcity
rather than immunity.

**A Prime Time crate hands the launcher over loaded with six rockets, and no rocket ammo
exists anywhere in the arena.** It empties inside a single wave and the player drops back
to the Pulse Blaster, which is exactly the fallback role GDD 3.3 gives it.

**Why six and not three.** Three was proposed and Kai pushed back. A wave runs about two
minutes and spawns roughly 250 hostiles, so at about five kills a rocket, three rockets is
15 kills, 6% of a wave, which does not read as the rarest crate in the game. Six is about
30. It still runs dry inside one wave, so it can never become the weapon the player lives
on. Max Health is set to 200 on this island, so a rocket at the player's own feet is
survivable rather than instantly fatal.

## 40. What a close shave is, and what it pays — KAILEE'S RULING, 2026-08-19

**What the GDD says.** 3.1 names "close-shave dodges" as a Hype source and never defines
one. Amendment 28 called it the main earner, because it works at any density and cannot be
farmed by killing, and left it unbuilt as `BUILD_ORDER.md` item 9.

**The ruling, 2026-08-19.**

| Rule | Value |
|---|---|
| A hostile closes within | **2 metres** |
| Escaping it without being hit pays | **+3 Hype** |
| That hostile cannot pay again until the player breaks | **4 metres clear of it** |

**Why 2 metres.** Every hostile in the map is melee and swings at about arm's length, and
GDD 5.3 already treats 3 metres as the danger line by blocking spawns inside it. At 3 the
player would be paid for merely being near something; at 2 they are paid for standing
inside the ring where they could have been hit. The genre gives no number worth copying:
graze in Touhou and the CAVE shooters is a handful of pixels measured against a hitbox the
size of a full stop, tuned to bullets rather than to melee pursuers. What transfers is the
principle, that the reward zone sits immediately outside the kill zone.

**Why the 4-metre break.** Melee hostiles sit inside 2 metres continuously while chasing,
so without a rule the player would be paid for being followed. Requiring a 4-metre break
before the same hostile can pay again means the payment is for escaping, which is what 3.1
describes.

**Why 3 Hype.** The tiers are 0-39, 40-74, 75-94 and 95+, and the meter bleeds about 24
points across a two-minute wave, so reaching Prime Time inside one wave needs roughly 120
points, about one a second, which is a shave every three seconds. That crosses a tier
about every 40 seconds, and since a crate falls on every crossing as well as on the
25-second trickle, something lands for the player every 15 to 20 seconds.

**Rejected: survivor-like pacing.** About 5 a shave would reach Prime Time inside the
first minute and park there for the rest of the wave, which is the exact problem amendment
13's uneven thresholds of 40 and 75 were shaped to prevent. Kai asked whether the game
should be paced as a survivor-like; it should not. The GDD names Vampire Survivors only
under "Art Style & Scope", as a model for low-fidelity readable sprites. Its stated
gameplay references are Smash TV and Total Carnage, which are room-clear arcade shooters.

**The estimate that is not measured.** "A shave every three seconds" is a guess at how
often a kiting player brushes a crowd. If a playtest shows fewer, raise the 3 rather than
change anything else.

**Sources.** a327ex, "Roguelite Design Analysis", on survivor-likes granting a reward
about every 10 seconds early and on event-triggered rewards beating fixed intervals:
https://a327ex.com/posts/roguelite-design-analysis . Touhou Wiki on hitboxes:
https://en.touhouwiki.net/wiki/Hitbox

## 41. The Sponsor Aegis is three hits, with no timer — KAILEE'S RULING, 2026-08-19

**What the GDD says, in two places that pull apart.** 3.3 describes the Sponsor Aegis as
a "bright pink, translucent hexagonal energy bubble wrapping the player character" that
"absorbs up to 3 hostile hits". 3.2 says a duplicate upgrade "refreshes its active
duration rather than stacking", which implies every upgrade runs on a clock. 3.3 never
gives the Aegis one.

**The ruling, 2026-08-19. Hits only. There is no timer.** The bubble lasts until all
three hits are spent, however long that takes. A second Aegis collected while one is up
refills it to three hits rather than stacking to six, which keeps 3.2's anti-exploit rule
without needing a clock.

**Why.** Three hits and no timer is the genre's own standard: Gradius' Force Field, the
most copied shield in arcade shooters, absorbs exactly three hits and vanishes, and it is
preferred over the timed shield variants. A timer punishes the player for playing well,
since dodging cleanly wastes the pickup, which is the Power-Up Letdown that amendment 38
already ruled against.

**Engine note.** Enemy damage was measured at exactly 20 a hit, recorded earlier in this
file, so 60 points of Fortnite shield absorbs exactly three hostile hits and the existing
shield bar carries the whole mechanic. **To check before building: Island Settings owns
Max Shields and it must be at least 60**, or the Aegis will silently grant less than three
hits. Island Settings is invisible to the Verse digest, so it can only be read in the
editor.

**Colour.** The bubble is `#FF69D4`, the palette's reserved SHIELD pink, amendment 36.

**Sources.** Gradius Wiki on the Force Field absorbing three hits:
https://gradius.fandom.com/wiki/Shield . StrategyWiki, Gradius III weapons:
https://strategywiki.org/wiki/Gradius_III/Weapons

## 42. Ammo modifiers last 30 seconds — KAILEE'S RULING, 2026-08-19

**What the GDD says.** 3.2 says a duplicate upgrade "refreshes its active duration rather
than stacking", so upgrades plainly run on a clock. 3.3 describes Flaming Ammo and Icy
Rounds and never gives either one a duration. No other section supplies it.

**The ruling.** Both ammo modifiers last **30 seconds**. A duplicate collected while one
is running resets it to 30 rather than adding to it, per 3.2.

**Why 30.** The design guidance is that impact and frequency should both run inversely to
duration: strong, common pickups stay brief, rare and moderate ones last longer, and a
pickup should cover a sweep of the arena and a second pass without lasting a whole wave.
Both modifiers come only from Prime Time crates, the rarest in the game, and they layer
damage rather than clearing the screen, which puts them at the longer end.

**And one reason specific to this game.** 30 seconds is a quarter of a two-minute wave,
so a modifier never carries one. It also sits just above the 25-second crate trickle of
amendment 25, which means a duplicate can genuinely arrive while one is still running.
Any shorter and GDD 3.2's refresh rule would almost never fire at all.

**Still open, and it blocks Flaming Ammo only.** 3.3 gives Flaming Ammo a "ticking burn"
with no damage number, which is the same gap amendment 15 recorded as blocking the build.
Icy Rounds is unaffected: 3.3 gives it -20% movement speed per stack to a maximum of 3.

**Sources.** Antonio Delgado, "Power-Up Time: How Long Should Power-Ups Last":
https://gt3000.medium.com/powerup-time-how-long-should-powerups-last-e96df34f7d4f .
TV Tropes, "Timed Power-Up": https://tvtropes.org/pmwiki/pmwiki.php/Main/TimedPowerUp

## 43. How Icy Rounds behaves on a hostile — KAILEE'S RULING, 2026-08-19

**What the GDD says.** 3.3: "SLOW FIELD: Layers a stacking movement-speed debuff (-20%
per stack, max 3) onto hit targets. Used to kite dense melee swarms." It never says how
long a stack lasts, and 3.2 separately forbids duplicate upgrades from stacking.

**The ruling, 2026-08-19.** Each shot that lands adds one stack to that hostile, up to
three. The whole slow expires **3 seconds after the last hit** on that hostile, and its
stacks reset with it. Keep shooting something and it stays slowed; look away and it
recovers.

**Why 3 seconds.** Long enough to feel while kiting, short enough that the arena does not
silt up with permanently crawling hostiles, which would undo the Smash TV rush the density
ruling of amendment 30 exists to protect.

**The two stacking rules do not collide.** 3.2 governs the player's four upgrade slots: a
second Icy Rounds pickup refreshes the 30-second modifier of amendment 42 rather than
doubling it. 3.3's stacks live on hostiles, which 3.2 says nothing about. Kai ruled them
compatible.

**AN ENGINE LIMIT THE GDD'S NUMBERS OVERSHOOT.** `SetMovementSpeedMultiplier` clamps at
0.5, found when the Death Save slow motion was built and recorded in amendment 32. Three
stacks at -20% each is a 40% multiplier on paper, which the engine will not go below 0.5.
So three stacks land at **half speed**, not 40%. The first two stacks land as written.
This is recorded rather than worked around: the alternative is faking movement in Verse,
which costs far more than the difference is worth.

**Look and sound.** Frost trails in the palette's `#9FE8FF`, amendment 36, on a VFX
Creator with Stick to Player on so the effect rides the slowed hostile.

## 44. Flaming Ammo burns for 5 a second over 3 seconds — KAILEE'S RULING, 2026-08-19

**What the GDD says.** 3.3: "TICKING BURN: Layers ticking burn damage on top of SMG,
Shotgun, or Sniper shots. Highly effective against heavy elite tanks." No damage number
and no burn duration. Amendment 15 lists this as one of the missing damage values.

**The ruling.** The burn does **5 damage a second for 3 seconds**, and a further landed
shot restarts those 3 seconds rather than adding a second burn. The modifier itself still
lasts 30 seconds, amendment 42.

**Why exactly that.** It is the only damage figure the GDD ever states: the SMG's own
bleed is "5 damage/second over 3 seconds". Against a Swarmer's 40 health, recorded in
amendment 15, the full burn is 15 damage, or 37% of a basic hostile.

**A first proposal was rejected on the numbers.** "About a quarter of a Swarmer" came out
at 10 damage, which is weaker than the bleed a stock SMG already carries for free. The
rarest crate in the game cannot hand over something feebler than standard equipment.

**Why a flat number rather than a share of health.** The design guidance for damage over
time is that it should be an absolute amount rather than a percentage of maximum health,
and that it should finish and soften rather than out-damage direct fire, or shooting stops
mattering.

**Why a flat burn is still "highly effective against heavy elite tanks", as 3.3 claims.**
Kai raised that hostile health differs per enemy. It does, and it cuts the right way: only
a high-health hostile survives long enough for all three seconds to tick, so tanks eat the
whole 15 while Swarmers die partway through it. The burn's real value elsewhere is giving
the Shotgun and Sniper a damage-over-time effect neither one otherwise has.

**Sources.** TV Tropes, "Damage Over Time":
https://tvtropes.org/pmwiki/pmwiki.php/Main/DamageOverTime . G2A, "What Is Damage Over
Time (DoT) in Gaming?": https://www.g2a.com/news/glossary/what-is-damage-over-time-dot/

## 45. Four hostile types, sharing the arena, at one strength each — KAILEE'S RULING, 2026-08-19

**What the GDD says.** 3.3 names four hostiles in passing: Cyber-Swarmers, Cyber-Boars,
Ranged Sentinels and heavy elite tanks. 2.4 makes Room-Loop 1 "weak melee Cyber-Swarmers
only", so Swarmers are the baseline. 5.5 scales "hostile maximum health pools, movement
speeds, and spawn densities" by 8% a tier. Amendment 35 settled that there are four types
and deliberately left open whether they share the arena.

**Ruling 1: all four share the arena at once.** Not one type per tier. The GDD's stated
reference is Smash TV, which mixes types on screen, and a crowd of one repeated enemy is
numerous rather than interesting. This costs a rework: the wave manager currently drives
one spawner and must now drive four and divide its concurrency between them.

**Ruling 2: the mix, at 10 concurrent.** Five Swarmers, two Boars, two Sentinels, one
Tank. Swarmers dominate because 2.4 makes them the baseline the player learns on. Tanks
are rare because 3.3 calls them "heavy elite". Sentinels are the ranged pressure 3.3
describes as "lines of distant, stationary Ranged Sentinels".

**Ruling 3 was reversed the same day. See amendment 48.** It first ruled one definition
per type with no ladders, to avoid twenty hand-built NPC definitions. Kai reversed it
within the hour and took the full ladder, so GDD 5.5's health and speed scaling stays
intact rather than being handed entirely to density.

## 46. Health and speed for the four hostile types — KAILEE'S RULING, 2026-08-19

**What the GDD says.** Nothing. 3.3 names the four types and describes their flavour;
5.4 budgets the models. No health or speed figure for any hostile appears anywhere.

**The ruling, 2026-08-19.** Sprint speeds in metres a second, with walk at 62.5% and run
at 87.5% of sprint, the ratios amendment 8 established from the original Swarmer card.

| Type | Health | walk / run / sprint |
|---|---|---|
| Cyber-Swarmer | 40 | 2.5 / 3.5 / 4.0, unchanged |
| Cyber-Boar | 80 | 4.4 / 6.1 / 7.0 |
| Ranged Sentinel | 40 | 0.6 / 0.9 / 1.0 |
| Heavy Elite Tank | 200 | 1.9 / 2.6 / 3.0 |

**Why these health values.** Everything reads against the Swarmer's 40, which was already
built. The Boar is "armored" in 3.3, so double. The Tank is "heavy elite", so five
Swarmers' worth: a wall you have to commit to rather than something you clip in passing.
The Sentinel matches the Swarmer, because 3.3 answers it with distance rather than
durability, so it should die fast once you close.

**Why these speeds.** The player was measured at 11.90 m/s, amendment 31, so none of these
outruns them and GDD 2.2's kiting survives intact. The Boar at 7.0 is the only hostile
that can genuinely close, which is what makes it a dodge rather than a chase, and it is
the first hostile ever set above the old 5.6 ceiling: the player is still 1.7 times
faster. The Sentinel at 1.0 is effectively rooted, which is 3.3's "distant, stationary".

**Damage is unchanged at 20 a hit for all four.** Measurement recorded in item 11, and
the GDD never gives hostile damage a per-type or per-tier figure. Not varied here.

**STILL OPEN, AND IT BLOCKS THE SENTINEL ONLY.** 3.3 makes the Ranged Sentinel a shooter
and never says what it fires, how far, how often, or for how much. That has to be ruled
before the Sentinel can be built. The other three are melee and are buildable now.

## 47. The Ranged Sentinel carries a sniper — KAILEE'S RULING, 2026-08-19

**What the GDD actually says.** 3.3 arms the *player*: the Sponsor Sniper "emits an
overcharged energy beam that pierces through lines of distant, stationary Ranged
Sentinels". That describes the player's counter to them. The document never says what a
Sentinel itself fires, so this is an addition rather than a contradiction.

**The ruling.** The Ranged Sentinel carries a sniper rifle.

**Engine note, and it is the whole of the balance.** Fortnite does not let a creator set
a weapon's damage, so choosing the Sentinel's weapon *is* choosing its damage. A sniper
body shot lands around 80 against the player's 200 health, so three of them end a run.

**The concern was raised and overruled, deliberately.** A rooted enemy that outranges the
player and takes a third of their health per hit was put to Kai on 2026-08-19, along with
a marksman rifle at roughly half the damage. Kai ruled sniper anyway. Recorded so the
decision is not rediscovered as a bug.

**Why it can hold up.** The Sentinel moves at 1.0 m/s against a player measured at 11.90,
amendment 46, so breaking line of sight is always available, and GDD 1.1's electrical
grids and concrete debris exist precisely to block it.

**Watch this in the first playtest.** If Sentinels are what end runs, the lever is the
weapon rather than their health, since health is not what is killing the player. Swapping
to a marksman rifle is a one-field change on the character definition.


## 48. The full tier ladder for all four hostile types — KAILEE'S RULING, 2026-08-19

**Reverses amendment 45's ruling 3, same day.** That ruling gave each type one strength
to avoid twenty hand-built definitions before the 2026-09-04 ship date. Kai reversed it
and took the ladder, so GDD 5.5's per-tier health and speed scaling is delivered as
written rather than being carried entirely by density.

**The method is amendment 8's, unchanged.** Health compounds 8% a tier across blocks of
four, so each card is 1.36 times the one before it. Sprint compounds 2.1% a tier, so each
card is 1.087 times the one before it, with run at 87.5% and walk at 62.5% of sprint.

**Cyber-Boar**, tiers 1-4, 5-8, 9-12, 13-16, 17-21:

| Card | Health | walk / run / sprint |
|---|---|---|
| `CyberBoar` | 80 | 4.4 / 6.1 / 7.0 |
| `CyberBoar_T2` | 109 | 4.8 / 6.7 / 7.6 |
| `CyberBoar_T3` | 148 | 5.2 / 7.3 / 8.3 |
| `CyberBoar_T4` | 202 | 5.6 / 7.9 / 9.0 |
| `CyberBoar_T5` | 274 | 6.1 / 8.6 / 9.8 |

**Ranged Sentinel**, same health curve as the Swarmer:

| Card | Health | walk / run / sprint |
|---|---|---|
| `RangedSentinel` | 40 | 0.6 / 0.9 / 1.0 |
| `RangedSentinel_T2` | 54 | 0.7 / 1.0 / 1.1 |
| `RangedSentinel_T3` | 74 | 0.8 / 1.1 / 1.2 |
| `RangedSentinel_T4` | 101 | 0.8 / 1.1 / 1.3 |
| `RangedSentinel_T5` | 137 | 0.9 / 1.2 / 1.4 |

**Heavy Elite Tank**:

| Card | Health | walk / run / sprint |
|---|---|---|
| `HeavyEliteTank` | 200 | 1.9 / 2.6 / 3.0 |
| `HeavyEliteTank_T2` | 272 | 2.1 / 2.9 / 3.3 |
| `HeavyEliteTank_T3` | 370 | 2.2 / 3.1 / 3.5 |
| `HeavyEliteTank_T4` | 504 | 2.4 / 3.3 / 3.8 |
| `HeavyEliteTank_T5` | 685 | 2.6 / 3.7 / 4.2 |

**THE ONLY NUMBER HERE WORTH WATCHING.** The Boar at Tier 21 sprints at 9.8 against a
player measured at 11.90, amendment 31. That still cannot catch the player, which GDD
2.2's kiting requires, but the margin is 1.2 times rather than the 2 or 3 times every
other hostile leaves. If late tiers start feeling unfair, the Boar's sprint is the first
thing to look at, not its health.

**Amendment 8's PROVISIONAL marks can come off.** T3, T4 and T5 of the Swarmer were left
provisional pending a measurement of the player's run speed. That measurement exists now:
11.90 m/s, amendment 31, against a Swarmer top speed of 5.578. All three are safe.

## 49. The Cyber-Boar is a robot, not an animal — KAILEE'S RULING, 2026-08-19

**What the GDD says.** 1.1 makes every hostile either a rejected pilot-episode robot or a
bankrupt former contestant wearing a mechanical chassis taken as severance. 3.3 calls one
of them an "armored Cyber-Boar".

**What the engine says, checked 2026-08-19.** There is no boar NPC Character Definition in
the project, and Verse has no wildlife spawner of any kind, so Fortnite's animals could
never have been part of the mix the wave manager controls even if one had been found.

**The ruling.** The Cyber-Boar is a machine: a discarded mascot from a cancelled pilot,
built on the same humanoid base as the other three hostiles.

**Why that is the right answer and not a consolation.** A live animal breaks 1.1's fiction
outright, since nothing in this arena is alive that did not sign a contract. A robot
mascot is precisely what a show like this would have built and then thrown away, and
"Cyber-Boar" already says machine.

**What follows from it.** All four hostiles share one humanoid base, so the player tells
them apart by colour and size rather than by silhouette. **Settled the same day**, and
recorded in amendment 36: Swarmer THREAT red `#FF4D4D`, Boar a darker `#B3261E`, Tank
Heavy Enemy purple `#B04DFF`, and the Sentinel wearing Swarmer red but known by the laser
sight it paints before firing. Three body colours for four enemies, because a fourth
shade would read worse than a telegraph does.

## 50. The cash magnet — KAILEE'S RULING, 2026-08-19

**What the GDD says.** 2.3 makes collection a contact: walking over a drop "triggers an
immediate collision pickup". 5.3 despawns drops "exactly 5 seconds after generation".
Nothing anywhere pulls loot toward the player.

**Why it is needed, measured rather than felt.** The playtest log of 2026-08-19 records
12 drops spawned, 2 collected and **10 despawned uncollected**. Five sixths of the money
is being thrown away. Kai had already reported not being able to reach cash through the
crowd, and the log agrees: the loot lands where hostiles die, which is exactly where the
player is trying not to be.

**The ruling.** Drops inside `MagnetRadius` fly to the player. Outside it they do not
move at all, so crossing the arena for a distant pile is still a decision.

**It contradicts nothing.** 2.3 says pickup happens on contact, and this makes the contact
happen. The alternative, stretching the 5 seconds, would have contradicted 5.3 outright,
which is why it was rejected on 2026-08-19. Genre precedent is Vampire Survivors.

**THE RADIUS IS PROVISIONAL: 8 metres.** Kai parked this number earlier the same day on
the grounds that a distance means nothing until the arena has a size, which was correct.
It is unparked at 8 metres only because the loss rate is too high to leave alone, and it
is expected to change once items 14 and 15 give the room its dimensions.

**Two supporting numbers.** Drops fly at 14 m/s, above the player's measured 11.90 m/s of
amendment 31, because a drop that cannot catch someone running away would not fix
anything. And the pull waits one second, because the launch arc of GDD 2.3's "shower of
loot" owns the prop's position until it lands, and two things moving one prop would fight
every tick.

## 51. The arena is 30 metres across — KAILEE'S RULING, 2026-08-19

**What the GDD says.** 1.1 gives "a single-room stadium arena" and never a dimension.
No section anywhere states a size.

**What was already assumed.** `SimulatedAudience.verse` has an `ArenaRadius` default of
1500 centimetres, and crate landing spots have been drawn from it since it was built. The
arena has therefore had a size all along, in one device's default, unwritten anywhere.

**The ruling.** 15-metre radius, 30 metres across. Confirmed 2026-08-19.

**Derived, not copied.** The market gives no arena-size number: the guidance is that
metrics come from your own movement speed and weapon ranges and are then tested. At the
player's measured 11.90 m/s, amendment 31, 30 metres is 2.5 seconds corner to corner and a
lap of the edge is about 8 seconds, which is a real kiting loop and as tight as the Smash
TV and Geometry Wars rooms the GDD points at.

**WHAT 30 METRES COSTS, AND WHY IT IS NOT FIXED BY A BIGGER ROOM.** A sniper in a
30-metre room is a slow rifle. That applies to both GDD 3.3's Sponsor Sniper and to the
Ranged Sentinel of amendment 47. The answer is sight lines rather than distance: 1.1's
electrical grids and concrete debris are what make range mean anything, and amendment 47's
whole counter to the Sentinel, breaking line of sight, does not exist until they are
built. **This makes BUILD_ORDER items 14 and 15 a balance dependency, not decoration.**

**One number this settles.** Amendment 50 set the cash magnet's radius to 8 metres and
called it provisional for want of an arena size. Against a 15-metre radius that is just
over half the room, which is defensible, and it can now be judged rather than guessed.

**Sources.** The Level Design Book on metrics:
https://book.leveldesignbook.com/process/blockout/metrics . Game Developer, "Level Design
for Combat": https://www.gamedeveloper.com/design/level-design-for-combat

## 52. Obstacles block bullets, not just bodies — KAILEE'S RULING, 2026-08-19

**What the GDD says.** 1.1: the electrical grids and broken concrete "block player
movement and enemy pathfinding, forcing frantic tactical maneuvering". It is silent on
whether anything shot at them stops.

**The ruling.** They block shots as well. Kai's call, 2026-08-19.

**Why it matters more than it sounds.** Amendment 51 fixed the arena at 30 metres across,
which makes a sniper a slow rifle unless sight lines exist. Amendment 47 armed the Ranged
Sentinel with a sniper over a stated concern, and the reason that concern was survivable
was that the player could break line of sight. If bullets pass through concrete there is
no line of sight to break, and that whole answer evaporates.

**AN ENGINE TRAP TO AVOID.** In Fortnite a prop only stops a projectile if its collision
is solid. An "electrical grid" modelled as a fence, grating or railing will let shots
straight through while still blocking bodies, which would satisfy 1.1's wording and quietly
defeat this ruling. **Pick solid meshes, and test one shot against each before placing
twenty.**

**It cuts both ways, deliberately.** Cover that stops the Sentinel also stops the player,
so hostiles can break line of sight too. That is what keeps a 30-metre room from being a
shooting gallery, and it is the "frantic tactical maneuvering" 1.1 asks for.

**Unchanged by this.** Amendment 23 still has the obstacles return to their starting
positions, undamaged, when a room is cleared.


## 53. On-screen copy is sarcastic and cruel at once, and carries no slang: KAILEE'S RULING, 2026-08-20

**What the GDD says.** Section 1 sets the tone as "broad, self-aware game-show comedy in
the tradition of Smash TV and Total Carnage", with "corporate hostility and glitz played
for laughs" delivered through "sarcastic on-screen commentary". It never says how cruel,
it never says what the cruelty should be about, and it never mentions a modern or Gen Z
register.

**The ruling, 2026-08-20.** Text written in the Network's voice for the screen must do
three things.

1. **Sarcastic and cruel in the same sentence.** It says the opposite of what it means,
   through insincere praise, mock congratulation, fake generosity or fake concern, AND
   lands a jab at the contestant in the same breath. Cruel but sincere fails. Sarcastic
   but harmless fails. GDD 1 asks for both and wants them together.
2. **The jab is financial by default.** Contestants volunteer "to escape crushing
   financial debt" (GDD 1), so the item is billed, invoiced, surcharged, deducted, or
   counted against a payout that will never come. A jab about nobody surviving is the
   variation, used so nine cards do not tell the same joke.
3. **No slang and no meme vocabulary.**

**How this was arrived at.** Kai first described the voice as "sarcastic and cruel and
kinda funny, like some Gen Z announcer, like Smash TV". Three passes were rejected on the
way here, which is worth recording because each rejection named a real distinction:
copy that was polite comedy, then copy that was cruel but sincere, then copy that was
sarcastic but harmless. The rule above exists because the first two are easy to write by
accident.

**Why no slang, when the original description reached for it.** Kai's call after review.
Slang has a short shelf life, this capstone will be opened by graders and employers long
after it ships, and the joke the premise already tells is corporate polish sitting on top
of something monstrous. A Network that talks like a 22-year-old streamer is a narrower gag
that dates.

**Why the money jab and not the death jab.** Also Kai's call, on the reasoning that debt
is what the whole premise turns on, so financial cruelty keeps pointing at what the game
is about rather than reading as generic dark humour. It also does not run dry: invoices,
fees, interest and surcharges give a different joke per item, where death jabs start
repeating by the fourth card.

**What this does NOT change.** Josh Rose's ruling in the GDD Revision History stands
untouched. The 25 spoken announcer barks are hand-written by Kailee, and no agent may
draft, rewrite or improve them. This amendment governs on-screen interface copy only,
such as crate pickup cards.

**Where it is enforced.** `pipelines/assignment-07-style/settings.py`, as the tone rules
and slang blocklist the Style Guide Agent checks every card against.


## 54. Bare-fisted Swarmers were ruled out by the engine, not by choice — KAILEE'S RULING, 2026-08-20

**What the GDD says.** 3.3 calls them "weak melee Cyber-Swarmers" and 5.1 lists a "melee
Swarmer" model. It never says what a Swarmer holds, so fists were a preference rather than
a requirement, and a weapon breaks nothing.

**What Kai wanted.** Empty hands. All four character definitions had shipped with the same
ninja sword, and Kai asked for the Swarmers to fight with fists.

**Why it cannot be had, tested 2026-08-20 in this order.** Fortnite's built-in NPC brain
only chases and attacks while the NPC is holding a weapon. Clearing the weapon field left
the Swarmer standing still and harmless. Nitro Gauntlets, Seven Power Gloves and Myst Form
each did the same: they are the fist-shaped items UEFN offers and the brain does not know
how to swing them. A plain Basic Hammer made it fight immediately.

**A custom brain DID work, and is not the reason this was dropped.**
`SwarmerFistBehavior.verse`, a Verse `npc_behavior`, walked each Swarmer at the nearest
player and took 5 health off on contact. The session log confirms punches landing at 65 to
190 cm. Empty-handed damage is achievable.

**The blocker is the animation, and it is absolute.** Verse can play an animation on an NPC
only from an animation asset held in the project. This project holds none, Fortnite's own
punch animations are not exposed to Verse, and a Content Browser search for "punch" returns
props only. So the Swarmer damaged the player with no visible blow. A movement lunge was
built as a substitute and did not read as a strike either.

**The ruling.** Tabled. The Swarmers carry a sledge hammer for now.
`SwarmerFistBehavior.verse` stays in the project, unused and pointed at by nothing, as the
record of what was proven and what the engine refuses.

**What would reopen it.** An animation asset in the project. Nothing else changes the answer.


## 55. The weapon each hostile carries — KAILEE'S RULING, 2026-08-20

**Why this matters more than it looks.** Fortnite does not let a creator set a weapon's
damage, and Epic's NPC brain reacts to what an NPC holds. So the weapon choice IS the
hostile's damage and its behaviour at once: a gun makes it hang back and fire, a melee
weapon makes it charge. Amendment 47 established this for the Sentinel; it applies to all
four.

**The ruling.**

The Cyber-Swarmer carries a sledge hammer. Melee, and the weakest thing that still makes
the brain fight, which is what "weak melee" asks for.

The Cyber-Boar carries the Kinetic Blade. Melee, and its dash is what turns the Boar into
something that charges rather than another sword-swinger. GDD 3.3 has the shotgun
"stagger enemies and launch armored Cyber-Boars backward into other hostiles", so a
charger is what the document assumes.

The Ranged Sentinel carries a bolt-action sniper. This confirms amendment 47 in the map
rather than changing it.

The Heavy Elite Tank carries an LMG. GDD 5.1 names it a "heavy Ranged Tank" and 3.3 makes
Flaming Ammo "highly effective against heavy elite tanks", so heavy ranged is what the
document describes.

**Applied to all twenty cards, and the sixteen were the trap.** Each type has five
character definitions, base plus T2 to T5, because amendment 48 took the full tier ladder
and WaveManager swaps between them to scale health and speed. Setting only the four base
cards would have reverted every hostile to a ninja sword the moment the first wave cleared,
silently undoing the change with nothing on screen to explain it. All twenty now match.

**Watch this in the next playtest.** Two of the four are now ranged, where before all four
were melee. Amendment 51 sized the arena at 30 metres against melee pressure, and a sniper
plus an LMG firing across that room is a different problem. If runs end to gunfire rather
than to crowding, the lever is the weapon, not the health.

## 56. The onboarding ramp, hostiles only — KAILEE'S RULINGS, 2026-08-21

**What the GDD says.** Section 2.4, First-Life Onboarding Ramp, introduces systems
gradually over "the first five room-loops on the player's first life". Room-Loop 1 is
"Basic WASD movement, independent mouse aiming, standard Pulse Blaster weapon, and weak
melee Cyber-Swarmers only. HUD indicators, Hype systems, and crates are deactivated."
Room-Loop 2 unlocks crates, cash, the Hype Meter and the Hype Call. Room-Loop 4 unlocks
tiered crates. Room-Loop 5 unlocks the chat widget. Then: "Restart Skip: Upon death,
restarting immediately skips this ramp. The next run launches on loop 1 with all systems
and tiered crates active from the start."

**What the build did.** None of it. WaveManager turned all four spawners loose from wave 1,
so a Heavy Elite Tank could arrive in the opening seconds of a first-ever run. That was
never a spawner bug; the ramp had simply never been built.

**Ruling A: the hostile half is built, the blackout half is tabled.** Kai's call
2026-08-20. Holding back HUD, Hype and crates for a room is a separate job and a much
larger one, and it collides with item d of the contradictions list below, since 2.4 never
says what Room-Loop 3 unlocks. Only the hostile types ramp for now. Room 1 therefore shows
the Hype Meter and drops crates, which 2.4 does not, and that is a known and deliberate
gap rather than an oversight.

**Ruling B: staggered arrival, one new type per room.** Kai's call 2026-08-20. Boars join
at room 2, Sentinels at room 3, Tanks at room 4. Each type gets a room to itself before
the next lands. This fills the gap 2.4 leaves by listing Room-Loops 1, 2, 4 and 5 and
skipping 3 without comment.

**Ruling C: the ramp runs on EVERY run, not only the first life.** Kai's call 2026-08-21.
This is a deliberate departure from 2.4's Restart Skip, taken with the GDD's wording in
front of us. Read literally, Restart Skip puts Tanks back in the opening seconds of every
run after the first death, which is the exact thing Kai objected to and the exact thing
the ramp exists to prevent. Honouring it is also the more expensive option: a lost run
ends the match through the End Game device, so a fresh run restarts WaveManager at Tier 1
and the ramp returns by itself, where remembering "this player has died before" between
matches would need new persistent state. The cheap path and the good path agree here.

**Ruling D: room and Escalation Tier are the same counter.** Settled rather than chosen.
GDD 2.5 clears a room when "all spawned waves in the active Escalation Tier" are dead and
then begins the next tier, and WaveManager already runs exactly one wave per tier and
advances the tier when it clears. So "room 2" and "Escalation Tier 2" name the same thing,
and the ramp hangs off CurrentTier with nothing new to count.

**Ruling E: a held-back type leaves its seats empty.** Kai's call 2026-08-21. Amendment
45's mix is five Swarmers, two Boars, two Sentinels and one Tank in every ten alive, and
those are shares rather than counts. The choice was whether Swarmers fill the empty slots
in room 1 or not. They do not. Room 1 runs at five tenths of the density, room 2 at seven
tenths, room 3 at nine, room 4 onwards at full. The teaching room gets room to breathe,
and every later arrival makes the arena visibly fuller, so the ramp is felt and not merely
seen. Renormalising the shares instead would have put twenty Swarmers in room 1, as busy
as any later room, and hidden the ramp completely.

**Ruling F: the thinner rooms are also shorter, so they still last about two minutes.**
Kai's call 2026-08-21. Amendment 45's WaveSize of 250 is fixed per wave and was measured
at twenty hostiles on screen, so at ten it would have made the tutorial the longest room
in the game and broken Kai's ruling of 2026-08-18 that every wave runs 1m40 to 2m40. The
number to clear now scales by the same fraction as the density: about 125 in room 1, 175
in room 2, 225 in room 3, the full 250 from room 4 on.

**Built in `Content/WaveManager.verse`.** Three new `@editable` fields, `BoarJoinsAtTier`,
`SentinelJoinsAtTier` and `TankJoinsAtTier`, defaulting to 2, 3 and 4. Set all three to 1
and the ramp is off, which is how to test a late room without playing up to it.
`RampFraction` turns the unlocked shares into a multiplier that scales both the density and
the number to clear, `SpawnNext` refuses to spawn a type the ramp has not admitted, and the
wave log now names the types in play so a playtest can confirm the ramp is on.

**Disable() was NOT used to hold a type back, and must not be.** The file header records
that `Disable()` deletes the hostiles still alive at the moment it runs, proven across three
consecutive waves. Locked spawners stay enabled and are simply never asked to spawn, which
is safe because the spawner's own Spawn On Timer is off and every hostile arrives because
Verse called `Spawn()`.

**Watch this in the next playtest.** Room 1 at ten Swarmers with only the starting pistol
may now be too gentle rather than too harsh, which is the opposite of the complaint that
started this. The lever is `ConcurrentAtTier1`, not the join tiers.

## 57. The arena never held the number it said it held — 2026-08-21

**Found by playtesting the amendment 56 ramp.** The log said "up to 10 alive at once" and
room 1 was fighting sixteen, then twenty-two. Two separate causes, one editor and one
script, and they had been hiding each other.

**Cause 1, the editor: three of the four spawner devices were spawning by themselves.**
BoarSpawner, SentinelSpawner and TankSpawner each had Spawn On Timer set to Yes on a
three-second period, so three uninvited hostiles walked in every three seconds. That is why
Kai saw Tanks in room 1 on the very playtest that was meant to prove the ramp holds them
back until room 4: the ramp was working, and the devices were ignoring it. Set to No on all
three, 2026-08-21. SwarmerSpawner's own timer was set to 300 seconds, which is why turning
that one off changed almost nothing and cost a playtest to learn.

The file header has warned since the spawner was built that the device's automatic spawning
must be off. It said "the spawner", singular, which read as one box to tick. It now says all
four, and names this incident.

**Cause 2, the script: a requested hostile is invisible for about two seconds.** `Spawn()`
returns immediately but the hostile is not in the world yet, and `CountLiveHostiles` can
only see characters that have arrived. So the loop kept asking all through that gap. At a
0.25-second interval that is about six extra requests before the first arrival registers,
which is exactly the overshoot measured: a target of ten produced sixteen.

**The fix.** `SpawnsInFlight` counts what has been asked for and not yet arrived, and the
loop treats those as though they were already standing in the arena. A new
`SpawnArrivalTimeoutSeconds`, defaulting to 5, releases a reservation that is never filled,
so one silently failed spawn cannot starve the room for the rest of the wave. The spawn log
now ends with how many are still on the way.

**EVERY DENSITY NUMBER IN THIS FILE WAS MEASURED THROUGH THIS BUG.** `ConcurrentAtTier1`
of 20, ruled on 2026-08-20 after playing it, was really about 26 on screen, and on any
playtest where the three timers were also live it was far more than that. The number now
means what it says, so rooms 4 and up will feel calmer than the ones Kai has been playing.
Re-tune from what the next playtest actually feels like, not from the history above.

**Nothing about the ramp changed.** Amendment 56's rulings stand exactly as recorded:
Swarmers alone in room 1, Boars at 2, Sentinels at 3, Tanks last at 4, confirmed again by
Kai on 2026-08-21 when the order came up a second time.

**Cause 3, found on the playtest that verified the other two: waking a spawner spawns
one.** With both fixes in, room 1 held exactly ten for the whole run except the opening
seconds, which ran to fourteen, and Kai saw a Tank. `StartWave` woke all four spawner
devices at the start of every wave, and each produced one hostile of its own accord as it
came up: four uninvited, one of them a Tank, in a room the ramp had reserved for Swarmers.
Each device is now woken on the one wave its type joins and never again, so the freebie
lands on the wave that type was arriving in anyway.

## 58. The Art Direction Bible, and the seven rulings it needed — KAILEE'S RULINGS, 2026-08-21

**What this is.** `Sponsor_Me_Slayers_Art_Bible.pdf`, compiled 2026-08-21, is now the
authority on how the game LOOKS. The GDD stays the authority on how it PLAYS. Where the
bible touched play, or argued with the GDD, Kai ruled, and those rulings are below. Read
this item before placing a prop or writing a widget.

**Ruling A: retro-futurism is locked.** Section 01 of the bible offered three directions
and its own cover and concept board had already committed to one; the sources page still
listed the choice as open. Locked as retro-futurism: a 1985 TV studio's guess at the year
2100, chunky CRTs, chrome, hot neon, scanlines. The toasters, the retro TVs and the turkey
leg stop being a mismatch with "dystopian, futuristic" and become the joke.

**The sentence that reconciles it, which the bible's Step 1 asked to be added to GDD 1.1,
and which lives here instead because the GDD is a fixed PDF:** *The Network has not
reinvested in the show since its pilot episode. Every prop, prize, and hostile in the arena
is salvage, hand-me-down, or repurposed, which is why a futuristic broadcast looks four
decades out of date.*

**Ruling B: the Ranged Sentinel is the Ex-Contestant.** The bible describes three hostiles
and introduces an "Ex-Contestant, a former player who took a mechanical chassis as
severance", which GDD 1.1 allows as one of its two kinds of hostile. It never mentions the
Cyber-Boar at all. Rather than build a fifth type, the identity goes to the Sentinel: the
sniper has played this show before, which is exactly why he hangs back and shoots rather
than charging. He keeps his numbered bib. The Boar stays the cancelled-pilot mascot of
amendment 49, and still needs a look of its own.

**Ruling C: build the whole broadcast HUD, stream chat included.** The bible draws seven or
so elements; GDD 5.4 budgets three and 5.7 makes the chat cut number one. Kai's call: build
all of it. The chat is listed in 5.4 as an MVP widget in the first place, so this restores
something the cut order removed rather than inventing one. In scope: the LIVE badge,
scanlines over the frame, the announcer lower third, hostiles-left, the escalation tier, the
equipped weapon and active mods, and the chat feed. **The lower third and the chat are
containers only. Every word of announcer dialogue is Kai's, per CLAUDE.md section 0 rule 3.**

**Ruling D: the title card lands twice, and never on a main menu.** UEFN has no main menu,
amendment 18. So: a full-screen broadcast title card for a few seconds at match start,
naming the show, the season and the Career Sponsor Rank, and the holographic billboard on
the arena wall showing the rank permanently, which was already BUILD_ORDER item 26.

**Ruling E: obstacles shuffle to new spots when a room is won.** This REPLACES the reading
in amendment 23, which returned them to their starting positions. GDD 2.5's "environmental
coordinates and concrete obstacles reset" reads either way, and the bible's shuffle is what
keeps one arena interesting for twenty-one tiers. Constraint carried forward: new spots must
stay clear of the four enemy doors and away from the centre, and must never sit where the
3-metre spawn safety radius of GDD 5.3 would put a hostile inside one.

**Ruling F: between rooms, a broadcast card on a timer, not a button.** About four seconds
showing toasters collected, peak Hype, the bankroll and the tier coming next, then the next
wave starts by itself. The bible offered a BACK TO THE SHOW button and warned in the same
breath about putting a button in the combat loop. No button goes in the loop.

**Ruling G: four enemy doors, one in the middle of each wall.** The four spawners move to
them and each door gets a red light, so every hostile walks in from a place the player can
watch and learn. The doors stay clear of obstacles for ever, per the bible.

**THREE THINGS THIS BUILD CANNOT DO, SAID PLAINLY.**

1. **Claude cannot generate the concept images or model the sprites.** The bible's prompt
   pack is for Kai to paste into an image generator. Lighting, placement, colours, widgets
   and code are the buildable half.
2. **Whether UEFN can import custom art at all is UNVERIFIED.** Until it is, the in-game
   look has to come from Fortnite's existing props plus lighting, which is exactly what the
   bible's Step 2 argues for anyway: lighting is the first 80%.
3. **The set dressing has a prop budget.** GDD 5.3 allows roughly 100 active props and
   bullets, cash drops and FX already draw on it. Six sponsor banners, PA horns, a
   scoreboard, neon signage and a camera drone are not free. Count them as they go in.

## 59. The camera keeps its tilt, and stops following — KAILEE'S RULINGS, 2026-08-21

**Ruling A: the tilt stays.** The Art Direction Bible says "no tilt" and the camera has sat
about 11 degrees off straight down, with a slight twist, since the change saved on
2026-08-19 that was never written up. Kai keeps it deliberately. The reason is set dressing:
straight down you see the floor and the tops of heads, and a sponsor banner on the far fence
is invisible, which would waste the entire step 6 of the bible's own build plan. Tilted, the
fence, the banners and the fronts of the hostiles all read. This is a deliberate departure
from the bible, recorded so nobody "fixes" it later.

**Ruling B: the camera must not follow the player, so the device changes.** Kai reported the
camera following in play. It was not a setting: Epic documents the Fixed Angle Camera as one
that "can move to follow the player, but doesn't rotate", and the Fixed Point Camera as one
that "doesn't move, but can rotate to look toward the player". Following is what the placed
device is for.

**What was tried first, so it is not tried again.** Horizontal Speed and Vertical Speed set
to 0: still followed. Deadzone On, type Rectangle, sized to cover the whole arena: still
followed. Both playtested 2026-08-21.

**The change.** `TwinStickController.verse`'s `TopDownCamera` field is now typed
`gameplay_camera_fixed_point_device`. The file only ever calls `AddTo` on it, which lives on
the shared `gameplay_camera_device` base class, so nothing else in the file changed. In the
map, a Fixed Point Camera is placed above the arena and pointed at by that field. The old
Fixed Angle Camera actor, and the unused actor labelled `TopDownCamera`, are both leftovers.

**The trade, stated plainly.** A camera that genuinely never moves sees the far corners of a
46-metre room at a slant, and anything outside the frame is simply not seen. That is the
Smash TV arrangement the bible is asking for, and it is why the room was sized to the
camera rather than the other way round.

**This does not fix amendment 5.** UEFN still has no publishable orthographic camera, so the
lens is still a narrow perspective one faking it.

## 60. The Cyber-Boar takes a shotgun — KAILEE'S RULING, 2026-08-22

**What changed.** Amendment 55 gave the Boar the Kinetic Blade so it would dash
and charge. It now carries a shotgun.

**Why Kai called it.** In play the Cyber-Swarmer already reads as a charger, so a
dashing Boar made the two feel like one enemy at two sizes. Amendment 49 put all
four hostiles on the same humanoid base, so behaviour is the only thing
separating them, and two chargers waste one of the four.

**The engine rule this rests on.** Amendment 55 records that Epic's NPC brain
reacts to what an NPC holds: a gun makes it hang back and fire, a melee weapon
makes it charge. So this is a behaviour change, not a damage change, and that is
the whole point of it.

**What it costs, stated plainly.** Three of the four hostiles now stand off and
shoot, and the Swarmer is the only charger left. GDD 3.3's shotgun effect, which
"launch[es] armored Cyber-Boars backward into other hostiles", was written for
Boars crowding in close, and a Boar that hangs back is a looser target for that
chain. Put to Kai on 2026-08-22 and accepted: the Swarmer covers the role.

**Still open, and now doubled.** Amendment 46 left the Ranged Sentinel's range
and rate of fire unruled. The Boar's shotgun needs the same two figures.

**Applies to all five cards.** Amendment 55's trap applies again: the Boar has
five character definitions, base plus T2 to T5, and setting only the base card
would revert every Boar to the Kinetic Blade the moment the first wave cleared.


## 61. Wave length escalates to a 2m30 target, and the heavies are rationed — KAILEE'S RULINGS, 2026-08-22

**What amendment 30 got wrong.** It fixed the head count so waves would stay the same
length whatever the tier, and put the 8% entirely into crowding. In play that produced
the opposite: more hostiles on screen means more targets in reach, so the same head
count clears faster and later waves were SHORTER than early ones. Kai read the wording
back on 2026-08-22 and said it contradicted itself, which it did.

**The new dial is seconds, not hostiles.** 45 at Tier 1, plus 5.25 a tier, and the head
count is worked out from the length rather than set by hand. Kai thinks about waves in
minutes and seconds, so that is what the editable holds.

**Wave one is the tutorial: 45 seconds. Kai asked what the market says and left the
number to Claude.** Twin-stick arcade games in the GDD's own reference list live or die
in the first minute, and a tutorial wave that outlasts its lesson stops teaching. 45
seconds is long enough to learn running one way while shooting another, see the first
cash burst, and catch one crate on the 25-second trickle.

**2m30 IS A TARGET, NOT A HARD LIMIT. Kai's ruling 2026-08-22.** It was put to Kai that
nothing enforces it, because a wave ends when the arena is clear rather than when a
clock runs out, so a slow run simply runs long. Kai ruled it stays the length we aim
for. This also keeps GDD 2.5's win condition intact: the room is won by eliminating the
wave, never by surviving a timer.

**The head count shrinks as hostiles toughen. Claude's call, delegated by Kai.** A Tier
21 hostile takes about five times the bullets of a Tier 1 one, so without this a wave
built for 2m30 would really run eight or ten minutes and the ceiling would mean nothing.
`ToughnessPerCardStep` is 1.36, read off amendment 46's health ladders.

**Why length is not where difficulty lives.** Put to Kai on 2026-08-22 when Kai asked
what actually makes a wave harder. Tougher and denser makes each moment harder; longer
only makes you hold your nerve for longer. GDD 5.3 escalates difficulty 8% a tier and
never mentions wave length, and Smash TV, Total Carnage, Robotron and Vampire Survivors
all escalate by flooding the screen rather than by extending the clock.

**THE CEILING IS PROBABLY LONG BY GENRE STANDARDS.** Claude's read, given to Kai on
2026-08-22: nearer 90 seconds would sit better against the genre. Kai kept 2m30, on the
grounds that it is only reached at Tier 21 and almost no player will get there. Revisit
it after a genuinely long run, not before.

**The room list, written out by Kai twice.** Room 1 Swarmers. Room 2 adds a few Boars.
Room 3 adds two Ranged Sentinels. Room 4 adds one Tank. Room 5 onward gets progressively
harder. The join tiers were already built by amendment 56; the counts are what was new.

**Those counts are whole-wave quotas, not concurrency caps.** A share is a proportion of
the wave, so at room 4's size the old mix would have put about nine Tanks in the arena
instead of one. Sentinels and Tanks now carry a quota on the wave's whole contents: kill
the wave's one Tank and no other arrives until the next wave. Kai's reasoning, chosen
over the alternative, is that a heavy which returns the moment it dies is constant
pressure rather than an event.

**Rationing stops at room 15.** Sentinels run at two on arrival and three after; Tanks
at one on arrival and two after. Boars are NOT rationed, because with both heavies held
back the crowd has to come from somewhere, so they hold at roughly a fifth of it: about
four on screen in room 2, confirmed as wanted by Kai.

**A type that has used up its quota leaves no hole.** It drops out of the mix and
Swarmers and Boars divide the whole crowd between them, so the arena stays the size the
tier says and only its make-up changes.

**Wave one runs ten on screen, not twenty, and that is the ramp not a second setting.**
Amendment 56's ramp leaves an absent type's share of the arena empty, and three of four
types are absent in room 1, so the crowd is halved. All four are in by room 4, which is
where the full twenty arrives.

**THE ONE NUMBER THAT IS STILL A GUESS.** `KillsPerSecondPerHostileOnScreen` is 0.11,
from the 2026-08-22 log: 92 kills in 78 seconds with 10 on screen. Every wave length in
the game is worked out through it, so if waves run long it is the first thing to lower.
It has never been checked against a full run.

**STILL OPEN, RAISED WITH KAI AND NOT YET RULED.**

**a.** Room 4's single Tank arrives in the first few seconds, because the arena fills as
fast as it can. It is a greeting rather than a climax, and nothing yet holds a rationed
heavy back until later in the wave.

**b.** At room 15 the rationing stops in one step, so Tanks go from one a wave to a
constant stream between two consecutive rooms. That is a cliff, not a ramp.


## 62. The palette, replaced — KAILEE'S RULING, 2026-08-22

**What changed.** Kai supplied a new ten-colour retro-futuristic palette on 2026-08-22
and ruled that it replaces amendment 36. Amendment 36's hexes are dead; its structure and
its reasoning are not, and what it covered that this does not is listed at the bottom.

**The ten, as Kai gave them.**

- `#0F1216` Broadcast Black -- background, the void, anything behind the neon
- `#6E7580` Concrete Gray -- stadium floor, walls, debris
- `#25B4FF` Plasma Blue -- your bullets
- `#FFDD1C` Laser Yellow -- hazard stripes, SMG fire
- `#FF3B30` Danger Red -- enemy and threat
- `#FFC233` Prize Gold -- cash, coins, pickups
- `#39FF88` Heal Green -- health
- `#FF2D95` Sponsor Pink -- sponsor and shield
- `#FF8A00` Burn Orange -- fire
- `#A8DCFF` Frost Blue -- ice

**THE FOUR HOSTILES SHARE ONE HUE AND DIFFER BY BRIGHTNESS.** Claude's recommendation,
Kai's ruling 2026-08-22. Amendment 49 put all four on the same humanoid body, so colour
and size are the only things telling them apart, and with twenty on screen the player has
to know which to shoot first. Four separate hues would have bought that at the cost of
the thing red is doing in this palette, which is meaning threat and nothing else.

- `#C21F17` Cyber-Swarmer -- dull red, the crowd
- `#FF3B30` Cyber-Boar -- full Danger Red, the charger
- `#FF7A73` Ranged Sentinel -- pale red, and still known chiefly by the laser sight it
  paints before firing, which amendment 36 ruled and this does not change
- `#FF1447` Heavy Elite Tank -- hot crimson, with its size doing the rest

**THE CRATE TIERS ARE A VIOLET LADDER.** Claude's recommendation, Kai's ruling
2026-08-22. Amendment 36's bronze-silver-gold medal ladder cannot survive this palette:
Prize Gold is cash, so a gold crate reads as money, which was already flagged as the
clash to watch and is now unavoidable.

- `#5B4B8A` Underdog -- dull muted violet, reads as cheap
- `#8B5CF6` Rising Star -- clear violet
- `#C77DFF` Superstar -- bright pale violet
- `#FFFFFF` Prime Time -- pure white, which is what the 2026-08-19 ruling already gave it

**Why violet, checked against the market rather than guessed.** The retro-futuristic look
runs on three neon pillars, cyan, magenta and violet. This palette spends cyan on bullets
and magenta on sponsor and shield, so violet is the one pillar left unclaimed. The genre
also shows value by brightness rather than by metal, because bronze and silver read as
real metal and fight a neon palette instead of sitting in it. One hue getting brighter is
read without explanation, and it teaches the same rule as the hostile ramp above.

**WHAT THE NEW LIST DOES NOT COVER, AND IS THEREFORE OPEN AGAIN.** Amendment 36 held
three layers and thirty-odd entries. These had rulings and now have none:

**a. The player's own colour.** Amendment 36 gave the contestant `#4DD0FF`, deliberately
distinct from bullet blue `#29B6FF`, so "that is me" and "that came from me" were not the
same colour. The new list has one blue, for bullets only.

**RESOLVED 2026-08-22.** The contestant is `#7FE9FF`, a pale bright cyan, with Plasma
Blue staying on the bullets. Blue then means "mine" throughout, and the player is the
palest, brightest thing in the arena, which is the same brightness rule the hostiles and
the crate tiers now use. Claude's recommendation, Kai's ruling the same day.

**b. Hazard stripes and SMG fire now share Laser Yellow.** Amendment 36 split them on
purpose: the fence yellow was dirtied to `#C9A21A` precisely so the SMG's `#FFEE33` could
be clean. One yellow for both means the arena's stripes and the player's own tracers read
identically.

**RESOLVED 2026-08-22.** The split comes back. Hazard stripes are the dirty `#C9A21A`
against Broadcast Black, and Laser Yellow `#FFDD1C` stays clean and belongs to the SMG
alone. Kai compared the two side by side as rendered images before ruling, rather than
judging them as hex codes, and chose the dirtied version.

Nothing to do yet: hazard stripes arrive with the stadium dressing, build order item 15.
When they do, the colour goes on whatever material the fences and floor markings use.

**c. The world layer's detail.** Floor alt tile, grime, rust, dull metal and stage black
are gone; Concrete Gray covers "floor, walls, debris" as one colour, so the floor is one
flat slab again, which amendment 36 built the alt tile specifically to avoid.

**RESOLVED 2026-08-22.** Concrete Gray stays the single world colour and all the
variation comes from textures rather than more hexes.

**THE FLOOR IS CRACKED CONCRETE OVER A BLACK MARBLE BANK FLOOR.** Kai's design,
2026-08-22. Concrete is the base, and an art deco black marble bank floor shows through
where it has broken up. Kai had already imported both materials before the palette was
raised.

**It earns its place in the fiction, which is why it is recorded and not just noted.**
GDD 1.1 has contestants volunteering to escape crushing debt for a network that never
pays out. Staging that on the cracked floor of a bank says the whole premise without a
line of dialogue, and it costs nothing, because the floor had to be made of something.

**Black marble is also the best answer to the readability problem.** Every reserved
colour in this palette is bright and saturated, and all of them read against black.
A marble with gold or brass veining would have been the one version to avoid, since
Prize Gold is cash and coins would land on a floor their own colour.

Rust and grime ride in on whatever prop textures are chosen.

**d. The show layer entirely.** Sign pink, sign cyan, floodlight warm and the HUD panel
purple had no gameplay meaning and were what made the arena look like a television set.

**RESOLVED 2026-08-22.** No new colours. Decoration uses the gameplay palette dimmed
down, which is the same rule the fence posters follow, so a dim sign can never compete
with the bright version of a colour that means something. HUD panel backgrounds sit on
Broadcast Black. Floodlights are a warm off-white, since they are always large soft pools
rather than anything the player aims at or reacts to.

**e. The deep healing shade.** `#1E8F4E` existed because Kai pushed back on a single flat
green reading as a blob. Heal Green alone brings that problem back.

**RESOLVED 2026-08-22, Claude's call, delegated by Kai as a shading detail.** Heal Green
keeps a darker partner, `#1BA85A`, for the core of a healing glow. It is the same hue
darkened rather than a new colour, which is what amendment 36 established a second shade
of a reserved colour is for: depth inside one meaning. Reusing the hue on decoration is
still not allowed.

**That closes every item this replacement reopened.** a through e are all ruled.

**Fire and ice are covered.** Burn Orange and Frost Blue take over Flaming Ammo and Icy
Rounds cleanly, so those two need nothing.

**EVERY HEX HERE IS A TARGET, NOT A RESULT. Kai's note, 2026-08-22.** These colours are
read through the arena's lighting and against the floor, and neither is neutral, so a
value that is correct on paper can land on screen looking washed out, too dark, or too
close to something it was chosen to be far from. No hex in this amendment counts as
settled until it has been looked at in the arena under the lights it will ship with.

That cuts both ways and is the reason to keep the list rather than abandon it: when a
colour reads wrong on screen, the fix is to adjust that one value against the intent
recorded here, not to re-pick the palette.

**POSTERS ON THE FENCE, AND THE ONE RULE THEY OBEY. Kai's plan, 2026-08-22.** The arena's
fences carry sponsor posters, which is squarely on-theme for a show that never pays out.

A poster may be as loud as it likes, but it may not use a reserved gameplay colour at
full brightness. Those are Danger Red and its hostile shades, Plasma Blue and the
contestant's cyan, Prize Gold, Heal Green, Sponsor Pink, Burn Orange, Frost Blue, and the
crate violets. A poster that does becomes something the player's eye checks for threat or
for money, which is a cost paid in every fight for a decoration seen once.

Dulled and darkened versions of those colours are fine, which is the same rule the
dirtied hazard yellow above follows.


## 63. The crate is ours, not Fortnite's — KAILEE'S RULINGS, 2026-08-22

**Why crates never fell at all.** The Crate Manager's Audience field was empty in the
map. An unset device reference falls back to a fresh unplaced instance, so the manager
was listening to a stand-in audience that nothing ever signalled, while the real one
ordered three crates into the void. The log said so plainly: SpawnCrateEvent fired three
times and the manager never printed a single line in reply. Filling in one field fixed it.

**Then the crates arrived and were wrong.** Kai's report on sight: a column of smoke on
the floor more distracting than the crate itself, a descent too slow, and nothing visibly
carrying the crate down.

**The device had to go, and nothing was lost with it.** The smoke, the descent speed and
the tier colour were all one thing: a Supply Drop Spawner's only colour is its Supply
FXColor, which IS the smoke, so killing the smoke would have killed GDD 3.2's colour
coding too, and its descent speed is exposed nowhere. Its pickup was never used, because
collision here has always been a measured distance from the landing spot this file chose.
Its item list was already empty per amendment 26.

**So a crate is now a prop, spawned and lowered by hand.** The same technique
DeathSaveManager already used for the turkey leg. Kai asked "can't we rewrite the code",
which was the right question, and the answer was yes.

**A BALLOON STANDS IN FOR THE PARAGLIDER.** GDD 3.2 asks for "high-contrast colored
paragliders" and Kai checked the prop list: there is no parachute and no glider. A
balloon is the nearest thing and is what Fortnite's own supply drops use, so it reads
correctly while not being what 3.2 says. It exists only for the descent and is removed
the moment the crate lands.

**A SPAWNED PROP'S MATERIAL CAN BE SET FROM CODE, WHICH THIS PROJECT HAD WRITTEN OFF.**
Found in the digest on 2026-08-22 after Kai asked whether the balloon's colour could be
forced. `creative_prop.SetMaterial` exists, and so does `SetMesh`. Both the crate and its
balloon now take a material per tier, so amendment 62's violet ladder lands on the
objects themselves rather than on an effect around them.

This is the second claim of impossibility this project has recorded and then overturned
by reading the digest, after the wildlife spawner in amendment 49. Both were written down
as settled facts. Check the digest before recording that something cannot be done.

**THE DESCENT, TUNED BY HAND AND MIRRORED BACK.** Kai settled on a 350cm drift over 2
turns across a 4.5 second fall. Kai asked for it to float and swing rather than drop on a
line, so the crate spirals down and the drift tightens to nothing, landing exactly on the
spot the audience chose. Two things were learned tuning it: drama comes from the width of
the arc, not the number of turns, because more turns over a fixed fall reads as frantic;
and a wider arc needs a longer fall to read as a drift at all.

**Crates were landing in walls.** ArenaRadius was 1500, taken from amendment 51's
15-metre radius, which is the arena's own half-width. Measured from the playtest log's
own coordinates, the room is roughly 25 to 26 metres across, so 1100 leaves about 1.8
metres of margin. This also settles a contradiction: amendment 51 says 30 metres across,
amendment 59 describes a 46-metre room, and the measurement backs amendment 51.

## 64. The player could walk out of the arena — KAILEE'S RULING, 2026-08-22

**What Kai found.** The openings the hostiles come in by were walkable in both
directions. GDD 1.1 is a single-room stadium arena, so this was never intended.

**The doorways stay.** Smash TV, the GDD's stated reference, has enemies pour through
doors, and sealing them would have meant moving every spawner inside the room.

**A Barrier device in each doorway, made invisible.** Kai found the invisibility setting;
it is not the "Invisible to Ignored Players" option, which only hides the barrier from
whoever it is already letting through.

**ITS OWN TEAM AND CLASS FILTERS DO NOT WORK ON NPCS.** Tried on 2026-08-22 with the
hostiles' team index of 2, then with Ignore Class ticked as well, then with Can NPC Added
to Ignore List ticked. Hostiles were stopped dead in the doorway every time. The digest
describes AddToIgnoreList as being "in addition to the Ignore Team and Ignore Class
options", and it is the one that works.

**So the wave manager waves each hostile through as it spawns** and takes it off the list
when it dies, so a long run does not accumulate an entry per hostile.

**IT WORKS ON THE HOSTILE, NEVER ON WHAT THE HOSTILE IS.** Kai's condition: the looks and
the weapons are still being changed during play. Nothing in this reads a character
definition, a model or a weapon, so changing any of them cannot break it.

## 65. Crates must be shot open before they can be collected. KAILEE'S RULING, 2026-08-22

**What the GDD says.** 3.2: crates "trigger instantly upon player collision to maintain
momentum." Contact was the whole interaction, and the instant trigger was justified by
momentum specifically.

**The ruling.** A crate lands closed. Walking into a closed crate does nothing at all.
The player shoots it open, sees what is inside, and then walks in to collect it. **Only
the player's own shots can break a crate.** A hostile's fire cannot, and neither can
anything else in the arena.

**Why.** Kai wants to see what is inside before taking it. Amendment 38 already named the
pitfall this addresses, Power-Up Letdown, and dealt with it halfway by keeping a weapon in
every tier pool so no crate could hand over nothing. That does not save the player from a
Shotgun they already hold, which Kai raised directly on 2026-08-22. A crate you can look
at and walk away from does.

**What it costs, stated plainly.** 3.2's momentum. Collection is no longer one
uninterrupted run through a crate; it is now shoot, look, then decide. Kai was shown that
cost before ruling and accepted it, on the grounds that being handed a duplicate breaks
momentum worse than a deliberate second of shooting.

**Why hostiles are locked out.** Kai's condition. It keeps a crate from being opened, or
revealed on the far side of the arena, by something the player did not do. It also stops a
crate being spent by a stray shot during a crowd fight, which would read as the game
cheating.

**This narrows the duplicate gap but does not close it.** 3.2's refresh rule covers the
timed upgrades only, and nothing in the GDD says what a duplicate *weapon* does. A player
can still choose to collect one. That question stays open.

**Still open, and not decided here.** How many shots a crate takes to break, and what the
Sponsor Aid, Sponsor Aegis, Flaming Ammo and Icy Rounds look like sitting in an opened
crate, since none of the four is a real Fortnite item and none has a model yet.

## 66. A duplicate weapon tops up its ammo. KAILEE'S RULING, 2026-08-23

**What the GDD says.** 3.2 says a duplicate upgrade "refreshes its active duration rather
than stacking", which only makes sense for the timed upgrades. A weapon has no duration,
so the rule says nothing about the case, and amendment 65 recorded the hole.

**The ruling.** A crate that would hand over a weapon the contestant already holds tops up
that weapon's ammo instead. Kai's words, 2026-08-23: "top up the ammo instead".

**Why not pick the other weapon in the tier.** That was the alternative offered and Kai
chose against it. It would have made a crate's contents depend on the contestant's
inventory, which fights amendment 38's tier pools being a fixed promise about quality.

**Why this matters at all.** Amendment 38 already deals with Power-Up Letdown by keeping a
weapon in every tier pool so no crate is ever a dud. A second Shotgun in the same slot is
the remaining dud, and Kai raised it unprompted on 2026-08-22 while the shoot-to-open rule
was being written.

**NOT YET BUILT, AND NOT YET KNOWN TO BE BUILDABLE.** It needs the game to say what the
contestant is holding, and Verse's access to a player's inventory has not been checked.
If it turns out to be unreadable this ruling stands and the implementation has to find
another route, rather than the ruling bending to the engine.

## 67. Sponsor Aid is a med kit, not a turkey leg. KAILEE'S RULING, 2026-08-23

**What the GDD says.** 3.3 describes Sponsor Aid as a "Parachuting golden roasted turkey
leg mesh; bright green pulsing visual overlay". 3.4 has the Death Save spawning that same
turkey leg "within easy walking distance". Both are explicit.

**The ruling.** It is a med kit, in the crate reward and in the Death Save alike. Its
behaviour is untouched: it still restores 25% of maximum health on contact, per 3.3.

**The argument against, put to Kai and rejected.** The roast turkey is the most
recognisable pickup in Smash TV, which GDD 1.1 names as the tone this game is built on,
and a med kit is the generic version of the same idea. Kai reaffirmed the change on
2026-08-23 after that was said plainly.

**What it costs in practice.** Nothing structural. The prop is a slot filled in UEFN, so
the swap is two asset pickers: DeathSaveManager's Sponsor Aid Asset, and slot 4 of the
Crate Manager's Reward Props. The comments that call it a turkey leg are corrected in the
same pass so the code does not lie about it.

**The name does not change.** It is still Sponsor Aid everywhere in the code and in this
file, because the name is the joke about who is paying for it rather than what it looks
like.


## 68. The Death Save cuts to CCTV, not grayscale. KAILEE'S RULING, 2026-08-24

**What the GDD says.** 3.4 has the screen desaturate to grayscale for the three-second
Death Save window.

**The ruling.** The post process device is set to PP_CCTV_C at 0.65 strength instead, and
Kai overruled the document knowingly when it was put to them. Nothing about the window's
behaviour changes: the three seconds, the shield that holds the player up, the slowed
hostiles and the med kit are all untouched.

**The route to it.** Grayscale first became a pulsing red edge vignette, which Kai asked
for and then rejected: PP_VignetteMaskedColored_C has no colour setting, and at full
strength with a 0.2 blend it was still easy to miss. VHS was tried next and Kai liked it
enough to want it everywhere, which is where the always-on filter below came from, and
CCTV was then chosen for the window so the two read differently.

**A standing filter came out of the same conversation.** A second post process device,
VHSAlways, runs PP_VHS_Filter_C at 0.45 strength for the whole match. It supports GDD 1.1
rather than contradicting it, since the document already names chunky CRTs and scanlines as
the look. The Death Save device stacks on top of it, so the picture degrades further at the
exact moment the contestant is dying.

**The Verse field keeps its name.** It is still GrayscaleEffect on DeathSaveManager,
deliberately: renaming it would unwire the device on the placed manager.


## 69. The ammo modifiers are cut. Twelve appliance collectables replace them. KAILEE'S RULING, 2026-08-24

**This one amendment carries four departures.** They were ruled inside an hour and they
depend on each other, so splitting them would hide what traded for what.

### 69a. Flaming Ammo and Icy Rounds are both cut

**What the GDD and this file say.** GDD 5.7's cut order is stream chat widget first,
Flaming Ammo second, tiered crate scaling third. Amendment 37, on 2026-08-19, took Icy
Rounds off that list entirely with "it ships, do not propose cutting it."

**The ruling.** Both are cut. Kai was told plainly that this reverses amendment 37, that
Flaming Ammo is being cut ahead of the stream chat widget which is still on the books, and
that both features were finished and proven working in the 2026-08-24 03:36 log. Kai cut
them anyway, knowingly.

**Why they lost.** Kai asked whether the guns would fire ice shards and blobs of fire. They
cannot: what a weapon fires belongs to its asset and Fortnite keeps that sealed, so a
modifier can only change what a hit DOES, not what the bullet looks like. Burning damage
over time and a stacking slow with a glow on the target was not the feature Kai had in
mind.

**What it frees.** TierIcyChance and TierFlamingChance were 0.25 each on Prime Time, so
half of every Prime Time crate roll is now empty. That is exactly where the collectables go.

### 69b. Appliances stop being currency

**What the GDD says.** 2.3 has hostiles burst into coins, cash bundles AND retro household
appliances, and walking over any of them plays the ding and increments the run score.

**The ruling.** Money only in the hostile burst. The retro TVs, washing machines and
toasters leave the drop pool and become collectables that come out of crates instead.

### 69c. Twelve collectables, persistent across runs

**Not in the GDD at all.** 2.6's Career Sponsor Rank is the only thing the document
persists, and it is explicitly cosmetic with zero effect on combat.

**The ruling.** Twelve appliance collectables, awarded by crates. Once owned, a collectable
is out of the pool for good, so the twelve are a set to complete over many runs. A
collectable that comes up when it is already owned is turned into cash instead, which is
the same shape as amendment 66's duplicate weapon handing over ammo. They survive death:
Kai's words were "if I get a toaster and die it's still there".

**Where the save goes.** The same persistent store Career Rank already writes to, seen in
the log as SponsorMeSlayers_v2.CareerRecords. No new mechanism is needed.

### 69d. Three screens, and no pause

**The ruling.** A start screen, a defeat screen, and a collectables screen behind a key
press mid-run. All three are HUD widgets, the same machinery already drawing the Hype
thermometer and the rank title card.

**THERE IS NO PAUSE, and there cannot be.** Kai asked for one so the collectables could be
read at leisure. Fortnite treats every match as live and multiplayer and offers no pause at
any level; the only Pause functions in the whole Verse digest belong to animations,
effects and one vault sequence. Researched 2026-08-24, not assumed.

**There is no authorable main menu either.** Kai asked for the collectables screen on a
main menu. The nearest thing UEFN gives is a widget shown at match start, which is the same
artefact as the start screen above, so the two asks collapse into one.

**What is NOT decided yet.** Which twelve appliances, what the drop rate is, how much cash a
duplicate is worth, and what the three screens actually look like.

## 70. The start screen, and the broadcast it turned into. KAILEE'S RULING, 2026-08-24

**Eight rulings across one session.** They are one amendment because each one moved the
next: holding the waves forced a button, a button forced a mouse, and a mouse made the
whole screen possible.

### 70a. Nothing runs until the player says so

**Not in the GDD at all.** 2.1's loop begins at "defeat hostiles". Nothing describes what
happens before that, and the wave manager started spawning the instant the match did.

**The ruling.** The game holds until the player presses start. Kai was given the
alternative, a card that fades after a few seconds while the match already runs, and
rejected it: without the hold the contestant is shot at from behind the title.

**How far the hold reaches.** All of it. Kai's words were "hold everything until PLAY", so
the waves, the crate trickle, Hype and its decay, the starting pistol, the ammo top-up and
the rank title card all wait. Four scripts needed no gate at all, because the cash drops,
ammo modifiers, crate manager and Death Save only ever answer a hostile or a pickup.

### 70b. The start screen comes first, the title card second

**What amendment 18 says.** The Career Rank title card is "a HUD card shown at match
start", because UEFN has no main menu to put it on.

**The conflict.** Both wanted the same six seconds. **The ruling:** the start screen goes
first and the rank card plays after the player presses start.

### 70c. It is a screen with a pointer, not a keypress

**Kai's own idea, and a better one.** The plan was a keypress, spacebar. Kai asked whether
a whole separate screen with a mouse and a PLAY button was possible instead.

**It is.** A full-screen panel can hide the arena, take the mouse so a cursor appears, and
wait. What is NOT possible is doing anything about Fortnite's own countdown before a match,
which plays first regardless.

### 70d. There is no leaderboard, because there cannot be one

**Kai asked for a leaderboard so players could see their scores.** An island can only read
the save of the player standing in front of it and never anyone else's, and amendment 19
makes this game single-player, so there is nobody to rank against.

**The ruling.** A record board of the player's own **top five runs**. Kai chose five over a
single best-run line.

### 70e. The screen ships before the collectables system

**What amendment 69 agreed.** Collectables manager first, then the crate hook, then the
screen, because the screen can only draw what the save knows.

**The ruling reverses that order.** The screen ships now with twelve locked slots as a
placeholder. Kai was told plainly which way round it was and chose the screen first.

### 70f. The plain start card is replaced by a television broadcast

**Kai's brief, a few hours later.** The screen is not a menu, it is a broadcast: the player
is watching a channel, not choosing options. A locked seven-colour palette, hazard bars,
1980s TV graphics, Smash TV.

**The ruling.** The plain card built earlier the same day is out. Kai's words: "whatever,
make the start screen work." Nothing was deleted to do it; the old device comes out of the
map and its file stays, because the match hold of 70a lives beside it and five scripts
call it.

**What the interface can and cannot fake.** A VHS post-process runs on the 3D world and
cannot touch the interface, so the interface imitates it. Scanlines are real, as stacked
thin bars. Colour fringing is real, as the same text drawn three times with a red copy left
and a blue copy right. **Desaturation and edge softness are impossible:** Verse cannot
blur, feather or desaturate a widget and there is no shader access on the interface, so
they are absent rather than badly imitated. Neither can a widget be rotated, so hazard
stripes are vertical bars.

**Three engine limits found the hard way.** A shape's opacity refuses a value typed into
the Details panel, because it demands a number the compiler can prove sits between 0 and 1;
it has to be written in the script. Verse cannot set a sound's volume at all, so volume
lives on the placed Audio Player. And a sound played at a named player is silently ignored
unless that device is set to be heard by the instigator, so both new sounds play unnamed.

### 70g. One dead channel, not two

**What the brief asked for.** Two pressable channels that go nowhere: TEST PATTERN, a
colour bar card, and OFF AIR, a snow screen.

**The ruling.** One. Kai: "i only want one dead channel." Which of the two survives is not
decided.

### 70h. RSM STUDIOS goes on the ticker

**Kai's ruling, and the reason.** The scrolling ticker carries RSM STUDIOS as the station
ident between the sponsor slogans. It is a deliberate self-insert: it is the name of Kai's
company.

**What is NOT decided yet.** Which of the two dead channels survives 70g, whether the
scanlines can be lifted above the buttons without the mouse losing them, and everything
amendment 69 already listed as open.

## 71. The debt counter is a live number, and it carries between runs. KAILEE'S RULING, 2026-08-24

**What the brief asked for.** Item 5 of the 2026-08-24 broadcast brief wanted a number in a
corner reading CONTESTANT DEBT: $47,300, ticking up while the player sits on the title
screen. Interest accruing, as the pressure that makes somebody press start.

**Kai widened it on the spot.** The counter answers the actual money collected in the game.
Kai's words: "i want the debt counter to respond to the actual money we collect in the game
too, it goes up when we're offline and goes down when we're collecting the money."

**What off the air means, and why it is the right word.** The debt climbs whenever the
contestant is not on the air, which is the title screen and everything after death. It
falls while the show is running and cash is being picked up. That reading came from Kai's
own word, "offline", and it lines the counter up with the ON AIR light of the same brief:
the light out and the debt climbing are one idea.

**It carries between runs.** Kai was given the alternative, a fresh $47,300 every match,
and chose the running total, so cash paid off in one run is still paid off in the next.

**How the save holds it, and the trap that shaped it.** `career_record` gains one field,
`DebtDelta`, holding how far the debt has drifted from its starting figure across every run
ever played. A fresh save reads zero, which is exactly the starting debt, so there is no
"has this been set yet" flag to get wrong. **Both places in CareerRankManager.verse that
rewrite the record now name that field explicitly.** A field left out of one of those lists
is not a compile error, because it has a default: it is silently written as zero, and the
debt would have reset at the end of every single run.

**Who owns what.** BroadcastScreen.verse owns the counter and writes only `DebtDelta`.
CareerRankManager.verse still owns rank, records and bankroll and only carries the debt
through. Two writers on one save is a risk taken knowingly: the debt is written once a
second rather than every tick, so the most a crash or a collision between the two can cost
is one second of interest.

**Where it sits, and the budget it breaks.** Top right, opposite the ON AIR light, and up
for the whole match rather than the title screen alone, because falling is the half worth
watching. That makes six things drawing on the HUD against GDD 5.4's three. Kai already
overruled that count on 2026-08-17 for the winnings readout, and this follows the same
ruling rather than reopening it.

**What is NOT decided yet.** Whether the debt ever reaching zero means anything at all.
Nothing happens today: it simply keeps counting down past zero into credit.

## 72. PLEASE STAND BY is an idle card, not a card after the press. KAILEE'S RULING, 2026-08-24

**How this came up.** The session opened by asking whether the game should hold the
hostiles until the player presses start. It already does, as amendment 70a, and the question
was stale. Kai then produced the original 2026-08-24 broadcast brief and asked how far the
build had drifted from it, which is what caught the real problem: **item 7 in the brief is
an idle timeout, and what had been specced across five questions was a card after START SHOW
was pressed.** The specced version was thrown away.

**The ruling.** The card fires when the contestant sits on the listings doing nothing for
about thirty seconds, and a click anywhere gets out of it. Kai was given the choice of both
versions and chose the idle one alone.

**Why nothing plays after the press.** The Career Rank title card already holds for six
seconds the moment start is pressed, so a stand-by card in front of it would be two cards
back to back. Kai's own question, and the answer was to cut straight through.

**Where it may fire, and where it may not.** The listings only. The leaderboard, the prize
vault and the dead channel are all things a contestant is deliberately watching, and pulling
one away mid-loop ruins it. The idle clock resets on every channel change.

**What it looks like.** Bare: black, the words, and the colour fringing, with no scanlines,
no ticker and no listings behind it. Kai's word was "drop everything". The ON AIR light and
the debt counter ride on their own layers above the broadcast and therefore stay lit on top
of the card, which is left deliberately: both are ruled permanent, and a station insisting
it is still on air over a stand-by card is the better joke.

### 72a. Two things in the brief were never built, and are not oversights

**PAID PROGRAMMING is gone**, with its chasing marquee bulbs, its charcoal-blue studio and
its seven slogans. It went when amendment 70g cut the dead channels from two to one.

**The UNPAYABLE cap was never built.** The brief asked that the debt counter stop printing
digits past roughly 999,999 and print CONTESTANT DEBT: UNPAYABLE instead, so a long-running
save cannot shove the layout about. This is a real gap rather than a ruling, and it is now
recorded rather than lost.

**The debt counter also no longer matches the brief's design.** The brief wanted display
only, with an empty ReduceDebt to call later, and said the debt can never be paid off.
Amendment 71 wired it to real collected cash and lets it count past zero into credit.

### 72b. The broadcast is not per-player, and one day that will matter

The brief asked that every player get their own overlay, their own channel and their own
debt figure. The build does not do this: the static grid, the ticker, the channel token and
the debt drift are single values on the device, shared by everyone. Amendment 19 makes the
game single-player, so nothing is wrong today, and two testers in one session would fight
over one screen.

## 73. PAID PROGRAMMING comes back as a second dead channel. KAILEE'S RULING, 2026-08-24

**This reverses amendment 70g.** That ruling cut the brief's two dead channels down to one,
and PAID PROGRAMMING was the one that went. Kai asked for it back the same day, after
reading the original brief again. **Kai's words: "ITS A SECOND CHANNEL AT 10PM AFTER THE
PRIZE VAULT."** So the schedule is five rows now, and OFF AIR keeps its 4:00 AM slot.

**The tone is fixed and it is not Claude's to touch.** An upbeat, over-excited late night
advert. Cheerful and desperate, never menacing. Kai has said it was got wrong once already.
Every slogan and every popup line in the file is Kai's own writing.

### 73a. The popups are three different shapes, over the lights

**What was specced first, and rejected.** Three identical starbursts tucked into the corners
of the screen, deliberately clear of the slogan card and its marquee bulbs.

**Kai's ruling, in two parts.** They sit **over** the lights, on the card's corners, because
that is where an advert slaps a badge. And they are not all the same: "not all of it has to
be a spiky circle as long as it fits that theme of popup ads."

**The three.** A spiky gold badge with black words. A red sticker with a thick WHITE border
and white words, which is Kai's own. A hot pink banner with black words, the same shape the
NOW row has on the listings.

**On the white.** Kai asked whether red and white fits the locked palette. Red is one of the
seven; white is not, but it was already in the file for the static snow, so it is not a new
colour arriving. That is the whole reason the red sticker was allowed.

### 73b. The popups run on their own clock, not on the slogans

The first spec had all three clear whenever the slogan changed. That does not work: a slogan
holds two and a half seconds, so the popups would barely arrive before vanishing. **Kai's
ruling: their own clock.** One arrives, then a second, then a third, they hold, they all
clear together, and it starts again from empty.

### 73c. Three things the engine could not do, and what was done instead

- **The bulbs are squares, not circles.** A rectangle is the only shape a widget has.
- **The starburst is faked.** Fifteen stacked gold bars following a round profile, every
  other one pulled in short so the edge zigzags. A widget cannot be rotated, so a true star
  is not available. It reads as spiky rather than as a drawn star.
- **The white border is a block behind a block.** There is no border to set on a colour
  block, so the white one sits behind the red one and shows through as a frame.

**Also.** The hazard bars on this card are vertical, like everywhere else, for the reason
amendment 70f gives. Kai's mockup on the desktop has diagonal ones; that is the one thing in
it the interface cannot copy, along with its rounded corners.

**And the card carries the second colour outside the locked seven.** Charcoal blue,
#1A1F2E, for the ground. It is in Kai's own brief and the reason is in it too: a real late
night advert is brighter than the programming around it, so this one card sits lighter than
the rest of the broadcast.

**What is NOT decided.** Kai's longest popup line, ACT NOW AND YOULL GET A BONUS SECOND
TOASTER!, may spill past the edge of its badge. Nothing has been done about it yet, and
shortening the line is Kai's call rather than Claude's.

## 74. The snow dead channel comes out. KAILEE'S RULING, 2026-08-24

**The schedule is four rows now**, and PAID PROGRAMMING is the dead channel. AN APOLOGY
FROM MANAGEMENT, the snow screen of amendment 70g, is gone.

**How it came up.** Kai first asked for it to become a settings screen where a player
adjusts things as they please. That was scoped and then dropped, because the useful half of
it cannot be built: **Verse cannot set a sound's volume at all.** Loudness lives on the
placed Audio Player device, and code can only tell it to play. A working volume control
would mean placing every sound three times over at three different levels and playing
whichever the player picked, so three sounds becomes nine devices. Fortnite's own master
volume sits in the player's own settings, which no island can reach. Kai scrapped the idea
rather than pay that, and asked for a recommendation on the channel itself.

**The ruling, and the three reasons behind it.** Out. Its colour bars became the PLEASE
STAND BY card, so that half is still in the game. The infomercial tells the same
bankrupt-network joke better, because it gives the contestant something to watch. And it
was the last thing anywhere that held snow on screen indefinitely.

**That last one is the real reason.** Kai flagged the snow as bright enough to trigger a
seizure in someone with photosensitive epilepsy, and they were right: it repainted the whole
screen between near-black and white about seventeen times a second, which sits squarely in
the band that causes trouble. Cutting the channel leaves only the half-second burst that
covers a channel change, which is short enough not to.

**What was kept.** `BuildColourBars` stays, because the stand-by card is built from it.
`ChannelSlab` stays, because the BACK control on the two panels uses it. Everything else
went: the button, its hover pair, the flip between snow and bars, the pop sound, the
full-screen escape sheet, the way-out button and the four pieces of state behind them.

**What is NOT decided.** Whether the snow that still covers a channel change should be
toned down as well. It is well inside the safe range on duration alone, so nothing was
changed, and the shades it is painted in are still black, gray and white.

## 75. The stream chat sits on the RIGHT, not the left. KAILEE'S RULING, 2026-08-25

**What the GDD says.** Section 3.5 describes the simulated stream chat as "a scrolling
simulated stream chat widget positioned on the **left** side of the HUD."

**What is built.** It is on the right, under the cash counter, pinned to the right-hand
edge 13 per cent down.

**Why it moved.** The left edge is the Hype thermometer's, and the thermometer runs almost
the full height of the screen. Built to the letter of 3.5, the chat sat on top of it and
neither could be read. The GDD line was written before the thermometer had a fixed home, so
it describes a screen that no longer exists. The Hype Meter is named uncuttable in 5.7 and
the chat is first on the scope-cut list, so where they collide the chat is the one that
moves.

**The ruling.** It stays on the right. Kai was shown the conflict in plain terms and made
the call on 2026-08-25.

**What this does not change.** `ShowChat` is still the one-tick switch that performs scope
cut number one, and the chat is still the first thing to go if the schedule slips.

**And the corner it now sits in was thought unreachable.** Four attempts failed because a
canvas added to the player's screen shrinks to fit what is in it, so an anchor of 97 per
cent measured across the words rather than across the screen. A fully transparent colour
block stretched corner to corner, as the first slot of the canvas, gives the canvas the
screen's own size and the anchor then means what it says. The cash counter uses the same
shape. **A stretched sheet was blamed twice for breaking the aiming and was innocent both
times:** the real cause was a widget added with no slot, which leaves its input mode at the
default and takes the mouse. Every layer over the arena now says `ui_input_mode.None` out
loud, and aiming is uncuttable per 5.7, so that is the first line to check if it ever goes
again.

## 76. A lost run ends on a card, not on an elimination. KAILEE'S RULING, 2026-08-25

**What changed.** GDD 2.5's Run Lost used to end the match outright. It now raises a game
over card that Kai wrote the brief for: the show signing off, dismissive, already selling
the next episode. Buzzer, applause, a banner that slams in, three stats counting up, the
rank stamped on with a clunk, the buttons last, a ticker along the bottom.

**The contestant is no longer eliminated.** Kai's ruling after being shown the limits.
Fortnite deletes the body the instant a contestant is eliminated and takes the camera with
it, so the body Kai pictured lying in the arena cannot exist. The character is put in
stasis where it stands instead, and moved onto the hostiles' team so the robots lose
interest. The team move must be undone before the match can be ended: an End Game Device
works out what to end from the team of whoever activates it.

**Two things in the brief the engine will not do**, recorded so they are not tried again. A
robot cannot be told to walk over the body on cue. And a widget cannot be rotated at all,
so the rank stamp has its slam, its squash and its overshoot but no tilt.

**The LIVE dot is not on the card.** The arena already carries one and a second read as a
mistake. **The starburst leaves every other row clear**, because painting all of them made
a coloured brick rather than a burst.

**Still open at the time of writing:** both buttons end the match, deliberately and
temporarily, and the tidy-up that replaces them is not built.

## 77. The shotgun shoves and the sniper pierces. KAILEE'S RULING, 2026-08-26

**How it came up.** Kai asked why a shotgun blast only ever kills one robot and whether it
could kill several. It cannot, and GDD 3.3 does not ask for it either: the shotgun's row
is CHAIN KNOCKBACK, and cutting through a line of hostiles is the Sponsor Sniper's PIERCING
BEAM. Kai took the GDD's answer over the request.

**Neither weapon can be changed, so both effects are carried by hand.** A stock Fortnite
weapon's pellets, spread and damage are not reachable from Verse.

**The shotgun.** Any robot the contestant hits is shoved along the line away from them,
which is also the line that sends a Boar into whatever is behind it. The Boar is launched
and everything else is staggered, per the GDD's own wording, and the difference is one
multiplier. It is an impulse, so a heavy Tank travels less than a Swarmer on the same
number, which is wanted.

**The sniper pierces EVERY kind of robot**, not only the Ranged Sentinels GDD 3.3 names.
Kai was asked directly and chose all four. The beam runs from the contestant through the
robot that was hit and out the far side, and everything standing on that line takes the
same hit, up to a cap so a lined-up wave cannot become a one-shot clear.

**VERSE IS NEVER TOLD WHAT HURT A ROBOT.** This is the constraint both features are built
around. A damage_result carries who and how much; its Source is a game_action_causer, which
the contestant's own character satisfies, and there is no weapon on it anywhere.

**So the gun is inferred, and Kai found the better inference.** My first suggestion was to
fire on any hit above a set force, which cannot be aimed: the Heavy Sniper hits harder than
the shotgun, so any floor that lets a blast through lets a sniper round through with it.
Kai's answer was a damage WINDOW, which can be aimed, because the sniper lands above the
band and the pistol below it. Both files ship with the window switched off and a logging
dial on, so the numbers come from a playtest rather than a guess; until then each falls
back to the last gun a crate handed over.

**Only the contestant's own damage counts**, which Kai's question about enemy shotguns
turned up. Robot-on-robot hits and the splash of the contestant's own rocket used to set
the shove off. Neither does now, and nothing in either file can push the contestant around.

## 78. Every crate tier can hold a health pack. KAILEE'S RULING, 2026-08-26

**What it overrides.** Amendment 38 put Sponsor Aid in the Rising Star and Superstar pools
only, one entry of three in each, leaving Underdog and Prime Time unable to heal at all.
Kai asked for every crate to have a chance, was shown that this reversed their own earlier
ruling, and confirmed.

**The numbers.** Underdog, Rising Star and Superstar each a third. **Prime Time fifteen in
a hundred**, deliberately lower than the rest: it is the best crate in the game and a
health pack out of it reads as a wasted drop rather than a rescue.

**Nothing else changed.** The heal is still Sponsor Aid, still worth a quarter of maximum
health per GDD 3.3, and still rolled when the crate breaks open rather than at pickup.

**Remember the placed device overrides the script.** The four numbers are on the crate
manager in UEFN as well, and the value saved there wins.

## 81. The Swarmer's punch comes off for good. KAILEE'S RULING, 2026-08-26

**What the playtest showed.** In 95 seconds the contestant took 36 hits from Swarmers
alone: 28 of them 5 damage, 8 of them 25 to 30. Two different attacks from one robot.

**Why there were two.** `swarmer_fist_behavior` was fitted to all five
CyberSwarmerMelee character cards, in the Behavior modifier. It walks a Swarmer at
the contestant and takes 5 health on contact. But the Swarmer is still holding the
sledge hammer from amendment 55, and Epic's brain still swings it. So the punch was
extra damage on top of the hammer, not instead of it.

**It should never have been fitted.** Amendment 54 tabled the punch on 2026-08-20 and
said the file must stay "pointed at by nothing" until the project owns a punch
animation. It still owns none.

**The ruling.** Removed from all five cards. The sledge hammer is the Swarmer's only
attack. Amendment 54 stands unchanged and amendment 55's weapon list is untouched.

**Where it hides, for next time.** On the CHARACTER CARD, in the Behavior modifier.
NOT on the NPC Spawner device, which has no such setting at all. Five cards means
five places to check, and missing one leaves the punch alive at that tier.

**Watch on the next run.** That Swarmers still chase and still hit. Removing a Verse
behaviour hands the robot back to Epic's brain, and amendment 54 proved a hammer
makes that brain fight, but it has not been seen since.
