# CashDropManager.verse
#
# Implements GDD Section 2.3 "Cash & Retro Prize Drops ('Ding-Ding-Ding!')"
# and Section 2.1 core-loop step 1, "Defeat Hostiles & Collect Cash."
#
# Drops are created at runtime when a hostile dies and disposed of exactly
# DespawnSeconds later, per the prop budget in GDD Section 5.3.

using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Random }
using { /Verse.org/Simulation }

cash_drop_manager := class(creative_device):

    @editable
    HostileSpawner : npc_spawner_device = npc_spawner_device{}

    # The loot that bursts out of a dead hostile: gold coin, cash bundle,
    # toaster, retro TV. Fill this in UEFN. Drops cycle through the list in
    # order, so every kill scatters a mix.
    @editable
    CashPropAssets : []creative_prop_asset = array{}

    @editable
    CashPickupSound : audio_player_device = audio_player_device{}

    @editable
    ScoreManager : score_manager_device = score_manager_device{}

    # How many loot props burst out of each dead hostile.
    @editable
    ItemsPerKill : int = 3

    # How far from the kill spot the loot can land, in centimetres.
    @editable
    ScatterRadius : float = 100.0

    # How close the player has to walk before a drop counts as collected.
    # GDD 2.3: contact is the interaction, there is no pickup button.
    @editable
    PickupRadius : float = 150.0

    # How long a drop stays on the floor before it vanishes. GDD 5.3 fixes
    # this at 5 seconds to protect the prop budget.
    @editable
    DespawnSeconds : float = 5.0

    # The height the cash lands at, in world Z. The enemy's death position sets
    # only X and Y; this sets the height, so enemy body type and death pose no
    # longer affect it. Leave at 0 if the arena floor is at zero. Tune in UEFN.
    @editable
    FloorHeight : float = 0.0

    var RunScore : int = 0
    var NextAssetIndex : int = 0

    OnBegin<override>()<suspends>:void =
        HostileSpawner.EliminatedEvent.Subscribe(OnHostileEliminated)

        if (CashPropAssets.Length = 0):
            Print("WARNING: CashPropAssets is empty -- no cash will drop. Add the coin, cash bundle, toaster and TV prop assets in UEFN.")

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
            CashPropAssets.Length > 0
        then:
            CharacterLocation := FortCharacter.GetTransform().Translation
            Print("DEBUG: Body Z={CharacterLocation.Z} (ignored), Final drop Z={FloorHeight}")

            for (Item := 0..ItemsPerKill - 1):
                # Roll a scatter offset inside a square, then pull it back onto
                # the edge of the circle if it landed outside, so nothing ever
                # ends up further from the kill than ScatterRadius.
                RawOffset := vector3{X := GetRandomFloat(-ScatterRadius, ScatterRadius), Y := GetRandomFloat(-ScatterRadius, ScatterRadius), Z := 0.0}
                OffsetDistance := Distance(RawOffset, vector3{X := 0.0, Y := 0.0, Z := 0.0})
                Offset := if (OffsetDistance > ScatterRadius) then RawOffset * (ScatterRadius / OffsetDistance) else RawOffset
                DropLocation := vector3{X := CharacterLocation.X + Offset.X, Y := CharacterLocation.Y + Offset.Y, Z := FloorHeight}

                AssetIndex := NextAssetIndex
                if (NewIndex := Mod[NextAssetIndex + 1, CashPropAssets.Length]):
                    set NextAssetIndex = NewIndex

                if (Asset := CashPropAssets[AssetIndex]):
                    SpawnResult := SpawnProp(Asset, DropLocation, IdentityRotation())
                    if (Prop := SpawnResult(0)?):
                        Print("DEBUG: Spawned drop {Item + 1} of {ItemsPerKill}, asset {AssetIndex}, at X={DropLocation.X} Y={DropLocation.Y} Z={DropLocation.Z}")
                        spawn{ RunDropLifetime(Prop, DropLocation) }
                    else:
                        Print("DEBUG: SpawnProp failed for asset index {AssetIndex}")
                else:
                    Print("DEBUG: Asset index {AssetIndex} lookup failed")
        else:
            Print("DEBUG: GetFortCharacter failed, or CashPropAssets is empty")

    # One copy of this runs per dropped prop. It races the player against the
    # clock: whoever gets there first wins. Either way the prop is removed at
    # the end, so nothing outlives its 5 seconds (GDD 5.3).
    RunDropLifetime(Prop : creative_prop, DropLocation : vector3)<suspends>:void =
        var CollectedBy : ?agent = false
        race:
            block:
                Collector := AwaitPickup(DropLocation)
                set CollectedBy = option{Collector}
            Sleep(DespawnSeconds)

        if (CollectingAgent := CollectedBy?):
            OnCashCollected(CollectingAgent, DropLocation)
        else:
            Print("DEBUG: Drop despawned uncollected after {DespawnSeconds}s")

        Prop.Dispose()

    # Checks ten times a second whether anybody has walked close enough to the
    # drop, and hands back the first player who does.
    AwaitPickup(DropLocation : vector3)<suspends>:agent =
        var Collector : ?agent = false
        loop:
            for:
                Player : GetPlayspace().GetPlayers()
                FortCharacter := Player.GetFortCharacter[]
                Distance(FortCharacter.GetTransform().Translation, DropLocation) <= PickupRadius
            do:
                set Collector = option{Player}

            if (Found := Collector?):
                return Found

            Sleep(0.1)

    OnCashCollected(CollectingAgent : agent, DropLocation : vector3):void =
        set RunScore += 10
        Print("DEBUG: Drop collected at X={DropLocation.X} Y={DropLocation.Y}")

        # Move the speaker to the drop so the 'ding-ding-ding!' comes from the
        # right place. Best effort only: the stinger plays either way.
        if (CashPickupSound.TeleportTo[DropLocation, CashPickupSound.GetTransform().Rotation]):
            Print("DEBUG: Sound repositioned")
        else:
            Print("DEBUG: Sound TeleportTo failed -- playing anyway")
        CashPickupSound.Play()

        ScoreManager.Increment(CollectingAgent)
        Print("Cash collected! Running total: {RunScore}")
