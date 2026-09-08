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
# THE ASSETS MODULE, for `material`. A material is an asset type rather than a
# device or a maths type, so it lives here. Added 2026-09-06 with the warning
# marker's colour; script error 3506 named the module outright.
using { /Verse.org/Assets }
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
    # HOW FAR ABOVE THE FLOOR EACH PROP COMES TO REST. KAI, 2026-09-06: "some
    # things are falling through the floor, and the impact is happening a second
    # after."
    #
    # BOTH OF THOSE ARE ONE BUG. A prop's origin is not always at its base. One
    # whose origin sits at its middle LOOKS like it has touched the floor while
    # the code is still lowering that origin to FloorHeight, so it carries on
    # sinking, and the impact only fires when it finally arrives. Sunk pieces and
    # a late bang are the same mistake seen twice.
    #
    # ONE NUMBER PER PROP, in the SAME ORDER as DebrisAssets, exactly like
    # DebrisScales beside it. A girder that sinks half a metre wants 50 here.
    # Leave a slot out and it uses DebrisLift below.
    @editable
    DebrisLifts : []float = array{}

    @editable
    DebrisLift : float = 0.0

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

    # THE CRATE RECTANGLE, NOT THE ARENA. KAI, 2026-09-06: "they arent falling in
    # the arena????????????????????"
    #
    # This started at 1750 by 1250, the walls measured off the spawner positions,
    # and pieces landed at exactly X -1500 and Y 1000 over and over: shoved to
    # the edge of a rectangle bigger than the floor Kai can actually see.
    #
    # SimulatedAudience drops crates inside 1050 by 550 and every crate lands
    # where the contestant can walk to it, run after run, which is a stronger
    # piece of evidence than any measurement taken today. Debris borrows those
    # numbers rather than inventing a third set. Amendment 107 already warned
    # that 1050 by 550 is the crate-drop rectangle and NOT the room; that is
    # exactly why it is the right rectangle for dropping things into.
    @editable
    ArenaHalfLength : float = 1050.0

    @editable
    ArenaHalfWidth : float = 550.0

    # How far inside that rectangle a piece may land.
    @editable
    WallInset : float = 100.0

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
    CollapseSpread : float = 400.0

    # =================================================================
    # THE WARNING
    # =================================================================

    # A PROP LAID ON THE FLOOR, WHICH IS THE MARKER THAT ACTUALLY WORKS.
    # KAI, 2026-09-06: "i changed the icon to an X and i still only see little
    # floating red dots", then "use a prop instead."
    #
    # A vfx_creator_device plays particle bursts, not ground markings, so a red
    # X came out as a puff of dots in the air. A prop is a solid thing lying on
    # the floor at a size we choose, which is what a warning needs to be.
    #
    # PICK SOMETHING FLAT AND WIDE and give it a colour that is not in the arena.
    # One of the floor pieces laid down works; so does anything thin.
    # RED LIGHTS ON THE FLOOR, WHICH IS THE MARKER THAT FINALLY WORKS.
    # KAI, 2026-09-06: "i should be able to run over it to dodge yk", after a
    # prop marker that was white, sunk into the floor, lying on its side, and
    # solid enough to block the contestant.
    #
    # A prop was wrong on every count. It has collision, so the one thing you
    # must be able to sprint across becomes a wall. It spawns at whatever
    # orientation it was built with. It shows in its own colours unless a
    # material is made for it. And it needs lifting out of the floor by hand.
    #
    # A customizable_light_device has none of those problems. It casts a pool of
    # colour on the floor, it has no collision, there is no rotation to get
    # wrong, and the colour is set once on the device in UEFN.
    #
    # ONE PER PIECE THAT CAN BE FALLING AT ONCE, same as the VFX markers and for
    # the same reason: a device can only be in one place.
    @editable
    MarkerLights : []customizable_light_device = array{}

    # The prop marker is kept and defaults OFF. It is what Kai tried first and
    # the reasons it failed are worth keeping attached to the code rather than
    # deleted out of the history.
    @editable
    UseMarkerProp : logic = true

    @editable
    MarkerAsset : creative_prop_asset = DefaultCreativePropAsset

    # HOW HIGH THE WARNING LIGHT HANGS ABOVE THE SPOT, in centimetres, and which
    # way it points. Kai, 2026-09-07: "its red light but its not on the place
    # where its falling and its not bright enough".
    #
    # A LIGHT ON THE FLOOR LIGHTS THE FLOOR IT IS INSIDE. It was teleported to
    # the landing spot itself, which is the same mistake the Tank's spotlight
    # made: the lamp sits in the ground, most of what it throws goes into the
    # ground, and what escapes is a vague smear rather than a circle under the
    # piece. It was never in the wrong place. It was in the right place and
    # underneath it.
    #
    # Hung three metres up and aimed down, it puts a pool of light on the spot
    # the piece is about to land on, which is what Kai asked for on 2026-09-06:
    # "i want the red circle to appear on the floor underneath where its gonna
    # fall".
    #
    # BRIGHTNESS IS NOT HERE AND CANNOT BE. The Verse digest gives a light
    # Enable, Disable, TurnOn, TurnOff, Toggle, Dim and Undim, and nothing that
    # sets an intensity. Brightness is a Details panel setting on the placed
    # light device, so if it is still faint after this, that is the dial.
    @editable
    WarningLightHeight : float = 300.0

    @editable
    WarningLightPitchDegrees : float = -90.0

    # THE MARKER'S SIZE, PER AXIS, WHICH IS WHAT MAKES IT A STICKER.
    # KAI, 2026-09-06: "can you just write code to put something on the floor?"
    #
    # One number for size was the mistake. A prop is always solid, so a marker
    # you must be able to sprint across sounded impossible, and two hours went
    # into lights and particles trying to avoid the problem.
    #
    # SQUASH IT INSTEAD. Scaled wide and flat, a prop is a painted mark on the
    # ground with a millimetre of thickness, and a millimetre of collision is
    # something you walk over without noticing. Wide on X and Y, near nothing on
    # Z.
    #
    # DO NOT SET Z TO ZERO. A scale of nothing is a prop with no size at all,
    # which may not render or may behave oddly; 0.02 is thin enough to walk over
    # and still exists.
    @editable
    MarkerScaleX : float = 1.0

    @editable
    MarkerScaleY : float = 1.0

    @editable
    MarkerScaleZ : float = 0.02

    # HOW THE MARKER IS TURNED, in degrees. KAI, 2026-09-06: "i saw the prop but
    # its not lying flat." A prop is spawned at whatever orientation it was
    # built with, and a carpet built to hang is a carpet that hangs.
    #
    # Yaw spins it on the spot, pitch tips it forwards, roll tips it sideways.
    # A prop standing upright usually wants a pitch of 90 or -90 to lie down.
    # Try 90 first and flip the sign if it lies face down.
    @editable
    MarkerYaw : float = 0.0

    @editable
    MarkerPitch : float = 0.0

    @editable
    MarkerRoll : float = 0.0

    # THE COLOUR, FORCED ONTO THE PROP. KAI, 2026-09-06: "can i change the color
    # of the prop?" Yes: a material is painted over whatever the prop normally
    # looks like, the same way CrateManager paints a crate its tier colour.
    #
    # Make one in UEFN, give it the red you want, and put it here. Leave it
    # empty and the prop keeps its own look, which is fine if you picked
    # something already the right colour.
    @editable
    MarkerMaterials : []material = array{}

    # How many of the prop's material slots to paint. See LayMarkerProp: a prop
    # can have several and there is no way to ask how many, so this covers the
    # first few. Raise it if a prop is still showing its own colours somewhere.
    @editable
    MarkerMaterialSlots : int = 4

    # How far above the floor the marker sits. A little, so it is not fighting
    # the floor for the same pixels, which flickers.
    @editable
    MarkerLift : float = 5.0

    # WHETHER THE PROP MARKER IS LAID AT ALL. Off since 2026-09-07, on Kai's
    # ruling: "the light works."
    #
    # THERE ARE TWO MARKERS AND ONLY ONE OF THEM IS BEING USED. The prop route
    # wants a MarkerAsset filled in UEFN and that field is still empty, so every
    # single warning tried to lay a prop, failed, and logged about it: 280 times
    # in one session, drowning everything else in the log.
    #
    # The light is what reads on the floor now that it hangs above the spot and
    # points down, amendment 134. So this stops trying. Set it true and fill
    # MarkerAsset to bring the prop back; nothing else was removed.
    @editable
    ShowMarkerProp : logic = false

    # THE VFX MARKERS ARE KEPT AS WELL, and fire alongside the prop. They were
    # placed and wired before the prop route was chosen, they cost nothing, and
    # a burst of particles on top of a painted floor mark is better than either
    # alone. Empty the list to be rid of them.
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

    # GONE THE MOMENT IT LANDS. KAI, 2026-09-06: "the debris that flies out when
    # its landing needs to disappear as it hits the ground." It used to lie
    # there for over a second, which turned a spray of concrete into litter and
    # spent prop budget on it. Zero means the flight ends and the piece goes.
    # Raise it if the pop reads badly.
    @editable
    ShardRestSeconds : float = 0.0

    # =================================================================
    # A TEST MODE, FOR PICKING THE SIZES
    # =================================================================

    # KAI, 2026-09-06: "i need to test the sizes, can you have them all fall
    # down just for the next few runs so i can see."
    #
    # Ticked, every collapse drops ONE OF EVERY PROP in DebrisAssets, in list
    # order, spread across TestSpread so they land side by side and can be
    # compared. In list order specifically: the nth piece on the floor is the
    # nth number to type into DebrisScales.
    #
    # UNTICK IT BEFORE ANYONE PLAYS THIS. Nine pieces at once is not a game.
    @editable
    TestDropEveryPiece : logic = false

    # Brought down with the rectangle. At 1200 against a rectangle 950 wide,
    # nearly every test piece was clamped to the same edge and they landed in a
    # line rather than spread out.
    @editable
    TestSpread : float = 600.0

    @editable
    LogDebris : logic = true

    # Which markers are in use. Keyed on the index, the same shape TankEntrance
    # uses for its glows.
    var MarkerBusy : [int]logic = map{}

    # EVERY PIECE CURRENTLY ON THE FLOOR, so a run ending mid-fall can clear
    # them. Amendment 134, Kai 2026-09-07: "when debris fall down it persists to
    # the next game when i click play again".
    #
    # THE RACE IS WHY. A piece is spawned, lands, sleeps for DebrisLifeSeconds
    # and then disposes itself, and the whole of that lives inside RunDrops,
    # which is raced against the run ending. End a run while a piece is lying
    # there and the sleep is cancelled, so the Dispose after it never runs and
    # the girder is still on the floor of the next show.
    #
    # NOTHING IS EVER REMOVED FROM THIS MAP. Verse has no tidy key removal and
    # it does not need one: the sweep checks IsValid before disposing, so a
    # piece that already cleared itself is skipped, and the whole map is emptied
    # at the top of every run.
    var LivePieces : [int]creative_prop = map{}

    var NextPieceId : int = 0

    OnBegin<override>()<suspends>:void =
        # Every marker starts free. Without this the lookup in FreeMarker has no
        # entry to read and never finds one, which would mean no warning ever.
        # THE BODY LOGS RATHER THAN SKIPPING. `continue` is reserved in Verse and
        # not usable, script error 3101, so the branch needs something real in
        # it. TankEntrance does the same for its glow pool and this is copied
        # from it, log line and all.
        for (Index := 0..MarkerPoolSize() - 1):
            if (set MarkerBusy[Index] = false):
                Log("DEBUG: Debris warning marker {Index} is free and waiting.")

        # DARK UNTIL A PIECE IS ANNOUNCED. Kai asked the right question on
        # 2026-09-07: "will it not shot up when i play until the debris fall?"
        # It would have. A Customizable Light has no "start off" setting of its
        # own, only Enabled During Phase, so every warning lamp would sit lit
        # wherever it was parked from the moment the match began, and the first
        # real warning would be one more red light among several.
        #
        # TankEntrance has done exactly this since its spotlights went in, for
        # exactly this reason. These were simply never given the same treatment.
        for (Lamp : MarkerLights):
            Lamp.Enable()
            Lamp.TurnOff()

        Log("DEBUG: Falling debris watching. {DebrisAssets.Length} piece(s) to choose from, one every {DropEveryMinSeconds}s to {DropEveryMaxSeconds}s, lying there for {DebrisLifeSeconds}s, with {WarningMarkers.Length} warning marker(s) and {MarkerLights.Length} light(s), all started off.")

        # NOTHING FALLS BEFORE PLAY, and nothing carries over. The outer loop is
        # the restart, the same shape every manager in this project uses: the
        # dropper is raced against the run ending rather than spawned, because a
        # spawn cannot be cancelled and a second run would then have two.
        loop:
            AwaitMatchStart(Self)

            race:
                RunDrops()
                AwaitRunEnd(Self)

            SweepTheFloor()
            Log("DEBUG: Falling debris stood down -- the run ended.")

    # Clears every piece still lying about and forgets them all. See LivePieces.
    SweepTheFloor():void =
        var Cleared : int = 0
        for (Id -> Piece : LivePieces):
            if (Piece.IsValid[]):
                Piece.Dispose()
                set Cleared = Cleared + 1

        set LivePieces = map{}
        Log("DEBUG: Falling debris -- {Cleared} piece(s) swept off the floor for the next run.")

    RunDrops()<suspends>:void =
        loop:
            Sleep(GetRandomFloat(DropEveryMinSeconds, DropEveryMaxSeconds))

            # A COLLAPSE, NOT A PIECE. Each one is spawned separately so they
            # fall together rather than queueing, and so the wait for the next
            # collapse starts now rather than after these have finished lying on
            # the floor. Otherwise every piece would add its fifteen seconds to
            # the gap.
            var HowMany : int = GetRandomInt(PiecesPerCollapseMin, PiecesPerCollapseMax)
            var Start : int = GetRandomInt(0, DebrisAssets.Length - 1)
            var Spread : float = CollapseSpread

            # THE TEST MODE. Everything, in order, spread wide. See the dial.
            if (TestDropEveryPiece?):
                set HowMany = DebrisAssets.Length
                set Start = 0
                set Spread = TestSpread

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
            for (Piece := 0..HowMany - 1):
                # IN TEST MODE THEY GO ON A RING, EVENLY SPACED. KAI: "can u make
                # sure its spread out and not overlapping when they fall so i can
                # see." Scattering at random is right for a collapse, where two
                # pieces landing near each other is a pile of rubble, and wrong
                # for a lineup, where it hides one prop behind another.
                Spot := if (TestDropEveryPiece?) then EvenlySpaced(Middle, Piece, HowMany) else ScatteredAround(Middle, Spread)
                spawn{ DropOnePiece(Spot, Start + Piece) }

    DropOnePiece(Spot : vector3, Which : int)<suspends>:void =
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
                Above := vector3:
                    X := Spot.X
                    Y := Spot.Y
                    Z := Spot.Z + CeilingHeight

                Size := ScaleForPiece(Index)
                ScaleVector := vector3{X := Size, Y := Size, Z := Size}

                # The resting height for THIS prop, in plain world units.
                #
                # IT USED TO BE MULTIPLIED BY THE PIECE'S SIZE, on the reasoning
                # that a girder at half size sinks half as far. True, and useless
                # in practice: at DebrisScale 0.3 a lift of 40 became 12, so Kai
                # typed numbers and nothing moved. "okay i added the debris lift
                # but it didnt do anything", 2026-09-06.
                #
                # A number you type is now the number of centimetres it moves.
                # The cost is that changing a prop's size means revisiting its
                # lift, which is a fair trade for a dial that behaves.
                Lift := LiftForPiece(Index)

                Rest := vector3:
                    X := Spot.X
                    Y := Spot.Y
                    Z := Spot.Z + Lift
                Start := transform{Translation := Above, Rotation := IdentityRotation(), Scale := ScaleVector}
                Result := SpawnProp(Asset, Start)

                if (Piece := Result(0)?):
                    # Nobody can shoot it apart. See the header.
                    set Piece.CanBeDamaged = false

                    # On the books until it is off the floor. See LivePieces.
                    set NextPieceId = NextPieceId + 1
                    if (set LivePieces[NextPieceId] = Piece):
                        Log("DEBUG: Debris piece {NextPieceId} is on the books.")

                    # OUT OF SIGHT WHILE THE WARNING RUNS. The prop is spawned up
                    # at the ceiling and simply waits there, so the contestant
                    # sees the marker on the floor and nothing above it until the
                    # drop begins.
                    if (LogDebris?):
                        Log("DEBUG: Debris piece {Index} warning at X={Spot.X} Y={Spot.Y}. Size {Size}, resting {Lift} above the floor.")

                    # THE MARKER STAYS UP UNTIL THE PIECE LANDS ON IT. KAI'S
                    # RULING, 2026-09-06: "i want the red circle to appear on the
                    # floor underneath where its gonna fall and last until
                    # impact." It used to go out when the drop began, which left
                    # the last second of the fall unmarked, exactly when the
                    # contestant most needs to know where not to be standing.
                    Marker := ShowWarning(Spot)

                    # See ShowMarkerProp. False is the same "there is none"
                    # the function itself answers when no prop could be made, so
                    # HideMarkerProp already knows what to do with it.
                    var Painted : ?creative_prop = false
                    if (ShowMarkerProp?):
                        set Painted = LayMarkerProp(Spot)
                    Sleep(WarningSeconds)

                    Dropped := Piece.MoveTo(Rest, IdentityRotation(), FallSeconds)
                    HideWarning(Marker)
                    HideMarkerProp(Painted)
                    ImpactSound.Play()
                    # Both measured from the spot on the FLOOR, not from where
                    # the prop's origin came to rest. A girder lifted 50cm still
                    # lands on the same piece of floor.
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

        if (Index := FreeMarker[]):
            # THE LIGHT FIRST, because it is the one that reads on the floor.
            if (Lamp := MarkerLights[Index]):
                # ABOVE THE SPOT AND POINTING DOWN. See WarningLightHeight.
                Overhead := vector3:
                    X := Spot.X
                    Y := Spot.Y
                    Z := Spot.Z + WarningLightHeight

                Aim := MakeRotationFromYawPitchRollDegrees(0.0, WarningLightPitchDegrees, 0.0)

                if (Lamp.TeleportTo[Overhead, Aim]):
                    Lamp.Enable()
                    Lamp.TurnOn()
                    if (set MarkerBusy[Index] = true):
                        set Used = Index
                        Log("DEBUG: Warning light {Index} on at X={Spot.X} Y={Spot.Y}.")
                else:
                    Log("WARNING: a debris warning light would not move to X={Spot.X} Y={Spot.Y}.")

        if (Index := Used, Index >= 0, Marker := WarningMarkers[Index]):
            if (Marker.TeleportTo[Spot, IdentityRotation()]):
                # BEGIN, NOT ENABLE, AND THAT IS THE WHOLE BUG. Enable only
                # switches the device on; Begin is what starts the effect
                # playing. The first version called Enable and the log happily
                # reported a warning being placed while nothing appeared on the
                # floor. TankEntrance drives its Tank glow with Begin and End
                # and has worked all along.
                #
                # Enable first anyway, so a marker left switched off in UEFN
                # still plays.
                Marker.Enable()
                Marker.Begin()
                WarningSound.Play()
                Log("DEBUG: Warning particles {Index} lit at X={Spot.X} Y={Spot.Y}.")

        Used

    # Lays the marker prop on the floor and hands it back so it can be taken up
    # again when the piece lands on it. Renamed from ShowMarkerProp on
    # 2026-09-07, since that name is now the switch that decides whether it runs.
    LayMarkerProp(Spot : vector3):?creative_prop =
        var Laid : ?creative_prop = false

        if (UseMarkerProp?):
            Where := vector3{X := Spot.X, Y := Spot.Y, Z := Spot.Z + MarkerLift}
            Size := vector3{X := MarkerScaleX, Y := MarkerScaleY, Z := MarkerScaleZ}
            Lying := MakeRotationFromYawPitchRollDegrees(MarkerYaw, MarkerPitch, MarkerRoll)
            Made := SpawnProp(MarkerAsset, transform{Translation := Where, Rotation := Lying, Scale := Size})

            # SAYS WHAT IT DID. Added 2026-09-06: Kai reported "marker prop
            # wasnt used, or at least it wasnt the one i picked" and nothing in
            # this routine spoke, so there was no way to tell a marker that
            # never spawned from one that spawned wrong.
            if (LogDebris?):
                Log("DEBUG: Marker prop laid at X={Where.X} Y={Where.Y} Z={Where.Z}, scale {MarkerScaleX} by {MarkerScaleY} by {MarkerScaleZ}, yaw {MarkerYaw} pitch {MarkerPitch} roll {MarkerRoll}, {MarkerMaterials.Length} material(s) to paint with.")

            if (Mark := Made(0)?):
                # NOBODY SHOOTS THE WARNING. Same reason the debris itself
                # cannot be damaged: hostiles mob anything that can be.
                set Mark.CanBeDamaged = false

                # A LIST OF ONE IS THE NORMAL CASE. It is a list rather than a
                # single material so a future version can flash between two, and
                # because copying CrateManager's shape costs nothing today.
                # EVERY SLOT, NOT JUST THE FIRST. KAI, 2026-09-06: "not red
                # still", with MI_Simple_MediumRed_Flat sitting in the list and
                # the log confirming it was applied forty times.
                #
                # A prop can carry several material slots, and SetMaterial takes
                # an Index which defaults to the first of them. Kai's alphabet X
                # shows on a later one, so painting slot 0 painted something
                # nobody can see. There is no way to ask a prop how many slots it
                # has, so this paints the first MarkerMaterialSlots of them and a
                # slot that is not there costs nothing.
                if (Paint := MarkerMaterials[0]):
                    for (Slot := 0..MarkerMaterialSlots - 1):
                        Mark.SetMaterial(Paint, ?Index := Slot)

                    if (LogDebris?):
                        Log("DEBUG: Marker prop painted across {MarkerMaterialSlots} material slot(s).")

                set Laid = option{Mark}

        if (not Laid?, LogDebris?):
            Log("WARNING: the marker prop did not spawn. Check Marker Asset is set on this device.")

        Laid

    HideMarkerProp(Painted : ?creative_prop):void =
        if (Mark := Painted?):
            Mark.Dispose()

    HideWarning(Index : int):void =
        if (Index >= 0):
            if (Lamp := MarkerLights[Index]):
                Lamp.TurnOff()

            if (Marker := WarningMarkers[Index]):
                Marker.End()

            if (set MarkerBusy[Index] = false):
                return

    # As many markers as either list holds, so filling one and leaving the other
    # empty still gives a full pool.
    MarkerPoolSize()<transacts>:int =
        var Biggest : int = WarningMarkers.Length
        if (MarkerLights.Length > Biggest):
            set Biggest = MarkerLights.Length
        Biggest

    # Copied in shape from TankEntrance.FreeGlow, including the reason it works:
    # every index is given an entry at OnBegin, so the lookup below always finds
    # one and "not Busy" is a real answer rather than a missing key.
    FreeMarker()<transacts><decides>:int =
        var Found : int = -1
        for (Index := 0..MarkerPoolSize() - 1, Found < 0):
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

    # This prop's own resting height above the floor. See the dials for why a
    # prop needs one at all.
    LiftForPiece(AssetIndex : int)<transacts>:float =
        var Lift : float = DebrisLift
        if (Found := DebrisLifts[AssetIndex]):
            set Lift = Found
        Lift

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

    # One test piece's spot: evenly spaced around a ring, so nine props land as
    # nine separate things rather than a heap. Held inside the rectangle like
    # everything else, so a ring near an edge flattens against it rather than
    # putting pieces through a wall.
    EvenlySpaced(Middle : vector3, Piece : int, HowMany : int)<transacts>:vector3 =
        Edge := ArenaHalfLength - WallInset
        Side := ArenaHalfWidth - WallInset

        # COUNTED, NOT CONVERTED. Verse will not turn a whole number into a
        # fraction on its own: dividing a float by an int is script error 3509
        # and there is no conversion function anywhere in the digest.
        # HypeMeterManager's bulb hit this first and says the same thing.
        #
        # So both numbers are counted up as floats and the angle is stepped
        # round, which needs no division by an int at all.
        var TotalAsFloat : float = 0.0
        for (Each := 0..HowMany - 1):
            set TotalAsFloat = TotalAsFloat + 1.0

        var Angle : float = 0.0
        if (TotalAsFloat > 0.0):
            Step := FullCircleRadians / TotalAsFloat
            for (Each := 0..Piece - 1):
                set Angle = Angle + Step

        vector3:
            X := HeldInside(Middle.X + Cos(Angle) * TestSpread, Edge)
            Y := HeldInside(Middle.Y + Sin(Angle) * TestSpread, Side)
            Z := FloorHeight

    # One piece's spot, scattered around the middle of its collapse and then
    # held inside the room, so a cave-in near a wall still lands on the floor.
    ScatteredAround(Middle : vector3, Spread : float)<transacts>:vector3 =
        Edge := ArenaHalfLength - WallInset
        Side := ArenaHalfWidth - WallInset

        vector3:
            X := HeldInside(Middle.X + GetRandomFloat(-Spread, Spread), Edge)
            Y := HeldInside(Middle.Y + GetRandomFloat(-Spread, Spread), Side)
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
