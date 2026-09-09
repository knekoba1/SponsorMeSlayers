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


## 79. The retro appliances leave the kill drops and become crate prizes. KAILEE'S RULING, 2026-08-26

**What the GDD says.** 2.1 step 1 and 2.3 both have hostiles bursting into "coins,
cash bundles, and retro household appliances (toasters, TVs)".

**The ruling.** Kill drops become cash only. The appliances are won from crates
instead, as a vault of fourteen prizes kept for good. Kai confirmed on 2026-08-26
that the robots no longer drop them.

**Why.** The title screen already carried a prize vault panel, but it was set
dressing: five fixed rows, two of them lit. This is the real thing behind it.

**The wording of all fourteen is Kai's to write.** Each slot ships with a
placeholder that names the object and makes no joke, the same rule as the barks.

**The save is a list of index numbers, not a row of flags**, because the list is
expected to grow: Kai went from four prizes to fourteen inside one conversation. It
rides in the career record, the one thing UEFN persists, and must be carried
through OnRunEnded or the vault empties at the end of every run.

**One prize per crate, and never one already owned.** The crate asks the vault
before it rolls, so a finished collection falls through to an ordinary reward rather
than costing the contestant a drop. A prize also pays cash, so a novelty fridge does
not read as a wasted drop, and it brings its own size, because one shared scale
could never suit a fridge and a roll of toilet paper.

**What this costs against the GDD.** 2.3's appliance shower is gone from kills.
Coins and cash bundles still burst out; the toasters and TVs now arrive by parachute.


## 80. A crate gives its reward AND may give a prize on top. KAILEE'S RULING, 2026-08-26

**What it overrides.** Amendment 79 made the prize one of the cuts in the reward
roll, which meant winning a toaster COST you a gun, so a prize could land as a
disappointment.

**The ruling.** Every crate gives its normal reward and then rolls again,
separately, for a vault prize, so a prize is always a bonus and never a substitute.
**Two things per crate is the ceiling**, also Kai's ruling: three or more lets a
single crate decide the run.

**The chance is 15 in a hundred, the same on every tier on purpose.** A prize is a
keepsake rather than a reward that scales with the crate.

**The prize gets its own everything.** Its own prop slot, because two props can now
stand on one crate and sharing one left whichever spawned second orphaned on the
floor. Its own place to stand, offset to one side. Its own size. And the promise is
cleared before every roll, or a stale one from the crate before hands the same prize
out twice.

**Claim is silent when there is no prize.** It warned before, which was right when a
prize was the whole reward and would now be noise on four crates in five.

**Nothing is written to the log when the roll misses**, and that cost a session on
2026-08-26: three crates opened with no prize and no way to tell luck from a fault.
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

## 82. The Hype meter's two invented penalties. KAILEE'S RULING, 2026-08-26

**What the playtest showed.** In a 95 second run the meter earned 62 points, from
36 cash pickups, 8 close shaves and 1 cluster kill, and lost roughly 290. It peaked
at 7 out of the 40 Rising Star needs and spent most of the run at zero.

**Neither penalty is in the GDD.** 3.1 lists the Hype sources and gives exactly one
decay rule, 5% every 10 seconds of INACTIVITY. A cost for being hit and a constant
bleed while playing well were both added on top, without a ruling behind either.

**The ruling.** A hit costs 3 instead of 10, which is about three cash pickups. The
constant bleed goes to zero, so the meter only leaks when the contestant goes quiet,
which is the one leak the GDD asks for. The idle leak stays at 5, untouched.

**What this is expected to give.** That same run would have reached about 35 rather
than 7. Rising Star becomes reachable in a good run rather than unreachable in any
run, and the top two tiers still have to be worked for.

**Not changed, on purpose.** A cash pickup still pays 1. Raising it was the other way
to fix this and Kai chose the penalties instead, so the meter keeps rewarding how you
fight rather than how much loot you sweep up.

## 83. Players are told generative AI was used. KAILEE'S RULING, 2026-08-26

**Why.** The instructor said players themselves have to be told, not just the grader.
Nothing in the fourteen class handouts or the course program says so in writing, so this
amendment is the record of it.

**Where it goes.** On the PLEASE STAND BY card, in white under PLEASE STAND BY:
PORTIONS OF THIS PROGRAM WERE PRODUCED USING GENERATIVE AI. Worded as a broadcast
disclaimer so it fits the station and is still completely literal. The black band was
grown from 0.44 to 0.50 to hold it, rather than a second band being added, because a
real test card carries its text in one strip.

**Both showings, not one.** The card plays after START SHOW and again when the listings
sit idle for thirty seconds. Kai's ruling: the line carries in both. One card, one line,
nothing to switch on or off.

**The hold does not change.** 2.5 seconds after START SHOW, unchanged. Kai ruled against
stretching it: getting into the arena beats a comfortable read, which is the same call
Class 13's "first ten seconds" note would have made.

**A jokey version as well, and it is Kai's own words.** A fifth entry joins the START
SHOW fine print rotation: "THIS PROGRAM WAS ASSEMBLED BY ARTIFICIAL INTELLIGENCE. THE
HUMAN RESPONSIBLE CANT CODE, THEY CONTRIBUTED MORAL SUPPORT AND NOTHING ELSE." Kai wrote
it and Claude may not rewrite it. The straight version on the stand-by card is the one
that does the actual work; the fine print is the joke.

**Not in the GDD, and not against it.** The GDD describes no title screen at all, which
is amendment 18. GDD 5.4's three-widget budget covers the in-match HUD, so a line on the
title card costs nothing against it.

**Still owed elsewhere.** itch.io asks the same question on its own upload form, and
Assignment 10 wants the agent readme and the cost analysis. Neither is covered by this.

## 84. The sponsor ticker becomes Kai's own words. KAILEE'S RULING, 2026-08-26

**What changed.** All eight adverts scrolling along the bottom of the title screen were
replaced. Claude wrote the first set as set dressing; Kai wrote seven new ones and they
go in verbatim. The header on that list now says so, and marks the list closed to Claude
the way the PAID PROGRAMMING slogans already were.

**The fourth line is amendment 83's disclosure.** Kai asked for the generative AI joke to
ride the ticker as well, so the same sentence she wrote for the START SHOW fine print is
now in three places: the stand-by card carries the straight version, the fine print
carries the joke on hover, and the ticker carries the joke without hiding.

**It went in eighth and was moved to fourth the same day, and the reason generalises.**
The ticker is one long string that the window walks from the front, so a line's position
in the list IS how long a viewer waits to read it. Last meant 24 seconds of a 34 second
loop, on a screen most people leave in five, and the idle card covers everything at 30.
Kai's ruling: move it to the middle. Fourth lands it around 10 seconds. The log settled
this rather than argument: "Ticker feed built, 618 letters per loop from 8 slogan(s)"
proved the line was loaded all along and only ever arrived too late to be seen.

**Two punctuation changes, and only these two.** Kai's QUESTIONABLE CAPITAL line quoted
its terms in curly double quotes. Those became single quotes, because a double quote
inside a Verse string ends the string and the file would not build. The (TM) marks are
Kai's and were left as she typed them.

**One thing to look at on screen.** The (TM) character is the only glyph on the ticker
that is not a plain letter, number or full stop. If Fortnite's font has no picture for
it, it shows as an empty box in two of the eight lines. One character to swap if so.

**Ticker length was not retuned.** `TickerWindowChars` is still 170. The new lines are
longer than the old ones, but the window is a fixed count of letters and does not care
what they say, so nothing about the scroll changes.

## 85. RSM STUDIOS comes off the ticker. KAILEE'S RULING, 2026-08-26

**This reverses amendment 70h.** 70h put the studio name between every advert so the
ticker read like a real channel identing itself, and said it was meant to be spotted.
Kai's ruling today takes it out. The adverts now run one after another with nothing
between them but the /// separator.

**Three places it was.** Between every slogan, in the empty-list guard, and as the text
the strip starts on before the scroll writes over it. All three are gone; the guard and
the starting text both use the separator now.

**The name is kept in the file and nothing reads it.** Deleting it would mean retyping it
to put it back. Leaving it means one line in `BuildTickerFeed` restores the old behaviour,
and the reversal stays readable to whoever opens the file next.

**Ticker length was not retuned.** `TickerWindowChars` is still 170. Taking the station
out shortens the loop but the window is a fixed count of letters, so the scroll is
unchanged.

## 86. PLAY AGAIN restarts, LEAVE THE SHOW goes back to the telly. KAILEE'S RULING, 2026-08-26

**This reverses the earlier ruling on the same two buttons.** That one had PLAY AGAIN
returning to the title card and LEAVE THE SHOW really ending the match. Kai's ruling now:
PLAY AGAIN drops the contestant straight back into a fresh run at Tier 1, and LEAVE THE
SHOW puts the broadcast back on. Neither ends the match. Anyone wanting out of the island
leaves through Fortnite's own menu, which beats dropping them on Fortnite's end screen.

**Fortnite's own round system was investigated and rejected.** Island Settings has a Round
section and there is a `round_settings_device` with `EndRound` and a `RoundBeginEvent`, so
the engine can restart a match. It was the wrong tool: a Fortnite round restart does not
restart Verse, so the wave loop would have carried on spawning through it and every script
would have needed teaching to stop anyway. Total Rounds stays at 1 and no Round Settings
device is placed.

**The mechanism, and it is smaller than the one previously planned.** `AwaitRunEnd` is the
mirror of `AwaitMatchStart`, and work that never ends is put in a `race` against it. Verse
cancels the loser, so a wave loop halfway through spawning is dropped where it stands
rather than being taught to unwind. Each manager becomes `loop: AwaitMatchStart; reset;
race{ work, AwaitRunEnd }; pack up`. `EndRunForAll` and `BeginRunForAll` open and close the
gate.

**A MODULE-SCOPED `var` MUST BE A `weak_map`, and that is why the gate is one.** A plain
run counter was written alongside these helpers and would not compile: script error 3502,
"Module-scoped `var` may only be partially read or written, e.g. `ModuleVar[Player]`", plus
"Module-scoped `var` must have `weak_map` type". Anything shared between scripts at module
scope has to be keyed per contestant. Nothing needed the counter, so there is none.

**A one second gap sits inside PLAY AGAIN and it is load-bearing.** Managers read the gate
every tenth of a second and `AwaitMatchStart` waits half a second before its first look, so
closing and reopening in one breath would be missed and nothing would restart. The
broadcast waits 1.5 seconds before coming back for the same reason in reverse: both buttons
close the gate, and only the reopen tells them apart.

**`Disable()` on the spawners is used deliberately at the end of a run.** WaveManager's
header forbids it mid-wave because it deletes live hostiles without firing
`EliminatedEvent`, which loses the count and hangs the room. At the end of a run that
deletion is the point and no count is waiting, so the thing that makes it dangerous is what
makes it right. `StartFreshRun` switches them back on.

**What carries over and what does not.** Career Sponsor Rank and the prize vault survive a
restart, because both are meant to build across runs. Cash, Hype, the escalation tier, the
robots on the floor and the crate weapons all reset.

**THE DEBT CARRIES OVER TOO, and clearing it has a payoff.** Kai's ruling: the debt counter
stays wherever the contestant got it down to rather than jumping back to the full 1.2
million. If it is ever cleared, the announcer says something snarky and the Network puts
the debt straight back up to 1.2 million. **The snarky line is Kai's to write and Claude
may not draft it**, per CLAUDE.md section 0 rule 3. A marked placeholder stands in until
then. Debt persistence saves the same way Career Rank does, so like the rank it only works
once the island is published; see amendment 22.

**Built so far, and what is still owed.** Landed: the gate helpers, the wave loop
restarting at Tier 1, the floor clearing, both buttons, the card coming down with the mouse
handed back, and the broadcast returning. Still owed: cash and Hype back to zero, the
pistol re-granted, the contestant teleported to the start, the debt work above, and outer
loops for the six other managers that still call `AwaitMatchStart` once and never re-arm.
**Until those land the second run is not clean**, and the game over card in particular will
not come up a second time.

---

## 87. Every manager re-arms for a second run. KAILEE'S RULINGS, 2026-08-27

Stage two of amendment 86. Landing PLAY AGAIN restarted the waves, but the rest of the
game only ever woke up once, so the second run played against a half-dead set of systems.
Six scripts now use the same shape amendment 86 gave WaveManager: `loop: AwaitMatchStart;
reset; race{ work, AwaitRunEnd }`.

**THE RULING ON THE RANK CARD. No card on a restart.** Kai, asked whether the cyan rank
card and its bankroll line should flash up again on PLAY AGAIN: no, drop straight into the
fight. It needed no code: `ShowCardIfPromoted` is only called from OnBegin and
`PlayerAddedEvent`, so it already greets you once per match and never again.

**THE RULING ON THE DEATH SAVE. The rescue comes back on a restart.** Found while checking
the five above, and it was the worst of the set. `SaveSpent` is a local of the per-player
watch loop and the file header says it is "set once and never cleared", which was correct
while a match held exactly one run. With PLAY AGAIN the flag leaked, so the FIRST fatal
blow of run two would take the anti-chain branch: no window, no slow motion, no turkey leg,
straight to the sign-off card. **GDD 3.4's own words are "once per life", and a fresh run is
a fresh life**, so this is what the section already asked for rather than a change to it.
The body of the loop moved into `WatchOneRun`, which the race cancels, so all four flags are
fresh locals every run and nothing is cleared by hand. The anti-chain rule inside a single
run is untouched.

**A SPAWN CANNOT BE CANCELLED, AND THAT IS WHY THESE ARE RACES.** Five of the six used
`spawn{ }` for their watch loops. A spawned loop survives the run that started it, so PLAY
AGAIN would have left the old copy running beside a fresh one: every kill paying Hype twice,
two trickles ordering crates, two crowds posting into one chat box. Each watch is now an arm
of the race instead, and Verse drops it wherever it had got to.

**A WIDGET WITH NO REMOVE IS DRAWN ONCE PER MATCH, NOT ONCE PER RUN.** `ShowHypeBar` and
`ShowChatBox` both add a widget and neither has a matching remove, so a second run would
have stacked a second Hype column and a second chat box over the first. `BarIsUp` and
`ChatBoxIsUp` stay true across a restart; the reset empties what is already on screen
instead. The Hype column is emptied by handing `AddHype` the current reading back as a debt,
which lands on exactly zero and repaints the column and the bulb in the one call.

**What each of the six resets.** Hype: the meter to zero, the cluster and idle clocks, the
shave cooldown and the armed shaves. The audience: the remembered tier back to Underdog, or
a fresh run starting at nothing would read as a fall and the first threshold crossed would
order no crate. The chat: every clock and every memory of the last run, with the cash
baseline READ rather than zeroed so it is right whether or not the score has been reset yet.
The loadout: nothing, but the 30-second ammo top-up now pauses between runs and starts its
clock over. TwinStick: nothing, but the FORT-1110974 facing repair re-runs, because PLAY
AGAIN hands the mouse back from the game over card exactly the way START SHOW hands it back
from the title card. The Death Save: all four of its flags, as above.

**Still owed from amendment 86.** Cash back to zero, the pistol re-granted with the crate
guns taken away, the contestant teleported to the start, and the debt payoff line. The Hype
half of that list is now done, in HypeMeterManager's `StartFreshRun`. Crates left standing
on the floor when a run ends are also not cleared: WaveManager's `PackUp` only takes the
hostiles.

**NOT PLAYTESTED.** None of this has been in a playtest, and neither had amendment 86's
stage one.

---

## 88. The shotgun gets its spread as well as its shove. KAILEE'S RULING, 2026-08-27

**This reverses the ruling of 2026-08-26** recorded in ShotgunKnockback.verse's header,
which said a blast killing several robots was the Sponsor Sniper's job and the shotgun's
job was only to shove. Kai played it, asked again, and reversed it: "why can't I have a
spread", then "I need the shotgun arc to be wider".

**The GDD was already on Kai's side.** Section 3.3's shotgun row asks for a "Wide
horizontal 5-pellet red-mist spread" as well as the CHAIN KNOCKBACK. Only the knockback
half had been built, so this closes a gap rather than adding something new.

**Fortnite will not widen a weapon's pellet spread**, so the fan is Verse's, applied when a
shotgun hit lands. The robot actually hit takes Fortnite's full blast; everything else in
the wedge takes half, Kai's ruling, and is shoved exactly as the chain knockback already
shoves.

**THE SHAPE IS WHAT KEEPS THE SNIPER'S JOB, not a refusal to build this.** The fan is wide
and SHORT: 160 degrees, five metres, a crowd standing on top of the contestant. The beam is
narrow and LONG: twenty-five metres across the arena. Neither does the other's work, which
is what makes both rulings true at once.

**THE WEDGE POINTS AT THE ROBOT THAT WAS HIT, NOT AT THE MOUSE.** A damage_result carries
no aim direction, and the AimRotationProbe has reported the same yaw of 90 on every line
for days, so the mouse is not a thing to trust. The line from the contestant to the robot
the pellets actually found IS the direction of the blast and needs nothing read from the
engine that might be wrong.

**Two guards, both learned from the sniper's beam.** A `Fanning` flag is up for the length
of one fan, because the fan's own damage comes back through the same DamagedEvent and
without it a blast would fan, and every robot caught would fan again, without end. And one
fan per BLAST rather than one per robot the pellets found, which is a different cooldown
from the shove's per-robot one.

**Unchanged and still true:** Verse cannot tell which gun fired a shot, so "the shotgun" is
still "the last gun a crate handed over", with the cost recorded in the file header.

**NOT PLAYTESTED.**

---

## 89. The shotgun is told apart by its burst, not by its damage. 2026-08-27

**Kai asked "this only applied to my shotgun right?" and then asked for the gap closed.**
The gap was the cost of amendment 88's inherited rule: "the shotgun" meant "the last gun a
crate handed over", so a contestant who took a shotgun and then switched back to the pistol
by hand kept fanning and shoving with the pistol. Nothing in Verse can see a hand-switch.

**THE PLAN THAT WAS ALREADY WRITTEN DOWN FOR THIS DOES NOT WORK, AND THE LOG IS WHY.** The
file carried Kai's own better idea from 2026-08-26: a damage WINDOW, on the reasoning that a
sniper round lands above the band and the pistol below it. The 2026-08-27 log was read
before anything was built, and **the shotgun does 23 a pellet while the drum gun does
exactly 23 too**, 53 hits of it. There is no band that holds one and not the other. The idea
was sound and the weapons defeated it. `UseDamageWindow`, `MinShotgunDamage` and
`MaxShotgunDamage` are now marked NO LONGER USED rather than deleted, because deleting a
wired `@editable` unwires the placed device.

**THE TELL IS THE PELLETS.** A shotgun sprays several pellets that all land in the same
frame. Every other gun in this game puts one thing on target at a time: the pistol one
bullet, the sniper one round, the rocket one blast, the drum gun one bullet every ninth of a
second. So the contestant's hits are counted inside each tenth-of-a-second clock tick, and
three in one tick is a blast. Nothing to tune per weapon, and it does not break when a crate
gun is swapped.

**Three rather than two, and rather than eight.** A blast is about eight pellets but not all
connect, and at range only a few do. Two would let a drum gun through on a tick that
happened to hold two bullets. Three has never been reached by anything else in the log.

**The third pellet is what fires, not the first**, and they all land in the same frame so
nothing is visibly late. A side effect worth having: the shove used to go off on a single
pistol shot and no longer does.

**What else the log settled while it was open.** The pistol reads 25 on a body and 50 on a
head. The shotgun's pellets fall off with distance, from 23 down through 22.3, 11.5, 10.5,
9.9 and 9.1, which is a second reason a damage band was never going to hold it.

**Also this sitting, from Kai playing amendment 88:** the fan went from five metres to
eight, KnockbackForce doubled to 180000 because the shove was not reading as a shove, and
`FanDamageShare` was corrected from 0.5 to 4.0. That last one was a real fault: the share is
of ONE PELLET, not of the blast, so Kai's ruling of "half the blast" written as 0.5 was
really half a pellet, about 11 damage, which is nothing against a robot.

**NOT PLAYTESTED.**

---

