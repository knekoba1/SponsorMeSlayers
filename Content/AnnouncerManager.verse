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
# ONE SOUND BOX PER LINE, AND THIS REPLACED SOMETHING CHEAPER. An Audio Player
# plays one sound and Verse cannot swap it: the digest gives it Play, Stop,
# Enable, Disable, Register and nothing else. So the first build used UEFN's
# "MSS Play Random Oneshot" MetaSound preset, one per moment, holding that
# moment's clips and picking one for itself. Ten devices instead of sixty, and
# the variety came free. Amendment 91.
#
# IT WAS WRONG THE DAY THE CLIPS ARRIVED. A preset that picks for itself never
# says which it picked, and the caption was separately asking the database for a
# random line, so the words on screen were usually not the words being heard.
# Nothing looked broken. Kai caught it the same afternoon the recordings went in,
# 2026-08-30, and asked for the caption to follow the voice.
#
# SO THE CHOICE MOVED IN HERE. Each moment has a LIST of Audio Players, one per
# line, this file picks an index, and that index both plays a box and fetches the
# line to print. The cost is Kai placing sixty boxes rather than twelve, which
# Kai accepted knowing the number.
#
# HOW TO FILL IT IN:
#   1. Import the .wav files into UEFN.
#   2. Place one Audio Player per line and point each at its single clip.
#   3. Drop them into the list for their moment, IN THE ORDER THE RECORDING
#      SHEET LISTS THEM.
#
# STEP 3 IS THE ONE THAT BITES. Nothing checks it and nothing can: a box in the
# wrong slot means he says one line and types another, silently. An empty list
# is safe, though, and still captions, because a half-wired host has to be
# shippable.
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
using { /Verse.org/Assets }
using { /Verse.org/Colors }
using { /Verse.org/Random }
using { /Verse.org/Simulation }

