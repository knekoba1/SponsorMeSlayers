# TwinStickController.verse
#
# GDD Section 1.1 "Look and Feel" (locked top-down camera at a fixed height) and
# GDD Section 2.2 "Controls & Twin-Stick Aiming" (movement on WASD, aiming
# independent and tracked by the mouse cursor). Twin-stick aiming is listed as
# uncuttable in GDD 5.7.
#
# SCOPE. Handing the camera and the control scheme to players. Nothing else.
# This device does not aim anything, does not fire anything, and does not decide
# how the camera looks.
#
# THE FEEL OF THE CAMERA IS SET IN UEFN, NOT HERE.
# Neither device exposes a single runtime setter in the Verse API: both are
# nothing but Enable, Disable, AddTo, AddToAll, RemoveFrom and RemoveFromAll. So
# every number that decides how this plays lives on the two placed devices, and
# there is nothing to mirror back into this script. Two settings in particular
# are load-bearing:
#
#   * Fixed Angle Camera. Angle Pitch near -90 for the overhead view, Distance
#     for the height that frames the whole arena, and a NARROW Field of View.
#     The narrow field of view is what stands in for the orthographic
#     perspective GDD 1.1 asks for and UEFN cannot publish. See
#     GDD_AMENDMENTS.md item 5.
#
#   * Third Person Controls. Facing Direction must be TWIN STICK, and Twin Stick
#     Mouse Aim Mode must be TARGET CURSOR. That pair is the whole of GDD 2.2:
#     it is what makes the player aim at the mouse cursor instead of facing
#     wherever they are walking. Left on the default, Facing Direction is
#     Movement, and the player turns to face their own WASD input. The game
#     still runs, it just stops being a twin-stick shooter.
#
#   * Third Person Controls, targeting. Targeting Assistance must be OFF and
#     Targeting Lock On must be OFF. Both were found ON in the map on
#     2026-08-22, which is why shots bent toward hostiles instead of going
#     where the cursor pointed. GDD 2.2 makes aiming "entirely independent,
#     tracked dynamically via the mouse cursor", so an assist works against
#     that spec rather than for it.
#
#     DO NOT TRUST AMENDMENT 6 ON THIS. It records both options as off during
#     the rear-arc investigation. They were switched off to test and not left
#     that way, and nothing noticed for two months.
#
#     This also gates a feature. Amendment 65 has the player shoot a crate
#     open, and an assist that drags shots onto hostiles makes a crate
#     unshootable in the middle of a crowd.
#
# If the aiming feels wrong, the two devices in the map are where to look. This
# script cannot cause it.
#
# THE FACING WORKAROUND, AND WHY IT IS HERE.
# On this build the player's body locks to one fixed direction and ignores the
# mouse entirely. Frame by frame, with the character standing still in one spot:
# cursor up-left, body up-right. Cursor down-left, body up-right. Cursor
# directly below, body up-right. It is not mirrored and it is not offset, it is
# stuck. Respawning does not clear it. Camera yaw does not change it. Target
# Cursor and Dial Aiming behave identically, which is what you would expect if
# the cursor is not being read at all.
#
# That is the locked-facing symptom of Epic ticket FORT-1110974, backlogged on
# 1 June 2026. The community workaround is to take the controls device away from
# the player and hand it straight back a moment after it was first applied,
# forcing the facing logic to start over. This file does that below.
#
# NOTE. Every creator reporting success with this had a bug that respawning also
# cleared. Ours survives respawn, so this may not be the same fault underneath.
#
# ONLY the controls are cycled. The camera is applied once and left alone. It
# works correctly and there is no reason to disturb it.
#
# WHY EVERY PLAYER IS HANDLED ONE AT A TIME.
# Both devices work as a per-player stack: AddTo pushes onto one player and
# makes it their active camera or active controls. Nobody who was not pushed
# gets it. A player who joins after the match has started therefore has an empty
# stack and drops back to Fortnite's ordinary third-person camera and controls,
# in a game that has no third-person camera anywhere else in it. So the
# playspace's PlayerAddedEvent is subscribed to and late joiners are handed both
# on arrival.

using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Simulation }