## 90. The announcer has 41 lines, not 25, and 8 of them are adverts. KAILEE'S RULING, 2026-08-28

**Kai wrote the announcer.** All 41 lines arrived on 2026-08-28 in a document titled
"SPONSOR ME, SLAYERS! - Announcer Lines". They are Kai's alone, per CLAUDE.md standing rule
3 and GDD Section 4, and they are transcribed into `pipelines/announcer-bark/barks.py`
character for character with nothing added, cut, reordered or tidied.

**THE CONFLICT, AND THE RULING.** The GDD fixes the count at 25 in three separate places:
5.2 preloads "all 25 pre-written barks", 5.4's asset budget lists "25 compiled announcer
bark audio strings" under a commitment to strict asset caps, and 5.6 makes Week 5 "write and
map the 25 sarcastic announcer audio barks". Kai wrote 41 and ruled that the number moves
rather than the writing. **The budget is 41.**

**THE SPLIT IS 33 AND 8, AND IT IS A DESIGN, NOT A ROUNDING.** 33 are the host reacting to a
moment in the game. The other 8 are the Sponsor Reads, which are the title screen's ticker
adverts spoken aloud. Kai's own words for what they are for: *"the ads are there to sprinkle
in when the announcer runs out of things to say or has said something repeatedly"*. They are
FILLER, drawn from when the moment pool has nothing fresh, never a reward for reaching a
moment. So only the ads needed the amendment to reach 41; the host himself is 33.

**THE TRIGGER LIST WAS REBUILT AROUND KAI'S TEN CATEGORIES.** The fourteen triggers of
2026-08-24 were guessed at before a single line existed, and the document proves how far off
they were: eight of them had no line written for them at all (RankUp, CloseShave, the three
Hype tiers, CrateOpened, DeathSaveOpened, DeathSaveSurvived) and four categories Kai did
write for had no trigger (cash pickup, low health, dead air, the ads). Kai's categories are
now the triggers. **A guessed trigger list is worth less than the writing it was guessing
at**, and this is the second time on this project that reading the real thing beat
theorising about it.

**Eight of the ten are wired to systems that already exist.** DeadAir and SponsorRead are
not: DeadAir needs an idle timer that nothing in the project has yet, and SponsorRead needs
the filler rule above. Both are marked NOT WIRED YET in `settings.py`.

**The word cap goes from 14 to 22, and is a warning rather than a rule.** 14 was set before
any line existed, to stop a bark still talking when the next thing happens. Five of Kai's
lines are longer, and each is long on purpose: the two longest are a DEAD AIR line and the
AI disclosure, and DEAD AIR exists precisely because nothing is happening, so there is
nothing for it to talk over. Kai's longest line is 19 words.

**TWO STANDING NOTES FROM KAI ON THE TEXT ITSELF.** Line 24, "THEY WERE GREAT TELEVISION,
FOLKS! WHO'S NEXT?", is the locked host line from the death screen notes and may not be
reworded. And the trademark symbols came off lines 39 and 40 because nobody says "tee em"
out loud; they still belong on any ON-SCREEN version of those two.

**Still owed, and it is the large half.** GDD 5.2 talks about dialogue FILES, so hearing the
host means 41 recorded clips and the UEFN devices to play them. Nothing of that exists. The
database is written; the voice is not.

---

## 91. The announcer speaks through ten devices, not forty-one. 2026-08-28

**The plumbing for GDD Section 4's commentator, built the day after Kai wrote the lines.**
`AnnouncerManager.verse` decides WHEN the host speaks and WHICH MOMENT he is speaking about.
It never touches the text, which stays Kai's under CLAUDE.md standing rule 3.

**TEN DEVICES RATHER THAN FORTY-ONE, and this is what made it a small job.** An Audio Player
device plays one sound and Verse cannot swap it: the digest gives it `Play`, `Stop`,
`Enable`, `Disable`, `Register` and nothing else. Forty-one lines would have meant forty-one
devices and forty-one fields wired by hand. **UEFN's "MSS Play Random Oneshot" MetaSound
preset holds a SET of sounds and picks one at random**, so there is one device per moment,
ten in all, and the line variety comes free. Researched in Epic's own documentation, not
guessed.

**A voice for the recording was researched too.** ElevenLabs has a sports-announcer voice
library that matches Kai's brief of "a radio DJ with big lungs and no sympathy"; Typecast and
FineVoice do the same job. **There is no rule against a synthetic voice**: standing rule 3
governs who WRITES the dialogue, and Kai wrote all 41. The title screen already carries Kai's
own AI disclosure.

**NOTHING CALLS THE ANNOUNCER. IT WATCHES.** It polls the public getters the other managers
already expose, exactly the way SimulatedAudience polls the Hype meter. That was chosen over
calling `Say()` from eight other scripts: eight edits to shipped files is eight chances to
break something a week from the ship date, and GDD 4.1 wants these systems loosely coupled.
The single exception is one new counter, `GetCratesLanded` on CrateManager, because a landed
crate left no public trace at all.

**ONE LINE PER LOOK, HIGHEST PRIORITY FIRST, and the order is a design decision.** Low
health, then a room cleared, then a room starting, then a crate landing, then a kill streak,
then cash, then filler. Several can be true at once and a host who says all of them is a host
talking over himself.

**`GapBetweenLines` at 7 seconds is the most important dial in the file.** Kai's longest line
is 19 words, roughly six seconds spoken. GDD 5.2 is entirely about the host's comedic timing,
and him talking over himself is worse than him saying nothing.

**The ads are filler, per amendment 90.** They alternate with the dead air lines during a
quiet stretch rather than replacing them, and neither is a moment in the game.

**A field left unwired plays nothing** and the host stays quiet for that moment, deliberately:
a half-recorded database has to be safe to ship.

**STILL OWED: the 41 recordings.** Nothing can be heard until they exist.

## 92. Clearing a room pays, and the game never stops escalating. KAILEE'S RULINGS, 2026-08-28

**GDD 2.1 STEP 6 WAS NOT BUILT.** "Clearing room waves yields massive cash windfalls" was in
the core loop from the first draft, and `CompleteWave` sounded the buzzer, counted the room,
climbed the tier, showed ROOM WON and paid nothing at all. The only money in the game came
from `RunScore` rising 10 per pickup off the floor. It was number 1 on the bug list Kai asked
to be held on 2026-08-28.

**THE ROOM BONUS: 1,000 FOR ROOM 1, THEN 50% MORE EVERY ROOM, FOR EVER.** Kai's ruling.
Room 2 pays 1,500, room 10 about 38,000, room 21 over three million. "Massive" is measured
against the floor loot, and the floor loot is small: a hostile bursts into 3 items at 10 each,
so a whole room of pickups is a few hundred. It is paid through the cash manager's existing
public `AddPrizeMoney`, so the money still lives in one place and WaveManager only says a room
was won and what it was worth.

**KAI FROZE THE BONUS AT ROOM 21 AND THEN REVERSED IT IN THE SAME SITTING.** The freeze was
ruled on the premise that rooms stop getting harder at 21. The rest of this amendment removed
that premise, the question was put again, and the bonus now compounds with no ceiling.

**THE GAME IS ENDLESS AND THE GDD'S TIER CAP MADE IT LOOK OTHERWISE.** Kai's words: "i am
creating an infinite game, if it caps at 21 its not infinite, how do i combat this?" The run
never did end at 21; rooms kept coming for ever. What stopped was the 8%-busier-every-room
rule, and the tier NUMBER, which left the banner reading ESCALATION TIER 21 for the whole back
half of a run with no sense of progress at all.

**CROWDING CANNOT BE THE LEVER PAST 21, AND THAT IS THE ENGINE TALKING.** GDD 5.3 caps the
arena at 40 live bots because UEFN does. Density had genuinely run out of road; the GDD's cap
was an honest reading of a platform limit, not a design choice, which is why it is amended
rather than overruled.

**SO TOUGHNESS TAKES OVER AS THE ESCALATION LEVER, at 8% a room from Tier 22 on, with no
ceiling.** Kai's ruling, and 8% is the GDD's own escalation figure, so the ramp past 21 reads
as a continuation rather than a new rule. Robots take twice the punishment by room 30 and
about ten times by room 51. **This amends GDD 5.5's hard cap at Escalation Tier 21**: the
crowd still stops there, the difficulty does not.

**TIERS 1 TO 21 ARE UNTOUCHED, deliberately.** Kai was offered toughness from room 1 and
refused it: everything up to 21 has been playtested and balanced, and the handover from
crowding to toughness is invisible to the player.

**THE ENGINE CAN ACTUALLY DO IT, checked in the digest before it was promised.** A hostile is
a `fort_character`, `fort_character` implements `healthful`, and `healthful` gives
`SetMaxHealth`, which "will be clamped between 1.0 and Inf" with current health "scaled up or
down based on the scale difference". So a robot raised the instant it spawns arrives at full.
It had to be done on the body rather than through the tier definition cards, because a card's
health lives in the asset where no script can reach it, and the cards run out at Tier 21
anyway.

**LATE ROOMS SEND FEWER ROBOTS, AUTOMATICALLY.** `ToughnessFactor` already divided the head
count by how much slower a tier's hostiles die, so that a room lands near its target length.
The endless multiplier is folded into it. Without that, a room built to run 2m30 would run
eight or ten minutes and the game would read as broken rather than as hard.

**ON SCREEN: a third line on the ROOM WON banner, in the same gold as the HUD winnings**, so
the eye ties the payout to the cash total without anything having to say they are the same
money. The panel grew downwards rather than the two existing lines moving, so the banner still
lands where Kai signed it off.

## 93. PLAY AGAIN finishes the job, and the debt becomes a billion two. KAILEE'S RULINGS, 2026-08-28

**Amendments 86 and 87 left a list owed and this clears it.** Cash back to zero, the pistol
back in hand with the crate guns gone, and the contestant back at the start. All three were
known gaps and all three were number 2 on the bug list Kai asked to be held.

**ONE CALL DOES ALL THREE, and finding it is the whole of this amendment.** The digest says
`player_spawner_device.SpawnPlayer` "uses the device's ShouldRespawnAlivePlayers setting to
control behavior when called on an alive player". So Fortnite will restart a contestant who
never died, which is exactly the position amendment 76 leaves them in: the game over card
freezes them standing on a single point of health rather than eliminating them, because
elimination deletes the body and takes the camera with it.

**Kai was offered the hand-built version and turned it down.** Teleport, heal, and strip the
guns with a new Item Remover device: three things built by hand that Fortnite already does in
one, plus a device to place and configure. The cost of the chosen route is the usual brief
respawn moment, which Kai accepted.

**THE PAD NEEDS ITS RESPAWN ALIVE PLAYERS SETTING TICKED.** Without it the call does nothing
at all and PLAY AGAIN goes back to opening wherever the last run died. It is the one thing
this amendment needs from UEFN.

**And the spawn re-arms the rest for free.** `SpawnedEvent` already hands the pistol back
through the loadout manager, and CrateManager already clears its record of which guns have
been handed out on the same event, so a crate offering the gun you used to hold gives the gun
rather than a magazine for it.

**The first run of a match is skipped deliberately.** The contestant is already standing on
the pad when the show starts and respawning them there would be a lurch for no reason.

**CASH RESETS IN THE CASH MANAGER'S OWN OUTER LOOP.** It was the one manager amendment 87 did
not re-arm, because everything in it hangs off events and there was no continuous work to
race. It gets the loop without the race.

**THE DEBT IS NOW $1,200,000,000. Kai's ruling, asked as "can the debt just be in the
billions?"** It was $47,300, a believable amount of real debt. Amendment 92's room bonuses
cleared that by about room 8, and a debt that can be paid off in ten minutes is not the life
sentence the premise needs. At a billion two it holds until about room 33.

**THE INTEREST HAD TO GROW WITH IT.** Seven dollars a tick moved only the last two digits of
a billion and the counter read as frozen, which killed the "obviously climbing once noticed"
effect it was tuned for. Now 250 a tick, a thousand a second: the thousands column climbs
while you watch and the billions never budge.

**A FLOOR AT ZERO, WHICH NEVER EXISTED.** `DebtDrift` had nothing stopping it, so a paid-off
debt would have shown as a negative number on the television. Now the counter stops dead,
flashes CONTESTANT DEBT: PAID IN FULL for three seconds, and the Network reissues the debt at
full, which is Kai's ruling from amendment 86 finally built. **The host says nothing about it
yet**: the snarky line for that moment is Kai's to write under standing rule 3 and there is no
recording of it, so the flash carries the moment alone.

**ONE BUG FOUND WHILE IN THERE.** The debt pays down from the run score, remembering how much
it has already credited. With cash now resetting between runs, that memory was higher than the
new run's score, so the debt would have paid off nothing until run two beat run one. It now
notices the total going down and re-reads its baseline, the same way amendment 87 handles the
chat's.

**NOT PLAYTESTED.** Neither this nor amendment 92 has been in a playtest.

## 94. A crate cannot outlive the run that ordered it. 2026-08-28

**Bug 3 of Kai's list, and it was worse than the "crates litter the floor on a restart" it
was written down as.** WaveManager's `PackUp` only ever took the hostiles, so anything the
crate system had put on the floor stayed there through the game over card and into the next
run.

**THE REAL FAULT IS AMENDMENT 87'S WARNING, WORD FOR WORD: a spawned task survives the run
that started it.** Each crate runs as `spawn{ RunCrate }`, so a crate ordered seconds before
a run ended carried on privately behind the game over card. Once PLAY AGAIN opened a fresh
run that crate would land in it, light its glow and hand over a weapon minutes into a run
that had not earned it. Litter on the floor was the visible half of it.

**Each crate is now raced against `AwaitRunEnd`**, the same shape the six managers of
amendment 87 use, and the losing side sweeps that tier: the crate, its balloon, the reward
and prize props standing on it, its glow, and its descending flag.

**THE SWEEP ONLY RUNS IF THE RUN IS WHAT ENDED IT, and that is not fussiness.** `RunCrate`
also returns early when a newer crate of the same tier has replaced it. Sweeping the tier on
that path would delete the replacement rather than the crate that was told to stand down,
which is the exact fault the 2026-08-23 churn guard was built to stop. A `RunEnded` flag set
inside the losing arm of the race is what tells the two apart.

**THE BALLOON HAD TO BECOME VISIBLE TO DO IT.** It was a local of the crate's own routine and
nothing outside could reach it, which was fine while a crate always ran to the end of its own
story. Cancel that routine mid-descent and the balloon is left hanging over the arena for the
rest of the match with no handle on it anywhere. It is now written down per tier, exactly like
`LiveCrates`, and `ClearTier` takes it.

**Loose cash needed nothing.** Every drop already races its own five-second despawn, per GDD
5.3, so the floor clears itself long before the card comes down.

**NOT PLAYTESTED.**

## 95. Nothing crosses a wall: not the cash, not the rescue. KAILEE'S RULING, 2026-08-28

**Bug 4 of Kai's list, plus one Kai added on the spot:** "fix the death save loop bc the med
pack also falls outside the wall".

**CASH COULD BE COLLECTED THROUGH THE WEST WALL.** The adversarial QA agent's INV-11 watched
the score go up three times while the contestant stood outside the arena. The pickup only ever
asked how far a player was from a drop, and the magnet of amendment 50 was helpfully dragging
drops to the wall to be taken through it. Three loops now ask whether the player is in the
room first: the pickup, the magnet's reach test, and the magnet's pull.

**IT IS DELIBERATELY BELT AND BRACES.** TwinStickController's containment, built the same day,
drags anyone who gets out back inside within a tenth of a second, so in a clean playtest this
guard never fires. It is here because a pickup is worth money and a containment loop is one
more thing that can be switched off in UEFN.

**THE MED KIT WAS THROWN IN A RANDOM COMPASS DIRECTION WITH NOTHING CHECKING THE WALLS.** Die
anywhere near the edge and GDD 3.4's rescue, which "always spawns within easy walking
distance", landed outside the room. The window then ran its three seconds against something
unreachable, which is a loss the design never intended to deal out.

**IT NOW TURNS INWARD RATHER THAN BEING CLAMPED, and the difference matters.** Clamping alone
drops the leg flat against the wall the contestant is already stood at, so in a corner it can
land almost on top of them, and a rescue you walk into by accident is not the three-second
scramble GDD 3.4 describes. A throw that would clear a wall is re-aimed at the middle of the
arena at the same distance, and only then held inside the walls as a last resort, because a
contestant in a corner can beat the turn as well. Away from the walls, where most fatal blows
land, every direction is still equally likely.

**A HUNDRED CENTIMETRES OF INSET**, so the leg never lands flush against the boundary where
reaching it would mean standing in the wall.

**FOUR FILES NOW CARRY THEIR OWN COPY OF THE ARENA'S HALF EXTENTS**: SimulatedAudience,
WaveManager, TwinStickController and AdversarialTester, and now the cash manager and the death
save manager as well. Each says in its comment that it must match the others. That is the
house pattern rather than an oversight, since a device cannot read another device's editable,
but it is six places to change if the arena is ever resized.

**NOT PLAYTESTED.**

## 96. The ammo modifiers are cut in the code as well. KAILEE'S RULING, 2026-08-28

**A CUT RULED FOUR DAYS AGO HAD NEVER BEEN MADE.** Amendment 69a cut Flaming Ammo and Icy
Rounds on 2026-08-24, knowingly and against amendment 37, and CLAUDE.md section 8 has said
they are "out of the game" ever since. `TierIcyChance` and `TierFlamingChance` were still
0.25 each on Prime Time, `DecideReward` still rolled codes 6 and 7, and `GrantTier` still
started both modifiers. **Half of the best crate in the game was handing out two cut
features.** Found while filling in the reward props, and confirmed against the placed device:
it carries no override for either chance, so the script defaults were what played.

**Both are zero now, and the freed half goes to the rocket launcher.** Kai's ruling. The roll
falls through to the weapon pool, so a Prime Time crate is 15% a health pack, 25% the Sponsor
Aegis and 60% the rocket. The best crate in the game mostly hands over the best gun in the
game, which is the simplest promise for a player to read.

**Amendment 69a had meant that space for the twelve appliance collectables.** Amendment 80
then made prizes a separate roll on top of the reward rather than one of the cuts, so the
space was genuinely unspoken for by the time anyone came back to it.

**ZEROED, NOT DELETED.** The two fields, reward codes 6 and 7 and the whole of
`AmmoModifierManager` are left standing, so bringing either modifier back is a number rather
than a rebuild. Deleting an @editable also throws away whatever a placed device has saved in
it.

**AND THE REWARD PROPS LIST WAS THE WRONG SHAPE, which is why it sat empty.** It was indexed
by reward code, eight entries long, and the first four were ignored because guns are laid out
by their weapon spawners instead. Filling it meant adding four blank entries before reaching
the two that mattered. It is now two entries: 0 the Sponsor Aid, 1 the Sponsor Aegis. Codes 6
and 7 were the modifiers, so two is the whole of it.

**STILL OWED BY KAI, IN UEFN:** the two prop assets themselves. Until they are filled, a
health pack or shield crate opens onto an empty floor, which is bug 5 on the list and the
reason this was opened at all.

## 97. The crate's health pack is a real med kit, not scenery. KAILEE'S RULING, 2026-08-28

**There is no health pack PROP in the library.** Kai went looking for one to fill
`RewardProps` with and came back with "i cant find a health pack asset". That is the same
wall DeathSaveManager hit when GDD 3.4's Sponsor Aid was built: the med kit exists as an
ITEM and Fortnite has no scenery version of it.

**So it gets the same answer: an Item Spawner.** Kai's words, "can we do the same thing we
did for the death save manager". A crate holding the health pack now lays out a real med kit
on top of itself, exactly the way a crate holding a gun lays out the gun.

**ITS OWN DEVICE, NOT THE DEATH SAVE'S.** That one is teleported to wherever the contestant
fell and could be doing it at the same moment a crate wants one. A device can only be in one
place at a time.

**WHAT IS SHOWN IS STILL NOT WHAT HANDS THE HEAL OVER.** Touching the crate heals in code as
it always has. The item is there to be seen, and it is switched off the instant the heal
lands, the same way the weapon spawners are.

