# WaveManager.verse
#
# Implements the win half of GDD Section 2.5 "Win/Loss Resolution & Loop
# Termination": "A room is cleared when the player successfully eliminates all
# spawned waves in the active Escalation Tier." Also implements the escalation
# curve of GDD Section 5.5, 8% per tier hard-capped at Escalation Tier 21, and
# respects the 40-bot concurrency cap of GDD Section 5.3.
#
# SCOPE. Waves only. This device does not decide whether a run is won or lost,
# does not sound the game-show buzzer, does not touch score, and does not touch
# Hype. Those belong elsewhere and are deliberately left out. All this does is
# count hostiles in and out and keep the waves coming.
#
# VERSE DRIVES THE SPAWNING, NOT THE EDITOR.
# GDD 5.5 asks for spawn density to climb with the tier, and the NPC Spawner's
# Spawn Count cannot be changed at runtime: nothing in npc_spawner_device sets
# it, and only other spawner devices even expose a getter. So the pacing is done
# here instead. This device calls Spawn() on its own interval and tops the arena
# up to a concurrent target it works out per tier. Both the rate
# (SpawnIntervalSeconds) and the density (ConcurrentAtTier1) are script values
# that scale, rather than fixed editor settings.
#
# HOSTILE HEALTH AND SPEED SCALE BY SWAPPING THE DEFINITION.
# GDD 5.5 scales three things per tier: spawn density, hostile health pools and
# movement speeds. The last two live on the NPC character definition and cannot
# be set at runtime, so the wave manager swaps which definition the spawner uses
# as the tier climbs, stepping through TierDefinitions from weakest to
# strongest. The swap happens between waves, when nothing is alive, so it can
# never catch a hostile mid-fight. Leave TierDefinitions empty and none of this
# happens at all.
#
# HOW ONE WAVE RUNS.
#   1. Reset the spawner, work out this tier's wave size and concurrent target.
#   2. Enable the spawner, then call Spawn() every SpawnIntervalSeconds for as
#      long as fewer hostiles are alive than the concurrent target allows, until
#      WaveSize of them have appeared.
#   3. Disable the spawner so the wave is a fixed batch, not an endless stream.
#   4. Count EliminatedEvent until every hostile from that batch is dead.
#   5. Advance the Escalation Tier, grow both the wave size and the concurrent
#      target by TierScalingPercent, wait DelayBetweenWaves, and go round again.
#
# TWO REQUIRED UEFN SETTINGS.
#   * "Despawn AIs When Disabled" must be OFF. This device switches the spawner
#     off as soon as a wave is fully spawned, while those hostiles are alive and
#     fighting. With that setting ON, switching it off would delete the wave the
#     player is supposed to fight.
#   * The spawner's own automatic spawning must be turned down or off, by
#     setting its spawn interval very high. An enabled spawner still spawns on
#     its own schedule, and this device cannot stop that from script. If it is
#     left at 3 seconds, hostiles will arrive from two sources at once and the
#     concurrent target will be overshot.
#
# TWO SAFETY VALVES, BOTH LOUD.
# A capstone demo must not be able to lock up, so neither wave phase can wait
# forever. If spawning stalls, or if the arena empties without the eliminations
# being counted, the wave moves on and prints a WARNING saying exactly what it
# expected versus what it got. Neither one can fail quietly.

using { /Fortnite.com/Assets }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Simulation }

