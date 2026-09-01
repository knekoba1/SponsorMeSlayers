# GameOverScreen.verse
#
# GDD Section 2.5 "Loss State (Run Lost)", built to Kai's brief of 2026-08-25.
#
# WHAT THIS IS, AND WHAT IT IS NOT. It is not a "you died" screen. It is the
# show signing off. The Network is dismissive, it never admits that dying was
# bad, and it is already selling the next episode before the contestant has
# stopped twitching. Everything here follows from that: no sad sound, no fade to
# black, no YOU DIED, no credits, no continue timer. The upbeat music keeps
# playing straight through, which is the joke.
#
# THE CONTESTANT STAYS STANDING, FROZEN AND UNTOUCHABLE. Kai's ruling. Fortnite
# deletes a contestant the instant they are eliminated and takes the camera with
# them, so the body Kai pictured on the ground cannot exist. Instead the run
# ends without an elimination: the character is put in stasis where it stands
# and moved onto the hostiles' team, which is the only lever that makes guards
# lose interest in something. See [[uefn-npc-and-inventory-limits]] for why
# there is no way to tell a guard to ignore anything directly.
#
# TWO THINGS IN THE BRIEF THE ENGINE WILL NOT DO, recorded so they are not
# attempted again.
#   * A robot walking over the body on cue. Guard pathing is not ours to drive.
#     What actually happens is better than nothing: the hostiles keep milling
#     about, and once the contestant is on their team they wander rather than
#     swarm.
#   * The tilt on the rank stamp. A widget cannot be rotated at all, in any
#     container, at any point. The slam, the squash and the spring back are all
#     real; only the tilt is missing. Do not reach for a tilted image to fake
#     it: the same wish produced the slanted caution tape, which is a stack of
#     nudged rows, and a stamp is a single word that cannot be sliced that way.
#
# THE MOUSE IS TAKEN ON PURPOSE HERE, AND ONLY HERE. This card has buttons, so
# it goes up with ui_input_mode.All. Every other layer over the arena says None,
# because the default takes the mouse and breaks aiming, which cost two
# playtests on 2026-08-25. When the reset lands, taking this card down must put
# the mouse back or aiming will be gone for the next run. Aiming is uncuttable
# per GDD 5.7.
#
# NEITHER BUTTON ENDS THE MATCH ANY MORE, amendment 86. PLAY AGAIN drops the
# contestant straight back into a fresh run at Tier 1; LEAVE THE SHOW puts the
# broadcast back on. Anyone wanting out of the island leaves through Fortnite's
# own menu.
#
# FREEZING WITHOUT THAWING REPLAYED THE CARD, and it is worth knowing why. The
# first working PLAY AGAIN restarted the waves and then put this card straight
# back up. The contestant was still held in stasis on zero health, so the fatal
# blow was still in force when the run resumed and the death fired again.
# TakeCardDown now thaws and heals. Anything else that freezes the contestant
# must own its own way back out.

using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }
using { /Verse.org/Colors }
using { /Verse.org/Simulation }

# An opacity, in the only range an opacity is allowed to be.
#
# IT SITS ABOVE THE CLASS BECAUSE VERSE READS TOP DOWN. A type alias cannot be
# used earlier in a file than it is written; the first build said so in as many
# words.
unit_float := type{_X : float where 0.000000 <= _X, _X <= 1.000000}

