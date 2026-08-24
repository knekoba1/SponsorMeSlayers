# CrateManager.verse
#
# GDD Section 3.2 "Color-Coded Paraglider Crates" -- the Gameplay Systems half of
# the crate handoff. Hears SpawnCrateEvent and puts a crate in the arena.
#
# WHY THIS IS SEPARATE FROM THE AUDIENCE. GDD Section 4's handoff table gives the
# Simulated Audience the "random-coordinate crate spawn parameters" and gives
# Gameplay Systems the machinery. GDD 4.1 makes the designer the only checkpoint
# between them. This file decides nothing about which crate falls or where; it is
# told, and it obeys. SimulatedAudience.verse can be replaced, stubbed or driven
# from fixed test data without a line of this file changing. DO NOT MERGE THEM.
#
# THE CRATE IS OURS, NOT FORTNITE'S. Kai's ruling 2026-08-22. This used to drive
# one Supply Drop Spawner per tier. Three things were wrong with that: the device
# lays a column of smoke on the floor that Kai found more distracting than the
# crate itself, its descent runs at Fortnite's speed and nothing exposes that
# speed, and its only colour comes from that same smoke, so killing the smoke
# would have killed GDD 3.2's tier colour coding with it.
#
# So a crate is now a prop this file spawns and lowers by hand, a step at a time,
# exactly the way DeathSaveManager lowers the Sponsor Aid turkey leg. The fall
# speed is a plain number, the smoke is gone, and the colour is ours.
#
# NOTHING WAS LOST BY DROPPING THE DEVICE. Its pickup was never used: collision
# here has always been measured as a distance from the landing spot, because this
# file chose that spot and already knows it. Its item list was already empty per
# amendment 26, because a supply drop hands over everything at once and is opened
# by holding a key, which broke GDD 3.2's "trigger instantly upon player
# collision to maintain momentum".
#
# TWO WAYS TO COLOUR A TIER, AND BOTH ARE SUPPORTED. TierCrateAssets can hold a
# differently coloured prop per tier, and TierGlows can put a coloured light on
# the floor beneath it. Fill in whichever the prop list actually allows. The glow
# alone is enough, and it is the half guaranteed to work, since a vfx creator's
# colours are set in the editor.
#
# THERE IS STILL NO PARAGLIDER MESH. GDD 3.2 asks for "high-contrast colored
# paragliders" and nothing in the prop list is one, so the descent itself is what
# reads as a parachute. The same compromise is already recorded for the turkey
# leg, which GDD 3.3 also calls "Parachuting".
#
# TEN SECONDS FROM LANDING. Kai's ruling 2026-08-18. Not from ordering: the
# parachute descent should not eat the window. Twenty was tried on paper and
# rejected, because at a 25-second trickle a 20-second crate is lying there four
# fifths of the time and stops being a prize. Ten puts one on the floor about 40%
# of the time, so crossing the arena for it is a decision you can fumble.
#
# NEWEST WINS. A new order of the same tier clears whatever that tier still has
# out, so ignoring one crate can never block every future crate of its grade.
#
# THE OLD SAME-TIER ARTEFACT IS GONE. While this drove devices it could only ask
# a spawner to destroy everything it had out, so a second crate of one tier
# inside ten seconds could be cleared early by the first one's timer. Each crate
# is now a prop this file holds a reference to, so a timer only ever clears its
# own.

using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /Fortnite.com/Input/Character }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Assets }
using { /Verse.org/Input }
using { /Verse.org/Random }
using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }

