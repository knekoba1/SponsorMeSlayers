# CrowdNoise.verse
#
# GDD Section 1.1's stadium and GDD 5.4's audio, and amendment 123.
#
# THE ARENA HAD NO CROWD IN IT. Kai, 2026-08-29: "should we be able to hear the
# audience cheering?" The game is built around a simulated televised audience
# that fills a Hype meter, chants for crates and types in a chat box, and until
# now it never made a single sound. A stadium that is silent reads as an empty
# room with a scoreboard.
#
# A BED PER TIER, BECAUSE VOLUME CANNOT BE CHANGED FROM VERSE. The obvious build
# is one loop whose volume rides the Hype bar, and the digest does not allow it:
# an audio_player_device offers Play, Stop, Enable, Disable, Register and
# Unregister, and nothing that touches volume. So the swell is built out of
# separate loops instead, one per Hype tier, each recorded at its own intensity,
# and the tier change swaps which one is running.
#
# THE TIERS ARE ALREADY THERE, so this borrows them rather than inventing a
# second set of thresholds. It reads the same three getters SimulatedAudience
# reads, which is what keeps the crowd you HEAR and the crate quality you SEE
# agreeing with each other. Amendment 13's bands, quietest first:
#
#   0  Underdog     a room half paying attention
#   1  Rising Star  interested
#   2  Superstar    loud
#   3  Prime Time   a wall of noise
#
# IT IS A HARD SWAP, NOT A CROSSFADE, and that is the cost of the workaround
# above. It lands better than it sounds on paper: amendment 117 stopped the tier
# flipping back and forth on a wobble, so a swap is now a real change of gear
# rather than a stutter.
#
# LEAVE THE LIST EMPTY AND NOTHING HAPPENS, which is the silence this file was
# written to end, so a half-finished set of recordings is still safe to ship.

using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Simulation }

