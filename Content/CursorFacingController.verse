# CursorFacingController.verse
#
# GDD Section 2.2 "Controls & Twin-Stick Aiming", specifically the half the
# engine does not deliver: the body and weapon following the cursor instead of
# the direction of travel. Twin-stick aiming is uncuttable per GDD 5.7.
#
# WHY THIS EXISTS.
# Facing Direction on the Third Person Controls device is inert on this build.
# The device IS reaching the player: Movement Speed Multiplier at 2.0 visibly
# doubled run speed in the same playtest where Facing Direction did nothing. So
# the device works and one setting on it is dead. Epic ticket FORT-1110974.
#
# WHERE THE CURSOR DIRECTION COMES FROM, AND WHY NOT THE OBVIOUS PLACE.
# GetViewRotation is documented as "the rotation where this fort_character is
# looking or aiming at" (Fortnite digest 8368). Measured across four playtests,
# with and without the overhead camera, its yaw read 0.000000 on all but 2 of
# 272 samples. It does not work on this build. Do not build on it.
#
# The entity's own global transform does work. Standing still, no movement keys,
# sweeping the mouse one full circle, its yaw traced a clean 360: 25.9, 49.1,
# 64.0, 80.2, 93.5, 112.1, 129.1, 151.5, 179.2, -153.8, -126.1, -106.0, -80.9,
# -59.1, -41.3, -25.4, -10.4, 0.1. That is the number this file reads.
#
# THE ROUTE THAT LOOKS RIGHT AND IS NOT. Do not build it.
# The widely suggested approach is two custom 2D Input Actions, a left stick for
# movement and a right stick for aim, read through an input_action_device with
# .Listen(), driving the character with MoveBy. None of those three exist in
# this build: no input_action_device, no .Listen, no MoveBy, zero mentions
# across all three digests. input_action itself is marked epic_internal, so a
# custom one cannot be made, and the only input actions Verse can see are six
# fixed buttons: Reload, WeaponPrimary, WeaponSecondary, Crouch, Sprint, Jump.
# All on/off. There is no aim axis to read anywhere in the API.
#
# HOW IT TURNS THE PLAYER.
# TeleportTo "applies the yaw and pitch of Rotation" (Fortnite digest 8434) and
# is the only handle Verse has on a player's facing. So the character is
# teleported onto the spot it already occupies, carrying a new yaw. Pitch and
# roll are forced flat: a top-down character must never tip.
#
# THIS IS A TEST, NOT A KNOWN-GOOD FIX. TWO WAYS IT CAN FAIL, BOTH EXPECTED.
#   1. If the yaw being read turns out to be the same value the teleport writes,
#      the loop feeds itself, the number freezes at whatever was last written,
#      and the mouse stops mattering. The once-a-second log line below prints
#      what was read next to what was written precisely so this is visible
#      rather than mysterious.
#   2. Teleporting a live player thirty times a second is not what teleport is
#      for. It may fight movement, stutter, or interrupt firing.
# Playtest before trusting any of it.

using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/SceneGraph }
using { /Verse.org/SpatialMath }
using { /Verse.org/Simulation }

cursor_facing_controller := class(creative_device):

    # How often the body is turned, in seconds. 0.03 is about thirty times a
    # second, which reads as continuous. Raise it if the game stutters.
    @editable
    UpdateSeconds : float = 0.03

    # Turn this ON in UEFN if the character comes out facing backwards. The
    # weapon currently renders opposite the head, and which of the two the
    # teleport lands on cannot be known until it is played. This is the switch
    # for that, so a wrong guess costs a checkbox and not a code change.
    @editable
    InvertFacing : logic = false

    # How many degrees the cursor must move before the body is turned again.
    # Stops a stationary player being teleported thirty times a second over a
    # fraction of a degree of mouse drift.
    @editable
    DeadzoneDegrees : float = 2.0

    # How often to print a reading, in seconds. Diagnostic only. Set high to
    # quieten the log once this is trusted.
    @editable
    LogEverySeconds : float = 1.0

    OnBegin<override>()<suspends>:void =
        Playspace := GetPlayspace()

        # Subscribed before existing players are handled, so anyone arriving
        # while that loop runs is still caught.
        Playspace.PlayerAddedEvent().Subscribe(OnPlayerAdded)

        Players := Playspace.GetPlayers()
        Print("DEBUG: Cursor facing starting -- {Players.Length} player(s) already here, InvertFacing is {InvertText()}")
        for (JoinedPlayer : Players):
            spawn{ DriveFacing(JoinedPlayer) }

    OnPlayerAdded(JoinedPlayer : player):void =
        Print("DEBUG: Cursor facing -- player joined, starting their facing loop")
        spawn{ DriveFacing(JoinedPlayer) }

    # A logic value cannot be dropped into a printed line: ToString has no
    # overload for it. So it is turned into a word first.
    InvertText()<transacts>:string =
        if (InvertFacing?) then "yes" else "no"

    # One copy of this runs per player, for as long as the match lasts.
    DriveFacing(TargetPlayer : player)<suspends>:void =
        # The yaw last written, so the deadzone has something to compare to.
        var LastWrittenYaw : float = 0.0
        var SecondsSinceLog : float = 0.0

        loop:
            Sleep(UpdateSeconds)
            set SecondsSinceLog += UpdateSeconds

            if:
                Character := TargetPlayer.GetFortCharacter[]
                PlayerEntity := Character.GetEntity[]
            then:
                # A tuple, not an array. GetGlobalTransform is the Verse.org
                # rotation and its GetYawPitchRollDegrees returns three values
                # in round brackets. The Temporary one returns an array in
                # square brackets. Same name, two shapes. See AimRotationProbe.
                CursorAngles := PlayerEntity.GetGlobalTransform().Rotation.GetYawPitchRollDegrees()
                CursorYaw := CursorAngles(0)

                var WantedYaw : float = CursorYaw
                if (InvertFacing?):
                    set WantedYaw = CursorYaw + 180.0

                if (SecondsSinceLog >= LogEverySeconds):
                    set SecondsSinceLog = 0.0
                    Print("DEBUG: Cursor facing -- read {CursorYaw} | writing {WantedYaw} | last written {LastWrittenYaw}")

                # Only turn when the cursor has actually moved.
                Change := WantedYaw - LastWrittenYaw
                Moved := if (Change < 0.0) then -Change else Change
                if (Moved >= DeadzoneDegrees):
                    CurrentPosition := Character.GetTransform().Translation
                    # Spelled out in full because BOTH SpatialMath modules define
                    # a function with this name, and the TeleportTo below takes
                    # the Temporary one. Left unqualified it is ambiguous.
                    WantedRotation := (/UnrealEngine.com/Temporary/SpatialMath:)MakeRotationFromYawPitchRollDegrees(WantedYaw, 0.0, 0.0)
                    if (Character.TeleportTo[CurrentPosition, WantedRotation]):
                        set LastWrittenYaw = WantedYaw
                    else:
                        Print("DEBUG: Cursor facing -- TeleportTo refused at yaw {WantedYaw}")