**Leave `AidSpawner` empty and nothing breaks.** The teleport fails, the prop branch takes
over, and `RewardProps` entry 0 shows instead. Whichever of the two Kai fills in is the one
that plays.

**ONE GAP CLOSED ON THE WAY PAST.** Only the grant path ever switched a spawner off, so a gun
laid out on a crate that timed out uncollected stayed lying on the floor afterwards.
`PutAwayLaidOutItem` now runs on the expiry path and on amendment 94's run-end sweep as well.
Not on the replaced path, deliberately, since by then a newer crate of the same tier may have
laid out its own.

**STILL OWED BY KAI, IN UEFN:** place one Item Spawner holding a med kit, point AidSpawner at
it, and fill `RewardProps` entry 1 with a prop for the Sponsor Aegis shield.

### 97a. The shield gets an Item Spawner too

**Kai's follow-up, "how do i have the shield and the med kit", and the answer is one device
each.** Fortnite has a shield potion item and no shield prop, so the Sponsor Aegis takes the
same route the health pack took in 97: `AegisSpawner`, laid out on the opened crate, switched
off the instant the shield is handed over in code.

**AND NO, THE DEATH SAVE'S SPAWNER CANNOT BE BORROWED.** Kai asked. That device is teleported
to wherever the contestant fell and could be doing exactly that at the moment a crate wants
it, and a device can only be in one place at a time. Two crates of different tiers can be
open at once as well.

**ONE DEVICE PER ITEM RATHER THAN ONE THAT CYCLES.** The digest gives an Item Spawner
`CycleToNextItem`, so a single device holding both items could be stepped onto the right one
before spawning. It would have to count its own position in a list it cannot read back, and
one stray cycle would put a shield on every health crate for the rest of the match. Two
devices cannot get that wrong.

**Both fall back to `RewardProps` if left empty**, so a prop still works for either if a
suitable one ever turns up.

## 98. PLAY AGAIN is a clean slate. The debt no longer carries. KAILEE'S RULING, 2026-08-28

**Kai's words, after watching a restart in a playtest:** PLAY AGAIN should be "like you're
hitting START SHOW for the first time", and "the only thing that stays is the career rank".

**THIS REVERSES AMENDMENT 86 ON THE DEBT.** That one had the debt counter stay wherever the
contestant got it down to rather than jumping back to the full figure. It now opens at
$1,200,000,000 every run. `ReadDebtDrift`, `SaveDebtDrift`, `DebtSaveEveryTicks` and
`TicksSinceDebtSaved` are left standing but unused and marked as such, the way
DeathSaveManager marks its retired settings, in case it is ever made to carry again.

**THE PERIODIC SAVE IS GONE WITH IT.** Writing the drift to the career record every second was
writing a number nothing would ever read back.

**BUT THE TWELVE APPLIANCE COLLECTABLES STILL SURVIVE, and Kai was asked directly.** Amendment
69c has them persist across runs, in Kai's own words "if I get a toaster and die it's still
there", and the whole point of them is a set built over many runs. Offered the clean sweep,
Kai kept them. So what survives a restart is the Career Rank and the collection; everything
else starts over.

**THE RESET IS A WATCHER BESIDE THE COUNTER, not part of it.** The debt counter runs for the
whole match rather than per run, because the debt climbs while the contestant is off the air
too. The reset re-reads the credited-score baseline rather than zeroing it, so it is right
whichever order it and the cash manager's own reset happen to run in.

**STILL OPEN FROM THE SAME RULING:** the Career Rank being shown on the leaderboard as the
highest rank achieved next to the score. The board is still amendment 72's five placeholder
rows.

## 99. The contestant is on the leaderboard. KAILEE'S RULING, 2026-08-28

**The other half of amendment 98's ruling:** the Career Rank is the one thing that survives a
restart, and Kai wants it "shown on the leaderboard as highest rank achieved next to the
score".

**FIVE MADE-UP CONTESTANTS AND ONE REAL ROW.** The contestant's best score ever, out of the
same career save the rank lives in, slots in among amendment 72's five placeholders wherever
it lands, with the rank title beside it. Kai chose that over pinning the row at the bottom:
the point is watching yourself climb, and a pinned row shows no movement.

**THE FIVE STOPPED BEING FINISHED LINES.** They were written out as complete strings, columns
and all, which cannot be sorted against a real score. They are now a name and a number each,
and every row on the board is written out at draw time through the same code.

**THE BOARD IS REDRAWN WHEN IT IS OPENED, not only when it is built.** Every channel in this
file is built once at match start and hidden, so the row would otherwise have shown whatever
the record said before the first run and stayed there all session. The row widgets are kept
and their text is rewritten on the way in.

**IT STILL WORKS WITH THE CAREER RANK SLOT LEFT EMPTY IN UEFN**, because the rank is read out
of the shared career save rather than off the device. Wiring it costs nothing and changes
nothing; leaving it costs nothing either.

**THE WARNING UNDER THE HEADING HAD TO CHANGE.** It said the scores were placeholders and
nobody had ever scored this, which stopped being true of one row in six. It now says five of
the six are made up and yours is not.

**THE NAME ON YOUR ROW IS "YOU", and it is an editable string.** Verse cannot read a player's
Fortnite name, the same closed door amendment 7 hit.

**NOT PLAYTESTED.**

### 99a. The board is real, and it keeps every run

**Kai looked at 99 and asked for the rest of it:** "i want it to be a real leaderboard, all
the scores are there but only the top 5". So the five made-up contestants are gone entirely,
and every row is one of the contestant's own runs.

**IT KEEPS THEM FOR GOOD, NOT FOR A SITTING.** Kai was offered the choice and took the saved
one: the five best runs live in the same career save the rank does, so they are there
tomorrow. A board that empties every time the game is closed has nothing worth chasing on it.

**THE RANK BESIDE EACH SCORE IS THE RANK HELD AT THE END OF THAT RUN**, not the one held now,
which is why it is stored alongside rather than looked up. The board reads as a history:
here is what you scored, and here is who you were when you scored it.

**TWO PARALLEL LISTS IN THE SAVE, `TopScores` and `TopScoreRanks`.** A struct inside a
persistable struct is more than this needs, and `PrizesFound` already proved a plain list of
ints saves correctly. A save written before this existed reads back as two empty lists, which
is exactly a board nobody has scored on yet, so no migration is needed.

**THE RUN IS WALKED INTO PLACE RATHER THAN SORTED.** Everything it beats shuffles down one and
the list is cut off at five. **A tie keeps the older run above**, deliberately: matching a
score you already hold should not read as beating it.

**Five empty places are drawn on a fresh board** rather than a blank panel, so filling it in is
visibly the job.

**`RankName` is public now.** The board needs the name of a rank held during some earlier run,
which is not the rank anybody holds now, so `GetRankTitle` could not answer it.

**AMENDMENT 72'S LAST PLACEHOLDER DATA IS GONE with this.** The fake prize list went in the
2026-08-26 audit; the fake leaderboard was the other half and outlived it by two days.

## 100. The robots stuck outside the west wall get pulled back in. KAILEE'S RULING, 2026-08-28

**A HUNG RUN, NOT AN UNTIDY ARENA.** A wave ends when everything in it is dead, so a robot
that cannot find its way into the room can never be killed and the room never finishes. The
log for 2026-08-26 shows one robot alive, the contestant on 75 health, and nothing happening
for nineteen seconds.

**THE CAUSE IS PARKED AND STAYS PARKED.** The Swarmer spawner sits outside the west wall at
about X -1500 and Kai will not move it, because moving it would spoil how the arena looks.
Turning the fence's collision off did not help. A Barrier Device with Ignore Team did not
either: the barrier's ignore rules govern bumping through it, not the robots' navigation,
which still sees a wall.

**ONLY ROBOTS STUCK OUTSIDE THE ROOM ARE MOVED.** Kai chose that over moving any robot that
has stopped. A robot outside the walls is always wrong, so the rescue cannot misfire. A Ranged
Sentinel standing inside shooting at the contestant has not moved either, and yanking it
across the arena would read as the game cheating. StuckHostileProbe's own header has warned
about exactly that confusion since it was written.

**BEING OUTSIDE IS NOT ENOUGH ON ITS OWN.** Every Swarmer is legitimately outside for the
first seconds of its life while it walks in from that spawner. It has to be outside AND going
nowhere for six looks, which is the threshold the probe already used for reporting.

**IT GOES STRAIGHT IN THROUGH THE NEAREST WALL**, which is what clamping each coordinate on
its own amounts to, since the wall a robot is nearest is the one whose limit it has broken.
**Never within three metres of the contestant**, GDD 5.5's spawn safety radius applied here
for the same reason: arriving on top of somebody is not a fair hit.

**IT LIVES IN StuckHostileProbe.verse, which said it would need a new ruling before it grew a
fix.** This is that ruling. The 2026-08-26 refusal of a wider safety net that cleared out a
stalled wave still stands: this despawns nothing and ends no wave.

**IT TRIES AGAIN EVERY LOOK while the robot is still out there.** A successful teleport counts
as movement, so the counter clears on the next look and the rescue stops of its own accord.
Only the first failure is logged, or a robot that genuinely cannot be moved would write a line
every second for the rest of the match.

**NOT PLAYTESTED.** The beacon was down when it was written.

## 101. The wave loop was giving up on hostiles that were still coming. 2026-08-28

**Found in the 2026-08-28 playtest log rather than reported.** Twice in one run the wave loop
warned that three, then four, requested hostiles had never arrived, released their reservation
and asked again. **Both times a hostile arrived 0.13 seconds later.** Nothing had ever been
lost.

**THE TIMEOUT WAS TUNED AGAINST A DIFFERENT GAME.** Six seconds came from an arrival time
measured at about two seconds on 2026-08-21, before the loop ever had four hostiles queued at
once. The spawner device paces its own deliveries, and with a queue behind it, it can go quiet
for a little over six seconds and still be working. Now twelve.

**GIVING UP TOO EARLY IS NOT HARMLESS, which is why this is worth an amendment rather than a
tidy-up.** Releasing the reservation makes the loop ask for replacements, and then the
originals arrive on top of them. The arena can end up carrying more hostiles than the
concurrent target it was given, and GDD 5.3 caps that at 40. This was quietly pushing at a
hard limit.

**THE SAFETY VALVE ITSELF IS UNCHANGED.** It measures time with NOTHING arriving at all, not
time per hostile, and any arrival resets the clock. So a slow trickle never trips it and a
spawner that has genuinely died is still caught, just twelve seconds later than before.

**THE SCRIPT AND THE DEVICE HAD DRIFTED, again.** The script said 5 and the placed device said
6, which is the fourth time CLAUDE.md section 10's warning has been proved. Kai has to set the
placed Wave Manager to 12 as well, or the device's 6 goes on winning.

### 100a. The rescue slides along the wall, it does not step into the room

**First playtest of amendment 100, and Kai's report was "the enemies were teleporting in front
of me".** The log had one rescue in it: a Swarmer pulled from X -1315 to X -900, which is hard
against the inside of the west wall. Kai was fighting at the west end at the time, so it
arrived at their elbow.

**THREE METRES WAS THE WRONG FIGURE TO BORROW.** It came from GDD 5.5's spawn safety radius,
and a spawn is something the player expects. A robot appearing out of nothing is not, and it
needs more room than one that walks in. Five metres now.

**AND KAI RULED ON WHERE IT GOES, not just how far.** In their words: "if the robot was stuck
at the west wall it just appears right in front of the wall so it still looks like its running
in, and not in the middle of the arena". So a robot that would land too close is slid ALONG
the wall it came through rather than pushed out into the room. It still enters where it got
stuck, which is what sells it as running in.

**THE SIDE IS CHOSEN, NOT ASSUMED.** Away from the contestant is tried first; if the wall runs
out that way, the other direction is used instead, because at the end of a wall "away" would
simply clamp back to where they are standing.

**FIVE METRES IS THE CEILING HERE, because the room is small.** The arena is 21 metres by 11,
so the east and west walls are 11 metres end to end and about 8 once the inset is off. Asking
for more would spend most of its time clamped into a corner.

**ONE THING THE PLAYTEST ALSO SHOWED, unfixed and not yet ruled on:** the shotgun's shove is
900,000 on the placed device against 180,000 in the script, the fifth script-versus-device
drift this project has hit. That is enough to throw a robot clean out of the room, which is
one way they end up outside needing rescuing in the first place.

## 102. Robots run and arrive a little faster. KAILEE'S RULING, 2026-08-28

**Two dials, both from Kai playing:** "the enemies are a tad too slow" and "they spawn in a tad
too slow".

**`HostileBaseSpeed` 0.85 to 0.92.** The 0.85 came from the opposite complaint earlier the same
day, when robots at full card speed killed Kai in 1.8 seconds because they kept pace and
nothing could be kited. So the answer is between the two rather than back at full speed. This
is still the only place in the project that writes a hostile's speed.

**`SpawnIntervalSeconds` 1.2 to 0.9.** Still well off the 0.25 that once put sixteen robots in
the arena in 4.9 seconds, so the trickle stays a trickle; the room just fills about a third
faster. A wave's head count follows this on its own through `SpawnTimeShareOfWave`, so a
quicker door makes a fuller room rather than a longer one.

**BOTH ARE OVERRIDDEN ON THE PLACED DEVICES and Kai has to type them in.** That is now the
sixth and seventh time. CLAUDE.md section 10 has warned about it since it was written.

## 103. PLAY AGAIN empties the arena, and last run's robots stop paying. KAILEE'S RULING, 2026-08-28

**Kai, watching a restart: "why is cash falling when i first spawn in, i didnt kill the
enemies?" and "when i press play again all the robots that surrounded me are still there".
Both are the same fault.**

**`Disable()` DOES NOT EMPTY THE ARENA, and WaveManager's header claimed it did.** The digest
is exact: "Characters will despawn if *Despawn AIs When Disabled* is set", and it is not set on
the placed spawners. The 2026-08-28 log settles it: a restarted run opened with **nine robots
already alive**, the ones that had just killed Kai, standing where they fell. `DespawnAll` is
the call that actually clears them, and it is what `PackUp` uses now. No instigator is passed,
so no contestant is credited with killing a roomful of robots they never touched.

**AND THOSE DEATHS ARRIVE AS ORDINARY ELIMINATIONS, moments later, inside the new run.** Three
things paid out on them: the cash, which is what Kai saw raining down outside the west wall
having shot nothing, the run score, and the wave counter, **which is why it reached MINUS
THREE**: a wave was counting deaths that were never part of it, so it ended while robots were
still walking in.

**A HOSTILE A RUN HAS NOT SEEN ARRIVE IS NOT THAT RUN'S BUSINESS.** Both the wave manager and
the cash manager now keep their own record of every hostile they watched spawn, emptied at the
top of every run, and ignore the death of anything not in it.

**TWO RECORDS RATHER THAN ONE SHARED ONE, deliberately.** The cash manager could have asked the
wave manager, and GDD 4.1 wants these devices loosely coupled. The record is three lines; a
dependency is forever.

**AND THE CASH MANAGER ALSO REFUSES TO PAY WHILE NO RUN IS LIVE**, because the arena is cleared
the instant a run ends, a full second before the next one opens, and at that moment its record
still holds the old run's hostiles. The gate catches what the record cannot.

**WHAT SURVIVES A RESTART IS UNCHANGED and Kai restated it while ruling this:** "play again
needs to be like complete reset and do over, minus the score you get and the prizes i won". The
career score, the rank and the twelve collectables carry; everything else starts over.

### 103a. The arena is swept clean before the show starts

**Kai, watching the first seconds of a run: "why did the robot evaporate when i first spawned
in".** The log has three hostiles eliminated inside the first three seconds, none of which the
run had watched arrive: they were standing in the world before START SHOW was pressed, and the
spawner reset that opens the first wave took them away.

**AMENDMENT 103'S FILTER ALREADY MADE THEM HARMLESS.** They paid no cash and did not count
towards the wave, which the log confirms: sixty-six eliminations in that run, sixty-three paid,
three refused. This is only about not seeing it happen.

**SO THE SPAWNERS ARE SWEPT AT `OnBegin`**, while the title card is still up and nobody is
looking at the arena. It is the same `DespawnAll` PackUp uses, for the same reason and with the
same absent instigator.

## 104. A prize won before your first run ended was thrown away. 2026-08-28

**Found in the log, not reported.** Twice in one session: "Prize vault -- no record to save
into, so REFRIGERATOR, LIGHTLY HAUNTED was not kept", and the same for a MICROWAVE. Two of
amendment 69c's twelve collectables, won and lost on the spot.

**THE CAUSE IS AN ORDERING ONE.** The career record is first written by CareerRankManager when
a run ENDS. The vault refused to save into a record that did not exist yet, so every prize won
on a contestant's very first run had nowhere to go. **The first run is exactly when a player is
most likely to be collecting their first appliance.**

**An empty record is now the starting point rather than a problem.** Every field of
`career_record` defaults to what somebody who has done nothing yet should have, so the vault
builds one and writes into it.

**AND THE SAME AUDIT FOUND THE LEADERBOARD ABOUT TO BE WIPED.** A hand-built `career_record`
writes back EVERY field, so one left out is written back empty. Amendment 99a added `TopScores`
and `TopScoreRanks` and only OnRunEnded listed them. Winning a prize would have cleared the
board; so would the promotion card. All four rebuild sites now list every field: OnRunEnded,
the promotion card's flag clear, PrizeVault's Add, and the retired SaveDebtDrift, which was
itself missing PrizesFound the whole time it was in use.

**THE 2026-08-26 AUDIT FOUND THIS EXACT FAULT ONCE ALREADY** and the comment it left behind is
what made it quick to find the second time. Four sites is three too many; a single helper that
takes a record and one changed field would end it, and that is a tidy-up for a quieter day.

## 105. Shooting anywhere near the crate stopped counting as shooting at it. KAILEE'S RULING, 2026-08-28

**Kai, playing: shooting off in another direction still opened the crate.** `AimToleranceDegrees`
was 90, which means the crate only had to be somewhere in the HALF of the world the contestant
was facing. That is nearly every direction except behind them.

**45 NOW, THE THIRD NUMBER TRIED AND BETWEEN THE OTHER TWO.** 25 was rejected on 2026-08-23 as
demanding near-perfect aim while being swarmed. 90 is too generous to read as aiming at all. 45
asks for the crate to be in the quarter of the world in front of you, which is about what
"pointing at it" looks like on a top-down screen.

**IT DOES NOT FIX THE DRY CLICK, and cannot.** Amendment 65 counts the contestant's trigger
press because Fortnite gives no signal for a bullet leaving a gun, so an empty magazine still
opens a crate you are aiming at. Kai was offered two presses instead of one as a tightening and
has not ruled. The magazine itself is unreadable; amendment 7's closed door.

**No UEFN step: the placed crate manager carries no override for this one**, checked in the
map file rather than assumed.

## 106. The shotgun was firing robots out of the arena. KAILEE'S RULING, 2026-08-28

**`KnockbackForce` was 900,000 on the placed device against 180,000 in the script**, the fifth
script-versus-device drift this project has hit, and the log settles which one plays: every
shove in the 2026-08-28 run printed 900,000.

**IT MATTERS MORE THAN THE USUAL DRIFT.** That is enough to throw a robot clean out of the
room. Once it is outside it cannot path back in, so the wave cannot finish until amendment
100's rescue teleports it back, and a robot arriving out of nothing is exactly what Kai has
objected to twice today. **The shove was quietly manufacturing the problem the rescue exists to
solve.**

**450,000, between the two known points.** 180,000 was already a doubling of amendment 88's
figure and still did not read as a shove under a crowd; 900,000 reads and overshoots the arena.
The room is 21 metres by 11, so there is not much space between a shove you can see and a robot
in the next postcode.

**Kai has to type it into the placed ShotgunKnockback device**, or the 900,000 goes on winning.

## 107. The arena was never 1050 by 550. That was the crate-drop rectangle. 2026-08-28

**Kai: "i cant run against the walls now, i get teleported".** The containment guard of
2026-08-28 was fetching them back from places they were entitled to stand.

