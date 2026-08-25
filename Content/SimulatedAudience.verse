# SimulatedAudience.verse
#
# GDD Section 4 "Simulated Audience" -- decides the quality tier and the landing
# spot of every paraglider crate, and does nothing else.
#
# WHY THIS IS ITS OWN FILE. The Section 4 handoff table gives this system the
# "random-coordinate crate spawn parameters" and gives Gameplay Systems the
# machinery that actually puts a crate in the arena. GDD 4.1 makes the human
# designer the only checkpoint between the two. Keeping them apart is what makes
# this system swappable: it can be replaced, stubbed, or fed fixed test numbers
# without touching a line of crate-spawning code. DO NOT MERGE THE TWO.
#
# THE HANDOFF. This file signals SpawnCrateEvent, named after GDD 4.2's payload,
# carrying a tier and a 3D location. Whoever drops crates awaits that event.
# This file spawns nothing and holds no reference to any crate device.
#
# WHEN A CRATE IS ORDERED. Two triggers, Kailee's ruling 2026-08-18:
#   1. Climbing into a higher Hype tier, which is GDD 2.1 step 3's "crossing
#      Hype thresholds", graded at the tier just entered.
#   2. A repeating trickle, graded at whatever tier the player is in when it
#      fires. 2.1 calls the loop recursive, and threshold crossings alone deliver
#      only three or four crates in a whole run, which leaves steps 3 and 4 of
#      that loop barely happening.
#
# TIERS ARE NUMBERS HERE, 0 to 3. Underdog 0, Rising Star 1, Superstar 2, Prime
# Time 3. The receiving side keeps one Supply Drop Spawner per tier, each with
# its own Supply FXColor for GDD 3.2's colour coding, so a number indexes that
# list directly. Prime Time is amendment 24 and is not in the GDD.

using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Random }
using { /Verse.org/Simulation }

# One crate order: the payload of GDD 4.2's SpawnCrateEvent.
crate_order := struct:
    # 0 Underdog, 1 Rising Star, 2 Superstar, 3 Prime Time.
    Tier : int
    # Where the crate should come down.
    LandingSpot : vector3

simulated_audience := class(creative_device):

    # The Hype meter this audience watches. GDD Section 4 gives the meter and the
    # crate parameters to the same system, so it is reading its own other half.
    @editable
    HypeMeter : hype_meter_manager = hype_meter_manager{}

    # Hype at or above this is Rising Star. Amendment 13, ruled 2026-08-18.
    @editable
    RisingStarAt : float = 40.0

    # Hype at or above this is Superstar. Amendment 13.
    @editable
    SuperstarAt : float = 75.0

    # Hype at or above this is Prime Time. Amendment 24, a departure from the
    # GDD, which names only three tiers.
    @editable
    PrimeTimeAt : float = 95.0

    # Seconds between trickle crates. 25 is a starting guess meant to be tuned by
    # feel in UEFN. Mirror any change back into this default.
    @editable
    TrickleSeconds : float = 25.0

    # HOW FAR A CRATE MAY LAND FROM THIS DEVICE, AS A RECTANGLE RATHER THAN A
    # CIRCLE. PLACE THIS DEVICE IN THE MIDDLE OF THE ARENA: its own position is
    # the centre, and if it sits off to one side the whole zone shifts with it.
    #
    # WHY NOT A CIRCLE. The arena is five floor tiles by three, confirmed by Kai
    # 2026-08-22, which at 512 a tile is 25.6 by 15.4 metres. A circle wide enough
    # to use the length spills out of the sides, because the short axis is only
    # 7.7 metres from the middle. Crates were landing outside the room.
    #
    # 1050 and 550 leave roughly two metres of margin on every side, so a crate
    # never lands in a wall or close enough to one to be awkward to reach.
    #
    # This supersedes the circular radius twice ruled on 2026-08-22, at 1500 and
    # then 1100. Both were measured against the room's LENGTH, which was the
    # wrong axis: the short one is what a crate falls out of.
    @editable
    ArenaHalfLength : float = 1050.0

    # The short axis, the three-tile one.
    @editable
    ArenaHalfWidth : float = 550.0

    # The floor the crate comes down to, matching DeathSaveManager's FloorHeight.
    @editable
    FloorHeight : float = 0.0

    # How often the Hype meter is checked for a tier change.
    @editable
    PollSeconds : float = 0.25

    # GDD 4.2's SpawnCrateEvent, and the only thing this file offers the outside
    # world.
    SpawnCrateEvent : event(crate_order) = event(crate_order){}

    # The tier the player was in at the last check, so a climb can be told from
    # standing still. Starts at Underdog.
    var LastTier : int = 0

    OnBegin<override>()<suspends>:void =
        Log("DEBUG: Simulated Audience watching. Trickle every {TrickleSeconds}s, arena {ArenaHalfLength} by {ArenaHalfWidth} from centre.")
        # No crates ordered until PLAY is clicked. Amendment 70.
        AwaitMatchStart(Self)
        spawn{ WatchForTierClimbs() }
        spawn{ RunTrickle() }

    # Trigger 1. GDD 2.1 step 3, "crossing Hype thresholds".
    WatchForTierClimbs()<suspends>:void =
        loop:
            Sleep(PollSeconds)
            Current := TierForHype(HypeMeter.GetHype())
            if (Current > LastTier):
                Log("DEBUG: Hype climbed to {TierName(Current)}. Ordering a crate.")
                OrderCrate(Current)
            # Tracked downward too, so falling back and re-climbing orders another.
            set LastTier = Current

    # Trigger 2. The trickle, so the loop keeps turning between climbs.
    RunTrickle()<suspends>:void =
        loop:
            Sleep(TrickleSeconds)
            Tier := TierForHype(HypeMeter.GetHype())
            Log("DEBUG: Trickle due. Ordering a {TierName(Tier)} crate.")
            OrderCrate(Tier)

    # The handoff itself. Picks the spot, signals, and forgets.
    OrderCrate(Tier : int):void =
        Spot := RandomLandingSpot()
        Log("DEBUG: SpawnCrateEvent -- tier {Tier} ({TierName(Tier)}) at X={Spot.X} Y={Spot.Y} Z={Spot.Z}")
        SpawnCrateEvent.Signal(crate_order{Tier := Tier, LandingSpot := Spot})

    # Which tier a Hype reading falls in. Amendment 13's bands.
    TierForHype(Hype : float)<transacts>:int =
        if (Hype >= PrimeTimeAt):
            3
        else if (Hype >= SuperstarAt):
            2
        else if (Hype >= RisingStarAt):
            1
        else:
            0

    # A random point on the arena floor inside the rectangle this device sits in
    # the middle of. Even by construction: a flat random pick on each axis is
    # already spread evenly across a rectangle, which is why the circle's square
    # root correction is gone with it.
    RandomLandingSpot()<transacts>:vector3 =
        Centre := GetTransform().Translation
        vector3:
            X := Centre.X + GetRandomFloat(-ArenaHalfLength, ArenaHalfLength)
            Y := Centre.Y + GetRandomFloat(-ArenaHalfWidth, ArenaHalfWidth)
            Z := FloorHeight

    # For the log only.
    TierName(Tier : int)<transacts>:string =
        if (Tier >= 3):
            "Prime Time"
        else if (Tier = 2):
            "Superstar"
        else if (Tier = 1):
            "Rising Star"
        else:
            "Underdog"
