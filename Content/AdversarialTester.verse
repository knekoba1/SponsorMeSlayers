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
# IT ALSO TRAVELS AND IT ALSO TOUCHES THINGS, added 2026-08-28 after Kai watched
# a run and said the agent did not play the game, it teleported to different
# places. That was fair. A-11 walks it round the perimeter in short steps rather
# than blinking, and A-12 sweeps the whole floor lane by lane, which is how it
# INTERACTS: cash and crates in this game are collected by walking into them, so
# covering the floor touches everything on it. Neither is decoration. The
# perimeter walk brushes every wall continuously, and the sweep is what gives
# INV-11 something to catch.
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
#   INV-11  cash is never claimed from out of bounds    an exploit
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
    # Wrong here and this device reports faults that are only disagreements
    # about where the walls are.
    # =================================================================

    # THE REAL WALLS, MEASURED 2026-08-28. 1220 by 720 from centre.
    #
    # It was 1050 by 550, which is SimulatedAudience's crate-drop rectangle and
    # was never the room. Every file that needed the walls copied that figure,
    # and the guard in TwinStickController then hauled Kai back every time they
    # ran at a wall they were entitled to touch. Measured properly by running
    # into all four walls and reading the positions out of the log: the east
    # wall sits past X 1184, the west past X -1223, and both the north and south
    # past Y 700.
    #
    # THE DROP RECTANGLE IS DELIBERATELY SMALLER and stays 1050 by 550, so a
    # crate never lands flush against a wall. Do not "fix" these two to match it
    # again.
    # 2560 BY 1280, corrected 2026-09-05. See WaveManager.verse for how the old
    # 1220 by 720 came to be wrong and what proves this one.
    @editable
    ArenaHalfLength : float = 1750.0

    @editable
    # 1250, PROVEN BY THE SPAWNERS THEMSELVES, 2026-09-05. The probe printed
    # where all four sit and they are at the four walls: Swarmer X -1672,
    # Boar X 1744, Sentinel Y 1241, Tank Y -1220. That matches the robot pile-ups
    # exactly and settles an argument that ran all afternoon. The 2600 of an hour
    # earlier came from reading a gate actor as Y -2560, which nothing else in
    # the game agrees with.
    ArenaHalfWidth : float = 1250.0

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

    # HOW LONG A ROBOT IS ALLOWED TO BE OUTSIDE BEFORE INV-01 CALLS IT A FAULT,
    # in looks. At WatchSeconds of half a second, twenty looks is ten seconds.
    #
    # It exists because the Swarmer spawner sits OUTSIDE the west wall at about
    # X -1500, which is a placement Kai will not change because moving it spoils
    # how the arena looks. Every Swarmer is therefore legitimately outside while
    # it walks in, and the first real run of this device reported little else.
    # Ten seconds is far longer than the walk and far shorter than a robot that
    # is never getting in.
    GraceLooks : int = 20

    # How long INV-08 waits after a spawn before measuring, in seconds. Long
    # enough for WaveManager's safety-radius move to have run, short enough that
    # the hostile has not walked anywhere of its own accord.
    #
    # NOT CALLED SettleSeconds. This file already had one of those, for how long
    # the contestant is left somewhere illegal before it is judged, and a second
    # made every use of either ambiguous: script errors 3588 and 3532,
    # 2026-08-29.
    SpawnSettleSeconds : float = 0.25

    # How far a hostile must move between looks to count as moving.
    @editable
    MovedEnough : float = 40.0

    # How many hops A-09 makes, and how long it leaves between them.
    @editable
    HopCount : int = 20

    @editable
    HopSeconds : float = 0.1

    # -- travelling and touching, A-11 and A-12 ------------------------

    # How far the contestant moves per step when WALKING rather than blinking.
    # Short enough to read as travel and to brush a wall on the way past.
    @editable
    PatrolStepCm : float = 120.0

    # How long each step is held. At 0.08 the agent covers about fifteen metres
    # a second, which reads as a sprint rather than a teleport.
    @editable
    StepSeconds : float = 0.08

    # How far apart the sweep's lanes are. It must be smaller than a cash prop's
    # pickup radius or the sweep walks past things it should have collected.
    @editable
    SweepLaneCm : float = 200.0

    # How far inside the walls the patrol and the sweep stay.
    @editable
    Inset : float = 100.0

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

    # How many looks this device has watched each robot for. INV-01 uses it to
    # tell a robot walking in from the spawner apart from one that has genuinely
    # failed to get into the room.
    var SeenLooks : [agent]int = map{}

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

    # The score at the last look, so INV-11 can tell a rise from a reading.
    var LastScoreSeen : int = 0

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

    InvariantCount : int = 11
    AttackCount : int = 12

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

    # WITH ITS BRACKETS AT EVERY CALL SITE. Written `Contestant?` the compiler
    # is handed the function itself rather than the option it returns, and says
    # so eleven times over as script error 3509.
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
        if (P := Contestant()?, Character := P.GetFortCharacter[]):
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
        var NextSeen : [agent]int = map{}

        for (SlotIndex -> Spawner : AllSpawners()):
            for:
                Hostile : Spawner.GetAgents()
                Character := Hostile.GetFortCharacter[]
                Character.IsActive[]
            do:
                Here := Character.GetTransform().Translation

                # HOW LONG THIS DEVICE HAS BEEN WATCHING THIS ROBOT, counted
                # first because INV-01 needs it. Added 2026-08-28.
                var Seen : int = 1
                if (Before := SeenLooks[Hostile]):
                    set Seen = Before + 1

                # INV-01. Outside the one room the GDD gives this game.
                #
                # A ROBOT WALKING IN DOES NOT COUNT, and the first run of this
                # device reported nothing else. The Swarmer spawner sits OUTSIDE
                # the west wall at about X -1500 and cannot be moved without
                # spoiling the arena, so every Swarmer is legitimately out there
                # for the first seconds of its life. Reporting that buries the
                # one finding in the report that mattered.
                #
                # So a robot has to have been outside for GraceLooks looks
                # before it is called a fault. That is a genuine failure to get
                # into the room, which is what INV-01 is for.
                if (Seen > GraceLooks, OutsideArena(Here)?, not Reported[Hostile]):
                    if (set Reported[Hostile] = true):
                        Report("INV-01", "BOUNDARY_BREAK", "high", Place(Here), "{SpawnerName(SlotIndex)} / WaveManager", "a hostile has been outside the arena for more than {GraceLooks} looks; {GameContext()}")

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
                set NextSeen = ConcatenateMaps(NextSeen, map{Hostile => Seen})

        set LastSpot = NextSpot
        set StillLooks = NextLooks
        set SeenLooks = NextSeen

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

        # INV-11. Cash collected from somewhere the contestant cannot stand.
        # GDD 2.3 makes a pickup a COLLISION, so a score that rises while the
        # contestant is outside the room or below the floor is reach they should
        # not have. A-12's sweep is what gives this something to catch.
        if (Score > LastScoreSeen):
            if (P := Contestant()?, Character := P.GetFortCharacter[], Character.IsActive[]):
                Here := Character.GetTransform().Translation
                var Unreachable : logic = false
                if (OutsideArena(Here)?):
                    set Unreachable = true
                if (Here.Z < FloorHeight - 100.0):
                    set Unreachable = true
                if (Unreachable?):
                    Report("INV-11", "OUT_OF_BOUNDS_PICKUP", "high", Place(Here), "cash_drop_manager", "the score rose from {LastScoreSeen} to {Score} while the contestant was somewhere they cannot stand; {GameContext()}")
        set LastScoreSeen = Score

    # INV-05 and INV-06.
    CheckContestant():void =
        if (P := Contestant()?, Character := P.GetFortCharacter[], Character.IsActive[]):
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
    #
    # IT LOOKS A MOMENT LATER, NOT AT THE INSTANT OF THE SPAWN, and that is the
    # whole of this check being trustworthy. WaveManager subscribes to the same
    # event and MOVES a hostile that arrives too close; the digest gives no order
    # in which two subscribers run. The first real run of this device reported
    # six breaches at 64cm and 187cm, and the game's own log has it moving those
    # very hostiles out to 450cm in the same instant. The device was reading the
    # position before the fix had run.
    #
    # GDD 5.5 asks that a hostile not BE inside the radius, and a hostile moved
    # out within a frame never was, as far as the contestant is concerned.
    OnHostileSpawned(Spawned : agent):void =
        spawn{ CheckSafetyRadiusAfterSettling(Spawned) }

    CheckSafetyRadiusAfterSettling(Spawned : agent)<suspends>:void =
        Sleep(SpawnSettleSeconds)

        if:
            P := Contestant()?
            Contender := P.GetFortCharacter[]
            Contender.IsActive[]
            Body := Spawned.GetFortCharacter[]
            Body.IsActive[]
        then:
            Mine := Contender.GetTransform().Translation
            Theirs := Body.GetTransform().Translation
            Gap := Apart(Mine, Theirs)
            if (Gap < SafetyRadius):
                Report("INV-08", "SAFETY_RADIUS_BREACH", "high", Place(Theirs), "WaveManager spawn loop", "a hostile was still {Gap}cm from the contestant {SpawnSettleSeconds}s after spawning, inside the {SafetyRadius}cm safety radius; {GameContext()}")

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
            PatrolPerimeter()
            SweepFloor()
            BackToCentre()

    # A-01 to A-04. Put the contestant well past a wall, leave them there, and
    # see whether the game takes them back.
    #
    # WHAT COUNTS AS BROKEN. Not the teleport itself, which is ours. It is the
    # contestant STILL being out there after SettleSeconds, because a single
    # room with no way out is what GDD 1.1 promises.
    PushPast(Code : string, Side : string, X : float, Y : float)<suspends>:void =
        if (P := Contestant()?, Character := P.GetFortCharacter[], Character.IsActive[]):
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
            if (P := Contestant()?, Character := P.GetFortCharacter[], Character.IsActive[]):
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
        if (P := Contestant()?, Character := P.GetFortCharacter[], Character.IsActive[]):
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
        if (P := Contestant()?, Character := P.GetFortCharacter[], Character.IsActive[]):
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
            if (P := Contestant()?, Character := P.GetFortCharacter[], Character.IsActive[]):
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

            if (P := Contestant()?, Character := P.GetFortCharacter[], Character.IsActive[]):
                # SIDE TO SIDE WITHOUT DIVIDING. `/` on two whole numbers in
                # Verse gives a rational, not a whole number, so a parity test
                # written that way does not compile. A flag costs nothing.
                # AND `not` IS NOT A FLIP. In Verse `not` belongs to a failure
                # context; `set HopLeft = not HopLeft` is script error 3513,
                # "expected an expression that can fail". An if/else is the flip.
                Side := ArenaHalfLength * 0.8
                var X : float = Side
                if (HopLeft?):
                    set X = -Side
                    set HopLeft = false
                else:
                    set HopLeft = true
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

    # =================================================================
    # A-11 AND A-12: TRAVELLING, AND TOUCHING THINGS
    #
    # Everything above this line blinks the contestant somewhere illegal. These
    # two move them legally, at speed, over ground they are meant to be on.
    #
    # ATTACKING STAYS FALSE THROUGHOUT, on purpose. These two are not excused
    # from the invariants the way a wall push is. If the contestant ends up
    # outside the room while merely walking about inside it, that is exactly the
    # sort of fault INV-05 exists to catch.
    # =================================================================

    # One step. Separated out because both A-11 and A-12 are made of it, and
    # because the sleep has to happen whether or not the teleport took.
    StepTo(X : float, Y : float)<suspends>:void =
        if (P := Contestant()?, Character := P.GetFortCharacter[], Character.IsActive[]):
            Target := vector3{X := X, Y := Y, Z := FloorHeight}
            if (Character.TeleportTo[Target, IdentityRotation()]):
                Sleep(StepSeconds)
            else:
                Sleep(StepSeconds)
        else:
            Sleep(StepSeconds)

    # Walks from one point to another in steps of PatrolStepCm.
    #
    # THE DIVISIONS SIT IN THE IF because every division in Verse can fail,
    # floats included, and a line of no length would be one that did.
    WalkLine(X1 : float, Y1 : float, X2 : float, Y2 : float)<suspends>:void =
        DX := X2 - X1
        DY := Y2 - Y1
        Span := Sqrt(DX * DX + DY * DY)
        if (Span > 1.0, UnitX := DX / Span, UnitY := DY / Span):
            var Travelled : float = 0.0
            loop:
                if (Travelled >= Span):
                    break
                set Travelled = Travelled + PatrolStepCm
                var Along : float = Travelled
                if (Along > Span):
                    set Along = Span
                StepTo(X1 + UnitX * Along, Y1 + UnitY * Along)

    # A-11. A lap of the arena just inside the walls, walked rather than
    # blinked. Every step is a chance for the wall beside it to fail.
    PatrolPerimeter()<suspends>:void =
        Left := -(ArenaHalfLength - Inset)
        Right := ArenaHalfLength - Inset
        Bottom := -(ArenaHalfWidth - Inset)
        Top := ArenaHalfWidth - Inset

        Log("ADVQA: A-11 patrolling the perimeter.")
        WalkLine(Left, Bottom, Right, Bottom)
        WalkLine(Right, Bottom, Right, Top)
        WalkLine(Right, Top, Left, Top)
        WalkLine(Left, Top, Left, Bottom)
        Sleep(AttackGapSeconds)

    # A-12. Lane by lane across the whole floor, turning at each end.
    #
    # THIS IS THE INTERACTION, and it needs no list of what is lying about. GDD
    # 2.3 collects cash on contact and GDD 3.2 opens a crate on contact, so
    # covering the floor touches everything on it. What is being watched for is
    # not the collecting: it is whether the score can be made to rise from
    # somewhere the contestant should not be able to reach, which is INV-11.
    SweepFloor()<suspends>:void =
        Before := CashDrops.GetRunScore()
        Left := -(ArenaHalfLength - Inset)
        Right := ArenaHalfLength - Inset

        Log("ADVQA: A-12 sweeping the floor.")

        var Y : float = -(ArenaHalfWidth - Inset)
        var Rightward : logic = true
        loop:
            if (Y > ArenaHalfWidth - Inset):
                break
            if (Rightward?):
                WalkLine(Left, Y, Right, Y)
                set Rightward = false
            else:
                WalkLine(Right, Y, Left, Y)
                set Rightward = true
            set Y = Y + SweepLaneCm

        Gained := CashDrops.GetRunScore() - Before
        Log("ADVQA: A-12 done. The sweep collected {Gained} score off the floor.")
        Sleep(AttackGapSeconds)

    # A-13, and the tail of several others. Somewhere legal, so the next attack
    # starts from a known place.
    BackToCentre():void =
        if (P := Contestant()?, Character := P.GetFortCharacter[], Character.IsActive[]):
            Middle := vector3{X := 0.0, Y := 0.0, Z := FloorHeight}
            if (Character.TeleportTo[Middle, IdentityRotation()]):
                Log("ADVQA: back to the middle.")
