# HypeMeterManager.verse
#
# GDD Section 3.1 "Hype Meter" -- risk-driven Hype, with a constant bleed.
#
# ORDINARY KILLS PAY NOTHING. 3.1 names the sources as "rapid multi-kills,
# close-shave dodges, and prize pickups", never plain kills. Paying per kill made
# the meter ratchet to full and park there, flattening all four crate tiers into
# one, because in a twin-stick at Smash TV density constant killing is the
# baseline rather than a flourish. Kai's ruling 2026-08-18.
#
# WHAT PAYS INSTEAD. A cluster of near-simultaneous kills pays a little, and
# taking a hit costs a lot. This is the genre's own answer: grazing in Touhou and
# CAVE, and Geometry Wars tying its multiplier to chaining kills without being
# hit, both reward surviving dangerously rather than killing efficiently. Close
# shaves, the biggest earner, are built here as of amendment 40: a hostile that
# closes inside two metres arms a shave, and it pays once the player has broken
# four metres clear of that same hostile.
#
# THE BLEED IS TWO RATES. GDD 3.1 gives one: "decays by 5% every 10 seconds of
# inactivity". Kai's ruling 2026-08-18 adds a constant 2 on top, so the meter
# always sags and has to be out-earned. The GDD's 5 is the idle rate and still
# applies as written. Recorded as an amendment.

using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Colors }
using { /Verse.org/Simulation }

