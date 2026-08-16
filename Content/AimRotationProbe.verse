# AimRotationProbe.verse
#
# GDD Section 2.2 "Controls & Twin-Stick Aiming".
#
# MEASUREMENT ONLY. TEMPORARY. DELETE ONCE ANSWERED.
# One job: print the aim rotation and the body's actual facing side by side, once
# every SampleSeconds. It does not move, rotate, teleport or force anything, and
# it never writes to the character. Reading only.
#
# THE QUESTION IT ANSWERS.
# On this build the character's body faces the mirror image of the cursor. Aim
# left and the body faces right. Shots inside the body's twist arc still follow
# the cursor correctly, but past that arc the player's own model sits between the
# barrel and the target and the shot goes along the body instead, which is what
# makes that arc unshootable. See GDD_AMENDMENTS.md item 6.
#
# GetViewRotation is documented (Fortnite digest line 8368) as "the rotation where
# this fort_character is looking or aiming at".
#
#   * If AIM yaw tracks the CURSOR while BODY yaw does not, the engine is holding
#     the correct aim and only the body is wrong. That is a precise, reproducible
#     bug that no existing Epic ticket describes, and worth filing with footage.
#
#   * If AIM yaw and BODY yaw move together, the aim value is mirrored too, the
#     fault is upstream of anything reachable from Verse, and there is nothing
#     left to try.
#
# HOW TO READ IT.
# Yaw is a compass bearing in degrees and it wraps: -180 and 180 are the same
# direction. Point the cursor at one edge of the screen, hold still for two or
# three seconds so you get repeated readings, then move to the next edge.
#
# The printed difference is NOT wrapped, so read it loosely. A difference near
# 180 or near -180 is the mirror. A difference near 0 means the two agree. A
# difference of, say, 350 is the same as -10.
#
# TWO ROTATION TYPES, WHICH IS A TRAP.
# GetViewRotation returns the Temporary SpatialMath rotation, whose
# GetYawPitchRollDegrees hands back an ARRAY of three floats (UnrealEngine digest
# line 1273). GetGlobalTransform returns the Verse.org SpatialMath transform, and
# ITS rotation hands back a TUPLE (Verse digest line 3108). Same function name,
# two types, two different return shapes. Hence the array brackets in one place
# and the tuple parentheses in the other.

using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/SceneGraph }
using { /Verse.org/SpatialMath }
using { /Verse.org/Simulation }

aim_rotation_probe := class(creative_device):

    # How often to print. One second is slow enough to read back in the log and
    # fast enough to catch a deliberate pause at each screen edge.
    @editable
    SampleSeconds : float = 1.0

    OnBegin<override>()<suspends>:void =
        Print("DEBUG: Aim probe starting -- yaw is a compass bearing in degrees and wraps at 180")

        Playspace := GetPlayspace()

        loop:
            Sleep(SampleSeconds)
            for (WatchedPlayer : Playspace.GetPlayers()):
                ReportAim(WatchedPlayer)

    ReportAim(WatchedPlayer : player):void =
        if (Character := WatchedPlayer.GetFortCharacter[]):
            AimAngles := Character.GetViewRotation().GetYawPitchRollDegrees()

            if (AimYaw := AimAngles[0]):
                if (PlayerEntity := Character.GetEntity[]):
                    BodyAngles := PlayerEntity.GetGlobalTransform().Rotation.GetYawPitchRollDegrees()
                    BodyYaw := BodyAngles(0)
                    Difference := AimYaw - BodyYaw
                    Print("DEBUG: Aim probe -- AIM yaw {AimYaw} | BODY yaw {BodyYaw} | difference {Difference}")
                else:
                    Print("DEBUG: Aim probe -- AIM yaw {AimYaw} | BODY unavailable, no entity for this character")
            else:
                Print("DEBUG: Aim probe -- aim rotation returned no yaw")
        else:
            Print("DEBUG: Aim probe -- no character yet")
