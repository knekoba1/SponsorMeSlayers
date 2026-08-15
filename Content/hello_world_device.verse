# CashDropManager.verse
#
# Implements GDD Section 2.3 "Cash & Retro Prize Drops ('Ding-Ding-Ding!')"
# and Section 2.1 core-loop step 1, "Defeat Hostiles & Collect Cash."

using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Simulation }

cash_drop_manager := class(creative_device):

    @editable
    HostileSpawner : npc_spawner_device = npc_spawner_device{}

    @editable
    CashPickupPool : []creative_prop = array{}

    @editable
    CashPickupSound : audio_player_device = audio_player_device{}

    @editable
    CashPickupTrigger : trigger_device = trigger_device{}

    @editable
    ScoreManager : score_manager_device = score_manager_device{}

    # How far to move the cash drop vertically from the enemy's mid-body anchor.
    # Negative lowers it toward the floor, positive raises it. Tune in UEFN.
    @editable
    DropHeightOffset : float = -90.0

    var RunScore : int = 0
    var NextPoolIndex : int = 0
    var ActivePickup : ?creative_prop = false

    OnBegin<override>()<suspends>:void =
        HostileSpawner.EliminatedEvent.Subscribe(OnHostileEliminated)
        CashPickupTrigger.TriggeredEvent.Subscribe(OnCashTriggered)

    OnHostileEliminated(Result : device_ai_interaction_result):void =
        Print("Hostile eliminated -- wiring cash drop next")
        if (Target := Result.Target?):
            Print("DEBUG: Target found, attempting drop")
            spawn{ DropCashAt(Target) }
        else:
            Print("DEBUG: No Target on this Result -- cash drop skipped")

    DropCashAt(EliminatedAgent : agent)<suspends>:void =
        if:
            FortCharacter := EliminatedAgent.GetFortCharacter[]
            CashPickupPool.Length > 0
        then:
            Print("DEBUG: Got character + pool not empty, dropping now")
            CharacterLocation := FortCharacter.GetTransform().Translation
            DropZ := CharacterLocation.Z + DropHeightOffset
            DropLocation := vector3{X := CharacterLocation.X, Y := CharacterLocation.Y, Z := DropZ}
            Print("DEBUG: Body Z={CharacterLocation.Z}, Offset={DropHeightOffset}, Final drop Z={DropZ}")
            PickupIndex := NextPoolIndex
            if (NewIndex := Mod[NextPoolIndex + 1, CashPickupPool.Length]):
                set NextPoolIndex = NewIndex
            if (Pickup := CashPickupPool[PickupIndex]):
                if (Pickup.TeleportTo[DropLocation, Pickup.GetTransform().Rotation]):
                    Print("DEBUG: Teleport succeeded, showing pickup")
                    Pickup.Show()
                    set ActivePickup = option{Pickup}
                    if (CashPickupTrigger.TeleportTo[DropLocation, CashPickupTrigger.GetTransform().Rotation]):
                        Print("DEBUG: Trigger repositioned")
                    else:
                        Print("DEBUG: Trigger TeleportTo failed")
                    if (CashPickupSound.TeleportTo[DropLocation, CashPickupSound.GetTransform().Rotation]):
                        Print("DEBUG: Sound repositioned")
                    else:
                        Print("DEBUG: Sound TeleportTo failed")
                else:
                    Print("DEBUG: TeleportTo failed")
            else:
                Print("DEBUG: Pool index lookup failed")
        else:
            Print("DEBUG: GetFortCharacter failed, or pool is empty")

    OnCashTriggered(MaybeAgent : ?agent):void =
        if (CollectingAgent := MaybeAgent?):
            if (Pickup := ActivePickup?):
                OnCashCollected(CollectingAgent, Pickup)
                set ActivePickup = false

    OnCashCollected(CollectingAgent : agent, Pickup : creative_prop):void =
        set RunScore += 10
        Pickup.Hide()
        CashPickupSound.Play()
        ScoreManager.Increment(CollectingAgent)
        Print("Cash collected! Running total: {RunScore}")