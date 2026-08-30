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
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }
using { /Verse.org/Colors }
using { /Verse.org/Random }
using { /Verse.org/Simulation }

announcer_manager := class(creative_device):

    # =================================================================
    # THE TEN VOICES. One device per moment, each holding that moment's lines.
    # The names match the trigger names in pipelines/announcer-bark/settings.py
    # and the section headings in Kai's own document.
    # =================================================================

    # =================================================================
    # THE BANNER, AND WHY THE HOST IS ON SCREEN AT ALL
    #
    # Kai, 2026-08-29: "where is the announcers voice!!! the announcer is
    # supposed to be saying things are happening like the crate falling the tank
    # coming all that stuff."
    #
    # HE WAS SILENT FOR TWO REASONS AND NEITHER WAS THIS FILE. His two devices
    # had never been placed in the map at all, and even placed, every one of the
    # ten voice fields needs a recorded clip that does not exist yet. Kai's 41
    # lines are written; nobody has said them out loud.
    #
    # SO HE SPEAKS IN TEXT UNTIL HE SPEAKS ALOUD. Kai's ruling the same day: his
    # own banner across the bottom of the screen, not a line in the stream chat,
    # "because next to it i want to have the announcers face". The face does not
    # exist yet either, so its square is drawn and held empty, waiting for the
    # picture rather than being added once there is one.
    #
    # THE TEXT COMES FROM THE DATABASE, NEVER FROM HERE. GetBark picks one of
    # that moment's lines at random and this file prints whatever it is handed.
    # CLAUDE.md standing rule 3: no agent writes, rewrites or improves a word.
    @editable
    Barks : bark_database = bark_database{}

    # The crowd, for the moment they chant for a crate. Amendment 122.
    @editable
    Audience : simulated_audience = simulated_audience{}

    # The prize vault, for the moment a prize is won off a crate.
    @editable
    Vault : prize_vault_manager = prize_vault_manager{}

    # THE FIVE MOMENTS ADDED ON 2026-08-29. Kai: "i dont see much for the
    # announcer to say stuff when the audience orders a crate or props though."
    # Two are wired below; the three arrivals are slots waiting for their
    # trigger, the same way DeadAir and SponsorRead waited for theirs.
    @editable
    CrateCalledVoice : audio_player_device = audio_player_device{}

    @editable
    PrizeLandedVoice : audio_player_device = audio_player_device{}

    @editable
    FirstTankVoice : audio_player_device = audio_player_device{}

    @editable
    FirstBoarVoice : audio_player_device = audio_player_device{}

    @editable
    FirstSniperVoice : audio_player_device = audio_player_device{}

    # The banner off, without unwiring anything.
    @editable
    ShowBanner : logic = true

    # How long one line stays on screen. It sits just under GapMinSeconds so the
    # banner is always clear before the next line can arrive.
    #
    # RAISED 6 -> 12 ON 2026-08-30. Kai, reading along with the host: "the
    # annocuer is saying things too fast liek teh captions are too fast i dont
    # think anyone talks that fast". 6 was set when nothing was recorded and the
    # banner WAS the announcer, so it only had to be readable. Now it runs
    # alongside a real clip and has to last as long as he is talking.
    @editable
    BannerSeconds : float = 12.0

    @editable
    BannerTextSize : float = 28.0

    # The empty square the announcer's face will go in, in pixels.
    @editable
    FaceSize : float = 96.0

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

    # THE GAP BETWEEN ANY TWO LINES, and it is the single most important dial in
    # this file. The host talking over himself is worse than the host saying
    # nothing, and GDD 5.2 is entirely about his comedic timing.
    #
    # IT IS A RANGE, NOT A NUMBER, AND THAT IS KAI'S RULING OF 2026-08-30: "the
    # brething room should varry though? as logn as he never ovelaps himself".
    # A fresh wait is drawn after every line, the same way amendment 122 draws
    # the crate trickle, because a fixed gap makes a host sound scheduled.
    #
    # THE MINIMUM IS A CLIP LENGTH, NOT A TASTE. It used to be 7, set when Kai's
    # longest line was 19 words. Verse cannot ask an audio device how long its
    # clip runs, so this floor has to clear the longest recording BY HAND, and
    # it is the one number in this file that a new clip can silently invalidate.
    #
    # 18, AND THE WORD COUNT IS NOT WHAT SETS IT. Kai, 2026-08-30: "the annocner
    # takes pases so keep that in mind like pauses in their script and line".
    # The ElevenLabs credit line is 27 words, which is around eleven seconds
    # said flat, but it is not said flat: it carries a deadpan collapse and a
    # written pause, and the delivery is the point. 18 covers the words plus the
    # silence inside them. Measure the longest .wav and lower this if it is
    # shorter; raise it the moment a longer line is recorded.
    @editable
    GapMinSeconds : float = 18.0

    # The other end. 30 means some silences read as the host having genuinely
    # lost interest, which suits him.
    @editable
    GapMaxSeconds : float = 30.0

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

    # The gap this particular silence is waiting out, redrawn after every line.
    # It starts at the minimum so the show's opening line is never held back.
    var GapNow : float = 18.0

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
    # THE BANNER'S OWN BITS
    # =================================================================

    HostBlack : color = MakeColorFromHex("0F1216")
    HostWhite : color = MakeColorFromHex("FFFFFF")

    # The line of text on the banner, kept so it can be rewritten. False until
    # the banner has been drawn for somebody.
    var Line : ?text_block = false

    # Counts up on every line said. The clear-down waits its turn and then only
    # clears if its own number is still the latest, so a second line arriving
    # inside BannerSeconds is not wiped by the first one's timer.
    var BannerToken : int = 0

    # How many prizes the contestant had at the last look, so a new one can be
    # spotted. Read off the vault rather than told to us, which is the same way
    # every other moment in this file is noticed.
    var LastPrizes : int = 0

    # Draws the banner once, empty, and leaves it on screen. Drawing it per line
    # would mean adding and removing a widget several times a minute, and the
    # empty version shows nothing at all: a transparent strip and a dark square.
    BuildBanner(P : player):void =
        if (not ShowBanner?):
            return

        Words := text_block:
            DefaultText := ScreenLine("")
            DefaultTextColor := HostWhite
            DefaultTextSize := BannerTextSize
            DefaultJustification := text_justification.Left

        set Line = option{Words}

        # THE FACE'S SQUARE, EMPTY ON PURPOSE. Kai has not drawn the announcer
        # yet, so the space is held rather than added later: a banner that
        # changes shape the day the picture arrives is a second layout job.
        Face := color_block:
            DefaultColor := HostBlack
            DefaultOpacity := 0.85
            DefaultDesiredSize := vector2{X := FaceSize, Y := FaceSize}

        Row := stack_box:
            Orientation := orientation.Horizontal
            Slots := array:
                stack_box_slot:
                    Widget := Face
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 14.0, Bottom := 0.0}
                stack_box_slot:
                    Widget := Words
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

        Backing := color_block:
            DefaultColor := HostBlack
            DefaultOpacity := 0.55

        Box := overlay:
            Slots := array:
                overlay_slot:
                    Widget := Backing
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                overlay_slot:
                    Widget := Row
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 16.0, Top := 12.0, Right := 16.0, Bottom := 12.0}

        # ACROSS THE BOTTOM, and the invisible full-screen sheet is what makes
        # the bottom reachable at all: a canvas holding only pinned widgets
        # shrinks to fit them, so 88 per cent would be 88 per cent of the banner
        # rather than of the screen. The stream chat and the cash readout both
        # do the identical thing.
        Layout := canvas:
            Slots := array:
                canvas_slot:
                    Widget := color_block{DefaultColor := HostBlack, DefaultOpacity := 0.0}
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 0
                canvas_slot:
                    Widget := Box
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.88}, Maximum := vector2{X := 0.5, Y := 0.88}}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    ZOrder := 1

        # INPUT MODE NONE, LIKE EVERY OTHER LAYER THIS PROJECT PUTS OVER THE
        # ARENA. A panel that takes the mouse breaks the aiming, which this
        # project has learned twice.
        Slot := player_ui_slot:
            ZOrder := 103
            InputMode := ui_input_mode.None

        if (PlayerUI := GetPlayerUI[P]):
            PlayerUI.AddWidget(Layout, Slot)
            Log("DEBUG: Announcer banner up along the bottom, face square held empty.")
        else:
            Log("WARNING: the announcer's banner could not be drawn for this contestant.")

    # Puts one moment's line on the banner and takes it down again.
    ShowLine(Moment : string)<suspends>:void =
        if (Words := Line?):
            Words.SetText(ScreenLine(Barks.GetBark(Moment)))
            set BannerToken = BannerToken + 1
            Mine := BannerToken

            Sleep(BannerSeconds)

            # Only if nothing else has spoken since. See BannerToken.
            if (Mine = BannerToken):
                Words.SetText(ScreenLine(""))

    # =================================================================
    # GOING ON AIR
    # =================================================================

    OnBegin<override>()<suspends>:void =
        Log("DEBUG: Announcer ready. Nothing is said until the show starts.")

        Playspace := GetPlayspace()
        Playspace.PlayerAddedEvent().Subscribe(BuildBanner)

        # THE ONE THING THIS FILE LISTENS FOR RATHER THAN WATCHES. A chant is
        # over in a couple of seconds and a quarter-second poll would miss which
        # one it belonged to, so this moment arrives as an event. Everything
        # else is still read off the getters, per the header.
        #
        # AWAIT, NOT SUBSCRIBE. A Verse `event` has no Subscribe: it is waited
        # on. CrateManager takes SpawnCrateEvent the same way, and several
        # waiters on one event are all woken by a signal.
        spawn{ WatchForChants() }
        for (Contestant : Playspace.GetPlayers()):
            BuildBanner(Contestant)

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
        set LastPrizes = PrizesNow()
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
    #
    # A COMPARISON IS NOT A TRUE OR FALSE IN VERSE. Written as the bare
    # `SecondsElapsed - LastLineAt >= GapNow` this is script error 3512: a `>=`
    # can FAIL, so it needs a failure context, and the function was also told it
    # was returning a float rather than a logic. The if/else is what turns a
    # comparison into an answer, and every other test in this project is written
    # the same way for the same reason.
    CanSpeak()<transacts>:logic =
        var Free : logic = false
        if (SecondsElapsed - LastLineAt >= GapNow):
            set Free = true
        Free

    # Plays one moment. WHICH line of that moment is heard is the sound device's
    # decision, not this file's: see the header on Play Random Oneshot.
    Say(Moment : string, Voice : audio_player_device):void =
        set LastLineAt = SecondsElapsed
        set LastAnythingAt = SecondsElapsed
        Voice.Play()

        # THE NEXT SILENCE IS DRAWN HERE, not measured. Kai's ruling of
        # 2026-08-30. A guard against a range entered backwards in UEFN, since
        # GetRandomFloat with Min above Max is not worth finding out about
        # during a playtest.
        if (GapMaxSeconds > GapMinSeconds):
            set GapNow = GetRandomFloat(GapMinSeconds, GapMaxSeconds)
        else:
            set GapNow = GapMinSeconds

        # AND ON SCREEN, until there are clips to play. A voice field left
        # unwired plays nothing at all, so today the banner IS the announcer.
        if (ShowBanner?):
            spawn{ ShowLine(Moment) }

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

    # The crowd has started chanting and the crate is a couple of seconds out.
    # Said straight away rather than queued, because by the time the poll came
    # round the crate would already be falling and CrateDrop would own the
    # moment instead.
    WatchForChants()<suspends>:void =
        loop:
            Tier := Audience.CrateDemandEvent.Await()
            Log("DEBUG: Announcer heard the crowd chant for a tier {Tier} crate.")
            if (CanSpeak()?):
                Say("CrateCalled", CrateCalledVoice)

    # The contestant. Single-player per amendment 19, so the first one is the
    # only one.
    FirstContestant()<transacts>:?player =
        Contestants := GetPlayspace().GetPlayers()
        if (First := Contestants[0]):
            return option{First}
        false

    # How many prizes the contestant is holding right now, or the last count if
    # they cannot be read.
    PrizesNow()<transacts>:int =
        if (Contestant := FirstContestant()?):
            return Vault.FoundFor(Contestant).Length
        LastPrizes

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

        # A PRIZE IS RARER THAN A CRATE, so it sits below the crate only because
        # a crate carrying a prize would otherwise say both about one object.
        # The crate line goes first and the prize line lands on the next look.
        else if (PrizesNow() > LastPrizes):
            set LastPrizes = PrizesNow()
            Say("PrizeLanded", PrizeLandedVoice)

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
