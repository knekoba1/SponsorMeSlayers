# AnnouncerManager.verse
#
# GDD Section 4's Announcer Bark, and GDD 5.2's latency guardrail. This is the
# playback half of the commentator. The lines are Kai's, they live in
# pipelines/announcer-bark/barks.py, and nothing in this file writes, chooses
# or edits a word of them. CLAUDE.md standing rule 3.
#
# WHAT THIS FILE DOES AND DOES NOT DO. It decides WHEN the host speaks and WHICH
# MOMENT he is speaking about. It does not decide which of that moment's lines
# is used: the sound device does, see below. And it never touches the text.
#
# TEN DEVICES, NOT FORTY-ONE, and this is the whole reason the plumbing is
# small. An Audio Player device plays one sound and Verse cannot swap it: the
# digest gives it Play, Stop, Enable, Disable, Register and nothing else. So
# forty-one lines would have meant forty-one devices and forty-one fields to
# wire by hand.
#
# UEFN'S "PLAY RANDOM ONESHOT" METASOUND PRESET IS THE WAY OUT. It holds a set
# of sounds and picks one at random each time it is played. So there is ONE
# device per moment holding that moment's lines, ten in all, and the variety
# comes free. Amendment 91.
#
# HOW TO FILL IT IN, once the clips exist:
#   1. Import the .wav files into UEFN.
#   2. Right-click the MSS Play Random Oneshot MetaSound Source and make a
#      preset per moment, then put that moment's clips in it.
#   3. Place ten Audio Player devices, point each at one preset, and wire them
#      to the ten fields below.
# A field left unwired plays nothing and the host simply stays quiet for that
# moment, which is deliberate: a half-recorded database has to be safe to ship.
#
# NOTHING CALLS THIS FILE. It WATCHES instead, polling the public getters the
# other managers already expose, exactly the way SimulatedAudience polls the
# Hype meter. That was chosen over calling Say() from eight other scripts: eight
# edits to shipped files is eight chances to break something a week from the
# ship date, and GDD 4.1 wants these systems loosely coupled anyway.
#
# THE ADS ARE FILLER AND THAT IS KAI'S RULING. Amendment 90: the eight Sponsor
# Reads are "there to sprinkle in when the announcer runs out of things to say
# or has said something repeatedly". So they are not a moment. They are what
# comes out during a quiet stretch, alternating with the dead air lines.

using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Random }
using { /Verse.org/Simulation }

