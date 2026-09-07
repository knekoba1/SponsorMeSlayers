# TankEntrance.verse
#
# GDD Section 1.1 "the arena and its hostiles", and amendment 121.
#
# THE TANK GETS AN ENTRANCE, AND THIS IS WHY IT IS NOT SCALE.
#
# Kai asked on 2026-08-29 to make the Tank look like a giant. A Fortnite
# character cannot be scaled: the character modifier list has twelve entries and
# scale is not among them, scale exists only for creative_prop, and where a scale
# box does appear in UEFN it is Epic bug FORT-1143931, which looks bigger in the
# editor and comes out at 1.0 in the game. Outfits are all built to one height
# too, so no costume makes a giant either.
#
# So the Tank is made frightening rather than tall. Kai: "how can i make him
# scary." Two things arrive with him: a low sound the moment he walks in, and a
# red glow that follows him for as long as he lives, so he can be picked out of a
# crowd from across the arena and heard before he is seen.
#
# ITS OWN DEVICE RATHER THAN MORE OF WaveManager. This only listens; it never
# spawns, counts, or ends anything, and WaveManager is long enough. Both files
# subscribe to the same SpawnedEvent, and the digest gives no order between two
# subscribers, which does not matter here because nothing in this file reads or
# writes anything WaveManager touches.
#
# A POOL OF GLOWS, ONE PER LIVE TANK. A VFX creator can only be in one place, so
# a single device shared between two Tanks would be dragged between them and read
# as a smear. Each arrival takes a free one and gives it back when the Tank dies.
# Run out and the Tank simply arrives without a glow, which is the behaviour
# before this file rather than a fault.

using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Simulation }

