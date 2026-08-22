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

    # How far from this device a crate may land, in centimetres. PLACE THIS
    # DEVICE IN THE MIDDLE OF THE ARENA: its own position is the centre.
    #
    # 1100 rather than 1500, 2026-08-22. 1500 came from amendment 51's 15-metre
    # radius, which is the arena's own half-width, so a crate could land exactly
    # in a wall. The room was measured from the playtest log at roughly 25 to 26
    # metres across, and 1100 leaves about 1.8 metres of margin so every crate
    # lands on open floor. Amendment 59's "46-metre room" is wrong.
    @editable
    ArenaRadius : float = 1100.0

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
        Print("DEBUG: Simulated Audience watching. Trickle every {TrickleSeconds}s, arena radius {ArenaRadius}.")
        spawn{ WatchForTierClimbs() }
        spawn{ RunTrickle() }

    # Trigger 1. GDD 2.1 step 3, "crossing Hype thresholds".
    WatchForTierClimbs()<suspends>:void =
        loop:
            Sleep(PollSeconds)
            Current := TierForHype(HypeMeter.GetHype())
            if (Current > LastTier):
                Print("DEBUG: Hype climbed to {TierName(Current)}. Ordering a crate.")
                OrderCrate(Current)
            # Tracked downward too, so falling back and re-climbing orders another.
            set LastTier = Current

    # Trigger 2. The trickle, so the loop keeps turning between climbs.
    RunTrickle()<suspends>:void =
        loop:
            Sleep(TrickleSeconds)
            Tier := TierForHype(HypeMeter.GetHype())
            Print("DEBUG: Trickle due. Ordering a {TierName(Tier)} crate.")
            OrderCrate(Tier)

    # The handoff itself. Picks the spot, signals, and forgets.
    OrderCrate(Tier : int):void =
        Spot := RandomLandingSpot()
        Print("DEBUG: SpawnCrateEvent -- tier {Tier} ({TierName(Tier)}) at X={Spot.X} Y={Spot.Y} Z={Spot.Z}")
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

    # A random point on the arena floor within ArenaRadius of this device. The
    # square root keeps the spread even instead of crowding the middle.
    RandomLandingSpot()<transacts>:vector3 =
        Centre := GetTransform().Translation
        Angle := GetRandomFloat(0.0, 6.2831853)
        # Named DistanceFromCentre, not Distance: SpatialMath already exports a
        # Distance function and the compiler cannot tell the two apart.
        DistanceFromCentre := ArenaRadius * Sqrt(GetRandomFloat(0.0, 1.0))
        vector3:
            X := Centre.X + Cos(Angle) * DistanceFromCentre
            Y := Centre.Y + Sin(Angle) * DistanceFromCentre
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
