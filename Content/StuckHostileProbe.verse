# StuckHostileProbe.verse
#
# A DIAGNOSTIC THAT NOW ALSO RESCUES, since 2026-08-28. It still watches every
# robot and writes down where one has stopped. It also frees two kinds of stuck
# robot: one stranded OUTSIDE the walls, which it puts back in through the wall
# it came through, and one WEDGED INSIDE the room, which it nudges a few metres
# towards the middle. It never touches a Ranged Sentinel, which is supposed to
# stand still, and never one that is simply fighting the contestant. See THE
# RESCUE and WEDGED INSIDE below.
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
    # HALF A SECOND, so StillLooksBeforeReport's three looks land at a second
    # and a half rather than three. Kai's ruling 2026-09-05: a robot that has
    # not moved for a second and a half has stopped, and waiting three seconds
    # to say so wastes half the time a wave has.
    CheckEverySeconds : float = 0.5

    # How far a robot must move between two looks to count as moving, in
    # centimetres. A robot shuffling on the spot against a wall still travels a
    # few centimetres, so this is not zero.
    @editable
    MovedAtLeast : float = 40.0

    # How many looks in a row a robot may fail to move before it is reported.
    # At one second apart, six is six seconds of genuinely going nowhere.
    @editable
    # 6 -> 3, Kai 2026-08-29: "when they are stuck can it be unstuck faster."
    # At CheckEverySeconds of 1.0 that is three seconds of a robot not having
    # moved 40cm, and a robot that has genuinely not shifted 40cm in three
    # seconds is not thinking about it. Every rescue hangs off this number, the
    # wall fetch and the inside nudge both, so it is the one that decides how
    # long a wave sits waiting on a robot that is never coming.
    StillLooksBeforeReport : int = 3

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

    # =================================================================
    # THE PAUSE AFTER A ROBOT ARRIVES IS WANTED. KAI'S RULING, 2026-09-05.
    #
    # Kai: "i like that they stand still for a second because then the announcer
    # has time to say stuff." A robot that has just walked out of its spawner and
    # is standing there working out where to go is not stuck, it is part of the
    # show.
    #
    # WHAT THIS FIXES. Earlier the same day the stuck rule was shortened to 1.5
    # seconds, and it began catching robots inside that pause and teleporting
    # them onto the spot they were already standing on. That reset them, so they
    # never started walking, so they were caught again. The 18:17 log is nothing
    # but spawn, flagged, sent back, over and over.
    #
    # LOOKS RATHER THAN SECONDS, to match StillLooksBeforeReport above and so
    # that changing CheckEverySeconds cannot silently change what this means
    # relative to it. At half a second a look, 8 looks is four seconds.
    @editable
    SettleLooks : int = 8

    # How many looks each robot has been watched for. Nothing else uses it, and
    # it is never cleared, because a robot only exists for one life.
    var LooksAlive : [agent]int = map{}

    # Counts this robot's looks and answers whether it has been around long
    # enough to be judged. Everything upstream of this is skipped until it does.
    Settled(Hostile : agent):logic =
        var Seen : int = 1
        if (Already := LooksAlive[Hostile]):
            set Seen = Already + 1

        var Ready : logic = false
        if (set LooksAlive[Hostile] = Seen):
            if (Seen > SettleLooks):
                set Ready = true
        Ready

    OnBegin<override>()<suspends>:void =
        Log("DEBUG: Stuck hostile probe watching. A robot that has not moved {MovedAtLeast}cm across {StillLooksBeforeReport} looks will be reported with its coordinates.")

        # WHERE THE SPAWNERS ACTUALLY ARE, printed once at the top of every run.
        #
        # Added 2026-09-05 after an afternoon lost to arguing about which box in
        # the UEFN Details panel is X and which is Y. Kai read the same actors
        # twice and got Y -2560, Z 0, X 620; typing those numbers back put the
        # spawner somewhere neither of us expected. This line ends that: it
        # prints the spawner's position in the SAME coordinates every other
        # number in this log is written in, so a position read off the screen and
        # a position used by the code can finally be compared directly.
        #
        # Read it against the STUCK HOSTILE coordinates below it. Those are the
        # ground truth for where the room is.
        for (SlotIndex -> Spawner : AllSpawners()):
            Sits := Spawner.GetTransform().Translation
            Log("DEBUG: The {KindFor(SlotIndex)} spawner sits at X={Sits.X} Y={Sits.Y} Z={Sits.Z}. The floor is Z={RescueFloorHeight}.")
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
                    # SETTLED IS CALLED ON ITS OWN LINE, NOT IN THE IF ABOVE.
                    # It writes to LooksAlive, and Verse will not let a function
                    # that writes be called from inside a failable condition,
                    # because a failed condition has to roll back and a write
                    # cannot be rolled back. Script error 3512.
                    Ready := Settled(Hostile)
                    if (Ready?):
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

        # HOW LONG IT HAS BEEN OUT OF THE ROOM, counted whether or not it is
        # moving. See CountOutside for why standing still is not the only way to
        # be stuck outside.
        CountOutside(Hostile, Body, Now, Kind)

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
            # OUTSIDE FIRST AND ON ITS OWN CLOCK. See
            # OutsideStillLooksBeforeRescue: a robot standing outside the room is
            # always wrong and there is nothing to wait for. The call does
            # nothing at all for a robot that is inside, so this is safe to ask
            # every look.
            if (Looks >= OutsideStillLooksBeforeRescue):
                RescueIfOutside(Hostile, Body, Now, Kind, Looks)

            if (Looks >= StillLooksBeforeReport):
                Report(Hostile, Now, Kind, Looks)
                BringToSpawnSide(Hostile, Body, Now, Kind, Looks)

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
        if (RescueStuckOutside?, IsSwarmer(Kind)?, OutsideTheRoom(Now)?):
            # Straight in through the nearest wall: clamping each coordinate on
            # its own is exactly that, because the wall a robot is nearest to is
            # the one whose limit it has broken.
            var TargetX : float = HeldInside(Now.X, ArenaHalfLength - RescueWallInset)
            var TargetY : float = HeldInside(Now.Y, ArenaHalfWidth - RescueWallInset)

            # THE DOORS, IF THEY ARE BEING USED. See RescueThroughTheDoor. The
            # west wall is the negative end of the length axis, and the doors are
            # the middle of it.
            if (RescueThroughTheDoor?):
                set TargetX = -(ArenaHalfLength - RescueWallInset)
                set TargetY = RescueDoorY

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

            # Coming in through the doors is coming in through the west wall,
            # whatever wall the robot was stuck behind, so along is the Y axis
            # and every fallback below slides across the doorway rather than out
            # into the room.
            if (RescueThroughTheDoor?):
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

                # BELT AND BRACES ON THE LOOP FILTER. The log showed one
                # "Fetching it" producing two RESCUED lines, which is a robot
                # teleported twice in a frame, so the same test is made again
                # here rather than trusted to the filter alone.
                Landing := vector3{X := TryX, Y := TryY, Z := RescueFloorHeight}
                if (not Landed?, Body.TeleportTo[Landing, IdentityRotation()]):
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

    # =================================================================
    # PACING ABOUT OUTSIDE, added 2026-08-29.
    #
    # The rescue above only ever caught a robot that had STOPPED. The
    # adversarial tester found the gap: one Swarmer walked around outside the
    # south wall for more than ten seconds, never standing still long enough to
    # count as stuck, and nothing ever fetched it in. A wave ends only when
    # everything in it is dead, so a robot that can never be reached is a run
    # that can never finish.
    #
    # ALL FOUR SPAWNERS ARE OUTSIDE THE ROOM, which is why this keeps happening
    # rather than being a freak event. The tester measured them: the Swarmer's is
    # past the west wall, the Boar's past the east, the Sentinel's past the
    # north, the Tank's past the south. Kai has ruled twice now that they stay
    # where they are, because moving them spoils how the arena looks, so the
    # robots get moved instead.
    #
    # SO BEING OUTSIDE IS ITSELF THE TEST, once it has gone on long enough. The
    # grace is what separates a robot walking in, which is every robot in the
    # game for its first seconds, from one that is never getting in.
    # =================================================================

    # How long a robot may be outside before it is fetched in regardless of
    # whether it is moving, in looks. At one second apart, ten looks is ten
    # seconds: far longer than the walk in, far shorter than a stalled wave.
    @editable
    # 10 -> 6, and see StillLooksBeforeReport above for the ask. This is
    # amendment 112's rule, the one that catches a robot pacing about outside
    # without ever standing still, and the grace exists only to tell that robot
    # from one still walking in. The rescues log a trip of under three metres
    # from spawner to wall, which is a second or two of walking, so six seconds
    # is still far more room than a legitimate arrival needs.
    # 6 -> 2, Kai 2026-08-29: "its doing it too slowly it needs to be instantly."
    # Truly instant is not available, because every robot in this game starts
    # outside and walks in, so a zero grace would teleport each one the moment it
    # appeared. Two looks is two seconds, and the rescues log a walk of under
    # three metres from spawner to wall, so a robot genuinely on its way in still
    # gets there first. This is amendment 112's pacing rule; the standing-still
    # rule below is faster still.
    OutsideLooksBeforeRescue : int = 2

    # HOW LONG A ROBOT MAY STAND STILL OUTSIDE, as its own number rather than a
    # share of StillLooksBeforeReport. Outside is judged faster than inside on
    # purpose: a robot standing outside the room is always wrong, while one
    # standing inside may simply be fighting, which is why the inside nudge keeps
    # the longer count.
    @editable
    OutsideStillLooksBeforeRescue : int = 1

    # WHERE A RESCUED ROBOT IS PUT BACK. Kai's ruling 2026-08-29: "directly in
    # front of the wall doors and not the audience wall", and asked which wall,
    # "the west wall the doors is the middle".
    #
    # This replaces "in through the nearest wall". Every rescued robot now walks
    # in through the doors, wherever it got stuck, because the doors are the one
    # place a robot appearing reads as a robot arriving. Switch it off and the
    # nearest-wall behaviour of amendment 100 comes back.
    @editable
    RescueThroughTheDoor : logic = true

    # How far along the west wall the doors are. The middle of it, per Kai.
    @editable
    RescueDoorY : float = 0.0

    # How many looks in a row each robot has been outside the walls.
    var OutsideFor : [agent]int = map{}

    CountOutside(Hostile : agent, Body : fort_character, Now : vector3, Kind : string):void =
        if (OutsideTheRoom(Now)?):
            var Looks : int = 1
            if (Already := OutsideFor[Hostile]):
                set Looks = Already + 1

            if (set OutsideFor[Hostile] = Looks):
                if (Looks >= OutsideLooksBeforeRescue, IsSwarmer(Kind)?):
                    Log("DEBUG: a {Kind} has been outside the room for {Looks} looks without getting in. Fetching it.")
                    RescueIfOutside(Hostile, Body, Now, Kind, StillLooksBeforeReport)
        else:
            if (set OutsideFor[Hostile] = 0):
                return

    # =================================================================
    # WEDGED INSIDE THE ROOM, added 2026-08-28 after the adversarial tester
    # caught one: a Swarmer sat at X -1067 Y 694, well inside the walls, and had
    # not moved for twelve looks. Nothing would ever have freed it, and a wave
    # ends only when everything in it is dead.
    #
    # NEVER A SENTINEL. Kai's ruling, and it is the whole reason this was
    # refused the first time it was offered: a Ranged Sentinel is SUPPOSED to
    # stand still and shoot, and hauling one across the arena mid-fight reads as
    # the game cheating. The probe already knows which type each robot is, so
    # the exception costs one comparison.
    #
    # AND NEVER ONE THAT IS SIMPLY FIGHTING YOU. A robot standing on the
    # contestant has not wedged itself, it has cornered them, so anything inside
    # the safe gap is left exactly where it is.
    #
    # A NUDGE TOWARDS THE MIDDLE, NOT A JOURNEY. Kai's constraint holds here as
    # everywhere else: nothing appears in the middle of the arena and nothing
    # drops out of the sky. This moves a robot a few metres off whatever it is
    # caught on, at floor height, and lets it walk from there.
    # =================================================================

    # KAI'S RULING, 2026-09-05: A STUCK ROBOT GOES BACK TO ITS OWN SPAWNER.
    #
    # Kai: "they spawn from the right side of the arena and i want to keep it
    # this way." So a robot that has stopped is put back where its own kind
    # comes in, not somewhere more convenient. The side of the room the robots
    # arrive from is a staging choice, and a rescue must not quietly undo it.
    #
    # AN EARLIER VERSION PUT IT BESIDE THE CONTESTANT and was wrong for exactly
    # that reason. Recorded rather than deleted because it is the obvious idea
    # and someone will have it again.
    #
    # THE SPAWNER'S OWN POSITION, READ AT THE TIME. Nothing here holds a
    # coordinate of its own, so moving a spawner in UEFN moves the place stuck
    # robots are returned to, with no code change. Only the spawner's X and Y
    # are used: its height is ignored in favour of RescueFloorHeight, because a
    # spawner sitting below the floor would otherwise bury the robot it rescued.
    #
    # PULLED A LITTLE INTO THE ROOM, in growing steps. A spawner usually sits
    # against the wall it feeds robots through, so landing exactly on it can put
    # a robot back inside that wall. Each step moves the landing spot further
    # towards the middle until one takes.
    BringToSpawnSide(Hostile : agent, Body : fort_character, Now : vector3, Kind : string, Looks : int):void =
        if (RescueStuckOutside?, IsSwarmer(Kind)?):
            Spawner := SpawnerFor(Kind)
            Gate := Spawner.GetTransform().Translation

            # ALREADY HOME, SO LEAVE IT ALONE. Teleporting a robot onto the spot
            # it is already standing on achieves nothing and costs everything: it
            # resets whatever the robot was about to do, so a robot loitering at
            # its own spawner would be reset for ever. This is the other half of
            # the 2026-09-05 fault, and the reason the 18:17 log shows the same
            # robots sent back to the place they were already at.
            AwayX := Now.X - Gate.X
            AwayY := Now.Y - Gate.Y
            if (AwayX * AwayX + AwayY * AwayY < AlreadyHomeRadius * AlreadyHomeRadius):
                return

            Home := Sqrt(Gate.X * Gate.X + Gate.Y * Gate.Y)

            var Landed : logic = false
            for (Step : ReturnOffsets(), not Landed?):
                var TryX : float = Gate.X
                var TryY : float = Gate.Y
                if (Home > 1.0):
                    set TryX = Gate.X - Gate.X / Home * Step
                    set TryY = Gate.Y - Gate.Y / Home * Step

                HeldX := HeldInside(TryX, ArenaHalfLength - RescueWallInset)
                HeldY := HeldInside(TryY, ArenaHalfWidth - RescueWallInset)
                Landing := vector3{X := HeldX, Y := HeldY, Z := RescueFloorHeight}
                if (Body.TeleportTo[Landing, IdentityRotation()]):
                    set Landed = true
                    Log("DEBUG: SENT BACK a {Kind} that had stopped at X={Now.X} Y={Now.Y}. Returned to its spawner side at X={HeldX} Y={HeldY}.")
                    Forget(Hostile)

            if (not Landed?, Looks = StillLooksBeforeReport):
                Log("WARNING: a {Kind} would not move at X={Now.X} Y={Now.Y} and could not be put back at its spawner either. The wave cannot finish while it is stuck.")

    # Which spawner a robot of this kind arrives from. Falls back to the Swarmer
    # spawner, which is the only kind this rescue acts on anyway.
    SpawnerFor(Kind : string)<transacts>:npc_spawner_device =
        var Found : npc_spawner_device = SwarmerSpawner
        for (SlotIndex -> Spawner : AllSpawners()):
            if (KindFor(SlotIndex) = Kind):
                set Found = Spawner
        Found

    # A robot this close to its own spawner is treated as already home and is
    # never sent back, because the teleport would only reset it.
    @editable
    AlreadyHomeRadius : float = 500.0

    # How far towards the middle of the room each attempt pulls the landing spot
    # away from the spawner, in centimetres. Zero first, so an unobstructed
    # spawner puts the robot back exactly where its kind arrives.
    ReturnOffsets()<transacts>:[]float =
        array{0.0, 200.0, 500.0, 900.0}

    # The one robot that is supposed to stand still. Matches the third entry of
    # TypeNames above; change both together or neither.
    SentinelName : string = "Sentinel"

    IsSentinel(Kind : string)<transacts>:logic =
        if (Kind = SentinelName):
            true
        else:
            false

    # THE ONLY ROBOT THIS PROBE IS ALLOWED TO MOVE, as of Kai's ruling on
    # 2026-08-30: "its onyl reallt th swarers that ha d the stuck issue the tank
    # smakr men and baor sholdhave differen rules".
    #
    # THE PROBE WAS DOING HARM. The log shows it hauling a Sentinel in from
    # X=7 Y=894, which is a Sentinel doing its job, and every rescue lands on
    # the same doorway spot, so robots piled onto the doors and new arrivals
    # spawned into the pile and died. Kai saw that as robots dying the moment
    # they walked in.
    #
    # Matches the first entry of TypeNames above; change both together.
    SwarmerName : string = "Swarmer"

    IsSwarmer(Kind : string)<transacts>:logic =
        if (Kind = SwarmerName):
            true
        else:
            false

    # Whether a point is inside the gap the contestant is entitled to. A robot
    # in here is fighting them, not wedged.
    TooCloseToContestant(Where : vector3)<transacts>:logic =
        var Close : logic = false
        for (Contestant : GetPlayspace().GetPlayers(), Standing := Contestant.GetFortCharacter[], Standing.IsActive[]):
            Mine := Standing.GetTransform().Translation
            OffX := Where.X - Mine.X
            OffY := Where.Y - Mine.Y
            if (OffX * OffX + OffY * OffY < RescueSafeGap * RescueSafeGap):
                set Close = true
        Close

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