announcer_manager := class(creative_device):

    # =================================================================
    # THE VOICES. One LIST per moment, holding one Audio Player per line, in the
    # order the lines are written. The names match the trigger names in
    # pipelines/announcer-bark/settings.py and the section headings in Kai's own
    # document.
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

    # The results card, watched for one thing only: whether it is on screen, so
    # the caption can get out of its way. Left unwired the caption simply never
    # hides, which is how it behaved before this was added.
    @editable
    Results : game_over_screen = game_over_screen{}

    # THE FIVE MOMENTS ADDED ON 2026-08-29. Kai: "i dont see much for the
    # announcer to say stuff when the audience orders a crate or props though."
    # Two are wired below; the three arrivals are slots waiting for their
    # trigger, the same way DeadAir and SponsorRead waited for theirs.
    @editable
    CrateCalledVoices : []audio_player_device = array{}

    @editable
    PrizeLandedVoices : []audio_player_device = array{}

    @editable
    FirstTankVoices : []audio_player_device = array{}

    @editable
    FirstBoarVoices : []audio_player_device = array{}

    @editable
    FirstSniperVoices : []audio_player_device = array{}

    # The banner off, without unwiring anything.
    @editable
    ShowBanner : logic = true

    # SECONDS PER LETTER. This is the announcer's speaking pace, and it is the
    # dial to turn if the caption runs ahead of him or lags behind.
    #
    # 0.045 IS ABOUT 22 LETTERS A SECOND, which is roughly how fast a hyped
    # broadcast announcer reads. Kai's longest line is 141 letters, so it types
    # itself in about six and a half seconds. Kai, 2026-08-30: "the annocuer is
    # saying things too fast liek teh captions are too fast i dont think anyone
    # talks that fast."
    @editable
    TypeSeconds : float = 0.045

    # How long the finished line rests on screen before it clears, counted from
    # the last letter rather than the first. Short on purpose: the typing is now
    # most of the caption's life on screen.
    @editable
    BannerHoldSeconds : float = 2.5

    # HOW FAST THE MOUTH MOVES, in seconds per frame. 0.1 is ten frames a second,
    # the middle of the 8 to 12 the art handoff asks for.
    #
    # IT IS A FLIPBOOK, NOT LIP SYNC. The four open-mouth frames cycle while he
    # talks and that is the whole trick. Nothing here looks at the audio, and
    # nothing can: Verse cannot read a waveform out of an Audio Player.
    @editable
    FaceFrameSeconds : float = 0.1

    @editable
    ShowFace : logic = true

    @editable
    BannerTextSize : float = 28.0

    # WHERE THE CAPTION SITS, as a share of the screen. Kai's ruling 2026-08-31:
    # top centre, in the gap between the LIVE panel on the left and the CASH
    # counter on the right.
    #
    # PINNED BY ITS TOP EDGE so a long line grows DOWNWARD into the empty middle
    # of the screen, never sideways into the panels.
    @editable
    BannerX : float = 0.5

    @editable
    BannerY : float = 0.045

    # HOW TALL THE BAND IS, as a share of the screen. Two rows at the default
    # text size plus its padding. It ends at 0.045 + 0.09, well inside the top
    # fifth Kai fixed as the limit.
    @editable
    BannerBandHeight : float = 0.09

    # THE LANE, and the reason nothing here is in pixels. Kai: "No fixed pixel
    # width and no fixed pixel position. The CASH value gets wider as the
    # contestant earns money."
    #
    # WHAT CANNOT BE DONE, AND THIS IS THE HONEST LIMIT. Kai asked for the
    # caption to be positioned against the MEASURED bounds of its neighbours.
    # Verse cannot see them: the LIVE panel and the game mode readout are
    # Fortnite's own HUD, and nothing in the digest reads a HUD element's
    # rectangle. So the caption reserves a share of the screen instead and
    # leaves everything outside it alone.
    #
    # 0.42 LEAVES 29 PER CENT CLEAR EITHER SIDE, which a seven-figure cash
    # readout does not come close to crossing. Widen this and check the cash
    # counter at its longest, not at $0.
    @editable
    BannerLaneFraction : float = 0.42

    # THE HARD CAP ON HEIGHT. Kai's ruling 2026-08-31: "Hard cap it at 2 lines.
    # If the text still does not fit in 2 lines, shrink the font size to make it
    # fit. Never add a third line and never grow downward into the arena."
    @editable
    BannerMaxRows : float = 2.0

    # ROUGHLY HOW WIDE A LETTER IS as a share of the text size. Used only to
    # guess how much text fits on a row, because Verse cannot measure a string.
    # 0.5 is about right for this typeface in capitals; raise it if long lines
    # still spill onto a third row.
    @editable
    LetterWidthRatio : float = 0.5

    # The text never shrinks past this, however long the line. Below it the
    # caption stops being readable at HUD size, and a clipped line beats an
    # unreadable one.
    @editable
    BannerMinTextSize : float = 15.0

    # The reference width UEFN lays widgets out against. The lane above is a
    # fraction of THIS, not of a real monitor, which is what makes it hold at
    # any resolution. The Hype meter uses the matching 1080.0 for height.
    @editable
    ScreenWidthUnits : float = 1920.0

    # The empty square the announcer's face will go in, in pixels.
    @editable
    FaceSize : float = 96.0

    @editable
    ShowIntroVoices : []audio_player_device = array{}

    @editable
    RoundStartVoices : []audio_player_device = array{}

    @editable
    KillStreakVoices : []audio_player_device = array{}

    @editable
    CashPickupVoices : []audio_player_device = array{}

    @editable
    CrateDropVoices : []audio_player_device = array{}

    @editable
    LowHealthVoices : []audio_player_device = array{}

    @editable
    RoundClearVoices : []audio_player_device = array{}

    @editable
    SignOffVoices : []audio_player_device = array{}

    @editable
    DeadAirVoices : []audio_player_device = array{}

    @editable
    SponsorReadVoices : []audio_player_device = array{}

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
    # IT USED TO BE A FLAT 18 TO 30 AND IT WRECKED THE SHOW. Kai's log, 02:18 on
    # 2026-08-31: a supply crate landed and he announced it forty-four seconds
    # later, three seconds before that crate expired. A round started and he
    # announced it forty-three seconds later, by which point the round was
    # nearly over. Kai: "everything was off i didnt say the round voices when
    # the round ended". The floor had to be that high because it had to clear
    # the LONGEST clip in the game, so every four-word quip blocked him for as
    # long as the twenty-seven-word ad did.
    #
    # SO THE BLOCK IS NOW AS LONG AS THE LINE. Three buckets by letter count,
    # because Verse has no tidy int-to-float here and three numbers Kai can
    # actually turn beats an arithmetic estimate nobody can picture. A short
    # quip frees him in about seven seconds, the ad still holds him for twenty.
    @editable
    ShortLineSeconds : float = 5.0

    # Longer than this many letters is a medium line.
    @editable
    MediumLineLetters : int = 60

    @editable
    MediumLineSeconds : float = 8.0

    # Longer than this many letters is a long line.
    @editable
    LongLineLetters : int = 110

    @editable
    LongLineSeconds : float = 13.0

    # THE PAUSE ON TOP, drawn fresh every time. Kai, 2026-08-30: "the brething
    # room should varry though? as logn as he never ovelaps himself". The line
    # length above is the never-overlapping half; this is the breathing.
    @editable
    GapExtraMin : float = 2.0

    @editable
    GapExtraMax : float = 8.0

    # HOW LATE IS TOO LATE. A moment he could not speak to within this many
    # seconds is dropped rather than saved up. This is the other half of the
    # 02:18 bug: the counters that remember a moment stay true until he says
    # something about them, so an unsaid moment queued up and came out whenever
    # he was next free, however long that was and however over it was.
    @editable
    StaleAfterSeconds : float = 6.0

    # How long the arena has to be uneventful before he fills the silence.
    @editable
    QuietBeforeFiller : float = 18.0

    # How many kills close together count as a streak worth remarking on. The
    # Hype meter has its own cluster rule; this is deliberately separate, so
    # tuning one never silently retunes the other.
    #
    # 3 -> 5 -> 4 ON 2026-08-30, and the second move came with a tighter window.
    # Kai first: "the ratings line happene too freqents". Three kills inside four
    # seconds is most of a room once the waves are forty hostiles deep, so the
    # streak was not a streak, it was the baseline. Then, seeing 5 in 4 seconds
    # written down, Kai named what was actually wanted: "i wan tit wired so i
    # kill like 4 robots within the same seccond of each other."
    #
    # THE COUNT MATTERED LESS THAN THE WINDOW. Four kills spread over four
    # seconds is ordinary shooting; four inside a single second is a crowd of
    # them walking into one burst, which is the moment worth a line.
    @editable
    KillsForStreak : int = 4

    # How long a streak's kills may be spread over, in seconds. The clock is
    # reset by every kill, so this is the longest gap ALLOWED BETWEEN kills
    # rather than the length of the whole streak.
    #
    # 4.0 -> 1.0 ON 2026-08-30, and this is the half of Kai's ruling that does
    # the work. See KillsForStreak.
    @editable
    StreakWindowSeconds : float = 1.0

    # Below this share of maximum health he starts enjoying himself. GDD 3.1
    # puts the Underdog Boost at 40%, and using the same line keeps the two
    # halves of "you are in trouble" agreeing with each other.
    @editable
    LowHealthFraction : float = 0.4

    # Cash is constant, so only some pickups are worth a line. One in this many.
    @editable
    OneCashLineIn : int = 8

    # THE SAME RULE, NOW ON THE OTHER TWO FREQUENT MOMENTS. Kai, 2026-08-30: "it
    # doesnt need to always say th elines you knoe, like if i get 3 kill streaks
    # inthe speanof 30 seconds it doesnt needs to run all the lines yk."
    #
    # A HOST WHO ANSWERS EVERYTHING IS A HOST NOBODY LISTENS TO, and the ones
    # that repeat are the ones that wear out. Cash already worked this way and
    # the rule simply never spread.
    #
    # THE RARE MOMENTS ARE LEFT ALONE ON PURPOSE. A room cleared, a round
    # starting, a prize, low health, the three entrances and the sign-off happen
    # once or twice a run each; skipping one of those loses the moment rather
    # than sparing the player a line.
    @editable
    OneStreakLineIn : int = 3

    @editable
    OneCrateLineIn : int = 2

    # =================================================================
    # STATE
    # =================================================================

    var SecondsElapsed : float = 0.0
    var LastLineAt : float = -100.0
    var LastAnythingAt : float = 0.0

    # The gap this particular silence is waiting out, redrawn after every line.
    # It starts at nothing so the show's opening line is never held back.
    var GapNow : float = 0.0

    # JUST THE TALKING HALF OF THAT GAP, without the breathing pause on the end.
    # An entrance is allowed to jump the pause but never the clip. See CanBarge.
    var SpokenNow : float = 0.0

    # WHEN EACH WAITING MOMENT HAPPENED, or -1.0 for nothing waiting. Only the
    # four that are remembered by a counter need one; a kill streak and a cash
    # pickup expire on their own, and low health is a state rather than an
    # event.
    # THE LAST LINE SAID IN EACH MOMENT, so it is never said twice running.
    # Kai, 2026-08-30, on hearing the same kill streak line back to back. With
    # four lines in a group, a fair roll repeats about a quarter of the time,
    # which is often enough to sound broken rather than random.
    var LastSaid : [string]int = map{}

    var RoomsAt : float = -1.0
    var TierAt : float = -1.0
    var CratesAt : float = -1.0
    var PrizesAt : float = -1.0

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

    # ONE ENTRANCE EACH PER RUN. Kai's ruling 2026-08-30: "i onyl want it the
    # firre for the first time they coem out so the first 4 rounds and thats
    # it". The Boar arrives in room 2, the Sniper in room 3 and the Tank in
    # room 4, so all three are spent inside the opening minutes and the host
    # never mentions an arrival again.
    var CalledTank : logic = false
    var CalledBoar : logic = false
    var CalledSniper : logic = false

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
    # while an earlier one is still typing is not wiped by that one's timer.
    var BannerToken : int = 0

    # The face on the banner, kept so the mouth can be swapped frame by frame.
    var Portrait : ?texture_block = false

    # The same trick as BannerToken, for the mouth: a new line abandons whatever
    # cycle was running rather than the two fighting over the same picture.
    var FaceToken : int = 0

    # THE BOX CURRENTLY TALKING, kept so it can be silenced. Amendment 105,
    # Kai's ruling 2026-09-01: "cant u just cut him off?"
    #
    # PLAY AGAIN USED TO PRODUCE TWO HOSTS AT ONCE. The sign-off is a real clip
    # that keeps playing after the run is over, and the fresh run wipes the
    # memory of it and says the show intro straight away. The 2026-09-01 log has
    # SignOff at 23:58:57 and ShowIntro one second later, both audible.
    var Playing : ?audio_player_device = false

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

            # WRAPS RATHER THAN STRETCHES. Without this a long line runs on for
            # ever and walks straight through whatever is beside it. WrapWidth
            # is the only pixel number in the layout and it is derived, not
            # typed: the lane's share of UEFN's own reference width.
            AutoWrap := true
            WrapWidth := ScreenWidthUnits * BannerLaneFraction

        set Line = option{Words}

        # THE FACE. Empty since the banner was built, because Kai had not drawn
        # the announcer yet and a banner that changes shape the day the picture
        # arrives is a second layout job. The picture arrived 2026-08-30.
        #
        # NAMED FaceSquare, NOT Face. The 35 portrait frames live in a content
        # folder called Face, and UEFN turns every content folder into a Verse
        # module of the same name, so a local called Face went ambiguous with it
        # and the whole project stopped compiling. Script error 3588. Do not
        # rename it back.
        FaceSquare := texture_block:
            DefaultImage := Face.announcer_excited_00
            DefaultDesiredSize := vector2{X := FaceSize, Y := FaceSize}

        set Portrait = option{FaceSquare}

        Row := stack_box:
            Orientation := orientation.Horizontal
            Slots := array:
                stack_box_slot:
                    Widget := FaceSquare
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

        # THE INVISIBLE FULL-SCREEN SHEET IS WHAT MAKES A CORNER REACHABLE AT
        # ALL: a canvas holding only pinned widgets shrinks to fit them, so a
        # percentage would be a percentage of the banner rather than of the
        # screen. The stream chat and the cash readout both do the identical
        # thing.
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

                    # A BAND, NOT A POINT, AND THIS IS THE WHOLE FIX. Pinned at
                    # a point the box had no width to speak of, so the layout
                    # gave the text almost none and every line came out as a
                    # tall thin column of one or two words. Kai, 2026-08-31:
                    # "Give it a MINIMUM width, not just a maximum, so it can
                    # never squeeze into a narrow column."
                    #
                    # Stretched between two anchors it always has the lane's
                    # full width, which is a floor as well as a ceiling.
                    Anchors := anchors{Minimum := vector2{X := BannerX - BannerLaneFraction * 0.5, Y := BannerY}, Maximum := vector2{X := BannerX + BannerLaneFraction * 0.5, Y := BannerY + BannerBandHeight}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
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

    # TYPES ONE LINE ACROSS THE BANNER, then takes it down again.
    #
    # KAI ASKED FOR A TYPEWRITER, 2026-08-30: "the way i want the captiosn to
    # apper onthe screen is like a type writer". It also solves a problem it was
    # not asked to solve. A caption that appears whole has to guess how long to
    # sit there; one that types itself is still arriving while he is still
    # talking, so the pace does the work the guess used to.
    #
    # THE SPEED IS PER LETTER, so a long line takes longer than a short one for
    # free, which is exactly how the clips behave.
    # THE TEXT SIZE THIS LINE NEEDS so it fits in BannerMaxRows rows of the
    # band. Verse cannot measure a string, so this is an estimate: the band's
    # width times the rows allowed, divided by the letters to place, divided by
    # how wide a letter is as a share of its size.
    #
    # IT ONLY EVER SHRINKS. A short line stays at the size Kai set rather than
    # ballooning to fill the band.
    SizeFor(Words : string)<transacts>:float =
        var Wanted : float = BannerTextSize
        RowUnits := ScreenWidthUnits * BannerLaneFraction

        # STEPPED DOWN A POINT AT A TIME rather than solved in one sum, because
        # Verse has no tidy way to divide a letter count by a size: an int and a
        # float will not meet without Floor, and Floor is the comparison anyway.
        # A dozen steps at most, once per line, costs nothing.
        loop:
            if (Wanted <= BannerMinTextSize):
                break
            if (Wanted <= 0.0, LetterWidthRatio <= 0.0):
                break
            if (Capacity := Floor[RowUnits * BannerMaxRows / (Wanted * LetterWidthRatio)], Words.Length <= Capacity):
                break
            set Wanted = Wanted - 1.0

        if (Wanted < BannerMinTextSize):
            set Wanted = BannerMinTextSize
        Wanted

    TypeOut(Words : string)<suspends>:void =
        if (Label := Line?):
            Label.SetTextSize(SizeFor(Words))
            set BannerToken = BannerToken + 1
            Mine := BannerToken

            var Shown : string = ""
            for (Spot := 0..Words.Length - 1):
                # ABANDONED THE MOMENT ANYTHING ELSE SPEAKS. Without this, two
                # lines type over each other one letter at a time, which looks
                # like corruption rather than like a mistake.
                if (Mine <> BannerToken):
                    return
                if (Piece := Words.Slice[0, Spot + 1]):
                    set Shown = Piece
                    Label.SetText(ScreenLine(Shown))
                Sleep(TypeSeconds)

            Label.SetText(ScreenLine(Words))

            # HOW LONG IT RESTS IS MEASURED FROM THE END OF THE TYPING, not from
            # the start, so a long line is not half gone before it finishes
            # arriving.
            Sleep(BannerHoldSeconds)

            # Only if nothing else has spoken since. See BannerToken.
            if (Mine = BannerToken):
                Label.SetText(ScreenLine(""))


    # =================================================================
    # THE FACE
    #
    # A CRT-HEADED HOST, AND THE HEAD IS THE POINT. Kai's design, locked
    # 2026-08-31: a man in a hot pink game-show jacket whose head is a retro
    # television, so his expression is graphics on a screen rather than a drawn
    # face. It can change instantly per event and still read at HUD size, which
    # a drawn human face cannot.
    #
    # SEVEN STATES, FIVE FRAMES EACH. Frame 00 is the resting face and 01 to 04
    # are the mouth opening. Cycling 01 to 04 while a bark plays is what makes
    # him look like he is talking, and the moment it ends he goes back to 00.
    #
    # DEADPAN'S MOUTH BARELY MOVES ON PURPOSE. He is bored, so he is not putting
    # the effort in. Do not "fix" it to match excited's range.
    #
    # ONE STATE PER LINE, WHICH IS THE HANDOFF'S OWN FALLBACK. The design would
    # rather he switched from excited to deadpan mid-line at the [deadpan] mark.
    # He cannot: those marks are recording directions typed into ElevenLabs and
    # were never stored with the words, so the game has no idea where in a line
    # the turn happens. Storing them would mean them typing out in the caption.
    # =================================================================

    FramesFor(Moment : string)<transacts>:[]texture =
        if (Moment = "DeadAir"):
            array{Face.announcer_deadpan_00, Face.announcer_deadpan_01, Face.announcer_deadpan_02, Face.announcer_deadpan_03, Face.announcer_deadpan_04}
        else if (Moment = "KillStreak" or Moment = "RoundClear"):
            array{Face.announcer_impressed_00, Face.announcer_impressed_01, Face.announcer_impressed_02, Face.announcer_impressed_03, Face.announcer_impressed_04}
        else if (Moment = "CashPickup"):
            array{Face.announcer_cash_00, Face.announcer_cash_01, Face.announcer_cash_02, Face.announcer_cash_03, Face.announcer_cash_04}
        else if (Moment = "LowHealth"):
            array{Face.announcer_alarm_00, Face.announcer_alarm_01, Face.announcer_alarm_02, Face.announcer_alarm_03, Face.announcer_alarm_04}
        else if (Moment = "SignOff"):
            array{Face.announcer_wink_00, Face.announcer_wink_01, Face.announcer_wink_02, Face.announcer_wink_03, Face.announcer_wink_04}
        else if (Moment = "SponsorRead"):
            array{Face.announcer_salesman_00, Face.announcer_salesman_01, Face.announcer_salesman_02, Face.announcer_salesman_03, Face.announcer_salesman_04}
        else:
            # EXCITED IS THE RESTING STATE, not deadpan. The show intro, a round
            # starting, a crate called or landing, a prize, and all three
            # entrances live here.
            array{Face.announcer_excited_00, Face.announcer_excited_01, Face.announcer_excited_02, Face.announcer_excited_03, Face.announcer_excited_04}

    # Runs the mouth for as long as the line is expected to last, then rests.
    # Seconds is the clip-length estimate Say already works out for the gap, so
    # the mouth and the silence after it agree without a second guess.
    TalkFace(Moment : string, Seconds : float)<suspends>:void =
        if (Block := Portrait?):
            Frames := FramesFor(Moment)

            set FaceToken = FaceToken + 1
            Mine := FaceToken

            var Elapsed : float = 0.0
            var Spot : int = 1
            loop:
                # A NEWER LINE HAS STARTED. Leave its mouth alone; it will set
                # its own resting frame when it finishes.
                if (Mine <> FaceToken):
                    return
                if (Elapsed >= Seconds):
                    break
                if (Picture := Frames[Spot]):
                    Block.SetImage(Picture)
                set Spot = Spot + 1
                if (Spot > 4):
                    set Spot = 1
                Sleep(FaceFrameSeconds)
                set Elapsed = Elapsed + FaceFrameSeconds

            if (Mine = FaceToken, Resting := Frames[0]):
                Block.SetImage(Resting)

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
            Say("ShowIntro", ShowIntroVoices)

            race:
                RunWatch()
                AwaitRunEnd(Self)

            # THE SIGN-OFF IS THE LAST THING HE SAYS, and it plays whichever
            # button ended the run. The game over card is already up by now.
            Say("SignOff", SignOffVoices)
            Log("DEBUG: Announcer off air until the next run.")

    # Everything he remembers about a run, cleared. Called at the top of every
    # run including the first, so one path serves both.
    # CUTS THE HOST OFF MID-WORD. The clip stops, the caption clears and the
    # mouth goes back to resting, so the picture and the sound stop together.
    #
    # The two tokens are bumped rather than the loops being cancelled, because
    # a spawn cannot be cancelled. Both loops check their own number every pass
    # and abandon quietly when it is no longer the latest, which is the same
    # trick a second line arriving mid-sentence already relies on.
    CutHimOff():void =
        if (Box := Playing?):
            Box.Stop()
            set Playing = false

        set BannerToken = BannerToken + 1
        set FaceToken = FaceToken + 1

        if (Label := Line?):
            Label.SetText(ScreenLine(""))

        if (Block := Portrait?):
            Block.SetImage(Face.announcer_excited_00)

        Log("DEBUG: Announcer cut off. The microphone is clear for the new show.")

    StartFreshRun():void =
        CutHimOff()
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
        set RoomsAt = -1.0
        set TierAt = -1.0
        set CratesAt = -1.0
        set PrizesAt = -1.0

        # THE ENTRANCES ARE PER RUN, not per island. A second run starts at
        # room 1 with no Tank in it, so the Tank walking in is news again.
        set CalledTank = false
        set CalledBoar = false
        set CalledSniper = false
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

    # THE SAME TEST WITHOUT THE BREATHING PAUSE. Only the three entrances use
    # it, and only because of what Kai saw on 2026-08-30: "the baor was not
    # timed rigth the round eded the boar swpaned and it didnt sya the line till
    # later."
    #
    # A ROOM ENDS AND THE NEXT ONE BEGINS A SECOND APART, so the room-won line
    # goes out first and the Boar walks in while the host is still inside the
    # pause after it. The pause is there so he does not chatter; an entrance
    # happens once a run and is the one thing worth chattering about. He still
    # waits out the CLIP, so he never talks over himself.
    CanBarge()<transacts>:logic =
        var Free : logic = false
        if (SecondsElapsed - LastLineAt >= SpokenNow):
            set Free = true
        Free

    # Plays one moment. THIS FILE NOW CHOOSES THE LINE, which it did not used to.
    #
    # It used to hand the choice to the sound device: one Play Random Oneshot
    # preset per moment, holding that moment's clips, picking one for itself.
    # That was cheap and it was wrong the moment the clips existed, because the
    # caption was separately asking the database for a random line, so the words
    # on screen were usually not the words being heard. Kai spotted it as soon as
    # the recordings went in, 2026-08-30.
    #
    # SO THE PICK IS A NUMBER NOW. One Audio Player per LINE, held in a list per
    # moment, and this picks an index. That index plays a sound box and fetches
    # the matching line for the caption, so the two cannot drift apart.
    #
    # THE LIST ORDER IS LOAD-BEARING AND NOTHING VALIDATES IT. Position 3 in the
    # list must be position 3 in the recording sheet. Get it wrong and he says
    # one line while typing another, with no error anywhere.
    Say(Moment : string, Voices : []audio_player_device):void =
        SayLine(Moment, Voices, -1)

    # THE SAME THING WITH THE LINE ALREADY CHOSEN. Wanted is -1 for "pick one",
    # and anything else names the position to say.
    #
    # ONE CALLER USES IT AND IT IS THE PRIZES. Kai, 2026-08-30: "based on the
    # prize it drops its usppose dto say the prize line." Fourteen prizes,
    # fourteen lines, and a random pick meant he announced a television over a
    # traffic cone. The prize vault knows which one it just handed over, so the
    # announcer asks and says that one.
    SayLine(Moment : string, Voices : []audio_player_device, Wanted : int):void =
        set LastLineAt = SecondsElapsed
        set LastAnythingAt = SecondsElapsed

        # A MOMENT WITH NO BOXES WIRED STILL CAPTIONS. Half-wired has to be safe
        # to ship, so the words appear even when nothing has been placed yet, and
        # a moment with neither boxes nor words simply passes in silence.
        var Index : int = -1
        if (Voices.Length > 0):

            # A NAMED LINE IS TAKEN AS GIVEN, no reroll and no no-repeat rule.
            # Winning the same prize twice running should say that prize's line
            # twice, and the fallback is a random pick rather than silence in
            # case the two lists are ever different lengths.
            if (Wanted >= 0, Wanted < Voices.Length):
                set Index = Wanted
            else:
                set Index = GetRandomInt(0, Voices.Length - 1)

                # NOT THE SAME ONE TWICE RUNNING. One reroll rather than a loop:
                # with two lines it always lands on the other one, and with more
                # it very nearly always does, which is enough. A group of one is
                # left alone, because there is nothing else for it to say.
                if (Voices.Length > 1, Before := LastSaid[Moment], Before = Index):
                    set Index = GetRandomInt(0, Voices.Length - 1)

                    # Still the same one, so step to the neighbour and wrap.
                    # Cheaper and more predictable than rolling until it differs.
                    if (Index = Before):
                        set Index = Index + 1
                        if (Index >= Voices.Length):
                            set Index = 0

            if (set LastSaid[Moment] = Index):
                Log("DEBUG: Announcer remembers {Moment} line {Index}.")

            if (Box := Voices[Index]):
                Box.Play()
                set Playing = option{Box}

        Words := if (Index >= 0) then Barks.GetBarkAt(Moment, Index) else Barks.GetBark(Moment)

        # THE NEXT SILENCE IS AS LONG AS THIS LINE, PLUS A PAUSE. See the dials.
        # The guard is against a range entered backwards in UEFN, since
        # GetRandomFloat with Min above Max is not worth finding out about
        # during a playtest.
        var Spoken : float = ShortLineSeconds
        if (Words.Length > MediumLineLetters):
            set Spoken = MediumLineSeconds
        if (Words.Length > LongLineLetters):
            set Spoken = LongLineSeconds

        set SpokenNow = Spoken
        if (GapExtraMax > GapExtraMin):
            set GapNow = Spoken + GetRandomFloat(GapExtraMin, GapExtraMax)
        else:
            set GapNow = Spoken + GapExtraMin

        # NOT OVER THE SCOREBOARD. The line is still said out loud; only the
        # caption stands down, because the results card is already full of the
        # numbers the contestant wants to read.
        if (ShowBanner?, Words <> "", not Results.IsShowing()?):
            spawn{ TypeOut(Words) }

        if (ShowFace?):
            spawn{ TalkFace(Moment, Spoken) }

        Log("DEBUG: Announcer says {Moment} line {Index}, quiet for {GapNow}s.")

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
            else if (CanBarge()?):
                CallAnEntrance()

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

        # THE FOUR REMEMBERED MOMENTS, each stamped when it arrives and thrown
        # away if he could not get to it in time. Before this, an unsaid moment
        # stayed true for ever and came out whenever he was next free: Kai heard
        # a crate announced forty-four seconds after it landed and three seconds
        # before it expired.
        Landed := Crates.GetCratesLanded()
        if (Landed > LastCrates):
            set LastAnythingAt = SecondsElapsed
            if (CratesAt < 0.0):
                set CratesAt = SecondsElapsed
            if (SecondsElapsed - CratesAt > StaleAfterSeconds):
                set LastCrates = Landed
                set CratesAt = -1.0
                Log("DEBUG: Announcer -- a crate drop went stale unsaid.")

        Rooms := Waves.GetRoomsWon()
        if (Rooms > LastRooms):
            set LastAnythingAt = SecondsElapsed
            if (RoomsAt < 0.0):
                set RoomsAt = SecondsElapsed
            if (SecondsElapsed - RoomsAt > StaleAfterSeconds):
                set LastRooms = Rooms
                set RoomsAt = -1.0
                Log("DEBUG: Announcer -- a room won went stale unsaid.")

        Tier := Waves.GetCurrentTier()
        if (Tier > LastTier):
            set LastAnythingAt = SecondsElapsed
            if (TierAt < 0.0):
                set TierAt = SecondsElapsed
            if (SecondsElapsed - TierAt > StaleAfterSeconds):
                set LastTier = Tier
                set TierAt = -1.0
                Log("DEBUG: Announcer -- a round start went stale unsaid.")

        Prizes := PrizesNow()
        if (Prizes > LastPrizes):
            set LastAnythingAt = SecondsElapsed
            if (PrizesAt < 0.0):
                set PrizesAt = SecondsElapsed
            if (SecondsElapsed - PrizesAt > StaleAfterSeconds):
                set LastPrizes = Prizes
                set PrizesAt = -1.0
                Log("DEBUG: Announcer -- a prize landing went stale unsaid.")

    # The crowd has started chanting and the crate is a couple of seconds out.
    # Said straight away rather than queued, because by the time the poll came
    # round the crate would already be falling and CrateDrop would own the
    # moment instead.
    WatchForChants()<suspends>:void =
        loop:
            Tier := Audience.CrateDemandEvent.Await()
            Log("DEBUG: Announcer heard the crowd chant for a tier {Tier} crate.")
            if (CanSpeak()?):
                Say("CrateCalled", CrateCalledVoices)

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
            Say("LowHealth", LowHealthVoices)

        # THE THREE ENTRANCES SIT HIGH, above the room they arrive in. A room
        # starting is a line he has four of and says every room; a Tank walking
        # in happens once a run. The room start is not lost either, it simply
        # waits for the next look and lands a few seconds later, which is the
        # right way round: the monster first, the paperwork after.
        else if (Waves.TanksAreIn()?, not CalledTank?):
            set CalledTank = true
            Say("FirstTank", FirstTankVoices)

        else if (Waves.BoarsAreIn()?, not CalledBoar?):
            set CalledBoar = true
            Say("FirstBoar", FirstBoarVoices)

        else if (Waves.SentinelsAreIn()?, not CalledSniper?):
            set CalledSniper = true
            Say("FirstSniper", FirstSniperVoices)

        else if (Rooms > LastRooms):
            set LastRooms = Rooms
            set RoomsAt = -1.0
            Say("RoundClear", RoundClearVoices)

        else if (Tier > LastTier):
            set LastTier = Tier
            set TierAt = -1.0
            Say("RoundStart", RoundStartVoices)

        else if (Landed > LastCrates):
            set LastCrates = Landed
            set CratesAt = -1.0
            if (GetRandomInt(1, OneCrateLineIn) = 1):
                Say("CrateDrop", CrateDropVoices)

        # A PRIZE IS RARER THAN A CRATE, so it sits below the crate only because
        # a crate carrying a prize would otherwise say both about one object.
        # The crate line goes first and the prize line lands on the next look.
        else if (PrizesNow() > LastPrizes):
            set LastPrizes = PrizesNow()
            set PrizesAt = -1.0
            SayLine("PrizeLanded", PrizeLandedVoices, Vault.LastPrizeWon())

        else if (StreakKills >= KillsForStreak):
            set StreakKills = 0
            set StreakLeft = 0.0
            if (GetRandomInt(1, OneStreakLineIn) = 1):
                Say("KillStreak", KillStreakVoices)

        else if (Score > LastScore):
            # ONE IN EIGHT, because cash is constant and a line every pickup
            # would be the only thing anybody heard all match.
            set LastScore = Score
            if (GetRandomInt(1, OneCashLineIn) = 1):
                Say("CashPickup", CashPickupVoices)

        else if (SecondsElapsed - LastAnythingAt >= QuietBeforeFiller):
            FillTheSilence()

        # Health climbing back re-arms the low health remark for next time. Done
        # last so it can never eat this look's line.
        if (not LowOnHealth()?):
            set CalledLowHealth = false

    # The three entrances on their own, for the look where the host is out of
    # his clip but still inside his pause. Same order and same flags as in
    # CallIt, so an entrance can never be said twice.
    CallAnEntrance():void =
        if (Waves.TanksAreIn()?, not CalledTank?):
            set CalledTank = true
            Say("FirstTank", FirstTankVoices)

        else if (Waves.BoarsAreIn()?, not CalledBoar?):
            set CalledBoar = true
            Say("FirstBoar", FirstBoarVoices)

        else if (Waves.SentinelsAreIn()?, not CalledSniper?):
            set CalledSniper = true
            Say("FirstSniper", FirstSniperVoices)

    # Kai's ruling, amendment 90: the ads go in the gaps, taking turns with the
    # dead air lines rather than replacing them.
    FillTheSilence():void =
        set LastAnythingAt = SecondsElapsed
        if (AdIsNext?):
            set AdIsNext = false
            Say("SponsorRead", SponsorReadVoices)
        else:
            set AdIsNext = true
            Say("DeadAir", DeadAirVoices)

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