hype_meter_manager := class(creative_device):

    # All four hostile spawners, amendment 45. Order does not matter here, unlike
    # in WaveManager, because nothing in this file cares which type it is looking
    # at. Leave any of them out and those hostiles pay no Hype and offer no shave.
    @editable
    HostileSpawners : []npc_spawner_device = array{}

    # A cluster is ClusterCount kills inside ClusterWindowSeconds. The window is
    # deliberately shorter than the time it takes to kill two things one after
    # another, so only something that wipes a group at once can reach it.
    @editable
    ClusterCount : int = 4

    @editable
    ClusterWindowSeconds : float = 0.4

    # Small on purpose. Kai's call 2026-08-18: 20 and 10 both felt far too high.
    @editable
    HypePerCluster : float = 2.0

    # What one hostile hit costs. This is what makes the meter fall as well as
    # rise, and it is why playing safe cannot climb it.
    @editable
    HypeLostPerHit : float = 10.0

    # GDD 3.1's "close-shave dodges", numbers from amendment 40.
    @editable
    HypePerShave : float = 3.0

    # What one prize pickup pays, when the player travelled to it. GDD 3.1 names
    # prize pickups as a Hype source and gives no number at all. 1 is Claude's
    # starting figure, delegated by Kai on 2026-08-22, and it is the first thing
    # to lower if the meter starts filling too easily.
    @editable
    HypePerTravelledPickup : float = 1.0

    # In centimetres. 200 is amendment 40's two metres: every hostile is melee
    # and swings at about arm's length, and GDD 5.3 already treats three metres
    # as the danger line, so two is inside the ring where the player could have
    # been hit rather than merely near something.
    @editable
    ShaveRadius : float = 200.0

    # In centimetres. Amendment 40's four-metre break.
    @editable
    ShaveBreakRadius : float = 400.0

    # How often hostile distances are measured. Finer than TickSeconds because
    # amendment 31 measured the contestant at 11.90 m/s, who would cross a
    # two-metre ring between two quarter-second samples.
    @editable
    ShavePollSeconds : float = 0.1

    # The constant bleed, applied every DrainEverySeconds.
    @editable
    AlwaysDrainPoints : float = 2.0

    # GDD 3.1's own rate, applied instead of the above once nothing has been
    # earned for IdleAfterSeconds. On a 0-to-100 meter, 5% is 5 points.
    @editable
    IdleDrainPoints : float = 5.0

    @editable
    DrainEverySeconds : float = 10.0

    @editable
    IdleAfterSeconds : float = 10.0

    # How often the cluster window, the bleed and the player's health are checked.
    @editable
    TickSeconds : float = 0.25

    MaxBarHeight : float = 300.0

    var CurrentHype : float = 0.0
    var HypeBar : ?color_block = false
    var KillsInCluster : int = 0
    var SecondsSinceKill : float = 0.0
    var SecondsSinceHype : float = 0.0
    var SecondsSinceDrain : float = 0.0
    var Contestant : ?player = false
    var ArmedShaves : [agent]logic = map{}

    OnBegin<override>()<suspends>:void =
        for (Spawner : HostileSpawners):
            Spawner.EliminatedEvent.Subscribe(OnHostileEliminated)
        Print("DEBUG: Hype Meter started, subscribed to the spawner.")
        spawn{ WatchContestant() }
        spawn{ RunMeterTick() }
        spawn{ RunShaveWatch() }

    # Waits for the contestant, puts the bar on screen, then watches their health
    # so a hit can cost Hype. The bar used to be built only for players already in
    # the playspace the instant this device began, and in a playtest nobody is.
    # Single contestant by design; amendment 19 records the game as single-player.
    WatchContestant()<suspends>:void =
        loop:
            if (P := GetPlayspace().GetPlayers()[0]):
                set Contestant = option{P}
                ShowHypeBar(P)
                Print("DEBUG: Hype bar added for the contestant.")
                break
            Sleep(0.5)

        # The health seen on the previous check, so a drop can be spotted. 0.0
        # means nothing has been read yet.
        var LastHealth : float = 0.0
        loop:
            Sleep(TickSeconds)
            if:
                P := Contestant?
                Character := P.GetFortCharacter[]
                Character.IsActive[]
            then:
                Now := Character.GetHealth()
                if (LastHealth > 0.0, Now < LastHealth):
                    Print("DEBUG: hit taken. -{HypeLostPerHit} Hype.")
                    AddHype(-HypeLostPerHit)
                    # 3.1 pays for dodging, and a hit is the opposite, so every
                    # shave still waiting to be earned is cancelled.
                    set ArmedShaves = map{}
                set LastHealth = Now

    # The cluster window and both bleed rates, on one clock.
    RunMeterTick()<suspends>:void =
        loop:
            Sleep(TickSeconds)
            set SecondsSinceKill = SecondsSinceKill + TickSeconds
            set SecondsSinceHype = SecondsSinceHype + TickSeconds
            set SecondsSinceDrain = SecondsSinceDrain + TickSeconds

            # A cluster has to be near-simultaneous, so stale kills stop counting.
            if (SecondsSinceKill > ClusterWindowSeconds, KillsInCluster > 0):
                set KillsInCluster = 0

            if (SecondsSinceDrain >= DrainEverySeconds, CurrentHype > 0.0):
                set SecondsSinceDrain = 0.0
                if (SecondsSinceHype >= IdleAfterSeconds):
                    AddHype(-IdleDrainPoints)
                else:
                    AddHype(-AlwaysDrainPoints)

    # A hostile inside ShaveRadius arms a shave against itself, and it pays only
    # once the player has broken ShaveBreakRadius clear of that same hostile, so
    # what is paid for is escaping rather than being chased. Melee hostiles sit
    # inside two metres continuously while pursuing, and without the break rule
    # the meter would fill for standing still.
    #
    # A hostile killed while armed pays nothing. It was shot, not dodged, and the
    # cluster rule already covers killing.
    #
    # The armed set is rebuilt from the live hostiles on every pass rather than
    # edited in place, so eliminated hostiles fall out of it on their own and
    # nothing accumulates across a run.
    RunShaveWatch()<suspends>:void =
        loop:
            Sleep(ShavePollSeconds)
            if:
                P := Contestant?
                Character := P.GetFortCharacter[]
                Character.IsActive[]
            then:
                PlayerLocation := Character.GetTransform().Translation
                var StillArmed : [agent]logic = map{}
                for:
                    Spawner : HostileSpawners
                    Hostile : Spawner.GetAgents()
                    HostileCharacter := Hostile.GetFortCharacter[]
                    HostileCharacter.IsActive[]
                do:
                    Gap := Distance(PlayerLocation, HostileCharacter.GetTransform().Translation)
                    if (ArmedShaves[Hostile]?):
                        if (Gap >= ShaveBreakRadius):
                            Print("DEBUG: CLOSE SHAVE. +{HypePerShave} Hype.")
                            AddHype(HypePerShave)
                        else:
                            set StillArmed = ConcatenateMaps(StillArmed, map{Hostile => true})
                    else:
                        if (Gap <= ShaveRadius):
                            set StillArmed = ConcatenateMaps(StillArmed, map{Hostile => true})
                set ArmedShaves = StillArmed

    ShowHypeBar(P : player)<suspends>:void =
        # The empty thermometer of GDD 3.1, so the meter can be seen before any
        # Hype is earned. Without it, a meter at zero is zero pixels tall.
        Track := color_block:
            DefaultColor := NamedColors.Black
            DefaultOpacity := 0.4
            DefaultDesiredSize := vector2{X := 40.0, Y := MaxBarHeight}

        Bar := color_block:
            DefaultColor := NamedColors.Magenta
            DefaultOpacity := 1.0
            DefaultDesiredSize := vector2{X := 40.0, Y := 0.0}

        set HypeBar = option{Bar}

        HypeCanvas := canvas:
            Slots := array:
                canvas_slot:
                    Widget := Track
                    Anchors := anchors{Minimum := vector2{X := 0.05, Y := 0.5}, Maximum := vector2{X := 0.05, Y := 0.5}}
                    Offsets := margin{Left := 0.0, Top := -150.0, Right := 0.0, Bottom := 0.0}
                # Pinned by its bottom edge to the foot of the track, so the fill
                # climbs upward as Hype rises. GDD 3.1 calls it a thermometer.
                # The old slot pinned the top edge, so it filled downward.
                canvas_slot:
                    Widget := Bar
                    Anchors := anchors{Minimum := vector2{X := 0.05, Y := 0.5}, Maximum := vector2{X := 0.05, Y := 0.5}}
                    Offsets := margin{Left := 0.0, Top := 150.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.0, Y := 1.0}

        if (PlayerUI := GetPlayerUI[P]):
            PlayerUI.AddWidget(HypeCanvas)

    OnHostileEliminated(Result : device_ai_interaction_result):void =
        set KillsInCluster = KillsInCluster + 1
        set SecondsSinceKill = 0.0
        if (KillsInCluster >= ClusterCount):
            set KillsInCluster = 0
            Print("DEBUG: CLUSTER KILL. +{HypePerCluster} Hype.")
            AddHype(HypePerCluster)

    # GDD 3.1's "prize pickups", the third Hype source. Called by the cash drop
    # manager, and only for loot the player actually crossed the floor for, which
    # is Kai's ruling of 2026-08-22: the magnet of amendment 50 reaches 8 metres
    # in a 25-metre room and brings most piles over for free, and free money is
    # not a flourish.
    #
    # A FLAT AMOUNT IS ENOUGH BECAUSE THE FILTER DOES THE WORK. Paying per pickup
    # is the fault that made ordinary kills pay nothing: 180 drops were collected
    # in one 90-second run, so any per-item figure fills the meter in seconds.
    # Once only travelled-to drops count, most of that 180 pays nothing and a flat
    # point each is a reward rather than a flood.
    OnPrizeCollected():void =
        Print("DEBUG: TRAVELLED PICKUP. +{HypePerTravelledPickup} Hype.")
        AddHype(HypePerTravelledPickup)

    AddHype(Amount : float):void =
        # Earning resets the idle clock. Losing must not, or the idle bleed would
        # keep restarting its own timer and never repeat.
        if (Amount > 0.0):
            set SecondsSinceHype = 0.0
        var NewHype : float = CurrentHype + Amount
        if (NewHype > 100.0):
            set NewHype = 100.0
        if (NewHype < 0.0):
            set NewHype = 0.0
        set CurrentHype = NewHype
        if (Bar := HypeBar?):
            Bar.SetDesiredSize(vector2{X := 40.0, Y := MaxBarHeight * (CurrentHype / 100.0)})
        Print("Hype: {CurrentHype}")

    # Read by the Simulated Audience, which grades crates by the current Hype.
    # GDD Section 4 gives the meter and the crate parameters to one system.
    GetHype()<transacts>:float =
        CurrentHype