twin_stick_controller := class(creative_device):

    # The locked top-down camera of GDD 1.1, and the Art Direction Bible's
    # "camera never moves". A FIXED POINT camera, not a fixed angle one: Epic
    # documents the fixed angle camera as one that "can move to follow the
    # player", and it does, playtested 2026-08-21 with the deadzone on, sized to
    # the whole arena, and both follow speeds at zero. It still followed. The
    # fixed point camera is the only one that genuinely stays put. Kai's ruling
    # 2026-08-21, amendment 59.
    #
    # Place a Fixed Point Camera in the map, above the arena, and point this at
    # it. Only AddTo is called on it, which lives on the shared camera base
    # class, so nothing else in this file changes.
    @editable
    TopDownCamera : gameplay_camera_fixed_point_device = gameplay_camera_fixed_point_device{}

    # The twin-stick control scheme of GDD 2.2. Place a Third Person Controls
    # device in the map and point this at it. Its Facing Direction setting is
    # what decides whether aiming is independent of movement; see the header.
    @editable
    TwinStickControls : gameplay_controls_third_person_device = gameplay_controls_third_person_device{}

    # How long to wait after first handing the controls over before taking them
    # away again. Long enough that the game has finished setting the player up,
    # short enough that the player does not notice.
    @editable
    DelayBeforeRemove : float = 0.5

    # How long to sit with no controls applied before handing them back. This is
    # the pause that gives the facing logic a clean start.
    @editable
    DelayBeforeReAdd : float = 0.5

    OnBegin<override>()<suspends>:void =
        Playspace := GetPlayspace()

        # Subscribed BEFORE the existing players are handled, so anyone who
        # arrives while that loop is running is still caught.
        Playspace.PlayerAddedEvent().Subscribe(OnPlayerAdded)

        Players := Playspace.GetPlayers()
        Log("DEBUG: Twin-stick controller starting -- {Players.Length} player(s) already here")
        for (JoinedPlayer : Players):
            ApplyToPlayer(JoinedPlayer)

        # AND AGAIN WHEN THE SHOW ACTUALLY STARTS. This is what fixes the aiming
        # that "kept breaking".
        #
        # THE WORKAROUND WAS BEING SPENT ON THE TITLE SCREEN. It runs half a
        # second after OnBegin, and the broadcast card is still up then, holding
        # the mouse with ui_input_mode.All because it has buttons. The contestant
        # does not take control until START SHOW, which in the 2026-08-26 log was
        # twelve seconds later. By then the repair had already happened, against
        # a mouse the title card owned, and facing was dead for the whole run.
        #
        # IT IS WHY THE FAULT CAME AND WENT. Press START SHOW quickly and the two
        # race close enough to work; take your time reading the card and it does
        # not. Aiming was reported broken three times on 2026-08-25 and 26 and
        # twice "fixed itself", which was this race landing the other way.
        #
        # RUN AT MATCH START, NOT INSTEAD OF THE FIRST ONE. The first pass still
        # matters for a contestant who joins before the card is up, and a second
        # remove-and-re-add costs a second of a screen nobody is aiming at.
        #
        # AND AT THE START OF EVERY RUN, not only the first. Amendment 86. PLAY
        # AGAIN hands the mouse back from the game over card exactly the way
        # START SHOW hands it back from the title card, so the same repair is
        # owed again, and without it aiming would be dead for the whole of run
        # two. AwaitRunEnd is what sends this round again.
        loop:
            AwaitMatchStart(Self)
            Log("DEBUG: Show started -- re-running the facing workaround now the card has let go of the mouse.")
            for (Contestant : Playspace.GetPlayers()):
                spawn{ ReapplyControls(Contestant) }
            AwaitRunEnd(Self)

    OnPlayerAdded(JoinedPlayer : player):void =
        Log("DEBUG: Player joined after the match started -- handing them the top-down camera and twin-stick controls")
        ApplyToPlayer(JoinedPlayer)

    # Pushes both onto one player. AddTo takes an agent, and a player is a kind
    # of agent, so a player can be passed straight in.
    ApplyToPlayer(TargetPlayer : player):void =
        TopDownCamera.AddTo(TargetPlayer)
        TwinStickControls.AddTo(TargetPlayer)

        # Launched with spawn so the waiting happens off to one side. Without
        # it, a player joining mid-match would be held up for a second before
        # anything else could run.
        spawn{ ReapplyControls(TargetPlayer) }

    # The FORT-1110974 workaround described in the header. Takes the controls
    # away and gives them back, once, shortly after the player first gets them.
    ReapplyControls(TargetPlayer : player)<suspends>:void =
        Sleep(DelayBeforeRemove)
        TwinStickControls.RemoveFrom(TargetPlayer)
        Log("DEBUG: Twin-stick controls removed for the facing workaround")

        Sleep(DelayBeforeReAdd)
        TwinStickControls.AddTo(TargetPlayer)
        Log("DEBUG: Twin-stick controls re-applied -- facing should be live now")