tank_entrance := class(creative_device):

    # =================================================================
    # WIRING
    # =================================================================

    # The Tank's own spawner, which is slot 3 in WaveManager's fixed order. Wire
    # this to the same placed device WaveManager's TankSpawner points at.
    @editable
    TankSpawner : npc_spawner_device = npc_spawner_device{}

    # KAI HAS CUT THE ARRIVAL SOUND, 2026-08-30, and this field is only still
    # here so the cut can be finished. It held an Audio Player for a low rumble
    # as a Tank walked in; that box was deleted in the clear-out of the old
    # announcer boxes, leaving the device pointing at nothing, which UEFN
    # reports as a missing external actor and which blocks the build.
    #
    # DELETING THE FIELD DID NOT CLEAR THE REFERENCE. The dangling value is
    # saved on the PLACED device, not in this script, and taking the field away
    # took away the X button that clears it while leaving the value behind. So
    # the field comes back, Kai clears the slot in UEFN, and only then does it
    # go for good.
    #
    # NOTHING PLAYS IT ANY MORE. The call in OnTankArrived is already gone, so
    # an Audio Player left in here is ignored either way.
    @editable
    ArrivalSound : audio_player_device = audio_player_device{}

    # The glows that follow living Tanks about. See the header for why this is a
    # list. Three is enough: the Tank joins at room 4 and never arrives in
    # numbers, and a fourth Tank simply goes without.
    @editable
    TankGlows : []vfx_creator_device = array{}

    # THE SPOTLIGHT. One per Tank that can be alive at once, matched slot for
    # slot with TankGlows above: spotlight 0 rides with glow 0. Fill either list,
    # or both, or neither.
    #
    # Kai asked for a spotlight rather than a glow, and the difference is real: a
    # VFX creator paints an effect onto the Tank, while a light lights him AND
    # the floor around him, which is what picking someone out of a crowd looks
    # like.
    @editable
    TankSpotlights : []customizable_light_device = array{}

    # How far above the Tank the light hangs. A light inside a character lights
    # nothing, so it goes over his head and shines down. Zero puts it at his
    # feet instead.
    @editable
    SpotlightHeight : float = 400.0

    # WHICH WAY THE BEAM POINTS, in degrees, where positive is up. Kai's placed
    # lights are Spot type, checked in the map file on 2026-09-07, so they throw
    # a cone rather than glowing in all directions and the direction matters as
    # much as the position.
    #
    # IT USED TO BORROW THE TANK'S OWN ROTATION, which aimed the cone sideways
    # out of a light hanging four metres over his head, and swung it round the
    # arena every time he turned. Kai, 2026-09-07: "i saw the tank light but the
    # light was supposed to follow him". A beam sweeping the far wall is exactly
    # what that looks like from the floor.
    #
    # -90 is straight down. If it comes out pointing at the ceiling, this is the
    # one number to flip, and it can be flipped in UEFN without a rebuild.
    @editable
    SpotlightPitchDegrees : float = -90.0

    # =================================================================
    # DIALS
    # =================================================================

    # The whole thing off, without unwiring anything.
    @editable
    ShowTankEntrance : logic = true

    # How many times a Tank's spotlight prints where it actually ended up. See
    # the trace in HauntUntilDead. Zero switches the trace off.
    @editable
    TraceLines : int = 5

    # How often a glow is moved onto the Tank it belongs to. A tenth of a second
    # is under the eye's ability to see a step, and GDD 5.5 wants a locked 60 FPS
    # with three of these running at most.
    @editable
    FollowSeconds : float = 0.1

    # =================================================================
    # STATE
    # =================================================================

    # Which glows are in use. One entry per device in TankGlows, in the same
    # order, filled at OnBegin so the two lists can never drift apart.
    var GlowBusy : [int]logic = map{}

    OnBegin<override>()<suspends>:void =
        # THE POOL COVERS WHICHEVER LIST IS LONGER, so filling only the
        # spotlights and leaving the glows empty still gives every Tank one.
        for (Index := 0..PoolSize() - 1):
            if (set GlowBusy[Index] = false):
                Log("DEBUG: Tank spotlight slot {Index} is free and waiting.")

        # DARK UNTIL A TANK WALKS IN. The device has no "start off" setting of
        # its own, only Enabled During Phase, so a spotlight would otherwise sit
        # lit wherever it was parked from the moment the match began. Switched
        # off here so the only time one is on is when it is riding a Tank.
        for (Lamp : TankSpotlights):
            Lamp.Enable()
            Lamp.TurnOff()

        TankSpawner.SpawnedEvent.Subscribe(OnTankArrived)
        Log("DEBUG: Tank entrance watching -- {TankGlows.Length} glow(s) for the big ones.")

    # =================================================================
    # THE ENTRANCE
    # =================================================================

    OnTankArrived(Arrival : agent):void =
        if (not ShowTankEntrance?):
            return

        # A GLOW IS NO LONGER REQUIRED. Kai wants the spotlight and not the
        # glow, so TankGlows is expected to be empty and this used to fail on
        # that lookup and give the Tank nothing at all. The slot is claimed
        # first and whichever lists have something in it are used inside.
        if (Body := Arrival.GetFortCharacter[], Index := FreeGlow[]):
            if (set GlowBusy[Index] = true):
                spawn{ HauntUntilDead(Index, Body) }
        else:
            Log("DEBUG: Tank arrived with nothing free to mark it, so it comes in plain.")

    # The first glow not already following something. Fails when every one is
    # taken, which is what sends the Tank in without one.
    PoolSize()<transacts>:int =
        var Biggest : int = TankGlows.Length
        if (TankSpotlights.Length > Biggest):
            set Biggest = TankSpotlights.Length
        Biggest

    FreeGlow()<transacts><decides>:int =
        var Found : int = -1
        for (Index := 0..PoolSize() - 1, Found < 0):
            if (Busy := GlowBusy[Index], not Busy?):
                set Found = Index
        Found >= 0
        Found

    # Holds the glow on the Tank until the Tank is gone, then puts it away and
    # hands it back to the pool.
    #
    # THE CHECK IS IsActive, the same test WaveManager.CountLiveHostiles uses.
    # A despawned or eliminated character stops being active, so this ends
    # whether the Tank was killed, cleared away at the end of a run, or removed
    # by the spawner between waves.
    HauntUntilDead(Index : int, Body : fort_character)<suspends>:void =
        var Lit : logic = false

        # So a refused teleport is reported once rather than ten times a second
        # for as long as the Tank is alive.
        var Warned : logic = false

        # THE TRACE. Counts loop passes so the light's own reported position can
        # be printed about once a second, and stops after TraceLines of them so
        # a long-lived Tank cannot drown the log. This is here to settle one
        # question and one only: whether a light that is told to move actually
        # moves. Set TraceLines to 0 once that is known.
        var Ticks : int = 0
        var Traces : int = 0

        loop:
            if (Body.IsActive[]):
                Standing := Body.GetTransform()
                set Ticks = Ticks + 1

                # The glow, if there is one. Kai's build has none.
                if (Glow := TankGlows[Index]):
                    if (Glow.TeleportTo[Standing.Translation, Standing.Rotation]):
                        if (not Lit?):
                            Glow.Begin()

                # AND THE SPOTLIGHT, RIDING ALONG WITH IT. KAI'S RULING,
                # 2026-09-06: "i dont want a glow for the tank i want the
                # spotlight."
                #
                # A vfx_creator_device paints an effect ON the Tank. A light
                # LIGHTS him, and lights the floor around him, which is what a
                # spotlight picking someone out of a crowd actually looks like.
                # It is moved to the same place on the same tick, so the two
                # cannot drift apart, and either list can be left empty.
                #
                # HUNG ABOVE HIM, NOT ON HIM. A light inside a character lights
                # nothing; SpotlightHeight puts it over his head so it shines
                # down. Set it to 0 if a light at floor level suits better.
                if (Lamp := TankSpotlights[Index]):
                    Overhead := vector3:
                        X := Standing.Translation.X
                        Y := Standing.Translation.Y
                        Z := Standing.Translation.Z + SpotlightHeight

                    # AND IT SAYS WHETHER IT ACTUALLY GOT THERE. Added
                    # 2026-09-07, after Kai reported no tank light for a second
                    # time on a run where a Tank certainly arrived and this
                    # whole loop certainly ran, and the log had nothing to say
                    # about it either way. TeleportTo is failable and a device
                    # refused a destination logs nothing of its own, so a light
                    # that never moved and a light that moved and was too dim to
                    # see looked identical from here.
                    # STRAIGHT DOWN, NOT WHEREVER THE TANK IS FACING. See
                    # SpotlightPitchDegrees.
                    Aim := MakeRotationFromYawPitchRollDegrees(0.0, SpotlightPitchDegrees, 0.0)

                    if (Lamp.TeleportTo[Overhead, Aim]):
                        if (not Lit?):
                            Lamp.Enable()
                            Lamp.TurnOn()
                            Log("DEBUG: Tank spotlight {Index} switched on above the Tank at X={Overhead.X} Y={Overhead.Y} Z={Overhead.Z}.")

                        if (Ticks >= 10, Traces < TraceLines):
                            set Ticks = 0
                            set Traces = Traces + 1
                            Where := Lamp.GetTransform().Translation
                            Log("DEBUG: Tank spotlight {Index} was sent to X={Overhead.X} Y={Overhead.Y} and reports it is at X={Where.X} Y={Where.Y}. The two matching means the light moved.")
                    else if (not Warned?):
                        set Warned = true
                        Log("WARNING: Tank spotlight {Index} could not be moved to X={Overhead.X} Y={Overhead.Y} Z={Overhead.Z}, so it stays wherever it was parked and never lights the Tank.")

                set Lit = true
            else:
                break

            Sleep(FollowSeconds)

        if (Glow := TankGlows[Index]):
            Glow.End()

        if (Lamp := TankSpotlights[Index]):
            Lamp.TurnOff()

        if (set GlowBusy[Index] = false):
            Log("DEBUG: a Tank is down, its glow is back in the pool.")
