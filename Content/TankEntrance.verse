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

    # Played once as a Tank walks in. A low rumble or horn, not a sting: this is
    # the sound of something heavy arriving, and it plays over the top of the
    # wave rather than interrupting it.
    @editable
    ArrivalSound : audio_player_device = audio_player_device{}

    # The glows that follow living Tanks about. See the header for why this is a
    # list. Three is enough: the Tank joins at room 4 and never arrives in
    # numbers, and a fourth Tank simply goes without.
    @editable
    TankGlows : []vfx_creator_device = array{}

    # =================================================================
    # DIALS
    # =================================================================

    # The whole thing off, without unwiring anything.
    @editable
    ShowTankEntrance : logic = true

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
        for (Index := 0..TankGlows.Length - 1):
            if (set GlowBusy[Index] = false):
                Log("DEBUG: Tank glow {Index} is free and waiting.")

        TankSpawner.SpawnedEvent.Subscribe(OnTankArrived)
        Log("DEBUG: Tank entrance watching -- {TankGlows.Length} glow(s) for the big ones.")

    # =================================================================
    # THE ENTRANCE
    # =================================================================

    OnTankArrived(Arrival : agent):void =
        if (not ShowTankEntrance?):
            return

        ArrivalSound.Play()

        if (Body := Arrival.GetFortCharacter[], Index := FreeGlow[], Glow := TankGlows[Index]):
            if (set GlowBusy[Index] = true):
                spawn{ HauntUntilDead(Glow, Index, Body) }
        else:
            Log("DEBUG: Tank arrived with no glow free, so it comes in plain.")

    # The first glow not already following something. Fails when every one is
    # taken, which is what sends the Tank in without one.
    FreeGlow()<transacts><decides>:int =
        var Found : int = -1
        for (Index := 0..TankGlows.Length - 1, Found < 0):
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
    HauntUntilDead(Glow : vfx_creator_device, Index : int, Body : fort_character)<suspends>:void =
        var Lit : logic = false

        loop:
            if (Body.IsActive[]):
                Standing := Body.GetTransform()
                if (Glow.TeleportTo[Standing.Translation, Standing.Rotation]):
                    if (not Lit?):
                        Glow.Begin()
                        set Lit = true
            else:
                break

            Sleep(FollowSeconds)

        if (Lit?):
            Glow.End()

        if (set GlowBusy[Index] = false):
            Log("DEBUG: a Tank is down, its glow is back in the pool.")
