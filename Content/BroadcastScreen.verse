# BroadcastScreen.verse
#
# GDD Section 2.1 "Core Gameplay Loop" and amendment 18 "There is no main menu
# to put the title card on". This is the title screen, built as a television
# broadcast rather than a menu: the contestant is watching a channel, not
# choosing options.
#
# BUILD ITEMS 1, 2, 9, 3, 4 AND 5. The brief Kailee gave on 2026-08-24 has nine
# numbered items, to be built one at a time in a set order. Done here: 1 the
# title screen, 2 sound, 9 the ON AIR light, 3 the sponsor ticker, 4 channel
# flicker with static, 5 the debt counter, 6 the legal fine print, and 8 the TV
# listings framing with its ONE dead channel. Still owed: 7 please stand by.
#
# TWO OF KAI'S CHANGES ON TOP OF THE BRIEF. The fine print does not sit along
# the bottom edge all the time; it appears only while the mouse rests on START
# SHOW. And only START SHOW buzzes: the schedule buttons are silent.
#
# Also owed, and parked by Kai rather than forgotten: hiding Fortnite's own
# minimap out of the ON AIR light's corner. Kai's ruling was to do it in code
# here rather than place a HUD Controller device, and to leave it until later.
#
# THIS FILE REPLACES THE SCREEN IN StartScreenManager.verse. That file drew the
# plain start card built earlier the same day. Kai's ruling: "whatever, make the
# start screen work", so the broadcast version is the one that ships.
#
# Nothing was deleted to do it, and no existing file was touched. The old
# device is simply taken out of the map, so its class never runs and its card
# never draws. What that file still owns, and what this file leans on, is the
# match hold: MatchStartedFor, AwaitMatchStart and MatchHasStarted live there,
# five other scripts already call them, and they work untouched. It also owns
# ScreenLine, the helper that turns a plain string into something a text widget
# will accept. Tidying the dead class away is a later job, and a deliberate
# one, because five files depend on what sits beside it.
#
# THE VHS LOOK, AND WHAT IS REAL. A post-process VHS filter runs on the 3D
# world but cannot touch the interface, so the interface fakes it:
#
#   * SCANLINES are real. Fifty thin dark bars, spread evenly down the screen
#     by a stack box that shares its height equally between them.
#   * COLOR FRINGING is real. The title is drawn three times, a red copy two
#     pixels left, a blue copy two pixels right, the true text on top. Kept off
#     small text, where it destroys readability.
#   * DESATURATION AND EDGE SOFTNESS ARE NOT POSSIBLE. Verse cannot blur,
#     feather or desaturate a widget, and there is no shader access on the
#     interface. Left out rather than faked badly.
#
# WHERE THE SCANLINES SIT, AND WHY IT IS NOT THE TOP. The honest place for
# them is over everything, tape over picture. They are one layer under the
# buttons instead, because an interface layer drawn over a button can swallow
# the mouse click, and a screen where nothing is clickable is worse than a
# screen with slightly clean buttons. Each panel gets its own copy of the
# scanlines for the same reason. If the buttons prove to still work with the
# lines above them, this can be lifted in one line.

using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
# text_block lives here. color_block, canvas, stack_box, overlay and button
# live in the UnrealEngine UI module below, so both imports are needed.
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Colors }
using { /Verse.org/Random }
using { /Verse.org/Simulation }

# =====================================================================
# THE MATCH HOLD LIVES IN StartScreenManager.verse
#
# MatchStartedFor, AwaitMatchStart and MatchHasStarted are defined in that
# file, at module scope. Every .verse file in this folder shares one module, so
# this file calls them directly with no wire and no import. They are NOT
# repeated here on purpose: two definitions of the same name in one module is a
# build error.
#
# Five scripts call AwaitMatchStart(Self) in their OnBegin and sit still until
# START SHOW is pressed: WaveManager, SimulatedAudience, HypeMeterManager,
# StartingLoadoutManager and CareerRankManager.
# =====================================================================

