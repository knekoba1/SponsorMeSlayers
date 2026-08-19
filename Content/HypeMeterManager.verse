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
        Players := GetPlayspace().GetPlayers()
        for (P : Players):
            spawn{ ShowHypeBar(P) }

    ShowHypeBar(P : player)<suspends>:void =
        Bar := color_block:
            DefaultColor := NamedColors.Magenta
            DefaultOpacity := 1.0
            DefaultDesiredSize := vector2{X := 40.0, Y := 0.0}

        set HypeBar = option{Bar}

        HypeCanvas := canvas:
            Slots := array:
                canvas_slot:
                    Widget := Bar
                    Anchors := anchors{Minimum := vector2{X := 0.05, Y := 0.5}, Maximum := vector2{X := 0.05, Y := 0.5}}
                    Offsets := margin{Left := 0.0, Top := -150.0, Right := 0.0, Bottom := 0.0}

        if (PlayerUI := GetPlayerUI[P]):
            PlayerUI.AddWidget(HypeCanvas)

    OnHostileEliminated(Result : device_ai_interaction_result):void =
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