**THE FIGURE EVERYTHING USED WAS THE WRONG ONE.** `SimulatedAudience` carries an
ArenaHalfLength and ArenaHalfWidth of 1050 by 550, and they describe the rectangle a CRATE is
dropped into, deliberately kept off the walls so a crate is never awkward to reach. Five other
files copied those two numbers as if they were the room: TwinStickController, WaveManager,
DeathSaveManager, the cash manager, StuckHostileProbe and AdversarialTester, each with a
comment telling the next reader they MUST match the audience's. They must not.

**THE ROOM WAS MEASURED RATHER THAN GUESSED.** The containment guard already logs exactly
where the contestant was each time it fires, so Kai ran into all four walls and the log
answered: past X 1184 to the east, past X -1223 to the west, and past Y 700 both north and
south. **1220 by 720 from centre**, now set in all six.

**IT WAS NOT ONLY THE TELEPORT.** The same wrong rectangle was quietly breaking three other
things built the same day. Cash could not be collected in the outer three metres of the real
room, because amendment 95's guard thought the contestant was outside the walls. Amendment
100's rescue considered a robot standing legitimately in that band to be outside and teleported
it. And the med kit was being placed into a box smaller than the room. All three were correct
code given a wrong number.

**THE COMMENTS NOW SAY THE OPPOSITE**, in all six files and in SimulatedAudience itself: the
drop rectangle is deliberately smaller than the room, and these two must NOT be made to match
it again.

### 100b. The rescue tries every spot along the wall, at floor height

**Five robots were left stranded on 2026-08-28** with "would NOT move" in the log, two of them
seventeen metres west of the room. A teleport is refused when something is already standing
where the robot would land, and the inside of a wall in a busy room is exactly where a crowd
gathers.

**IT NOW WALKS ALONG THE WALL until a spot takes**, nearest first and alternating sides, so the
robot still arrives as close as possible to where it was stuck.

**AND IT LANDS AT FLOOR HEIGHT, NEVER THE HEIGHT IT WAS STRANDED AT.** A robot thrown over a
wall can come to rest on top of something out there, and reusing that height would drop it into
the room out of the air. **Kai's constraint on this whole fix, in their words: "as long as it
doesnt look like they spawn in the middle of the arena or dropping from the sky".** Every
candidate spot is on the wall the robot came through and every one is on the floor.

**THIS PROBABLY FEEDS THE SPAWN STALL TOO.** The same log has the wave loop reporting robots it
asked for that never arrived, once eight at a time. Stranded robots pile up around the spawner,
and a blocked door is exactly what that warning looks like from the inside.

### 88a. The fan shoves before it damages

**Kai, 2026-08-28: "i dont see the enemies knocking back, theyre just dying off the rip".** The
log shows the fan working exactly as amendment 88 asks, catching up to seven robots a blast,
and hitting each one for around 400. Almost nothing survives that, and a robot that has stopped
existing cannot be pushed.

**So the shove is applied before the damage now.** It does not guarantee a visible fling on a
robot that dies anyway, but the impulse lands on a body that is still standing when it arrives.

**AMENDMENT 88'S HALF A BLAST IS UNTOUCHED.** Making the knockback genuinely visible on the
robots at the edge of the fan would mean them surviving it, which means cutting the fan's
damage, which reverses a ruling Kai made on 2026-08-27. That is Kai's call and has not been
made.

## 108. The fan deals a quarter blast, so the shove can be seen. KAILEE'S RULING, 2026-08-28

**This revises amendment 88's half a blast rather than misreading it.** Kai ruled that on
2026-08-27, before anyone had watched it. `FanDamageShare` 4.0 to 2.0.

**THE REASON IS THE KNOCKBACK, not the damage.** The log measured the fan hitting each caught
robot for around 400. Almost nothing survived, so nothing was ever thrown, and Kai's report was
"i dont see the enemies knocking back, theyre just dying off the rip". A shove only reads on
something still standing.

**WHAT IT TRADES, and Kai took it knowingly.** The shotgun kills fewer things per blast and
becomes a crowd-shover rather than a crowd-clearer. One pellet was offered as well, which would
have made the shove the whole weapon; a quarter blast is the middle.

**The robot actually shot is untouched**, as it always has been: its damage is Fortnite's own
weapon and no Verse number reaches it.

**No UEFN step. The placed device carries no override for this one**, checked in the map file.

## 109. Robots wedged INSIDE the room get freed too, except Sentinels. KAILEE'S RULING, 2026-08-28

**The adversarial tester's first real run found it.** INV-02: a Swarmer at X -1067 Y 694, well
inside the walls, that had not moved for twelve looks. Amendment 100's rescue only ever touched
robots stranded outside, so nothing would have freed it, and a wave ends only when everything
in it is dead.

**NEVER A SENTINEL, and that exception is the whole reason this was refused the first time.** A
Ranged Sentinel is supposed to stand still and shoot; hauling one across the arena mid-fight
reads as the game cheating. The probe already knows which type each robot is, so the exception
costs one comparison. Kai was offered the blunt version, any robot that stops, and turned it
down again.

**AND NEVER ONE THAT IS SIMPLY FIGHTING YOU.** A robot standing on the contestant has not
wedged itself, it has cornered them, so anything inside the five metre safe gap is left where
it is. That also disposes of the tester's other complaint, INV-08, which flags any robot within
three metres of the contestant as a safety-radius breach: GDD 5.5's radius governs where robots
SPAWN, not where they walk, so the tester is too strict rather than the game being wrong.

**A NUDGE, NOT A JOURNEY.** It moves the robot three metres towards the middle, then six, then
ten if those are refused, at floor height. Kai's standing constraint holds: nothing appears in
the middle of the arena and nothing drops out of the sky.

**THE TESTER'S THIRD COMPLAINT IS ALSO NOISE.** INV-01 flags Swarmers as out of bounds while
they walk in from the west spawner, which sits outside the wall by design and cannot be moved
without spoiling the arena. Both false positives are worth teaching the tester about on a
quieter day.

## 110. The adversarial tester was reporting the game working correctly as faults. 2026-08-29

**Its first real run produced thirty lines and one of them mattered.** The rest were the device
being wrong about the game rather than the game being wrong.

**INV-08 WAS READING THE POSITION BEFORE THE FIX HAD RUN.** It subscribes to the spawner's
SpawnedEvent and measured the distance immediately. WaveManager subscribes to the SAME event
and moves a hostile that arrives too close, and the digest gives no order in which two
subscribers run. The game's own log has it moving the very hostiles the device complained
about, out to 450cm, in the same instant. It now waits a quarter of a second and then measures.
GDD 5.5 asks that a hostile not BE inside the radius, and one moved out within a frame never
was as far as the contestant is concerned.

**INV-01 WAS REPORTING EVERY SWARMER WALKING IN.** The Swarmer spawner sits outside the west
wall at about X -1500, a placement Kai will not change because moving it spoils how the arena
looks, so every Swarmer is legitimately outside for the first seconds of its life. A robot now
has to have been outside for twenty looks, ten seconds, before it counts. That is a genuine
failure to get into the room, which is what the invariant is for.

**BOTH ARE THE SAME LESSON.** An invariant that fires on the correct behaviour of the game is
worse than no invariant, because it buries the one line that mattered. The run that found this
had a real fault in it, amendment 109's wedged Swarmer, sitting under six false alarms.

**NOTHING WAS LOOSENED THAT SHOULD NOT HAVE BEEN.** A hostile that is still inside the radius a
quarter second later is still reported, and a robot that never gets into the room is still
reported.

## 111. GDD 5.5's safety radius only looked as if it worked. 2026-08-29

**The adversarial tester's second run found it, which is the first thing that run was good
for.** With the two false alarms of amendment 110 silenced, INV-01 went quiet and INV-08 kept
firing: five hostiles still 80cm to 152cm from the contestant a quarter of a second after
spawning, inside GDD 5.5's three metre radius.

**THE FAULT IS A CLAMP FIGHTING A PUSH.** `HoldTheSafetyRadius` moved the robot along the line
away from the contestant and then held that point inside the arena. The tester had parked the
contestant AT the west wall, where away from them is out of the room, so the hold pulled the
robot straight back to the wall and put it beside them again. The same shape of bug as the med
kit landing on a cornered contestant, amendment 95, and the rescue landing at Kai's elbow,
amendment 100a. Three times now: **holding a pushed point inside a box is not the same as
moving something away.**

**THE LOG LINE HID IT FOR TWO DAYS, and that is worth as much as the fix.** It printed
`SafeSpawnDistance`, the distance it had ASKED for, rather than the distance it achieved. Six
lines a run said "moved out to 450cm" while the robot was standing at 80. **A message that
reports an intention rather than a result is a message that cannot be trusted**, and this file
now prints the real gap.

**EIGHT DIRECTIONS AND THE BEST ONE WINS.** Every compass point is tried, each held inside the
room, and the robot goes to whichever ends up furthest from the contestant. Against a wall that
is along it or into the room; in the open it comes out much the same as the old straight-out
push. If even the best spot is inside the radius, the contestant is cornered somewhere the
radius cannot fit and the log says exactly that instead of claiming success.

### 111a. The other log lines that reported intentions

**Amendment 111's fix was a lie in a log line, so the rest were read for the same habit.** Two
more were found.

**THE CRATE'S HEAL SAID WHAT IT ASKED FOR.** `SetHealth` clamps at the maximum, so a contestant
on 290 of 300 who is "healed 75" has really been healed 10, and the line printed 75 either way.
It now prints the health before, the health after, and the difference. The Death Save's own
heal line is measured the same way.

**THE SHOTGUN'S SHOVE READ AS A DISTANCE.** "Shotgun shove -- 900000 away from the contestant"
invites anyone reading the log to take that for centimetres. It is an impulse, divided by the
robot's mass before it moves anything, and how far a robot actually travels depends on what it
hits. Now: "impulse 450000 applied, directed away from the contestant."

**THE REST CAME OUT CLEAN.** Every other teleport line already sits inside the `if` that tests
whether the teleport succeeded, which is the pattern that makes a message trustworthy in the
first place.

## 112. A robot pacing outside is as stuck as one standing still. KAILEE'S RULING, 2026-08-29

**The tester's third run found the last gap in the rescue.** One Swarmer walked around outside
the south wall for more than ten seconds, never standing still long enough to be called stuck,
so nothing ever fetched it in. A wave ends only when everything in it is dead.

**ALL FOUR SPAWNERS ARE OUTSIDE THE ROOM, and that is the root of everything this rescue keeps
patching.** The tester measured them: the Swarmer's past the west wall, the Boar's past the
east, the Sentinel's past the north, the Tank's past the south. It had been treated as a
peculiarity of the west one.

**KAI RULED THEY ALL STAY.** Offered moving all four inside, or the three not previously ruled
on, Kai kept them where they are for the same reason as before: moving them spoils how the
arena looks. So the robots get moved instead, and the rescue has to be good enough to carry
that decision.

**BEING OUTSIDE IS NOW ITSELF THE TEST, after ten seconds.** The grace is what separates a robot
walking in, which is every robot in this game for its first seconds, from one that is never
getting in. Standing still outside is still caught faster, at six seconds, by the original rule.

**NOTHING ELSE LOOSENED.** A robot inside the room is untouched by this, Sentinels are untouched
by all of it, and every landing is still on the wall it came through at floor height.

## 113. Nothing falls out of the contestant any more. KAILEE'S RULING, 2026-08-29

Kai: "when i die and all my stuff fals down when i hit play again those things through be
gone."

**A SWEEP IS NOT POSSIBLE AND THAT IS THE WHOLE FINDING.** The guns Fortnite throws on the
floor when a player is eliminated are engine pickups. Verse cannot see them, list them or
delete them: `item_remover_device` reaches into an agent's inventory and nothing in the
digest reaches a pickup lying in the world. Offered a faked fall instead -- our own physics
props thrown out of the contestant, gone in five seconds like every other drop -- Kai asked
the better question, "why do i need that if its all suppose dot dissaper when i hit play
again", and the answer was that they do not.

**SO NOTHING DROPS.** Class Designer, Player > Inventory, **Eliminated Player's Items: Drop
-> Keep.** One switch, no code. The other three settings beside it are untouched.

**IT DOES NOT TOUCH ANYTHING THE GAME HANDS OUT.** Kai's own check, and worth writing down:
crates, the Death Save turkey leg, the med kit and the shield potion are spawned by their
own devices and none of them read that setting.

## 114. The med kit must never sit in the bag. KAILEE'S RULING, 2026-08-29

**WHAT THE CRATE SHOWS AND WHAT IT HANDS OVER ARE TWO DIFFERENT THINGS**, and amendment 97a
blurred them. Kai on the shield: "i dont like it, i like the drop we had before." Asked
which way round, Kai ruled **the med kit keeps its Item Spawner and the shield goes back to
a prop** -- `AegisSpawner` cleared to None, `RewardProps` entry 1 filled. The first entry is
now dead weight and holds a placeholder, because a list needs an index 0 for an index 1.

**THEN THE HARDER HALF.** Kai: "i dont want the med kit to ever be in my inventory." The
crate heals in code and disables the spawner in the same instant, but the item already lying
there can be grabbed in that split second, **and the Death Save's turkey leg has exactly the
same hole** -- it detects arrival by proximity, not by pickup, and disables its spawner the
same way.

**AN ITEM REMOVER ON BOTH.** `MedKitRemover` on CrateManager and on DeathSaveManager, both
pointed at one placed Item Remover with Affected Items set to the med kit alone. Each
subscribes to its own spawner's `ItemPickedUpEvent` and takes the item straight back out.

**IT IS A SAFETY NET, NOT AN INVISIBLE ONE, AND THE CLAIM THAT IT WOULD BE WAS WRONG.** The
item enters the bag and is then removed, so a flash of the slot and a pickup message are
likely. Kai was told "too fast to see", asked "is this true", and the honest answer was no.
The trade was taken knowingly: playtest it, and if the flash is ugly the med kit becomes a
prop like the shield.

## 115. LEAVE THE SHOW made START SHOW dead for the rest of the session. 2026-08-29

Kai: "when i press leave the show and try to press the buton to start the game again it
doesnt start." The log said nothing at all, which was the clue: `OnStartPressed` logs from
inside `ReleaseTheMatch`, so the press was falling out before it got there.

**`StandingBy` IS A ONE-SHOT CATCH THAT NOTHING PUT BACK.** It stops START SHOW being
double-pressed, and the only two places that clear it belong to the idle PLEASE STAND BY
card, not to the press that starts a match. So the first START SHOW of a session set it and
it stayed set for ever.

**IT WAS UNREACHABLE UNTIL AMENDMENT 86.** Before LEAVE THE SHOW existed there was no way
back to the broadcast, so the button was never pressed twice in one session and the catch
never mattered. It is cleared now at the moment the television comes back on, beside
`ScreenIsUp`, which is the one place that knows the broadcast is live again.

## 116. Hit feedback: one of the three exists. KAILEE'S RULING, 2026-08-29

BUILD_ORDER item 31 asked for screen shake, a few frames of freeze on impact, and hostiles
flashing white when hit. It was parked until the crate loop ran. **The build allows one of
the three, and Kai ruled to take that one and leave the rest.**

- **No screen shake.** `gameplay_camera_device` exposes Enable, Disable and adding or
  removing itself from an agent's camera stack. Nothing moves it. Jolting a camera device
  about was the only route and Kai turned it down.
- **No freeze.** There is no time dilation in the digest. The only lever is how fast robots
  walk, which the Death Save already uses for its slow motion, and borrowing it for every
  bullet would blunt the one moment the game slows down on purpose.
- **No white flash.** A robot cannot be tinted. Amendment 49's finding stands: an NPC
  character definition has no colour setting, and Character Cosmetic picks an outfit.

**SO IT IS A SPARK BURST ON THE ROBOT**, the same device and the same trick as the death
sparks, fired on a hit rather than on a kill, and up at chest height rather than at the
feet so it reads as a bullet going in.

**A POOL, NOT ONE DEVICE.** A VFX creator can only be in one place, and a shotgun lands
pellets on several robots inside a tenth of a second; one device would be dragged across
the arena mid-burst. Each hit takes the next in the list. **It sits above the shotgun test
in `OnHostileDamaged` on purpose**, so it belongs to every gun, and it ignores hits of zero
damage, which are robots already on their way out.

**Left empty the list does nothing**, which is the behaviour before today rather than a
fault.

## OPEN, UNRESOLVED: every run banks a score of zero

Two runs on 2026-08-29 banked score 0 and tier 1 into the career record while the arena had
4440 and Tier 3. **The map wiring was checked byte by byte and is correct**: Career Rank
Manager and Game Over Screen both point at the placed cash and wave managers, and Kai
confirmed the slots are filled. A probe then showed **the Game Over Screen's own reading is
also 0 score, 0 rooms, tier 1**, which are the untouched class defaults of all three
getters, so this is not one bad slot. A stamp probe is in `hello_world_device.verse` to
prove whether the device slots resolve to the placed manager or to a stand-in. **Career
Sponsor Rank is uncuttable (GDD 5.7) and is currently recording nothing.**

## 117. The balance pass. KAILEE'S RULINGS, 2026-08-29

Four complaints in one message, each measured against the log before anything moved.

**CRATES CAME TOO FAST, AND IT WAS THE THRESHOLDS, NOT THE TIMER.** A three-minute run
ordered fourteen crates: seven on the 25-second trickle and seven on threshold crossings.
The bar was sitting just under a line, wobbling over it and dropping back, and Prime Time
was crossed four separate times in that one run. A crossing now pays once and re-arms only
once the bar has fallen `ReArmMarginHype` clear of the line. **Kai asked how we knew the
threshold-only figure of "three or four crates a run" from amendment 13, and the honest
answer was that we did not: it was a prediction, and the log disproves it.**

**THE THRESHOLDS WERE TOO EASY, SO THE CLIMB WAS SLOWED INSTEAD OF THE LINES MOVED.** Prime
Time already sits at 95 of 100, so there is nowhere for the top line to go. The same run
logged 79 cash pickups and 29 close shaves, which between them were nearly the whole bar,
so both are halved: `HypePerTravelledPickup` 1.0 -> 0.5 and `HypePerShave` 3.0 -> 2.0.

**THE CASH MAGNET REACHED PAST THE WALLS.** BUILD_ORDER item 32 parked this number until
the arena existed, because "6 metres means nothing without knowing how big the room is".
The room was measured on 2026-08-28 and is 24.4m by 14.4m, so the 8 metre reach swept the
whole width from anywhere near the middle. `MagnetRadius` 800 -> 350.

**THE SHOTGUN CLEARED CROWDS INSTEAD OF SCATTERING THEM.** Kai: "the whole group around me
dies in one blast." The fan's reach is untouched on purpose -- 80 degrees either side at 8
metres is what makes the shove read as a shove -- but the same arc was lethal.
`FanDamageShare` 2.0 -> 0.5, revising amendment 88a's quarter blast.

## 118. Room one stops being a baby round, and the GDD was asked first. KAILEE'S RULING, 2026-08-29

Kai: "room 1 feels like a baby round." It was, by arithmetic. The ramp thins a room by the
share of hostile types that have joined, only the Swarmer has joined in room 1, and its
share is 5 of 10, so `ConcurrentAtTier1` was halved and room one ran six on screen against
room two's nine.

**THE CONFLICT WAS PUT TO KAI RATHER THAN DECIDED.** GDD 2.4 makes room-loop 1 a teaching
room: movement, aiming, the pistol and weak Swarmers, with Hype and crates switched off.
But it says that only "on the player's first life", and that first-life version has never
been built, so every run gets the same room one. Told this plainly, Kai's answer was "well
room 1 feels too easy". **The first-life teaching room stays on the list as its own job.**

`RampFloor` 0.7 is room two's own fraction, chosen so nothing else moves: rooms 2, 3 and 4
already sit at 0.7, 0.9 and 1.0. Only room one rises, from six on screen to eight. Robots
also arrive every 0.6s rather than 0.9s, Kai: "can the robots spawn faster".

## 119. Rescued robots come in through the doors. KAILEE'S RULING, 2026-08-29

