# WaveManager.verse
#
# Implements the win half of GDD Section 2.5 "Win/Loss Resolution & Loop
# Termination": "A room is cleared when the player successfully eliminates all
# spawned waves in the active Escalation Tier." Also implements the escalation
# curve of GDD Section 5.5, 8% per tier hard-capped at Escalation Tier 21, and
# respects the 40-bot concurrency cap of GDD Section 5.3.
#
# SCOPE. Waves, and the win buzzer that marks one being cleared. This device
# does not decide whether a run is won or lost, does not touch score, and does
# not touch Hype. Those belong elsewhere and are deliberately left out.
#
# THE BUZZER. GDD 2.5 sounds "a loud game-show buzzer" when a room is cleared,
# and GDD 1.1 calls it "a satirical game-show buzzer at wave completion". One
# wave is one room here, so both land on the same instant. It sounds at every
# tier including the Tier 21 cap: Kai's ruling 2026-08-17, amendment 23, since
# 1.1 ties the buzzer to wave completion and never to tiers, and going silent
# at the ceiling would read as a fault rather than a design choice.
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
# THE ONBOARDING RAMP, HOSTILES ONLY.
# GDD 2.4 introduces systems gradually over the first rooms. Kai's ruling
# 2026-08-21, amendment 56: the hostile half of that ramp is built and the
# HUD/Hype/crate blackout half is tabled. Boars join at room 2, Sentinels at
# room 3, Tanks at room 4, each type getting a room to itself before the next
# lands. That fills the gap 2.4 leaves by listing rooms 1, 2, 4 and 5 and
# skipping 3.
#
# THE RAMP RUNS ON EVERY RUN, not only the first life. A deliberate departure
# from 2.4's "Restart Skip", Kai's ruling 2026-08-21. A lost run ends the
# match, so a fresh run restarts this device at Tier 1 and the ramp returns by
# itself. Honouring Restart Skip would have meant remembering deaths between
# matches, and would have put Tanks in the opening seconds of every run after
# the first death, which is the thing the ramp exists to prevent.
#
# A LOCKED TYPE LEAVES ITS SEATS EMPTY. Locked types keep their share of the
# arena and never fill it, so room 1 runs at five tenths of the density, room 2
# at seven, room 3 at nine, room 4 onwards at full. The number to clear shrinks
# by the same fraction, so a thinner room is also a shorter one and every room
# still runs about two minutes, per Kai's ruling 2026-08-18. Renormalising the
# shares instead would have made room 1 twenty Swarmers, as busy as any later
# room, and would have hidden the ramp completely.
#
# HOW ONE WAVE RUNS.
#   1. Reset the spawner, work out this tier's wave size and concurrent target.
#   2. Enable the spawner, then call Spawn() every SpawnIntervalSeconds for as
#      long as fewer hostiles are alive than the concurrent target allows, until
#      WaveSize of them have appeared.
#   3. The spawn loop stops there, which is what makes the wave a fixed batch.
#      Nothing further arrives, because the device only ever spawns when this
#      script asks it to.
#   4. Count EliminatedEvent until every hostile from that batch is dead.
#   5. Advance the Escalation Tier, grow both the wave size and the concurrent
#      target by TierScalingPercent, wait DelayBetweenWaves, and go round again.
#
# A REQUESTED HOSTILE TAKES ABOUT TWO SECONDS TO ARRIVE.
# Spawn() returns at once but the hostile is not in the world yet, and until it
# is, CountLiveHostiles cannot see it. So the loop keeps a count of what it has
# already asked for, SpawnsInFlight, and treats those as if they were already
# standing there. Without it the loop asked all through the arrival gap and
# overshot the target by about six, which is how a room built for ten held
# sixteen on 2026-08-21. Amendment 57.
#
# ONE REQUIRED UEFN SETTING.
#   * The spawner's own automatic spawning must be OFF. This means ALL FOUR
#     spawner devices, not just one: on 2026-08-21 the Boar, Sentinel and Tank
#     devices each had Spawn On Timer set to Yes on a three-second period, so
#     three uninvited hostiles arrived every three seconds, in room 1, where the
#     ramp had let none of those types in. Amendment 57. With Spawn On Timer
#     disabled, an enabled spawner produces nothing by itself and every hostile
#     arrives because this script called Spawn(). If the device also spawns on
#     its own schedule, hostiles come from two sources at once and the
#     concurrent target is overshot.
#
# WHY THIS DEVICE NEVER CALLS Disable(). DO NOT ADD IT BACK.
# It used to, to cap a wave once WaveSize had spawned. That call was deleting
# the hostiles still alive at the moment it ran. Across three consecutive waves
# the number that vanished without firing EliminatedEvent was exactly the number
# alive when Disable() was called, every time. This happened with "Despawn AIs
# When Disabled" already unticked, so either that setting does not behave as
# documented in this version, or Disable() despawns regardless of it.
#
# With Spawn On Timer off the call has no job left to do, so it is gone. The
# wave is capped by the spawn loop finishing, not by switching the device off.
#
# TWO SAFETY VALVES, BOTH LOUD.
# A capstone demo must not be able to lock up, so neither wave phase can wait
# forever. If spawning stalls, or if the arena empties without the eliminations
# being counted, the wave moves on and prints a WARNING saying exactly what it
# expected versus what it got. Neither one can fail quietly.

