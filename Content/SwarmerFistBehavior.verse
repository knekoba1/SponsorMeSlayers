# SwarmerFistBehavior.verse
#
# GDD Section 2.2 hostile roster, "weak melee Cyber-Swarmers", and GDD 5.1's
# "2 cybernetic hostile models (melee Swarmer, heavy Ranged Tank)".
#
# WHY THIS FILE EXISTS.
# Fortnite's built-in hostile brain only chases and attacks while the NPC is
# holding a weapon. Tested 2026-08-20: an empty weapon field, Nitro Gauntlets,
# Seven Power Gloves and Myst Form each left the Swarmer standing still and
# harmless. Only a plain melee weapon such as Basic Hammer made it fight, and
# Kai's ruling is that Swarmers fight bare-handed. So this replaces the built-in
# brain for Swarmers only: it walks each one at the nearest player, and takes
# health off that player while it is close enough to touch them.
#
# WHAT IT CANNOT DO.
# Verse cannot play an attack animation on an NPC, so a Swarmer damages by
# reaching the player, not by visibly swinging. It reads as a robot barging into
# you and hurting you.
#
# WHERE IT GOES.
# On the Swarmer NPC Spawner only, in Override NPC Behavior Script. The Boar,
# Sentinel and Tank keep Epic's brain and their own weapons, so nothing else in
# the map should point at this.

using { /Fortnite.com/AI }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Playspaces }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Simulation }

swarmer_fist_behavior<public> := class(npc_behavior):

    # Health removed by one connecting punch. The GDD calls the Swarmers "weak"
    # and never gives a number, so 5 is Kai's ruling 2026-08-20: against a 200
    # health pool one Swarmer is a nuisance and a crowd of them is the threat.
    # The Boar, Sentinel and Tank each take 20 per hit for comparison.
    @editable
    PunchDamage : float = 5.0

    # Seconds between punches from a single Swarmer.
    @editable
    PunchIntervalSeconds : float = 1.0

    # How close counts as touching, in centimetres. 200 is two metres, roughly
    # arm's length once both bodies are allowed for.
    @editable
    PunchReach : float = 200.0

    # Pause between one walk finishing and the next decision, in seconds. Also
    # the guard that stops this loop spinning when the player cannot be reached
    # at all, so it must never be 0.0.
    @editable
    RepathIntervalSeconds : float = 0.1

    # How long the lunge lasts, in seconds. Long enough to see, short enough
    # that the Swarmer does not shove the player around the arena.
    @editable
    LungeSeconds : float = 0.2

    # Where the walk stops, in centimetres. This MUST be smaller than
    # PunchReach. It was the same number at first, which parked every Swarmer
    # exactly on the edge of its own punch, so the blow missed by a hair and
    # nothing ever landed. 100 walks them a metre inside reach.
    @editable
    ChaseStopDistance : float = 100.0

    # Range within which a near miss is logged, in centimetres. Diagnostic
    # only. Set it to 0.0 to silence the near-miss line once this is trusted.
    @editable
    DiagnosticRange : float = 600.0

    # THE LOOP RUNS INSIDE OnBegin, NOT IN A spawn. House style launches
    # long-running work with spawn, but a spawned task is not cancelled when
    # this NPC is removed from the arena, and a dead Swarmer that keeps punching
    # would be a bug that only shows up under load.
    OnBegin<override>()<suspends>:void =
        if (MyAgent := GetAgent[]):
            if (MyChar := MyAgent.GetFortCharacter[]):
                if (MyEntity := GetEntity[]):
                    if (Playspace := MyEntity.GetPlayspaceForEntity[]):
                        ChaseAndPunchLoop(MyChar, Playspace)
                    else:
                        Log("DEBUG: Swarmer fists -- no playspace, this Swarmer will stand still.")
                else:
                    Log("DEBUG: Swarmer fists -- no entity, this Swarmer will stand still.")
            else:
                Log("DEBUG: Swarmer fists -- no character, this Swarmer will stand still.")
        else:
            Log("DEBUG: Swarmer fists -- no agent, this Swarmer will stand still.")

    # ONE LOOP, NOT TWO. Chasing and punching used to be separate loops raced
    # against each other. Once the punch grew a lunge, both wanted to drive the
    # same feet, and two navigation calls on one body fight. Keeping them in one
    # loop makes the order explicit: close the gap, or, if already close, hit.
    #
    # DO NOT RACE THE WALK AGAINST A TIMER. It was, to force a re-aim twice a
    # second, and cancelling the walk mid-stride made every Swarmer hobble:
    # start, stop, start. Kai spotted it on sight, 2026-08-20. The destination
    # is the player rather than a fixed spot, so the walk tracks them by itself
    # and needs no interrupting.
    ChaseAndPunchLoop(MyChar : fort_character, Playspace : fort_playspace)<suspends>:void =
        loop:
            if (not MyChar.IsActive[]):
                return
            if (Nav := MyChar.GetNavigatable[], Target := FindNearestPlayer[MyChar, Playspace], TargetChar := Target.GetFortCharacter[]):
                Gap := Distance(MyChar.GetTransform().Translation, TargetChar.GetTransform().Translation)
                if (Gap <= PunchReach):
                    TargetChar.Damage(PunchDamage)
                    Log("DEBUG: Swarmer fists -- PUNCH LANDED at {Gap} cm, -{PunchDamage} health.")
                    Lunge(Nav, Target)
                    Sleep(PunchIntervalSeconds)
                else:
                    if (Gap <= DiagnosticRange):
                        Log("DEBUG: Swarmer fists -- closing, {Gap} cm away.")
                    Nav.NavigateTo(MakeNavigationTarget(Target), ?ReachRadius := ChaseStopDistance)
                    Sleep(RepathIntervalSeconds)
            else:
                Sleep(RepathIntervalSeconds)

    # THE VISIBLE BLOW. Verse can play an animation on an NPC, but only from an
    # animation asset held in the project, and this project has none: Fortnite's
    # own punch animations are not exposed to Verse. So the tell is movement.
    # For LungeSeconds the Swarmer walks with no stopping distance at all, which
    # throws it at the player, and the next pass of the loop settles it back to
    # ChaseStopDistance. Kai's call 2026-08-20, after asking why a hit that
    # clearly landed could not be seen.
    Lunge(Nav : navigatable, Target : player)<suspends>:void =
        race:
            Nav.NavigateTo(MakeNavigationTarget(Target), ?ReachRadius := 0.0)
            Sleep(LungeSeconds)

    # Nearest living player, or failure when the arena holds none. Distance is
    # measured between feet, which is close enough at this scale.
    FindNearestPlayer(MyChar : fort_character, Playspace : fort_playspace)<transacts><decides>:player =
        MyPosition := MyChar.GetTransform().Translation
        var Nearest : ?player = false
        var NearestDistance : float = 1000000.0
        for (Contestant : Playspace.GetPlayers()):
            if (ContestantChar := Contestant.GetFortCharacter[], ContestantChar.IsActive[]):
                Gap := Distance(MyPosition, ContestantChar.GetTransform().Translation)
                if (Gap < NearestDistance):
                    set NearestDistance = Gap
                    set Nearest = option{Contestant}
        Nearest?
