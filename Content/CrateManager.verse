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
# ONE SUPPLY DROP SPAWNER PER TIER, and that is not an accident. Its Supply
# FXColor is set in the editor and cannot be reached from Verse, so the only way
# to deliver GDD 3.2's "high-contrast colored paragliders that denote their
# quality tier" is one pre-coloured device per tier. TierCrates is indexed by the
# tier number the audience sends, 0 Underdog to 3 Prime Time. Amendment 24 added
# the fourth.
#
# THE CRATE IS AN EMPTY BOX. Amendment 26: its Item List stays empty and the item
# is granted from Verse on contact instead. Two reasons. A supply drop hands over
# everything in its list at once, which breaks the one-item-per-crate ruling, and
# Fortnite crates are opened by holding a key, which breaks GDD 3.2's "trigger
# instantly upon player collision to maintain momentum".
#
# COLLISION IS MEASURED, NOT DETECTED. There is no trigger volume here and there
# does not need to be one: this file chose the landing spot, so it already knows
# where the crate is and can simply watch the player's distance to it. That saves
# four placed devices and any chance of a volume being left somewhere stale.
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
# ONE KNOWN ARTEFACT, ACCEPTED DELIBERATELY. If a second order of the same tier
# lands within ten seconds of the first, the first crate's expiry timer is still
# running and will clear the replacement a little early. It is benign, it needs a
# same-tier order inside ten seconds against a 25-second trickle to happen at
# all, and the alternative is per-tier generation bookkeeping that costs more in
# complexity than the fault costs in play. If crates ever start vanishing early,
# this is why.

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

    # One Supply Drop Spawner per tier, in order: 0 Underdog, 1 Rising Star,
    # 2 Superstar, 3 Prime Time. Each carries its own Supply FXColor for GDD
    # 3.2's colour coding, its Item List EMPTY, and its Spawn Delay set to Off,
    # or a crate falls at match start before anyone has earned one.
    @editable
    TierCrates : []supply_drop_spawner_device = array{}

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

    OnBegin<override>()<suspends>:void =
        Print("DEBUG: Crate Manager listening -- {TierCrates.Length} tier crate spawner(s), {TierGranters.Length} granter(s)")

        if (TierCrates.Length < 4):
            Print("WARNING: Crate Manager has {TierCrates.Length} of 4 tier crate spawners. Orders for the missing tiers will be dropped with a warning. Fill TierCrates with one Supply Drop Spawner per tier, 0 to 3.")

        loop:
            Order := Audience.SpawnCrateEvent.Await()
            # Spawned so a long-lived crate never holds up the next order. The
            # audience is not made to wait on the arena.
            spawn{ RunCrate(Order) }

    # One crate, from order to gone.
    RunCrate(Order : crate_order)<suspends>:void =
        if (Crate := TierCrates[Order.Tier]):
            # Newest wins. See the header.
            Crate.DestroySpawnedDrops()

            # The device spawns its crate above itself, so moving the device is
            # how the landing spot gets chosen. Nothing else can set it.
            if (Crate.TeleportTo[Order.LandingSpot, IdentityRotation()]):
                Crate.Spawn()
                Print("DEBUG: Crate ordered -- tier {Order.Tier} falling to X={Order.LandingSpot.X} Y={Order.LandingSpot.Y}")
                AwaitCrateResolved(Order, Crate)
            else:
                Print("WARNING: Crate -- tier {Order.Tier} spawner refused to move to the landing spot, so no crate fell. Check the device is not locked in the outliner.")
        else:
            Print("WARNING: Crate -- nothing filled in for tier {Order.Tier}, so this order was dropped. Fill TierCrates.")

    # Waits for the crate to land, then races the player against the clock.
    AwaitCrateResolved(Order : crate_order, Crate : supply_drop_spawner_device)<suspends>:void =
        Crate.LandingEvent.Await()
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

        Crate.DestroySpawnedDrops()

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