crowd_noise := class(creative_device):

    # =================================================================
    # WIRING
    # =================================================================

    # The meter, for the Hype itself and for the three tier lines. Reading both
    # off the same device is what stops this file and the audience disagreeing
    # about which tier the contestant is in.
    @editable
    HypeMeter : hype_meter_manager = hype_meter_manager{}

    # One looping Audio Player per tier, QUIETEST FIRST: Underdog, Rising Star,
    # Superstar, Prime Time. Each one wants Loop ticked and Enabled On Game Start
    # unticked, because this file decides when each is heard.
    #
    # Fewer than four is fine. The list is read by index, so three beds cover
    # tiers 0 to 2 and Prime Time simply keeps the loudest one already playing.
    @editable
    CrowdBeds : []audio_player_device = array{}

    # =================================================================
    # DIALS
    # =================================================================

    # THE BROADCAST SCREEN, WATCHED FOR ONE THING ONLY: whether the PLEASE STAND
    # BY tone is sounding. Kai, 2026-08-30: "the music and murumur is playing
    # during the please standby part and its not suppsoed to im onl suppsoed to
    # hear the tone i set up wtih it."
    #
    # LEFT UNWIRED THE ROOM SIMPLY NEVER GOES QUIET, which is exactly how it
    # behaved before this was added, so a half-wired map still plays correctly.
    @editable
    Broadcast : broadcast_screen = broadcast_screen{}

    # GDD 5.4's one synth-wave track. It needs no code to play, and needs this
    # much to shut up: an Audio Player cannot be paused, only stopped, so the
    # song RESTARTS when the card clears rather than picking up where it was.
    # That is the cost of the card being silent and it is barely audible on a
    # looping instrumental.
    @editable
    Song : audio_player_device = audio_player_device{}

    # The crowd off, without unwiring anything.
    @editable
    CrowdOn : logic = true

    # How often the tier is checked. Half a second: a crowd changing gear is
    # allowed to take a moment, and this costs nothing.
    @editable
    PollSeconds : float = 0.5

    # How often the stand-by card is checked. Much faster than the tier poll,
    # because a crowd that keeps roaring for half a second over a test card is
    # the whole bug, where a crowd that takes half a second to change gear is
    # not a bug at all.
    @editable
    CardPollSeconds : float = 0.1

    # =================================================================
    # STATE
    # =================================================================

    # Which bed is playing, or -1 for none. NOT the tier: they are the same
    # number today, and will stop being if the list is ever shorter than four.
    var Playing : int = -1

    # True while the stand-by card has the room silenced, and the bed that was
    # running when it did. Remembered because HushAll forgets, and coming back
    # from a test card into the wrong tier of crowd would be its own bug.
    var Hushed : logic = false
    var BedBeforeHush : int = 0

    OnBegin<override>()<suspends>:void =
        Log("DEBUG: Crowd noise ready -- {CrowdBeds.Length} bed(s).")

        # THE MURMUR STARTS BEFORE THE SHOW DOES AND NEVER STOPS. Kai's ruling
        # 2026-08-29, asked whether the crowd should carry on between runs:
        # "yeah the murmur and the song should play". A stadium does not empty
        # out because the contestant died, and the title card and the game over
        # card both read better with a room behind them.
        if (CrowdOn?):
            SwapTo(0)

        # THE CARD WATCH RUNS FOR THE WHOLE ISLAND, not just for a run, because
        # PLEASE STAND BY is on screen before the match has started and the
        # loop below does not begin until it has.
        spawn{ WatchTheCard() }

        # THE OUTER LOOP IS THE RESTART, amendment 86, and the same shape every
        # other watcher in this project uses. What changes at the end of a run is
        # only which bed is playing: it drops back to the murmur rather than to
        # silence.
        loop:
            AwaitMatchStart(Self)

            race:
                RideTheHype()
                AwaitRunEnd(Self)

            if (CrowdOn?):
                SwapTo(0)
            Log("DEBUG: Crowd noise -- the run is over, the room settles back to a murmur.")

    # =================================================================
    # THE TEST CARD
    # =================================================================

    # Silences the room while PLEASE STAND BY is sounding and puts it back the
    # moment the card clears. Kai's ruling 2026-08-30: the tone plays alone.
    WatchTheCard()<suspends>:void =
        loop:
            Quiet := Broadcast.IsStandingBy()

            if (Quiet?):
                if (not Hushed?):
                    set Hushed = true
                    set BedBeforeHush = Playing
                    HushAll()
                    Song.Stop()
                    Log("DEBUG: Crowd noise -- PLEASE STAND BY, the room goes quiet.")
            else:
                if (Hushed?):
                    set Hushed = false
                    Song.Play()
                    if (CrowdOn?, BedBeforeHush >= 0):
                        SwapTo(BedBeforeHush)
                    Log("DEBUG: Crowd noise -- the card is gone, the room comes back.")

            Sleep(CardPollSeconds)

    # =================================================================
    # THE SWELL
    # =================================================================

    RideTheHype()<suspends>:void =
        loop:
            # NOT WHILE THE CARD IS UP. Without this the tier poll would notice
            # the wrong bed is playing, and start one over the test card.
            if (CrowdOn?, not Hushed?):
                Wanted := BedForHype(HypeMeter.GetHype())
                if (Wanted <> Playing):
                    SwapTo(Wanted)
            Sleep(PollSeconds)

    # Which bed the Hype right now asks for, clamped to what has been wired. The
    # tier bands are amendment 13's, asked of the meter that owns them.
    BedForHype(Hype : float)<transacts>:int =
        var Tier : int = 0
        if (Hype >= HypeMeter.GetRisingStarAt()):
            set Tier = 1
        if (Hype >= HypeMeter.GetSuperstarAt()):
            set Tier = 2
        if (Hype >= HypeMeter.GetPrimeTimeAt()):
            set Tier = 3

        # A shorter list than four is allowed, so the top tiers share the last
        # bed rather than falling silent.
        Last := CrowdBeds.Length - 1
        if (Tier > Last):
            set Tier = Last
        Tier

    # Stops whatever is running and starts the one asked for. Stop first, because
    # two beds playing at once is two crowds.
    SwapTo(Wanted : int):void =
        HushAll()

        if (Wanted >= 0, Bed := CrowdBeds[Wanted]):
            Bed.Play()
            set Playing = Wanted
            Log("DEBUG: Crowd noise -- the stadium moves up to bed {Wanted}.")

    # Every bed silenced. Called on a swap and again when the run ends, so a
    # crowd is never left roaring over the game over card.
    HushAll():void =
        for (Bed : CrowdBeds):
            Bed.Stop()
        set Playing = -1