crate_manager := class(creative_device):

    # The Simulated Audience whose orders this file fills. The only thing it is
    # asked for is SpawnCrateEvent; nothing else about it is touched.
    @editable
    Audience : simulated_audience = simulated_audience{}

    # One crate prop per tier, in order: 0 Underdog, 1 Rising Star, 2 Superstar,
    # 3 Prime Time. If the prop list offers differently coloured crates, this is
    # where GDD 3.2's colour coding comes from. Fill entry 0 at minimum; a tier
    # with no entry of its own falls back to entry 0.
    @editable
    TierCrateAssets : []creative_prop_asset = array{}

    # One coloured glow per tier, same order, placed anywhere: this file moves it
    # onto the landing spot before the crate arrives, so the colour is readable
    # while the crate is still in the air. Leave a tier empty for no glow.
    @editable
    TierGlows : []vfx_creator_device = array{}

    # How high above the landing spot the crate appears, in centimetres.
    @editable
    DropHeight : float = 1500.0

    # How long the crate takes to come down, in seconds. Kai asked for this on
    # 2026-08-22, when Fortnite's own descent was too slow and its speed could not
    # be reached from anywhere. 1.5 is quick enough not to be a wait and slow
    # enough to read as a descent rather than a teleport.
    # 4.5, tuned by hand on 2026-08-22. 1.5 was too fast, and 3 still was once the
    # arc widened, because a wider arc needs longer to read as a drift.
    @editable
    DescentSeconds : float = 4.5

    # How often the crate is moved down a step during the descent, in seconds.
    @editable
    DescentStepSeconds : float = 0.05

    # How big the crate prop is, as a multiplier of the asset's own size.
    @editable
    CrateScale : float = 1.0

    # HOW HIGH THE CLOSED CRATE HANGS ABOVE THE FLOOR, IN CENTIMETRES.
    #
    # Kai's ruling 2026-08-23. A crate resting on the floor is shorter than the
    # height the contestant's gun fires at, so bullets sail over it and no shot
    # ever marks it. Every crate size big enough to be hit was too big to look
    # right. Hanging the closed crate at gun height fixes it from the other end:
    # the crate stays small and the bullets run into it for real.
    @editable
    HoverHeight : float = 100.0

    # One balloon per tier, in the same order as TierCrateAssets: 0 Underdog,
    # 1 Rising Star, 2 Superstar, 3 Prime Time.
    #
    # GDD 3.2 asks for "high-contrast colored paragliders" and nothing in the prop
    # list is one, checked by Kai on 2026-08-22, so a balloon stands in for it.
    # Fortnite's own supply drops use a balloon too, so it reads correctly even
    # though it is not what 3.2 says.
    #
    # A tier with no entry of its own falls back to entry 0, and an empty list
    # means the crate comes down on its own.
    @editable
    TierBalloonAssets : []creative_prop_asset = array{}

    # How far above the crate the balloon sits, in centimetres.
    @editable
    BalloonHeightAboveCrate : float = 200.0

    # How big the balloon is, as a multiplier of the asset's own size.
    @editable
    BalloonScale : float = 1.0

    # How far the crate drifts to the side as it comes down, in centimetres. The
    # drift tightens to nothing as it lands, so it always settles on the spot the
    # audience chose rather than near it.
    #
    # 350 rather than 90, tuned by hand on 2026-08-22. Kai wanted it dramatic, and
    # drama comes from the width of the arc rather than the number of turns: at 250
    # with 3 turns it read as frantic, and at 350 with 2 it reads as a lazy swing.
    @editable
    SwayRadius : float = 350.0

    # How many full turns that drift makes over the whole descent. Kai asked on
    # 2026-08-22 for it to float and swing rather than drop on a line, and a slow
    # spiral reads as both.
    #
    # 2, tuned by hand the same day. More turns over a fixed fall means faster
    # spinning, which reads as busy rather than dramatic, so this stays low and
    # SwayRadius carries the drama.
    @editable
    SwayTurns : float = 2.0

    # THE CRATE AND THE BALLOON ARE PAINTED SEPARATELY. Kai's ruling 2026-08-22:
    # the balloon carries the tier colour and the crate is left alone, so the
    # crate reads as one consistent object and only the thing above it changes.
    #
    # One material per tier in each list, same order: 0 Underdog, 1 Rising Star,
    # 2 Superstar, 3 Prime Time. A tier with no entry of its own falls back to
    # entry 0, and an empty list leaves that prop in its own colours, which is
    # what the crate list is for.
    #
    # A spawned prop's material can be set from code at all, found 2026-08-22.
    # Before that the tier colour had to come from a device's own effect, which is
    # what tied it to the smoke this file was rewritten to get rid of.
    #
    # SIMPLE COLORS IS WHERE THESE COME FROM. Kai found
    # /FortniteBaseMaterials/FortniteBase/SimpleColors on 2026-08-22, which holds
    # a flat and an emissive version of every colour. Flat is paint and goes dark
    # in a dark corner; emissive glows on its own and holds up whatever the arena
    # lighting does, which is why the brighter tiers use emissive.
    @editable
    TierCrateMaterials : []material = array{}

    @editable
    TierBalloonMaterials : []material = array{}

    # What each tier's crate turns into once it has been shot open, in the same
    # order as everything else: 0 Underdog, 1 Rising Star, 2 Superstar, 3 Prime
    # Time. A tier with no entry of its own falls back to entry 0.
    #
    # WHY THIS EXISTS. Amendment 65 has the player shoot a crate open, and the
    # first build changed nothing on screen when that happened. The crate looked
    # identical before and after, so the only moment the player could see was
    # the pickup, and shooting read as having done nothing at all. Kai reported
    # exactly that on 2026-08-22, repeatedly, and was right each time.
    #
    # Leave the list empty and the crate simply looks unchanged, as it did then.
    @editable
    TierOpenedMeshes : []mesh = array{}

    # One burst effect per tier, same order, played where the crate stands the
    # moment it is shot open. Kai's pick, 2026-08-22: a VFX Creator device set
    # to Upward Mesh Burst, which throws mesh pieces upward and reads as the
    # crate breaking apart without needing a broken-crate asset, since the mesh
    # library had nothing suitable and the prop pickers take a different type.
    #
    # Leave a tier empty for no burst. Set the device to play once rather than
    # loop, or it will keep bursting for as long as the crate sits there.
    @editable
    TierOpenBursts : []vfx_creator_device = array{}

    # How far the crate rolls onto its side when it is shot open, in degrees.
    # 90 lays it flat, 0 leaves it standing.
    #
    # OFF BY DEFAULT. This was the stopgap reveal while there was no art for
    # one. Kai played it on 2026-08-22 and disliked how it looked, and the
    # Upward Mesh Burst above replaced it. Kept rather than deleted because it
    # costs nothing and reads well enough if a burst is ever unavailable.
    @editable
    OpenedRollDegrees : float = 0.0

    # How far the crate sinks into the floor when it opens, in centimetres.
    #
    # WHY IT SINKS AT ALL. Kai wants the reward sitting on top of the opened
    # crate, 2026-08-23, and a solid upright crate puts anything on top of it
    # out of reach: Kai had to jump for a gun there. Tipping it flat solved that
    # and Kai disliked the look. There is no opened crate mesh to swap to, the
    # library having none, so sinking it is the substitute. It reads as burst
    # open, needs no art, and brings the top down to walking height.
    #
    # 40, tuned by Kai on 2026-08-23. 70 was set while the sink was never
    # actually visible on screen, and once it was, 70 buried too much of it.
    @editable
    OpenedSinkDepth : float = 40.0

    # How high above the landing spot a weapon rests, in centimetres. Low, so it
    # sits on the sunken crate and can be run into rather than jumped for.
    @editable
    WeaponRestHeight : float = 40.0

    # The pieces the crate breaks into. Entry 0 is used for all of them, so one
    # small wooden thing is enough. Leave empty for no debris.
    #
    # WHY REAL PROPS AND NOT AN EFFECT. Kai, 2026-08-23: the VFX device only
    # sprays one flat picture, so a soft circle reads as floating bubbles
    # whatever colour it is given, and it fought the coloured floor glow.
    # Fortnite's own wood-break effects belong to its destructible props and
    # cannot be fired from Verse. Objects that fly and fall are the only thing
    # that reads as breaking.
    @editable
    DebrisAssets : []creative_prop_asset = array{}

    # How many pieces fly out.
    @editable
    DebrisCount : int = 8

    # How big each piece is, as a multiplier of the asset's own size.
    @editable
    DebrisScale : float = 0.3

    # How far out a piece can travel, in centimetres. Each one takes a random
    # share of this so they do not land in a tidy ring.
    @editable
    DebrisReach : float = 200.0

    # How high a piece can arc, in centimetres, randomised the same way.
    @editable
    DebrisRise : float = 160.0

    # How long the flight lasts, in seconds.
    @editable
    DebrisFlightSeconds : float = 0.6

    # How many smooth moves the arc is made of. Two gave a straight climb and a
    # straight fall, which Kai spotted at once on 2026-08-23. Six reads as a
    # curve while each move is still interpolated by the engine, so it does not
    # stutter the way the cash drops do.
    @editable
    DebrisArcSegments : float = 6.0

    # How long a landed piece lies there before it is removed, in seconds.
    # Kept short: GDD 5.3 despawns expired visual FX and the prop ceiling is
    # about a hundred.
    #
    # 1.5, Kai 2026-08-23. 0.6 was gone before the eye caught it, and the GDD's
    # five-second cap on loose props leaves room for it.
    @editable
    DebrisRestSeconds : float = 1.5

    # One Item Granter per WEAPON, in the reward numbering: 0 SMG, 1 Shotgun,
    # 2 Sniper, 3 Rocket. These are the four granters already in the map, which
    # hold exactly one gun each.
    #
    # They used to be wired as one pool per tier and drawn from at random, which
    # no code has read since the reward became a decision made when the crate
    # opens. Same devices, honest name.
    #
    # Set Grant on Cycle to OFF on these, or the cycle grants as well as the
    # grant and the player gets two items.
    @editable
    GunGranters : []item_granter_device = array{}

    # ONE ITEM GRANTER PER WEAPON'S AMMO, in the same order as GunGranters:
    # 0 SMG, 1 Shotgun, 2 Sniper, 3 Rocket. Entry 0 is used for any weapon
    # without its own, so wiring a single generic ammo granter is enough to
    # start with.
    #
    # Kai's ruling 2026-08-23: a crate holding a gun you already have must hand
    # over ammo rather than a second copy. Playtest 2026-08-24 gave Kai two
    # shotguns. This matches GDD Section 4, where a duplicate refreshes what you
    # have instead of stacking.
    @editable
    AmmoGranters : []item_granter_device = array{}

    # One Item Spawner per weapon, in a fixed order: 0 SMG, 1 Shotgun, 2 Sniper,
    # 3 Rocket. Moved onto the crate as it breaks open and told to spawn, so the
    # real gun lies there and the player picks it up the ordinary Fortnite way.
    #
    # WHY THIS AND NOT A GRANTER PLUS A PROP. Kai, 2026-08-23: the thing on
    # display should be the gun itself. The prop list has no gun in it, checked
    # the same night, so a granter could only ever hand the weapon over
    # invisibly and a stand-in prop would have been a lie about what was there.
    # It also gives the weapon its own ammo, runs dry, and leaves the pistol as
    # the fallback, exactly as GDD 3.3 describes, with no code for any of it.
    #
    # IT ALSO CLOSES AMENDMENT 66 FOR FREE. Walking over a gun already held is
    # how Fortnite tops up its ammo, which is the ruling, with nothing written.
    #
    # THERE IS ONLY ONE WEAPON LIST. A WeaponGranters field sat above this for a
    # few hours as an unused fallback, and its name was close enough to this one
    # that Kai filled the wrong box on 2026-08-23. Deleted rather than kept.
    #
    # Amendment 38 sets which tiers each weapon can come from, and WeaponsForTier
    # below holds that table.
    @editable
    WeaponSpawners : []item_spawner_device = array{}

    # WHY GRANTERS AS WELL AS THE SPAWNERS. The spawners lay the real gun on
    # the crate, which is the display Kai asked for. Picking it up was left to
    # Fortnite's own run-over rule, and that failed repeatedly on 2026-08-23:
    # the gun rests inside a solid crate the contestant cannot stand in, so
    # there is often nothing to run over. Some guns could be reached and some
    # could not, which is exactly what Kai saw. The handover is GunGranters
    # above.
    #
    # GDD 2.1 step 4 says touching a crate instantly equips its contents, so
    # the pickup cannot be left to Fortnite. The cash drops already work this
    # way, by watching the distance in code, and this is the same thing.

    # What sits on an opened crate, one entry per reward, in this order:
    # 0 SMG, 1 Shotgun, 2 Sniper, 3 Rocket, 4 Sponsor Aid, 5 Sponsor Aegis,
    # 6 Icy Rounds, 7 Flaming Ammo. A missing entry simply shows nothing.
    @editable
    RewardProps : []creative_prop_asset = array{}

    # How high above the crate the reward sits, in centimetres.
    @editable
    RewardPropHeight : float = 120.0

    # How big it is, as a multiplier of its own size.
    @editable
    RewardPropScale : float = 0.5

    # Amendment 65: a crate lands closed and only the contestant's own shots
    # open it. One Prop Manipulator per tier, same order as everything else.
    #
    # WHY ONE EACH AND NOT ONE FOR THE ARENA. The device names who damaged a
    # prop but never which prop. A single arena-wide watcher therefore counted
    # any prop the contestant shot toward whatever crate was down, so a stray
    # bullet into a cash drop opened crates and one crate's hits opened its
    # neighbours. Kai rejected that outright on 2026-08-22: hit a crate and it
    # takes damage, hit nothing and nothing takes damage.
    #
    # WHY THE OBJECTIVE DEVICE AND NOT THE PROP MANIPULATOR. The manipulator
    # names who damaged a prop but never which prop, and its listening zone
    # stays where it was placed even when the device is moved, proved by
    # playtest 2026-08-22: "Watcher moved onto tier 0's crate" followed by
    # silence. An Objective device reports damage to itself alone, so it can
    # never confuse one crate with another.
    #
    # WHY THE BARS ARE GONE. Kai rejected this device once for dragging
    # Fortnite's health and shield display into the arena. Its own panel turns
    # all of it off. IN UEFN each one needs "Visible During Games" unticked,
    # both Badge Visibility options set to Off, and "Display Damage Numbers"
    # unticked. What is left is invisible, still solid, and still reports hits.
    #
    # A tier left unfilled never sees a hit, so its crates simply time out.
    @editable
    CrateBreakers : []objective_device = array{}

    # WHICH WAY A CRATE IS OPENED. Kai's ruling 2026-08-23.
    #
    # TRUE reads the contestant's own trigger and aim. FALSE goes back to the
    # breaker devices above, which are kept whole so this reverses with one tick.
    #
    # WHY THE BREAKERS LOST. An objective device is the only thing in UEFN that
    # reports who damaged it, and Fortnite's Guard hostiles mob it. Research on
    # 2026-08-23 found no way to stop that: Epic's documentation says a custom
    # Verse brain EXTENDS guard behaviour rather than replacing it, no character
    # modifier filters what is targeted, and another creator's attempt to make
    # NPCs deliberately attack an objective device failed as unsupported, which
    # points at the guards' obstacle reaction rather than a target choice.
    # Changing its team, its collision and its height all did nothing.
    #
    # Kai proved a bare crate is ignored completely the moment the breaker list
    # was emptied, so removing the object removes the problem.
    @editable
    OpenByAiming : logic = true

    # THE SPAWN PAD AND TEAM SETTINGS DEVICES, ONLY SO A RESPAWN CAN BE HEARD.
    #
    # Kai's playtest 2026-08-23: two crates opened normally, then Kai was
    # eliminated twice, and after that not one shot registered for the rest of
    # the run, with no rejection logged either. fort_playspace has no respawn
    # event and PlayerAddedEvent does not fire on one. StartingLoadoutManager
    # already solved exactly this by listening to these two devices, so this
    # listens to the same pair. Wire them to the same devices it uses.
    @editable
    SpawnPad : player_spawner_device = player_spawner_device{}

    @editable
    TeamSettings : team_settings_and_inventory_device = team_settings_and_inventory_device{}

    # The hostile spawners, so a hostile standing in front of a crate can block
    # the shot. Kai, 2026-08-23: they crowd a crate, so shooting one of them
    # must not open it. Leave empty and nothing ever blocks.
    @editable
    HostileSpawners : []npc_spawner_device = array{}

    # How close the contestant must be for a shot to count, in centimetres.
    # 3000, raised by Kai on 2026-08-23. 1000 was under half the arena's
    # length, so a crate across the room could not be shot at all.
    @editable
    AimRange : float = 3000.0

    # How far off dead-on the aim may be, in degrees.
    # 90, Kai 2026-08-23, so the crate only has to be in the half of the world
    # you are facing. 25 demanded near-perfect aim while being swarmed.
    @editable
    AimToleranceDegrees : float = 90.0

    # How near the line of fire a hostile must be to block it, in centimetres.
    # 0, which switches blocking off entirely, Kai 2026-08-23. At 150 the
    # hostiles crowding the contestant ate nearly every shot, and now that the
    # crate hangs at gun height Fortnite already decides whether a bullet
    # reaches it. A shot that visibly hit but did not count was the worse error.
    @editable
    AimBlockRadius : float = 0.0

    # How far above the landing spot the breaker sits, in centimetres.
    #
    # The crate is solid, so a bullet stops on it before reaching anything
    # inside. Playtest 2026-08-22: four or five point blank shots, nothing
    # registered. Raise this until the breaker's own collision catches the
    # shots instead of the crate swallowing them.
    @editable
    BreakerZOffset : float = 0.0

    # How far below the arena the breaker is parked once its crate is done,
    # in centimetres. It is invisible but still solid, so leaving it standing
    # on the crate would block the player from walking in to collect it.
    @editable
    BreakerParkDepth : float = 5000.0

    # How many of the contestant's hits open a crate. Kai's ruling 2026-08-22.
    # Counted as hits, not damage, so the number holds whatever weapon is held.
    #
    # ONE, Kai 2026-08-23, and it has to be. This counts trigger PRESSES, not
    # bullets: the engine gives no per-bullet event at all. On an automatic
    # weapon one press sprays a dozen rounds and still counts once, so two
    # meant releasing and pressing again, which read as the crate ignoring you.
    @editable
    ShotsToOpen : int = 1

    # Whether a shot that failed to count says why in the log. Noisy on
    # purpose, and meant to be switched off once the cause is understood.
    @editable
    LogRejectedShots : logic = true

    # Whether the crate prop can be damaged at all.
    #
    # TRUE, and it has to be. A prop that takes no damage produces no damage
    # events, and those events are now the only way the crate knows it was
    # shot. Kai's ruling that hostiles cannot break a crate is delivered
    # instead by healing the props back after every single hit, below.
    @editable
    CrateTakesDamage : logic = false

    # Prop hits the contestant has landed on each tier's crate, counted by a
    # standing subscription rather than a loop.
    #
    # WHY A STANDING SUBSCRIPTION. The first version awaited one signal at a
    # time and re-armed after each, so anything fired during the re-arm was
    # lost. Playtest 2026-08-22: four or five point blank shots, one counted.
    var TierHits : []int = array{0, 0, 0, 0}

    # How long a landed crate waits to be collected, in seconds. Kai's ruling
    # 2026-08-18. See the header for why it is not 20.
    @editable
    CrateLifeSeconds : float = 10.0

    # How close the player has to get, in centimetres. GDD 3.2 wants contact, and
    # a crate is a large object, so this stays forgiving: a pickup that needs
    # precision would fight 3.2's "to maintain momentum".
    #
    # 150, down from 250. Kai, 2026-08-23: two and a half metres grabbed from
    # far enough away that it did not read as reaching the crate at all. Now
    # that the weapon is handed over on this radius rather than run over, the
    # number is what sells the walk-in, so it wants to be about a body's length.
    @editable
    PickupRadius : float = 150.0

    # How often the player's distance to a live crate is checked, in seconds.
    @editable
    PollSeconds : float = 0.1

    # The chance, 0 to 1, that a crate of this tier heals instead of granting an
    # item. Indexed by tier, 0 Underdog to 3 Prime Time. Amendment 38 puts
    # Sponsor Aid in the Rising Star and Superstar pools only, as one entry of
    # three in each, so both are a third and the other two are zero.
    @editable
    TierHealChance : []float = array{0.0, 0.33, 0.33, 0.0}

    # GDD 3.3: Sponsor Aid "restores 25% of the contestant's maximum health pool
    # immediately upon collision pickup". A fraction rather than a number,
    # because Island Settings owns Max Health and currently has it at 200.
    @editable
    HealFraction : float = 0.25

    # The green burst that makes the heal visible. Its two colours are the
    # palette's Heal Green #39FF88 over #1BA85A, amendment 62. Its own device rather than
    # the Death Save's SponsorAidGlow, so a heal during a Death Save cannot
    # switch that one off.
    @editable
    HealGlow : vfx_creator_device = vfx_creator_device{}

    # How long the burst stays up, in seconds.
    @editable
    HealGlowSeconds : float = 1.0

    @editable
    HealSound : audio_player_device = audio_player_device{}

    # The chance, 0 to 1, that a crate of this tier hands over the Sponsor Aegis.
    # Superstar's pool is Sniper, Aegis, Sponsor Aid, so a third. Prime Time's is
    # Aegis, Flaming Ammo, Icy Rounds and the Rocket Launcher of amendment 39, so
    # a quarter. Amendment 38.
    @editable
    TierAegisChance : []float = array{0.0, 0.0, 0.33, 0.25}

    # GDD 3.3 gives the Aegis "up to 3 hostile hits". Enemy damage was measured
    # at exactly 20 a hit, so 60 shield is exactly three. Amendment 41. Island
    # Settings has Max Shields at 100, checked 2026-08-19, so 60 fits under it.
    @editable
    AegisShieldPoints : float = 60.0

    # The pink bubble of GDD 3.3, in the palette's reserved Sponsor Pink #FF2D95,
    # amendment 62.
    # ITS "STICK TO PLAYER" SETTING MUST BE ON, or it will not follow the player
    # and Begin(Agent) will do nothing.
    @editable
    AegisGlow : vfx_creator_device = vfx_creator_device{}

    @editable
    AegisSound : audio_player_device = audio_player_device{}

    # The ammo modifier manager, which owns what Icy Rounds and Flaming Ammo do
    # once handed over. This file only ever tells it one has been collected.
    @editable
    AmmoModifiers : ammo_modifier_manager = ammo_modifier_manager{}

    # The chance, 0 to 1, that a crate of this tier hands over Icy Rounds. Prime
    # Time only, one entry of four alongside the Aegis, Flaming Ammo and the
    # Rocket Launcher. Amendments 38 and 39.
    @editable
    TierIcyChance : []float = array{0.0, 0.0, 0.0, 0.25}

    # The same for Flaming Ammo, the fourth Prime Time entry. With the Aegis and
    # Icy Rounds each on a quarter, the remaining quarter falls through to the
    # granter and its Rocket Launcher.
    @editable
    TierFlamingChance : []float = array{0.0, 0.0, 0.0, 0.25}

    # One full turn in radians, for the descent's spiral.
    FullCircleRadians : float = 6.2831853

    # Whether a bubble is already up, so a second Aegis refills the shield
    # instead of starting a second watcher against the same one.
    var AegisWatching : logic = false

    # The crate each tier currently has in the arena, so a new order of one tier
    # clears only that tier's crate and an expiry timer only ever clears its own.
    var LiveCrates : []?creative_prop = array{false, false, false, false}

    # Which tiers have a crate still on its way down.
    var TierDescending : []logic = array{false, false, false, false}

    # What each tier's crate has been decided to hold, by the reward numbering
    # above, or -1 for undecided. Set the moment a crate is shot open, so what
    # is shown and what is handed over can never disagree.
    var TierReward : []int = array{-1, -1, -1, -1}

    # The prop currently sitting on each tier's opened crate.
    var ShownRewards : []?creative_prop = array{false, false, false, false}

    # Contestants already subscribed, so a respawn re-adds the input mapping
    # without subscribing a second time and counting every shot twice.
    var ArmedTriggers : [player]logic = map{}

    # Which weapons have already been handed over this life. Cleared on respawn,
    # since dying empties the inventory and every gun is new again after it.
    var GrantedWeapons : []logic = array{false, false, false, false}

    OnBegin<override>()<suspends>:void =
        Print("DEBUG: Crate Manager listening -- {TierCrateAssets.Length} crate prop(s), {TierGlows.Length} glow(s), {WeaponSpawners.Length} weapon spawner(s), {CrateBreakers.Length} breaker(s)")

        # Subscribed once and left alone, so no shot can slip through a gap.
        if (B0 := CrateBreakers[0]):
            B0.DamagedEvent().Subscribe(OnTier0Damaged)
        if (B1 := CrateBreakers[1]):
            B1.DamagedEvent().Subscribe(OnTier1Damaged)
        if (B2 := CrateBreakers[2]):
            B2.DamagedEvent().Subscribe(OnTier2Damaged)
        if (B3 := CrateBreakers[3]):
            B3.DamagedEvent().Subscribe(OnTier3Damaged)

        if (CrateBreakers.Length < 1):
            Print("WARNING: Crate Manager has no breakers, so no crate can be opened and every one will time out. Fill CrateBreakers.")

        if (OpenByAiming?):
            SpawnPad.SpawnedEvent.Subscribe(OnAgentSpawned)
            TeamSettings.TeamMemberSpawnedEvent.Subscribe(OnAgentSpawned)

            # The breakers are dead weight on this route, and they are
            # objective devices: shootable, damageable, and the strongest NPC
            # magnet in the arena. Nothing moved them until a crate finished
            # its cycle, so tier 0's stood in the open for thirteen minutes of
            # the 2026-08-23 session. Sent underground before the first wave.
            for (Tier := 0..3):
                if (Breaker := CrateBreakers[Tier]):
                    Standing := Breaker.GetTransform().Translation
                    Below := vector3{X := Standing.X, Y := Standing.Y, Z := Standing.Z - BreakerParkDepth}
                    if (Breaker.TeleportTo[Below, IdentityRotation()]):
                        Print("DEBUG: Breaker for tier {Tier} sent underground at match start.")
                    else:
                        Print("WARNING: Crate -- the breaker for tier {Tier} would not move at match start, so it is still standing in the arena.")

            Playspace := GetPlayspace()
            Playspace.PlayerAddedEvent().Subscribe(ArmTrigger)
            for (Contestant : Playspace.GetPlayers()):
                ArmTrigger(Contestant)

        if (TierCrateAssets.Length < 1):
            Print("WARNING: Crate Manager has no crate prop at all, so every order will be dropped with a warning. Fill TierCrateAssets with at least entry 0.")

        loop:
            Order := Audience.SpawnCrateEvent.Await()
            # Spawned so a long-lived crate never holds up the next order. The
            # audience is not made to wait on the arena.
            spawn{ RunCrate(Order) }

    # One crate, from order to gone.
    RunCrate(Order : crate_order)<suspends>:void =
        # CHURN GUARD. Playtest 2026-08-23: two Prime Time orders 0.365 seconds
        # apart, the second killing the first mid-fall, which read to Kai as a
        # crate vanishing and reappearing. Newest wins is about an IGNORED crate
        # never blocking future ones, not about replacing one nobody has seen.
        if (Falling := TierDescending[Order.Tier], Falling?):
            Print("DEBUG: Crate -- tier {Order.Tier} is already on its way down, so this order is dropped.")
            return

        # THE SAME GUARD FOR A CRATE ALREADY ON THE GROUND. Playtest 2026-08-24:
        # tier 1's crate was open, its Sponsor Aid decided, and Kai was walking
        # to it when a trickle order for tier 1 arrived and deleted it. A crate
        # that has been shot open has been paid for, and is never taken away to
        # make room for another. The block clears itself: the crate is gone
        # within CrateLifeSeconds whether it is collected or times out.
        if (Standing := LiveCrates[Order.Tier]?, Standing.IsValid[]):
            Print("DEBUG: Crate -- tier {Order.Tier} still has a crate waiting to be collected, so this order is dropped.")
            return

        SetDescending(Order.Tier, true)

        # Newest wins. See the header.
        ClearTier(Order.Tier)

        if (Asset := AssetFor(Order.Tier)?):
            AirLocation := vector3:
                X := Order.LandingSpot.X
                Y := Order.LandingSpot.Y
                Z := Order.LandingSpot.Z + DropHeight
            ScaleVector := vector3{X := CrateScale, Y := CrateScale, Z := CrateScale}
            SpawnTransform := transform{Translation := AirLocation, Rotation := IdentityRotation(), Scale := ScaleVector}
            SpawnResult := SpawnProp(Asset, SpawnTransform)
            if (Crate := SpawnResult(0)?):
                RememberCrate(Order.Tier, option{Crate})

                # Kai's ruling 2026-08-22: a hostile cannot break a crate. The
                # breaker already discards hostile hits, but the crate PROP was
                # still destructible in its own right and hostiles went for it.
                # Playtest 2026-08-22: a crate landed at 02:49:07, hostiles hit
                # it three times inside the next second and it was gone, which
                # AwaitCrateGone then misread as the crate having been replaced.
                set Crate.CanBeDamaged = CrateTakesDamage

                # The tier colour, forced onto the prop rather than borrowed.
                # Empty by Kai's ruling: only the balloon is painted.
                if (Paint := MaterialFrom(TierCrateMaterials, Order.Tier)?):
                    Crate.SetMaterial(Paint)

                Print("DEBUG: Crate ordered -- tier {Order.Tier} falling to X={Order.LandingSpot.X} Y={Order.LandingSpot.Y}")

                # The balloon exists only for the descent and is removed the
                # moment the crate is down.
                var Balloon : ?creative_prop = false
                BalloonScaleVector := vector3{X := BalloonScale, Y := BalloonScale, Z := BalloonScale}
                BalloonStart := vector3:
                    X := AirLocation.X
                    Y := AirLocation.Y
                    Z := AirLocation.Z + BalloonHeightAboveCrate
                BalloonTransform := transform{Translation := BalloonStart, Rotation := IdentityRotation(), Scale := BalloonScaleVector}
                if (BalloonAsset := BalloonFor(Order.Tier)?):
                    BalloonResult := SpawnProp(BalloonAsset, BalloonTransform)
                    if (Lifted := BalloonResult(0)?):
                        set Balloon = option{Lifted}
                        if (Paint := MaterialFrom(TierBalloonMaterials, Order.Tier)?):
                            Lifted.SetMaterial(Paint)
                    else:
                        Print("DEBUG: Crate -- balloon would not spawn, so the crate comes down on its own.")
                else:
                    Print("DEBUG: Crate -- no balloon filled in for tier {Order.Tier}, so the crate comes down on its own.")

                # The glow marks the spot while the crate is still in the air, so
                # the colour is readable before the player commits to the walk.
                StartGlow(Order.Tier, Order.LandingSpot)

                Landed := LowerCrate(Crate, Balloon, Order.LandingSpot)

                # Down, one way or another. Cleared here rather than on each
                # exit below, so no path leaves a tier marked as falling.
                SetDescending(Order.Tier, false)
                if (not Landed?):
                    # A newer crate of this tier replaced this one mid-descent.
                    # Stopping here is the whole point: carrying on would announce
                    # a landing, run a window and finally delete the crate that
                    # replaced it.
                    Print("DEBUG: Crate -- tier {Order.Tier} replaced mid-descent, this one stops here.")
                    StopGlowIfOrphaned(Order.Tier)
                    return

                Print("DEBUG: Crate landed -- tier {Order.Tier}. {CrateLifeSeconds}s to reach it.")

                var Collected : logic = false
                var Replaced : logic = false
                race:
                    block:
                        AwaitCrateShotOpen(Order.Tier, Order.LandingSpot)
                        DecideReward(Order.Tier)
                        PopBalloon(Balloon)
                        ShowOpened(Crate, Order.Tier, Order.LandingSpot)
                        ShowReward(Order.Tier, Order.LandingSpot)
                        BurstDebris(Order.LandingSpot)
                        AwaitPlayerReaching(Order)
                        set Collected = true
                    block:
                        Sleep(CrateLifeSeconds)
                    block:
                        # The same guard for the waiting half: a crate can be
                        # replaced after it lands as easily as before.
                        AwaitCrateGone(Crate)
                        set Replaced = true

                # However this crate ended, its breaker stops standing there.
                ParkBreaker(Order.Tier, Order.LandingSpot)
                ClearShown(Order.Tier)

                # And its balloon goes, however it ended. Harmless if the
                # opening already popped it.
                PopBalloon(Balloon)

                if (Replaced?):
                    Print("DEBUG: Crate -- tier {Order.Tier} replaced while waiting, this one stops here.")
                    ForgetReward(Order.Tier)
                    StopGlowIfOrphaned(Order.Tier)
                    return

                if (Collected?):
                    GrantTier(Order.Tier)
                else:
                    Print("DEBUG: Crate expired uncollected -- tier {Order.Tier}")

                ForgetReward(Order.Tier)
                ClearTier(Order.Tier)
            else:
                Print("WARNING: Crate -- tier {Order.Tier} prop could not be spawned, so no crate fell. Check the asset filled into TierCrateAssets.")
                SetDescending(Order.Tier, false)
        else:
            Print("WARNING: Crate -- no prop for tier {Order.Tier} and no entry 0 to fall back on, so this order was dropped. Fill TierCrateAssets.")
            SetDescending(Order.Tier, false)

    # The crate asset for a tier, falling back to entry 0, so one filled entry is
    # enough to get crates falling at every tier.
    AssetFor(Tier : int)<transacts>:?creative_prop_asset =
        var Result : ?creative_prop_asset = false
        if (Asset := TierCrateAssets[Tier]):
            set Result = option{Asset}
        else if (Fallback := TierCrateAssets[0]):
            set Result = option{Fallback}
        Result

    # Lowers the crate from DropHeight onto the floor. Drawn by hand the same way
    # DeathSaveManager lowers the turkey leg: no engine physics is involved, the
    # prop is simply teleported a little further down each step.
    # Returns once this crate has been taken out from under us, which is how a
    # replaced task learns to stop instead of finishing someone else's crate.
    AwaitCrateGone(Crate : creative_prop)<suspends>:void =
        loop:
            Sleep(PollSeconds)
            if (not Crate.IsValid[]):
                return

    # True if the crate reached the floor, false if it was disposed on the way
    # down, which means a newer crate of its tier has taken its place.
    LowerCrate(Crate : creative_prop, Balloon : ?creative_prop, LandingSpot : vector3)<suspends>:logic =
        var Elapsed : float = 0.0
        var BalloonSteps : int = 0
        loop:
            Sleep(DescentStepSeconds)
            set Elapsed += DescentStepSeconds

            if (Crate.IsValid[]):
                Progress := if (Elapsed >= DescentSeconds) then 1.0 else Elapsed / DescentSeconds
                Remaining := 1.0 - Progress
                Height := LandingSpot.Z + HoverHeight + DropHeight * Remaining

                # The spiral. Drift shrinks with Remaining, so the last step lands
                # on the landing spot exactly and nothing has to correct for it.
                Angle := SwayTurns * FullCircleRadians * Progress
                Drift := SwayRadius * Remaining
                DriftX := LandingSpot.X + Cos(Angle) * Drift
                DriftY := LandingSpot.Y + Sin(Angle) * Drift
                Target := vector3{X := DriftX, Y := DriftY, Z := Height}

                if (Crate.TeleportTo[Target, IdentityRotation()]):
                    # The balloon follows the crate down the same spiral. A
                    # refused move is ignored: the crate is what matters.
                    if (Held := Balloon?):
                        BalloonTarget := vector3{X := DriftX, Y := DriftY, Z := Height + BalloonHeightAboveCrate}
                        if:
                            Held.IsValid[]
                            Held.TeleportTo[BalloonTarget, IdentityRotation()]
                        then:
                            set BalloonSteps += 1

                    if (Remaining <= 0.0):
                        # The balloon STAYS. It is what holds the crate up at
                        # gun height, and it pops when the crate is shot open.
                        return true
                else:
                    Print("DEBUG: Crate -- descent stopped early, it rests where it stopped")
                    PopBalloon(Balloon)
                    return true
            else:
                PopBalloon(Balloon)
                return false

    # The balloon only exists for the descent, so it goes the moment the crate is
    # down or the descent ends for any other reason. Nothing pops on screen; it
    # simply disappears as the crate settles.
    PopBalloon(Balloon : ?creative_prop):void =
        if:
            Held := Balloon?
            Held.IsValid[]
        then:
            Held.Dispose()

    # The balloon for a tier, falling back to entry 0 the same way the crate does.
    BalloonFor(Tier : int)<transacts>:?creative_prop_asset =
        var Result : ?creative_prop_asset = false
        if (Asset := TierBalloonAssets[Tier]):
            set Result = option{Asset}
        else if (Fallback := TierBalloonAssets[0]):
            set Result = option{Fallback}
        Result

    # The material for a tier out of whichever list is handed in, falling back to
    # entry 0 the same way the crate and balloon assets do. One function for both
    # lists, so the two can never drift apart in how they behave.
    MaterialFrom(Materials : []material, Tier : int)<transacts>:?material =
        var Result : ?material = false
        if (Paint := Materials[Tier]):
            set Result = option{Paint}
        else if (Fallback := Materials[0]):
            set Result = option{Fallback}
        Result

    # The crate visibly breaks open. This is the whole point of amendment 65:
    # the player is meant to see what is inside before deciding to take it.
    ShowOpened(Crate : creative_prop, Tier : int, Spot : vector3):void =
        if (Crate.IsValid[]):
            # The mesh swap, if one was ever filled in. Optional, and empty on
            # 2026-08-22 because the library had nothing suitable.
            if (Opened := MeshFrom(TierOpenedMeshes, Tier)?):
                Crate.SetMesh(Opened)
                Print("DEBUG: Crate for tier {Tier} swapped to its opened look.")

            # The tip-over, which is what the player actually sees. Its own
            # position is read back rather than assumed, so a crate whose
            # descent stopped early is knocked over where it stands.
            Where := Crate.GetTransform().Translation

            # X and Y are read back so a crate whose descent stopped early
            # breaks where it stands. Z comes from the landing spot, because the
            # closed crate is hanging at HoverHeight and sinking from up there
            # would leave it floating.
            Ground := vector3{X := Where.X, Y := Where.Y, Z := Spot.Z}

            # The drop, the sink and the tip-over in ONE move. They used to be
            # two teleports, the second of which put the crate straight back up
            # to where it started, so the sink has never once been seen on
            # screen. Found 2026-08-23.
            Sunk := vector3{X := Ground.X, Y := Ground.Y, Z := Ground.Z - OpenedSinkDepth}
            Tipped := MakeRotationFromYawPitchRollDegrees(0.0, 0.0, OpenedRollDegrees)
            if (Crate.TeleportTo[Sunk, Tipped]):
                Print("DEBUG: Tier {Tier}'s crate dropped to the floor and sank {OpenedSinkDepth}.")
            else:
                Print("DEBUG: Crate for tier {Tier} would not drop.")

            # The reveal itself, on the floor rather than up where it hung.
            if (Burst := TierOpenBursts[Tier]):
                if (Burst.TeleportTo[Ground, IdentityRotation()]):
                    Burst.Begin()
                    Print("DEBUG: Open burst played for tier {Tier}.")

    # The crate breaking into pieces. Each one is launched on its own so they
    # all fly at once rather than one after another, and this returns straight
    # away so the walk-in is never held up.
    BurstDebris(Spot : vector3)<suspends>:void =
        if (Asset := DebrisAssets[0]):
            var Made : int = 0
            loop:
                if (Made >= DebrisCount):
                    break
                Angle := GetRandomFloat(0.0, FullCircleRadians)
                spawn{ FlyPiece(Asset, Spot, Angle) }
                set Made += 1
        else:
            Print("DEBUG: Crate has no debris asset filled in, so it breaks with no pieces. Fill DebrisAssets.")

    # One piece, flown along a parabola by hand and removed at the end. The
    # height term peaks halfway and returns to the floor exactly at the finish,
    # so nothing has to correct for where it lands.
    FlyPiece(Asset : creative_prop_asset, Spot : vector3, Angle : float)<suspends>:void =
        ScaleVector := vector3{X := DebrisScale, Y := DebrisScale, Z := DebrisScale}
        Start := transform{Translation := Spot, Rotation := IdentityRotation(), Scale := ScaleVector}
        Result := SpawnProp(Asset, Start)

        if (Piece := Result(0)?):
            Reach := GetRandomFloat(DebrisReach * 0.4, DebrisReach)
            Rise := GetRandomFloat(DebrisRise * 0.4, DebrisRise)

            # Smooth moves along the curve rather than hops. MoveTo is
            # interpolated by the engine, so it flows instead of stuttering the
            # way the cash drops do, and it begins at once. The height term
            # peaks halfway and returns to the floor exactly at the finish, so
            # a piece always lands level with where it started.
            Step := if (DebrisArcSegments >= 1.0) then 1.0 / DebrisArcSegments else 1.0
            var Progress : float = 0.0
            loop:
                set Progress += Step
                if (Progress > 1.0):
                    set Progress = 1.0

                At := vector3:
                    X := Spot.X + Cos(Angle) * Reach * Progress
                    Y := Spot.Y + Sin(Angle) * Reach * Progress
                    Z := Spot.Z + Rise * 4.0 * Progress * (1.0 - Progress)

                # A fresh random rotation each leg, so a piece tumbles as it
                # goes rather than sliding through the air facing one way.
                Tumble := MakeRotationFromYawPitchRollDegrees(GetRandomFloat(0.0, 360.0), GetRandomFloat(0.0, 360.0), GetRandomFloat(0.0, 360.0))
                Moved := Piece.MoveTo(At, Tumble, DebrisFlightSeconds * Step)

                if (Progress >= 1.0):
                    break

            Sleep(DebrisRestSeconds)

            if (Piece.IsValid[]):
                Piece.Dispose()

    # The opened look for a tier, falling back to entry 0 exactly as the
    # materials and the crate assets do.
    MeshFrom(Meshes : []mesh, Tier : int)<transacts>:?mesh =
        var Result : ?mesh = false
        if (Shape := Meshes[Tier]):
            set Result = option{Shape}
        else if (Fallback := Meshes[0]):
            set Result = option{Fallback}
        Result

    # Switches a tier's glow off, but only when nothing has taken that tier
    # over. Both replacement paths return early and never reach ClearTier, which
    # is what left a glow burning on an empty floor. Kai saw it on 2026-08-23
    # after hostiles destroyed a crate. It cannot simply call StopGlow, because
    # on a genuine replacement the successor has already started its own glow
    # and the crate it replaced would put it straight back out.
    StopGlowIfOrphaned(Tier : int):void =
        if:
            not LiveCrates[Tier]?
        then:
            StopGlow(Tier)
            Print("DEBUG: Crate -- tier {Tier} left nothing behind, so its glow is out.")

    # Puts this tier's glow on the landing spot and starts it. A tier with no glow
    # filled in simply gets none.
    StartGlow(Tier : int, Spot : vector3):void =
        if (Glow := TierGlows[Tier]):
            if (Glow.TeleportTo[Spot, IdentityRotation()]):
                Glow.Begin()
            else:
                Print("WARNING: Crate -- tier {Tier} glow refused to move to the landing spot, so no glow. This is the line that identifies the disposed-object error.")
        else:
            Print("DEBUG: Crate -- no glow filled in for tier {Tier}.")

    # Turns this tier's glow off.
    StopGlow(Tier : int):void =
        if (Glow := TierGlows[Tier]):
            Glow.End()

    # Removes whatever crate this tier has in the arena and turns its glow off.
    ClearTier(Tier : int):void =
        if:
            Held := LiveCrates[Tier]?
            Held.IsValid[]
        then:
            Held.Dispose()
        RememberCrate(Tier, false)
        StopGlow(Tier)

    # Records which crate a tier is holding. Rebuilt rather than assigned into by
    # index, which is the form the other managers use for arrays.
    RememberCrate(Tier : int, Crate : ?creative_prop):void =
        var Rebuilt : []?creative_prop = array{}
        for (Index -> Existing : LiveCrates):
            if (Index = Tier):
                set Rebuilt += array{Crate}
            else:
                set Rebuilt += array{Existing}
        set LiveCrates = Rebuilt

    # Amendment 65. Returns once the contestant has shot this tier's crate open.
    #
    # It never returns on its own if nobody shoots. That is deliberate and safe:
    # the caller runs this inside a race against the crate's own lifetime, so an
    # unshot crate simply times out the way an uncollected one always has.
    #
    # WHY EVERY HIT HEALS THE PROPS. Kai's ruling is that a hostile cannot break
    # a crate. Undoing the damage the instant it lands delivers that for hostile
    # fire and Swarmer melee alike, and it does so without needing to know which
    # prop was hit, which this device does not tell us.
    #
    # KNOWN IMPRECISION, RECORDED RATHER THAN HIDDEN. The device names the agent
    # but not the prop, so any prop the contestant damages inside the zone
    # counts toward the crate in front of them. Cash drops are props and litter
    # the floor. Not yet solved.
    AwaitCrateShotOpen(Tier : int, Spot : vector3)<suspends>:void =
        # Park this tier's watcher on its crate, so anything it reports from
        # here is that crate and nothing else.
        # The breaker is only moved into place on the old route. On the aiming
        # route nothing shootable goes into the arena at all, which is the whole
        # point of it.
        OnSpot := vector3{X := Spot.X, Y := Spot.Y, Z := Spot.Z + BreakerZOffset}
        if (not OpenByAiming?, Breaker := CrateBreakers[Tier]):
            Breaker.SetHealth(Breaker.GetMaxHealth())
            if (Breaker.TeleportTo[OnSpot, IdentityRotation()]):
                Print("DEBUG: Breaker moved onto tier {Tier}'s crate.")
            else:
                Print("WARNING: Crate -- the breaker for tier {Tier} would not move, so this crate cannot be opened.")

        # Each crate starts from zero. This used to keep a running total per
        # tier and remember where the last crate finished, so every crate
        # silently needed two more than the total before it, and shots fired
        # during the descent inflated it further. Kai hit exactly that on
        # 2026-08-23: a crate that was one shot away read as unbreakable.
        if (set TierHits[Tier] = 0):
            Print("DEBUG: Tier {Tier}'s crate is down and needs {ShotsToOpen} shots.")

        loop:
            Sleep(PollSeconds)
            if (HitsFor(Tier) >= ShotsToOpen):
                break

        Print("DEBUG: Crate SHOT OPEN -- tier {Tier}")

    # Sends a tier's breaker underground. Invisible is not the same as absent:
    # it keeps its collision, so one left standing on an open crate would block
    # the walk in that collects it.
    ParkBreaker(Tier : int, Spot : vector3):void =
        if (Breaker := CrateBreakers[Tier]):
            Below := vector3{X := Spot.X, Y := Spot.Y, Z := Spot.Z - BreakerParkDepth}
            if (Breaker.TeleportTo[Below, IdentityRotation()]):
                Print("DEBUG: Breaker for tier {Tier} parked out of the way.")

    # Starts listening to one contestant's fire button. The mapping has to be
    # added or the action never reports anything, per the input documentation.
    ArmTrigger(Contestant : player):void =
        if (Input := GetPlayerInput[Contestant]):
            # Re-added after every respawn: Fortnite rebuilds the character and
            # the fire action stops reporting without the mapping back in place.
            Input.AddInputMapping(RangedWeaponMapping)

            if (ArmedTriggers[Contestant]?):
                Print("DEBUG: Crate -- contestant respawned, their fire mapping is back.")
            else:
                Input.GetInputEvents(WeaponPrimary).TriggerActivationEvent.Subscribe(OnTriggerPulled)
                if (set ArmedTriggers[Contestant] = true):
                    Print("DEBUG: Crate -- watching the contestant's trigger.")
        else:
            Print("WARNING: Crate -- could not read the contestant's input, so no crate can be shot open.")

    # A contestant has spawned or respawned, so their fire button is heard again.
    OnAgentSpawned(Spawned : agent):void =
        if (Contestant := player[Spawned]):
            ArmTrigger(Contestant)

            # A respawn empties the inventory, so what has been handed over is
            # no longer true and every weapon counts as new again.
            set GrantedWeapons = array{false, false, false, false}
            Print("DEBUG: Crate -- contestant respawned, so every weapon counts as new again.")

    # One press of the fire button. Counts against the nearest live crate the
    # contestant had a clear line to, and nothing otherwise.
    OnTriggerPulled(Fired : tuple(player, logic)):void =
        Contestant := Fired(0)
        if:
            Character := Contestant.GetFortCharacter[]
            Character.IsActive[]
        then:
            From := Character.GetTransform().Translation
            YawRadians := BodyYawRadians(Character)

            # Where the body is pointing, flattened to the floor. Height is
            # ignored on purpose: GDD 1.1's camera looks straight down and
            # everything of interest sits on the floor.
            ForwardX := Cos(YawRadians)
            ForwardY := Sin(YawRadians)

            # Dead-on is an alignment of 1, and the tolerance converts to the
            # smallest alignment that still counts. No inverse trig needed.
            Needed := Cos(AimToleranceDegrees * (FullCircleRadians / 360.0))

            var BestTier : int = -1
            var BestGap : float = AimRange + 1.0

            # WHY A SHOT WAS THROWN AWAY, FOR THE LOG ONLY. Kai 2026-08-23:
            # shots kept being dropped and nothing said which check rejected
            # them, so every playtest was a guess between range, aim and being
            # blocked by a hostile.
            var NearestTier : int = -1
            var NearestGap : float = 1000000.0
            var NearestAlign : float = -1.0
            var NearestBlocked : logic = false

            for (Tier := 0..3):
                # A crate still coming down does not answer to shots. Its count
                # is reset the moment it lands, so anything counted during the
                # fall was thrown away while the log claimed it had landed.
                # Playtest 2026-08-24 lost six shots that way in one descent.
                #
                # Nor does one that is already open. Its reward is decided and
                # nothing more can be done to it, so counting further shots only
                # told Kai to keep firing. On 2026-08-24 that meant emptying a
                # rocket launcher into an open crate at point blank range and
                # dying to the splash.
                if (Held := LiveCrates[Tier]?, Held.IsValid[], Falling := TierDescending[Tier], not Falling?, Decided := TierReward[Tier], Decided < 0):
                    At := Held.GetTransform().Translation
                    ToX := At.X - From.X
                    ToY := At.Y - From.Y
                    Gap := Distance(vector3{X := From.X, Y := From.Y, Z := 0.0}, vector3{X := At.X, Y := At.Y, Z := 0.0})

                    if (Gap > 0.0, Gap < NearestGap):
                        set NearestGap = Gap
                        set NearestTier = Tier
                        set NearestAlign = (ToX / Gap) * ForwardX + (ToY / Gap) * ForwardY
                        set NearestBlocked = if (Blocked[From, ForwardX, ForwardY, Gap]) then true else false

                    if (Gap > 0.0, Gap <= AimRange, Gap < BestGap):
                        Alignment := (ToX / Gap) * ForwardX + (ToY / Gap) * ForwardY
                        if (Alignment >= Needed):
                            if (not Blocked[From, ForwardX, ForwardY, Gap]):
                                set BestGap = Gap
                                set BestTier = Tier

            if (BestTier >= 0):
                if (Current := TierHits[BestTier], set TierHits[BestTier] = Current + 1):
                    Print("DEBUG: Contestant shot tier {BestTier}'s crate. {Current + 1} of {ShotsToOpen}.")
            else if (LogRejectedShots?, NearestTier >= 0):
                BlockedText := if (NearestBlocked?) then "yes" else "no"
                Print("DEBUG: Crate -- shot NOT counted. Nearest is tier {NearestTier} at {NearestGap}cm of {AimRange}, alignment {NearestAlign} needs {Needed}, blocked {BlockedText}.")

    # Which way the contestant's body is pointing, in radians, or zero if it
    # cannot be read.
    #
    # WHY THE CHARACTER AND NOT THE SCENE GRAPH ENTITY. AimRotationProbe reads
    # the entity's global transform, but that rotation is a Verse.org one and
    # reading its angles needs an import that made vector3 ambiguous in 46
    # places in this file. The character's own transform is the flavour this
    # file already uses. Whether it tracks the cursor as the entity's does is
    # the one thing to confirm on the next playtest, 2026-08-23.
    BodyYawRadians(Character : fort_character)<transacts>:float =
        var Result : float = 0.0
        Angles := Character.GetTransform().Rotation.GetYawPitchRollDegrees()
        if (Yaw := Angles[0]):
            set Result = Yaw * (FullCircleRadians / 360.0)
        Result

    # True when a hostile stands between the contestant and the crate. Distance
    # along the line of fire and distance from it are both plain arithmetic, so
    # nothing here depends on the engine tracing anything.
    Blocked(From : vector3, ForwardX : float, ForwardY : float, Gap : float)<transacts><decides>:void =
        var Found : logic = false
        for:
            Spawner : HostileSpawners
            Hostile : Spawner.GetAgents()
            HostileCharacter := Hostile.GetFortCharacter[]
            HostileCharacter.IsActive[]
        do:
            Its := HostileCharacter.GetTransform().Translation
            OffX := Its.X - From.X
            OffY := Its.Y - From.Y
            Along := OffX * ForwardX + OffY * ForwardY
            if (Along > 0.0, Along < Gap):
                Side := OffX * (0.0 - ForwardY) + OffY * ForwardX
                Sideways := if (Side < 0.0) then 0.0 - Side else Side
                if (Sideways < AimBlockRadius):
                    set Found = true
        Found?

    # Four one-line handlers because Subscribe passes only the agent, and the
    # tier has to come from somewhere.
    OnTier0Damaged(Result : damage_result):void = CountHit(0, Result)
    OnTier1Damaged(Result : damage_result):void = CountHit(1, Result)
    OnTier2Damaged(Result : damage_result):void = CountHit(2, Result)
    OnTier3Damaged(Result : damage_result):void = CountHit(3, Result)

    # Heal first, ask questions after. Topping the breaker back up as each hit
    # lands is what stops a hostile ending a crate, per Kai's ruling, and it
    # costs nothing when the hit turns out to be the contestant's.
    CountHit(Tier : int, Result : damage_result):void =
        if (Breaker := CrateBreakers[Tier]):
            Breaker.SetHealth(Breaker.GetMaxHealth())

        if:
            Instigator := Result.Instigator?
            PlayerFrom(Instigator)?
        then:
            if (Current := TierHits[Tier], set TierHits[Tier] = Current + 1):
                Print("DEBUG: Contestant hit tier {Tier}'s crate. Count now {Current + 1} of {ShotsToOpen}.")
        else if (Result.Instigator?):
            Print("DEBUG: Hit on tier {Tier}'s crate ignored, not the contestant.")
        else:
            Print("DEBUG: Hit on tier {Tier}'s crate ignored, the engine named nobody.")

    # Who the engine blames for a hit, resolved to a player or nothing.
    #
    # WHY THREE ATTEMPTS AND NOT ONE. game_action_instigator is an empty
    # interface, so what actually arrives depends on what did the damage. An
    # earlier version cast straight to agent and gave up when that failed,
    # which threw away every one of the contestant's own shots on a crate.
    # Anything not resolving to a player is a hostile as far as amendment 65
    # is concerned, and is meant to be discarded.
    PlayerFrom(Instigator : game_action_instigator)<transacts>:?player =
        # The player object itself.
        if (Direct := player[Instigator]):
            option{Direct}
        else:
            # An agent, which a player is a kind of.
            if:
                Blamed := agent[Instigator]
                AsPlayer := player[Blamed]
            then:
                option{AsPlayer}
            else:
                # The character in the world, which owns an agent.
                if:
                    Character := fort_character[Instigator]
                    Owner := Character.GetAgent[]
                    AsPlayer := player[Owner]
                then:
                    option{AsPlayer}
                else:
                    false

    # This tier's running count, zero if the list is short.
    HitsFor(Tier : int)<transacts>:int =
        var Result : int = 0
        if (Hits := TierHits[Tier]):
            set Result = Hits
        Result

    # Marks a tier as having a crate in the air, or not. Rebuilt rather than
    # edited in place, the same way LiveCrates is.
    SetDescending(Tier : int, Falling : logic):void =
        var Rebuilt : []logic = array{}
        for (Index -> Existing : TierDescending):
            if (Index = Tier):
                set Rebuilt += array{Falling}
            else:
                set Rebuilt += array{Existing}
        set TierDescending = Rebuilt

    # Returns once the player is within PickupRadius of where the crate came
    # down. Single contestant by design; amendment 19 records the game as
    # single-player.
    AwaitPlayerReaching(Order : crate_order)<suspends>:void =
        loop:
            Sleep(PollSeconds)
            if:
                Contestant := GetPlayspace().GetPlayers()[0]
                Character := Contestant.GetFortCharacter[]
                Character.IsActive[]
                Distance(Character.GetTransform().Translation, Order.LandingSpot) <= PickupRadius
            then:
                return

    # Hands over one reward from this tier's pool. GDD 3.2's four upgrade slots
    # are filled by which items sit in which granter's list, not by anything
    # here.
    #
    # TWO KINDS OF REWARD, BECAUSE TWO KINDS EXIST. The SMG, Shotgun, Sniper and
    # Rocket Launcher are real Fortnite items and come out of the granter. The
    # Sponsor Aid heal is not an item at all and has to be done in code, so
    # TierHealChance rolls for it first. Amendment 38.
    GrantTier(Tier : int)<suspends>:void =
        # Hands over whatever DecideReward settled on when the crate broke open.
        # The roll used to happen here, at the moment of pickup, which meant the
        # crate could not be shown holding anything. Kai's ruling 2026-08-23.
        if (Code := TierReward[Tier]):
            if (Code = 4):
                GrantHeal()
            else if (Code = 5):
                GrantAegis()
            else if (Code = 6):
                Print("DEBUG: Crate COLLECTED -- Icy Rounds")
                AmmoModifiers.StartIcyRounds()
            else if (Code = 7):
                Print("DEBUG: Crate COLLECTED -- Flaming Ammo")
                AmmoModifiers.StartFlamingAmmo()
            else if (Code >= 0, Code <= 3):
                GrantWeapon(Code)

    # Puts a crate's weapon in the contestant's hands, full inventory or not,
    # the moment they are close enough. The gun on the crate is the display; this
    # is the pickup.
    GrantWeapon(Code : int):void =
        if (Already := GrantedWeapons[Code], Already?):
            GrantSpareAmmo(Code)
        else if (Granter := GunGranters[Code]):
            for (Contestant : GetPlayspace().GetPlayers()):
                Granter.GrantItem(Contestant)
                Print("DEBUG: Crate COLLECTED -- weapon {Code} handed over.")
            RememberGranted(Code)
        else:
            Print("WARNING: Crate -- no granter for weapon {Code}, so nothing was handed over. Fill GunGranters.")

        # The one lying on the crate goes, so no second copy is left behind.
        # Whether disabling the spawner clears an already-spawned gun is the one
        # thing to watch on the next playtest, 2026-08-23.
        if (Spawner := WeaponSpawners[Code]):
            Spawner.Disable()

    # Ammo instead of a duplicate gun.
    GrantSpareAmmo(Code : int):void =
        if (Granter := AmmoGranterFor(Code)?):
            for (Contestant : GetPlayspace().GetPlayers()):
                Granter.GrantItem(Contestant)
            Print("DEBUG: Crate COLLECTED -- weapon {Code} already held, so ammo went over instead.")
        else:
            Print("WARNING: Crate -- weapon {Code} already held and no ammo granter filled in, so nothing went over. Fill AmmoGranters.")

    # The ammo granter for a weapon, falling back to entry 0 the same way the
    # crate assets, balloons and materials do.
    AmmoGranterFor(Code : int)<transacts>:?item_granter_device =
        var Result : ?item_granter_device = false
        if (Granter := AmmoGranters[Code]):
            set Result = option{Granter}
        else if (Fallback := AmmoGranters[0]):
            set Result = option{Fallback}
        Result

    # Bookkeeping, rebuilt rather than edited in place, the same way LiveCrates
    # and TierReward are.
    RememberGranted(Code : int):void =
        var Rebuilt : []logic = array{}
        for (Index -> Existing : GrantedWeapons):
            if (Index = Code):
                set Rebuilt += array{true}
            else:
                set Rebuilt += array{Existing}
        set GrantedWeapons = Rebuilt

    # Decides what this crate holds. Lifted wholesale out of GrantTier, which
    # used to roll at the moment of pickup. Amendment 38's pools and the coded
    # chances are unchanged; only the timing moved.
    DecideReward(Tier : int):void =
        var HealCut : float = 0.0
        if (C := TierHealChance[Tier]):
            set HealCut = C
        var AegisCut : float = HealCut
        if (C := TierAegisChance[Tier]):
            set AegisCut = HealCut + C
        var IcyCut : float = AegisCut
        if (C := TierIcyChance[Tier]):
            set IcyCut = AegisCut + C
        var FlamingCut : float = IcyCut
        if (C := TierFlamingChance[Tier]):
            set FlamingCut = IcyCut + C

        Roll := GetRandomFloat(0.0, 1.0)
        var Chosen : int = -1
        if (Roll < HealCut):
            set Chosen = 4
        else if (Roll < AegisCut):
            set Chosen = 5
        else if (Roll < IcyCut):
            set Chosen = 6
        else if (Roll < FlamingCut):
            set Chosen = 7
        else:
            Pool := WeaponsForTier(Tier)
            if (Pick := Pool[GetRandomInt(0, Pool.Length - 1)]):
                set Chosen = Pick

        SetReward(Tier, Chosen)
        Print("DEBUG: Tier {Tier}'s crate holds reward {Chosen}.")

    # Amendment 38's pools, as weapon numbers. The Sponsor Aid, Aegis and both
    # ammo modifiers are not weapons and are rolled above instead.
    WeaponsForTier(Tier : int)<transacts>:[]int =
        if (Tier = 0):
            array{0, 1}
        else if (Tier = 1):
            array{1, 2}
        else if (Tier = 2):
            array{2}
        else:
            array{3}

    # Puts the decided reward on top of the crate, so the player can see what
    # they are about to take. Kai's whole reason for shooting a crate open.
    ShowReward(Tier : int, Spot : vector3):void =
        # A weapon is laid out for real. Everything else is a prop, because the
        # shield, the med kit and both ammo modifiers are built in code and have
        # no Fortnite item behind them.
        if (Code := TierReward[Tier], Code >= 0, Code <= 3, Spawner := WeaponSpawners[Code]):
            OnTop := vector3{X := Spot.X, Y := Spot.Y, Z := Spot.Z + WeaponRestHeight}
            if (Spawner.TeleportTo[OnTop, IdentityRotation()]):
                Spawner.Enable()
                Spawner.SpawnItem()
                Print("DEBUG: Tier {Tier}'s crate laid out weapon {Code}.")
            else:
                Print("WARNING: Crate -- the spawner for weapon {Code} would not move, so nothing was laid out.")
        else if (Code := TierReward[Tier], Code >= 0, Asset := RewardProps[Code]):
            ScaleVector := vector3{X := RewardPropScale, Y := RewardPropScale, Z := RewardPropScale}
            Above := vector3{X := Spot.X, Y := Spot.Y, Z := Spot.Z + RewardPropHeight}
            Where := transform{Translation := Above, Rotation := IdentityRotation(), Scale := ScaleVector}
            Result := SpawnProp(Asset, Where)
            if (Shown := Result(0)?):
                set Shown.CanBeDamaged = false
                RememberShown(Tier, option{Shown})
                Print("DEBUG: Tier {Tier}'s crate is showing reward {Code}.")
        else:
            Print("DEBUG: Tier {Tier} has no prop for its reward, so the crate shows nothing. Fill RewardProps.")

    # Takes the shown reward away and forgets what the crate held.
    ClearShown(Tier : int):void =
        if (Held := ShownRewards[Tier]?):
            if (Held.IsValid[]):
                Held.Dispose()
        RememberShown(Tier, false)

    # Forgetting WHAT the crate held is separate from taking the prop away,
    # because the prop goes the moment the crate is done and the code is still
    # needed to hand the reward over. Doing both at once meant GrantTier saw -1
    # and granted nothing. Playtest 2026-08-23.
    ForgetReward(Tier : int):void =
        SetReward(Tier, -1)

    # Bookkeeping, rebuilt rather than edited in place, the same way LiveCrates
    # and TierDescending are.
    SetReward(Tier : int, Code : int):void =
        var Rebuilt : []int = array{}
        for (Index -> Existing : TierReward):
            if (Index = Tier):
                set Rebuilt += array{Code}
            else:
                set Rebuilt += array{Existing}
        set TierReward = Rebuilt

    RememberShown(Tier : int, Shown : ?creative_prop):void =
        var Rebuilt : []?creative_prop = array{}
        for (Index -> Existing : ShownRewards):
            if (Index = Tier):
                set Rebuilt += array{Shown}
            else:
                set Rebuilt += array{Existing}
        set ShownRewards = Rebuilt

    # GDD 3.3's Sponsor Aid, delivered in code because Fortnite has no turkey
    # leg item. SetHealth clamps to the maximum by itself, so healing past full
    # is handled by the engine and needs no ceiling check here.
    GrantHeal()<suspends>:void =
        for:
            Contestant : GetPlayspace().GetPlayers()
            Character := Contestant.GetFortCharacter[]
            Character.IsActive[]
        do:
            Restored := Character.GetMaxHealth() * HealFraction
            Character.SetHealth(Character.GetHealth() + Restored)
            Print("DEBUG: Crate COLLECTED -- Sponsor Aid healed {Restored}")
            if (HealGlow.TeleportTo[Character.GetTransform().Translation, IdentityRotation()]):
                HealGlow.Begin()
                spawn{ EndHealGlow() }
            HealSound.Play(Contestant)

    EndHealGlow()<suspends>:void =
        Sleep(HealGlowSeconds)
        HealGlow.End()

    # GDD 3.3's Sponsor Aegis. Amendment 41: three hits, and no timer at all.
    #
    # A second Aegis collected while one is up refills the shield rather than
    # stacking, which is GDD 3.2's duplicate rule delivered without a clock.
    GrantAegis()<suspends>:void =
        for:
            Contestant : GetPlayspace().GetPlayers()
            Character := Contestant.GetFortCharacter[]
            Character.IsActive[]
        do:
            Character.SetShield(AegisShieldPoints)
            Print("DEBUG: Crate COLLECTED -- Sponsor Aegis up, {AegisShieldPoints} shield")
            AegisSound.Play(Contestant)
            if (not AegisWatching?):
                set AegisWatching = true
                AegisGlow.Begin(Contestant)
                spawn{ WatchAegis(Contestant, Character) }

    # Holds the bubble up until the shield is spent. Amendment 41 gives the Aegis
    # no timer, so this is the only thing that ends it.
    WatchAegis(Contestant : agent, Character : fort_character)<suspends>:void =
        loop:
            Sleep(PollSeconds)
            if (Character.GetShield() <= 0.0):
                break
            if (not Character.IsActive[]):
                break
        AegisGlow.End(Contestant)
        set AegisWatching = false
        Print("DEBUG: Sponsor Aegis spent.")