Kai: "the robots that got stuck and get unstuck its doing it too slowly it needs to be
instantly and directly in front of the wall doors and not the audience wall." Asked which
wall: **"the west wall the doors is the middle."**

**THIS REPLACES AMENDMENT 100'S NEAREST WALL.** Every rescued robot now walks in through
the west doors wherever it got stuck, because the doors are the one place a robot appearing
reads as a robot arriving rather than a robot teleporting. The along-the-wall fallbacks of
amendment 100b all slide across the doorway now.

**INSTANT IS NOT AVAILABLE AND KAI WAS TOLD SO.** Every robot in this game starts outside
the room and walks in, so a zero grace would teleport each one the moment it appeared. The
outside rules are now two looks for pacing and one for standing still, against six and
three. **The inside nudge keeps the longer count on purpose**: a robot standing outside is
always wrong, while a robot standing inside may simply be fighting.

## 120. The leash was anchoring the robots outside the arena. 2026-08-29

Kai: "the enemies dont seem to recognise or start running at me until i start shooting or
moving, it should instantly charge at me."

**NO VERSE ROUTE EXISTS FOR THIS BUILD.** `ForceAttackTarget`, which "forces guards to
attack Target, bypassing perception checks", is on `guard_spawner_device` and this game is
built on `npc_spawner_device`. Reading the Swarmer's card instead found the real cause.

**ENABLE LEASH WAS TICKED, AT 30 METRES.** A leash ties a guard to the spot it spawned at,
and amendment 112 established that all four spawners sit outside the arena walls, so every
robot was anchored to a post out in the void and only half-committed to the room. **It is
very likely the root of the stuck-outside problem that amendments 100, 100a, 100b, 109 and
112 have all been patching.**

Unticked on all four cards. **The Sentinel was flagged as the risk** -- it is meant to
stand its ground and shoot, and unleashing it may send it charging like the rest -- and Kai
unticked it anyway, so that is the thing to watch on the next run.

## 121. The Tank is made frightening rather than tall. KAILEE'S RULING, 2026-08-29

Kai: "how do i make the character look bigger like a giant?"

**IT CANNOT BE DONE, AND THAT WAS ANSWERED BEFORE.** A Fortnite character has no scale.
The character modifier list has twelve entries and scale is not among them, scale exists
only for `creative_prop`, and where a scale box does appear in UEFN it is Epic bug
FORT-1143931: bigger in the editor, 1.0 in the game. Outfits are all built to one height,
so no costume makes a giant either. Kai then asked which outfit was biggest, and the honest
answer was that none of them would do it.

**SO HE GETS WEIGHT AND AN ENTRANCE INSTEAD.** Kai: "can we make him look slow mo or scary,
how can i make him scary?"

- **Weight is acceleration, not speed.** The Tank's acceleration was 20.5, exactly the same
  as the little Swarmer's, so it started and stopped as sharply as they do. Now 6.0 and
  4.0, with walk, run and sprint down to 1.5, 2.0 and 2.2. Fortnite plays the walk
  animation at the speed the character actually moves, so the slow-motion look Kai asked
  for comes free with the lower speed.
- **The entrance is `TankEntrance.verse`**, a new device that only listens. A low sound
  plays the moment a Tank walks in, and a red glow follows him until he dies, so he can be
  picked out of a crowd and heard before he is seen.

**A POOL OF GLOWS, ONE PER LIVE TANK**, for the same reason the hit sparks need one: a VFX
creator can only be in one place, and a device shared between two Tanks reads as a smear.
Run out and the Tank arrives plain, which is the behaviour before the file.

**ITS OWN DEVICE RATHER THAN MORE OF WaveManager.** It never spawns, counts or ends
anything. Both files subscribe to the same SpawnedEvent and the digest gives no order
between two subscribers, which does not matter because this one touches nothing WaveManager
reads or writes.

## 122. The announcer speaks on screen, and the crowd asks for the crate. KAILEE'S RULINGS, 2026-08-29

**HE WAS SILENT FOR TWO REASONS AND NEITHER WAS THE CODE.** Kai: "where is the announcers
voice!!! the announcer is supposed to be saying things are happening like the crate falling
the tank coming all that stuff." His two devices, `announcer_manager` and `bark_database`,
had never been placed in the map at all. And even placed, all ten voice fields need
recorded clips, which do not exist: Kai's lines are written, nobody has said them aloud.

**SO HE SPEAKS IN TEXT UNTIL HE SPEAKS ALOUD.** Kai chose a banner of his own across the
bottom rather than a line in the stream chat, "because next to it i want to have the
announcers face". The face does not exist yet, so its square is drawn and held empty rather
than added the day the picture arrives. The text comes from `GetBark`, which had to be made
public; the words are untouched, per CLAUDE.md standing rule 3.

**THE CRATE IS NOW ASKED FOR BEFORE IT ARRIVES.** Kai: "the crate should be granted upon
audience request and it should say it in the stream chat", and "there needs to be a line for
the chat to say when they want to get a crate like CRATE! CRATE! CRATE! and it needs to be
noticeable and repetitive so the player can notice it." So the trickle now signals
`CrateDemandEvent`, four handles chant it in the box, the host says his own line over the
top, and the crate is ordered `ChantSeconds` later. **Only the trickle chants**: a crate
earned by climbing a Hype threshold is the contestant's doing, and having the crowd demand
something already on its way reads as them taking the credit.

**AND THE TIMER IS NOT A TIMER ANY MORE.** Kai: "why does the crate fall every 45 seconds,
the audience should call for it so the times should vary." A fresh wait is drawn between
`TrickleMinSeconds` and `TrickleMaxSeconds` before every crate. Averaging 45, which is the
figure Kai settled on; the spread is what stops it sounding scheduled.

**SEVENTY-FIVE CHAT LINES HAD NEVER APPEARED IN THE GAME**, found while listing every line
out for Kai to review. Five whole sets -- close-shave dodges, the Death Save, a crate
falling, a crate opening, a room won -- were written and nothing anywhere posted them.
Crate falling is wired now. **The other four are still dead and are worth a look.**

**FIVE NEW MOMENTS, AND THE BUDGET MOVED.** Kai asked for lines when the audience orders a
crate, when a prop lands, and when the first Tank, Boar and Sniper of a run walk in.
`CrateCalled` and `PrizeLanded` are wired; the three arrivals are triggers waiting for one,
the same way DeadAir and SponsorRead once waited. Kai wrote the five CrateCalled lines the
same day. **Amendment 90's budget of 41 goes to 46**, and a slot count of 0 in settings.py
now means "waiting for Kai" rather than "cut".

**AND THE PRIZES WERE ARRIVING AT FRIDGE SIZE.** Kai: "the props in the crate are HUGE."
`PrizeScales` has never been filled in, so every prize fell back to 1.0. The fallback is now
`UnsetPrizeScale` at 0.5, matching the crate's own reward props. It is a fallback, not an
answer: a fridge and a roll of toilet paper cannot share one number.

## 123. The stadium gets a crowd in it. KAILEE'S RULING, 2026-08-29

Kai: "should we be able to hear the audience cheering?" The whole game is built around a
simulated televised audience -- it fills the Hype meter, chants for crates, types in a chat
box -- and it had never made a sound. A silent stadium reads as an empty room with a
scoreboard.

**VOLUME CANNOT BE CHANGED FROM VERSE, so the swell is built out of separate loops.** The
obvious version is one crowd track whose volume rides the Hype bar, and the digest does not
allow it: `audio_player_device` offers Play, Stop, Enable, Disable, Register and Unregister
and nothing else. So there is one loop per Hype tier, recorded at its own intensity, and
the tier change swaps which is running. **A hard swap rather than a crossfade**, which is
the cost of the workaround and lands better than it reads, because amendment 117 already
stopped the tier flipping on a wobble.

**IT BORROWS THE AUDIENCE'S OWN THRESHOLDS** rather than inventing a second set, reading the
same three getters off the Hype meter. That is what keeps the crowd you HEAR and the crate
quality you SEE agreeing with each other.

**THE MURMUR NEVER STOPS.** Asked whether the crowd should carry on between runs, Kai: "yeah
the murmur and the song should play". So the quietest bed starts as the island loads, plays
under the title card, and the run ending drops the room back to it rather than to silence.

**MUSIC NEEDS NO CODE AND DELIBERATELY HAS NONE.** GDD 5.4's one retro synth-wave track is a
looping Audio Player set to start with the game, sitting under everything this file does.

**A REBUILD I SHOULD NOT HAVE STARTED.** Kai asked "do i need to put in a sound for the
audience?", which is a question, and a chant sting was built in answer to it. Kai: "why did
you add a sound slot for it, thats not what i asked." It was taken out again and this was
built instead. Worth keeping in the file: a question is not an instruction.

## 124. The idle decay overrules GDD 3.1. KAILEE'S RULING, 2026-09-05

**What the GDD says.** Section 3.1: the Hype meter "decays by 5% every 10 seconds of
inactivity". On a 0-to-100 meter that is 5 points, and `IdleDrainPoints` at 2.5 every five
seconds was exactly that, set up deliberately on 2026-08-29 to hold the rate when
`DrainEverySeconds` was halved.

**Why it had to change.** `AlwaysDrainPoints` is also 2.5, so idling drained at precisely
the same speed as fighting. Doing nothing therefore felt like nothing. Kai, after the 23:49
run: *"i ran around for a bit but i didnt see the meter go down that much until AFTER i got
hit."* The log agreed to the second: 78.5 down to 69 across twenty-two idle seconds, one
point every two seconds, against eight hits that took 34 points in nine.

**The ruling.** `IdleDrainPoints` 2.5 -> 5.0, which is 10% every ten seconds, double what
3.1 says and double the constant leak. Kai was told plainly that this overrules the
document and answered *"yes overrule it"*. Kai also asked for it "but not too much", which
is why it is doubled rather than the four times it would need to be genuinely punishing.

**`IdleAfterSeconds` 10 -> 8 in the same pass**, and that breaks no rule: 3.1 never says how
long counts as inactive. The number comes from a measurement rather than a feel. On the
23:11 run the quiet gaps between rooms, where the arena is empty and the next wave is
still arriving, were 7.5 and 12.5 seconds. 8 leaves the short gap free and charges only for
the long one. Kai asked about exactly this before agreeing: *"what happens between rounds
cause theres a second of the enemies to get their bearings?"*

**What is NOT changed.** The constant leak stays at 2.5 and the earners stay where they
are. Raising the constant leak was the obvious route and was rejected, because it also
slows the climb during a fight, which is the see-saw the whole evening had been stuck on.

## 125. The Hype Call is a big burst on a long cooldown, overruling GDD 3.1's ten seconds. KAILEE'S RULING, 2026-09-05

**What the GDD says.** Section 3.1: *"Pressing and holding the Hype Call key for 1 second
triggers a manual Hype Call (10-second cooldown), granting an instant burst of Hype."* The
hold and the cooldown are stated; **the size of the burst is not, anywhere.**

**The first proposal, and why Kai rejected it.** 5 points on the document's own 10 second
cooldown. Six presses a minute is 30 points, and the meter bleeds 30 points a minute, so
spamming the key would have held the bar exactly level for ever and never climbed it. It
was designed that way on purpose, so that pressing one key could not beat playing well.
Kai: *"why not big boost and long cool down."*

**The ruling.** **25 points, a quarter of the bar, once every 45 seconds.** That is 33 a
minute, so it still cannot sustain the meter on its own, but spending it is a moment rather
than a habit: you hold it for when you are sitting just under a threshold and a crate is
due. Kai was told plainly that 45 overrules 3.1's ten and chose it anyway.

**Why 45 and not longer.** Kai asked directly whether 45 was too short. Measured rather than
felt: rooms are running 35 to 60 seconds each and whole runs 1 to 2 and a half minutes, so
45 is about one use a room and two or three a run. At 90 you would get one use per run and
never learn to use it. **If runs get longer, this number should go out with them.**

**The one-second hold is honoured exactly and costs no code.** An `input_trigger_device`'s
`ReleasedEvent` hands back how long the input was held, so 3.1's one second is a comparison
rather than a timer of ours.

**On screen it is a line under the meter title**, reading HYPE CALL READY or counting down.
It is deliberately part of the Hype meter rather than a fourth element, because GDD 5.4's
three-widget HUD budget has no room for another.

**Still not built and unlocked by this:** GDD 3.4's Hype Call rescue teleport, `BUILD_ORDER`
item 13, which was waiting on this and on the tier bands.

### 125a. And the one-second hold goes too. KAILEE'S RULING, 2026-09-05

Kai: *"can i just press, why do i have to hold it?"* `HypeCallHoldSeconds` 1.0 -> 0.0,
which turns the check off entirely. This overrules the other half of the same sentence in
GDD 3.1 that amendment 125 already overruled the cooldown in.

**It cost three playtests before it was noticed.** Across two runs the key was pressed
seventeen times and the longest hold measured 0.72 seconds, so the Hype Call never once
fired and read to Kai as broken: *"its off and not working"*. The device was wired
correctly the whole time and said so in the log every press.

**What the hold was buying, and it is not nothing.** It stopped a 45 second cooldown being
burnt by a fat finger mid-fight. Kai was told that and accepted the trade. Holding a key
steady for a second while being swarmed is not something this game leaves room for.

**The branch is still there and reads the number**, so putting the hold back is a value in
UEFN rather than a rebuild.

## 126. The leak gets heavier the fuller the bar is, and the crowd throws an opening crate. KAILEE'S RULINGS, 2026-09-07

**Both come out of one playtest report and one log.** Kai's list of 2026-09-06 held six
items. Three of them were the same fault: *"the hype does not go down fast enough"*, being
*"stuck on the hype bar for a while"*, and *"no Underdog crate arrives"*.

### What the log said

The 09:15 run of 2026-09-06 lasted 3 minutes 50. The bar reached full at 2 minutes 47 and
then never came down: across the last minute it sat between 90 and 100 and did not once
fall below 90. It crossed Rising Star at 40 seconds, Superstar at 2 minutes 12 and Prime
Time at 2 minutes 47.

**Cash is why it pinned.** 233 travelled pickups in 230 seconds at 0.75 apiece is 175
points, 45 a minute, against a constant leak of 30 a minute. Hoovering the floor
out-earned the entire drain on its own, so 51 points of close shaves, 35 of clusters and
50 of Hype Calls were all profit on top and the ceiling absorbed the rest. Total earned
311 into a bar that stops at 100.

### The first ruling: a top-heavy leak

`TopHeavyDrainPoints`, a new dial, defaults to 6.0. It is zero at `SuperstarAt` and 6 at a
full bar, sliding evenly between, and it is added to whichever of the two existing leaks is
running that tick. At a full bar the constant leak becomes 8.5 every five seconds, 102
points a minute, just above the roughly 100 a minute a contestant can earn playing
perfectly. The best tier stays reachable and cannot be parked in.

**This overrules GDD 3.1 a second time at the top end.** 3.1 gives one decay figure, 5%
every ten seconds of inactivity; amendment 124 already doubled that to 10% on Kai's ruling,
and above the Superstar line this adds more again. Kai was told plainly that it does and
answered *"yes"*.

**The climb is deliberately untouched, and that is what separates this from the four
earlier passes at the same complaint.** Every one of those moved an earner or the flat
leak and so changed how fast the bar filled. Kai's own pace target, *"i should have the
rockets by the tank"*, was met on that run with Prime Time landing around room 4 at about
three minutes. Asked directly whether the climb was too fast for the genre, the answer
given was no: reaching the best state quickly is normal for a twin-stick of this lineage,
and what keeps it interesting is being unable to hold it. Nothing below `SuperstarAt` moves
by a point.

### The second ruling: the crowd throws an opening crate

`FirstTrickleSeconds`, a new dial, defaults to 15.0. Only the first wait of a run uses it;
every wait after it is still drawn between `TrickleMinSeconds` and `TrickleMaxSeconds`, so
the crowd still does not keep time.

**The Underdog crate had no window to arrive in.** A climb INTO a tier orders a crate, but
a run begins in Underdog and therefore never climbs into it, which leaves the trickle as
the bottom tier's only possible source. The trickle's first wait was 30 to 60 seconds and
the bar left Underdog at 40, so the crate that is supposed to open the show usually never
existed. The best crate in the game had been seen many times; the worst one had not.

**Slowing the climb was the other route and it was rejected.** Holding Underdog past a wait
that can run to 60 seconds would have meant dragging every tier above it back too, to fix a
bottom tier by spoiling the pace of the whole meter. Kai approved the switch: *"do that"*.

### What is NOT changed

Every earner, `AlwaysDrainPoints`, `IdleDrainPoints`, `HypeLostPerHit`, and all three tier
lines. Set `TopHeavyDrainPoints` to 0 and the meter behaves exactly as it did before, and
`FirstTrickleSeconds` to 45 and the crowd does too.

## 127. Once the Death Save is spent, only an empty health bar ends the run. KAILEE'S RULING, 2026-09-07

**What Kai saw.** The 15:11 run of 2026-09-07 ended while there was still health showing on
the bar. Kai: *"but i saw my health it wasnt 0??"*, and then *"i dont like that it feels
unfair"*.

**Why it did that, and it was working as built.** The save has to be caught before the blow
that kills, because a blow bigger than the remaining health eliminates the contestant
before any Verse code runs at all. `TriggerHealth` is 25 for exactly that reason. The same
25 was also what ended the run once the save was spent, so a contestant who had used their
rescue died a quarter of a health bar early, every time.

**The run itself.** The save opened at 15:12:13 and the rescue worked, back on 76 health.
Fifty-two seconds later, at 15:13:07, health crossed 25 again with 109 points on the bar a
breath earlier, and the run ended in the same millisecond with no window and no warning.

### The ruling

`TriggerHealth` is now the save's own business and nothing else's. While the save is in
hand it behaves exactly as before: the damage handler catches the contestant at 25, holds
them up at `WindowHoldHealth`, and the window opens. Once `SaveSpent` is true, neither the
handler nor the poll does anything at all. The last 25 points are the contestant's to
spend, and the run ends when Fortnite eliminates them, through the outright-kill path that
already existed for the freak case.

**Kai was offered the GDD's own narrower rule instead and turned it down.** GDD 3.4's
second line only ends the run instantly on a second fatal blow taken "before the player's
health regenerates above 25%", which on that run would have handed back a fresh save and a
second turkey leg. Kai's answer: *"no one death save per run and then after if i get to 0
then i die and the game ends."* Amendment 127 therefore leaves the 2026-08-16 once-per-run
ruling standing and changes only where the ending happens.

**Kai was told what comes with it and accepted it.** With the save gone nothing is propping
the contestant up, so a hard hit can take them from a sliver of health straight to
eliminated. That is the trade for not dying with health still on the bar.

### It does not break the anti-chain rule

3.4 says a second fatal blow ends the run instantly, and it still does: a blow that empties
the bar ends the run in the same moment, with no window. What has gone is treating "dropped
below 25" as though it were fatal, which was an implementation's convenience and never the
document's words.

### What is NOT changed

`TriggerHealth` itself, `WindowHoldHealth`, the 3-second window, the health recharge, and
the once-per-run rule. `RunEndCalled` is gone, because the branch that needed it is gone.

## 128. A crate takes pity on a contestant who is nearly dead. KAILEE'S RULING, 2026-09-07

Kai, mid-playtest: *"why desont the crate giv eme a health pask when i need it ???"*

**The crate rolled blind and always had.** `TierHealChance` is the whole of the decision,
a third for Underdog, Rising Star and Superstar and fifteen in a hundred for Prime Time,
and not one of those numbers has ever known how much health the contestant had. On a good
run that is fine. On a bad one the show hands a contestant on their last legs a shotgun
they will never live to fire.

**The 40% line is GDD 3.1's own.** The Underdog Boost already treats health below 40% as
the point where the show starts helping, so `HurtHealthPercent` uses that same line rather
than inventing a second idea of what being in trouble means. `HurtHealChance` is 0.75:
under the line, three crates in four hold a health pack.

**It replaces the tier's chance rather than adding to it, and only upwards.** A tier
already more generous keeps its own number. Below the line every tier heals at the same
rate, Prime Time included, because a contestant about to die does not care which parachute
it came under.

