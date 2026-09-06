# FallingDebris.verse
#
# GDD Section 1.1 "Arena Aesthetics", and BUILD_ORDER item 14's two static
# obstacle types, which 1.1 says "block player movement and enemy pathfinding,
# forcing frantic tactical maneuvering."
#
# KAI'S RULING, 2026-09-06: "like the props falling, like broken sets and lights
# and stuff... they should stay as obstacles and disappear after a few seconds,
# like idk 15?"
#
# WHY THIS IS ONE JOB AND NOT TWO. The arena has needed obstacles since the
# build order was written, and the instructor's playtest asked separately for
# something to change between waves so progress does not feel static. A set
# piece crashing out of the roof and lying there for fifteen seconds is both:
# the show falling apart around the contestant, and a thing they and the robots
# have to path around while it lasts.
#
# THEY ARE NOT PERMANENT, AND THAT IS KAI'S CALL. GDD 1.1 calls the obstacles
# static and 2.5 has them reset when a room is won. Debris that clears itself
# after DebrisLifeSeconds needs no reset, because there is never anything left
# to put back. Recorded as a departure rather than hidden: the room's furniture
# changes constantly instead of being rearranged between rooms.
#
# IT CAN LAND ON YOU, AND THAT IS THE POINT. KAI'S RULING, 2026-09-06: "if it
# falls on me it should take half my health." An earlier draft of this file
# picked spots that avoided the contestant, which made the debris scenery. It
# falls where it falls now, and standing under it costs you.
#
# HALF OF WHAT YOU HAVE LEFT, NOT HALF OF FULL. Half of the current reading can
# never take a contestant to zero, so a girder is always a disaster and never a
# death. What it CAN do is drop them under the Death Save's trigger, which is
# exactly the right amount of dangerous.
#
# ROBOTS ARE NOT CRUSHED YET. Kai: "if it hits robots and stuff we can work on
# that after." Deliberately left out rather than guessed at.
#
# THE PIECES CANNOT BE SHOT. CanBeDamaged is forced off. A crate learnt this the
# hard way on 2026-08-22: hostiles mob anything damageable, and three of them
# removed a crate inside a second. Debris nobody can destroy is debris that
# lasts exactly as long as it is meant to.
#
# YOU GET A WARNING, AND YOU HAVE TO. KAI'S RULING, 2026-09-06: "have like a red
# circle on the bottom before it falls so the person knows something is falling."
# A hazard that takes half your health with no tell is not a hazard, it is a
# tax. A marker sits on the spot for WarningSeconds before anything leaves the
# roof, which is the whole difference between being caught out and being caught
# napping.
#
# THE MARKERS ARE A POOL, one per piece that can be in the air at once, and that
# is not an optimisation. A vfx_creator_device can only be in one place, so two
# collapses sharing one marker would drag it between them and read as a smear.
# Same reasoning as the Tank's glows in TankEntrance.verse. Run out and the
# piece simply falls unannounced, which is the behaviour before this rather than
# a fault.
#
# LEAVE DebrisAssets EMPTY AND NOTHING HAPPENS AT ALL, so a half-dressed arena
# is still shippable.

using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Random }
using { /Verse.org/Simulation }

