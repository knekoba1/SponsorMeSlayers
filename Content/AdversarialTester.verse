# AdversarialTester.verse
#
# ASSIGNMENT 9, the Adversarial QA Agent. Not a GDD feature and not part of the
# shipped game: RunAdversarialTest is OFF and must stay off for a normal
# playtest, because this device drives the contestant around and nobody can aim
# while it does.
#
# WHAT MAKES IT ADVERSARIAL RATHER THAN A PLAYER. It is not trying to have a
# good run. It spends the whole match doing the things a person would not: it
# walks the contestant into every wall, past every wall, under the floor, into
# the ceiling, onto the robot spawners, and it hops twenty times in two seconds
# to see what falls over. It attacks the edges of the rules on purpose.
#
# WHAT "BROKEN" MEANS HERE, and it is written down rather than felt. Ten
# invariants, each one a promise the GDD or a house rule already makes:
#
#   INV-01  no hostile may be outside the arena          GDD 1.1, one room
#   INV-02  no hostile may stand still indefinitely      a stuck state
#   INV-03  never more than 40 hostiles alive            GDD 5.5's hard cap
#   INV-04  Hype stays between 0 and 100                 GDD 3.1
#   INV-05  the contestant may not REMAIN outside        GDD 1.1
#   INV-06  health never exceeds its maximum             an exploit tell
#   INV-07  the Escalation Tier never passes 21          GDD 5.5's hard cap
#   INV-08  nothing spawns inside the safety radius      GDD 5.5's 3 metres
#   INV-09  the run score never goes backwards           an accounting break
#   INV-10  the tier never goes backwards mid-run        an accounting break
#
# An invariant is checked whether or not an attack is running, so a fault the
# ordinary game causes on its own is caught too. That is how the west-wall
# spawn break was found on 2026-08-27, by watching rather than by playing.
#
# HOW A FINDING LEAVES THE GAME. Verse cannot write a file. Each finding is one
# PIPE-DELIMITED line in the UEFN log behind the ADVQA marker, and
# pipelines/assignment-09-adversarial/harvest.py turns a run's worth of them
# into report.json and report.csv.
#
# PIPES RATHER THAN JSON, DELIBERATELY. Writing JSON here would mean a quote
# character inside a Verse string, and there is not one anywhere else in this
# project. The report has to be JSON; the log line does not.
#
# THE FIELD ORDER IS FIXED and harvest.py depends on it:
#   ADVQA|check|error_type|severity|location|system|context|seconds

using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Simulation }