game_over_screen := class(creative_device):

    # =================================================================
    # THE PALETTE
    #
    # Kai's six colours and no others. Anything that looks like a seventh here
    # is one of these at a different opacity.
    # =================================================================

    NearBlack : color = MakeColorFromHex("0F1216")
    ConcreteGray : color = MakeColorFromHex("6E7580")
    HazardYellow : color = MakeColorFromHex("FFDD1C")
    DangerRed : color = MakeColorFromHex("FF3B30")
    HotPink : color = MakeColorFromHex("FF2D95")
    PrizeGold : color = MakeColorFromHex("FFC233")

    # =================================================================
    # WIRING
    # =================================================================

    # The three numbers on the card come from the devices that own them rather
    # than being counted twice here.
    @editable
    CashDrops : cash_drop_manager = cash_drop_manager{}

    @editable
    Waves : wave_manager = wave_manager{}

    @editable
    CareerRank : career_rank_manager = career_rank_manager{}

    # RETIRED BY AMENDMENT 86 and activated by nothing now. The field stays
    # because it is wired to a placed End Game device and removing it would
    # unwire that device. See LeaveTheShow at the bottom of this file for the
    # working way to end a match, if it is ever wanted again.
    @editable
    RunEnder : end_game_device = end_game_device{}

    # -- sound ---------------------------------------------------------
    #
    # ALL FIVE ARE PLACED AUDIO PLAYER DEVICES, and loudness lives on them, not
    # here: Verse cannot set a volume at all. Two traps, both already paid for
    # once on this project. Attenuation makes a device fade with distance from
    # where it sits, so these want it off. And a fresh device defaults Enabled
    # During Phase to None, which means it does nothing during gameplay.

    # The losing buzzer. GDD 2.5's game-show buzzer, and the first thing heard.
    @editable
    Buzzer : audio_player_device = audio_player_device{}

    # Canned applause, straight after the buzzer. The audience does not care
    # either.
    @editable
    Applause : audio_player_device = audio_player_device{}

    # The heavy clunk, played on the frame the rank lands and NOT before. Kai
    # was specific about this and it is the whole reason the stamp reads as
    # weight rather than as a fade.
    @editable
    StampClunk : audio_player_device = audio_player_device{}

    # The ding on each stats row as it finishes counting. The cash pickup's
    # ding-ding-ding is the obvious candidate to point this at.
    @editable
    RowDing : audio_player_device = audio_player_device{}

    # The host's line, which Kai wrote: "THEY WERE GREAT TELEVISION, FOLKS!
    # WHO'S NEXT?" VOICE ONLY. It must never appear on screen as text.
    #
    # Announcer dialogue is Kai's to write and only Kai's. This field points at
    # a recording; nothing in this file generates, rewrites or displays a word
    # of it. If the recording does not exist yet, leave this unset and the card
    # simply plays without it.
    @editable
    HostVoice : audio_player_device = audio_player_device{}

    # -- the hostiles' team --------------------------------------------

    # Which team the hostiles are on, as an index into the playspace's team
    # list. Moving the contestant onto it at run end is what stops the guards
    # attacking a contestant who can no longer fight back.
    #
    # IT IS AN EDITABLE BECAUSE THE INDEX IS NOT KNOWABLE FROM CODE. The team
    # list is built from Island Settings, and nothing in the digest names the
    # teams. If the robots keep shooting the frozen contestant, this is the
    # number to change, and the log line at run end says how many teams there
    # were to choose from.
    @editable
    HostileTeamIndex : int = 1

    # =================================================================
    # DIALS
    # =================================================================

    # The whole performance, in seconds, from buzzer to buttons. Kai's brief
    # says about six.
    @editable
    BannerSlamSeconds : float = 0.35

    @editable
    RowCountSeconds : float = 0.35

    @editable
    RowGapSeconds : float = 0.12

    @editable
    StampSeconds : float = 0.25

    # THE BEATS BETWEEN THE MOMENTS, which used to be bare numbers typed into
    # the middle of the sequence. Found in the 2026-08-26 audit: the timing IS
    # the performance here, and it was the one part of the card that could not
    # be tuned without a rebuild.
    @editable
    ApplauseAfterBuzzerSeconds : float = 0.4

    @editable
    HostVoiceAfterApplauseSeconds : float = 0.6

    @editable
    StatsBeginSeconds : float = 0.25

    @editable
    ButtonsAfterStampSeconds : float = 0.3

    # How long the stamp sits at its overshoot before settling. Short on
    # purpose: a slow recovery reads as a wobble rather than as weight.
    @editable
    StampSpringSeconds : float = 0.08

    # How dim the arena goes behind the card. 0.7 leaves the arena showing at
    # about 30 per cent, which is Kai's brief.
    @editable
    DimAmount : float = 0.7

    @editable
    TickerStepSeconds : float = 0.07

    @editable
    TickerWindowChars : int = 120

    # How many steps the slam and the stamp are drawn in. Higher is smoother and
    # costs more; the slam rebuilds a canvas slot on every step.
    #
    # IT IS A FLOAT ON PURPOSE. Verse will not turn a whole number into a
    # fraction for you, so every eased fraction below would need a conversion
    # that the language does not provide. Held as a float, the easing is pure
    # float arithmetic and only the loop count is rounded back to a whole
    # number, once, in StepCount.
    @editable
    AnimationSteps : float = 10.0

    StepCount()<transacts>:int =
        if (Count := Round[AnimationSteps], Count > 0):
            return Count
        10

    # Opacity is typed to 0 through 1 and nothing else, so anything handed to it
    # comes through here first.
    #
    # WHY THIS IS NOT JUST A COMPARISON. The compiler can prove a literal like
    # 0.55 is in range, but it cannot prove anything about a number that was
    # added up at runtime, so a plain float is refused where an opacity is
    # wanted. The cast on the last line is the ask-and-check version, and the
    # two guards above mean it is only ever reached with a value already inside
    # the range.
    Clamped(Value : float)<transacts>:unit_float =
        if (Value <= 0.0):
            return 0.0
        if (Value >= 1.0):
            return 1.0
        if (Safe := unit_float[Value]):
            return Safe
        1.0

    @editable
    ScanlineCount : int = 60

    # =================================================================
    # THE WORDS
    #
    # All of it is Kai's copy. None of it is generated and none of it should be
    # rewritten without asking.
    # =================================================================

    ChannelLine : string = "CH 07 // THE NETWORK"
    # REMOVED 2026-08-31 unused - restore if something breaks
    # LiveLine : string = "LIVE"
    BannerWords : string = "THAT'S OUR SHOW!"

    RowOneLabel : string = "ROUNDS SURVIVED"
    RowTwoLabel : string = "CASH EARNED"
    RowThreeLabel : string = "ROBOTS SCRAPPED"

    FinePrint : string = "Contestant remains property of the Network. Winnings subject to broadcast fees, equipment damage and applicable taxes."

    PlayAgainLine : string = "PLAY AGAIN"
    LeaveLine : string = "LEAVE THE SHOW"

    TickerLine : string = "TONIGHT'S EPISODE BROUGHT TO YOU BY ZORP MEAT PASTE * BRAND-O TOASTERS: IT'S A TOASTER * THE NETWORK IS NOT LIABLE FOR CONTESTANT REMAINS * VITA-GLOW SUNLAMPS, SQUINT AND WIN * NOW CASTING SEASON 9, NO EXPERIENCE REQUIRED, NO REFUNDS * NEXT ON CHANNEL 07: MORE OF THIS * "

    # =================================================================
    # STATE
    # =================================================================

    var CardIsUp : logic = false

    # WHETHER THE RESULTS CARD IS ON SCREEN. Public because the announcer's
    # caption has to get out of its way: Kai, 2026-08-31, "It also currently
    # draws on top of the end-of-match results screen (ROUNDS SURVIVED / CASH
    # EARNED / ROBOTS SCRAPPED). Hide the caption while that results screen is
    # showing." The sign-off line still plays; it simply plays unseen, which is
    # the right way round for a host talking over your own scoreboard.
    IsShowing<public>()<transacts>:logic = CardIsUp

    var Root : ?canvas = false
    var BannerText : ?text_block = false
    # REMOVED 2026-08-31 unused - restore if something breaks
    # var BannerSlot : ?text_block = false

    var RowOneValue : ?text_block = false
    var RowTwoValue : ?text_block = false
    var RowThreeValue : ?text_block = false

    var StampText : ?text_block = false
    var StampBox : ?color_block = false

    var ButtonRow : ?stack_box = false

    var TickerLabel : ?text_block = false
    var TickerHead : int = 0
    var TickerDoubled : string = ""
    var TickerLoopLength : int = 0

    # The team the contestant started on, so a future PLAY AGAIN can put them
    # back. Written the moment they are moved off it.
    var OriginalTeam : ?team = false

    OnBegin<override>()<suspends>:void =
        # NOTHING HAPPENS AT MATCH START. This device draws only when the run is
        # lost, so it deliberately does not call AwaitMatchStart: there is no
        # loop here to hold back.
        set TickerDoubled = "{TickerLine}{TickerLine}"
        set TickerLoopLength = TickerLine.Length
        Log("DEBUG: Game over screen ready.")

    # =================================================================
    # THE ENTRY POINT
    #
    # DeathSaveManager calls this instead of ending the match.
    # =================================================================

    Show<public>(P : player):void =
        if (CardIsUp?):
            # A second fatal blow while the card is already up. Ignore it rather
            # than drawing a second card over the first.
            return

        set CardIsUp = true
        spawn{ RunShow(P) }

    RunShow(P : player)<suspends>:void =
        # THE RUN IS BANKED BEFORE ANYTHING IS READ. OnRunEnded promotes the
        # rank, and the stamp has to show the rank the player leaves with, not
        # the one they arrived with.
        # PROBE, 2026-08-29. See the note in CareerRankManager.OnRunEnded. This
        # is the same pair of numbers read through THIS device's own slots, a
        # line before the career manager reads them through its own.
        Log("DEBUG: PROBE card read -- score {CashDrops.GetRunScore()}, rooms {Waves.GetRoomsWon()}, tier {Waves.GetCurrentTier()}")
        Log("DEBUG: PROBE card sees cash manager stamp {CashDrops.GetDeviceStamp()} -- 7 is the placed one, 0 is a stand-in")

        CareerRank.OnRunEnded(P)

        FreezeContestant(P)
        BuildCard(P)

        Buzzer.Play()
        spawn{ RunTicker() }

        Sleep(ApplauseAfterBuzzerSeconds)
        Applause.Play()
        spawn{ SlamBanner() }

        Sleep(HostVoiceAfterApplauseSeconds)
        HostVoice.Play()

        Sleep(StatsBeginSeconds)
        CountRow(RowOneValue, Waves.GetRoomsWon())
        Sleep(RowGapSeconds)
        CountRow(RowTwoValue, CashDrops.GetRunScore())
        Sleep(RowGapSeconds)
        CountRow(RowThreeValue, Waves.GetRunEliminations())

        Sleep(RowGapSeconds)
        StampRank(P)

        Sleep(ButtonsAfterStampSeconds)
        if (Row := ButtonRow?):
            Row.SetVisibility(widget_visibility.Visible)

        Log("DEBUG: Game over card finished its run-in.")

    # =================================================================
    # FREEZING THE CONTESTANT
    # =================================================================

    FreezeContestant(P : player):void =
        # Stasis holds them exactly where they stand. The defaults stop
        # movement; turning and emotes stay allowed, which does no harm because
        # their input is about to be pointed at a pair of buttons anyway.
        if (Character := P.GetFortCharacter[]):
            Character.PutInStasis(stasis_args{})
            Log("DEBUG: Contestant frozen in place.")
        else:
            Log("WARNING: no character to freeze at run end. The contestant was already eliminated.")

        # ONTO THE ROBOTS' TEAM, which is the only way to make guards lose
        # interest. There is no "ignore this thing" anywhere in the digest:
        # npc_awareness_component and its neighbours are all epic_internal.
        Collection := GetPlayspace().GetTeamCollection()
        Teams := Collection.GetTeams()
        Log("DEBUG: {Teams.Length} teams in this playspace; moving the contestant to index {HostileTeamIndex}.")

        if (Current := Collection.GetTeam[P]):
            set OriginalTeam = option{Current}

        if (Target := Teams[HostileTeamIndex]):
            if (Collection.AddToTeam[P, Target]):
                Log("DEBUG: Contestant moved onto the hostiles' team.")
            else:
                Log("WARNING: the contestant could not be moved onto team {HostileTeamIndex}. The robots will keep attacking.")
        else:
            Log("WARNING: there is no team at index {HostileTeamIndex}. Check HostileTeamIndex against the count above.")

    # =================================================================
    # BUILDING THE CARD
    # =================================================================

    BuildCard(P : player):void =
        # The dim sheet. Near black at 0.7 leaves the arena readable underneath
        # at about 30 per cent, which is the brief. It is also what gives this
        # canvas the screen's own size: a canvas holding only pinned widgets
        # shrinks to fit them, and every anchor below would then be measured
        # across the words rather than across the screen.
        # Clamped, because an opacity is typed to 0 through 1 and a dial on the
        # Details panel can be set to anything at all.
        Dim := color_block:
            DefaultColor := NearBlack
            DefaultOpacity := Clamped(DimAmount)

        Card := canvas:
            Slots := array:
                canvas_slot:
                    Widget := Dim
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 0

                # -- CH 07 // THE NETWORK, top left ---------------------
                canvas_slot:
                    Widget := SmallLabel(ChannelLine, ConcreteGray)
                    Anchors := anchors{Minimum := vector2{X := 0.03, Y := 0.04}, Maximum := vector2{X := 0.03, Y := 0.04}}
                    Alignment := vector2{X := 0.0, Y := 0.0}
                    ZOrder := 6

                # THE RED DOT AND LIVE ARE NOT HERE. Kai's ruling on seeing it:
                # the arena already carries a LIVE badge of its own, and it is
                # still on screen behind this card, so a second one in the
                # opposite corner reads as a mistake rather than as a flourish.
                # BuildLiveBadge is kept below in case the arena's badge ever
                # goes away.

                # -- the stats panel ------------------------------------
                canvas_slot:
                    Widget := BuildStatsPanel()
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.44}, Maximum := vector2{X := 0.5, Y := 0.44}}
                    Alignment := vector2{X := 0.5, Y := 0.0}
                    ZOrder := 4

                # -- the rank stamp -------------------------------------
                canvas_slot:
                    Widget := BuildStamp()
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.66}, Maximum := vector2{X := 0.5, Y := 0.66}}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    ZOrder := 5

                # -- the fine print -------------------------------------
                canvas_slot:
                    Widget := SmallLabel(FinePrint, ConcreteGray)
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.74}, Maximum := vector2{X := 0.5, Y := 0.74}}
                    Alignment := vector2{X := 0.5, Y := 0.0}
                    ZOrder := 4

                # -- the two buttons ------------------------------------
                #
                # ABOVE THE SCANLINES, AND THAT IS THE WHOLE REASON THEY WORK.
                # At ZOrder 5 they sat under the scanline sheet, which covers
                # the entire screen at 8, and a click never reached them: the
                # card drew, the buttons showed, and pressing them did nothing
                # at all. A layer over a button eats the button. 20 puts them
                # above every sheet on this card.
                canvas_slot:
                    Widget := BuildButtons()
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.83}, Maximum := vector2{X := 0.5, Y := 0.83}}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    ZOrder := 20

                # -- the ticker, along the very bottom ------------------
                canvas_slot:
                    Widget := BuildTicker()
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.94}, Maximum := vector2{X := 1.0, Y := 0.965}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 7

                # -- scanlines over everything --------------------------
                canvas_slot:
                    Widget := BuildScanlines(ScanlineCount)
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 8

                # -- the hazard stripe on the very bottom edge ----------
                canvas_slot:
                    Widget := BuildHazardBar()
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.965}, Maximum := vector2{X := 1.0, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 9

        set Root = option{Card}

        # THE BANNER IS ADDED SEPARATELY, because the slam moves it. A canvas
        # slot's anchor is fixed when the slot is made, so the only way to move
        # a widget is to take it out and put it back somewhere else, which needs
        # a handle on the canvas.
        Card.AddWidget(BannerSlotAt(-0.2))

        # THE MOUSE IS TAKEN HERE, AND THIS IS THE ONE LAYER ALLOWED TO DO IT.
        # The buttons need a pointer. See the header for why every other layer
        # over the arena says None.
        if (UI := GetPlayerUI[P]):
            UI.AddWidget(Card, player_ui_slot{ZOrder := 200, InputMode := ui_input_mode.All})
            Log("DEBUG: Game over card drawn.")
        else:
            Log("WARNING: the game over card could not be drawn for this contestant.")

    # -- the pieces ----------------------------------------------------

    SmallLabel(Content : string, Shade : color) : text_block =
        text_block:
            DefaultText := ScreenLine(Content)
            DefaultTextColor := Shade
            DefaultTextSize := 22.0
            DefaultJustification := text_justification.Center

    # REMOVED 2026-08-31 unused - restore if something breaks
    # BuildLiveBadge() : stack_box =
    #     Dot := color_block:
    #         DefaultColor := DangerRed
    #         DefaultOpacity := 1.0
    #         DefaultDesiredSize := vector2{X := 18.0, Y := 18.0}
    #
    #     Word := text_block:
    #         DefaultText := ScreenLine(LiveLine)
    #         DefaultTextColor := DangerRed
    #         DefaultTextSize := 26.0
    #         DefaultJustification := text_justification.Left
    #
    #     stack_box:
    #         Orientation := orientation.Horizontal
    #         Slots := array:
    #             stack_box_slot:
    #                 Widget := Dot
    #                 VerticalAlignment := vertical_alignment.Center
    #                 Padding := margin{Left := 0.0, Top := 0.0, Right := 10.0, Bottom := 0.0}
    #             stack_box_slot:
    #                 Widget := Word
    #                 VerticalAlignment := vertical_alignment.Center
    #                 Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

    # THE BANNER, and the starburst behind it.
    #
    # The rays are stacked bars of alternating width following a round profile,
    # the same trick the broadcast's popups use. It is not a true starburst and
    # it does not need to be: at this size and behind solid lettering, the eye
    # reads the ragged edge as rays.
    BuildBanner() : overlay =
        Rays := BuildStarburst()

        Words := text_block:
            DefaultText := ScreenLine(BannerWords)
            DefaultTextColor := HazardYellow
            DefaultTextSize := 92.0
            DefaultJustification := text_justification.Center

        # The chrome is faked with a pink shadow word sitting a few pixels off
        # behind the yellow one. Two flat colours reading as one lit edge.
        Fringe := text_block:
            DefaultText := ScreenLine(BannerWords)
            DefaultTextColor := HotPink
            DefaultTextSize := 92.0
            DefaultJustification := text_justification.Center

        set BannerText = option{Words}

        overlay:
            Slots := array:
                overlay_slot:
                    Widget := Rays
                    HorizontalAlignment := horizontal_alignment.Center
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                # Four pixels, not eight. At eight the pink copy read as a
                # second word printed badly rather than as a lit edge.
                overlay_slot:
                    Widget := Fringe
                    HorizontalAlignment := horizontal_alignment.Center
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 4.0, Top := 4.0, Right := 0.0, Bottom := 0.0}
                overlay_slot:
                    Widget := Words
                    HorizontalAlignment := horizontal_alignment.Center
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

    BuildStarburst() : stack_box =
        var Rows : []stack_box_slot = array{}

        # Written out rather than divided, for the reason in RayWidth. Eleven
        # rays put the widest one at six.
        RayCount := 11
        MiddleRay := 6

        # WHAT WAS WRONG WITH THE FIRST ONE, on Kai's report of seeing it. Every
        # row was painted, in alternating pink and gold, at better than half
        # opacity and twenty-two pixels tall. Thirteen of those is a solid slab
        # nearly three hundred pixels high sitting behind the words, which reads
        # as a coloured brick, not as a burst.
        #
        # WHAT MAKES IT READ AS RAYS. Every other row is left CLEAR. A ray needs
        # a gap beside it or it is just part of the block next to it, and the
        # gap has to be real transparency rather than a darker shade, because a
        # dark row over a dark card is another band. They are also thinner and
        # much dimmer, so the lettering stays the brightest thing on the card.
        for (Index := 1..RayCount):
            # The Mod stays inside the if, where a failable call is allowed.
            # Pulled out onto a line of its own it does not compile.
            Ray := color_block:
                DefaultColor := if (Index = MiddleRay) then HotPink else PrizeGold
                DefaultOpacity := if (Mod[Index, 2] = 1) then 0.30 else 0.0
                DefaultDesiredSize := vector2{X := RayWidth(Index, MiddleRay), Y := 14.0}

            set Rows += array{stack_box_slot{Widget := Ray, HorizontalAlignment := horizontal_alignment.Center}}

        stack_box:
            Orientation := orientation.Vertical
            Slots := Rows

    # How wide one ray is: widest across the middle of the burst, narrowing
    # towards both ends.
    #
    # THE NARROWING IS COUNTED RATHER THAN MULTIPLIED because Verse will not
    # multiply a whole number by a fraction without a conversion it does not
    # offer. Six additions at most, once, while the card is being built.
    #
    # THE MIDDLE IS HANDED IN RATHER THAN WORKED OUT. Dividing to find it would
    # make this function failable, because in Verse every division can fail and
    # has to sit inside an if. The caller knows both numbers already.
    #
    # AND IT IS NOT CALLED Distance. SpatialMath owns that name three times over
    # and the first build refused the file for it.
    RayWidth(Index : int, Middle : int)<transacts>:float =
        var StepsOut : int = Index - Middle
        if (StepsOut < 0):
            set StepsOut = -StepsOut

        var Shrink : float = 0.0
        for (Step := 1..StepsOut):
            set Shrink = Shrink + 110.0

        900.0 - Shrink

    # THE STATS PANEL. Three rows, label on the left and value on the right, all
    # three starting at zero and counted up one at a time.
    # Each row is built and its value block claimed straight afterwards. A row
    # hands its value back through LastMadeValue rather than returning a pair,
    # because a Verse function returns one thing and the row itself is what the
    # panel needs.
    BuildStatsPanel() : stack_box =
        One := StatRow(RowOneLabel)
        set RowOneValue = LastMadeValue

        Two := StatRow(RowTwoLabel)
        set RowTwoValue = LastMadeValue

        Three := StatRow(RowThreeLabel)
        set RowThreeValue = LastMadeValue

        stack_box:
            Orientation := orientation.Vertical
            Slots := array:
                stack_box_slot{Widget := One, HorizontalAlignment := horizontal_alignment.Fill, Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 14.0}}
                stack_box_slot{Widget := Two, HorizontalAlignment := horizontal_alignment.Fill, Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 14.0}}
                stack_box_slot{Widget := Three, HorizontalAlignment := horizontal_alignment.Fill, Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}}

    var LastMadeValue : ?text_block = false

    StatRow(Label : string) : stack_box =
        Name := text_block:
            DefaultText := ScreenLine(Label)
            DefaultTextColor := ConcreteGray
            DefaultTextSize := 34.0
            DefaultJustification := text_justification.Left

        Value := text_block:
            DefaultText := ScreenLine("0")
            DefaultTextColor := PrizeGold
            DefaultTextSize := 40.0
            DefaultJustification := text_justification.Right

        set LastMadeValue = option{Value}

        stack_box:
            Orientation := orientation.Horizontal
            Slots := array:
                stack_box_slot:
                    Widget := Name
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 40.0, Bottom := 0.0}
                    Distribution := option{1.0}
                stack_box_slot:
                    Widget := Value
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

    # THE RANK STAMP. A red box with the rank in it, both starting invisible and
    # oversized so the slam has somewhere to come from.
    BuildStamp() : overlay =
        Box := color_block:
            DefaultColor := DangerRed
            DefaultOpacity := 0.0
            DefaultDesiredSize := vector2{X := 760.0, Y := 96.0}

        Words := text_block:
            DefaultText := ScreenLine("FINAL RANK:")
            DefaultTextColor := HazardYellow
            DefaultTextSize := 108.0
            DefaultTextOpacity := 0.0
            DefaultJustification := text_justification.Center

        set StampBox = option{Box}
        set StampText = option{Words}

        overlay:
            Slots := array:
                overlay_slot:
                    Widget := Box
                    HorizontalAlignment := horizontal_alignment.Center
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                overlay_slot:
                    Widget := Words
                    HorizontalAlignment := horizontal_alignment.Center
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 24.0, Top := 8.0, Right := 24.0, Bottom := 8.0}

    BuildButtons() : stack_box =
        PlayAgain := BigButton(PlayAgainLine, PrizeGold, NearBlack, 44.0, 420.0)
        PlayAgain.OnClick().Subscribe(OnPlayAgainPressed)

        Leave := BigButton(LeaveLine, ConcreteGray, NearBlack, 30.0, 300.0)
        Leave.OnClick().Subscribe(OnLeavePressed)

        Row := stack_box:
            Orientation := orientation.Horizontal
            Slots := array:
                stack_box_slot:
                    Widget := PlayAgain
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 32.0, Bottom := 0.0}
                stack_box_slot:
                    Widget := Leave
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

        # THE BUTTONS ARRIVE LAST, per the brief. Built now and hidden, because
        # a widget added to a canvas later cannot be placed as precisely.
        Row.SetVisibility(widget_visibility.Collapsed)
        set ButtonRow = option{Row}
        Row

    BigButton(Label : string, Fill : color, Ink : color, TextSize : float, Width : float) : button =
        Back := color_block:
            DefaultColor := Fill
            DefaultOpacity := 1.0
            DefaultDesiredSize := vector2{X := Width, Y := 78.0}

        Words := text_block:
            DefaultText := ScreenLine(Label)
            DefaultTextColor := Ink
            DefaultTextSize := TextSize
            DefaultJustification := text_justification.Center

        # NAMED ButtonFace, NOT Face. The announcer's portrait frames live in
        # a content folder called Face, which UEFN exposes as a Verse module of
        # that name, and a local called Face clashes with it. Script error 3588.
        ButtonFace := overlay:
            Slots := array:
                overlay_slot:
                    Widget := Back
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                overlay_slot:
                    Widget := Words
                    HorizontalAlignment := horizontal_alignment.Center
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 20.0, Top := 0.0, Right := 20.0, Bottom := 0.0}

        button:
            Slot := button_slot:
                Widget := ButtonFace
                HorizontalAlignment := horizontal_alignment.Fill
                VerticalAlignment := vertical_alignment.Fill
                Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

    BuildTicker() : overlay =
        Strip := color_block:
            DefaultColor := NearBlack
            DefaultOpacity := 0.9

        Words := text_block:
            DefaultText := ScreenLine(TickerLine)
            DefaultTextColor := HazardYellow
            DefaultTextSize := 24.0
            DefaultJustification := text_justification.Left

        set TickerLabel = option{Words}

        overlay:
            Slots := array:
                overlay_slot:
                    Widget := Strip
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                overlay_slot:
                    Widget := Words
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 18.0, Top := 0.0, Right := 18.0, Bottom := 0.0}

    # Lighter than the ground, not darker. Near-black lines on a near-black card
    # are invisible, which is a mistake this project has already made once.
    BuildScanlines(LineCount : int) : stack_box =
        var Lines : []stack_box_slot = array{}

        for (Index := 1..LineCount):
            Bar := color_block:
                DefaultColor := ConcreteGray
                DefaultOpacity := 0.10
                DefaultDesiredSize := vector2{X := 8.0, Y := 2.0}

            set Lines += array{stack_box_slot{Widget := Bar, HorizontalAlignment := horizontal_alignment.Fill, VerticalAlignment := vertical_alignment.Top, Distribution := option{1.0}}}

        stack_box:
            Orientation := orientation.Vertical
            Slots := Lines

    # A flat yellow and black hazard bar. The broadcast's version is slanted
    # with a stack of nudged rows; this one is a single row along a 3 per cent
    # strip, where a slant would only read as a smear.
    BuildHazardBar() : stack_box =
        var Cells : []stack_box_slot = array{}

        for (Index := 1..24):
            Shade := if (Mod[Index, 2] = 0) then HazardYellow else NearBlack

            Block := color_block:
                DefaultColor := Shade
                DefaultOpacity := 1.0
                DefaultDesiredSize := vector2{X := 40.0, Y := 20.0}

            set Cells += array{stack_box_slot{Widget := Block, HorizontalAlignment := horizontal_alignment.Fill, VerticalAlignment := vertical_alignment.Fill, Distribution := option{1.0}}}

        stack_box:
            Orientation := orientation.Horizontal
            Slots := Cells

    # =================================================================
    # THE PERFORMANCE
    # =================================================================

    # The banner's slot at a given height down the screen. Remade on every step
    # of the slam, because a slot's anchor cannot be changed once it is built.
    BannerSlotAt(Height : float) : canvas_slot =
        canvas_slot:
            Widget := BannerHolder()
            Anchors := anchors{Minimum := vector2{X := 0.5, Y := Height}, Maximum := vector2{X := 0.5, Y := Height}}
            Alignment := vector2{X := 0.5, Y := 0.5}
            ZOrder := 3

    var HeldBanner : ?overlay = false

    BannerHolder() : overlay =
        if (Existing := HeldBanner?):
            return Existing
        Made := BuildBanner()
        set HeldBanner = option{Made}
        Made

    # SLAMS IN FROM THE TOP. It starts above the screen and is taken out and put
    # back a little lower on each step, easing as it arrives.
    SlamBanner()<suspends>:void =
        # THE TWO DIVISIONS SIT IN THE IF ON PURPOSE. In Verse every division can
        # fail, floats included, so one cannot stand on a line of its own. Both
        # are done once here rather than per step.
        if (Card := Root?, Step := BannerSlamSeconds / AnimationSteps, Increment := 1.0 / AnimationSteps):
            Start := -0.2
            Finish := 0.22
            Count := StepCount()

            var Fraction : float = 0.0
            for (Index := 1..Count):
                set Fraction = Fraction + Increment
                # Eased, so it arrives heavily rather than at a constant crawl.
                Eased := 1.0 - ((1.0 - Fraction) * (1.0 - Fraction))
                Height := Start + (Finish - Start) * Eased

                if (Held := HeldBanner?):
                    Card.RemoveWidget(Held)
                Card.AddWidget(BannerSlotAt(Height))
                Sleep(Step)

    # Counts a row up from zero, then dings. The ding is on the finish rather
    # than the start, so it reads as the number landing.
    CountRow(Slot : ?text_block, Target : int)<suspends>:void =
        if (Label := Slot?, Step := RowCountSeconds / AnimationSteps):
            Count := StepCount()

            for (Index := 1..Count):
                # QUOTIENT, NOT A SLASH. Dividing two whole numbers with / gives
                # a rational, which is not a whole number of dollars and which
                # Floor then refused to take. Quotient is the whole-number
                # division, and like every division in Verse it can fail, which
                # is why it sits in an if.
                if (Shown := Quotient[Target * Index, Count]):
                    Label.SetText(ScreenLine(Commas(Shown)))
                Sleep(Step)

            Label.SetText(ScreenLine(Commas(Target)))
            RowDing.Play()

    # THE STAMP. Kai's brief in four beats: it starts about three times size and
    # fully transparent, it drops to full opacity as it shrinks, it lands
    # slightly SMALLER than its final size, then springs back slightly LARGER,
    # then settles. The squash and the overshoot are what sell the weight.
    #
    # THE CLUNK PLAYS ON THE FRAME IT LANDS, not before. That is the whole
    # effect: sound before impact reads as a fade with a noise over it.
    StampRank(P : player)<suspends>:void =
        Title := CareerRank.GetRankTitle(P)

        if (Words := StampText?, Box := StampBox?, Step := StampSeconds / AnimationSteps, Increment := 1.0 / AnimationSteps):
            Words.SetText(ScreenLine("FINAL RANK: {Title}"))

            Settled := 54.0
            Start := Settled * 3.0
            Squashed := Settled * 0.88
            Sprung := Settled * 1.08

            Count := StepCount()

            # The drop: three times size down to slightly under, fading in as it
            # comes.
            var Fraction : float = 0.0
            for (Index := 1..Count):
                set Fraction = Fraction + Increment
                Eased := Fraction * Fraction
                Size := Start + (Squashed - Start) * Eased

                Words.SetTextSize(Size)
                # CLAMPED, and not out of tidiness. Opacity is typed as nothing
                # outside 0 to 1, and ten additions of a tenth can land a hair
                # over one, which is a runtime error rather than a rounding
                # nuisance.
                Words.SetTextOpacity(Clamped(Fraction))
                Box.SetOpacity(Clamped(Fraction * 0.9))
                Box.SetDesiredSize(vector2{X := 760.0, Y := Size * 1.8})
                Sleep(Step)

            # IT LANDS HERE. The clunk goes on this line and nowhere earlier.
            StampClunk.Play()

            # The spring back, over and then to rest. Deliberately quicker than
            # the drop, because a slow recovery reads as a wobble.
            Words.SetTextSize(Sprung)
            Box.SetDesiredSize(vector2{X := 760.0, Y := Sprung * 1.8})
            Sleep(StampSpringSeconds)

            Words.SetTextSize(Settled)
            Box.SetDesiredSize(vector2{X := 760.0, Y := Settled * 1.8})

    RunTicker()<suspends>:void =
        loop:
            Sleep(TickerStepSeconds)

            if (not CardIsUp?):
                break

            set TickerHead += 1
            if (TickerHead >= TickerLoopLength):
                set TickerHead = 0

            if (Label := TickerLabel?, Window := TickerDoubled.Slice[TickerHead, TickerHead + TickerWindowChars]):
                Label.SetText(ScreenLine(Window))

    # =================================================================
    # THE BUTTONS
    #
    # BOTH END THE MATCH FOR NOW. Temporary, by Kai's instruction, so the
    # performance can be watched before anything about restarting changes. The
    # tidy-up that replaces both of these is the next piece of work, and when it
    # lands the card must be taken down and the mouse handed back, or aiming
    # will be gone for the next run.
    # =================================================================

    # THE TWO BUTTONS DO DIFFERENT THINGS NOW, amendment 86. Kai's ruling
    # 2026-08-26, which reverses the earlier one: PLAY AGAIN drops the
    # contestant straight back into a fresh run at Tier 1, and LEAVE THE SHOW
    # puts them back on the broadcast, watching telly instead of being on it.
    #
    # NEITHER ONE ENDS THE MATCH ANY MORE. Anyone who wants out of the island
    # leaves through Fortnite's own menu, which is tidier than dropping them on
    # Fortnite's end-of-match screen.
    OnPlayAgainPressed(Message : widget_message):void =
        if (P := player[Message.Player]):
            Log("DEBUG: PLAY AGAIN pressed.")
            spawn{ RestartRun(P) }

    OnLeavePressed(Message : widget_message):void =
        if (P := player[Message.Player]):
            Log("DEBUG: LEAVE THE SHOW pressed.")
            BackToTheBroadcast(P)

    # PLAY AGAIN. The gap in the middle is not padding: every manager looks at
    # the gate every tenth of a second and AwaitMatchStart waits half a second
    # before its first look, so closing and reopening in the same breath would
    # be missed entirely and nothing would ever restart.
    RestartRun(P : player)<suspends>:void =
        TakeCardDown(P)
        EndRunForAll(Self)
        Sleep(1.0)
        BeginRunForAll(Self)
        Log("DEBUG: PLAY AGAIN -- a fresh run has been started.")

    # LEAVE THE SHOW. The gate stays shut, so the broadcast comes back up on its
    # own and the contestant is a viewer again.
    BackToTheBroadcast(P : player):void =
        TakeCardDown(P)
        EndRunForAll(Self)
        Log("DEBUG: LEAVE THE SHOW -- back to the broadcast.")

    # THE CARD MUST COME DOWN AND THE MOUSE MUST GO BACK, both, every time.
    # This card is the one layer allowed to take the pointer, and a card that
    # never leaves never gives it back, which reads in play as aiming being
    # broken. That mistake has been made twice on this project already.
    TakeCardDown(P : player):void =
        if (Home := OriginalTeam?):
            Collection := GetPlayspace().GetTeamCollection()
            if (Collection.AddToTeam[P, Home]):
                Log("DEBUG: Contestant put back on their own team.")

        if (UI := GetPlayerUI[P], Card := Root?):
            UI.RemoveWidget(Card)
            Log("DEBUG: Game over card taken down.")

        ThawContestant(P)
        set CardIsUp = false

    # THE OTHER HALF OF FreezeContestant, AND LEAVING IT OUT REPLAYED THE CARD.
    #
    # The first PLAY AGAIN put the waves back to Tier 1 and then the score card
    # came straight back up. The contestant was still held in stasis on zero
    # health, so the moment the run restarted the fatal blow was still in force
    # and the death fired again. Freezing without thawing is a bug on its own:
    # the run cannot be played from inside stasis whichever button was pressed.
    #
    # HEALTH GOES BACK BEFORE THE GATE REOPENS. RestartRun waits a second
    # between closing and opening the gate, and this happens first, so the
    # Death Save has nothing to catch by the time the next run begins.
    ThawContestant(P : player):void =
        if (Character := P.GetFortCharacter[]):
            Character.ReleaseFromStasis()
            Character.SetHealth(Character.GetMaxHealth())
            Log("DEBUG: Contestant released from stasis and healed to full.")
        else:
            Log("WARNING: no character to thaw. The contestant was already eliminated.")

    # RETIRED BY AMENDMENT 86 AND NOTHING CALLS THIS ANY MORE. Neither button
    # ends the match now. It is kept, with its device, for two reasons: the
    # @editable above is wired to a placed End Game device and deleting the
    # field would unwire it, and the paragraph below is the only written record
    # of why that device needs the contestant's team put back first. If ending
    # the match is ever wanted again, this is the working way to do it.
    #
    # THE TEAM GOES BACK FIRST, AND THAT ORDER IS THE WHOLE FIX.
    #
    # The first playtest with working buttons pressed them seven times and the
    # match never ended, while the log recorded every press. The End Game device
    # decides what to end from the team of the agent that activates it, and by
    # then the contestant had been moved onto the hostiles' team so the card
    # could be watched in peace. Handing that device a contestant on the robots'
    # team asks it to end something it has no answer for, so it does nothing.
    #
    # The card being stuck is also why aiming appeared to break: this card takes
    # the mouse on purpose, and a card that never goes away never gives it back.
    LeaveTheShow(P : player):void =
        if (Home := OriginalTeam?):
            Collection := GetPlayspace().GetTeamCollection()
            if (Collection.AddToTeam[P, Home]):
                Log("DEBUG: Contestant put back on their own team.")
            else:
                Log("WARNING: the contestant could not be put back on their own team. The match may refuse to end.")
        else:
            Log("WARNING: no original team was recorded, so there is nothing to put the contestant back on.")

        RunEnder.Activate(P)
