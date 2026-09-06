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

    @editable
    DebrisScale : float = 1.0

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

    @editable
    LogDebris : logic = true

    OnBegin<override>()<suspends>:void =
        Log("DEBUG: Falling debris watching. {DebrisAssets.Length} piece(s) to choose from, one every {DropEveryMinSeconds}s to {DropEveryMaxSeconds}s, lying there for {DebrisLifeSeconds}s.")

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

            # SPAWNED, so the wait for the next piece starts now rather than
            # after this one has finished lying on the floor. Otherwise every
            # piece would add its fifteen seconds to the gap.
            spawn{ DropOnePiece() }

    DropOnePiece()<suspends>:void =
        if (DebrisOn?, DebrisAssets.Length > 0):
            Index := GetRandomInt(0, DebrisAssets.Length - 1)

            if (Asset := DebrisAssets[Index]):
                Spot := SomewhereInTheRoom()
                Above := vector3:
                    X := Spot.X
                    Y := Spot.Y
                    Z := Spot.Z + CeilingHeight

                ScaleVector := vector3{X := DebrisScale, Y := DebrisScale, Z := DebrisScale}
                Start := transform{Translation := Above, Rotation := IdentityRotation(), Scale := ScaleVector}
                Result := SpawnProp(Asset, Start)

                if (Piece := Result(0)?):
                    # Nobody can shoot it apart. See the header.
                    set Piece.CanBeDamaged = false

                    if (LogDebris?):
                        Log("DEBUG: Debris falling to X={Spot.X} Y={Spot.Y}.")

                    Dropped := Piece.MoveTo(Spot, IdentityRotation(), FallSeconds)
                    ImpactSound.Play()
                    CrushAnyoneUnder(Spot)

                    if (LogDebris?):
                        Log("DEBUG: Debris landed. Blocking the floor for {DebrisLifeSeconds}s.")

                    Sleep(DebrisLifeSeconds)
                    Piece.Dispose()

                    if (LogDebris?):
                        Log("DEBUG: Debris cleared away.")

    # A landing spot inside the room. It does not care where anybody is
    # standing: see the header for why that is the whole idea.
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
