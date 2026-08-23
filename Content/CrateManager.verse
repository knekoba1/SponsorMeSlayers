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
using { /UnrealEngine.com/Assets }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Assets }
using { /Verse.org/Random }
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

    # One effect asset per tier, same order, played where the crate stands the
    # moment it is shot open. This is the upward mesh burst Kai found in the
    # Content Drawer on 2026-08-23 and wanted to use as it comes, rather than
    # rebuilding the look by hand on a VFX Creator device.
    #
    # PREFER THIS OVER TierOpenBursts ABOVE. Both fire, so filling in both gives
    # two effects at once. The VFX Creator route is kept only because it was
    # already wired when this arrived.
    @editable
    TierOpenEffects : []particle_system = array{}

    # How far the crate rolls onto its side when it is shot open, in degrees.
    # 90 lays it flat, 0 leaves it standing.
    #
    # OFF BY DEFAULT. This was the stopgap reveal while there was no art for
    # one. Kai played it on 2026-08-22 and disliked how it looked, and the
    # Upward Mesh Burst above replaced it. Kept rather than deleted because it
    # costs nothing and reads well enough if a burst is ever unavailable.
    @editable
    OpenedRollDegrees : float = 0.0

    # One Item Granter per tier, same order, holding that tier's pool. The pool
    # is drawn from by CycleToRandomItem, so a tier with three items in its list
    # hands over one of the three. Set Grant on Cycle to OFF on these, or the
    # cycle grants as well as the grant and the player gets two items.
    @editable
    TierGranters : []item_granter_device = array{}

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
    @editable
    ShotsToOpen : int = 2

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
    # a crate is a large object, so this is generous on purpose: a pickup that
    # needs precision would fight 3.2's "to maintain momentum".
    @editable
    PickupRadius : float = 250.0

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

    OnBegin<override>()<suspends>:void =
        Print("DEBUG: Crate Manager listening -- {TierCrateAssets.Length} crate prop(s), {TierGlows.Length} glow(s), {TierGranters.Length} granter(s), {CrateBreakers.Length} breaker(s)")

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

        if (TierCrateAssets.Length < 1):
            Print("WARNING: Crate Manager has no crate prop at all, so every order will be dropped with a warning. Fill TierCrateAssets with at least entry 0.")

        loop:
            Order := Audience.SpawnCrateEvent.Await()
            # Spawned so a long-lived crate never holds up the next order. The
            # audience is not made to wait on the arena.
            spawn{ RunCrate(Order) }

    # One crate, from order to gone.
    RunCrate(Order : crate_order)<suspends>:void =
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
                if (not Landed?):
                    # A newer crate of this tier replaced this one mid-descent.
                    # Stopping here is the whole point: carrying on would announce
                    # a landing, run a window and finally delete the crate that
                    # replaced it.
                    Print("DEBUG: Crate -- tier {Order.Tier} replaced mid-descent, this one stops here.")
                    return

                Print("DEBUG: Crate landed -- tier {Order.Tier}. {CrateLifeSeconds}s to reach it.")

                var Collected : logic = false
                var Replaced : logic = false
                race:
                    block:
                        AwaitCrateShotOpen(Order.Tier, Order.LandingSpot)
                        ShowOpened(Crate, Order.Tier)
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

                if (Replaced?):
                    Print("DEBUG: Crate -- tier {Order.Tier} replaced while waiting, this one stops here.")
                    return

                if (Collected?):
                    GrantTier(Order.Tier)
                else:
                    Print("DEBUG: Crate expired uncollected -- tier {Order.Tier}")

                ClearTier(Order.Tier)
            else:
                Print("WARNING: Crate -- tier {Order.Tier} prop could not be spawned, so no crate fell. Check the asset filled into TierCrateAssets.")
        else:
            Print("WARNING: Crate -- no prop for tier {Order.Tier} and no entry 0 to fall back on, so this order was dropped. Fill TierCrateAssets.")

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
                Height := LandingSpot.Z + DropHeight * Remaining

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
                        PopBalloon(Balloon)
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
    ShowOpened(Crate : creative_prop, Tier : int):void =
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

            # The reveal itself.
            if (Effect := EffectFrom(TierOpenEffects, Tier)?):
                Played := SpawnParticleSystem(Effect, Where)
                Print("DEBUG: Open effect played for tier {Tier}.")

            if (Burst := TierOpenBursts[Tier]):
                if (Burst.TeleportTo[Where, IdentityRotation()]):
                    Burst.Begin()
                    Print("DEBUG: Open burst played for tier {Tier}.")

            Tipped := MakeRotationFromYawPitchRollDegrees(0.0, 0.0, OpenedRollDegrees)
            if (Crate.TeleportTo[Where, Tipped]):
                Print("DEBUG: Crate for tier {Tier} knocked onto its side.")
            else:
                Print("DEBUG: Crate for tier {Tier} would not tip over.")

    # The opened effect for a tier, falling back to entry 0 exactly as the
    # meshes, materials and crate assets do.
    EffectFrom(Effects : []particle_system, Tier : int)<transacts>:?particle_system =
        var Result : ?particle_system = false
        if (Burst := Effects[Tier]):
            set Result = option{Burst}
        else if (Fallback := Effects[0]):
            set Result = option{Fallback}
        Result

    # The opened look for a tier, falling back to entry 0 exactly as the
    # materials and the crate assets do.
    MeshFrom(Meshes : []mesh, Tier : int)<transacts>:?mesh =
        var Result : ?mesh = false
        if (Shape := Meshes[Tier]):
            set Result = option{Shape}
        else if (Fallback := Meshes[0]):
            set Result = option{Fallback}
        Result

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
        OnSpot := vector3{X := Spot.X, Y := Spot.Y, Z := Spot.Z + BreakerZOffset}
        if (Breaker := CrateBreakers[Tier]):
            Breaker.SetHealth(Breaker.GetMaxHealth())
            if (Breaker.TeleportTo[OnSpot, IdentityRotation()]):
                Print("DEBUG: Breaker moved onto tier {Tier}'s crate.")
            else:
                Print("WARNING: Crate -- the breaker for tier {Tier} would not move, so this crate cannot be opened.")

        Start := HitsFor(Tier)
        loop:
            Sleep(PollSeconds)
            if (HitsFor(Tier) - Start >= ShotsToOpen):
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
        # One roll, and each of the tier's coded rewards takes a slice of it, so
        # the chances stay honest as more of them get built. Whatever is left
        # over goes to the granter and its real Fortnite items.
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
        if (Roll < HealCut):
            GrantHeal()
        else if (Roll < AegisCut):
            GrantAegis()
        else if (Roll < IcyCut):
            Print("DEBUG: Crate COLLECTED -- Icy Rounds")
            AmmoModifiers.StartIcyRounds()
        else if (Roll < FlamingCut):
            Print("DEBUG: Crate COLLECTED -- Flaming Ammo")
            AmmoModifiers.StartFlamingAmmo()
        else if (Granter := TierGranters[Tier]):
            for (Contestant : GetPlayspace().GetPlayers()):
                # Random first, then grant, so a tier holding several items gives
                # one of them rather than all of them. Amendment 26.
                Granter.CycleToRandomItem(Contestant)
                Granter.GrantItem(Contestant)
            Print("DEBUG: Crate COLLECTED -- tier {Tier} granted one item")
        else:
            Print("WARNING: Crate collected but no Item Granter filled in for tier {Tier}, so the player got nothing. Fill TierGranters.")

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