using { /Fortnite.com/Assets }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }
using { /Verse.org/Colors }
using { /Verse.org/Simulation }

# text_block takes a message rather than a string, so the banner text has to pass
# through a localizes function. It holds no wording of its own.
BannerLine<localizes>(Value : string) : message = "{Value}"

wave_manager := class(creative_device):

    # ONE SPAWNER PER HOSTILE TYPE. Amendment 45: all four share the arena at
    # once, and SetNPCCharacterDefinition is refused across different character
    # types, so one device cannot serve them all. Named slots rather than array
    # rows, because a mis-ordered row is silent and a named slot is not.
    @editable
    SwarmerSpawner : npc_spawner_device = npc_spawner_device{}

    @editable
    BoarSpawner : npc_spawner_device = npc_spawner_device{}

    @editable
    SentinelSpawner : npc_spawner_device = npc_spawner_device{}

    @editable
    TankSpawner : npc_spawner_device = npc_spawner_device{}

    # How the concurrent target is divided. Amendment 45's mix is five Swarmers,
    # two Boars, two Sentinels and one Tank out of every ten alive. Shares rather
    # than counts, so the proportions hold as the tier climbs and the crowd grows.
    @editable
    SwarmerShare : float = 5.0

    @editable
    BoarShare : float = 2.0

    @editable
    SentinelShare : float = 2.0

    @editable
    TankShare : float = 1.0

    # THE ONBOARDING RAMP of GDD 2.4. The room each type first appears in, so
    # the player meets one new hostile at a time. Kai's ruling 2026-08-21.
    # Swarmers are always in from room 1, so they have no field here.
    #
    # Room and Escalation Tier are the same counter, per GDD 2.5, so these are
    # tier numbers. Set all three to 1 to switch the ramp off and have all four
    # types present from the first room, which is what the build did before.
    @editable
    BoarJoinsAtTier : int = 2

    @editable
    SentinelJoinsAtTier : int = 3

    @editable
    TankJoinsAtTier : int = 4

    # HOW MANY SENTINELS AND TANKS A WHOLE WAVE MAY CONTAIN, while they are still
    # meant to be rare. Kai's rulings 2026-08-22, from the room list Kai wrote
    # out twice: room 3 is Swarmers, a few Boars and two Sentinels; room 4 adds
    # one Tank.
    #
    # THESE ARE WHOLE-WAVE QUOTAS, NOT A LIMIT ON HOW MANY ARE ALIVE AT ONCE.
    # Kill the wave's one Tank and no other Tank arrives until the next wave.
    # That is the point of them: a heavy that returns the moment it dies is
    # constant pressure rather than an event, and Kai asked for it to keep
    # feeling like a big deal.
    #
    # The rationed slots do not leave the arena thin. A type that has used up its
    # quota drops out of the mix and Swarmers and Boars fill the space, so the
    # crowd stays the size the tier says and only its make-up changes.
    @editable
    SentinelsOnArrival : int = 2

    # From the room after they arrive until RareTypesEndAtTier. Kai's "two or
    # three a wave for a good stretch".
    @editable
    SentinelsWhileRare : int = 3

    @editable
    TanksOnArrival : int = 1

    # Kai's "one or two a wave" for the stretch after the Tank arrives.
    @editable
    TanksWhileRare : int = 2

    # Where the rationing stops and both types go back to taking their share of
    # the crowd like Swarmers and Boars. Kai's ruling 2026-08-22: about room
    # fifteen, so the Tank is a rare terror for eleven rooms before it ever
    # becomes ordinary.
    @editable
    RareTypesEndAtTier : int = 15

    # The placed Audio Player holding the win buzzer. GDD 5.4 budgets two
    # game-show buzzer sounds and this is the first; the second is the losing
    # buzzer in DeathSaveManager. Set this device to be heard everywhere rather
    # than fading with distance, or it is faint from the far side of the arena.
    @editable
    WinBuzzer : audio_player_device = audio_player_device{}

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
    # One list per type, amendment 48, five cards each, weakest first. A type
    # with an empty list keeps whatever card its spawner was given in UEFN.
    @editable
    SwarmerDefinitions : []npc_character_definition = array{}

    @editable
    BoarDefinitions : []npc_character_definition = array{}

    @editable
    SentinelDefinitions : []npc_character_definition = array{}

    @editable
    TankDefinitions : []npc_character_definition = array{}

    # The Barrier devices standing in the arena's doorways. Each hostile is added
    # to every one of these ignore lists as it spawns and taken off again when it
    # dies, so hostiles walk through the doorway and the player cannot.
    #
    # WHY THIS IS DONE IN CODE. The Barrier's own Ignore Team and Ignore Class
    # settings were both tried on 2026-08-22, with the hostiles' team index of 2
    # and Can NPC Added to Ignore List ticked, and hostiles were still stopped.
    # AddToIgnoreList is a separate mechanism, described in the digest as being
    # "in addition to the Ignore Team and Ignore Class options", and it is the one
    # that works.
    #
    # IT WORKS ON THE HOSTILE, NOT ON WHAT THE HOSTILE IS. Kai's concern on
    # 2026-08-22 was that the look and the weapons are still being changed during
    # play. Nothing here reads a character definition, a model or a weapon, so
    # changing any of them cannot break this.
    #
    # Leave it empty and nothing happens, which is what you want if the doorways
    # are ever sealed instead.
    @editable
    ArenaBarriers : []barrier_device = array{}

    # HOW LONG A WAVE SHOULD LAST, IN SECONDS. The head count is worked out from
    # this rather than set by hand, so the dial is the thing Kai actually thinks
    # in. Kai's rulings 2026-08-22.
    #
    # WHY THIS REPLACED A FIXED WAVE SIZE. The 2026-08-18 ruling fixed the head
    # count so waves stayed the same length and escalation went into crowding.
    # In play it did the opposite: a fixed head count against a crowd that grows
    # 8% a tier means more targets in reach, so later waves finished FASTER. Kai
    # spotted that on 2026-08-22 and reversed the ruling. Length escalates on
    # purpose now, and 2m30 is the ceiling it may never pass.
    #
    # Wave one is the tutorial, so 45 seconds: long enough to learn running one
    # way while shooting another, see the first cash burst and catch one crate on
    # the 25-second trickle, short enough that the escalation arrives while the
    # player still cares.
    #
    # 30, Kai's ruling 2026-08-24, after 15 was tried and 45 was too long. That is
    # about 33 hostiles rather than 50, so the first escalation arrives while the
    # opening wave still has the player's attention.
    @editable
    WaveSecondsAtTier1 : float = 30.0

    # How many seconds longer each tier's wave runs than the one before. 6 takes
    # 30 seconds at Tier 1 to 150 at Tier 21, where GDD 5.5 caps escalation, so
    # the ramp and the cap still land together.
    @editable
    WaveSecondsPerTier : float = 6.0

    # The longest a wave may ever run, in seconds. Kai's ruling 2026-08-22:
    # "2m30 is the longest wave that will ever exist." This game has no end, so
    # every wave past Tier 21 sits here.
    @editable
    WaveSecondsMax : float = 150.0

    # How many hostiles the player kills a second, per hostile on screen. A
    # wave's head count is this times the crowd size times the seconds above.
    #
    # 0.11 from the 2026-08-22 log: 92 kills in 78 seconds with 10 on screen is
    # 1.18 a second, and the earlier 20-on-screen reading was about 2.2. A
    # measured first guess, not a law. If waves run long, lower it; if they end
    # early, raise it.
    @editable
    KillsPerSecondPerHostileOnScreen : float = 0.11

    # How much longer a kill takes for each step up the hostile card ladder.
    # 1.36 from amendment 46's health table: the Boar ladder runs 80, 109, 148,
    # 202, 274, which is 1.36 times tougher a step, and the other three ladders
    # were built to the same ratio.
    @editable
    ToughnessPerCardStep : float = 1.36

    # How many hostiles may be alive at once at Escalation Tier 1. This is the
    # spawn density GDD 5.5 asks to scale, and it climbs per tier exactly like
    # the wave size does. A decimal for the same compounding reason.
    #
    # 10, DOWN FROM 20 AND EXPLICITLY TEMPORARY. Kai's ruling 2026-08-19, after
    # playing it: at 20 with only the pistol, hostiles built up faster than they
    # could be cleared, the measured kill rate being 0.18 a second, so the arena
    # boxed the player in rather than being outrun. Kai asked to be made faster
    # and that is not the fault: amendment 31 measured the player at 11.90 m/s
    # against a hostile top speed of 5.6, so speed is already more than double.
    # The arsenal is the bottleneck, not the density, so this rises again once
    # the crate weapons exist. It also makes GDD 3.1's four-kills-in-0.4-seconds
    # cluster reachable, which is currently the only source of Hype in the game.
    #
    # 20 was itself up from 3, Kai's ruling 2026-08-18: the GDD's references are
    # Smash TV and Total Carnage, which flood the screen, and 3 at a time is a
    # queue rather than a rush. That 3 came from a playtest where five at once
    # was unsurvivable, but that was before the pistol stopped running dry on
    # 2026-08-17, so it judged a fight where you could be caught with an empty
    # gun. Every hostile in the map is melee, and kiting exists to handle crowds.
    #
    # At 20 this reaches GDD 5.3's ceiling of 40 at about Tier 10, so the density
    # the GDD asks for actually arrives inside a run. Past that the 8% has to come
    # from tougher hostiles, which is what TierDefinitions is for.
    #
    # Was 10 from 2026-08-19, parked low until the crate weapons were proven.
    # Crates landed on 2026-08-20 and Kai raised it the same evening. 40 was not
    # taken directly because bullets and cash drops now share the ~100 prop budget
    # and GDD 5.1 makes 60 FPS a hard target.
    @editable
    ConcurrentAtTier1 : float = 20.0

    # How often this device tries to add one hostile, in seconds. This is the
    # spawn rate, and it is a script value now rather than an editor setting.
    # 0.25 rather than 0.5. At two hostiles a second the spawner could only just
    # match the player's kill rate, so the arena never filled to its target.
    @editable
    SpawnIntervalSeconds : float = 0.25

    # How long the spawn loop will keep asking for a hostile that never arrives
    # before it gives up on the rest of the wave, in seconds.
    #
    # Only time spent actually asking counts towards this. Waiting because the
    # arena is already as full as the concurrent target allows is normal play
    # and never counts, so a slow player can never trip it.
    @editable
    SpawnStallTimeoutSeconds : float = 15.0

    # How long a hostile the script asked for may be on its way before the loop
    # stops counting it, in seconds. Arrival was measured at about two seconds on
    # 2026-08-21, so five is generous. Without this, one spawn that silently
    # failed would hold a slot for the rest of the wave and the room would run
    # short for ever after.
    @editable
    SpawnArrivalTimeoutSeconds : float = 5.0

    # How much denser each wave gets per tier, as a percentage. GDD 5.5 fixes
    # this at exactly 8% per tier. It applies to the concurrent target ONLY;
    # wave size is fixed, so waves stay the same length and get busier. See
    # WaveSize above for the ruling.
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
    MaxConcurrentHostiles : float = 40.0

    # The breather between one wave being cleared and the next starting, in
    # seconds.
    @editable
    DelayBetweenWaves : float = 3.0

    # GDD 1 asks for "flashing scoreboard visuals" and GDD 2.5 names the moment
    # "Room Won". Until now only the buzzer marked it and nothing did visually.
    # Kai's call 2026-08-20: big and centre, so it cannot be missed mid-fight.
    # Kept under DelayBetweenWaves so it is gone before the next wave arrives.
    @editable
    BannerSeconds : float = 2.0

    # Amendment 36 Layer 2: Broadcast Purple is the designated colour for "HUD
    # panel backgrounds, chat widget frame, title cards", and this is a title
    # card. Floodlight Warm for the text. Neither is a reserved Layer 3 gameplay
    # colour, so the banner can never be mistaken for something that hurts or heals.
    BannerPanelColor : color = MakeColorFromHex("7A2E8C")
    BannerTextColor : color = MakeColorFromHex("FFE9A8")

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

    # Read-only access for other devices. CareerRankManager needs the tier
    # reached at the moment a run ends, per GDD 2.6. This only reports the
    # number; it changes nothing, and this file's scope is unchanged.
    GetCurrentTier<public>()<transacts>:int = CurrentTier

    # ROOMS WON AND ROBOTS SCRAPPED, for the game over card's stats panel.
    #
    # Neither could be worked out from what was already here. CurrentTier stops
    # climbing at MaxTier while waves keep coming, so it stops being a count of
    # rooms at tier 21, and EliminatedThisWave is wiped at the start of every
    # wave. These two are the run's own totals and nothing resets them but a
    # fresh run.
    var RoomsWon : int = 0
    var RunEliminations : int = 0

    GetRoomsWon<public>()<transacts>:int = RoomsWon
    GetRunEliminations<public>()<transacts>:int = RunEliminations

    # How long the wave in progress should run, in seconds. Grows by
    # WaveSecondsPerTier each tier and stops at WaveSecondsMax.
    var WaveSecondsExact : float = 0.0

    # The concurrent target carried as a decimal, so the 8% compounds properly.
    # Rounding every tier would throw the fraction away and the crowd would grow
    # too slowly.
    var ConcurrentExact : float = 0.0

    # The same after the onboarding ramp has thinned it and GDD 5.3's ceiling has
    # capped it, still a decimal. The head count is worked out from this, and
    # ConcurrentTarget is just this rounded.
    var ConcurrentNowExact : float = 0.0

    # How many hostiles the wave in progress should spawn in total.
    var TargetThisWave : int = 0

    # How many may be alive at once during the wave in progress, already rounded
    # and already clamped to MaxConcurrentHostiles.
    var ConcurrentTarget : int = 0

    # Counters for the wave in progress. These track wave progress; they are not
    # used to decide how many are alive, which CountLiveHostiles answers.
    var SpawnedThisWave : int = 0
    var EliminatedThisWave : int = 0

    # How many of each type this wave has asked for, in the AllSpawners order.
    # Counted when asked for rather than when it arrives, because that is where
    # the decision is made and a request that never lands is already handled by
    # SpawnsInFlight. Reset at the start of every wave.
    var SpawnedByType : []int = array{0, 0, 0, 0}

    # Hostiles asked for that have not arrived yet. A spawn takes about two
    # seconds to appear and counts nowhere until it does, because
    # CountLiveHostiles can only see characters already in the world. Without
    # this the loop kept asking through that gap and overshot by about six, which
    # is how a room built for ten held sixteen. Measured from the log 2026-08-21.
    var SpawnsInFlight : int = 0

    # Seconds since a hostile last actually arrived, used only to release
    # reservations that are never going to be filled.
    var SecondsSinceArrival : float = 0.0

    OnBegin<override>()<suspends>:void =
        for (Spawner : AllSpawners()):
            Spawner.SpawnedEvent.Subscribe(OnHostileSpawned)
            Spawner.EliminatedEvent.Subscribe(OnHostileEliminated)

        # Seed the running values from the editable starting values.
        set WaveSecondsExact = WaveSecondsAtTier1
        set ConcurrentExact = ConcurrentAtTier1

        for (SlotIndex := 0..3):
            DefinitionCount := DefinitionsFor(SlotIndex).Length
            if (DefinitionCount > 0):
                Log("DEBUG: Tier scaling ACTIVE for spawner {SlotIndex} -- {DefinitionCount} cards, swapped between waves as the tier climbs.")
            else:
                Log("DEBUG: Tier scaling OFF for spawner {SlotIndex} -- its card list is empty, so it keeps whatever definition it was given in UEFN.")

        # Apply the Tier 1 entry before the first wave, so the list is
        # authoritative from the start rather than the arena running on
        # whatever definition the spawner happened to be given in UEFN.
        ApplyTierDefinition()

        # Nothing spawns until PLAY is clicked. Amendment 70.
        AwaitMatchStart(Self)

        RunWaves()

    # The wave loop. Runs for as long as the match does.
    RunWaves()<suspends>:void =
        loop:
            StartWave()
            RunSpawnLoop()

            # The batch is out. Nothing else will arrive, because the device
            # only spawns when this script calls Spawn() and the spawn loop has
            # finished. Switching the device off here used to delete the
            # hostiles still alive; see the file header.
            LiveCount := CountLiveHostiles()
            Log("DEBUG: Wave fully spawned -- {LiveCount} hostiles in the arena")

            AwaitWaveCleared()
            CompleteWave()
            Sleep(DelayBetweenWaves)

    StartWave():void =
        set SpawnedThisWave = 0
        set EliminatedThisWave = 0
        set SpawnedByType = array{0, 0, 0, 0}
        set SpawnsInFlight = 0
        set SecondsSinceArrival = 0.0

        # In case the editor's Spawn Count is a total budget rather than a
        # concurrency cap. The digest describes Reset as "allowing spawning of a
        # new batch" without saying which it is, and calling it is harmless
        # either way.
        for (Spawner : AllSpawners()):
            Spawner.Reset()

        # The ramp thins the early rooms: a type that has not joined yet leaves
        # its share of the arena empty, so fewer hostiles are on screen.
        Fraction := RampFraction()

        # The crowd first, because the head count is worked out from it.
        var Crowd : float = ConcurrentExact * Fraction
        if (Crowd > MaxConcurrentHostiles):
            set Crowd = MaxConcurrentHostiles
        if (Crowd < 1.0):
            set Crowd = 1.0
        set ConcurrentNowExact = Crowd

        var Concurrent : int = 1
        if (RoundedConcurrent := Round[Crowd]):
            set Concurrent = RoundedConcurrent
        set ConcurrentTarget = Concurrent

        # The head count is the wave's length times how fast this crowd dies, so
        # the wave runs about as long as WaveSecondsExact says it should.
        var Size : int = 1
        if (RoundedSize := Round[WaveSecondsExact * KillsPerSecondPerHostileOnScreen * Crowd / ToughnessFactor()]):
            set Size = RoundedSize
        if (Size < 1):
            set Size = 1
        set TargetThisWave = Size

        LiveCount := CountLiveHostiles()
        Log("DEBUG: Wave started -- Escalation Tier {CurrentTier}, {TargetThisWave} hostiles to spawn, up to {ConcurrentTarget} alive at once, {LiveCount} alive right now, types in play {UnlockedTypeNames()}")

        # Waking a spawner makes it produce one hostile of its own accord, so a
        # type the ramp has not admitted must not be woken: that is where the
        # Tank in room 1 came from, 2026-08-21. Each device is woken on the one
        # wave its type joins and never again, so the freebie lands on the wave
        # that type was going to arrive in anyway. Amendment 57.
        for (SlotIndex -> Spawner : AllSpawners()):
            if (CurrentTier = JoinTierFor(SlotIndex)):
                Spawner.Enable()

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

            # A request that never lands would otherwise hold its slot for the
            # rest of the wave, so a reservation this old is written off.
            if (SpawnsInFlight > 0):
                set SecondsSinceArrival += SpawnIntervalSeconds
                if (SecondsSinceArrival >= SpawnArrivalTimeoutSeconds):
                    Log("WARNING: {SpawnsInFlight} requested hostile(s) never arrived after {SecondsSinceArrival}s. Releasing the reservation and asking again. Check that nothing else is despawning hostiles.")
                    set SpawnsInFlight = 0
                    set SecondsSinceArrival = 0.0

            if (LiveCount + SpawnsInFlight < ConcurrentTarget):
                # There is room, so a hostile should be arriving. Whether one
                # did since the last tick decides if this counts as a stall.
                if (SpawnedThisWave > SpawnedAtLastCheck):
                    set StalledSeconds = 0.0
                    set SpawnedAtLastCheck = SpawnedThisWave
                else:
                    set StalledSeconds += SpawnIntervalSeconds

                if (StalledSeconds >= SpawnStallTimeoutSeconds):
                    Log("WARNING: Wave gave up waiting for hostiles to spawn. Expected {TargetThisWave}, got {SpawnedThisWave}, after {StalledSeconds}s of asking with room in the arena. Continuing with what spawned. Check the spawner's Spawn Count and that Verse is the only thing driving it.")
                    set TargetThisWave = SpawnedThisWave
                    return

                SpawnNext()

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
            Spawner : AllSpawners()
            Hostile : Spawner.GetAgents()
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
                    Log("WARNING: Wave cleared because nothing is alive, but only {EliminatedThisWave} of {TargetThisWave} eliminations were counted. {TargetThisWave - EliminatedThisWave} hostiles left the arena without firing EliminatedEvent.")
                    return

            Sleep(PollSeconds)

    CompleteWave():void =
        # GDD 2.5's "loud game-show buzzer", sounded the instant the room is
        # clear and before the tier moves, so it marks what the player just did
        # rather than what comes next.
        WinBuzzer.Play()

        # Counted here rather than off the tier, because past MaxTier the tier
        # stops moving and the rooms keep being won.
        set RoomsWon += 1

        # Tier, wave size and density climb only while under the GDD 5.5 cap.
        # Past it, waves keep coming at the Tier 21 numbers.
        if (CurrentTier < MaxTier):
            set CurrentTier += 1
            Multiplier := 1.0 + TierScalingPercent / 100.0
            set ConcurrentExact = ConcurrentExact * Multiplier
            set WaveSecondsExact = WaveSecondsExact + WaveSecondsPerTier
            if (WaveSecondsExact > WaveSecondsMax):
                set WaveSecondsExact = WaveSecondsMax

        # Swap the hostile for the new tier now, in the gap between waves.
        ApplyTierDefinition()

        # After the tier has moved, so the banner names the tier being entered.
        spawn{ ShowBanner("ROOM WON!", "ESCALATION TIER {CurrentTier}") }

    # GDD 2.5's Room Won, on screen. Built as a whole canvas per showing rather
    # than one kept and hidden, because a wave ends every couple of minutes at
    # most and a widget that is never removed is a widget that leaks.
    ShowBanner(TopLine : string, BottomLine : string)<suspends>:void =
        Panel := color_block:
            DefaultColor := BannerPanelColor
            DefaultOpacity := 0.75
            DefaultDesiredSize := vector2{X := 700.0, Y := 160.0}

        Top := text_block:
            DefaultText := BannerLine(TopLine)
            DefaultTextColor := BannerTextColor
            DefaultTextSize := 64.0
            DefaultJustification := text_justification.Center

        Bottom := text_block:
            DefaultText := BannerLine(BottomLine)
            DefaultTextColor := BannerTextColor
            DefaultTextSize := 32.0
            DefaultJustification := text_justification.Center

        BannerCanvas := canvas:
            Slots := array:
                canvas_slot:
                    Widget := Panel
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.45}, Maximum := vector2{X := 0.5, Y := 0.45}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                canvas_slot:
                    Widget := Top
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.42}, Maximum := vector2{X := 0.5, Y := 0.42}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                canvas_slot:
                    Widget := Bottom
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.49}, Maximum := vector2{X := 0.5, Y := 0.49}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}

        # Every player who has a UI right now, so the banner is removed from
        # exactly the ones it was added to and nothing is left behind.
        var Shown : []player_ui = array{}
        for (P : GetPlayspace().GetPlayers(), UI := GetPlayerUI[P]):
            UI.AddWidget(BannerCanvas)
            set Shown += array{UI}

        Sleep(BannerSeconds)

        for (UI : Shown):
            UI.RemoveWidget(BannerCanvas)

        # The tier has already moved, so this fraction describes the room about
        # to start, not the one just cleared.
        NextFraction := RampFraction()

        var NextCrowd : float = ConcurrentExact * NextFraction
        if (NextCrowd > MaxConcurrentHostiles):
            set NextCrowd = MaxConcurrentHostiles

        var NextConcurrent : int = ConcurrentTarget
        if (RoundedConcurrent := Round[NextCrowd]):
            set NextConcurrent = RoundedConcurrent

        var NextSize : int = TargetThisWave
        if (RoundedSize := Round[WaveSecondsExact * KillsPerSecondPerHostileOnScreen * NextCrowd / ToughnessFactor()]):
            set NextSize = RoundedSize

        Log("DEBUG: Wave cleared -- Escalation Tier is now {CurrentTier} of a maximum {MaxTier}, next wave {NextSize} hostiles at up to {NextConcurrent} alive at once, aiming at {WaveSecondsExact}s")

    # How much slower this tier's hostiles die than the base cards, as a
    # multiplier of one. The head count is divided by it, so a wave of tougher
    # hostiles is a smaller wave and still lands near WaveSecondsExact.
    #
    # WITHOUT THIS THE CEILING MEANS NOTHING. A Tier 21 hostile takes about five
    # times the bullets of a Tier 1 one, so a wave built to run 2m30 would really
    # run eight or ten minutes. Claude's call 2026-08-22, delegated by Kai.
    #
    # Read off the Swarmer ladder, because Swarmers are most of every crowd. A
    # type with a different number of cards steps at its own pace, which this
    # ignores on purpose: one representative figure is enough for a length that
    # is already an estimate.
    ToughnessFactor()<transacts>:float =
        var Result : float = 1.0
        Count := SwarmerDefinitions.Length
        if (Count > 0):
            Index := TierDefinitionIndex(Count)
            for (Step := 1..Index):
                set Result = Result * ToughnessPerCardStep
        Result

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
    TierDefinitionIndex(Count : int)<transacts>:int =
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
        for (SlotIndex -> Spawner : AllSpawners()):
            Definitions := DefinitionsFor(SlotIndex)
            Count := Definitions.Length
            if (Count > 0):
                Index := TierDefinitionIndex(Count)
                if (Definition := Definitions[Index]):
                    if (Spawner.SetNPCCharacterDefinition[Definition]):
                        Log("DEBUG: Tier {CurrentTier} -- spawner {SlotIndex} set to card {Index} of {Count}")
                    else:
                        Log("WARNING: SetNPCCharacterDefinition was refused for spawner {SlotIndex}, card {Index}, at Tier {CurrentTier}. It fails when the character type differs, so check every card in that one list is the same type. Those hostiles stay as they were.")
                else:
                    Log("WARNING: Spawner {SlotIndex} has no card {Index} at Tier {CurrentTier}; it has {Count}. Those hostiles stay as they were.")

    # The four spawners in a fixed order: 0 Swarmer, 1 Boar, 2 Sentinel, 3 Tank.
    # Everything else in this file indexes off this order.
    AllSpawners()<transacts>:[]npc_spawner_device =
        array{SwarmerSpawner, BoarSpawner, SentinelSpawner, TankSpawner}

    AllShares()<transacts>:[]float =
        array{SwarmerShare, BoarShare, SentinelShare, TankShare}

    DefinitionsFor(SlotIndex : int)<transacts>:[]npc_character_definition =
        var Result : []npc_character_definition = SwarmerDefinitions
        if (SlotIndex = 1):
            set Result = BoarDefinitions
        else if (SlotIndex = 2):
            set Result = SentinelDefinitions
        else if (SlotIndex = 3):
            set Result = TankDefinitions
        Result

    # How many of one spawner's hostiles are alive, counted as a float because
    # it is only ever compared against a share of the concurrent target.
    LiveFor(Spawner : npc_spawner_device)<transacts>:float =
        var Count : float = 0.0
        for:
            Hostile : Spawner.GetAgents()
            FortCharacter := Hostile.GetFortCharacter[]
            FortCharacter.IsActive[]
        do:
            set Count = Count + 1.0
        Count

    # The room each type joins in, indexed by the AllSpawners order. Swarmers
    # are slot 0 and always in, so they answer 1.
    JoinTierFor(SlotIndex : int)<transacts>:int =
        var Result : int = 1
        if (SlotIndex = 1):
            set Result = BoarJoinsAtTier
        else if (SlotIndex = 2):
            set Result = SentinelJoinsAtTier
        else if (SlotIndex = 3):
            set Result = TankJoinsAtTier
        Result

    # How much of a full room the ramp allows right now, as a fraction of one.
    # The shares of the types that have joined, over the shares of all four. At
    # the default five-two-two-one that is 0.5 in room 1, 0.7 in room 2, 0.9 in
    # room 3 and 1.0 from room 4 on. It scales the density and the number to
    # clear together, so a thinner room is also a shorter one.
    #
    # Falls back to a full room if every share is zero, so a mistyped share list
    # can never silently empty the arena. SpawnNext already warns about that.
    RampFraction()<transacts>:float =
        var Total : float = 0.0
        var Unlocked : float = 0.0
        for (SlotIndex -> Share : AllShares()):
            set Total = Total + Share
            if (CurrentTier >= JoinTierFor(SlotIndex)):
                set Unlocked = Unlocked + Share
        var Result : float = 1.0
        if (Total > 0.0):
            if (Unlocked > 0.0):
                set Result = Unlocked / Total
        Result

    # Which types the ramp has let in, for the log. Reading "types in play
    # Swarmer" in room 1 is how a playtest confirms the ramp is actually on.
    UnlockedTypeNames()<transacts>:string =
        Names := array{"Swarmer", "Boar", "Sentinel", "Tank"}
        var Result : string = ""
        for (SlotIndex -> Name : Names):
            if (CurrentTier >= JoinTierFor(SlotIndex)):
                if (Result.Length > 0):
                    set Result = "{Result}, {Name}"
                else:
                    set Result = Name
        Result

    # How many of this type a whole wave may contain, or false if it is not
    # rationed. Only Sentinels (slot 2) and Tanks (slot 3) are ever rationed, and
    # only until RareTypesEndAtTier.
    QuotaFor(SlotIndex : int)<transacts>:?int =
        var Result : ?int = false
        if (CurrentTier < RareTypesEndAtTier):
            if (SlotIndex = 2):
                if (CurrentTier <= SentinelJoinsAtTier):
                    set Result = option{SentinelsOnArrival}
                else:
                    set Result = option{SentinelsWhileRare}
            else if (SlotIndex = 3):
                if (CurrentTier <= TankJoinsAtTier):
                    set Result = option{TanksOnArrival}
                else:
                    set Result = option{TanksWhileRare}
        Result

    # Whether a type may take any more of the arena right now. Three ways to be
    # out: no share, not let in by the ramp yet, or this wave's quota used up.
    CanSpawnType(SlotIndex : int)<transacts>:logic =
        Shares := AllShares()
        var Result : logic = false
        if:
            Share := Shares[SlotIndex]
            Share > 0.0
            CurrentTier >= JoinTierFor(SlotIndex)
        then:
            set Result = true
            if:
                Quota := QuotaFor(SlotIndex)?
                Used := SpawnedByType[SlotIndex]
                Used >= Quota
            then:
                set Result = false
        Result

    # Spawns one hostile from whichever type is furthest below its share of the
    # arena. That keeps the mix at roughly five-two-two-one however the crowd is
    # thinned, rather than letting the player clear all the Swarmers and leave a
    # room of Tanks.
    #
    # THREE THINGS TAKE A TYPE OUT OF THE RUNNING: a share of zero, a type the
    # ramp has not let in yet, and a type that has used up this wave's quota.
    # Whichever types are left divide the whole crowd between them, so a rationed
    # Tank leaves Swarmers and Boars in its place rather than a hole.
    #
    # The early rooms are still thinner, but that now comes from RampFraction
    # cutting the crowd itself rather than from slots being left empty here.
    SpawnNext():void =
        Spawners := AllSpawners()
        Shares := AllShares()

        var TotalShare : float = 0.0
        for (SlotIndex -> Share : Shares):
            if (CanSpawnType(SlotIndex)?):
                set TotalShare = TotalShare + Share
        if (TotalShare <= 0.0):
            Log("WARNING: No hostile type can spawn. If every share is zero, set one of SwarmerShare, BoarShare, SentinelShare or TankShare above zero.")
            return

        var BestIndex : int = -1
        var BestDeficit : float = 0.0
        for (SlotIndex -> Spawner : Spawners):
            if:
                Share := Shares[SlotIndex]
                CanSpawnType(SlotIndex)?
            then:
                Deficit := ConcurrentNowExact * Share / TotalShare - LiveFor(Spawner)
                if (Deficit > BestDeficit):
                    set BestDeficit = Deficit
                    set BestIndex = SlotIndex

        if (Chosen := Spawners[BestIndex]):
            Chosen.Spawn()
            set SpawnsInFlight += 1

            # Rebuilt rather than assigned into by index, which is the form this
            # file already uses for arrays elsewhere.
            var Counted : []int = array{}
            for (SlotIndex -> Used : SpawnedByType):
                if (SlotIndex = BestIndex):
                    set Counted += array{Used + 1}
                else:
                    set Counted += array{Used}
            set SpawnedByType = Counted

    OnHostileSpawned(SpawnedAgent : agent):void =
        # Let this one through the doorways. See ArenaBarriers.
        for (Barrier : ArenaBarriers):
            Barrier.AddToIgnoreList(SpawnedAgent)

        set SpawnedThisWave += 1
        set SecondsSinceArrival = 0.0
        if (SpawnsInFlight > 0):
            set SpawnsInFlight -= 1
        LiveCount := CountLiveHostiles()
        Log("DEBUG: Hostile spawned -- {SpawnedThisWave} of {TargetThisWave} this wave, {LiveCount} alive now, {SpawnsInFlight} still on the way")

    OnHostileEliminated(Result : device_ai_interaction_result):void =
        # Taken off the ignore lists again, so a long run does not leave them
        # holding an entry for every hostile it ever spawned.
        if (DeadHostile := Result.Target?):
            for (Barrier : ArenaBarriers):
                Barrier.RemoveFromIgnoreList(DeadHostile)

        set EliminatedThisWave += 1
        set RunEliminations += 1
        Remaining := TargetThisWave - EliminatedThisWave
        LiveCount := CountLiveHostiles()
        Log("DEBUG: Hostile eliminated -- {Remaining} left in this wave, {LiveCount} alive now")