**Read when the crate is decided, which is when it is ordered.** So what counts is how the
contestant was doing when the crowd called for it, not when they finally reach it. A crate
ordered while healthy and collected while dying is still whatever it rolled, which is the
honest version: the crowd cannot see the future either.

**Set `HurtHealChance` to 0 and the crate goes back to rolling blind.**

### The stage lights, tuned in the same sitting

`FlashOnSeconds` 0.18 -> 0.26 and `FlashOffSeconds` 0.14 -> 0.20 on the WaveManager, tuned
on the placed device and mirrored back into the script. Kai, on the first run with the
lights actually wired: *"the lights flashed but it was a bit fast"*, then *"better"*. Three
flashes now run about 1.4 seconds against the 0.96 they did.

**The lights themselves were never wired until today**, which is the whole of why nothing
flashed on 2026-09-06. Eight Customizable Light devices are now in `RoomWonLights`, set to
green with Initial State off.

## 129. The rooms become a lap that repeats, and each lap is a tougher version of the same fight. KAILEE'S RULING, 2026-09-07

Kai, straight after a playtest: *"i finished round 5 or 4 whatever it is with the tank then
i had the next round with all the enemies all over again, it should be the swarmers again
against the swarms like the first round but harder than the first round!"*

**What it used to do.** GDD 2.4's onboarding ramp ran once per run. Room 1 was Swarmers,
room 2 added the Boar, room 3 the Sentinel, room 4 the Tank, and from room 4 onwards all
four types were in every room for the rest of the run. The log said so plainly: tiers 4 and
5 both read *types in play Swarmer, Boar, Sentinel, Tank*.

### The lap

`LapLength` is 4. The ramp now runs once per lap instead of once per run, so room 5 is
Swarmers only again, room 6 adds the Boar, room 7 the Sentinel, room 8 the Tank, and round
it goes for ever.

**Nothing underneath it changed.** The tier still climbs every room, so GDD 5.3's 8% a
room, the crowd size and the wave length all carry on exactly as before. A lap is harder
than the one before it because everything beneath the lap kept escalating through it.

### One more of each, every lap

Kai: *"round 2 only has 2 boars then the round where it loops again for the second time
should have 3 boars and so forth. the max tanks you should have at once is 4."*

`BoarsOnArrival`, `SentinelsOnArrival` and `TanksOnArrival` are now what lap 1 gets, and
each lap after adds one. Caps: `TanksMaxPerRoom` 4 as Kai asked, `BoarsMaxPerRoom` 8 and
`SentinelsMaxPerRoom` 6, both agreed after being shown that by lap ten an uncapped room
would want eleven Boars and ten Sentinels out of GDD 5.3's forty-bot ceiling.

**The Swarmer has no cap and must not be given one.** Kai: *"swarmers shouldnt have a cap i
think but idk what do u think"*, and the answer was to leave it uncapped: it is the only
unrationed type and it fills whatever the other three leave, which is what keeps a room
full at any lap.

**The rare ramp is gone.** `BoarsWhileRare`, `SentinelsWhileRare`, `TanksWhileRare`,
`BoarsEndAtTier` and `RareTypesEndAtTier` answered the same question on the old
once-per-run ramp. Nothing reads them now. Each is labelled in the script and left standing
rather than deleted, the same way the cut ammo modifiers were left as zeroed dials.

### One robot card per lap

Kai asked how the five character cards per type should fit in. Told it plainly as *"same
fight each lap, bigger robots"*, the answer was *"yeah thats what i want"*.

`TierDefinitionIndex` now returns the lap number minus one, held at the strongest card once
they run out. It used to divide the tier range into blocks of the largest size that fitted
every card inside `MaxTier`, which with five cards and `MaxTier` 21 gave blocks of four and
therefore exactly the same answer. That coincidence is why this is a tidying rather than a
change of feel: tying them together means retuning `LapLength` moves the cards with it
instead of letting the two drift into disagreeing.

**The plain-English attempt matters here.** The arithmetic version of this question got
*"i dont understand"*. What landed was: you made five versions of each robot, rooms 1 to 4
use the weakest, room 5 swaps everything to the second version, room 9 to the third.

### Where the old numbers still apply

`JoinTierFor` is still read in two places and both are correct: waking each spawner for the
first time in a run, once, on the room its type first appears in. Whether a type is in
THIS room is `TypeIsInPlay`'s job now.

## 130. The Career Rank is held across a sitting, because the account save comes back empty. KAILEE'S RULING, 2026-09-07

Kai, asked whether the save could be tested: *"hmm how do i test that career save"*. It can
be tested, in one sitting, by playing twice and seeing whether the second run remembers the
first. It does not.

### What the log showed

Four runs in one sitting on 2026-09-07 scored 1770, 3520, 11215 and 6950. Every one of them
wrote its own score down as the lifetime total, and every one of them was *"Promoted to
Undercard Filler"* from nothing, again. The run after the 11215 saved a best score of 6950,
which can only happen if the record it loaded was blank.

### The wiring is right, which is the awkward part

A correction to what Kai was told twice in this session. The first answer, taken from
`BUILD_ORDER.md`, was that the save is lost because the island is not published. The second
was that the store "is an ordinary one that empties, not the kind Epic actually saves".
**Both are wrong**, and the second was wrong on the code:

- `CareerRecords` is a module-scoped `var`, which UEFN requires.
- It is a `weak_map(player, career_record)`, which is the persistence mechanism; `player`
  itself carries `<persistent>` and `<module_scoped_var_weak_map_key>` in the Verse digest.
- `career_record` is declared `struct<concrete><computes><persistable>`.
- The engine's own save service logs the map being constructed every session, under
  `kailee-nekoba@fortnite.com/SponsorMeSlayers_v2.CareerRecords`. There is no
  `invaliddomain` anywhere in the log.
- Every `SaveRecord` reports success.

So the writes are accepted and the reads come back empty regardless. The cause is not known.
The likeliest remaining explanations are that the persistent map only commits where a
published island backs it, or that the restart of amendment 86 hands back a different
`player` and therefore a different key.

### The ruling

`LastKnownRecord` holds the last saved record for the lifetime of the session. `LoadRecord`
asks the account save first and falls back to it; `SaveRecord` sets it whatever the account
write does. The account save is untouched and still wins whenever it has anything, so the
day it starts working, nothing here has to be undone.

**It is a field on the device, not a module-scoped var, and Verse insists.** The first
attempt put it beside `CareerRecords` and got script error 3502, *"Module-scoped `var` must
have `weak_map` type"*, plus a second 3502 for each plain read and write: *"Module-scoped
`var` may only be partially read or written"*. Only the persistent map itself is allowed out
there. A field on the placed device lasts the session all the same, which is all this needs.

**It is a fix rather than a diagnosis, and deliberately so.** What the account save needs
may well be publishing the island, which is out of reach the day before the deadline. This
costs one variable and makes the rank climb across a sitting, which is the whole of what
GDD 2.6 is for and the only part of it anybody watching would see.

**Single player is what makes it safe.** Amendment 19 records the game as single-player, so
one held record cannot be handed to the wrong contestant.

**A load line was added** beside the existing save line, printing what was loaded at the
start of each run's banking. Two lines that agree across consecutive runs are the proof
this works; that is the test Kai asked for.

### Career Rank is uncuttable

GDD 5.7 names it as one of four features that ship no matter what. A rank that returns to
Debt-Ridden Rookie every time is the feature not shipping, however well the ladder itself
computes.

### 130a. And the prize vault has to come the same way. KAILEE'S RULING, 2026-09-07

Kai, immediately after 130: *"wb the leader board and prize does that persist"*.

**The leaderboard was already fine.** `TopScores` and `TopScoreRanks` are fields of the same
`career_record`, written through `SaveRecord`, so amendment 130's holder carries them with
the rank at no extra cost.

**The prizes were not.** `PrizeVault.verse` read and wrote `CareerRecords[P]` directly. That
was correct for as long as the account save was the only store, and stopped being correct
the moment 130 put a holder in front of it: a prize went into a map nothing reads any more,
and the next run loaded from the holder, which had never heard of it. Winning a toaster
would have been forgotten while the rank beside it was remembered.

**`LoadRecord` and `SaveRecord` are now public** and `PrizeVault` calls them through a new
`CareerRank` slot, which Kai drags the placed Career Rank device into. Every other field is
still carried through by hand in that write, for the reason recorded in both files: a
`career_record` is written back in full, so a field left off the list is written back empty.

**Leave the new slot empty and prizes are simply not kept**, which is a change from the old
behaviour of a loud warning. It is called out in the field's own comment as the first thing
to check if the prize board is empty after a run that collected something.

## 131. Three GDD rules that were quoted for weeks and never applied. 2026-09-07

Kai, working through the backlog: *"what else do i need to do and fix?"* These three were
on it, all of them things the GDD asks for in plain words and the build did not do.

### The Underdog Boost

GDD 3.1: *"If health drops below 40%, the Underdog Boost activates, granting +50% Hype
generation."* BUILD_ORDER item 10. The 2026-09-05 audit found it existed only in comments,
in `AnnouncerManager.verse` and `BarkDatabase.verse`, both of which already discuss the 40%
line. Quoted around the project for three weeks and never once applied.

`UnderdogBoostMultiplier` multiplies what is EARNED and nothing else. Every drain is left
alone, so being hurt does not also slow the bleed: 3.1 says generation and means generation.
The Hype Call's burst counts, since that is the contestant generating Hype on purpose.

**It suits the meter's own shape.** The bar is hardest to fill when a contestant is being
mobbed, which is exactly when they are under 40%, so it pays out at the moment the meter is
otherwise least reachable. The health line is read once a tick on the watch that already
reads health, and logged only on the way in and on the way out.

### The wall scoreboard

BUILD_ORDER item 25. `hello_world_device.verse` called `ScoreManager.Increment` on every
cash pickup. The digest is explicit that Increment *"increments the score quantity to be
awarded by the NEXT activation by 1"*. It awards nothing. So every pickup quietly raised the
price of an award that was never once made, and the device sat at zero all match beside a
HUD counter that was correct.

`SetScoreAward` then `Activate` now, so the wall and the readout agree to the pound rather
than the wall counting in ones. Room-clear windfalls reach it too, through the agent-less
`Activate`, or clearing a room would move one number and not the other.

`CashPerPickup` replaces a bare `10`, because two copies of a figure that must agree is the
drift CLAUDE.md warns about, and the score device had just become the second copy.

### The meter now says what it is set to

Three times in one evening, "did that change reach the game" could not be answered from the
log. A session keeps the numbers it started with, and a placed device can hold its own copy
of any `@editable`, so the only honest answer is the device saying out loud what it has.
`HypeMeterManager` prints every drain at match start.

## 132. The submachine gun bleeds, and the sniper's beam was on the wrong gun. 2026-09-07

### Two files disagreed about which slot is which gun

`CrateManager.verse` says three separate times, for the granters, the spawners and the ammo,
that the numbering is **0 SMG, 1 Shotgun, 2 Sniper, 3 Rocket**. `SniperPiercing.verse` said
*"0 is whatever GranterUnderdog holds, the Heavy Sniper today"* and had `SniperSlot` at 0.

**`WeaponsForTier` settles it.** It hands out `{0, 1}` at Underdog, `{1, 2}` at Rising Star,
`{2}` at Superstar and `{3}` at Prime Time. Read as SMG/shotgun, then shotgun/sniper, then
sniper, then rocket, that is a clean progression from the worst crate to the best. Read the
other way, the worst crate in the game hands out a Heavy Sniper.

**The log agrees:** 345-damage pierces recorded against slot 0. `UseDamageWindow` is false,
so that one number is the only thing telling the guns apart, and the beam has been going
through robots while the contestant held the submachine gun. `SniperSlot` 0 -> 2.

### The bleed itself

GDD 3.3: *"BLEED STATUS: Inflicts a bleed effect dealing 5 damage/second over 3 seconds.
Ideal for melting low-health Cyber-Swarmers."* BUILD_ORDER item 5, unbuilt since the
2026-09-05 audit, which left the third crate weapon as the only one with no character.

**One bleed at a time per robot.** A gun firing ten rounds a second would otherwise stack
ten bleeds and melt a Tank in a blink. A fresh hit on a robot already bleeding starts
nothing and refreshes nothing, which is the same anti-stacking rule GDD 3.2 sets for
duplicate crate pickups.

**It lives in `ShotgunKnockback.verse`, and that is a deadline decision rather than a tidy
one.** That device already subscribes to every hostile's damage, already asks the crate
manager which gun is held, and already tells the contestant's own damage from a robot's. A
new file would have been a new device for Kai to place and wire on the last day. If that
file is ever split, the bleed is the natural first thing to leave.

## 133. The Hype Call rescue teleport, at last. KAILEE'S RULING, 2026-09-07

GDD 3.4: *"Hype Call (Rescue Teleport): Taking a fatal blow instantly resets the player's
Hype Call cooldown. Pressing the key initiates a Hype-scaled rescue teleport. Success rates
scale with Hype quality: 35% at Underdog, 50% at Rising Star, and 65% at Superstar. On
success, a Sponsor Aid item spawns directly at the player's feet."*

BUILD_ORDER item 13, the last unbuilt piece of an uncuttable feature. Kai turned it down
earlier the same evening and then asked for it, giving the reason in one line: *"build it
cause you can get stuck with the swarm and they get all around you."*

**That reason decided the design.** A rescue that heals a contestant where they stand
leaves them exactly as surrounded as they were, so this really moves them: eight metres,
in one of eight compass directions, first clear one wins, with the starting direction
random so a contestant rescued twice is not thrown the same way twice. The throw is what
makes it a rescue rather than a heal.

### Where the work sits

The tidy split put the roll in `HypeMeterManager`, which owns the Hype Call key, and **the
Verse linker refused it**: script error 9000, a cycle running hype meter to death save to
game over screen to cash drop manager and back to the hype meter. The hype meter references
no other class in the project and several reference it, so the reference has to run the
other way.

`DeathSaveManager` therefore listens to the same placed Input Trigger, asks the meter for
the tier through a new public `GetTier`, rolls, and rescues. **Two new wiring slots on the
Death Save device**: the Hype Call input, pointed at the same trigger the Hype Meter uses,
and the Hype Meter itself. Leave either empty and the rescue simply never fires.

**The cooldown is bypassed rather than zeroed.** 3.4 says a fatal blow "instantly resets"
it; checking the window before the cooldown comes to the same thing and leaves whatever
cooldown the contestant had before the blow still running when they walk away from it.

### The fourth tier's number is not the GDD's

3.4 gives three rates because it was written before Prime Time existed; amendment 24 added
that tier afterwards. `RescueChanceByTier` is `{0.35, 0.50, 0.65, 0.80}`. The 0.80
continues the document's own steps of fifteen and keeps the best tier better than the one
below it. **That figure is Claude's, on Kai's standing delegation for calls of this kind,
and is a number rather than a ruling.**

### What is not changed

The manual run. 3.4 is explicit that the walk-to-it med kit spawns "always, whether or not
the Hype Call was used or succeeded", so a contestant who gambles and loses the roll still
has exactly the run they always had. A failed roll costs the press and nothing else.

## 134. The announcer stops talking when the run does. KAILEE'S RULING, 2026-09-08

Kai, playing the published island: *"stillt alking after i died say something about the
crate delovery"*.

**The chant watch is the culprit, and it is a structural one.** `AnnouncerManager`'s
`RunWatch` is raced against `AwaitRunEnd`, so it stops the instant a run ends. Its sibling
`WatchForChants` is **spawned**, and Verse cannot cancel a spawn. It therefore kept running
after the contestant was dead and kept drawing from `CrateCalled`, which is why the line
Kai heard over the results card was about crate delivery specifically rather than anything
else the host says.

**The voice was being let through deliberately.** The guard in `SayLine` stood the caption
down while the game over card was up and went out of its way to keep playing the clip, on
the reasoning that the words were in the way of the numbers and the performance was not.
Kai's report is that the performance is in the way as well.

### What changed

One guard at the top of `SayLine`: while the results card is showing, the whole line stands
down, clip and caption and mouth together. Nothing about the spawn was restructured, so the
chant watch still runs on after a run; it simply has nothing to say now.

**The sign-off is exempt, and that exception is load-bearing.** GDD 2.5's run-lost sequence
ends on the commentator, and the code already notes that the game over card is up before
`Say("SignOff", ...)` fires. Gating the card without exempting the sign-off would delete the
last line of the show.

**The old lower guard is now unreachable for anything but the sign-off.** It is left
standing rather than untangled, because the deadline is the same day and an unreachable
`if` is not a bug.

### 134a. The Death Save window is five seconds, not three. KAILEE'S RULING, 2026-09-08

Kai: *"death save neds to be 5 secomds"*, and then, unprompted: *"make sure that if i reach
the med kit befpre th e 5 secs the game reutns to normals"*.

**GDD 3.4 says three and is being departed from on purpose.** `CountdownSeconds` moves 3 ->
5. Nothing else in the project hard-codes the figure: the hold-alive, the grayscale, the
speed boost and the hostile slow all read this one dial, so the window, the colour and the
slow motion stay the same length as each other by construction.

**This dial has now moved three times and landed on 5 twice.** Amendment 10 stretched it to
5 because the slow motion GDD 3.4 asks for could not be built, and said it should come back
towards 3 if a substitute was ever found. One was, and 2026-08-18 restored the 3. The
substitute is real but it is not slow motion, and three seconds of it has now been played
many times by the person doing the playing. A window nobody can reach is a cutscene about
dying rather than a chance to live.

### Reaching it early already ends it early, and that is not a change

Kai's second sentence describes behaviour the code has had since the window was built, so
nothing was added for it. The window is a Verse `race` between reaching the med kit,
holding the contestant alive for the countdown, and keeping the hostiles slowed. Touching
the med kit wins the race, which cancels the other two the same instant, and the restore
that follows is one path shared by every ending: the colour blends back, the overlay goes,
the speed boost comes off, hostiles return to full speed, the shield is put back and the
glow stops.

**So a contestant who reaches it at two seconds gets everything back at two seconds.** The
5 is a ceiling on how long the contestant has, never a delay they have to sit through. It
is written down here because Kai asked for it specifically and a future session should not
have to re-derive it from the `race`.

## 135. The middle of the Hype meter drains too. KAILEE'S RULING, 2026-09-08

Kai: *"hype still off, shoudl go down faster if im ha;fway between supersta r and rising
star"*.

**A promise held for three amendments is being broken on purpose.** Amendments 124 and 126
both say in as many words that nothing below the Superstar line moves, because the climb
was the one thing Kai had said was right. Kai has now played it and asked for the middle to
bite, so this records the reversal rather than quietly reinterpreting the old rule.

### What changed

The top-heavy leak used to read `SuperstarAt` for where it starts. It now reads a dial of
its own, `TopHeavyStartsAt`, set to 40, which is the Rising Star line. Zero at that mark,
the full `TopHeavyDrainPoints` at a full bar, an even slide between.

- At 57, the halfway point Kai named, the extra is about 2.8 a tick where it was 0. Against
  the constant 2.5 that roughly doubles the pull in the dead water Kai was describing.
- At the Superstar line it is 5.8 where it was 0.
- At a full bar it is still exactly 10, so **the top of the meter is untouched** and
  amendment 126's tuning up there still stands.
- Below 40 nothing has changed and nothing should. That stretch is a contestant getting
  started rather than one coasting.

**The cost of the new dial** is that the leak and the tier marks can now drift apart, where
before they could not. Setting `TopHeavyStartsAt` to the same number as `SuperstarAt`
restores the old behaviour exactly, which is why it is a dial and not a rewrite.

The match-start log line reports the new start point, per amendment 131's rule that the
meter says what it is set to.

## 136. The crowd gets bored. KAILEE'S RULING, 2026-09-08

Kai: *"every 4 rounds it should get harder to obatin hype i think cause in realtim e
audicde wouldget bored and im earingmroe cash because ther emroe robots being added"*.

