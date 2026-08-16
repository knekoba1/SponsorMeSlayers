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
# If the aiming feels wrong, the two devices in the map are where to look. This
# script cannot cause it.
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

    # The locked top-down camera of GDD 1.1. Place a Fixed Angle Camera in the
    # map, above the arena, and point this at it.
    @editable
    TopDownCamera : gameplay_camera_fixed_angle_device = gameplay_camera_fixed_angle_device{}

    # The twin-stick control scheme of GDD 2.2. Place a Third Person Controls
    # device in the map and point this at it. Its Facing Direction setting is
    # what decides whether aiming is independent of movement; see the header.
    @editable
    TwinStickControls : gameplay_controls_third_person_device = gameplay_controls_third_person_device{}

    OnBegin<override>()<suspends>:void =
        Playspace := GetPlayspace()

        # Subscribed BEFORE the existing players are handled, so anyone who
        # arrives while that loop is running is still caught.
        Playspace.PlayerAddedEvent().Subscribe(OnPlayerAdded)

        Players := Playspace.GetPlayers()
        Print("DEBUG: Twin-stick controller starting -- {Players.Length} player(s) already here")
        for (JoinedPlayer : Players):
            ApplyToPlayer(JoinedPlayer)

    OnPlayerAdded(JoinedPlayer : player):void =
        Print("DEBUG: Player joined after the match started -- handing them the top-down camera and twin-stick controls")
        ApplyToPlayer(JoinedPlayer)

    # Pushes both onto one player. AddTo takes an agent, and a player is a kind
    # of agent, so a player can be passed straight in.
    ApplyToPlayer(TargetPlayer : player):void =
        TopDownCamera.AddTo(TargetPlayer)
        TwinStickControls.AddTo(TargetPlayer)