broadcast_screen := class(creative_device):

    # =================================================================
    # THE SPONSOR TICKER'S WORDS (build item 3)
    #
    # REWRITE THESE FREELY. This is the whole list, kept at the top of the file
    # so it never has to be hunted for. Add or remove lines and the ticker
    # simply gets longer or shorter; nothing else needs touching.
    #
    # A note on where the line is drawn. These are advertisements, which are
    # set dressing, so they were written here. The ANNOUNCER's barks are not,
    # and never will be: CLAUDE.md section 0 rule 3 puts every line the
    # commentator says in Kai's hands alone. If any of these read as the
    # announcer rather than as a sponsor, they are in the wrong file.
    # =================================================================

    SponsorSlogans : []string = array:
        "GRIMLOCK CANNED MEAT. IT IS MOSTLY MEAT."
        "NEW FROM VOLTPRO: A TOASTER THAT ONLY SOMETIMES CATCHES FIRE."
        "DRINK SLUDGE COLA. YOUR REPLACEMENT WILL."
        "CONSOLIDATED DEBT SOLUTIONS. WE ALREADY OWN YOU, SO RELAX."
        "FUNERAL PLANS FROM $4.99. ASK ABOUT THE CONTESTANT DISCOUNT."
        "HAPPY BRAND VITAMINS. THE SIDE EFFECTS ARE PART OF THE FUN."
        "BUY A HOME SATELLITE DISH AND WATCH SOMEBODY ELSE DIE INSTEAD."
        "TONIGHT'S EPISODE SPONSORED BY WHOEVER STILL ANSWERS OUR CALLS."

    # The station, dropped in between every slogan so the ticker reads like a
    # real channel identing itself. Kai's ruling, amendment 70h: it is the name
    # of Kai's own company, and it is meant to be spotted.
    StationIdent : string = "RSM STUDIOS"

    # =================================================================
    # THE LEGAL FINE PRINT (build item 6)
    #
    # Kai's ruling: it is NOT parked along the bottom edge all the time. It
    # appears only while the mouse is on START SHOW, which is exactly when a
    # network would want you not to read it.
    #
    # FOUR VARIATIONS, ALL IN USE. Kai's ruling: randomise them and rotate
    # them out on every hover, so the contestant never knows which set of terms
    # they are about to be shown. Add or remove lines freely; the rotation just
    # gets longer or shorter.
    # =================================================================

    FinePrintLines : []string = array:
        "THE NETWORK IS NOT LIABLE FOR DISMEMBERMENT, DISINTEGRATION, OR LOSS OF SPONSORSHIP."
        "BY PRESSING START YOU WAIVE ALL CLAIMS, INCLUDING THOSE YOUR NEXT OF KIN MIGHT RAISE."
        "PRIZES ARE NOT GUARANTEED. NEITHER IS ANYTHING ELSE. CONTESTANT ASSUMES ALL RISK."
        "PARTICIPATION IS VOLUNTARY. WITHDRAWAL IS NOT. TERMS SUBJECT TO CHANGE MID-EPISODE."

    # What sits between one entry and the next.
    TickerSeparator : string = "   ///   "

    # =================================================================
    # PLACEHOLDER DATA
    #
    # Deliberately, obviously fake. Every row is marked so it cannot be
    # mistaken for a real score or a real collection. Both lists are wired to
    # real systems later.
    # =================================================================

    # Item 1's fake leaderboard. Round numbers and numbered contestants.
    FakeLeaderboard : []string = array:
        "1.   CONTESTANT 004          999,999"
        "2.   CONTESTANT 011          888,888"
        "3.   CONTESTANT 002          777,777"
        "4.   CONTESTANT 019          666,666"
        "5.   CONTESTANT 007          555,555"

    # Item 1's fake prize vault. The found ones glow gold, the rest are dim
    # gray. Two found and three missing, so both states are visible at once.
    FoundPrizes : []string = array:
        "CHROME TOASTER"
        "GOLD COINS"

    MissingPrizes : []string = array:
        "WOOD-PANEL CRT TELEVISION"
        "CASH BUNDLE"
        "ROASTED TURKEY LEG"

    # =================================================================
    # THE PALETTE. Locked by the brief. Nothing outside this list.
    # =================================================================

    BroadcastBlack : color = MakeColorFromHex("0F1216")
    ConcreteGray : color = MakeColorFromHex("6E7580")
    LaserYellow : color = MakeColorFromHex("FFDD1C")
    SponsorPink : color = MakeColorFromHex("FF2D95")
    PlasmaBlue : color = MakeColorFromHex("25B4FF")
    PrizeGold : color = MakeColorFromHex("FFC233")
    DangerRed : color = MakeColorFromHex("FF3B30")

    # THE ONE COLOUR OUTSIDE THE SEVEN, and why it is allowed. The brief locks
    # the palette, and then asks for static made of "random gray and white
    # blocks". There is no white in the seven, so it is named here on its own,
    # used by nothing but the static, and deliberately not reached for anywhere
    # else on the screen.
    StaticWhite : color = MakeColorFromHex("FFFFFF")

    # The two fringing copies. A tape's color bleed is red one way and cyan the
    # other; Danger red and Plasma blue are the palette's nearest pair, so the
    # effect stays inside the seven approved colors.
    FringeLeftColor : color = MakeColorFromHex("FF3B30")
    FringeRightColor : color = MakeColorFromHex("25B4FF")

    # =================================================================
    # THE DIALS
    #
    # @editable means these appear on the device's Details panel in UEFN, so
    # they can be tried out without touching this file. Anything changed there
    # must be mirrored back into the defaults here in the same sitting, per
    # CLAUDE.md section 10.
    # =================================================================

    @editable
    TitleLineOne : string = "SPONSOR ME,"

    @editable
    TitleLineTwo : string = "SLAYERS!"

    # =================================================================
    # TONIGHT'S SCHEDULE (build item 8)
    #
    # The four buttons are a broadcast listing, not a menu. Each row is a time
    # and a programme, and each row is still the whole button: pressing the
    # 9:00 PM row opens the prize vault exactly as a button labelled
    # COLLECTABLES used to.
    #
    # A WARNING IF THE OLD WORDS ARE STILL THERE. These are @editable, which
    # means the copy saved on the device you already placed WINS over anything
    # written here. If the screen still says START SHOW after this build, the
    # device is holding the old text: hit the revert arrow beside each of these
    # settings in the Details panel, or delete the device and place a fresh
    # one. This is CLAUDE.md section 10's trap, from the other direction.
    # =================================================================

    @editable
    ScheduleHeading : string = "TONIGHT ON RSM STUDIOS"

    @editable
    StartTime : string = "NOW"

    @editable
    StartLabel : string = "SPONSOR ME, SLAYERS!"

    @editable
    LeaderboardTime : string = "8:00 PM"

    @editable
    LeaderboardLabel : string = "THE LEADERBOARD HOUR"

    @editable
    CollectablesTime : string = "9:00 PM"

    @editable
    CollectablesLabel : string = "THE PRIZE VAULT"

    @editable
    BackLabel : string = "BACK"

    # The dead channel. Fully pressable, and it goes nowhere on purpose: a snow
    # screen that holds until clicked. Kai's ruling, amendment 70g, is one dead
    # channel rather than the brief's two.
    #
    # The joke is that a bankrupt network schedules its own grovelling and then
    # cannot even air that. If it does not land, "DEAD AIR" and "PAID
    # PROGRAMMING" were the other two in the running.
    @editable
    OffAirTime : string = "4:00 AM"

    @editable
    OffAirLabel : string = "AN APOLOGY FROM MANAGEMENT"

    # What the way out of the dead channel says.
    @editable
    DeadExitLabel : string = "BACK TO OUR REGULARLY SCHEDULED PROGRAMMING"

    # THE FLIP. Clicking the dead channel switches it between snow and colour
    # bars. This is how long the burst of static covers the switch, in seconds.
    # It is the one number worth touching: below about 0.1 the pop is too quick
    # to register, above about 0.5 it stops feeling like a switch and starts
    # feeling like a wait.
    @editable
    DeadFlipPopSeconds : float = 0.22

    # The pop's sound. Point this at any Audio Player device in your arena; if
    # it is left unset the flip is silent and nothing else goes wrong.
    @editable
    StaticPop : audio_player_device = audio_player_device{}

    # There is no "which line" setting any more. Kai's ruling: the fine print
    # is randomised and rotates out on every hover, so all four are in use and
    # the contestant never knows which one they are about to be shown.

    # How many scanlines down the screen. 160 over a 1080-tall screen puts a
    # line every 7 pixels or so, which is close to real tape. Fifty was far too
    # sparse to read as anything. Raise for finer banding, lower for coarser.
    @editable
    ScanlineCount : int = 160

    # HOW DARK EACH SCANLINE IS. There is no dial for this on the Details
    # panel, and there cannot be one. The opacity setting on a shape does not
    # take an ordinary number: it demands one the compiler can prove sits
    # between 0 and 1, and a value typed into the editor later carries no such
    # proof. So it is written straight into BuildScanlines below, on the
    # DefaultOpacity line. 0.10 is a soft haze. 0.2 is heavy tape wear.

    # How many yellow stripes in each hazard bar.
    @editable
    HazardStripeCount : int = 32

    # How far the two fringe copies sit from the true text, in pixels.
    @editable
    FringeOffset : float = 3.0

    # =================================================================
    # THE ON AIR LIGHT (build item 9)
    # =================================================================

    # Untick to take the light off the screen entirely.
    @editable
    ShowOnAir : logic = true

    # THE BLINK RATE, in seconds per state. This is the starting value only.
    # The live one is BlinkSeconds below, and the switch other code reaches for
    # is SetBlinkSeconds. Small number means frantic, large means sleepy.
    @editable
    OnAirBlinkSeconds : float = 0.8

    # How often the light checks whether the contestant is still alive.
    @editable
    OnAirPollSeconds : float = 0.25

    # =================================================================
    # THE SPONSOR TICKER (build item 3)
    # =================================================================

    # Untick to take the strip off the screen.
    @editable
    ShowTicker : logic = true

    # HOW THE SCROLL WORKS, because it is not what you would expect. Verse
    # cannot move a widget once it is on the screen: there is no way to nudge a
    # position, and no scrolling container. So the strip never moves. What
    # moves is the WORDS INSIDE it. The whole ticker is one long piece of text,
    # and every step shows a window onto it one letter further along, which
    # reads as a scroll. Kai chose this over the alternative, which was tearing
    # the strip off the screen and re-attaching it a pixel over twenty times a
    # second, because that risks a visible flicker.
    #
    # It therefore steps by one letter rather than gliding, and letters are
    # different widths, so the pace wobbles slightly. A cheap studio ticker
    # wobbles too.

    # Seconds between steps. Smaller is faster. Below about 0.04 the letters
    # blur into each other.
    @editable
    TickerStepSeconds : float = 0.07

    # How many letters are on screen at once. Too high and the text runs off
    # the right edge; too low and it does not reach the edges. Tune by eye.
    @editable
    TickerWindowChars : int = 130

    # =================================================================
    # CHANNEL STATIC (build item 4)
    #
    # HOW THE STATIC IS MADE, since the obvious way is impossible. The brief
    # asks for randomly positioned rectangles, and a widget's position cannot
    # be changed once it is on screen. So the rectangles do not move: a fixed
    # grid of blocks is laid down once, and every frame each block is given a
    # new random shade of gray. Nothing moves and it still boils like static.
    #
    # WHY IT IS ITS OWN LAYER. Kai's brief is emphatic that channel surfing
    # must never be rate limited, queued or blocked, and that mashing must
    # work. An interface layer sitting over the buttons can swallow a click, so
    # the static is added as a separate screen layer that declares it consumes
    # NO input at all. It draws over everything and cannot eat a press.
    # =================================================================

    # How coarse the static is. 16 by 9 gives chunky blocks that suit a cheap
    # studio; raise both for finer noise at the cost of more blocks to recolor.
    @editable
    StaticColumns : int = 16

    @editable
    StaticRows : int = 9

    # Seconds each static frame is held. 0.06 is about sixteen frames a second,
    # which is the flicker rate of bad tape.
    @editable
    StaticFrameSeconds : float = 0.06

    # How long the static lasts. The brief asks for roughly half a second.
    @editable
    StaticSeconds : float = 0.5

    # =================================================================
    # THE DEBT COUNTER (build item 5)
    #
    # WHY THE CONTESTANT IS HERE. It sits top right, well away from the ON AIR
    # light in the top left, and like that light it stays up for the whole
    # match rather than only the title screen. It has to: Kai's ruling is that
    # it FALLS as cash is collected, and cash is collected during play.
    #
    # HOW IT MOVES. Interest climbs while the contestant is off the air, which
    # means the title screen and anything after death. Collected cash pulls it
    # down while the show is running. It is one running total that survives
    # between runs, so paying some off means it is still paid off next time.
    #
    # ONE WIRE NEEDED IN UEFN. CashDrops has to be pointed at the cash drop
    # manager device, or the counter will climb and never fall.
    # =================================================================

    # Untick to take the counter off the screen.
    @editable
    ShowDebt : logic = true

    # The cash drop manager, read for the run's score. Nothing is written to it.
    @editable
    CashDrops : cash_drop_manager = cash_drop_manager{}

    # What the debt starts at on a save that has never played. A fresh save
    # carries a drift of zero, so this figure is exactly what shows.
    @editable
    StartingDebt : int = 47300

    # How often the counter recalculates and redraws.
    @editable
    DebtTickSeconds : float = 0.25

    # Dollars of interest added per tick, while off the air. Seven a tick is
    # twenty-eight a second: slow enough to miss at first glance, obviously
    # climbing once noticed.
    @editable
    DebtInterestPerTick : int = 7

    # Dollars knocked off the debt per point of run score. Each pickup is worth
    # ten points, so at 1 a pickup pays off ten dollars.
    @editable
    DebtPerScorePoint : int = 1

    # How often the drifted total is written to the save, in ticks. Writing
    # every tick would hammer the save for no gain; four ticks is once a second
    # and the most that can be lost is a second of interest.
    @editable
    DebtSaveEveryTicks : int = 4

    # =================================================================
    # SOUND (build item 2)
    #
    # Both of these are Audio Player devices placed in the map. Verse cannot
    # choose a sound; the sound is picked on the device itself in UEFN, and
    # this file only says when to play it. That split is why nothing here
    # names a sound file.
    #
    # THE GAME SHOW BUZZER, on a button becoming hovered.
    @editable
    HoverBuzzer : audio_player_device = audio_player_device{}

    # THE DING-DING-DING CASH STINGER, on START SHOW.
    @editable
    StartStinger : audio_player_device = audio_player_device{}

    # How long the buzzer refuses to sound again, in seconds.
    #
    # WHY THIS EXISTS. A mouse crossing the stack of buttons hovers all three
    # in a fifth of a second, and without a gate that is three buzzers on top
    # of each other. This is not rate limiting the player's channel surfing,
    # which Kai's brief says must stay loose; it only stops one sound
    # retriggering over itself.
    @editable
    BuzzerCooldownSeconds : float = 0.15

    # Hide Fortnite's own HUD while the broadcast is up. Untick only for
    # debugging: with the HUD showing, the health bar and hotbar draw straight
    # over the card. Item 9 covers the ON AIR light's own fight with that HUD.
    @editable
    HideGameHUD : logic = true

    # =================================================================
    # LIVE STATE
    # =================================================================

    # The whole broadcast, so it can be taken off air when the show starts.
    var Screen : ?canvas = false

    # The three channel buttons as a group, hidden while a panel is open.
    var ChannelGroup : ?stack_box = false

    # The two panels, built once and left hidden.
    var BoardPanel : ?canvas = false
    var VaultPanel : ?canvas = false

    # Held so the hover handlers can recolor them. One pair per button: the
    # outline block behind it and the label on it.
    var StartFill : ?color_block = false
    var StartText : ?text_block = false
    var BoardEdge : ?color_block = false
    var BoardText : ?text_block = false
    var VaultEdge : ?color_block = false
    var VaultText : ?text_block = false
    var DeadEdge : ?color_block = false
    var DeadText : ?text_block = false

    # False while the buzzer is in its cooldown. See BuzzerCooldownSeconds.
    var BuzzerReady : logic = true

    # The ON AIR light's box, held so the blink can show and hide it.
    var OnAirBox : ?overlay = false

    # True while the contestant is on the air. Goes false on death and never
    # comes back on its own, which stops the blink for good.
    var OnAirLit : logic = true

    # Which half of the blink the light is currently in.
    var BlinkVisible : logic = true

    # The ticker's text, held so the scroll can keep rewriting it.
    var TickerLabel : ?text_block = false

    # The whole strip, held so it can be hidden if ShowTicker is unticked.
    var TickerStrip : ?overlay = false

    # Every block of the static grid, held so each one can be recolored.
    var StaticBlocks : []color_block = array{}

    # The static grid, shown and hidden between channels.
    var StaticSheet : ?stack_box = false

    # WHICH CHANNEL CHANGE IS THE REAL ONE. Every press takes the next number.
    # A change that finds this number has moved on knows a later press
    # overtook it, and bows out without touching the screen. That is what lets
    # the player mash the channels: presses are not queued and nothing waits
    # its turn, the newest press simply wins.
    var ChannelToken : int = 0

    # The debt readout, and the layer it rides on.
    var DebtLabel : ?text_block = false
    var DebtRoot : ?canvas = false

    # HOW FAR THE DEBT HAS DRIFTED from StartingDebt, across every run ever
    # played. Seeded from the save at match start, pushed up by interest and
    # down by collected cash, and written back on a throttle. The figure on
    # screen is always StartingDebt plus this.
    var DebtDrift : int = 0

    # The run score at the last tick, so only the NEW cash pays anything off.
    # Without it the whole score would be subtracted again every quarter second.
    var ScoreAlreadyCredited : int = 0

    # Counts ticks up to DebtSaveEveryTicks, then the save is written.
    var TicksSinceDebtSaved : int = 0

    # The fine print, hidden until the mouse rests on START SHOW.
    var FinePrint : ?text_block = false

    # The line shown last time, so the next hover never repeats it.
    var LastFinePrintShown : int = -1

    # The invisible sheet that covers the whole screen while the dead channel
    # is showing, so a click anywhere at all gets the contestant out again.
    var OffAirExit : ?button = false

    # True while the contestant is sitting on the dead channel. This is what
    # keeps the noise loop boiling rather than stopping.
    var HoldingSnow : logic = false

    # Which half of the dead channel is showing: false is snow, true is bars.
    var ShowingBars : logic = false

    # True during the burst of static that covers a switch. The noise keeps
    # boiling while this is set, even though the bars are the destination.
    var Popping : logic = false

    # The colour bar card, and the way back to the schedule.
    var BarCard : ?stack_box = false
    var DeadExit : ?button = false

    # How far along the feed the window currently starts.
    var TickerHead : int = 0

    # The feed, laid end to end twice. Doubling it is what makes the wrap free:
    # the window can start anywhere in the first copy and still read a full
    # window's worth without running off the end or needing to stitch two
    # pieces together.
    var TickerDoubled : string = ""

    # The length of ONE copy, which is where the window resets to nothing.
    var TickerLoopLength : int = 0

    # THE LIVE BLINK RATE. This is the single variable the brief asks to be
    # left reachable, seeded from OnAirBlinkSeconds at match start and changed
    # afterwards through SetBlinkSeconds. The Hype Meter will drive it later:
    # high hype means a smaller number and a faster blink. Nothing about the
    # Hype Meter is built here.
    var BlinkSeconds : float = 0.8

    # =================================================================
    # GOING ON AIR
    # =================================================================

    OnBegin<override>()<suspends>:void =
        # The live blink rate starts as whatever the Details panel says.
        set BlinkSeconds = OnAirBlinkSeconds

        # The ticker's words are laid end to end once, before any screen wants
        # to read them.
        BuildTickerFeed()

        Playspace := GetPlayspace()
        Playspace.PlayerAddedEvent().Subscribe(OnPlayerAdded)

        for (P : Playspace.GetPlayers()):
            ShowBroadcast(P)
            GoOnAir(P)
            ShowDebtCounter(P)

    # A contestant who arrives after this device has begun still gets the
    # broadcast, unless the show has already started. The ON AIR light is
    # separate and goes up either way, because it belongs to the whole match
    # and not to the title screen.
    OnPlayerAdded(P : player):void =
        if (MatchHasStarted(Self)?):
            Print("DEBUG: Broadcast skipped for a contestant who joined after the show started.")
        else:
            ShowBroadcast(P)

        GoOnAir(P)
        ShowDebtCounter(P)

    ShowBroadcast(P : player):void =
        # An opaque block across the whole screen. This is what hides the
        # arena. The arena is still there behind it, there is simply nothing
        # to see.
        Backdrop := color_block:
            DefaultColor := BroadcastBlack
            DefaultOpacity := 1.0

        # The fine print. Built now, shown only while the mouse rests on START
        # SHOW, which is precisely when a network would rather you did not read
        # it. Kai's ruling.
        SmallPrint := text_block:
            DefaultText := ScreenLine(NextFinePrint())
            DefaultTextColor := ConcreteGray
            DefaultTextSize := 15.0
            DefaultJustification := text_justification.Center

        SmallPrint.SetVisibility(widget_visibility.Hidden)
        set FinePrint = option{SmallPrint}

        # A sheet across the whole screen that only exists on the dead channel.
        # It is a button with nothing visible in it, so a click anywhere gets
        # the contestant back to the listings. That is the brief's "returns on
        # any input", done with the one input a captured mouse can give.
        Blank := color_block:
            DefaultColor := BroadcastBlack
            DefaultOpacity := 0.0

        EscapeHatch := button:
            Slot := button_slot:
                Widget := Blank
                HorizontalAlignment := horizontal_alignment.Fill
                VerticalAlignment := vertical_alignment.Fill
                Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

        EscapeHatch.OnClick().Subscribe(OnOffAirDismissed)
        EscapeHatch.SetVisibility(widget_visibility.Collapsed)
        set OffAirExit = option{EscapeHatch}

        # The colour bar half of the dead channel, and the way back out of it.
        Bars := BuildColourBars()
        Bars.SetVisibility(widget_visibility.Collapsed)

        ExitEdge := color_block:
            DefaultColor := LaserYellow
            DefaultOpacity := 1.0
            DefaultDesiredSize := vector2{X := 700.0, Y := 68.0}

        ExitText := text_block:
            DefaultText := ScreenLine(DeadExitLabel)
            DefaultTextColor := LaserYellow
            DefaultTextSize := 22.0
            DefaultJustification := text_justification.Center

        LeaveDead := button:
            Slot := button_slot:
                Widget := ChannelSlab(ExitEdge, ExitText)
                HorizontalAlignment := horizontal_alignment.Center
                VerticalAlignment := vertical_alignment.Center
                Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

        LeaveDead.OnClick().Subscribe(OnDeadChannelExit)
        LeaveDead.SetVisibility(widget_visibility.Collapsed)
        set DeadExit = option{LeaveDead}

        Board := BuildBoardPanel()
        Vault := BuildVaultPanel()

        # Built now and left hidden, so switching channel is instant and
        # nothing has to be rebuilt on a press.
        Board.SetVisibility(widget_visibility.Collapsed)
        Vault.SetVisibility(widget_visibility.Collapsed)

        Channels := BuildChannelStack()

        set BoardPanel = option{Board}
        set VaultPanel = option{Vault}
        set ChannelGroup = option{Channels}

        Root := canvas:
            Slots := array:
                # -- the picture ---------------------------------------
                canvas_slot:
                    Widget := Backdrop
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 0

                # -- hazard bars, top and bottom edges -----------------
                canvas_slot:
                    Widget := BuildHazardBar()
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 0.035}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 1
                canvas_slot:
                    Widget := BuildHazardBar()
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.965}, Maximum := vector2{X := 1.0, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 1

                # -- the title block, upper left -----------------------
                canvas_slot:
                    Widget := FringedText(TitleLineOne, 76.0, LaserYellow, FringeOffset)
                    Anchors := anchors{Minimum := vector2{X := 0.06, Y := 0.14}, Maximum := vector2{X := 0.06, Y := 0.14}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.0, Y := 0.5}
                    ZOrder := 3
                canvas_slot:
                    Widget := FringedText(TitleLineTwo, 96.0, SponsorPink, FringeOffset)
                    Anchors := anchors{Minimum := vector2{X := 0.06, Y := 0.245}, Maximum := vector2{X := 0.06, Y := 0.245}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.0, Y := 0.5}
                    ZOrder := 3

                # -- the tape over the picture -------------------------
                # One layer below the buttons on purpose. See the header.
                canvas_slot:
                    Widget := BuildScanlines(ScanlineCount)
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 5

                # -- tonight's schedule --------------------------------
                # The heading that makes the four slabs read as a listing
                # rather than a menu.
                canvas_slot:
                    Widget := ScheduleHeader()
                    Anchors := anchors{Minimum := vector2{X := 0.06, Y := 0.375}, Maximum := vector2{X := 0.06, Y := 0.375}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.0, Y := 0.5}
                    ZOrder := 10
                canvas_slot:
                    Widget := Channels
                    Anchors := anchors{Minimum := vector2{X := 0.06, Y := 0.42}, Maximum := vector2{X := 0.06, Y := 0.42}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.0, Y := 0.0}
                    ZOrder := 10

                # -- the two panels, on top of all of it ---------------
                canvas_slot:
                    Widget := Board
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 20
                canvas_slot:
                    Widget := Vault
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 20

                # -- the fine print, along the bottom edge -------------
                # Clears the ticker above it and the hazard bar below it.
                canvas_slot:
                    Widget := SmallPrint
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.952}, Maximum := vector2{X := 0.5, Y := 0.952}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    ZOrder := 31

                # -- the dead channel's colour bars --------------------
                # Under the flip sheet, so a click still flips rather than
                # landing on the bars and doing nothing.
                canvas_slot:
                    Widget := Bars
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 38

                # -- the static ---------------------------------------
                # ON THE CARD, not on a layer of its own above it. It started
                # on its own layer so it could never swallow a press, but that
                # put it over the dead channel's way-out button and buried it
                # under the snow. Here it sits under the two things that must
                # stay pressable and over everything that must not show
                # through: bars below it, flip sheet and way out above it.
                canvas_slot:
                    Widget := BuildStatic()
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 39

                # -- the way out of the dead channel -------------------
                # Above everything on this card, so nothing else can take the
                # click while the snow is holding. Collapsed the rest of the
                # time, which is what stops it eating every other press.
                canvas_slot:
                    Widget := EscapeHatch
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 40

                # -- the way back to the schedule ----------------------
                # Above the flip sheet, so pressing it leaves the channel
                # rather than flipping it one last time on the way out.
                canvas_slot:
                    Widget := LeaveDead
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.82}, Maximum := vector2{X := 0.5, Y := 0.82}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    ZOrder := 41

                # -- the sponsor ticker --------------------------------
                # Above the panels, not below them, so changing channel does
                # not take the advertising off the air. A real station never
                # stops selling. It clears the bottom hazard bar, and leaves
                # the strip beneath it free for item 6's fine print.
                canvas_slot:
                    Widget := BuildTicker()
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.90}, Maximum := vector2{X := 1.0, Y := 0.945}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 30

        set Screen = option{Root}

        # InputMode All is what puts the mouse pointer on screen and stops the
        # contestant walking about behind the broadcast. Without it there is no
        # cursor at all and nothing can be pressed.
        Slot := player_ui_slot:
            ZOrder := 100
            InputMode := ui_input_mode.All

        if (PlayerUI := GetPlayerUI[P]):
            PlayerUI.AddWidget(Root, Slot)

            # Off the air until a channel is changed.
            SetStaticVisible(false)

            if (HideGameHUD?):
                GetPlayspace().GetHUDController().HideElementsForPlayer(P, array{creative_hud_identifier_all{}})

            if (ShowTicker?):
                spawn{ RunTicker() }
            else if (Strip := TickerStrip?):
                Strip.SetVisibility(widget_visibility.Collapsed)

            Print("DEBUG: Broadcast on air. The match is holding until START SHOW.")
        else:
            # Nothing can hold the match if the broadcast never appeared, so
            # start the run rather than leave the contestant in an empty arena
            # for ever with no way out.
            Print("WARNING: The broadcast could not be drawn for this contestant, so the match is starting without it.")
            ReleaseTheMatch(P)

    # =================================================================
    # THE VHS FAKERY
    # =================================================================

    # Fifty thin dark bars spread evenly down the screen.
    #
    # HOW THE SPACING WORKS, since it is not obvious. A stack box with
    # Distribution set on every slot shares its height equally between them, so
    # fifty slots each get a fiftieth of the screen. Each slot holds one two
    # pixel bar pinned to the top of its band, which leaves the rest of the
    # band empty. That is the gap between lines, and it costs nothing to draw.
    # LineCount is a parameter rather than always ScanlineCount, because the ON
    # AIR light is a two inch box and fifty lines inside it is a solid block.
    BuildScanlines(LineCount : int) : stack_box =
        var Lines : []stack_box_slot = array{}

        for (Index := 1..LineCount):
            Bar := color_block:
                # LIGHTER than the ground, not darker. This was wrong at first
                # and the lines were invisible for it: near-black lines were
                # being drawn on a near-black backdrop, so there was nothing to
                # see anywhere except over the few bright panels. A dark screen
                # needs its scanlines drawn in the lighter colour.
                DefaultColor := ConcreteGray
                # The scanline strength. Written here rather than on the
                # Details panel, for the reason given up in the dials section.
                DefaultOpacity := 0.10
                DefaultDesiredSize := vector2{X := 8.0, Y := 2.0}

            set Lines += array{stack_box_slot{Widget := Bar, HorizontalAlignment := horizontal_alignment.Fill, VerticalAlignment := vertical_alignment.Top, Distribution := option{1.0}}}

        Layer := stack_box:
            Orientation := orientation.Vertical
            Slots := Lines

        Layer

    # A yellow and black hazard bar. Alternating blocks sharing the width
    # equally, by the same Distribution trick as the scanlines. Vertical
    # stripes rather than diagonal, because a widget cannot be rotated.
    BuildHazardBar() : stack_box =
        var Stripes : []stack_box_slot = array{}

        for (Index := 1..HazardStripeCount):
            Stripe := color_block:
                DefaultColor := LaserYellow
                DefaultOpacity := 1.0
                DefaultDesiredSize := vector2{X := 8.0, Y := 8.0}

            Gap := color_block:
                DefaultColor := BroadcastBlack
                DefaultOpacity := 1.0
                DefaultDesiredSize := vector2{X := 8.0, Y := 8.0}

            set Stripes += array{stack_box_slot{Widget := Stripe, HorizontalAlignment := horizontal_alignment.Fill, VerticalAlignment := vertical_alignment.Fill, Distribution := option{1.0}}}
            set Stripes += array{stack_box_slot{Widget := Gap, HorizontalAlignment := horizontal_alignment.Fill, VerticalAlignment := vertical_alignment.Fill, Distribution := option{1.0}}}

        Bar := stack_box:
            Orientation := orientation.Horizontal
            Slots := Stripes

        Bar

    # The same line of text three times: a red copy pushed left, a blue copy
    # pushed right, and the true text on top of both. That misregistration is
    # what reads as old tape.
    #
    # An overlay stacks its children in the same place, and each child's
    # Padding nudges it, which is how the offsets are made without three
    # separate positions to keep in step.
    FringedText(Content : string, Size : float, MainColor : color, Offset : float) : overlay =
        LeftCopy := text_block:
            DefaultText := ScreenLine(Content)
            DefaultTextColor := FringeLeftColor
            DefaultTextSize := Size
            DefaultJustification := text_justification.Left

        RightCopy := text_block:
            DefaultText := ScreenLine(Content)
            DefaultTextColor := FringeRightColor
            DefaultTextSize := Size
            DefaultJustification := text_justification.Left

        TrueText := text_block:
            DefaultText := ScreenLine(Content)
            DefaultTextColor := MainColor
            DefaultTextSize := Size
            DefaultJustification := text_justification.Left

        Stack := overlay:
            Slots := array:
                overlay_slot:
                    Widget := LeftCopy
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                overlay_slot:
                    Widget := RightCopy
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := Offset * 2.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                overlay_slot:
                    Widget := TrueText
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := Offset, Top := 0.0, Right := 0.0, Bottom := 0.0}

        Stack

    # =================================================================
    # THE CHANNEL BUTTONS
    #
    # Built from the plain `button`, not the ready-made Fortnite ones, for two
    # reasons: only the plain one reports hover, and only the plain one lets a
    # chunky arcade slab be put inside it instead of Fortnite's own thin
    # styling. The slab is an overlay: an outline block at the back, a fill
    # block slightly smaller in front of it, and the label on top.
    # =================================================================

    BuildChannelStack() : stack_box =
        # START SHOW. Primary, so it is the biggest and it is already lit in
        # sponsor pink rather than waiting to be hovered.
        StartFillBlock := color_block:
            DefaultColor := SponsorPink
            DefaultOpacity := 1.0
            DefaultDesiredSize := vector2{X := 700.0, Y := 96.0}

        StartLabelText := text_block:
            DefaultText := ScreenLine(StartLabel)
            DefaultTextColor := BroadcastBlack
            DefaultTextSize := 40.0
            DefaultJustification := text_justification.Left

        set StartFill = option{StartFillBlock}
        set StartText = option{StartLabelText}

        StartSlab := overlay:
            Slots := array:
                overlay_slot:
                    Widget := StartFillBlock
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                overlay_slot:
                    Widget := ListingRow(StartTime, BroadcastBlack, StartLabelText)
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 28.0, Top := 0.0, Right := 28.0, Bottom := 0.0}

        StartButton := button:
            Slot := button_slot:
                Widget := StartSlab
                HorizontalAlignment := horizontal_alignment.Left
                VerticalAlignment := vertical_alignment.Center
                Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

        StartButton.OnClick().Subscribe(OnStartPressed)
        StartButton.HighlightEvent().Subscribe(OnStartHover)
        StartButton.UnhighlightEvent().Subscribe(OnStartUnhover)

        # LEADERBOARD and COLLECTABLES. Dark slabs with a plasma blue edge and
        # a yellow label, both turning sponsor pink on hover.
        BoardEdgeBlock := color_block:
            DefaultColor := PlasmaBlue
            DefaultOpacity := 1.0
            DefaultDesiredSize := vector2{X := 700.0, Y := 76.0}

        BoardLabelText := text_block:
            DefaultText := ScreenLine(LeaderboardLabel)
            DefaultTextColor := LaserYellow
            DefaultTextSize := 30.0
            DefaultJustification := text_justification.Left

        set BoardEdge = option{BoardEdgeBlock}
        set BoardText = option{BoardLabelText}

        BoardButton := button:
            Slot := button_slot:
                Widget := ListingSlab(BoardEdgeBlock, LeaderboardTime, BoardLabelText)
                HorizontalAlignment := horizontal_alignment.Left
                VerticalAlignment := vertical_alignment.Center
                Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

        BoardButton.OnClick().Subscribe(OnLeaderboardPressed)
        BoardButton.HighlightEvent().Subscribe(OnBoardHover)
        BoardButton.UnhighlightEvent().Subscribe(OnBoardUnhover)

        VaultEdgeBlock := color_block:
            DefaultColor := PlasmaBlue
            DefaultOpacity := 1.0
            DefaultDesiredSize := vector2{X := 700.0, Y := 76.0}

        VaultLabelText := text_block:
            DefaultText := ScreenLine(CollectablesLabel)
            DefaultTextColor := LaserYellow
            DefaultTextSize := 30.0
            DefaultJustification := text_justification.Left

        set VaultEdge = option{VaultEdgeBlock}
        set VaultText = option{VaultLabelText}

        VaultButton := button:
            Slot := button_slot:
                Widget := ListingSlab(VaultEdgeBlock, CollectablesTime, VaultLabelText)
                HorizontalAlignment := horizontal_alignment.Left
                VerticalAlignment := vertical_alignment.Center
                Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

        VaultButton.OnClick().Subscribe(OnCollectablesPressed)
        VaultButton.HighlightEvent().Subscribe(OnVaultHover)
        VaultButton.UnhighlightEvent().Subscribe(OnVaultUnhover)

        # THE DEAD CHANNEL. Fully pressable and it goes nowhere, which is the
        # joke. Dimmer than the other two, in concrete gray, because a dead
        # channel should not look inviting and should still look pressable.
        DeadEdgeBlock := color_block:
            DefaultColor := ConcreteGray
            DefaultOpacity := 1.0
            DefaultDesiredSize := vector2{X := 700.0, Y := 76.0}

        DeadLabelText := text_block:
            DefaultText := ScreenLine(OffAirLabel)
            DefaultTextColor := ConcreteGray
            DefaultTextSize := 30.0
            DefaultJustification := text_justification.Left

        set DeadEdge = option{DeadEdgeBlock}
        set DeadText = option{DeadLabelText}

        DeadButton := button:
            Slot := button_slot:
                Widget := ListingSlab(DeadEdgeBlock, OffAirTime, DeadLabelText)
                HorizontalAlignment := horizontal_alignment.Left
                VerticalAlignment := vertical_alignment.Center
                Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

        DeadButton.OnClick().Subscribe(OnOffAirPressed)
        DeadButton.HighlightEvent().Subscribe(OnDeadHover)
        DeadButton.UnhighlightEvent().Subscribe(OnDeadUnhover)

        Stack := stack_box:
            Orientation := orientation.Vertical
            Slots := array:
                stack_box_slot:
                    Widget := StartButton
                    HorizontalAlignment := horizontal_alignment.Left
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 34.0}
                stack_box_slot:
                    Widget := BoardButton
                    HorizontalAlignment := horizontal_alignment.Left
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 24.0}
                stack_box_slot:
                    Widget := VaultButton
                    HorizontalAlignment := horizontal_alignment.Left
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 24.0}
                stack_box_slot:
                    Widget := DeadButton
                    HorizontalAlignment := horizontal_alignment.Left
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

        Stack

    # The line above the listings, with a laser yellow rule under it, so the
    # four slabs read as a printed schedule rather than four buttons.
    ScheduleHeader() : stack_box =
        Heading := text_block:
            DefaultText := ScreenLine(ScheduleHeading)
            DefaultTextColor := LaserYellow
            DefaultTextSize := 22.0
            DefaultJustification := text_justification.Left

        Rule := color_block:
            DefaultColor := LaserYellow
            DefaultOpacity := 1.0
            DefaultDesiredSize := vector2{X := 700.0, Y := 2.0}

        Header := stack_box:
            Orientation := orientation.Vertical
            Slots := array:
                stack_box_slot:
                    Widget := Heading
                    HorizontalAlignment := horizontal_alignment.Left
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 8.0}
                stack_box_slot:
                    Widget := Rule
                    HorizontalAlignment := horizontal_alignment.Left
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

        Header

    # ONE LINE OF THE SCHEDULE: a time on the left, a programme on the right.
    #
    # The two columns share the row by proportion rather than by pixel counts,
    # so the time column stays a quarter of the row whatever width the slab is
    # and however long the programme name gets.
    ListingRow(TimeText : string, TimeColor : color, TitleText : text_block) : stack_box =
        Clock := text_block:
            DefaultText := ScreenLine(TimeText)
            DefaultTextColor := TimeColor
            DefaultTextSize := 24.0
            DefaultJustification := text_justification.Left

        Row := stack_box:
            Orientation := orientation.Horizontal
            Slots := array:
                stack_box_slot:
                    Widget := Clock
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Center
                    Distribution := option{1.0}
                stack_box_slot:
                    Widget := TitleText
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Center
                    Distribution := option{3.0}

        Row

    # A dark slab with a colored edge, carrying one line of the schedule. The
    # edge is simply a bigger block behind a smaller dark one; Verse has no
    # border on a color block, so the border is faked by letting six pixels of
    # the block behind show all round.
    ListingSlab(EdgeBlock : color_block, TimeText : string, TitleText : text_block) : overlay =
        Inner := color_block:
            DefaultColor := BroadcastBlack
            DefaultOpacity := 1.0
            DefaultDesiredSize := vector2{X := 688.0, Y := 64.0}

        Slab := overlay:
            Slots := array:
                overlay_slot:
                    Widget := EdgeBlock
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                overlay_slot:
                    Widget := Inner
                    HorizontalAlignment := horizontal_alignment.Center
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                overlay_slot:
                    Widget := ListingRow(TimeText, ConcreteGray, TitleText)
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 28.0, Top := 0.0, Right := 28.0, Bottom := 0.0}

        Slab

    # The plain centred version, still used by the BACK control, which is a
    # control and not a listing.
    ChannelSlab(EdgeBlock : color_block, LabelText : text_block) : overlay =
        Inner := color_block:
            DefaultColor := BroadcastBlack
            DefaultOpacity := 1.0
            DefaultDesiredSize := vector2{X := 458.0, Y := 64.0}

        Slab := overlay:
            Slots := array:
                overlay_slot:
                    Widget := EdgeBlock
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                overlay_slot:
                    Widget := Inner
                    HorizontalAlignment := horizontal_alignment.Center
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                overlay_slot:
                    Widget := LabelText
                    HorizontalAlignment := horizontal_alignment.Center
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

        Slab

    # =================================================================
    # THE TWO PANELS
    # =================================================================

    BuildBoardPanel() : canvas =
        var Rows : []stack_box_slot = array{}

        for (Row : FakeLeaderboard):
            Line := text_block:
                DefaultText := ScreenLine(Row)
                DefaultTextColor := LaserYellow
                DefaultTextSize := 34.0
                DefaultJustification := text_justification.Left

            set Rows += array{stack_box_slot{Widget := Line, HorizontalAlignment := horizontal_alignment.Left, Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 16.0}}}

        Body := stack_box:
            Orientation := orientation.Vertical
            Slots := Rows

        BuildPanelFrame("THE LEADERBOARD HOUR", "PLACEHOLDER SCORES. NOT REAL. NOBODY HAS EVER SCORED THIS.", Body)

    BuildVaultPanel() : canvas =
        var Rows : []stack_box_slot = array{}

        # Found first, glowing gold.
        for (Prize : FoundPrizes):
            Line := text_block:
                DefaultText := ScreenLine("{Prize}   FOUND")
                DefaultTextColor := PrizeGold
                DefaultTextSize := 32.0
                DefaultJustification := text_justification.Left

            set Rows += array{stack_box_slot{Widget := Line, HorizontalAlignment := horizontal_alignment.Left, Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 16.0}}}

        # Then the missing ones, dim gray so they read as silhouettes.
        for (Prize : MissingPrizes):
            Line := text_block:
                DefaultText := ScreenLine("{Prize}   ---")
                DefaultTextColor := ConcreteGray
                DefaultTextSize := 32.0
                DefaultJustification := text_justification.Left

            set Rows += array{stack_box_slot{Widget := Line, HorizontalAlignment := horizontal_alignment.Left, Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 16.0}}}

        Body := stack_box:
            Orientation := orientation.Vertical
            Slots := Rows

        BuildPanelFrame("THE PRIZE VAULT", "PLACEHOLDER PRIZES. NOT REAL. NOTHING HAS BEEN WON YET.", Body)

    # Both panels share this frame, so they cannot drift apart: dark ground,
    # its own copy of the scanlines, a heading, a fake-data warning in danger
    # red, the body, and a BACK button.
    BuildPanelFrame(Heading : string, Warning : string, Body : widget) : canvas =
        Ground := color_block:
            DefaultColor := BroadcastBlack
            DefaultOpacity := 0.97

        HeadingText := text_block:
            DefaultText := ScreenLine(Heading)
            DefaultTextColor := LaserYellow
            DefaultTextSize := 54.0
            DefaultJustification := text_justification.Left

        WarningText := text_block:
            DefaultText := ScreenLine(Warning)
            DefaultTextColor := DangerRed
            DefaultTextSize := 20.0
            DefaultJustification := text_justification.Left

        BackEdge := color_block:
            DefaultColor := LaserYellow
            DefaultOpacity := 1.0
            DefaultDesiredSize := vector2{X := 280.0, Y := 68.0}

        BackText := text_block:
            DefaultText := ScreenLine(BackLabel)
            DefaultTextColor := LaserYellow
            DefaultTextSize := 32.0
            DefaultJustification := text_justification.Center

        BackButton := button:
            Slot := button_slot:
                Widget := ChannelSlab(BackEdge, BackText)
                HorizontalAlignment := horizontal_alignment.Left
                VerticalAlignment := vertical_alignment.Center
                Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

        BackButton.OnClick().Subscribe(OnBackPressed)

        Panel := canvas:
            Slots := array:
                canvas_slot:
                    Widget := Ground
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.035}, Maximum := vector2{X := 1.0, Y := 0.965}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 0
                canvas_slot:
                    Widget := BuildScanlines(ScanlineCount)
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.035}, Maximum := vector2{X := 1.0, Y := 0.965}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 1
                canvas_slot:
                    Widget := HeadingText
                    Anchors := anchors{Minimum := vector2{X := 0.07, Y := 0.15}, Maximum := vector2{X := 0.07, Y := 0.15}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.0, Y := 0.5}
                    ZOrder := 3
                canvas_slot:
                    Widget := WarningText
                    Anchors := anchors{Minimum := vector2{X := 0.07, Y := 0.22}, Maximum := vector2{X := 0.07, Y := 0.22}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.0, Y := 0.5}
                    ZOrder := 3
                canvas_slot:
                    Widget := Body
                    Anchors := anchors{Minimum := vector2{X := 0.07, Y := 0.32}, Maximum := vector2{X := 0.07, Y := 0.32}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.0, Y := 0.0}
                    ZOrder := 3
                canvas_slot:
                    Widget := BackButton
                    Anchors := anchors{Minimum := vector2{X := 0.07, Y := 0.86}, Maximum := vector2{X := 0.07, Y := 0.86}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.0, Y := 0.5}
                    ZOrder := 3

        Panel

    # =================================================================
    # PRESSES AND HOVERS
    # =================================================================

    # =================================================================
    # SOUND (build item 2)
    # =================================================================

    # The buzzer, if it is not still ringing from the last button.
    #
    # WHY Play() AND NOT Play(P). The digest is explicit that Play(Agent) works
    # only when the device is set to be heard by the instigator, and a freshly
    # placed device is not. Getting that wrong is a silent failure: the code
    # runs, no sound comes out, and nothing says why. Play() with nobody named
    # does not care how that setting is left, and amendment 19 makes this game
    # single-player, so "everyone hears it" and "the contestant hears it" are
    # the same sentence.
    PlayBuzzer(P : player):void =
        if (BuzzerReady?):
            set BuzzerReady = false
            HoverBuzzer.Play()
            spawn{ ArmBuzzerAgain() }

    ArmBuzzerAgain()<suspends>:void =
        Sleep(BuzzerCooldownSeconds)
        set BuzzerReady = true

    OnStartPressed(Message : widget_message):void =
        # The cash stinger fires before the broadcast comes down, so the ding
        # lands over the cut to the arena rather than after it. The sound is a
        # device out in the world and carries on playing once the screen is
        # gone, so nothing has to be held back to hear it.
        StartStinger.Play()
        ReleaseTheMatch(Message.Player)

    # These are not menu items. They are channels, so pressing one changes the
    # channel: everything cuts to static, and the new picture arrives after it.
    OnLeaderboardPressed(Message : widget_message):void =
        ChangeChannel(BoardPanel)

    OnCollectablesPressed(Message : widget_message):void =
        ChangeChannel(VaultPanel)

    # Both panels share one BACK, because only one can ever be open. Passing
    # nothing as the destination means the listings themselves.
    OnBackPressed(Message : widget_message):void =
        ChangeChannel(false)

    # =================================================================
    # CHANGING CHANNEL (build item 4)
    # =================================================================

    ChangeChannel(Target : ?canvas):void =
        set ChannelToken += 1
        Token := ChannelToken

        # Leaving the dead channel by any route clears all of it away. The flip
        # sheet especially: left up, it sits over the schedule and swallows
        # every press.
        set HoldingSnow = false
        set ShowingBars = false
        set Popping = false
        SetBarsVisible(false)
        if (Hatch := OffAirExit?):
            Hatch.SetVisibility(widget_visibility.Collapsed)
        if (Exit := DeadExit?):
            Exit.SetVisibility(widget_visibility.Collapsed)

        spawn{ RunChannelChange(Token, Target) }

    # A DIFFERENT LINE EVERY HOVER, and never the same one twice running.
    #
    # Random alone would repeat itself, and a repeat reads as broken rather
    # than random: hover twice, see the same words, and it looks like the
    # rotation is stuck. So a pick that lands on the line just shown is nudged
    # to the next one along instead.
    NextFinePrint()<transacts>:string =
        Count := FinePrintLines.Length

        if (Count > 1):
            var Pick : int = GetRandomInt(0, Count - 1)
            if (Pick = LastFinePrintShown):
                set Pick += 1
                if (Pick >= Count):
                    set Pick = 0

            set LastFinePrintShown = Pick
            if (Line := FinePrintLines[Pick]):
                return Line

        # One line, or none. Nothing to rotate.
        if (Only := FinePrintLines[0]):
            return Only
        ""

    RunChannelChange(Token : int, Target : ?canvas)<suspends>:void =
        # The old picture goes at once, so the cut to static is instant and a
        # press always feels answered on the frame it happened.
        HideEveryChannel()
        SetStaticVisible(true)

        var Held : float = 0.0
        loop:
            if (Token = ChannelToken):
                ScrambleStatic()
                Sleep(StaticFrameSeconds)
                set Held += StaticFrameSeconds
                if (Held >= StaticSeconds):
                    break
            else:
                # A later press overtook this one while the static was running.
                # That press owns the screen now, and it is already showing its
                # own static, so this one leaves without touching anything.
                # Nothing is queued and nobody waits their turn.
                return

        # Checked again, because the press could have landed during the last
        # sleep. Only the newest change is allowed to put a picture up.
        if (Token = ChannelToken):
            SetStaticVisible(false)
            if (Arriving := Target?):
                Arriving.SetVisibility(widget_visibility.Visible)
            else if (Channels := ChannelGroup?):
                Channels.SetVisibility(widget_visibility.Visible)

    HideEveryChannel():void =
        if (Channels := ChannelGroup?):
            Channels.SetVisibility(widget_visibility.Collapsed)
        if (Board := BoardPanel?):
            Board.SetVisibility(widget_visibility.Collapsed)
        if (Vault := VaultPanel?):
            Vault.SetVisibility(widget_visibility.Collapsed)

    # =================================================================
    # THE STATIC ITSELF (build item 4)
    # =================================================================

    # A fixed grid of blocks, sharing the screen out equally by the same
    # Distribution trick the scanlines use, so there is no pixel arithmetic and
    # it fits any screen. Each block is kept so it can be recolored later,
    # because recoloring is the only thing that CAN change once it is on screen.
    BuildStatic() : stack_box =
        var Rows : []stack_box_slot = array{}
        var Cells : []color_block = array{}

        for (Row := 1..StaticRows):
            var RowCells : []stack_box_slot = array{}

            for (Column := 1..StaticColumns):
                Cell := color_block:
                    DefaultColor := ConcreteGray
                    DefaultOpacity := 1.0
                    DefaultDesiredSize := vector2{X := 8.0, Y := 8.0}

                set RowCells += array{stack_box_slot{Widget := Cell, HorizontalAlignment := horizontal_alignment.Fill, VerticalAlignment := vertical_alignment.Fill, Distribution := option{1.0}}}
                set Cells += array{Cell}

            RowBox := stack_box:
                Orientation := orientation.Horizontal
                Slots := RowCells

            set Rows += array{stack_box_slot{Widget := RowBox, HorizontalAlignment := horizontal_alignment.Fill, VerticalAlignment := vertical_alignment.Fill, Distribution := option{1.0}}}

        set StaticBlocks = Cells

        Sheet := stack_box:
            Orientation := orientation.Vertical
            Slots := Rows

        set StaticSheet = option{Sheet}
        Print("DEBUG: Static grid built, {Cells.Length} blocks.")
        Sheet

    # One frame of noise. Three shades, picked fresh for every block: near
    # black, concrete gray, white. Grays and white only, as the brief says, so
    # nothing outside the locked palette creeps into the noise.
    ScrambleStatic():void =
        for (Block : StaticBlocks):
            Roll := GetRandomInt(0, 2)
            var Shade : color = ConcreteGray
            if (Roll = 0):
                set Shade = BroadcastBlack
            else if (Roll = 1):
                set Shade = ConcreteGray
            else:
                set Shade = StaticWhite
            Block.SetColor(Shade)

    SetStaticVisible(Wanted : logic):void =
        if (Sheet := StaticSheet?):
            if (Wanted?):
                Sheet.SetVisibility(widget_visibility.Visible)
            else:
                Sheet.SetVisibility(widget_visibility.Collapsed)

    # START SHOW is already pink, so its hover goes the other way: the slab
    # flips to laser yellow so the change is unmistakable.
    # START SHOW is the only button that buzzes, and the only one that brings
    # the fine print up. Reading the terms is a thing you do with your hand
    # already on the button.
    OnStartHover(Message : widget_message):void =
        PlayBuzzer(Message.Player)
        if (Fill := StartFill?):
            Fill.SetColor(LaserYellow)
        if (Terms := FinePrint?):
            # Rewritten before it is shown, so a fresh line arrives with the
            # hover rather than the previous one flashing up first.
            Terms.SetText(ScreenLine(NextFinePrint()))
            Terms.SetVisibility(widget_visibility.Visible)

    OnStartUnhover(Message : widget_message):void =
        if (Fill := StartFill?):
            Fill.SetColor(SponsorPink)
        if (Terms := FinePrint?):
            Terms.SetVisibility(widget_visibility.Hidden)

    # The dead channel lights concrete gray to sponsor pink like the others, so
    # it never reads as decoration. It just does not go anywhere.
    OnDeadHover(Message : widget_message):void =
        if (Edge := DeadEdge?):
            Edge.SetColor(SponsorPink)
        if (Label := DeadText?):
            Label.SetTextColor(SponsorPink)

    OnDeadUnhover(Message : widget_message):void =
        if (Edge := DeadEdge?):
            Edge.SetColor(ConcreteGray)
        if (Label := DeadText?):
            Label.SetTextColor(ConcreteGray)

    # =================================================================
    # THE DEAD CHANNEL (part of build item 8, brought forward)
    #
    # Nothing happens here, and that is the whole point. The static from the
    # channel change simply never stops, and any click puts the listings back.
    # =================================================================

    OnOffAirPressed(Message : widget_message):void =
        set ChannelToken += 1
        Token := ChannelToken
        spawn{ RunOffAir(Token) }

    RunOffAir(Token : int)<suspends>:void =
        HideEveryChannel()
        set HoldingSnow = true
        set ShowingBars = false
        set Popping = false
        SetBarsVisible(false)
        SetStaticVisible(true)

        # Both the flip sheet and the way out go up straight away, so a
        # contestant who presses the dead channel and immediately regrets it is
        # never stuck in it.
        if (Hatch := OffAirExit?):
            Hatch.SetVisibility(widget_visibility.Visible)
        if (Exit := DeadExit?):
            Exit.SetVisibility(widget_visibility.Visible)

        loop:
            Sleep(StaticFrameSeconds)

            # Leaving the channel, by the way out or by another press, ends
            # this. The noise boils while the snow is up, and during a pop as
            # well, since a pop is a burst of the same noise over the bars.
            if (Token = ChannelToken, HoldingSnow?):
                if (Popping?):
                    ScrambleStatic()
                else if (not ShowingBars?):
                    ScrambleStatic()
            else:
                break

    # A CLICK ANYWHERE ON THE DEAD CHANNEL FLIPS IT, snow to bars and back
    # again, with a burst of static over the switch. Kai's ruling: the flip is
    # the contestant's to make. There is no timer flipping it on its own; if
    # that is wanted back it is one loop, not a rebuild.
    OnOffAirDismissed(Message : widget_message):void =
        # A click landing mid-pop is ignored. Otherwise two pops overlap and
        # the channel ends up showing the opposite of what was asked for.
        if (Popping?):
            Print("DEBUG: dead channel flip ignored, one is already running.")
        else:
            spawn{ FlipDeadChannel() }

    FlipDeadChannel()<suspends>:void =
        StaticPop.Play()

        set Popping = true
        SetBarsVisible(false)
        SetStaticVisible(true)
        Sleep(DeadFlipPopSeconds)
        set Popping = false

        # Out of the pop and into whichever half was not showing.
        if (ShowingBars?):
            set ShowingBars = false
            SetBarsVisible(false)
            SetStaticVisible(true)
        else:
            set ShowingBars = true
            SetStaticVisible(false)
            SetBarsVisible(true)

    # The way back to the schedule. This is the only thing on the dead channel
    # that leaves it.
    OnDeadChannelExit(Message : widget_message):void =
        set HoldingSnow = false
        set ShowingBars = false
        set Popping = false
        SetBarsVisible(false)
        if (Exit := DeadExit?):
            Exit.SetVisibility(widget_visibility.Collapsed)
        ChangeChannel(false)

    SetBarsVisible(Wanted : logic):void =
        if (Card := BarCard?):
            if (Wanted?):
                Card.SetVisibility(widget_visibility.Visible)
            else:
                Card.SetVisibility(widget_visibility.Collapsed)

    # THE TEST CARD: flat vertical bars, nothing else. Seven of them, sharing
    # the width equally, and every colour is one of the locked palette so the
    # card cannot drift out of the show's look.
    BuildColourBars() : stack_box =
        Shades := array:
            StaticWhite
            LaserYellow
            PlasmaBlue
            PrizeGold
            SponsorPink
            DangerRed
            ConcreteGray

        var Bars : []stack_box_slot = array{}

        for (Shade : Shades):
            Bar := color_block:
                DefaultColor := Shade
                DefaultOpacity := 1.0
                DefaultDesiredSize := vector2{X := 8.0, Y := 8.0}

            set Bars += array{stack_box_slot{Widget := Bar, HorizontalAlignment := horizontal_alignment.Fill, VerticalAlignment := vertical_alignment.Fill, Distribution := option{1.0}}}

        Card := stack_box:
            Orientation := orientation.Horizontal
            Slots := Bars

        set BarCard = option{Card}
        Card

    # NO BUZZER on these two, by Kai's ruling. Only START SHOW buzzes. The
    # sound is the show starting, not a mouse wandering over the schedule.
    OnBoardHover(Message : widget_message):void =
        if (Edge := BoardEdge?):
            Edge.SetColor(SponsorPink)
        if (Label := BoardText?):
            Label.SetTextColor(SponsorPink)

    OnBoardUnhover(Message : widget_message):void =
        if (Edge := BoardEdge?):
            Edge.SetColor(PlasmaBlue)
        if (Label := BoardText?):
            Label.SetTextColor(LaserYellow)

    OnVaultHover(Message : widget_message):void =
        if (Edge := VaultEdge?):
            Edge.SetColor(SponsorPink)
        if (Label := VaultText?):
            Label.SetTextColor(SponsorPink)

    OnVaultUnhover(Message : widget_message):void =
        if (Edge := VaultEdge?):
            Edge.SetColor(PlasmaBlue)
        if (Label := VaultText?):
            Label.SetTextColor(LaserYellow)

    # =================================================================
    # THE DEBT COUNTER (build item 5)
    # =================================================================

    ShowDebtCounter(P : player):void =
        if (ShowDebt?):
            # Seeded from the save, so a debt partly paid off in an earlier run
            # is still partly paid off now.
            set DebtDrift = ReadDebtDrift(P)
            set ScoreAlreadyCredited = CashDrops.GetRunScore()

            Readout := text_block:
                DefaultText := ScreenLine(DebtLine(StartingDebt + DebtDrift))
                DefaultTextColor := DangerRed
                DefaultTextSize := 28.0
                DefaultJustification := text_justification.Right

            set DebtLabel = option{Readout}

            Panel := canvas:
                Slots := array:
                    canvas_slot:
                        Widget := Readout
                        Anchors := anchors{Minimum := vector2{X := 0.965, Y := 0.08}, Maximum := vector2{X := 0.965, Y := 0.08}}
                        Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 1.0, Y := 0.5}
                        SizeToContent := true

            set DebtRoot = option{Panel}

            # Its own layer, taking no input, and never removed: the counter has
            # to keep working through the match so the falling can be seen.
            Slot := player_ui_slot:
                ZOrder := 108
                InputMode := ui_input_mode.None

            if (PlayerUI := GetPlayerUI[P]):
                PlayerUI.AddWidget(Panel, Slot)
                Print("DEBUG: Debt counter up at ${StartingDebt + DebtDrift}, drift of {DebtDrift} carried in from the save.")
                spawn{ RunDebtCounter(P) }
            else:
                Print("WARNING: the debt counter could not be drawn for this contestant.")
        else:
            Print("DEBUG: Debt counter is switched off on the device.")

    # Interest up while off the air, cash down while on it, redraw, and write
    # to the save every so often.
    RunDebtCounter(P : player)<suspends>:void =
        loop:
            Sleep(DebtTickSeconds)

            # OFF THE AIR means either the show has not started yet or the
            # contestant is dead. Both are the same thing to a creditor.
            if (OffTheAir()?):
                set DebtDrift += DebtInterestPerTick

            # Only cash collected SINCE the last tick pays anything off.
            Score := CashDrops.GetRunScore()
            if (Score > ScoreAlreadyCredited):
                Paid := (Score - ScoreAlreadyCredited) * DebtPerScorePoint
                set DebtDrift -= Paid
                set ScoreAlreadyCredited = Score

            if (Label := DebtLabel?):
                Label.SetText(ScreenLine(DebtLine(StartingDebt + DebtDrift)))

            set TicksSinceDebtSaved += 1
            if (TicksSinceDebtSaved >= DebtSaveEveryTicks):
                set TicksSinceDebtSaved = 0
                SaveDebtDrift(P)

    OffTheAir()<transacts>:logic =
        if (not MatchHasStarted(Self)?):
            true
        else if (not OnAirLit?):
            true
        else:
            false

    # Reads the drift out of the career save. Guarded on the player being
    # active, because the digest is explicit that using an inactive player as a
    # key on one of these tables is a runtime error, not a quiet miss.
    ReadDebtDrift(P : player)<transacts>:int =
        if (P.IsActive[], Existing := CareerRecords[P]):
            return Existing.DebtDelta
        0

    # Writes the drift back, leaving every other field of the record exactly as
    # it was. Rank, records and bankroll belong to CareerRankManager.verse and
    # are only ever read here.
    SaveDebtDrift(P : player):void =
        if (P.IsActive[]):
            Existing := ReadWholeCareer(P)
            Updated := career_record:
                BestScore := Existing.BestScore
                BestTier := Existing.BestTier
                RankIndex := Existing.RankIndex
                LifetimeBankroll := Existing.LifetimeBankroll
                JustPromoted := Existing.JustPromoted
                DebtDelta := DebtDrift
            # Deliberately quiet on success. This runs once a second all match,
            # and a line here would bury every other message in the log.
            var Wrote : logic = false
            if (set CareerRecords[P] = Updated):
                set Wrote = true

            if (not Wrote?):
                Print("WARNING: the debt could not be written to the save, so this run's interest and repayments will be lost.")

    ReadWholeCareer(P : player)<transacts>:career_record =
        if (P.IsActive[], Existing := CareerRecords[P]):
            return Existing
        career_record{}

    # =================================================================
    # THE SPONSOR TICKER (build item 3)
    # =================================================================

    # The strip: a dark band, a yellow rule along its top edge the way a studio
    # chyron has one, its own few scanlines, and the text.
    #
    # No fringing on this text. The brief rules it out on small text and it is
    # right: at this size the red and blue copies turn the words to mush.
    BuildTicker() : overlay =
        Band := color_block:
            DefaultColor := BroadcastBlack
            DefaultOpacity := 0.9

        TopRule := color_block:
            DefaultColor := LaserYellow
            DefaultOpacity := 1.0
            DefaultDesiredSize := vector2{X := 8.0, Y := 3.0}

        Feed := text_block:
            DefaultText := ScreenLine(StationIdent)
            DefaultTextColor := LaserYellow
            DefaultTextSize := 22.0
            DefaultJustification := text_justification.Left
            # Clip rather than wrap, so a long window cannot push a second
            # line into the strip and double its height.
            DefaultOverflowPolicy := text_overflow_policy.Clip

        set TickerLabel = option{Feed}
        # Held so ShowTicker can put the whole strip away. The slot it lives in
        # is fixed once the screen is built, so hiding is the only way off.

        Strip := overlay:
            Slots := array:
                overlay_slot:
                    Widget := Band
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                overlay_slot:
                    Widget := TopRule
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                overlay_slot:
                    Widget := BuildScanlines(4)
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                overlay_slot:
                    Widget := Feed
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 24.0, Top := 0.0, Right := 24.0, Bottom := 0.0}

        set TickerStrip = option{Strip}
        Strip

    # Lays every slogan end to end with the station between them, then makes
    # sure the result is long enough to fill the window, then doubles it.
    BuildTickerFeed():void =
        var OneLoop : string = ""

        for (Slogan : SponsorSlogans):
            set OneLoop = "{OneLoop}{Slogan}{TickerSeparator}{StationIdent}{TickerSeparator}"

        # If the slogan list is empty there is nothing to lay end to end, and
        # the padding loop below would never finish. This is that guard.
        if (OneLoop.Length = 0):
            set OneLoop = "{StationIdent}{TickerSeparator}"

        # Repeat until one copy is at least a windowful, so the window can
        # never ask for more letters than exist.
        var Padded : string = OneLoop
        loop:
            if (Padded.Length >= TickerWindowChars):
                break
            set Padded = "{Padded}{OneLoop}"

        set TickerLoopLength = Padded.Length
        set TickerDoubled = "{Padded}{Padded}"

        Print("DEBUG: Ticker feed built, {TickerLoopLength} letters per loop from {SponsorSlogans.Length} slogan(s).")

    # The scroll. Moves the window one letter along, rewrites the strip, waits.
    RunTicker()<suspends>:void =
        loop:
            Sleep(TickerStepSeconds)

            # The strip belongs to the title screen, so once the show starts
            # there is nothing left to write on.
            if (MatchHasStarted(Self)?):
                break

            set TickerHead += 1
            if (TickerHead >= TickerLoopLength):
                set TickerHead = 0

            if (Label := TickerLabel?, Window := TickerDoubled.Slice[TickerHead, TickerHead + TickerWindowChars]):
                Label.SetText(ScreenLine(Window))

    # =================================================================
    # THE ON AIR LIGHT (build item 9)
    #
    # This is NOT part of the title screen. It is its own widget, added on its
    # own layer, and it is never taken down: title screen, gameplay, all of it.
    # Two things follow from that.
    #
    # It sits ABOVE the broadcast, on layer 110 against the broadcast's 100, so
    # the light is on even while the card is up. And it takes NO input, so
    # during gameplay it cannot steal the mouse from aiming. That is the whole
    # reason it is a second widget rather than another slot on the card: the
    # card takes the mouse, and the light must never.
    # =================================================================

    GoOnAir(P : player):void =
        if (ShowOnAir?):
            Box := BuildOnAirLight()
            set OnAirBox = option{Box}

            Light := canvas:
                Slots := array:
                    canvas_slot:
                        Widget := Box
                        Anchors := anchors{Minimum := vector2{X := 0.035, Y := 0.08}, Maximum := vector2{X := 0.035, Y := 0.08}}
                        Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.0, Y := 0.5}
                        SizeToContent := true

            Slot := player_ui_slot:
                ZOrder := 110
                InputMode := ui_input_mode.None

            if (PlayerUI := GetPlayerUI[P]):
                PlayerUI.AddWidget(Light, Slot)
                Print("DEBUG: ON AIR light lit, blinking every {BlinkSeconds}s.")
                spawn{ RunBlink() }
                spawn{ WatchForOffAir(P) }
            else:
                Print("WARNING: the ON AIR light could not be drawn for this contestant.")
        else:
            Print("DEBUG: ON AIR light is switched off on the device, so it was not drawn.")

    # A dark slab, a red bulb, and the words, with the fringe copies behind
    # them and its own few scanlines over the slab. The fringe offset is one
    # pixel here rather than three: at this text size three smears it.
    BuildOnAirLight() : overlay =
        Panel := color_block:
            DefaultColor := BroadcastBlack
            DefaultOpacity := 0.85
            DefaultDesiredSize := vector2{X := 196.0, Y := 54.0}

        Bulb := color_block:
            DefaultColor := DangerRed
            DefaultOpacity := 1.0
            DefaultDesiredSize := vector2{X := 20.0, Y := 20.0}

        Row := stack_box:
            Orientation := orientation.Horizontal
            Slots := array:
                stack_box_slot:
                    Widget := Bulb
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 14.0, Bottom := 0.0}
                stack_box_slot:
                    Widget := FringedText("ON AIR", 26.0, DangerRed, 1.0)
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

        Box := overlay:
            Slots := array:
                overlay_slot:
                    Widget := Panel
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                overlay_slot:
                    Widget := BuildScanlines(6)
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                overlay_slot:
                    Widget := Row
                    HorizontalAlignment := horizontal_alignment.Center
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

        Box

    # The blink. Reads BlinkSeconds fresh on every pass, so changing the rate
    # from elsewhere takes hold on the next blink rather than needing a
    # restart. The floor stops a rate of zero turning this into a loop with no
    # pause in it, which would lock the match up.
    RunBlink()<suspends>:void =
        loop:
            var Wait : float = BlinkSeconds
            if (Wait < 0.05):
                set Wait = 0.05
            Sleep(Wait)

            if (not OnAirLit?):
                break

            if (Box := OnAirBox?):
                if (BlinkVisible?):
                    set BlinkVisible = false
                    Box.SetVisibility(widget_visibility.Hidden)
                else:
                    set BlinkVisible = true
                    Box.SetVisibility(widget_visibility.Visible)

    # Watches for the contestant going off the air.
    #
    # WHAT COUNTS AS DEATH HERE. Not a health reading. The Death Save window in
    # GDD 3.4 deliberately keeps health off the floor while the commentator
    # screams for a rescue, so a health of zero never arrives. The honest
    # moment is the character no longer being active in the arena, which is
    # elimination, and that is what this waits for.
    #
    # The first loop waits for them to be alive at all, because for the first
    # few seconds of a match nobody has spawned yet and reading that as a death
    # would put the light out before the show began.
    WatchForOffAir(P : player)<suspends>:void =
        loop:
            Sleep(OnAirPollSeconds)
            if (IsStillOnAir(P)?):
                break

        loop:
            Sleep(OnAirPollSeconds)
            if (not IsStillOnAir(P)?):
                CutToBlack()
                break

    IsStillOnAir(P : player)<transacts>:logic =
        if (Character := P.GetFortCharacter[], Character.IsActive[]):
            true
        else:
            false

    # =================================================================
    # THE TWO SWITCHES LEFT REACHABLE
    #
    # Both are meant to be called from outside this file. The Hype Meter will
    # want SetBlinkSeconds. To reach either, the calling device needs one
    # @editable field of type broadcast_screen, pointed at this device in UEFN.
    # That wire is not made yet, and nothing needs it yet.
    # =================================================================

    # Change the blink rate mid-match. Faster means a smaller number.
    SetBlinkSeconds(Seconds : float):void =
        set BlinkSeconds = Seconds
        Print("DEBUG: ON AIR blink rate is now {Seconds}s.")

    # Off the air. The light goes dark and stays dark for the rest of the run.
    CutToBlack():void =
        set OnAirLit = false
        if (Box := OnAirBox?):
            Box.SetVisibility(widget_visibility.Hidden)
        Print("DEBUG: ON AIR light cut to black. The contestant is off the air.")

    # =================================================================
    # STARTING THE SHOW
    #
    # Takes the broadcast off air, gives the mouse and the HUD back, and lets
    # every waiting manager off the leash.
    # =================================================================

    ReleaseTheMatch(P : player):void =
        if (Root := Screen?, PlayerUI := GetPlayerUI[P]):
            PlayerUI.RemoveWidget(Root)
            set Screen = false

        if (HideGameHUD?):
            GetPlayspace().GetHUDController().ResetElementsForPlayer(P, array{creative_hud_identifier_all{}})

        if (P.IsActive[]):
            if (set MatchStartedFor[P] = true):
                Print("DEBUG: START SHOW pressed. The match is live.")
            else:
                Print("WARNING: START SHOW was pressed but the start flag could not be written, so the arena will stay empty. Restart the match.")
        else:
            Print("WARNING: START SHOW was pressed by a contestant who is no longer active.")

# The debt readout, spelled the way a bill is: a label, a dollar sign, and
# comma separated thousands. Commas() itself lives in hello_world_device.verse
# at module scope, so every file in this folder can borrow it.
DebtLine(Amount : int)<transacts>:string = "CONTESTANT DEBT: ${Commas(Amount)}"