**The reasoning behind it is arithmetic, and it is right.** A coin is worth the same Hype in
room 20 as in room 1, and room 20 holds far more robots, so it drops far more coins.
Earning therefore inflates with the tier while the drain stays flat. Amendment 126 already
found the same shape from the other end: 233 pickups in 230 seconds out-earned the entire
leak on their own. Left alone, the meter drifts from a measure of style into a measure of
how long you have lasted, and GDD 3.1 asks for the first one.

### What was built

Three dials on the Hype Meter. `BoredomLapRooms` is 4, `BoredomPerLap` is 0.10 and
`BoredomFloor` is 0.50. Earning is multiplied by 1.0 on the first lap, 0.9 on the second,
0.8 on the third, straight-line rather than compounding, and never below the floor.

**It scales all earning, not just the cash.** Kills, shaves and clusters get more plentiful
as the crowd grows too, so singling out the coins would only move the inflation elsewhere.

**Losing Hype is not scaled.** A hit costs what a hit costs, however deep the run is. The
Underdog Boost still multiplies on top, unchanged.

### The floor is the part that matters

Hype sets crate quality, GDD 3.1, and the game is endless as of amendment 92. Without a
floor a deep enough run would earn nothing at all, and the crates would collapse to Underdog
at exactly the point the hostiles are hardest. At 0.50 the best tier stays winnable, it just
costs twice the work it did on the first lap. **`BoredomFloor` at 1.0 switches the whole
feature off** without unpicking any wiring.

### One manual step, and it fails safe

**Drag the placed Hype Meter into the `HypeMeter` slot on the placed Wave Manager.** The
wave device tells the meter which room it is on; the meter cannot ask, because it
references no other class in the project and several reference it, which is the shape
amendment 133 had to settle after the Verse linker refused a cycle with script error 9000.

Leave the slot empty and `SetRoom` is simply never called: the room stays 1, earning stays
1.0x, and the meter behaves exactly as it did before this amendment. The match-start log
says what the dials are set to and how to tell an empty slot, per amendment 131's rule that
the meter says what it is set to.

**Four rooms is the lap the waves already run on** rather than a second rhythm invented for
this: WaveManager cycles Swarmer, Boar, Sentinel, Tank and repeats.

## 137. The announcer was watching the sticker album, not the prizes. 2026-09-08

Kai: *"didnt hear the prizes voice lines when they appaered inthecrate and i collected
them"*.

**He was watching the wrong number, and the bug got worse the more the game was played.**
`CallIt` compared `Vault.FoundFor(Contestant).Length`, which is the size of the collection:
how many DIFFERENT prizes have ever been won. That only rises on a prize never won before.
So the first toaster of a career announced itself and every toaster after it was silent.

**And the collection is saved against the career**, so it survives a restart. By the time a
sitting had turned up most of the fourteen prizes, the host had almost nothing left to say,
and a fresh run inherited a full album and started silent. That is the shape of Kai's
report exactly: the lines were heard early on and then stopped.

### What changed

`PrizeVault` now keeps `WinCount`, which climbs on every `Claim` that hands over a prize,
repeats included, and exposes it as `PrizesWonCount`. The announcer's `PrizesNow` reads
that instead of the collection size. Everything else about the moment is untouched: it
still sits below the crate line so a crate carrying a prize does not say both about one
object, and it still uses `LastPrizeWon` as the position of the line, so the words match
the prize.

`WinCount` is per sitting and never reset. The announcer re-syncs its own `LastPrizes` to
it at the top of every run, which is where "per run" belongs, so a number that only climbs
is the simplest thing that cannot go wrong across a PLAY AGAIN.

**The prize log line now says both numbers**, wins this sitting and album size, because
those two having been confused for each other is the whole of this bug.

### If it is still silent

The remaining suspect is `PrizeLandedVoices` on the placed announcer being empty or shorter
than the fourteen prize lines. The code deliberately survives that, captioning without a
clip, which is exactly the failure that looks like nothing being wrong. Not checked.

## 138. A run grants every rank it earned, not one rung. KAILEE'S RULING, 2026-09-08

Kai: *"got 11k cash and rank was still undercard filler"*.

**The queue was an invention and it is what Kai hit.** `OnRunEnded` granted exactly one
rung per run and banked the rest against later runs. 11,215 clears
`ScoreForRatingsMagnet` at 6,500, so that run qualified for rank 3, Ratings Magnet, and
handed over rank 1, Undercard Filler. GDD 2.6 says beating either threshold "advances the
rank" and says nothing about paying out over later runs.

**It was also unreachable in practice, not just slow.** The account save reads back empty
between sittings, so most sessions start a career at rank 0. One rung a run then means the
top three titles could not be won however well anyone played. The two faults compounded:
the queue only made sense if the queue survived, and it does not.

### What changed

One line. `NewRankIndex` is set to `Earned` rather than `Record.RankIndex + 1`. A run that
qualifies for three ranks now grants three. Nothing else moved: the thresholds are
untouched, either threshold still counts on its own per GDD 2.6, personal bests still only
climb, and the rank still cannot go down.

### What was asked for and NOT done, and why it was put back to Kai

Kai first described a rank that **wipes on every run**: *"the rankt is suppsoed to rest
whenyoi finish arunand press play again"*. That contradicts GDD 2.6, which calls the Career
Sponsor Rank a saved statistic that survives between runs, and GDD 5.7, which lists it
among the four uncuttable features. Per CLAUDE.md rule 2 the conflict was put to Kai rather
than resolved. Kai chose the wipe, then asked *"do you think thats best??"*, and on the
recommendation that an uncuttable feature should not be gutted on the day the project is
marked, settled on keeping the rank persistent and deleting the one-rung rule instead.

**So the rank still builds across runs.** If Kai returns to the wipe, this section is the
record of why it was not taken today.

### Still open, and not touched here

The cash counter showing the previous run's total at the start of a new run, which is the
part of Kai's report that IS a plain bug: *"the bug was that i could see the cash i
collected fromthe previo s game"*. `RunScore` is reset on match start, so the fault is in
what is displayed rather than in what is counted.

## 139. The career card shows this run, live. KAILEE'S RULING, 2026-09-08

Kai pressed the show-card key mid-run, saw the career totals, and read them as the previous
game's numbers leaking through: *"the bug was that i could see the cash i collected fromthe
previo s game"*. **They were not leaking.** That card showed `LifetimeBankroll` and the
held `RankIndex`, both career-wide on purpose, and the line already said "Career earnings".

**It was still the wrong answer.** Kai: *"thought it shoudl sho the rank i have now inrela
time and the cash as i am playing the gane right or is thatwrong?"* A card that answers
"how am I doing" with a total from three runs ago is answering a different question from
the one being asked of it.

### What the card shows now

- **The rank this run has earned so far**, big, in cyan. `LiveRankName` asks the same
  `QualifiedRank` the run end asks, with this run's tier and this run's cash in place of the
  career bests, so the card can never promise a title the run would not actually be given.
- **This run's cash**, in gold, from `CashDrops.GetRunScore()`.
- **Career earnings**, still there, in smaller white type underneath.

Both top lines are redrawn inside the loop that was already timing the card out, so this
costs one pass over two text blocks every `PollSeconds` and needs no second loop to cancel.
The career line is not redrawn: it cannot change until the run ends.

**Nothing is saved and nothing promotes from this.** The live rank is a reading of a run in
progress. GDD 2.6's comparison still happens once, at run termination, in `OnRunEnded`, and
amendment 138 governs what it grants.

**The career total was not removed, only made quieter**, 22pt gold down to 18pt white. It
is the only place the lifetime figure appears and GDD 2.1 step 6 asks for it.

### Still open

Kai's last report of the day: nobody knows to press the key at all. *"the user needs to
knoe ot press space to see thier rankt maybe a bill boward would bebetter"*. Not started.

### 139b. And it said THIS RUN twice. 2026-09-08

Kai: *"why is there this run twice? ot shoud be thid run and thne all time"*. Fair. 139a
added a THIS RUN caption above the rank and left the money line below it still prefixed
"This run:", so the card said it twice within a few pixels.

The card is two labelled groups now, each a caption over its own figures:

```
        THIS RUN
     RATINGS MAGNET
         $11215

        ALL TIME
         $43900
```

Captions carry the words, figures carry the money, and neither figure repeats its own
caption. Both top figures still redraw while the card is up; the all-time figure still
cannot change until the run ends.

### 139c. And the all-time group comes off the card entirely. KAILEE'S RULING, 2026-09-08

Kai: *"cant we jsut have the earinign and rank of this run?? they can look backat reh
leaderbaord fro the ranks and eairngs for the best run?? they want to celar the de t in one
big run si the goal anyways"*.

**The argument is right and it is a design argument, not a tidy-up.** This card is the
mid-run glance, and mid-run the only question worth answering is how this run is going. The
premise of the show is clearing the debt in one run, so a lifetime total is the wrong number
to put in front of a contestant who is mid-run.

The card is now the caption, the live rank, and this run's cash. Nothing else.

**Nothing was lost by removing it.** The all-time figure already appears on the start
screen, which prints CAREER EARNINGS above the PLAY button, so GDD 2.1 step 6's
accumulating bankroll is still shown. The broadcast screen's leaderboard still carries the
past runs and the rank held at each, which is the "look back at the leaderboard" Kai is
pointing at.

`BankrollLine`, `BankrollMessage` and `AllTimeLabelMessage` are left standing and unread, so
putting the group back is two widgets rather than a rewrite.

### 139d. The caption goes too. KAILEE'S RULING, 2026-09-08

Kai: *"dont haveti say this run its implied"*.

**It was right when it was added and wrong an hour later.** 139a put a THIS RUN caption over
the rank because the card also carried an all-time group and the two needed telling apart.
139c took the all-time group off. With nothing left to contrast against, the caption was
labelling the only thing on the card.

The mid-run card is now the live rank and this run's cash, and nothing else. Four amendments
in one afternoon to arrive at two lines, which is what it costs to find the right two.

`RunLabelMessage`, `AllTimeLabelMessage`, `BankrollMessage` and `BankrollLine` are all left
standing and unread. Any of this is reversible in a widget or two.

### 139e. ALL TIME EARNINGS on the start screen. KAILEE'S RULING, 2026-09-08

Kai asked what the line would say, was shown it, and picked the wording: CAREER EARNINGS
becomes **ALL TIME EARNINGS**. It is the phrase Kai reached for unprompted twice.

**The line stays.** Kai asked why it is needed at all. It is the only place in the game
where GDD 2.1 step 6, the bankroll accumulating run after run, is visible, and it costs one
line at the foot of the start screen's five-place board. Removing it would take a step of
the documented core loop out of the shipped game.

## 140. The debt carries between runs. KAILEE'S RULING, 2026-09-08

Kai: *"i dont want the deb to reset to fulll at the top of every run doesnt it ruinteh whole
alltiem earnings tings??"*

**It did, and that is the good catch of the day.** The debt was wiped back to the full
$1,200,000,000 at the top of every run, so all-time earnings climbed on one screen while
the debt ignored them on another and the two figures never met. A debt that comes down as
the career earnings go up is the same number told from the network's side, and it is what
gives the all-time line something to be for.

### What changed

- `SeedDebt` reads `ReadDebtDrift` from the save instead of zeroing.
- `ResetDebtEveryRun` no longer touches the debt. It still re-reads the credited-score
  baseline at the top of a run, which it always did and still must, because a fresh run
  puts the winnings back to zero and without it the counter would pay nothing off until the
  new run beat the old run's score.
- The periodic save is back on, once a second, on the throttle that was left in place.

**Seeded once a sitting, then left alone.** `DebtDrift` is state on a placed device, so it
survives a PLAY AGAIN on its own. Re-reading the save every run would have put the debt
back to full by a second route, because the account save reads back empty between sittings.
See [[career-save-reads-back-empty]] in the working notes.

**Three retired pieces came back exactly as they were left:** `TicksSinceDebtSaved`,
`DebtSaveEveryTicks` and `SaveDebtDrift`, retired 2026-08-28 and kept correct rather than
kept as a landmine. `SaveDebtDrift` still carries every field of the record by hand,
including the `PrizesFound` it was once missing.

**PAID IN FULL is unchanged.** Clearing the debt still flashes the notice and the Network
still reissues the whole amount, which now means the reissue is the only thing that puts it
back to full.

### Still wrong, and not fixed here

`DebtPerScorePoint` is 1. Against $1,200,000,000, with interest adding $1,000 a second, a
run scoring 11,215 takes $11,215 off and the counter reads as climbing only. Carrying the
debt makes that arithmetic survive between runs; it does not fix it. Raising the rate was
offered and is not yet ruled on.

## 141. The debt is impossible on purpose, and paying it is the punchline. KAILEE'S RULING, 2026-09-08

Kai, turning down an offer to make the debt payable: *"no its suppsoed to be impossible"*.
Then the shape of what should happen if anyone ever does it anyway: *"if theyreach the
imporssibel then it needs to rest and say soemting lineintrest fees and then teh numerb
needs to reapper and it needs to look like its snippingupwards and htenevetual stop at
antoerhimmproable numebr"*.

**So the debt stays unpayable and `DebtPerScorePoint` stays at 1.** A run scoring 11,215
takes $11,215 off $1,200,000,000, and interest adds $1,000 a second while off the air. That
was offered as a fault to fix and ruled to be the point. Clearing it is not a reward, it is
the Network's best joke.

### The sequence

1. **CONTESTANT DEBT: PAID IN FULL**, held for `PaidInFullSeconds`.
2. **PROCESSING... INTEREST FEES APPLIED**, held for `InterestFeesSeconds`.
3. The number reappears and climbs like a fruit machine, settling on a new figure.

### The new figure

Rolled between `ReissueDebtMin` and `ReissueDebtMax`, **1,000,256,000 and 1,569,394,000**.
The digits are Kai's own, given as 1,000,256 to 1,569,394; asked which of that and the
standing 1,200,000,000 was the bigger number, Kai chose the bigger, so the range is those
digits at that scale.

**`StartingDebt` at 1,200,000,000 sits inside the range on purpose.** A debt that shrank by
a factor of a thousand the first time it reissued would read as a fault rather than a joke.

### The roll

`RollUpTo` picks a random figure between where the display currently sits and the target,
so it only ever climbs and the jumps shrink by themselves as the gap closes. The wait grows
by `ReissueRollSlowdown` each step, so it starts as a blur and comes to rest. It then sets
the exact target, because a counter stopping just short of its own total is the one thing
this must not do.

**No easing maths and no division**, both of which would need a float where an int is, and
every division in Verse can fail. Randomness into a closing gap gives the same shape for
none of the trouble.

### DebtBase

`StartingDebt` is an editable constant, so the figure the drift is measured from is now
`DebtBase`, seeded to it in `SeedDebt` and moved by a reissue. **It is not saved.** Adding a
field to `career_record` risks every existing save, for a number that only changes when
somebody pays off 1.2 billion dollars one pickup at a time. If it is ever wanted across
sittings it is one field and one line in `SaveDebtDrift`.

**The host still says nothing at this moment**, deliberately, per CLAUDE.md standing rule 3.
The line is Kai's to write and there is no recording for it.

### 141a. And a different excuse every time. KAILEE'S RULING, 2026-09-08

Kai: *"waht if they do the impossible and elar instreat fees it needs tosya another
thing"*.

Clearing $1.2 billion once is already impossible. Clearing what the Network puts back is a
second impossible thing, and repeating the same notice at it would waste the moment. So
`InterestFeesLadder` holds an excuse per clearance, each thinner than the last:

1. PROCESSING... INTEREST FEES APPLIED
2. PROCESSING... INTEREST APPLIED TO YOUR INTEREST
3. PROCESSING... ADMINISTRATION FEE FOR PROCESSING YOUR PAYMENT
4. PROCESSING... EARLY REPAYMENT PENALTY APPLIED
5. PROCESSING... WE HAVE STOPPED EXPLAINING

**The last rung repeats for ever after.** Anybody who gets that far has earned a joke that
admits it has run out of jokes. An empty ladder falls back on `InterestFeesLabel`, so the
moment is never wordless.

`TimesCleared` counts the clearances for the sitting and is not saved, for the same reason
`DebtBase` is not.

**These are wording, not dialogue.** The distinction is the one `PaidInFullLabel` has
carried since it was written: on-screen text the Network puts up, not lines the host says.
Every rung is `@editable`, so Kai can rewrite any of them in UEFN without touching code, and
the host's own line for this moment is still Kai's to write and still absent.

## 142. The announcer says what is actually wired. 2026-09-08

Amendment 137 fixed the prize lines going quiet and left one suspect standing that nothing
in the code could answer: whether the placed announcer has any audio players in a given slot
at all. **A moment with no clips still captions, on purpose**, so a half-wired announcer
looks exactly like a working one with nothing to say. That is the failure this turns into a
line in the log.

`ReportWiring` runs at startup and prints every one of the fifteen moments with its written
line count beside its wired clip count. Three cases:

- **Lines written, nothing wired.** A warning naming the slot to fill in UEFN.
- **Fewer clips than lines.** A warning: the lines past the end can never be heard, and a
  line asked for by POSITION lands on the wrong clip.
- **Everything matching.** Printed anyway, so a moment missing from the list is itself a
  signal.

**The by-position case is the one that bites.** `PrizeLanded` and the crate rewards ask for
the line at an index, so the clip and the caption only agree while the two lists are the
same length and the same order. `BarkDatabase.GetBarkAt` already carries a note that its
array order is load-bearing for the same reason.

## 143. A hint that the rank card exists. KAILEE'S RULING, 2026-09-08

Kai: *"the user needs toknoe ot press space to see thier rankt maybe a bill baord would
bebetter"*. A billboard was offered, and Kai chose on-screen words once it was clear they
could sit under the Hype meter: *"cant it be like under the hhype thing on he right"*.

**PRESS SPACE FOR YOUR RANK**, at the top of every run, gone after `RankHintSeconds`.

### Why it fades rather than staying

A permanent line would be a fifth HUD widget against GDD 5.4's budget of three, and GDD
2.4's warning about HUD clutter is the whole reason `OnShowCardPressed` exists rather than
the card simply living on screen. A few seconds at the top of a run teaches the key and then
gets out of the way, which costs the budget nothing.

### Where it sits, and a correction

Directly under the Hype meter's title, at 0.10 across and 0.895 down. **The Hype meter is on
the LEFT of the screen**, spanning 0.015 to 0.235 across; Kai remembered it as the right.
The position is `@editable` either way.

Those are HypeMeterManager's numbers and cannot be read from CareerRankManager, so if the
meter is ever moved this has to be moved after it.

The wording is `@editable` too, because Verse cannot ask an Input Trigger which key it is
bound to. Rebind the key in UEFN and the words have to be changed by hand to match.

## 144. The prize is called as the crate breaks, not as it is picked up. KAILEE'S RULING, 2026-09-08

Kai: *"the prize line shoudl be saidas the user breaks the crate open"*.

**The line was a beat behind the picture.** The prize prop is laid out the instant the crate
is shot open, and the walk over to it is a second or two later. Announcing on the pickup put
the host behind the thing the player was already looking at, which is the wrong side of a
joke.

### What changed

`PrizeVault` gains `Reveal(Tier)`, called from `CrateManager` immediately after `ShowOpened`
and `ShowReward`. It sets `LastWon` and raises a new `RevealCount`, and the announcer's
`PrizesNow` reads `PrizesRevealedCount` instead of `PrizesWonCount`.

**Silent on a crate with no prize.** Amendment 80 made the prize a bonus rolled on top of
the reward, so most crates hold nothing and `Reveal` is called on all of them.

**`Claim` is untouched** and still counts the win, still pays the prize money and still adds
to the album. Wins and reveals are now two separate counts because they are two separate
moments, and only one of them is a cue for the host.

### This is the third place that trigger has been

The first was the size of the career prize collection, which only rose on a prize never won
before and went quiet as the album filled; amendment 137. The second was wins including
repeats, which was correct but late. This is the moment the player is actually looking at.

### 143a. The hint was drawn and not seen. 2026-09-08

Kai, after a run: *"i ddint see the pres space thing?"*.

**It almost certainly drew.** The log from that run carries no rank-hint warning, and the
only way the widget is skipped is `GetPlayerUI` failing, which warns. But the first version
logged **only** on failure, so "I didn't see it" and "it never drew" looked identical in the
log. That gap is closed: the hint now logs where it went and for how long.