adversarial_tester := class(creative_device):

    # =================================================================
    # WIRING
    # =================================================================

    # The four spawners, in the SAME ORDER Wave Manager uses: Swarmer, Boar,
    # Sentinel, Tank. Every other file in this project indexes off that order.
    @editable
    SwarmerSpawner : npc_spawner_device = npc_spawner_device{}

    @editable
    BoarSpawner : npc_spawner_device = npc_spawner_device{}

    @editable
    SentinelSpawner : npc_spawner_device = npc_spawner_device{}

    @editable
    TankSpawner : npc_spawner_device = npc_spawner_device{}

    @editable
    HypeMeter : hype_meter_manager = hype_meter_manager{}

    @editable
    Waves : wave_manager = wave_manager{}

    @editable
    CashDrops : cash_drop_manager = cash_drop_manager{}

    # =================================================================
    # THE SWITCH
    # =================================================================

    # OFF, AND IT MUST STAY OFF FOR A NORMAL PLAYTEST. This device teleports the
    # contestant every few seconds. Leave it on by accident and the next
    # playtest reads as the game being violently broken, which it is, by us.
    @editable
    RunAdversarialTest : logic = false

    # =================================================================
    # WHERE THE ARENA IS
    #
    # These MUST match SimulatedAudience's ArenaHalfLength and ArenaHalfWidth or
    # this device reports faults that are only disagreements about the walls.
    # 1050 by 550 from centre as of 2026-08-27.
    # =================================================================

    @editable
    ArenaHalfLength : float = 1050.0

    @editable
    ArenaHalfWidth : float = 550.0

    @editable
    FloorHeight : float = 85.0

    # How far past a wall still counts as inside, so a robot brushing the edge
    # is not reported. Only a real excursion is a finding.
    @editable
    BoundaryTolerance : float = 60.0

    # GDD 5.5's spawn safety radius, in centimetres. Three metres.
    @editable
    SafetyRadius : float = 300.0

    # GDD 5.5's concurrent cap.
    @editable
    MaxConcurrentHostiles : int = 40

    # GDD 5.5's hard tier cap.
    @editable
    MaxTier : int = 21

    # =================================================================
    # PACING
    # =================================================================

    # How often every invariant is checked.
    @editable
    WatchSeconds : float = 0.5

    # How long the contestant is left somewhere illegal before it is judged. A
    # game that shoves them back is behaving; one that leaves them there is not.
    @editable
    SettleSeconds : float = 1.5

    # How long between one attack and the next.
    @editable
    AttackGapSeconds : float = 2.0

    # How many looks a hostile may stand perfectly still for before it is called
    # stuck. At WatchSeconds of 0.5 this is six seconds.
    @editable
    StillLooksToReport : int = 12

    # How far a hostile must move between looks to count as moving.
    @editable
    MovedEnough : float = 40.0

    # How many hops A-09 makes, and how long it leaves between them.
    @editable
    HopCount : int = 20

    @editable
    HopSeconds : float = 0.1

    # =================================================================
    # STATE
    # =================================================================

    var SecondsElapsed : float = 0.0

    # An attack is running, so INV-05 knows the contestant is outside on purpose
    # and does not report our own doing as a fault.
    var Attacking : logic = false

    # Where each hostile stood at the last look, and how many looks it has
    # stayed there.
    var LastSpot : [agent]vector3 = map{}
    var StillLooks : [agent]int = map{}

    # Already reported, so one stuck robot is one finding rather than one every
    # half second.
    var Reported : [agent]logic = map{}

    # The highest values seen this run, for the two accounting invariants.
    var HighestScore : int = 0
    var HighestTier : int = 1

    # How many findings this run, for the closing line the harvester counts
    # against.
    var FindingCount : int = 0

    # Which side A-09's next hop lands on.
    var HopLeft : logic = false

    # =================================================================
    # GOING TO WORK
    # =================================================================

    OnBegin<override>()<suspends>:void =
        if (not RunAdversarialTest?):
            Log("ADVQA: adversarial tester is OFF. Tick RunAdversarialTest on the device to run it.")
            return

        Log("ADVQA: adversarial tester ARMED. The contestant will be driven; do not try to play.")
        Log("ADVQA|check|error_type|severity|location|system|context|seconds")

        spawn{ RunClock() }

        # Nothing before the show starts, the same gate every other manager
        # waits on. Amendment 70.
        AwaitMatchStart(Self)

        for (Spawner : AllSpawners()):
            Spawner.SpawnedEvent.Subscribe(OnHostileSpawned)

        Log("ADVQA: run has begun. Watching {InvariantCount} invariants and cycling {AttackCount} attacks.")

        spawn{ RunInvariantWatch() }
        spawn{ RunAttackCycle() }

    RunClock()<suspends>:void =
        loop:
            Sleep(0.1)
            set SecondsElapsed = SecondsElapsed + 0.1

    InvariantCount : int = 10
    AttackCount : int = 10

    AllSpawners()<transacts>:[]npc_spawner_device =
        array{SwarmerSpawner, BoarSpawner, SentinelSpawner, TankSpawner}

    SpawnerName(SlotIndex : int)<transacts>:string =
        var Result : string = "SwarmerSpawner"
        if (SlotIndex = 1):
            set Result = "BoarSpawner"
        else if (SlotIndex = 2):
            set Result = "SentinelSpawner"
        else if (SlotIndex = 3):
            set Result = "TankSpawner"
        Result

    LiveHostiles()<transacts>:[]agent =
        var Found : []agent = array{}
        for (Spawner : AllSpawners()):
            set Found = Found + Spawner.GetAgents()
        Found

    Contestant()<transacts>:?player =
        if (First := GetPlayspace().GetPlayers()[0]):
            return option{First}
        false

    # =================================================================
    # REPORTING
    #
    # One finding, one line, fields in the order the header above promises.
    # =================================================================

    Report(Check : string, ErrorType : string, Severity : string, Location : string, System : string, Context : string):void =
        set FindingCount = FindingCount + 1
        Log("ADVQA|{Check}|{ErrorType}|{Severity}|{Location}|{System}|{Context}|{SecondsElapsed}")

    # Everything the report needs to know about the moment a fault happened, in
    # one string. A finding with no context is a finding nobody can act on.
    GameContext()<transacts>:string =
        var Where : string = "contestant unknown"
        var Health : string = "health unknown"
        if (P := Contestant?, Character := P.GetFortCharacter[]):
            Standing := Character.GetTransform().Translation
            set Where = "contestant at X={Standing.X} Y={Standing.Y} Z={Standing.Z}"
            set Health = "health {Character.GetHealth()} of {Character.GetMaxHealth()}"

        Alive := LiveCount()
        "tier {Waves.GetCurrentTier()}; rooms won {Waves.GetRoomsWon()}; {Alive} hostiles alive; hype {HypeMeter.GetHype()}; score {CashDrops.GetRunScore()}; {Where}; {Health}"

    # NOT CALLED Spot. A local named Spot would shadow it and the file would be
    # arguing with itself over one word.
    Place(Position : vector3)<transacts>:string =
        "X={Position.X} Y={Position.Y} Z={Position.Z}"

    # HOW FAR APART, IN PLAIN ARITHMETIC. SpatialMath's own Distance is defined
    # in more than one module and a transform hands back a vector3 from a
    # different one than the maths expects, which has bitten this project
    # before. Pythagoras needs no import.
    Apart(A : vector3, B : vector3)<transacts>:float =
        DX := A.X - B.X
        DY := A.Y - B.Y
        DZ := A.Z - B.Z
        Sqrt(DX * DX + DY * DY + DZ * DZ)

    LiveCount()<transacts>:int =
        var Count : int = 0
        for:
            Hostile : LiveHostiles()
            Character := Hostile.GetFortCharacter[]
            Character.IsActive[]
        do:
            set Count = Count + 1
        Count

    # =================================================================
    # THE INVARIANTS
    #
    # Checked forever, whether or not an attack is running.
    # =================================================================

    RunInvariantWatch()<suspends>:void =
        loop:
            Sleep(WatchSeconds)
            CheckHostiles()
            CheckCounts()
            CheckContestant()

    # INV-01 and INV-02, both of which need every hostile's position, so they
    # share one walk of the list.
    CheckHostiles():void =
        var NextSpot : [agent]vector3 = map{}
        var NextLooks : [agent]int = map{}

        for (SlotIndex -> Spawner : AllSpawners()):
            for:
                Hostile : Spawner.GetAgents()
                Character := Hostile.GetFortCharacter[]
                Character.IsActive[]
            do:
                Here := Character.GetTransform().Translation

                # INV-01. Outside the one room the GDD gives this game.
                if (OutsideArena(Here)?, not Reported[Hostile]):
                    if (set Reported[Hostile] = true):
                        Report("INV-01", "BOUNDARY_BREAK", "high", Place(Here), "{SpawnerName(SlotIndex)} / WaveManager", "a hostile is outside the arena; {GameContext()}")

                # INV-02. Standing perfectly still is a stuck state.
                var Looks : int = 0
                if (Before := LastSpot[Hostile]):
                    if (Apart(Before, Here) < MovedEnough):
                        if (Was := StillLooks[Hostile]):
                            set Looks = Was + 1
                        else:
                            set Looks = 1

                if (Looks >= StillLooksToReport, not Reported[Hostile]):
                    if (set Reported[Hostile] = true):
                        Report("INV-02", "STUCK_STATE", "high", Place(Here), "{SpawnerName(SlotIndex)} / WaveManager", "a hostile has not moved for {StillLooksToReport} looks; {GameContext()}")

                set NextSpot = ConcatenateMaps(NextSpot, map{Hostile => Here})
                set NextLooks = ConcatenateMaps(NextLooks, map{Hostile => Looks})

        set LastSpot = NextSpot
        set StillLooks = NextLooks

    # INV-03, INV-04, INV-07, INV-09 and INV-10. All five are one number read
    # against a promise.
    CheckCounts():void =
        Alive := LiveCount()
        if (Alive > MaxConcurrentHostiles):
            Report("INV-03", "CAP_EXCEEDED", "high", "arena", "WaveManager", "{Alive} hostiles alive against a cap of {MaxConcurrentHostiles}; {GameContext()}")

        Hype := HypeMeter.GetHype()
        if (Hype < 0.0):
            Report("INV-04", "VALUE_OUT_OF_RANGE", "medium", "HUD hype meter", "HypeMeterManager", "hype is {Hype}, below zero; {GameContext()}")
        if (Hype > 100.0):
            Report("INV-04", "VALUE_OUT_OF_RANGE", "medium", "HUD hype meter", "HypeMeterManager", "hype is {Hype}, above one hundred; {GameContext()}")

        Tier := Waves.GetCurrentTier()
        if (Tier > MaxTier):
            Report("INV-07", "CAP_EXCEEDED", "high", "arena", "WaveManager", "escalation tier {Tier} is past the cap of {MaxTier}; {GameContext()}")

        Score := CashDrops.GetRunScore()
        if (Score < HighestScore):
            Report("INV-09", "COUNTER_WENT_BACKWARDS", "medium", "HUD cash counter", "cash_drop_manager", "score fell from {HighestScore} to {Score} inside one run; {GameContext()}")
        if (Score > HighestScore):
            set HighestScore = Score

        if (Tier < HighestTier):
            Report("INV-10", "COUNTER_WENT_BACKWARDS", "medium", "arena", "WaveManager", "tier fell from {HighestTier} to {Tier} inside one run; {GameContext()}")
        if (Tier > HighestTier):
            set HighestTier = Tier

    # INV-05 and INV-06.
    CheckContestant():void =
        if (P := Contestant?, Character := P.GetFortCharacter[], Character.IsActive[]):
            Here := Character.GetTransform().Translation

            # INV-05. Being outside DURING an attack is this device's own doing
            # and proves nothing. Being outside when nothing is pushing is the
            # game failing to hold its own room.
            if (not Attacking?, OutsideArena(Here)?):
                Report("INV-05", "BOUNDARY_BREAK", "high", Place(Here), "arena collision", "the contestant is outside the arena with nothing pushing them; {GameContext()}")

            # INV-06. More health than the maximum is the tell for a heal that
            # does not clamp.
            if (Character.GetHealth() > Character.GetMaxHealth()):
                Report("INV-06", "VALUE_OUT_OF_RANGE", "medium", Place(Here), "DeathSaveManager / CrateManager", "health above maximum; {GameContext()}")

    # INV-08. A hostile that appears within GDD 5.5's three metre safety radius.
    OnHostileSpawned(Spawned : agent):void =
        if:
            P := Contestant?
            Contender := P.GetFortCharacter[]
            Contender.IsActive[]
            Body := Spawned.GetFortCharacter[]
        then:
            Mine := Contender.GetTransform().Translation
            Theirs := Body.GetTransform().Translation
            Gap := Apart(Mine, Theirs)
            if (Gap < SafetyRadius):
                Report("INV-08", "SAFETY_RADIUS_BREACH", "high", Place(Theirs), "WaveManager spawn loop", "a hostile appeared {Gap}cm from the contestant, inside the {SafetyRadius}cm safety radius; {GameContext()}")

    OutsideArena(Position : vector3)<transacts>:logic =
        var Out : logic = false
        if (Position.X > ArenaHalfLength + BoundaryTolerance):
            set Out = true
        if (Position.X < -(ArenaHalfLength + BoundaryTolerance)):
            set Out = true
        if (Position.Y > ArenaHalfWidth + BoundaryTolerance):
            set Out = true
        if (Position.Y < -(ArenaHalfWidth + BoundaryTolerance)):
            set Out = true
        Out

    # =================================================================
    # THE ATTACKS
    #
    # Ten of them, cycled forever. Each one ends by putting the contestant back
    # in the middle, so one attack never poisons the next.
    # =================================================================

    RunAttackCycle()<suspends>:void =
        loop:
            PushPast("A-01", "west", -(ArenaHalfLength + 400.0), 0.0)
            PushPast("A-02", "east", ArenaHalfLength + 400.0, 0.0)
            PushPast("A-03", "north", 0.0, ArenaHalfWidth + 400.0)
            PushPast("A-04", "south", 0.0, -(ArenaHalfWidth + 400.0))

            CornerSlam()
            UnderFloor()
            Ceiling()
            SpawnerCamp()
            RapidHop()
            BackToCentre()

    # A-01 to A-04. Put the contestant well past a wall, leave them there, and
    # see whether the game takes them back.
    #
    # WHAT COUNTS AS BROKEN. Not the teleport itself, which is ours. It is the
    # contestant STILL being out there after SettleSeconds, because a single
    # room with no way out is what GDD 1.1 promises.
    PushPast(Code : string, Side : string, X : float, Y : float)<suspends>:void =
        if (P := Contestant?, Character := P.GetFortCharacter[], Character.IsActive[]):
            set Attacking = true
            Target := vector3{X := X, Y := Y, Z := FloorHeight}
            if (Character.TeleportTo[Target, IdentityRotation()]):
                Sleep(SettleSeconds)

                After := Character.GetTransform().Translation
                if (OutsideArena(After)?):
                    Report(Code, "BOUNDARY_BREAK", "high", Place(After), "arena collision", "pushed {Side} past the wall and was still outside {SettleSeconds}s later; {GameContext()}")
            set Attacking = false
            Sleep(AttackGapSeconds)

    # A-05. The four corners, exactly on the line, where two walls meet and
    # collision is most likely to have a gap.
    CornerSlam()<suspends>:void =
        Corners := array:
            vector3{X := ArenaHalfLength, Y := ArenaHalfWidth, Z := FloorHeight}
            vector3{X := ArenaHalfLength, Y := -ArenaHalfWidth, Z := FloorHeight}
            vector3{X := -ArenaHalfLength, Y := ArenaHalfWidth, Z := FloorHeight}
            vector3{X := -ArenaHalfLength, Y := -ArenaHalfWidth, Z := FloorHeight}

        for (Corner : Corners):
            if (P := Contestant?, Character := P.GetFortCharacter[], Character.IsActive[]):
                set Attacking = true
                if (Character.TeleportTo[Corner, IdentityRotation()]):
                    Sleep(SettleSeconds)
                    After := Character.GetTransform().Translation
                    if (OutsideArena(After)?):
                        Report("A-05", "BOUNDARY_BREAK", "high", Place(After), "arena collision", "dropped on a corner and slid outside; {GameContext()}")
                set Attacking = false
        Sleep(AttackGapSeconds)

    # A-06. Below the floor. A contestant who stays under it has found the way
    # out of the room that GDD 1.1 says does not exist.
    UnderFloor()<suspends>:void =
        if (P := Contestant?, Character := P.GetFortCharacter[], Character.IsActive[]):
            set Attacking = true
            Target := vector3{X := 0.0, Y := 0.0, Z := FloorHeight - 500.0}
            if (Character.TeleportTo[Target, IdentityRotation()]):
                Sleep(SettleSeconds)
                After := Character.GetTransform().Translation
                if (After.Z < FloorHeight - 100.0):
                    Report("A-06", "OUT_OF_WORLD", "high", Place(After), "arena floor collision", "left under the floor and stayed there; {GameContext()}")
            set Attacking = false
            Sleep(AttackGapSeconds)

    # A-07. High above the arena. What is being watched for is the landing:
    # a fall that does no damage is a fall that can be used to cross the room.
    Ceiling()<suspends>:void =
        if (P := Contestant?, Character := P.GetFortCharacter[], Character.IsActive[]):
            set Attacking = true
            Before := Character.GetHealth()
            Target := vector3{X := 0.0, Y := 0.0, Z := FloorHeight + 3000.0}
            if (Character.TeleportTo[Target, IdentityRotation()]):
                Sleep(SettleSeconds)
                Sleep(SettleSeconds)
                After := Character.GetHealth()
                Landed := Character.GetTransform().Translation
                if (Landed.Z < FloorHeight + 200.0, After >= Before):
                    Report("A-07", "NO_FALL_DAMAGE", "low", Place(Landed), "Island Settings fall damage", "dropped thirty metres and took nothing; {GameContext()}")
            set Attacking = false
            Sleep(AttackGapSeconds)

    # A-08. Stand on each spawner in turn. GDD 5.5 blocks a spawn within three
    # metres of the contestant, and INV-08 is listening while this happens, so
    # standing exactly where robots appear is the hardest test of that promise.
    SpawnerCamp()<suspends>:void =
        for (SlotIndex -> Spawner : AllSpawners()):
            if (P := Contestant?, Character := P.GetFortCharacter[], Character.IsActive[]):
                set Attacking = true
                OnTop := Spawner.GetTransform().Translation
                Standing := vector3{X := OnTop.X, Y := OnTop.Y, Z := FloorHeight}
                if (Character.TeleportTo[Standing, IdentityRotation()]):
                    # Long enough for the spawn loop to come round at least once
                    # at its slowest setting.
                    Sleep(SettleSeconds)
                    Sleep(SettleSeconds)

                    # A spawner sitting outside the arena is a finding on its
                    # own, and it is the fault that cost a playtest on
                    # 2026-08-27.
                    if (OutsideArena(OnTop)?):
                        Report("A-08", "DEVICE_OUT_OF_BOUNDS", "high", Place(OnTop), SpawnerName(SlotIndex), "a hostile spawner is placed outside the arena, so what it makes cannot reach the fight; {GameContext()}")
                set Attacking = false
        BackToCentre()
        Sleep(AttackGapSeconds)

    # A-09. Twenty teleports in two seconds. Anything that counts, times or
    # tracks the contestant gets asked to keep up.
    RapidHop()<suspends>:void =
        set Attacking = true
        var Index : int = 0
        loop:
            set Index = Index + 1
            if (Index > HopCount):
                break

            if (P := Contestant?, Character := P.GetFortCharacter[], Character.IsActive[]):
                # SIDE TO SIDE WITHOUT DIVIDING. `/` on two whole numbers in
                # Verse gives a rational, not a whole number, so a parity test
                # written that way does not compile. A flag costs nothing.
                Side := ArenaHalfLength * 0.8
                var X : float = Side
                if (HopLeft?):
                    set X = -Side
                set HopLeft = not HopLeft
                Target := vector3{X := X, Y := 0.0, Z := FloorHeight}
                if (Character.TeleportTo[Target, IdentityRotation()]):
                    Sleep(HopSeconds)
                else:
                    Sleep(HopSeconds)
            else:
                Sleep(HopSeconds)

        set Attacking = false
        BackToCentre()
        Sleep(AttackGapSeconds)

    # A-10, and the tail of several others. Somewhere legal, so the next attack
    # starts from a known place.
    BackToCentre():void =
        if (P := Contestant?, Character := P.GetFortCharacter[], Character.IsActive[]):
            Middle := vector3{X := 0.0, Y := 0.0, Z := FloorHeight}
            if (Character.TeleportTo[Middle, IdentityRotation()]):
                Log("ADVQA: back to the middle.")