falling_debris_manager := class(creative_device):

    # =================================================================
    # WHAT FALLS
    # =================================================================

    # Broken set pieces, lights, girders, whatever the arena is dressed with.
    # One is picked at random each time.
    @editable
    DebrisAssets : []creative_prop_asset = array{}

    # THE SIZE OF EACH PIECE, TWO WAYS. KAI'S RULING, 2026-09-06: "all these
    # things should be different sizes though?"
    #
    # DebrisScales is one number per prop, in the SAME ORDER as DebrisAssets, so
    # a hanging light can be small and a gantry can be huge. Leave a slot out
    # and that prop falls back to DebrisScale below. Same shape the cash drops
    # already use, so the two files read alike.
    #
    # AND THEN EVERY PIECE IS NUDGED. Even with a size per prop, the same girder
    # twice is the same girder twice. A small random multiplier on top means no
    # two pieces of the same prop are ever quite the same size, which is what
    # stops a floor of debris looking stamped out.
    @editable
    DebrisScales : []float = array{}

    # 1.0 WAS FAR TOO BIG. KAI, 2026-09-06: "props are wayy too big." At natural
    # size these are the arena's own girders and floor beams, which span a good
    # part of the room, so a piece of one falling filled the floor.
    #
    # 0.3 is a starting guess rather than a measurement, because the props'
    # real dimensions cannot be read from here. Raise it until a piece is
    # something you have to go around rather than something you cannot see past.
    @editable
    DebrisScale : float = 0.3

    # Narrowed with it. A third either way on top of a big number is a big
    # number.
    @editable
    ScaleVaryMin : float = 0.85

    @editable
    ScaleVaryMax : float = 1.15

    # Played the moment a piece lands. Volume lives on the device, as all sound
    # in this project does; Verse cannot set it.
    @editable
    ImpactSound : audio_player_device = audio_player_device{}

    # Everything off with one tick, for a playtest that wants a clean arena.
    @editable
    DebrisOn : logic = true

    # =================================================================
    # WHEN, AND FOR HOW LONG
    # =================================================================

    # A fresh wait between every piece, so the arena never falls apart to a
    # rhythm. Rooms run 35 to 60 seconds, measured 2026-09-05, so this is
    # roughly one or two pieces a room.
    @editable
    DropEveryMinSeconds : float = 20.0

    @editable
    DropEveryMaxSeconds : float = 40.0

    # KAI'S FIFTEEN SECONDS. Long enough to have to go round, short enough that
    # the floor never silts up. It also keeps the prop budget honest: GDD 5.3
    # allows about 100 active props and cash drops are already spending them.
    @editable
    DebrisLifeSeconds : float = 15.0

    # How far above the floor a piece starts, and how long it takes to arrive.
    # Fast, because a set piece falling in slow motion reads as a balloon.
    @editable
    CeilingHeight : float = 1600.0

    @editable
    FallSeconds : float = 0.9

    # =================================================================
    # WHERE
    # =================================================================

    # The room, from its middle. Measured off the four spawner positions the
    # game itself reported on 2026-09-05; see WaveManager for the long version.
    @editable
    ArenaHalfLength : float = 1750.0

    @editable
    ArenaHalfWidth : float = 1250.0

    # How far inside the walls a piece may land, so nothing lands half through
    # one.
    @editable
    WallInset : float = 250.0

    # The floor the contestant and the robots actually stand on. NOT zero: the
    # 2026-09-05 log has the contestant at Z 87.5 while several devices in this
    # project still believed the floor was at 0, which is how the Death Save's
    # med kit ended up underneath it.
    @editable
    FloorHeight : float = 85.0

    # How close to the landing spot counts as being under it.
    @editable
    ImpactRadius : float = 250.0

    # What a piece takes off a contestant it lands on, as a share of the health
    # they have left. Half, per Kai. A share rather than a number, so it scales
    # with whatever the health pool is set to and can never quite finish them.
    @editable
    ImpactShareOfHealth : float = 0.5

    # HOW MANY COME DOWN TOGETHER. KAI'S RULING, 2026-09-06: "yeah 2 or 3 at
    # once." A fresh roll each time between these two, so a collapse is
    # sometimes a pair and sometimes a proper cave-in rather than a fixed
    # pattern the contestant learns to read.
    @editable
    PiecesPerCollapseMin : int = 2

    @editable
    PiecesPerCollapseMax : int = 3

    # How far apart the pieces of one collapse are scattered. Without this they
    # would all be handed the same random spot and land inside each other, which
    # reads as one prop rather than three.
    @editable
    CollapseSpread : float = 700.0

    # =================================================================
    # THE WARNING
    # =================================================================

    # One marker per piece that can be in the air at once, so at three pieces a
    # collapse, place at least three. A red ring or a target decal on the floor.
    @editable
    WarningMarkers : []vfx_creator_device = array{}

    # How long the marker sits there before the piece leaves the roof. Long
    # enough to move out of, short enough that it is still a scare.
    @editable
    WarningSeconds : float = 1.2

    # Played when a marker appears, if you want one.
    @editable
    WarningSound : audio_player_device = audio_player_device{}

    # =================================================================
    # BREAKING UP ON IMPACT
    # =================================================================

    # KAI: "cant it fall and break?", then "maybe pieces of concrete fly out so
    # it looks like theres impact." A prop cannot shatter, so the impact is
    # faked: a handful of small pieces thrown out from where it lands, which
    # scatter and vanish.
    #
    # THEIR OWN LIST, AND KAI IS RIGHT THAT IT MATTERS. The first version drew
    # them from DebrisAssets at a quarter size, which throws out tiny girders and
    # miniature light fittings. Rubble is what flies off a thing hitting a floor.
    # GDD 1.1 names "broken concrete debris" outright, so this is the GDD's own
    # material rather than an invention.
    #
    # LEAVE IT EMPTY AND IT FALLS BACK to DebrisAssets, so the impact still
    # happens before any rubble has been chosen.
    @editable
    ShardAssets : []creative_prop_asset = array{}

    @editable
    ShardCount : int = 5

    @editable
    ShardScale : float = 0.25

    @editable
    ShardReach : float = 260.0

    @editable
    ShardFlightSeconds : float = 0.45

    @editable
    ShardRestSeconds : float = 1.2

    @editable
    LogDebris : logic = true

    # Which markers are in use. Keyed on the index, the same shape TankEntrance
    # uses for its glows.
    var MarkerBusy : [int]logic = map{}

    OnBegin<override>()<suspends>:void =
        # Every marker starts free. Without this the lookup in FreeMarker has no
        # entry to read and never finds one, which would mean no warning ever.
        # THE BODY LOGS RATHER THAN SKIPPING. `continue` is reserved in Verse and
        # not usable, script error 3101, so the branch needs something real in
        # it. TankEntrance does the same for its glow pool and this is copied
        # from it, log line and all.
        for (Index := 0..WarningMarkers.Length - 1):
            if (set MarkerBusy[Index] = false):
                Log("DEBUG: Debris warning marker {Index} is free and waiting.")

        Log("DEBUG: Falling debris watching. {DebrisAssets.Length} piece(s) to choose from, one every {DropEveryMinSeconds}s to {DropEveryMaxSeconds}s, lying there for {DebrisLifeSeconds}s, with {WarningMarkers.Length} warning marker(s).")

        # NOTHING FALLS BEFORE PLAY, and nothing carries over. The outer loop is
        # the restart, the same shape every manager in this project uses: the
        # dropper is raced against the run ending rather than spawned, because a
        # spawn cannot be cancelled and a second run would then have two.
        loop:
            AwaitMatchStart(Self)

            race:
                RunDrops()
                AwaitRunEnd(Self)

            Log("DEBUG: Falling debris stood down -- the run ended.")

    RunDrops()<suspends>:void =
        loop:
            Sleep(GetRandomFloat(DropEveryMinSeconds, DropEveryMaxSeconds))

            # A COLLAPSE, NOT A PIECE. Each one is spawned separately so they
            # fall together rather than queueing, and so the wait for the next
            # collapse starts now rather than after these have finished lying on
            # the floor. Otherwise every piece would add its fifteen seconds to
            # the gap.
            HowMany := GetRandomInt(PiecesPerCollapseMin, PiecesPerCollapseMax)
            Middle := SomewhereInTheRoom()

            if (LogDebris?):
                Log("DEBUG: Collapse -- {HowMany} pieces coming down around X={Middle.X} Y={Middle.Y}.")

            # NO TWO PIECES OF ONE COLLAPSE ARE THE SAME PROP. KAI'S RULING,
            # 2026-09-06: "can i put more than 3 things and we can code to
            # shuffle out these things and drop other stuff so its not the same
            # 3 things."
            #
            # A random START into the list, then each piece takes the next one
            # along, wrapping at the end. That guarantees three different props
            # in a collapse of three, and the start moving every time is what
            # stops the same trio arriving in the same order. Picking each piece
            # independently, which is what this did, could hand out the same
            # prop three times over.
            #
            # A LIST SHORTER THAN THE COLLAPSE STILL WORKS. The wrap means a list
            # of two, asked for three pieces, uses both and then repeats one,
            # which is the best that list allows.
            Start := GetRandomInt(0, DebrisAssets.Length - 1)

            for (Piece := 0..HowMany - 1):
                spawn{ DropOnePiece(Middle, Start + Piece) }

    DropOnePiece(Middle : vector3, Which : int)<suspends>:void =
        if (DebrisOn?, DebrisAssets.Length > 0):
            # Wrapped by hand rather than with a modulo, because Which is only
            # ever a small step past the start and Verse's remainder on a
            # negative would be its own conversation.
            var Index : int = Which
            loop:
                if (Index < DebrisAssets.Length):
                    break
                set Index = Index - DebrisAssets.Length

            if (Asset := DebrisAssets[Index]):
                Spot := ScatteredAround(Middle)
                Above := vector3:
                    X := Spot.X
                    Y := Spot.Y
                    Z := Spot.Z + CeilingHeight

                Size := ScaleForPiece(Index)
                ScaleVector := vector3{X := Size, Y := Size, Z := Size}
                Start := transform{Translation := Above, Rotation := IdentityRotation(), Scale := ScaleVector}
                Result := SpawnProp(Asset, Start)

                if (Piece := Result(0)?):
                    # Nobody can shoot it apart. See the header.
                    set Piece.CanBeDamaged = false

                    # OUT OF SIGHT WHILE THE WARNING RUNS. The prop is spawned up
                    # at the ceiling and simply waits there, so the contestant
                    # sees the marker on the floor and nothing above it until the
                    # drop begins.
                    if (LogDebris?):
                        Log("DEBUG: Debris warning at X={Spot.X} Y={Spot.Y}.")

                    # THE MARKER STAYS UP UNTIL THE PIECE LANDS ON IT. KAI'S
                    # RULING, 2026-09-06: "i want the red circle to appear on the
                    # floor underneath where its gonna fall and last until
                    # impact." It used to go out when the drop began, which left
                    # the last second of the fall unmarked, exactly when the
                    # contestant most needs to know where not to be standing.
                    Marker := ShowWarning(Spot)
                    Sleep(WarningSeconds)

                    Dropped := Piece.MoveTo(Spot, IdentityRotation(), FallSeconds)
                    HideWarning(Marker)
                    ImpactSound.Play()
                    CrushAnyoneUnder(Spot)
                    spawn{ ThrowShards(Spot) }

                    if (LogDebris?):
                        Log("DEBUG: Debris landed. Blocking the floor for {DebrisLifeSeconds}s.")

                    Sleep(DebrisLifeSeconds)
                    Piece.Dispose()

                    if (LogDebris?):
                        Log("DEBUG: Debris cleared away.")

    # Puts a marker on the spot and answers which one, so it can be released
    # again. -1 means there was none free, and the piece falls unannounced.
    ShowWarning(Spot : vector3):int =
        var Used : int = -1

        if (Index := FreeMarker[], Marker := WarningMarkers[Index]):
            if (Marker.TeleportTo[Spot, IdentityRotation()]):
                Marker.Enable()
                WarningSound.Play()
                if (set MarkerBusy[Index] = true):
                    set Used = Index

        Used

    HideWarning(Index : int):void =
        if (Index >= 0, Marker := WarningMarkers[Index]):
            Marker.Disable()
            if (set MarkerBusy[Index] = false):
                return

    # Copied in shape from TankEntrance.FreeGlow, including the reason it works:
    # every index is given an entry at OnBegin, so the lookup below always finds
    # one and "not Busy" is a real answer rather than a missing key.
    FreeMarker()<transacts><decides>:int =
        var Found : int = -1
        for (Index := 0..WarningMarkers.Length - 1, Found < 0):
            if (Busy := MarkerBusy[Index], not Busy?):
                set Found = Index
        Found >= 0
        Found

    # THE BREAK. A handful of small pieces thrown out from the point of impact,
    # which land and vanish. Drawn from the same list at ShardScale, so no new
    # art is needed, and thrown along a flat ring rather than a real arc: they
    # are on screen for under two seconds and nobody reads the curve.
    ThrowShards(Spot : vector3)<suspends>:void =
        Rubble := if (ShardAssets.Length > 0) then ShardAssets else DebrisAssets

        if (Rubble.Length > 0):
            for (Shard := 0..ShardCount - 1):
                Index := GetRandomInt(0, Rubble.Length - 1)

                if (Asset := Rubble[Index]):
                    Angle := GetRandomFloat(0.0, FullCircleRadians)
                    Reach := GetRandomFloat(ShardReach * 0.3, ShardReach)

                    Landing := vector3:
                        X := Spot.X + Cos(Angle) * Reach
                        Y := Spot.Y + Sin(Angle) * Reach
                        Z := FloorHeight

                    Small := vector3{X := ShardScale, Y := ShardScale, Z := ShardScale}
                    Start := transform{Translation := Spot, Rotation := IdentityRotation(), Scale := Small}
                    Made := SpawnProp(Asset, Start)

                    if (Bit := Made(0)?):
                        set Bit.CanBeDamaged = false
                        spawn{ RunOneShard(Bit, Landing) }

    RunOneShard(Bit : creative_prop, Landing : vector3)<suspends>:void =
        Thrown := Bit.MoveTo(Landing, IdentityRotation(), ShardFlightSeconds)
        Sleep(ShardRestSeconds)
        Bit.Dispose()

    FullCircleRadians : float = 6.2831853

    # This prop's own size, nudged so two of the same never match exactly. See
    # the dials for the reasoning.
    ScaleForPiece(AssetIndex : int)<transacts>:float =
        var Base : float = DebrisScale
        if (Found := DebrisScales[AssetIndex]):
            set Base = Found

        var Vary : float = 1.0
        if (ScaleVaryMax > ScaleVaryMin):
            set Vary = GetRandomFloat(ScaleVaryMin, ScaleVaryMax)

        Base * Vary

    # One piece's spot, scattered around the middle of its collapse and then
    # held inside the room, so a cave-in near a wall still lands on the floor.
    ScatteredAround(Middle : vector3)<transacts>:vector3 =
        Edge := ArenaHalfLength - WallInset
        Side := ArenaHalfWidth - WallInset

        vector3:
            X := HeldInside(Middle.X + GetRandomFloat(-CollapseSpread, CollapseSpread), Edge)
            Y := HeldInside(Middle.Y + GetRandomFloat(-CollapseSpread, CollapseSpread), Side)
            Z := FloorHeight

    HeldInside(Preferred : float, Limit : float)<transacts>:float =
        if (Preferred > Limit):
            return Limit
        if (Preferred < -Limit):
            return -Limit
        Preferred

    # The middle of a collapse. It does not care where anybody is standing: see
    # the header for why that is the whole idea.
    SomewhereInTheRoom()<transacts>:vector3 =
        vector3:
            X := GetRandomFloat(-(ArenaHalfLength - WallInset), ArenaHalfLength - WallInset)
            Y := GetRandomFloat(-(ArenaHalfWidth - WallInset), ArenaHalfWidth - WallInset)
            Z := FloorHeight

    # Takes a share of the health of anybody standing under a piece as it
    # lands. Measured flat, ignoring height, the same way the Death Save
    # measures reaching the med kit: the contestant stands about 85cm up and
    # counting that would eat most of the radius.
    CrushAnyoneUnder(Spot : vector3):void =
        for (Contestant : GetPlayspace().GetPlayers(), Standing := Contestant.GetFortCharacter[], Standing.IsActive[]):
            Mine := Standing.GetTransform().Translation
            OffX := Spot.X - Mine.X
            OffY := Spot.Y - Mine.Y

            if (OffX * OffX + OffY * OffY <= ImpactRadius * ImpactRadius):
                Before := Standing.GetHealth()
                Hurt := Before * ImpactShareOfHealth
                Standing.Damage(Hurt)
                Log("DEBUG: Debris landed ON the contestant. {Hurt} taken, {Before} down to {Standing.GetHealth()}.")
