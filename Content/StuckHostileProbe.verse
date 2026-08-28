# StuckHostileProbe.verse
#
# A DIAGNOSTIC THAT NOW ALSO RESCUES, since 2026-08-28. It still watches every
# robot and writes down where one has stopped. It also pulls a robot that is
# stuck OUTSIDE the walls back into the room, and nothing else. See THE RESCUE
# below for what it will and will not touch.
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
# KAI DECLINED A RESCUE ONCE AND THEN RULED FOR ONE. On 2026-08-26 a safety net
# that cleared out a wave which had stopped making progress was offered and
# turned down. That is still refused: this file does NOT despawn anything and
# does not end a wave. On 2026-08-28 Kai ruled for a narrower fix instead,
# amendment 100, which is the new ruling the paragraph above always said this
# would need. It moves a robot stuck outside the room back inside and does
# nothing else.
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
    # THE RESCUE, added 2026-08-28. Kai's ruling, and it is the new ruling the
    # header always said this file would need before it grew a fix.
    #
    # ONLY ROBOTS STUCK OUTSIDE THE ROOM ARE MOVED, and Kai chose that over
    # moving any robot that has stopped. A robot outside the walls is always
    # wrong, so the rescue cannot misfire. A Ranged Sentinel standing inside
    # shooting at the contestant has not moved either, and yanking it across the
    # arena would read as the game cheating.
    #
    # BEING OUTSIDE IS NOT ENOUGH ON ITS OWN. The Swarmer spawner sits outside
    # the west wall at about X -1500, so every Swarmer is legitimately outside
    # for the first seconds of its life while it walks in. It has to be outside
    # AND going nowhere.
    # =================================================================

    @editable
    RescueStuckOutside : logic = true

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
    @editable
    ArenaHalfLength : float = 1220.0

    @editable
    ArenaHalfWidth : float = 720.0

    # How far inside the wall a rescued robot is put, in centimetres. Enough
    # that it lands in the room rather than in the wall it was stuck behind.
    @editable
    RescueWallInset : float = 150.0

    # How close a rescued robot may be dropped to the contestant, in
    # centimetres.
    #
    # FIVE METRES, RAISED FROM THREE ON 2026-08-28 after the first playtest of
    # this. Three metres is GDD 5.5's spawn safety radius, and it turned out to
    # be the wrong figure to borrow: a spawn is something the player expects, and
    # a robot appearing out of nothing is not. Kai was fighting at the west end,
    # a Swarmer was rescued to the west wall three metres away, and it read as
    # the game teleporting enemies onto them.
    #
    # FIVE FITS THE REAL ROOM. The arena was measured on 2026-08-28 and is 24
    # metres by 14, so the east and west walls are 14 metres end to end and a
    # robot sliding along one has 11 to work with once the inset is off. The
    # figure was chosen against a room believed to be 21 by 11 and comfortably
    # survives the correction.
    @editable
    RescueSafeGap : float = 500.0

    # The height a rescued robot is put back at, in world Z. The floor, and
    # NEVER the height it was stranded at: a robot thrown over a wall can end up
    # on top of something out there, and reusing that height would drop it into
    # the room from the air. Kai's constraint, 2026-08-28. Robots stand at about
    # 85 in this arena, the same figure TwinStickController's containment uses.
    @editable
    RescueFloorHeight : float = 85.0

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
                CountStill(Hostile, Body, Now, Kind)

    # It moved, so everything counted up about it is cleared, its report
    # included. If it sticks somewhere else later, that is worth hearing about.
    Forget(Hostile : agent):void =
        if (set StillFor[Hostile] = 0, set Reported[Hostile] = false):
            return

    CountStill(Hostile : agent, Body : fort_character, Now : vector3, Kind : string):void =
        var Looks : int = 1
        if (Already := StillFor[Hostile]):
            set Looks = Already + 1

        if (set StillFor[Hostile] = Looks):
            if (Looks >= StillLooksBeforeReport):
                Report(Hostile, Now, Kind, Looks)
                RescueIfOutside(Hostile, Body, Now, Kind, Looks)

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

    # =================================================================
    # THE RESCUE
    #
    # Pulls a robot that is stuck OUTSIDE the walls back into the room, straight
    # in through the nearest wall. See the dials above for why it is only ever
    # the ones outside.
    #
    # THE PROBLEM IT SOLVES IS A HUNG RUN, not an untidy arena. A wave ends when
    # everything in it is dead, and a robot that cannot find its way into the
    # room can never be killed, so the room never finishes and the run stops
    # dead. Kai has had this happen from the Swarmer spawner, which sits outside
    # the west wall and cannot be moved without spoiling how the arena looks.
    #
    # IT TRIES AGAIN EVERY LOOK WHILE THE ROBOT IS STILL OUT THERE. A successful
    # teleport counts as movement, so the counter clears itself on the next look
    # and this stops of its own accord. Only the first failure is logged, or a
    # robot that genuinely cannot be moved would write a line every second for
    # the rest of the match.
    # =================================================================

    RescueIfOutside(Hostile : agent, Body : fort_character, Now : vector3, Kind : string, Looks : int):void =
        if (RescueStuckOutside?, OutsideTheRoom(Now)?):
            # Straight in through the nearest wall: clamping each coordinate on
            # its own is exactly that, because the wall a robot is nearest to is
            # the one whose limit it has broken.
            var TargetX : float = HeldInside(Now.X, ArenaHalfLength - RescueWallInset)
            var TargetY : float = HeldInside(Now.Y, ArenaHalfWidth - RescueWallInset)

            # NEVER ON TOP OF THE CONTESTANT, BUT IT STAYS ON ITS WALL.
            #
            # Kai's ruling 2026-08-28, after watching the first version put a
            # Swarmer at their elbow: "if the robot was stuck at the west wall it
            # just appears right in front of the wall so it still looks like its
            # running in, and not in the middle of the arena". So a robot that
            # would land too close is slid ALONG the wall it came through rather
            # than pushed out into the room. It still enters where it was stuck,
            # which is the whole point, just further down the wall.
            #
            # WHICH WAY IS ALONG. A robot that broke the length limit came
            # through the east or west wall, so along it is the Y axis; anything
            # else came through the north or south wall and slides on X.
            # WHICH WALL IT CAME THROUGH, worked out once and used twice below.
            # Written as two ifs rather than an `or`, because a comparison is not
            # a true or false in Verse and this has to end up as one.
            var CameThroughEndWall : logic = false
            if (Now.X > ArenaHalfLength):
                set CameThroughEndWall = true
            if (Now.X < -ArenaHalfLength):
                set CameThroughEndWall = true

            for (Contestant : GetPlayspace().GetPlayers(), Standing := Contestant.GetFortCharacter[], Standing.IsActive[]):
                Mine := Standing.GetTransform().Translation
                OffX := TargetX - Mine.X
                OffY := TargetY - Mine.Y
                if (OffX * OffX + OffY * OffY < RescueSafeGap * RescueSafeGap):
                    if (CameThroughEndWall?):
                        set TargetY = SlidAlong(Mine.Y, OffY, ArenaHalfWidth - RescueWallInset)
                    else:
                        set TargetX = SlidAlong(Mine.X, OffX, ArenaHalfLength - RescueWallInset)

            # THE FIRST SPOT CAN BE REFUSED, and on 2026-08-28 five robots were
            # left stranded because it was. A teleport fails when something is
            # already standing where the robot would land, and the inside of a
            # wall in a busy room is exactly where a crowd gathers.
            #
            # So it walks along the wall until one spot takes. Kai's constraint
            # governs every one of them: "as long as it doesnt look like they
            # spawn in the middle of the arena or dropping from the sky". Every
            # candidate stays on the same wall and every one is at floor height.
            var Landed : logic = false
            for (Shift : RescueOffsets(), not Landed?):
                var TryX : float = TargetX
                var TryY : float = TargetY
                if (CameThroughEndWall?):
                    set TryY = HeldInside(TargetY + Shift, ArenaHalfWidth - RescueWallInset)
                else:
                    set TryX = HeldInside(TargetX + Shift, ArenaHalfLength - RescueWallInset)

                Landing := vector3{X := TryX, Y := TryY, Z := RescueFloorHeight}
                if (Body.TeleportTo[Landing, IdentityRotation()]):
                    set Landed = true
                    Log("DEBUG: RESCUED a {Kind} stuck outside the room at X={Now.X} Y={Now.Y}. Put back inside at X={TryX} Y={TryY}.")
                    Forget(Hostile)

            if (not Landed?, Looks = StillLooksBeforeReport):
                Log("WARNING: a {Kind} is stuck outside the room at X={Now.X} Y={Now.Y} and every spot along its wall was refused. The wave cannot finish while it is out there.")

    # HOW FAR ALONG THE WALL EACH ATTEMPT MOVES, in centimetres, nearest first
    # and alternating sides so the robot ends up as close as possible to where
    # it was stuck. Held as a list because Verse will not multiply a whole
    # number by a decimal without a conversion the language does not offer.
    RescueOffsets()<transacts>:[]float =
        array{0.0, 300.0, -300.0, 600.0, -600.0, 900.0, -900.0}

    # One coordinate moved a safe gap away from the contestant along a single
    # axis, and held inside the room.
    #
    # IT PICKS THE ROOMIER SIDE. Away from the contestant is the natural choice,
    # but at the end of a wall there may be no room that way, and the hold would
    # simply put the robot back beside them. So the far side is tried first and
    # the near side only if the wall runs out.
    SlidAlong(Theirs : float, Offset : float, Limit : float)<transacts>:float =
        var Step : float = RescueSafeGap
        if (Offset < 0.0):
            set Step = -RescueSafeGap

        Preferred := Theirs + Step
        if (Preferred <= Limit, Preferred >= -Limit):
            return Preferred

        Other := Theirs - Step
        if (Other <= Limit, Other >= -Limit):
            return Other

        # Both ends are off the wall, which means the wall is shorter than two
        # safe gaps. Nothing on it is far enough away, so the far corner is the
        # best there is.
        HeldInside(Preferred, Limit)

    # Whether a point is outside the four walls. Written the outside way round
    # because that is the question the rescue asks, and asking it directly
    # avoids negating a query.
    OutsideTheRoom(Where : vector3)<transacts>:logic =
        if:
            Where.X <= ArenaHalfLength
            Where.X >= -ArenaHalfLength
            Where.Y <= ArenaHalfWidth
            Where.Y >= -ArenaHalfWidth
        then:
            false
        else:
            true

    # Holds one coordinate inside plus or minus Limit. The same helper
    # WaveManager and DeathSaveManager use, and for the same reason.
    HeldInside(Value : float, Limit : float)<transacts>:float =
        var Held : float = Value
        if (Held > Limit):
            set Held = Limit
        if (Held < -Limit):
            set Held = -Limit
        Held
