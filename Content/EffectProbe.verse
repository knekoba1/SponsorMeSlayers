# EffectProbe.verse
#
# GDD Section 3.2 "Color-Coded Paraglider Crates", amendment 65.
#
# MEASUREMENT ONLY. TEMPORARY. DELETE ONCE ANSWERED.
# Plays each candidate effect in turn at the contestant's feet, one every few
# seconds, printing which one is playing as it goes. It changes nothing about
# the game.
#
# THE QUESTION IT ANSWERS.
# Amendment 65 opens a crate on two shots, and that moment is invisible. Three
# effects have been tried at the crate and none was seen, so the question is no
# longer which effect to pick: it is whether SpawnParticleSystem renders at all
# in this build, and if it does, which of the effects on offer are big enough to
# read from GDD 1.1's overhead camera.
#
# WHY ALL OF THEM AT ONCE. Every attempt so far cost one launch, one playtest
# and one report to test a single effect. Kai called that out on 2026-08-23 and
# was right. This tests the whole shortlist in one recording.
#
# HOW TO READ IT. Fill Candidates with every effect worth trying, stand still,
# and record ten seconds. Each "PROBE: playing candidate N" line timestamps
# exactly when that one fired, so the recording can be matched to the list. A
# candidate with nothing on screen at its moment is a dud. No lines at all means
# SpawnParticleSystem renders nothing and the whole route is dead.

using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Assets }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Assets }
using { /Verse.org/Simulation }

effect_probe := class(creative_device):

    # Every effect worth trying, in the order they will be played.
    @editable
    Candidates : []particle_system = array{}

    # Seconds between one candidate and the next. Long enough to tell them
    # apart on a recording, short enough that ten seconds covers a few.
    @editable
    GapSeconds : float = 2.0

    # How high above the floor each one is played, in centimetres, so an effect
    # is not buried in the floor mesh.
    @editable
    PlayHeight : float = 50.0

    OnBegin<override>()<suspends>:void =
        Print("DEBUG: Effect probe running with {Candidates.Length} candidate(s).")

        if (Candidates.Length < 1):
            Print("WARNING: Effect probe has nothing to play. Fill Candidates.")

        loop:
            var Index : int = 0
            loop:
                if (Index >= Candidates.Length):
                    break

                if (Effect := Candidates[Index]):
                    Played := SpawnParticleSystem(Effect, WhereToPlay())
                    Print("PROBE: playing candidate {Index} now.")

                Sleep(GapSeconds)
                set Index += 1

            Print("PROBE: end of the list, starting again.")

    # The contestant's feet if they are in the arena, otherwise this device's
    # own spot, so the probe still shows something in an empty match.
    WhereToPlay()<transacts>:vector3 =
        var Spot : vector3 = GetTransform().Translation
        if:
            Contestant := GetPlayspace().GetPlayers()[0]
            Character := Contestant.GetFortCharacter[]
            Character.IsActive[]
        then:
            Ground := Character.GetTransform().Translation
            set Spot = vector3{X := Ground.X, Y := Ground.Y, Z := Ground.Z + PlayHeight}
        Spot