Alongside that it is louder. 16pt white became **22pt gold**, the show's own colour. Small
pale text low on the screen, during the eight seconds a contestant spends looking at the
middle of the arena, was asking to be missed.

### And the prize clips are wired, which closes amendment 142's open question

The same log's wiring report: **PrizeLanded, 14 lines, 14 clips.** Every one of the fifteen
moments matches, with no warnings. So the prize lines going quiet was entirely the trigger
bug of amendment 137, and the second suspect is ruled out rather than merely unlikely.

**Amendment 138 is confirmed working in the same log:** `Career saved -- rank 2, best tier
3, best score 3630`. A score of 3,630 clears `ScoreForFanFavorite` at 2,500 and the run
granted rank 2 outright from rank 0, where the old one-rung rule would have granted rank 1.

## 145. The debt sits still. KAILEE'S RULING, 2026-09-08

Kai: *"i thoguth we agreedona stangament nmber? and if htey o reach the imposibel ththenit
goe sup and seay s some lien then its stanganat again????"*

**`DebtInterestPerTick` goes from 250 to 0.** The debt now moves in exactly two ways: down
as cash is collected, and up in one jump when it is cleared. Nothing creeps.

### Why the creep had to go

It was seven a tick against a debt of $47,300, slow enough to miss at first glance and
obviously climbing once noticed. Amendment on 2026-08-28 raised it to 250, a thousand a
second, when the debt became a billion two, because seven a tick against that reads as
frozen.

**But a run earns a few thousand dollars over several minutes, and a thousand a second runs
while the contestant sits on the start screen.** So the debt ended every run higher than it
began. The 2026-09-08 log has it carried over at $1,200,008,250 and then $1,200,027,250,
with amendment 140's carrying working perfectly and doing nothing but preserve the climb.
Collecting cash was cosmetic.

**The joke survives without it.** The number is impossible because it is 1,200,000,000 and a
point of cash pays off a dollar, not because it runs away. A still number that visibly goes
down and will still never arrive is a better joke than one that laughs at you for trying.

### Unchanged

The reissue and its ladder, amendments 141 and 141a, are exactly as built: PAID IN FULL,
then an excuse off `InterestFeesLadder` that climbs a rung each time anyone does it again,
then a fresh figure rolled between 1,000,256,000 and 1,569,394,000 and rolled up like a
fruit machine. Kai asked for that to stay and it was never in question.

`OffTheAir`, the tick and the save are all untouched. Setting `DebtInterestPerTick` above
zero brings the creep back exactly as it was.

## 146. Two seconds in credit. KAILEE'S RULING, 2026-09-08

Kai: *"what happesnif theydo a runand they only have 50$ left over when they go back
shouldthe numebr be green and withthe + so lit sliek +150 and thne it does he paif int full
theninrst feeds applied etc"*.

**A run does not stop the moment the debt hits zero.** It stops when the last pickup is
walked over, and that pickup can carry the total past zero. The overshoot was thrown away
without ever being shown.

It is the only time in the entire game that this readout holds a positive number, so it now
gets a beat of its own: **CONTESTANT CREDIT: +$150**, in green, for `CreditSeconds`. Then
the line goes back to red and the sequence runs exactly as amendments 141 and 141a built it:
PAID IN FULL, the excuse off the ladder, and a fresh impossible figure rolling up.

**The colour is set back to red unconditionally**, not only after a credit was shown, so no
path can leave the readout green for the rest of the match. An exact zero skips the credit
beat, because a +$0 is worth nothing to look at.

**The surplus is not carried into the new debt.** The Network keeps it, which is what the
fee notice on the very next screen is about.

## 147. The screen says yes as well as no. KAILEE'S ASK, 2026-09-08

Kai: *"if i do get it it should say congrats, they took pity on you, teleport granted or
soemthing liek that word smith it"*.

**The refusal had words and the success did not.** A granted rescue teleported the
contestant, spawned the med kit and said nothing at all, so the two outcomes were told in
different languages: one explained itself, the other simply happened.

`RescueGrantedLine` is **"A SPONSOR TOOK PITY ON YOU. TELEPORT GRANTED."**, shown in green
where the refusal is red, with the odds line hidden either way because the odds are a
question and the question has been settled.

**The words are Kai's, tightened.** "Pity" and "teleport granted" are both Kai's and both
stay. "Congrats" went, because this network congratulates nobody and the backhand is the
joke: you were not rescued for being good, you were rescued because somebody felt sorry for
you. It is `@editable` like the other two.

### 147a. And a line that says whether the key ever arrived

Kai: *"hweni pressed shift nothing happened i didnt see the no takers thing"*. Both outcomes
of a working rescue now put words on the screen, so silence means the roll never happened at
all, and there are exactly two candidates: the key never reached the device, or a guard
returned without a word.

`OnHypeCallForRescue` now logs **before any guard**, reporting whether the window was open
and whether the ask had already been made, and the silent `WindowOpen` early return says so.
One playtest with a deliberate death tells the two apart.

**Note for whoever reads that log:** the subscription is `ReleasedEvent`, not `PressedEvent`.
The key has to be let go of, not just held.

## 148. A spotlight on a rescued contestant. KAILEE'S ASK, 2026-09-08

Kai: *"im haig a hard time seing wehre i am teleported cani have aspotlight on my wheni ge
teleproted?"*

**The throw is the whole point of the rescue and it was invisible.** Eight metres in one of
eight random directions, during slow motion, on a grey screen, while the contestant is
looking at where they used to be. They arrive somewhere and have no idea where. Amendment
133 built the throw precisely because a rescue that heals you where you stand leaves you as
surrounded as you were, and that argument only pays off if the contestant can find their
new spot.

`LightRescueSpot` hangs a Customizable Light `RescueSpotlightHeight` above where they
landed, aims it straight down, turns it on, and switches it off after
`RescueSpotlightSeconds`.

**It is the trick TankEntrance already uses**, and the height and pitch defaults are that
device's numbers on purpose, so the two lights behave alike and one lesson covers both. It
also carries that device's hard-won warning: `TeleportTo` is failable and a device that
refuses a destination logs nothing of its own, so a light that never moved and a light too
dim to notice look identical from inside the code.

**Four seconds, longer than the Death Save window on purpose.** The grey lifts and the arena
comes back and the light is still there for a beat, so the contestant gets their bearings
before the room turns ordinary again.

**One manual step:** place one Customizable Light device and drag it into the
`RescueSpotlight` slot on the placed Death Save device. Leave it empty and nothing happens
at all, exactly as it behaved before this amendment.

### Not published today, deliberately

Kai's live island code, 5530-5775-8888, works. Republishing would restart Epic's content
review, which had already rejected two submissions that day, and Kai's own observation is
that a new release comes back with a different island code. Trading a known working link for
a spotlight, hours before the capstone deadline, is the wrong trade. **This ships in the
next release, not tonight.**

### 148a. The spotlight is yellow. KAILEE'S RULING, 2026-09-08

The colour lives on the placed Customizable Light, not in Verse, so it is recorded here
rather than in a default.

White was recommended first, on the grounds that it is the brightest option and the one
colour a desaturating overlay cannot change. **Kai corrected that from the floor:** *"but he
oerlay is mkaing the scren look white shouldnt it ba differnt color thats not blacke?"* A
white light on a washed-out white screen is invisible, which is right and settles it. Hot
pink was then recommended; Kai chose **yellow**.

**Turn the intensity well up.** Against a desaturated screen it is brightness that carries,
not hue.

Green and red were both ruled out for meaning something else already: green is the room-won
flash of amendment 128, and red is the sponsors' refusal.

## 149. The rescue threw the contestant out of the room. KAILEE'S REPORT, 2026-09-08

Kai: *"the teleportation thing, its broken, i got teleported out of the arena!!!!"*

**Walking and teleporting are not the same test, and that is the whole bug.** The throw
clamped to `ArenaHalfLength` and `ArenaHalfWidth`, 1750 by 1250, which are the same numbers
`TwinStickController` holds the contestant inside during normal play. Those numbers have
never been caught out on foot, because a contestant walking at a wall is stopped by the wall
long before the clamp has an opinion. **A teleport has no wall to be stopped by.** It goes
exactly where it is told, and 1250 in Y is outside the room.

That also explains an older report that was never chased down: the med kit "fell out of
arena" on 2026-09-05, placed by the same kind of clamp.

### The fix

The rescue gets its own bounds, `RescueHalfLength` and `RescueHalfWidth`, at **1050 by
550**. Those are `SimulatedAudience`'s crate-drop rectangle, which is the one piece of floor
in this project **proven** to be inside the room: crates have landed in it for weeks and
contestants have walked to them.

**They are deliberately tighter than the room.** A rescue that lands a metre inside a wall is
worth nothing beside one that certainly lands on the floor, and this code runs once per life
at the exact moment being wrong ends the run.

### What was NOT done, on purpose

**The eight other copies of `ArenaHalfLength` and `ArenaHalfWidth` were left alone.** They
sit in AdversarialTester, StuckHostileProbe, TwinStickController, WaveManager and
hello_world_device at 1750 by 1250, and in FallingDebris and SimulatedAudience at 1050 by
550. The room's real size has now been measured wrongly twice, once at 1220 by 720 against
the game's own clamp and once at 2560 by 1280 off a wall actor's pivot, and the scripts
carry a third figure again. **Correcting all of them from a guess, hours before a deadline,
is how the 1220 mistake happened in the first place.** Somebody should read the true wall
positions off the map and fix all ten together, in daylight.

The log line now prints the bounds it clamped to, so the next playtest says what was used
rather than leaving it to be inferred.

## 150. After the death, only the goodbye. KAILEE'S RULING, 2026-09-08

Kai: *"the anoucner is saying lines afte rthey die, they need to fonish the line and not say
anymore lines"*, and then, exactly: *"the only line that is said after the death is the
goodbye sign off lines"*.

**Amendment 134 asked the wrong question.** It stood every line down while
`Results.IsShowing`, which sounded right and left a gap: a run ends the instant the Death
Save window expires, and the game over card takes a beat to appear after that. Anything that
spoke in between walked straight through the guard.

The test is now the run itself, `MatchHasStarted`. That gate closes at the moment of death
and stays shut until PLAY, so it is the honest question. The sign-off stays exempt, because
the run is over by definition when it fires and it is the one line that has to survive.

### And it waits for him to finish

The second half of the report. The sign-off used to land on top of whatever was mid-word,
which is what the `Stop` inside `SayLine` was added to tidy up. **Waiting is better than
tidying:** the line already going gets its ending, then the show closes.

`SecondsElapsed` stops advancing the moment `RunWatch` loses its race, so what is left of
the current line is worked out once and slept through, rather than watched for.

**Net effect, which is Kai's sentence back:** the contestant dies, the host finishes his
sentence, the host says goodnight, and then nothing.

## 151. A robot that will not move comes off the board. 2026-09-08

**Found in the log rather than reported.** Kai asked what else a QA tester might break, and
the 20:55 playtest had already answered it twice:

> WARNING: a Swarmer would not move at X=-611.71 Y=264.14 and could not be put back at its
> spawner either. **The wave cannot finish while it is stuck.**

That warning describes a run that can never end, and it printed twice in a single session.
`WaveManager` finishes a room by counting eliminations, so a robot that cannot be killed and
cannot be moved holds the room open for ever and the contestant is left shooting at nothing.

### Why clearing it is the lesser fault, and it is not close

GDD 5.7 makes win/loss resolution **uncuttable**, and a room that never resolves breaks it
outright. One robot leaving the arena unexplained costs a moment of confusion. A soft-locked
run costs the whole run, and on the capstone brief playability is the top criterion.

### It is the end of a long ladder, not a first guess

`ClearStuckHostiles` only fires after `StillLooksBeforeReport` consecutive looks with the
robot in exactly the same place **and** every teleport in `PushOffsets` or `ReturnOffsets`
refused. That is precisely the case the warning already described and did nothing about.
`StuckClearDamage` is 100,000, far past any hostile's pool, so no stat card can outlive it.

Set `ClearStuckHostiles` false and the old behaviour returns: the warning prints and the
robot stays where it is.

### Also confirmed working in that same log

The rescue chain end to end, which is worth recording because it was reported broken twice
today: `key released, window open yes` → `the ask is in` → `rolled 0.000328 against 0.500000
at tier 1. Saved.` → thrown to X=-595 Y=337, inside the new bounds → med kit at the
contestant's feet → `rescue spotlight on ... for 4.000000s` → `spotlight off`.

## 152. The debt was being reset by a second door. KAILEE'S REPORT, 2026-09-08

Kai: *"the numebr isnt going dwon on the contesttdant debt every after every run???"*

**Amendment 140 stopped `ResetDebtEveryRun` wiping the debt and missed this.** LEAVE THE
SHOW brings the television back on, and that path calls `SeedDebt` again for every
contestant. `SeedDebt` re-reads the career save, the career save reads back empty, and empty
means a drift of zero, which is the full debt. So the debt was put back to full after every
run by a second route, while 140's own comment promised it was not.

`DebtSeeded` now makes it once a sitting. The guard is a flag rather than moving the call,
because all three callers are legitimate: two are the first contestant arriving and one is
the television coming back. Only the first should seed.

### And the same door was stacking the HUD loops

Found while fixing the above. `StartHudLoops` sits beside `SeedDebt` in that same path and
it **spawns**, and a spawn cannot be cancelled. So every trip back to the television added a
second debt counter beside the first: two loops paying off the same cash, two loops writing
the same save, two blink schedules on the ON AIR light. Three runs in a sitting meant three
of each.

**Nobody caught it because the duplicates all agreed with one another** about the numbers.
The only symptom would have been the debt moving in steps of two, which against a
billion-dollar figure is invisible. `HudLoopsRunning` closes it.

**This is the third time a spawned loop has caused a bug on this project**, after the
announcer's chant watch outliving a run in amendment 134 and the note in amendment 86 about
PLAY AGAIN leaving two hosts talking. A `spawn` that is started per-run needs a reason not
to be a `race`.

## 153. The rank is about the run, and the ladder is on the wall. KAILEE'S RULINGS, 2026-09-08

Three rulings and a bug, all about the same thing: a contestant knowing what they just did
and what they are aiming at.

### The FINAL RANK stamp is this run's rank

Kai: *"the finalcrank need to be the rankyou got fromthat run or esle its confusing"*. The
card stamped the CAREER rank, which is a different number answering a different question. A
contestant reads FINAL RANK at the end of a run and takes it as a verdict on the run they
just played, and amendment 139 had already made the press-space card answer that question,
so the two cards disagreed by design. `CareerRank.RunRankTitle()` now serves both.

**The career rank is untouched.** It still climbs, still saves, still shows on the start
screen. Only the stamp changed, so GDD 2.6 and 5.7 are intact.

### The thresholds are for somebody actually trying

Kai: *"im not even trying though this is jsut to getit over with for the class we need to
treat it as if a person was really trying"*. The first proposal was anchored on Kai's own
test runs, which is exactly the wrong yardstick.

Anchored on the room bonus instead, which starts at 1,000 and grows 50% a room, so clearing
room 4 is about 5,000 total, room 7 about 30,000, room 10 about 115,000 and room 13 about
390,000:

| Rank | Was | Now | About |
|---|---|---|---|
| Undercard Filler | 1,000 | **5,000** | room 4 |
| Fan Favorite | 2,500 | **30,000** | room 7 |
| Ratings Magnet | 6,500 | **120,000** | room 10 |
| The Network's Sweetheart | 15,000 | **400,000** | room 13 |

Someone genuinely trying has to survive thirteen rooms to be called The Network's
Sweetheart. The tier thresholds, 3, 7, 13 and 21, are unchanged and still count on their
own per GDD 2.6.

### The ladder sits beside the board

Kai: *"the leaderbaerrd should show the rankson the right side ... so the player can know
what they are trying to earn to"*. A leaderboard says what you did and nothing about what it
was for. `RankLadder` prints all five titles with the price of each rung, down the right of
the record board, and the record rows shift from 0.5 to 0.36 so the pair still reads as
centred.

**The figures are asked for, not copied.** `ScoreNeededFor` reads the same `@editable`
thresholds the promotion reads, so the board can never advertise a price the game does not
charge. The first rung shows `---` rather than `$0`, because rank 0 is where everybody
starts rather than something to aim at.

**One manual step:** drag the placed Career Rank device into the new `CareerRank` slot on
the placed Start Screen device. Left empty, the ladder still prints its titles.

### And the stamp fits the box now

Kai: *"if i get network seet heart, on the end card screen it doesnt fit the red box"*. The
2026-09-07 fix reckoned a letter at half the text size, a ratio tuned for the announcer's
lighter banner face, and by that sum the longest line came to 792 pixels inside a 1040 box
and should have fitted comfortably. It did not, so the real face is wider than the sum
allowed.

`StampSizeFor` now steps the size down until the line actually fits, at a franker 0.68 ratio
with 40 pixels of clear space at each end. The longest title lands near 40 point and the
four shorter ones keep the full 44. **The width is added up rather than multiplied**,
because multiplying needs the character count as a float and Verse has no conversion to
hand.

### 153a. Half the screen each, and figures that cannot bleed. KAILEE'S RULING, 2026-09-08

Kai: *"the ladder should be on the leader board section, the right side of the screen, so
half the screen is the leaderboard and the other half is the rank ... and if the score is
big it bleeds into the other side of the screen, come up with a solution for me"*.

**The layout.** Scores centred in the left half at 0.27, ladder centred in the right half at
0.73, leaving a clear gutter down the middle rather than two columns leaning together.

**The bleed, and the solution is not clipping.** A clipped figure is a lie and a shrinking
one is unreadable. Instead the figure is never long: `Short` turns 1,234,567 into **1.2M**
and 45,600 into **45.6K**, so nothing on this screen runs past about six characters however
deep anyone gets. Nothing can reach across the gutter because nothing is long enough to.

It also reads better. A game show scoreboard says 1.2M; a bank statement says 1,234,567.
**`Commas` is still right for the debt counter**, where the whole joke is the number's absurd
length.

**Worked on the digits as text, not with division**, which is the same trick `Commas` uses
and is here for the same reason: every division in Verse can fail, and none is needed to
find where to cut a string of digits.

## 154. The ladder was built on a screen nobody has ever seen. 2026-09-08

Amendment 153 put the rank ladder on `StartScreenManager`'s record board. Kai went to wire
it up and could not find the device: *"cant find this. Click the Start Screen device in the
map"*, and then *"dnt see it"*.

**It is not in the map, and the log proves it.** The 2026-09-08 playtest never once says
"Start screen up" or "PLAY clicked", both of which that device logs, while `BroadcastScreen`
logs "back on the air" and everything else normally. No actor in `__ExternalActors__` carries
a single one of its settings either.

**Everything a contestant sees is the television:** the START SHOW card, the fine print, the
channels, the leaderboard, the prize vault and the debt counter. `StartScreenManager` is an
older screen doing the same job, and placing it now would put a second start screen on top of
the working one and have the two argue about when a match may begin.

### What moved

`RankLadder` is now `BroadcastScreen`'s, inside its leaderboard panel. The panel's body
became a horizontal box: the five scores on the left, `LadderGutter` of clear space, the
ladder on the right. No new wiring is needed, because that device already holds a
`CareerRank` reference for the rank titles beside each score.

`Short` stays where amendment 153a put it, at module scope in `StartScreenManager.verse`, so
it belongs to every file here. 400,000 prints as 400.0K and cannot grow across the gutter.

### A correction that should be recorded

**Amendment 139e renamed a line nobody can see.** "CAREER EARNINGS" became "ALL TIME
EARNINGS" on the start screen's board, and Kai was told the line sat above the PLAY button.
It does not, because that screen never appears. The reasoning for keeping it stands, but GDD
2.1 step 6's accumulating bankroll is **not currently displayed anywhere in the game.** That
is now an open question rather than a settled one.

The dead copy in `StartScreenManager` is left standing, with a warning over it, because the
module-scope run-gate functions at the top of that file are used by every device in the
project and cannot be separated from it today.