wave_manager := class(creative_device):

    @editable
    HostileSpawner : npc_spawner_device = npc_spawner_device{}

    # The hostile character definitions to step through as the tier climbs,
    # ordered WEAKEST FIRST. This is how GDD 5.5's health and movement-speed
    # scaling is delivered, since both live on the definition and neither can be
    # changed at runtime.
    #
    # The tier range is split evenly across however many entries are here, so
    # five entries against MaxTier 21 gives tiers 1-4, 5-8, 9-12, 13-16, 17-21.
    # Add or remove entries and the split recomputes itself.
    #
    # Entry 0 is applied at match start, so this list is authoritative from
    # Tier 1 onwards and whatever the spawner was given in UEFN is overridden.
    #
    # Leave it empty to switch tier scaling off entirely: the spawner then keeps
    # whatever definition it was given in UEFN and nothing here touches it.
    # Every entry must be the same character type, or the swap will be refused.
    @editable
    TierDefinitions : []npc_character_definition = array{}

    # How many hostiles are in the very first wave, at Escalation Tier 1.
    # Every later wave grows from this by TierScalingPercent.
    #
    # Written as a decimal, so 10.0 means ten hostiles. That looks odd for a
    # head count, and the reason is a Verse rule: it will not turn a whole
    # number into a decimal on its own. The running wave size has to be a
    # decimal for the 8% per tier to compound, so the starting size is one too.
    #
    # 10 is chosen to keep the Tier 21 wave near 47 hostiles. Starting higher
    # compounds into waves that are long rather than hard, because the
    # concurrency ceiling holds the pressure steady either way.
    @editable
    WaveSize : float = 10.0

    # How many hostiles may be alive at once at Escalation Tier 1. This is the
    # spawn density GDD 5.5 asks to scale, and it climbs per tier exactly like
    # the wave size does. A decimal for the same compounding reason.
    #
    # 3 rather than 5, from playtest: five shooters alive at once was
    # unsurvivable, which is the wrong shape for Tier 1 when GDD 2.4 wants the
    # first room-loop gentle.
    @editable
    ConcurrentAtTier1 : float = 3.0

    # How often this device tries to add one hostile, in seconds. This is the
    # spawn rate, and it is a script value now rather than an editor setting.
    @editable
    SpawnIntervalSeconds : float = 0.5

    # How long the spawn loop will keep asking for a hostile that never arrives
    # before it gives up on the rest of the wave, in seconds.
    #
    # Only time spent actually asking counts towards this. Waiting because the
    # arena is already as full as the concurrent target allows is normal play
    # and never counts, so a slow player can never trip it.
    @editable
    SpawnStallTimeoutSeconds : float = 15.0

    # How much bigger each wave gets per tier, as a percentage. GDD 5.5 fixes
    # this at exactly 8% per tier. It applies to both the wave size and the
    # concurrent target.
    @editable
    TierScalingPercent : float = 8.0

    # Where escalation stops. GDD 5.5 hard-caps it at Escalation Tier 21, about
    # 5x starting difficulty, so the late game stays hard but possible. Waves
    # keep coming past this point, they simply stop getting bigger.
    @editable
    MaxTier : int = 21

    # The ceiling on how many hostiles may be alive at once, capped at 40 bots
    # by GDD 5.3 to stay inside UEFN's budget. The per-tier concurrent target
    # scales up towards this and is never allowed past it.
    @editable
    MaxConcurrentHostiles : int = 40

    # The breather between one wave being cleared and the next starting, in
    # seconds.
    @editable
    DelayBetweenWaves : float = 3.0

    # How often the wave loop looks at its counters while waiting for a wave to
    # be cleared, in seconds. Not editable: this is bookkeeping, not something
    # that changes how the game feels.
    PollSeconds : float = 0.25

    # How many polls in a row must find nothing alive before a wave is declared
    # cleared on that basis alone. Four polls is one second. One reading of zero
    # is not trusted, because a hostile can read as not-yet-active for a moment
    # while it is still arriving.
    EmptyPollsToClear : int = 4

    # The Escalation Tier of GDD 5.5. Starts at 1, climbs by one per cleared
    # wave, stops at MaxTier.
    var CurrentTier : int = 1

    # The wave size carried as a decimal, so the 8% compounds properly. Rounding
    # to whole hostiles every tier would throw away the fraction each time and
    # the waves would grow too slowly.
    var WaveSizeExact : float = 0.0

    # The concurrent target carried as a decimal, for the same reason.
    var ConcurrentExact : float = 0.0

    # How many hostiles the wave in progress should spawn in total.
    var TargetThisWave : int = 0

    # How many may be alive at once during the wave in progress, already rounded
    # and already clamped to MaxConcurrentHostiles.
    var ConcurrentTarget : int = 0

    # Counters for the wave in progress. These track wave progress; they are not
    # used to decide how many are alive, which CountLiveHostiles answers.
    var SpawnedThisWave : int = 0
    var EliminatedThisWave : int = 0

    OnBegin<override>()<suspends>:void =
        HostileSpawner.SpawnedEvent.Subscribe(OnHostileSpawned)
        HostileSpawner.EliminatedEvent.Subscribe(OnHostileEliminated)

        # Start from a known state. Nothing spawns until a wave asks for it.
        HostileSpawner.Disable()

        # Seed the running values from the editable starting values.
        set WaveSizeExact = WaveSize
        set ConcurrentExact = ConcurrentAtTier1

        DefinitionCount := TierDefinitions.Length
        if (DefinitionCount > 0):
            Print("DEBUG: Tier scaling is ACTIVE -- {DefinitionCount} hostile definitions found, swapped between waves as the tier climbs.")
        else:
            Print("DEBUG: Tier scaling is OFF -- TierDefinitions is empty, so the spawner keeps the definition it was given in UEFN.")

        # Apply the Tier 1 entry before the first wave, so the list is
        # authoritative from the start rather than the arena running on
        # whatever definition the spawner happened to be given in UEFN.
        ApplyTierDefinition()

        RunWaves()

    # The wave loop. Runs for as long as the match does.
    RunWaves()<suspends>:void =
        loop:
            StartWave()
            RunSpawnLoop()

            # The batch is out. Shut the tap off so nothing else joins this
            # wave while the player is fighting it.
            HostileSpawner.Disable()
            LiveCount := CountLiveHostiles()
            Print("DEBUG: Wave fully spawned -- spawner off, {LiveCount} hostiles in the arena")

            AwaitWaveCleared()
            CompleteWave()
            Sleep(DelayBetweenWaves)

    StartWave():void =
        set SpawnedThisWave = 0
        set EliminatedThisWave = 0

        # In case the editor's Spawn Count is a total budget rather than a
        # concurrency cap. The digest describes Reset as "allowing spawning of a
        # new batch" without saying which it is, and calling it is harmless
        # either way.
        HostileSpawner.Reset()

        var Size : int = 1
        if (RoundedSize := Round[WaveSizeExact]):
            set Size = RoundedSize
        if (Size < 1):
            set Size = 1
        set TargetThisWave = Size

        var Concurrent : int = 1
        if (RoundedConcurrent := Round[ConcurrentExact]):
            set Concurrent = RoundedConcurrent
        if (Concurrent > MaxConcurrentHostiles):
            set Concurrent = MaxConcurrentHostiles
        if (Concurrent < 1):
            set Concurrent = 1
        set ConcurrentTarget = Concurrent

        LiveCount := CountLiveHostiles()
        Print("DEBUG: Wave started -- Escalation Tier {CurrentTier}, {TargetThisWave} hostiles to spawn, up to {ConcurrentTarget} alive at once, {LiveCount} alive right now")

        HostileSpawner.Enable()

    # Verse drives the spawning. While this wave still owes hostiles, top the
    # arena up towards ConcurrentTarget, one Spawn() per tick.
    #
    # SAFETY VALVE. Spawn() reports nothing, so a spawn that silently fails
    # would leave this loop asking forever and the wave would never end. If the
    # loop has been asking for SpawnStallTimeoutSeconds with room in the arena
    # and nothing has arrived, it gives up loudly and shrinks the wave to what
    # actually spawned, so the run carries on instead of deadlocking.
    RunSpawnLoop()<suspends>:void =
        # Seconds spent asking for a hostile with room available and getting
        # none. Reset to zero every time one actually arrives.
        var StalledSeconds : float = 0.0
        var SpawnedAtLastCheck : int = 0

        loop:
            if (SpawnedThisWave >= TargetThisWave):
                return

            LiveCount := CountLiveHostiles()
            if (LiveCount < ConcurrentTarget):
                # There is room, so a hostile should be arriving. Whether one
                # did since the last tick decides if this counts as a stall.
                if (SpawnedThisWave > SpawnedAtLastCheck):
                    set StalledSeconds = 0.0
                    set SpawnedAtLastCheck = SpawnedThisWave
                else:
                    set StalledSeconds += SpawnIntervalSeconds

                if (StalledSeconds >= SpawnStallTimeoutSeconds):
                    Print("WARNING: Wave gave up waiting for hostiles to spawn. Expected {TargetThisWave}, got {SpawnedThisWave}, after {StalledSeconds}s of asking with room in the arena. Continuing with what spawned. Check the spawner's Spawn Count and that Verse is the only thing driving it.")
                    set TargetThisWave = SpawnedThisWave
                    return

                HostileSpawner.Spawn()

            Sleep(SpawnIntervalSeconds)

    # How many of this spawner's hostiles are actually in the world right now.
    #
    # GetAgents hands back everything the device has created, and its
    # description does not promise that eliminated ones are dropped from that
    # list. So every agent is checked with IsActive, which succeeds only for a
    # character that is in the world and has not been eliminated.
    CountLiveHostiles()<transacts>:int =
        var Count : int = 0
        for:
            Hostile : HostileSpawner.GetAgents()
            FortCharacter := Hostile.GetFortCharacter[]
            FortCharacter.IsActive[]
        do:
            set Count += 1
        Count

    # Waits for every hostile in this wave to be eliminated.
    #
    # SAFETY VALVE. A hostile that leaves the arena without firing
    # EliminatedEvent would leave this loop waiting on a count that can never be
    # reached. So an empty arena also clears the wave: if nothing at all is
    # alive for EmptyPollsToClear polls in a row, the wave is over whatever the
    # counter says, and it says so loudly.
    #
    # That valve is not armed until at least one hostile has been confirmed
    # alive during this wave. Freshly spawned hostiles read as not-yet-active
    # for around a second while they arrive, and without the guard the valve
    # fired on that gap and ended waves before the fight had started.
    AwaitWaveCleared()<suspends>:void =
        var EmptyPolls : int = 0

        # Arms the empty-arena valve. Stays false until something has actually
        # been seen alive, so an arena that is merely not populated YET can
        # never be mistaken for one that has been cleared.
        var HasSeenLiveHostile : logic = false

        loop:
            if (EliminatedThisWave >= TargetThisWave):
                return

            LiveCount := CountLiveHostiles()
            if (LiveCount = 0):
                set EmptyPolls += 1
            else:
                set EmptyPolls = 0
                set HasSeenLiveHostile = true

            if (HasSeenLiveHostile?):
                if (EmptyPolls >= EmptyPollsToClear):
                    Print("WARNING: Wave cleared because nothing is alive, but only {EliminatedThisWave} of {TargetThisWave} eliminations were counted. {TargetThisWave - EliminatedThisWave} hostiles left the arena without firing EliminatedEvent.")
                    return

            Sleep(PollSeconds)

    CompleteWave():void =
        # Tier, wave size and density climb only while under the GDD 5.5 cap.
        # Past it, waves keep coming at the Tier 21 numbers.
        if (CurrentTier < MaxTier):
            set CurrentTier += 1
            Multiplier := 1.0 + TierScalingPercent / 100.0
            set WaveSizeExact = WaveSizeExact * Multiplier
            set ConcurrentExact = ConcurrentExact * Multiplier

        # Swap the hostile for the new tier now, in the gap between waves.
        ApplyTierDefinition()

        var NextSize : int = TargetThisWave
        if (RoundedSize := Round[WaveSizeExact]):
            set NextSize = RoundedSize

        var NextConcurrent : int = ConcurrentTarget
        if (RoundedConcurrent := Round[ConcurrentExact]):
            set NextConcurrent = RoundedConcurrent
        if (NextConcurrent > MaxConcurrentHostiles):
            set NextConcurrent = MaxConcurrentHostiles

        Print("DEBUG: Wave cleared -- Escalation Tier is now {CurrentTier} of a maximum {MaxTier}, next wave {NextSize} hostiles at up to {NextConcurrent} alive at once")

    # Which entry in TierDefinitions the current tier falls into.
    #
    # The tier range is divided evenly across however many entries the list
    # holds. The block size is the largest number of tiers that still fits every
    # entry inside MaxTier, so five entries and MaxTier 21 gives blocks of four:
    # tiers 1-4, 5-8, 9-12, 13-16, and the last entry absorbing 17-21. Nothing
    # is hardcoded, so adding or removing entries just works.
    #
    # This counts up in blocks rather than dividing. Verse's integer division is
    # not something this file relies on anywhere, and with MaxTier at 21 these
    # loops are trivially short.
    TierDefinitionIndex()<transacts>:int =
        Count := TierDefinitions.Length

        # The largest block size that still fits Count blocks inside MaxTier.
        var BlockSize : int = 1
        for (Candidate := 1..MaxTier):
            if (Candidate * Count <= MaxTier):
                set BlockSize = Candidate

        # How many whole blocks the current tier is past. The loop stops at
        # Count - 1, so the top entry absorbs any leftover tiers and the result
        # can never point past the end of the list.
        var Index : int = 0
        for (Step := 1..Count - 1):
            if (Step * BlockSize <= CurrentTier - 1):
                set Index = Step

        Index

    # Points the spawner at the hostile definition for the current tier.
    #
    # Called once at OnBegin so entry 0 is in force from Tier 1, and again from
    # CompleteWave in the gap between waves when nothing is alive. That gap is
    # deliberate: the digest does not say whether swapping a definition affects
    # hostiles already in the arena, and doing it there means there are none for
    # the question to apply to.
    #
    # Does nothing at all when TierDefinitions is empty.
    ApplyTierDefinition():void =
        Count := TierDefinitions.Length
        if (Count > 0):
            Index := TierDefinitionIndex()
            if (Definition := TierDefinitions[Index]):
                if (HostileSpawner.SetNPCCharacterDefinition[Definition]):
                    Print("DEBUG: Tier {CurrentTier} hostile definition set to entry {Index}, counting from 0, of {Count}")
                else:
                    Print("WARNING: SetNPCCharacterDefinition was refused for entry {Index} at Tier {CurrentTier}. Its documentation says it fails when the character type differs from the current definition, so check every entry in TierDefinitions is the same character type. Hostiles stay as they were.")
            else:
                Print("WARNING: TierDefinitions entry {Index} could not be read at Tier {CurrentTier}. Hostiles stay as they were.")

    OnHostileSpawned(SpawnedAgent : agent):void =
        set SpawnedThisWave += 1
        LiveCount := CountLiveHostiles()
        Print("DEBUG: Hostile spawned -- {SpawnedThisWave} of {TargetThisWave} this wave, {LiveCount} alive now")

    OnHostileEliminated(Result : device_ai_interaction_result):void =
        set EliminatedThisWave += 1
        Remaining := TargetThisWave - EliminatedThisWave
        LiveCount := CountLiveHostiles()
        Print("DEBUG: Hostile eliminated -- {Remaining} left in this wave, {LiveCount} alive now")
