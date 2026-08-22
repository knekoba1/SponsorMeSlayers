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
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
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
    @editable
    DescentSeconds : float = 1.5

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

    # One material per tier, in the same order: 0 Underdog, 1 Rising Star,
    # 2 Superstar, 3 Prime Time. Amendment 36's medal ladder is bronze #CD7F32,
    # silver #A8B0BC, gold #FFD700 and white #FFFFFF, so those are the four to
    # make. Applied to both the crate and its balloon.
    #
    # THIS IS WHY THE TIER COLOUR IS NOT BORROWED ANY MORE. A spawned prop's
    # material can be set from code, found 2026-08-22. Before that the colour had
    # to come from a device's own effect, which is what tied it to the smoke.
    # A tier with no entry falls back to entry 0, and an empty list leaves both
    # props in their own colours.
    @editable
    TierMaterials : []material = array{}

    # One Item Granter per tier, same order, holding that tier's pool. The pool
    # is drawn from by CycleToRandomItem, so a tier with three items in its list
    # hands over one of the three. Set Grant on Cycle to OFF on these, or the
    # cycle grants as well as the grant and the player gets two items.
    @editable
    TierGranters : []item_granter_device = array{}

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
    # palette's #3BE07A over #1E8F4E, amendment 36. Its own device rather than
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

    # The pink bubble of GDD 3.3, in the palette's reserved SHIELD pink #FF69D4.
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

    # Whether a bubble is already up, so a second Aegis refills the shield
    # instead of starting a second watcher against the same one.
    var AegisWatching : logic = false

    # The crate each tier currently has in the arena, so a new order of one tier
    # clears only that tier's crate and an expiry timer only ever clears its own.
    var LiveCrates : []?creative_prop = array{false, false, false, false}

    OnBegin<override>()<suspends>:void =
        Print("DEBUG: Crate Manager listening -- {TierCrateAssets.Length} crate prop(s), {TierGlows.Length} glow(s), {TierGranters.Length} granter(s)")

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

                # The tier colour, forced onto the prop rather than borrowed.
                if (Paint := MaterialFor(Order.Tier)?):
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
                        if (Paint := MaterialFor(Order.Tier)?):
                            Lifted.SetMaterial(Paint)
                    else:
                        Print("DEBUG: Crate -- balloon would not spawn, so the crate comes down on its own.")
                else:
                    Print("DEBUG: Crate -- no balloon filled in for tier {Order.Tier}, so the crate comes down on its own.")

                # The glow marks the spot while the crate is still in the air, so
                # the colour is readable before the player commits to the walk.
                StartGlow(Order.Tier, Order.LandingSpot)

                LowerCrate(Crate, Balloon, Order.LandingSpot)
                Print("DEBUG: Crate landed -- tier {Order.Tier}. {CrateLifeSeconds}s to reach it.")

                var Collected : logic = false
                race:
                    block:
                        AwaitPlayerReaching(Order)
                        set Collected = true
                    block:
                        Sleep(CrateLifeSeconds)

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
    LowerCrate(Crate : creative_prop, Balloon : ?creative_prop, LandingSpot : vector3)<suspends>:void =
        var Elapsed : float = 0.0
        var BalloonSteps : int = 0
        loop:
            Sleep(DescentStepSeconds)
            set Elapsed += DescentStepSeconds

            if (Crate.IsValid[]):
                Remaining := if (Elapsed >= DescentSeconds) then 0.0 else 1.0 - Elapsed / DescentSeconds
                Height := LandingSpot.Z + DropHeight * Remaining
                Target := vector3{X := LandingSpot.X, Y := LandingSpot.Y, Z := Height}

                if (Crate.TeleportTo[Target, IdentityRotation()]):
                    # The balloon follows the crate up the same line. A refused
                    # move is ignored: the crate is what matters.
                    if (Held := Balloon?):
                        BalloonTarget := vector3{X := LandingSpot.X, Y := LandingSpot.Y, Z := Height + BalloonHeightAboveCrate}
                        if:
                            Held.IsValid[]
                            Held.TeleportTo[BalloonTarget, IdentityRotation()]
                        then:
                            set BalloonSteps += 1

                    if (Remaining <= 0.0):
                        PopBalloon(Balloon)
                        return
                else:
                    Print("DEBUG: Crate -- descent stopped early, it rests where it stopped")
                    PopBalloon(Balloon)
                    return
            else:
                PopBalloon(Balloon)
                return

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

    # The material for a tier, falling back to entry 0 the same way the crate and
    # the balloon do.
    MaterialFor(Tier : int)<transacts>:?material =
        var Result : ?material = false
        if (Paint := TierMaterials[Tier]):
            set Result = option{Paint}
        else if (Fallback := TierMaterials[0]):
            set Result = option{Fallback}
        Result

    # Puts this tier's glow on the landing spot and starts it. A tier with no glow
    # filled in simply gets none.
    StartGlow(Tier : int, Spot : vector3):void =
        if:
            Glow := TierGlows[Tier]
            Glow.TeleportTo[Spot, IdentityRotation()]
        then:
            Glow.Begin()

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
