# StuckHostileProbe.verse
#
# A DIAGNOSTIC, NOT A FIX. It changes nothing about how the arena plays. It
# watches, and it writes down where.
#
# WHY IT EXISTS. A hostile got stuck somewhere it could not path out of and the
# wave never finished: the log for 2026-08-26 shows one robot alive with the
# contestant on 75 health and nothing happening for nineteen seconds. Kai could
# not see where it was to describe it, which is the whole difficulty. A stuck
# robot is usually caught on one particular piece of arena, and the way to find
# that piece is to have the game say the coordinates out loud.
#
# WHAT COUNTS AS STUCK. A robot that has barely moved for several seconds while a
# wave is still running. Not "standing still": a Ranged Sentinel is SUPPOSED to
# stand still and shoot, and so is anything that has cornered the contestant. So
# the test is movement over time and nothing else, and the threshold is generous
# on purpose. A false report costs a glance at a coordinate; a missed one costs
# another lost playtest.
#
# KAI DECLINED A RESCUE. On 2026-08-26 a safety net that cleared out a wave that
# had stopped making progress was offered and turned down. This file does NOT
# despawn anything, does not nudge anything, and does not end a wave. If it ever
# grows a fix, that is a new ruling and not a tidy-up of this one.
#
# HOW TO USE WHAT IT PRINTS. The numbers are world coordinates. In UEFN, an actor
# selected in the arena shows its own Location in the Details panel, so flying to
# roughly those X and Y values puts the stuck spot on screen. Compare a few
# reports: the same corner twice is a piece of geometry to fix, scattered
# positions are a pathing problem instead.

using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/Diagnostics }
# THE TEMPORARY SPATIAL MATHS, because that is the kind of vector a transform
# hands back. Verse.org's is a different type with different part names, and the
# only reason to reach for it is ApplyLinearImpulse, which this file never calls.
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Simulation }

stuck_hostile_probe := class(creative_device):

    # =================================================================
    # WIRING
    # =================================================================

    # The four spawners, in Wave Manager's order: Swarmer, Boar, Sentinel, Tank.
    # The order is what lets a report say which KIND of robot is stuck, which is
    # half the answer on its own.
    @editable
    SwarmerSpawner : npc_spawner_device = npc_spawner_device{}

    @editable
    BoarSpawner : npc_spawner_device = npc_spawner_device{}

    @editable
    SentinelSpawner : npc_spawner_device = npc_spawner_device{}

    @editable
    TankSpawner : npc_spawner_device = npc_spawner_device{}

    # =================================================================
    # DIALS
    # =================================================================

    # How often every robot is looked at. Often enough to catch a wave that has
    # stalled, rare enough that it is not doing arithmetic every frame.
    @editable
    CheckEverySeconds : float = 1.0

    # How far a robot must move between two looks to count as moving, in
    # centimetres. A robot shuffling on the spot against a wall still travels a
    # few centimetres, so this is not zero.
    @editable
    MovedAtLeast : float = 40.0

    # How many looks in a row a robot may fail to move before it is reported.
    # At one second apart, six is six seconds of genuinely going nowhere.
    @editable
    StillLooksBeforeReport : int = 6

    # A robot already reported is not reported again until it has moved and
    # stopped afresh, so one stuck robot does not fill the log with the same
    # line every second.
    @editable
    ReportEachRobotOnce : logic = true

    # =================================================================
    # STATE
    # =================================================================

    # Where each robot was at the last look.
    var LastSeenAt : [agent]vector3 = map{}

    # How many looks in a row each robot has failed to move.
    var StillFor : [agent]int = map{}

    # Which robots have already been reported at their current resting place.
    var Reported : [agent]logic = map{}

    OnBegin<override>()<suspends>:void =
        Log("DEBUG: Stuck hostile probe watching. A robot that has not moved {MovedAtLeast}cm across {StillLooksBeforeReport} looks will be reported with its coordinates.")
        spawn{ Watch() }

    Watch()<suspends>:void =
        loop:
            Sleep(CheckEverySeconds)
            LookAtEveryone()

    AllSpawners()<transacts>:[]npc_spawner_device =
        array{SwarmerSpawner, BoarSpawner, SentinelSpawner, TankSpawner}

    TypeNames()<transacts>:[]string =
        array{"Swarmer", "Boar", "Sentinel", "Tank"}

    LookAtEveryone():void =
        for (SlotIndex -> Spawner : AllSpawners()):
            Kind := KindFor(SlotIndex)

            for (Hostile : Spawner.GetAgents()):
                if (Body := Hostile.GetFortCharacter[], Body.IsActive[]):
                    LookAt(Hostile, Body, Kind)

    KindFor(SlotIndex : int)<transacts>:string =
        if (Name := TypeNames()[SlotIndex]):
            return Name
        "Hostile"

    LookAt(Hostile : agent, Body : fort_character, Kind : string):void =
        Now := Body.GetTransform().Translation

        # A first sighting has nothing to compare against, so it counts as
        # movement and the robot starts its count from clean.
        var Moved : logic = true

        if (Before := LastSeenAt[Hostile]):
            OffX := Now.X - Before.X
            OffY := Now.Y - Before.Y

            # Compared as squares, so no square root is needed and no division
            # can fail. Height is left out: a robot that has only risen or
            # fallen has not gone anywhere useful.
            if (OffX * OffX + OffY * OffY < MovedAtLeast * MovedAtLeast):
                set Moved = false

        # WRITING TO A MAP CAN FAIL IN VERSE, so it cannot stand on a line of
        # its own, and the work that follows hangs off it rather than sitting
        # after it.
        if (set LastSeenAt[Hostile] = Now):
            if (Moved?):
                Forget(Hostile)
            else:
                CountStill(Hostile, Now, Kind)

    # It moved, so everything counted up about it is cleared, its report
    # included. If it sticks somewhere else later, that is worth hearing about.
    Forget(Hostile : agent):void =
        if (set StillFor[Hostile] = 0, set Reported[Hostile] = false):
            return

    CountStill(Hostile : agent, Now : vector3, Kind : string):void =
        var Looks : int = 1
        if (Already := StillFor[Hostile]):
            set Looks = Already + 1

        if (set StillFor[Hostile] = Looks):
            if (Looks >= StillLooksBeforeReport):
                Report(Hostile, Now, Kind, Looks)

    Report(Hostile : agent, Now : vector3, Kind : string, Looks : int):void =
        # Already said once, and it has not moved since, so saying it every
        # second from here on would bury the rest of the log.
        if (ReportEachRobotOnce?, Seen := Reported[Hostile], Seen?):
            return

        # LOOKS RATHER THAN SECONDS, because a whole number will not multiply by
        # a decimal in Verse without a conversion the language does not offer.
        # The interval is printed beside it, so the two multiply in the reader's
        # head instead.
        if (set Reported[Hostile] = true):
            Log("STUCK HOSTILE -- a {Kind} has not moved across {Looks} looks, {CheckEverySeconds}s apart, at X={Now.X} Y={Now.Y} Z={Now.Z}. Fly to those coordinates in UEFN and look at what is there.")
