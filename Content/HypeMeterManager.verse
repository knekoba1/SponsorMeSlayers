# HypeMeterManager.verse
#
# GDD Section 3.1 "Hype Meter" -- real Hype value now, driven by kills.
# Pickup-based Hype and decay/Underdog Boost/manual Hype Call come in later steps.

using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Colors }
using { /Verse.org/Simulation }

hype_meter_manager := class(creative_device):

    @editable
    HostileSpawner : npc_spawner_device = npc_spawner_device{}

    MaxBarHeight : float = 300.0

    var CurrentHype : float = 0.0
    var HypeBar : ?color_block = false

    OnBegin<override>()<suspends>:void =
        HostileSpawner.EliminatedEvent.Subscribe(OnHostileEliminated)
        Print("DEBUG: Hype Meter started, subscribed to the spawner.")
        spawn{ ShowBarWhenContestantArrives() }

    # The bar used to be built only for players already in the playspace the
    # instant this device began. In a playtest the contestant has not arrived by
    # then, so the list was empty and no bar was ever created. Waits instead.
    ShowBarWhenContestantArrives()<suspends>:void =
        loop:
            if (P := GetPlayspace().GetPlayers()[0]):
                ShowHypeBar(P)
                Print("DEBUG: Hype bar added for the contestant.")
                break
            Sleep(0.5)

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
        Print("DEBUG: Hype Meter heard a kill.")
        AddHype(15.0)

    AddHype(Amount : float):void =
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