announcer_manager := class(creative_device):

    # =================================================================
    # THE TEN VOICES. One device per moment, each holding that moment's lines.
    # The names match the trigger names in pipelines/announcer-bark/settings.py
    # and the section headings in Kai's own document.
    # =================================================================

    @editable
    ShowIntroVoice : audio_player_device = audio_player_device{}

    @editable
    RoundStartVoice : audio_player_device = audio_player_device{}

    @editable
    KillStreakVoice : audio_player_device = audio_player_device{}

    @editable
    CashPickupVoice : audio_player_device = audio_player_device{}

    @editable
    CrateDropVoice : audio_player_device = audio_player_device{}

    @editable
    LowHealthVoice : audio_player_device = audio_player_device{}

    @editable
    RoundClearVoice : audio_player_device = audio_player_device{}

    @editable
    SignOffVoice : audio_player_device = audio_player_device{}

    @editable
    DeadAirVoice : audio_player_device = audio_player_device{}

    @editable
    SponsorReadVoice : audio_player_device = audio_player_device{}

    # =================================================================
    # WHAT IT WATCHES
    # =================================================================

    @editable
    Waves : wave_manager = wave_manager{}

    @editable
    CashDrops : cash_drop_manager = cash_drop_manager{}

    @editable
    Crates : crate_manager = crate_manager{}

    # =================================================================
    # PACING
    # =================================================================

    # How often the watch looks. Fast enough that a line lands on the beat it is
    # about, slow enough to cost nothing.
    @editable
    PollSeconds : float = 0.25

    # THE SHORTEST GAP BETWEEN ANY TWO LINES, and it is the single most
    # important dial in this file. The host talking over himself is worse than
    # the host saying nothing, and GDD 5.2 is entirely about his comedic timing.
    # Kai's longest line is 19 words, which is roughly six seconds spoken.
    @editable
    GapBetweenLines : float = 7.0

    # How long the arena has to be uneventful before he fills the silence.
    @editable
    QuietBeforeFiller : float = 18.0

    # How many kills close together count as a streak worth remarking on. The
    # Hype meter has its own cluster rule; this is deliberately separate, so
    # tuning one never silently retunes the other.
    @editable
    KillsForStreak : int = 3

    # How long a streak's kills may be spread over, in seconds.
    @editable
    StreakWindowSeconds : float = 4.0

    # Below this share of maximum health he starts enjoying himself. GDD 3.1
    # puts the Underdog Boost at 40%, and using the same line keeps the two
    # halves of "you are in trouble" agreeing with each other.
    @editable
    LowHealthFraction : float = 0.4

    # Cash is constant, so only some pickups are worth a line. One in this many.
    @editable
    OneCashLineIn : int = 8

    # =================================================================
    # STATE
    # =================================================================

    var SecondsElapsed : float = 0.0
    var LastLineAt : float = -100.0
    var LastAnythingAt : float = 0.0

    # The readings at the last look, so a change can be told from a value.
    var LastTier : int = 1
    var LastRooms : int = 0
    var LastKills : int = 0
    var LastScore : int = 0
    var LastCrates : int = 0

    # Kills inside the streak window, and how long is left of it.
    var StreakKills : int = 0
    var StreakLeft : float = 0.0

    # Said once until health climbs back, so being on low health is one remark
    # rather than one every quarter second.
    var CalledLowHealth : logic = false

    # Which filler comes next. Kai's ruling puts the ads in the gaps, so they
    # take turns with the dead air lines rather than replacing them.
    var AdIsNext : logic = false

    # =================================================================
    # GOING ON AIR
    # =================================================================

    OnBegin<override>()<suspends>:void =
        Log("DEBUG: Announcer ready. Nothing is said until the show starts.")

        # THE OUTER LOOP IS THE RESTART, amendment 86. The watch is raced
        # against AwaitRunEnd rather than spawned, because a spawn cannot be
        # cancelled and PLAY AGAIN would leave two hosts talking at once.
        loop:
            AwaitMatchStart(Self)
            StartFreshRun()

            # The show intro, before the watch starts, so it is never beaten to
            # the microphone by a cash pickup in the first second.
            Say("ShowIntro", ShowIntroVoice)

            race:
                RunWatch()
                AwaitRunEnd(Self)

            # THE SIGN-OFF IS THE LAST THING HE SAYS, and it plays whichever
            # button ended the run. The game over card is already up by now.
            Say("SignOff", SignOffVoice)
            Log("DEBUG: Announcer off air until the next run.")

    # Everything he remembers about a run, cleared. Called at the top of every
    # run including the first, so one path serves both.
    StartFreshRun():void =
        set LastLineAt = -100.0
        set LastAnythingAt = SecondsElapsed
        set LastTier = Waves.GetCurrentTier()
        set LastRooms = Waves.GetRoomsWon()
        set LastKills = Waves.GetRunEliminations()
        set LastScore = CashDrops.GetRunScore()
        set LastCrates = Crates.GetCratesLanded()
        set StreakKills = 0
        set StreakLeft = 0.0
        set CalledLowHealth = false
        Log("DEBUG: Announcer -- fresh run, nothing said yet.")

    # =================================================================
    # THE MICROPHONE
    #
    # One way in, so the gap between lines can never be worked around.
    # =================================================================

    # True if he is free to speak.
    CanSpeak()<transacts>:logic =
        SecondsElapsed - LastLineAt >= GapBetweenLines

    # Plays one moment. WHICH line of that moment is heard is the sound device's
    # decision, not this file's: see the header on Play Random Oneshot.
    Say(Moment : string, Voice : audio_player_device):void =
        set LastLineAt = SecondsElapsed
        set LastAnythingAt = SecondsElapsed
        Voice.Play()
        Log("DEBUG: Announcer says a {Moment} line.")

    # =================================================================
    # THE WATCH
    #
    # ONE LINE PER LOOK, HIGHEST PRIORITY FIRST. Several things can be true at
    # once, and a host who says all of them is a host talking over himself. The
    # order below IS the priority, and it is deliberate: losing your health
    # matters more than a room being cleared, which matters more than cash.
    # =================================================================

    RunWatch()<suspends>:void =
        loop:
            Sleep(PollSeconds)
            set SecondsElapsed = SecondsElapsed + PollSeconds

            if (StreakLeft > 0.0):
                set StreakLeft = StreakLeft - PollSeconds
                if (StreakLeft <= 0.0):
                    set StreakKills = 0

            ReadTheArena()

            if (CanSpeak()?):
                CallIt()

    # Takes every reading and updates what is remembered. Kept apart from
    # deciding what to say, so a moment is never missed just because the host
    # happened to be mid-sentence.
    ReadTheArena():void =
        Kills := Waves.GetRunEliminations()
        if (Kills > LastKills):
            set StreakKills = StreakKills + (Kills - LastKills)
            set StreakLeft = StreakWindowSeconds
            set LastAnythingAt = SecondsElapsed
        set LastKills = Kills

        Score := CashDrops.GetRunScore()
        if (Score > LastScore):
            set LastAnythingAt = SecondsElapsed

        Landed := Crates.GetCratesLanded()
        if (Landed > LastCrates):
            set LastAnythingAt = SecondsElapsed

        Rooms := Waves.GetRoomsWon()
        if (Rooms > LastRooms):
            set LastAnythingAt = SecondsElapsed

    # Picks the one thing worth saying right now, says it, and stops.
    #
    # NO `return` INSIDE A `for`, and no early return needed here either: every
    # branch is an else, so exactly one can fire.
    CallIt():void =
        Rooms := Waves.GetRoomsWon()
        Tier := Waves.GetCurrentTier()
        Score := CashDrops.GetRunScore()
        Landed := Crates.GetCratesLanded()

        if (LowOnHealth()?, not CalledLowHealth?):
            set CalledLowHealth = true
            Say("LowHealth", LowHealthVoice)

        else if (Rooms > LastRooms):
            set LastRooms = Rooms
            Say("RoundClear", RoundClearVoice)

        else if (Tier > LastTier):
            set LastTier = Tier
            Say("RoundStart", RoundStartVoice)

        else if (Landed > LastCrates):
            set LastCrates = Landed
            Say("CrateDrop", CrateDropVoice)

        else if (StreakKills >= KillsForStreak):
            set StreakKills = 0
            set StreakLeft = 0.0
            Say("KillStreak", KillStreakVoice)

        else if (Score > LastScore):
            # ONE IN EIGHT, because cash is constant and a line every pickup
            # would be the only thing anybody heard all match.
            set LastScore = Score
            if (GetRandomInt(1, OneCashLineIn) = 1):
                Say("CashPickup", CashPickupVoice)

        else if (SecondsElapsed - LastAnythingAt >= QuietBeforeFiller):
            FillTheSilence()

        # Health climbing back re-arms the low health remark for next time. Done
        # last so it can never eat this look's line.
        if (not LowOnHealth()?):
            set CalledLowHealth = false

    # Kai's ruling, amendment 90: the ads go in the gaps, taking turns with the
    # dead air lines rather than replacing them.
    FillTheSilence():void =
        set LastAnythingAt = SecondsElapsed
        if (AdIsNext?):
            set AdIsNext = false
            Say("SponsorRead", SponsorReadVoice)
        else:
            set AdIsNext = true
            Say("DeadAir", DeadAirVoice)

    # Single contestant by design; amendment 19 records the game as
    # single-player, so the first player is the one being laughed at.
    LowOnHealth()<transacts>:logic =
        var Low : logic = false
        if:
            P := GetPlayspace().GetPlayers()[0]
            Character := P.GetFortCharacter[]
            Character.IsActive[]
            Most := Character.GetMaxHealth()
            Most > 0.0
            Share := Character.GetHealth() / Most
            Share <= LowHealthFraction
        then:
            set Low = true
        Low
