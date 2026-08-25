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
# listings framing, and 7 please stand by. Nothing from the brief is owed.
#
# THE SCHEDULE IS FOUR ROWS, and the dead channel is PAID PROGRAMMING. The
# brief's other one, the snow screen, was built and then taken out again on
# Kai's ruling: its colour bars became the PLEASE STAND BY card, the
# infomercial tells the same joke better by giving you something to watch, and
# it was the last thing on the screen holding snow indefinitely, which is the
# flashing Kai flagged as a seizure risk.
#
# One thing in the brief was never built and is not an oversight: the
# UNPAYABLE cap on the debt counter.
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
    # PAID PROGRAMMING, THE INFOMERCIAL (build item 8's second channel)
    #
    # KAI'S OWN WORDS, ALL OF THEM. Nothing here was written by Claude and
    # nothing here may be rewritten by it. The tone is fixed, and Kai has said
    # it was got wrong once already: an upbeat, over-excited late night advert.
    # Cheerful and desperate, NEVER menacing.
    # =================================================================

    # The card cycles these one at a time, forever.
    PaidSlogans : []string = array:
        "ARE YOU IN DEBT?"
        "DO YOU HAVE A PULSE?"
        "YOU COULD BE A WINNER!"
        "CASH! PRIZES! A TOASTER!"
        "NO EXPERIENCE NECESSARY!"
        "EVERYBODY LOVES A SLAYER!"
        "ASK ABOUT OUR PAYMENT PLAN!"
        "THOUSANDS HAVE APPLIED!"
        "SPONSOR ME, SLAYERS!"

    # The popups, the way a 1990s infomercial slams a price at you.
    PaidPopupLines : []string = array:
        "FREE TO ENTER!*"
        "FREE TO WATCH!"
        "ACT NOW!"
        "ACT SOONER!"
        "BONUS SECOND TOASTER!"
        "WINNERS GET PAID!*"
        "NOT SOLD IN STORES!"
        "NOT SOLD ANYWHERE!"
        "OPERATORS STANDING BY!"
        "NO CREDIT CHECK!"
        "NEW! SAME AS BEFORE!"
        "LIMITED SLOTS!"
        "WHY ARE YOU STILL READING!"
        "ACT NOW AND YOULL GET A BONUS SECOND TOASTER!"
        "NO NEED TO SIGN!*"
        "YOU MAY ALREADY BE ENTERED!"

    # The plaque at the top. A filled gold slab, not floating text.
    PaidPlaqueLabel : string = "★ SPECIAL TELEVISION OFFER ★"

    # Fixed, along the bottom above the hazard bar, in plasma blue.
    PaidFinePrint : string = "NOT VALID IN ALL SECTORS. TOASTER MAY BE PREVIOUSLY OWNED."

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

    # THE THREE SHADES THE SNOW IS PAINTED IN, and the trick that lets it look
    # like real snow without being dangerous.
    #
    # Kai flagged the original as bright enough to trigger a seizure in someone
    # with photosensitive epilepsy, and they were right: black against white
    # across a whole screen, many times a second. The first fix took it down to
    # three near-black shades, which was safe and did not look like snow at all.
    #
    # WHAT ACTUALLY HURTS IS THE WHOLE SCREEN CHANGING BRIGHTNESS, not one block
    # changing. So all three shades sit in the middle of the range and are
    # picked with equal odds, which means the AVERAGE brightness of the field is
    # the same on every single frame. The screen never flashes, because as a
    # whole it never gets brighter or darker. Individual blocks still jump
    # between light and dark, which is the part the eye reads as snow.
    #
    # Do not put pure white or near-black back in here. That is what makes the
    # whole field swing, and it is the thing that causes the harm.
    StaticDark : color = MakeColorFromHex("3A4049")
    StaticMid : color = MakeColorFromHex("6E7580")
    StaticLight : color = MakeColorFromHex("B4BAC2")

    # THE INFOMERCIAL'S GROUND, and the second colour outside the seven. Kai's
    # brief asks for a dimly lit studio rather than a void on that one card,
    # because a real late night advert is brighter than the programming around
    # it. Used there and nowhere else.
    #
    # White gets a second use on the same card, on the red popup badge. Kai's
    # ruling: red is in the seven, and white was already in the file for the
    # snow, so red and white together is not a new colour arriving.
    StudioBlue : color = MakeColorFromHex("1A1F2E")

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

    # =================================================================
    # PAID PROGRAMMING'S DIALS
    #
    # Kai's ruling, 2026-08-24: a SECOND dead channel at 10:00 PM, under THE
    # PRIZE VAULT. It reverses amendment 70g, which had cut the brief's two
    # dead channels down to one.
    # =================================================================

    @editable
    PaidTime : string = "10:00 PM"

    @editable
    PaidLabel : string = "PAID PROGRAMMING"

    # How long each slogan holds before the next replaces it.
    @editable
    PaidSloganSeconds : float = 2.5

    # THE MARQUEE BULBS, the most important thing on the card. Twelve across
    # the top and bottom, four down each side: thirty-two in all, which is the
    # brief's "thirty or so" with no reduction.
    @editable
    PaidBulbsAcross : int = 12

    @editable
    PaidBulbsDown : int = 4

    # How often the lit bulbs step one place round the ring. Every third bulb
    # is lit, so a quarter second reads as a chase rather than a flicker.
    @editable
    PaidBulbChaseSeconds : float = 0.25

    # THE POPUPS' OWN CLOCK, Kai's ruling twice over. They do not follow the
    # slogans, and they no longer arrive as a set of three that clears together
    # either: each of the three runs its own cycle, staggered against the other
    # two, so one is always arriving as another leaves. Quick, read, gone.
    @editable
    PaidPopupShowSeconds : float = 1.3

    # THE BOUNCE. The words on a popup swell and shrink the whole time it is up,
    # which is what sells it as an advert lunging at the viewer rather than a
    # label sitting on a shape. Verse can change a text size at any moment, so
    # this is a real animation and not a fake of one.
    #
    # The size everything starts from, and what it is multiplied by at the
    # smallest and largest points of the swell.
    @editable
    PaidPopupTextSize : float = 18.0

    @editable
    PaidPopupMinScale : float = 0.70

    @editable
    PaidPopupMaxScale : float = 1.30

    # How much bigger it gets each step, and how long a step takes. Together
    # these set how fast it bounces: bigger step or shorter sleep is faster.
    @editable
    PaidPopupBounceStep : float = 0.05

    @editable
    PaidPopupBounceSeconds : float = 0.035

    # The beat between one leaving and the next taking its place.
    @editable
    PaidPopupRestSeconds : float = 0.35

    # How far apart the three are started, so they never move together.
    @editable
    PaidPopupStaggerSeconds : float = 0.4

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
    # How many yellow and black pairs run across the bar. Narrower stripes read
    # as tape; wide ones read as a fence.
    HazardStripeCount : int = 16

    # How many rows the slant is built from. More is a smoother diagonal and
    # more blocks to draw.
    HazardRows : int = 8

    # How far each row is nudged past the one above it, as a fraction of one
    # stripe. THE ANGLE IS THE TOTAL, not this number: across all eight rows
    # this shifts the stripes about a third of a stripe width, which against
    # the height of the bar comes out near forty five degrees, the angle real
    # caution tape has. The first attempt shifted two whole stripes, which is
    # nearly horizontal and looked like a smear.
    HazardSlantPerRow : float = 0.04

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
    # the right edge; too low and it stops short of it, which is what Kai saw:
    # 130 letters reached about four fifths of the way across and left the last
    # of the bar empty. Tune by eye.
    @editable
    TickerWindowChars : int = 170

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

    # How coarse the static is. It started at 16 by 9, which is blocks the size
    # of a fist, and 48 by 27 was still too coarse for Kai. 64 by 36 puts it at
    # roughly thirty pixels a block, four times finer than it began.
    #
    # That is 2,304 blocks to recolor. It is only affordable because the snow
    # shows for half a second at a time: the channel that used to hold it
    # indefinitely went out with amendment 74. Raise these further only if the
    # frame rate can stand it.
    @editable
    StaticColumns : int = 64

    @editable
    StaticRows : int = 36

    # Seconds each static frame is held. 0.06 is about sixteen frames a second,
    # which is the flicker rate of bad tape.
    @editable
    StaticFrameSeconds : float = 0.10

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
    # THE GAME SHOW BUZZER, on ANY button becoming hovered. Kai's ruling,
    # reversing the earlier one that left the schedule silent: one sound for
    # hovering anything, one sound for pressing START SHOW, and that is all.
    @editable
    HoverBuzzer : audio_player_device = audio_player_device{}

    # THE DING-DING-DING CASH STINGER, on START SHOW.
    @editable
    StartStinger : audio_player_device = audio_player_device{}

    # THE SOUND OF THE SNOW. It starts the moment the noise appears and stops
    # the moment it goes, so the two are always the same length as each other
    # however long a channel change happens to be.
    #
    # Point this at an Audio Player holding a hiss, and set that device to LOOP:
    # the noise can be up for anything from a fraction of a second to a couple
    # of seconds, and a one-shot would run out or overrun.
    @editable
    SnowSound : audio_player_device = audio_player_device{}

    # THE SOUND OF THE TEST CARD. It starts when the card is actually on the
    # screen, which is after the burst of snow that brings it up, and stops the
    # moment the card goes. Set the device to LOOP, like the snow: the card
    # holds for two and a half seconds after START SHOW and four and a half
    # when it comes up idle, so one sound has to cover both.
    @editable
    StandBySound : audio_player_device = audio_player_device{}

    # How long the ding is left alone with the title screen before the picture
    # cuts to snow. Kai's ruling: the ding belongs to the card you pressed, not
    # to the noise that follows it.
    @editable
    StartDingSeconds : float = 0.6

    # Hide Fortnite's own HUD while the broadcast is up. Untick only for
    # debugging: with the HUD showing, the health bar and hotbar draw straight
    # over the card. Item 9 covers the ON AIR light's own fight with that HUD.
    @editable
    HideGameHUD : logic = true

    # THE WHITE RIPPLE THAT DRAWS WHERE FOOTSTEPS ARE. It is Fortnite's own
    # accessibility readout for movement sound, and in a top-down arena where
    # every hostile is already on screen it tells the contestant nothing they
    # cannot see, while cluttering the floor they are trying to read.
    #
    # Hidden when the show starts, because until then the whole HUD is down
    # anyway. Untick to have it back.
    @editable
    HideFootstepIndicator : logic = true

    # THE MINIMAP. A top-down arena already shows the contestant the whole room,
    # so a small map of that same room in the corner is a picture of what they
    # are looking at. It was parked when the ON AIR light was built and Kai
    # asked for it out on 2026-08-25.
    #
    # BOTH SPELLINGS ARE HIDDEN. Epic's own list carries the identifier twice,
    # once correctly and once as "mimimap", and there is no way to tell from
    # outside which of the two is the live one, so this asks for both.
    @editable
    HideMinimap : logic = true

    # THE GAME IN PROGRESS BANNER, and the build menu with it. Neither belongs
    # on a game show: one narrates the match state the contestant is already
    # living through, and the other offers a Fortnite mechanic this game does
    # not use. The BUILD MENU TICK ONLY TAKES THE BUTTON OFF THE SCREEN. Whether
    # a contestant can build at all is an Island Settings checkbox, which no
    # script can reach.
    @editable
    HideRoundInfo : logic = true

    @editable
    HideBuildMenu : logic = true

    # THE WHOLE TOP RIGHT CORNER, cleared for the cash counter. Fortnite fills
    # it with the map prompt that the middle mouse button pings, the player
    # count, the team readout, the storm timer and its warnings, the round
    # timer and the elimination counter. Not one of them means anything in a
    # single-player arena with its own score.
    #
    # THE FULL MAP IS NOT IN THIS LIST, because it is not a HUD element. Opening
    # it is a player action, and switching it off is an Island Settings
    # checkbox rather than anything a script can reach.
    @editable
    ClearTopRight : logic = true

    # THE LIVE BADGE. The ON AIR plaque belongs to the title screen now, and
    # Kai's reference picture has a small LIVE light on the arena itself. Same
    # idea, same blinking red dot, shorter word. Top LEFT by Kai's ruling, in
    # the corner the plaque itself uses on the title screen, and well clear of
    # the Hype thermometer which sits halfway down that edge.
    #
    # It reuses the ON AIR light's blink: whichever badge was built last is the
    # one the blink drives, so nothing here needs its own loop.
    @editable
    ShowLive : logic = true

    @editable
    LiveLabel : string = "LIVE"

    # =================================================================
    # PLEASE STAND BY (build item 7)
    #
    # The station gives up on a contestant who is doing nothing. It only ever
    # fires on the listings: sitting on the leaderboard, the prize vault or
    # the dead channel is the POINT of those, and yanking one away mid-loop
    # ruins the joke.
    # =================================================================

    # Untick to stop the card ever appearing.
    @editable
    ShowStandBy : logic = true

    # Seconds of doing nothing before the card comes up.
    @editable
    StandByIdleSeconds : float = 30.0

    # How often the idle clock is looked at. Half a second is far finer than
    # thirty seconds needs and costs nothing.
    @editable
    StandByPollSeconds : float = 0.5

    # How long the card holds before the listings come back, when it came up
    # from sitting idle. Nothing is pressed to leave it: it goes on its own.
    @editable
    StandByHoldSeconds : float = 4.5

    # How long it holds after START SHOW, before the arena appears.
    @editable
    StandByBeforeShowSeconds : float = 2.5

    # What the card says.
    @editable
    StandByLine : string = "PLEASE STAND BY"

    # How big those words are.
    @editable
    StandByTextSize : float = 64.0

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

    # The ON AIR light's box, held so death can take the whole thing away.
    var OnAirBox : ?overlay = false

    # The red dot inside it, held so the blink can reach the dot alone.
    var OnAirBulb : ?color_block = false

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

    # The debt readout. There is no layer of its own any more: it is a slot of
    # the broadcast card, and it goes when the card goes.
    var DebtLabel : ?text_block = false

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

    # The idle card, built once and left hidden like every other channel.
    var StandByCard : ?canvas = false

    # The click sheet on it. Only ever shown for the idle card, never for the
    # one on the way into the arena.
    var StandByExit : ?button = false

    # True while the card is up, so the idle clock cannot fire it again
    # underneath itself.
    var StandingBy : logic = false

    # Seconds since anything was pressed. Reset by every channel change.
    var IdleSeconds : float = 0.0

    # True while the listings are the picture. The card may only fire there.
    var OnListings : logic = true

    # True while the test card's own sound is playing, for the same reason.
    var StandBySoundOn : logic = false

    # True while the hiss is playing, so showing the noise twice running does
    # not start a second copy of it over the first.
    var SnowPlaying : logic = false

    # True while the broadcast is on the screen. The idle clock and the
    # infomercial's three loops run off THIS rather than off the match start
    # flag, because a flag left over from the last playtest would stop all four
    # of them before they ever ran.
    var ScreenIsUp : logic = true

    # PAID PROGRAMMING. The card, and the button's two recolourable pieces.
    var PaidPanel : ?canvas = false
    var PaidEdge : ?color_block = false
    var PaidText : ?text_block = false

    # True only while the infomercial is the picture. The bulbs, the slogans
    # and the popups all stand still unless this is set, so a hidden card
    # costs nothing.
    var PaidShowing : logic = false

    # Every bulb, in RING order: along the top, down the right, back along the
    # bottom, up the left. Ring order is what makes the chase travel round the
    # card rather than jump about.
    var PaidBulbs : []color_block = array{}

    # How far the lit bulbs have travelled round.
    var PaidBulbOffset : int = 0

    # Handed back by BuildBulbRow, because a function returns one thing and
    # both the widget and its blocks are needed.
    var PaidBulbBuffer : []color_block = array{}

    # The slogan and its ONE fringe copy. Both are rewritten together, or the
    # fringe is left showing the previous line.
    var PaidSloganText : ?text_block = false
    var PaidSloganFringe : ?text_block = false
    var PaidSloganIndex : int = 0

    # The three popups and their labels, registered as they are built. Three
    # different shapes rather than three of one, by Kai's ruling: a spiky gold
    # badge, a red sticker with a white border and white words, and a hot pink
    # banner. Four palette colours and white, and nothing off-scheme.
    var PaidPopupBursts : []overlay = array{}
    var PaidPopupTexts : []text_block = array{}

    # The popup line just used, so the next one is never the same.
    var LastPopupShown : int = -1

    # Which of the fourteen places are in use right now. A runner claims a free
    # one at random and lets it go again when the advert leaves, which is what
    # keeps four runners choosing at random from ever landing on the same one.
    var PopupBusy : []logic = array{}

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

        # WIPE THE MATCH START FLAG, and do it first. A playtest restarted in
        # the same editor session can leave it set from the run before, which
        # starts the waves behind the title screen and silently switches off
        # everything that waits on it: the idle card, the marquee chase, the
        # slogans and the popups. Two playtests were lost to this before the log
        # gave it up.
        for (P : Playspace.GetPlayers()):
            if (set MatchStartedFor[P] = false):
                Print("DEBUG: Match start flag wiped for a contestant, in case the last playtest left it set.")

        Playspace.PlayerAddedEvent().Subscribe(OnPlayerAdded)

        for (P : Playspace.GetPlayers()):
            SeedDebt(P)
            ShowBroadcast(P)
            StartHudLoops(P)

    # A contestant who arrives after this device has begun still gets the
    # broadcast, unless the show has already started. The ON AIR light is
    # separate and goes up either way, because it belongs to the whole match
    # and not to the title screen.
    OnPlayerAdded(P : player):void =
        if (MatchHasStarted(Self)?):
            Print("DEBUG: Broadcast skipped for a contestant who joined after the show started.")
        else:
            SeedDebt(P)
            ShowBroadcast(P)
            StartHudLoops(P)

    # Read the carried-over debt before anything draws it.
    SeedDebt(P : player):void =
        if (ShowDebt?):
            set DebtDrift = ReadDebtDrift(P)
            set ScoreAlreadyCredited = CashDrops.GetRunScore()

    # The three loops behind the two permanent readouts. Started once, and they
    # follow whichever copy of the widgets is currently on screen.
    StartHudLoops(P : player):void =
        if (ShowOnAir?):
            Print("DEBUG: ON AIR light lit, blinking every {BlinkSeconds}s.")
            spawn{ RunBlink() }
            spawn{ WatchForOffAir(P) }

        if (ShowDebt?):
            Print("DEBUG: Debt counter up at ${StartingDebt + DebtDrift}, drift of {DebtDrift} carried in from the save.")
            spawn{ RunDebtCounter(P) }

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
            DefaultTextSize := 13.0
            DefaultJustification := text_justification.Left

        SmallPrint.SetVisibility(widget_visibility.Hidden)
        set FinePrint = option{SmallPrint}

        Board := BuildBoardPanel()
        Vault := BuildVaultPanel()

        # Built now and left hidden, so switching channel is instant and
        # nothing has to be rebuilt on a press.
        Board.SetVisibility(widget_visibility.Collapsed)
        Vault.SetVisibility(widget_visibility.Collapsed)

        Channels := BuildChannelStack()

        # THE ON AIR LIGHT AND THE DEBT COUNTER, BUILT INTO THE BROADCAST.
        #
        # They each used to live on a layer of their own above it, and across
        # four playtests neither ever appeared, however the layer was built.
        # Rather than keep guessing at why, they are slots of the card itself
        # now, which is the one canvas proven to draw. A second, separate copy
        # goes up when the show starts and the card comes down, because both are
        # ruled to last the whole match.
        TitleLight := BuildOnAirLight()
        TitleDebt := BuildDebtReadout()

        set BoardPanel = option{Board}
        set VaultPanel = option{Vault}
        set ChannelGroup = option{Channels}

        # The idle card. Built now and left hidden, like every other channel.
        StandBy := BuildStandByCard()
        StandBy.SetVisibility(widget_visibility.Collapsed)
        set StandByCard = option{StandBy}

        # The infomercial, the same way.
        Paid := BuildPaidPanel()
        Paid.SetVisibility(widget_visibility.Collapsed)
        set PaidPanel = option{Paid}

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
                    Anchors := anchors{Minimum := vector2{X := 0.06, Y := 0.355}, Maximum := vector2{X := 0.94, Y := 0.405}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 10

                # THE SCHEDULE FILLS THE SCREEN, rather than sitting in a
                # 700-pixel column down the left of it. Anchored to a BOX
                # instead of a point, so the slabs are measured against the
                # screen and stretch with it. The five rows share the height
                # between them, START SHOW taking a little more as the primary.
                canvas_slot:
                    Widget := Channels
                    Anchors := anchors{Minimum := vector2{X := 0.06, Y := 0.42}, Maximum := vector2{X := 0.94, Y := 0.82}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
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
                canvas_slot:
                    Widget := Paid
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 20

                # -- the static ---------------------------------------
                # ON THE CARD, not on a layer of its own above it, so it can
                # never swallow a press meant for something under it. It only
                # ever shows for half a second while a channel changes: the
                # snow that used to hold indefinitely went out with the dead
                # channel, and with it the flashing Kai flagged as a seizure
                # risk.
                canvas_slot:
                    Widget := BuildStatic()
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 39

                # -- the stand by card, over the whole broadcast -------
                # Above the ticker and the scanlines, because cutting to a
                # card means the picture is gone, not dressed. Nothing in it
                # is pressable: it leaves on a timer.
                canvas_slot:
                    Widget := StandBy
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 50

                # -- the ON AIR light and the debt counter -------------
                # Above the panels, so they are still up on the leaderboard,
                # the prize vault and the infomercial. Under the stand by card,
                # which is a station with no picture at all.
                canvas_slot:
                    Widget := TitleLight
                    Anchors := anchors{Minimum := vector2{X := 0.035, Y := 0.075}, Maximum := vector2{X := 0.035, Y := 0.075}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.0, Y := 0.5}
                    SizeToContent := true
                    ZOrder := 32
                canvas_slot:
                    Widget := TitleDebt
                    Anchors := anchors{Minimum := vector2{X := 0.965, Y := 0.075}, Maximum := vector2{X := 0.965, Y := 0.075}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 1.0, Y := 0.5}
                    SizeToContent := true
                    ZOrder := 32

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

            if (ShowStandBy?):
                spawn{ RunIdleWatch() }

            # The infomercial's three loops. All three stand still while the
            # card is not the picture, so nothing is spent on a hidden channel.
            spawn{ RunMarqueeChase() }
            spawn{ RunSloganCycle() }
            spawn{ RunPopups() }

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

    # A yellow and black hazard bar, SLANTED, so it reads as caution tape
    # rather than as a row of fence posts.
    #
    # HOW THE SLANT IS FAKED, since a widget cannot be rotated. The bar is not
    # one row of stripes any more, it is a stack of thin rows, and each row is
    # nudged sideways a little further than the row above it. Step down through
    # them and the stripes walk across, which the eye reads as a diagonal. The
    # nudge is a transparent block at the start of each row, sized by the same
    # Distribution trick the stripes themselves use, so there is no pixel
    # arithmetic and it holds at any width.
    #
    # It is a staircase rather than a true diagonal, and at this bar height the
    # steps are a couple of pixels each, which does not read as steps.
    BuildHazardBar() : stack_box =
        var Bands : []stack_box_slot = array{}
        var Shift : float = 0.02

        # WHAT MADE THE FIRST SLANT LOOK WRONG. Only a leading spacer was
        # added, so every row was a different total width, and the stripes in it
        # were squeezed to fit. Each row down the bar had slightly narrower
        # stripes than the one above, which reads as a smear rather than as a
        # constant angle.
        #
        # A TRAILING SPACER FIXES IT. The lead grows and the tail shrinks by the
        # same amount, so every row adds up to exactly the same total and the
        # stripes come out identical. All that changes down the bar is where the
        # row starts, which is the whole point.
        Total := HazardSlantPerRow * 8.0

        for (Row := 1..HazardRows):
            var Cells : []stack_box_slot = array{}

            Lead := color_block:
                DefaultColor := BroadcastBlack
                DefaultOpacity := 1.0
                DefaultDesiredSize := vector2{X := 8.0, Y := 8.0}

            set Cells += array{stack_box_slot{Widget := Lead, HorizontalAlignment := horizontal_alignment.Fill, VerticalAlignment := vertical_alignment.Fill, Distribution := option{Shift}}}

            for (Index := 1..HazardStripeCount):
                Stripe := color_block:
                    DefaultColor := LaserYellow
                    DefaultOpacity := 1.0
                    DefaultDesiredSize := vector2{X := 8.0, Y := 8.0}

                Gap := color_block:
                    DefaultColor := BroadcastBlack
                    DefaultOpacity := 1.0
                    DefaultDesiredSize := vector2{X := 8.0, Y := 8.0}

                set Cells += array{stack_box_slot{Widget := Stripe, HorizontalAlignment := horizontal_alignment.Fill, VerticalAlignment := vertical_alignment.Fill, Distribution := option{1.0}}}
                set Cells += array{stack_box_slot{Widget := Gap, HorizontalAlignment := horizontal_alignment.Fill, VerticalAlignment := vertical_alignment.Fill, Distribution := option{1.0}}}

            Tail := color_block:
                DefaultColor := BroadcastBlack
                DefaultOpacity := 1.0
                DefaultDesiredSize := vector2{X := 8.0, Y := 8.0}

            set Cells += array{stack_box_slot{Widget := Tail, HorizontalAlignment := horizontal_alignment.Fill, VerticalAlignment := vertical_alignment.Fill, Distribution := option{Total + 0.04 - Shift}}}

            Band := stack_box:
                Orientation := orientation.Horizontal
                Slots := Cells

            set Bands += array{stack_box_slot{Widget := Band, HorizontalAlignment := horizontal_alignment.Fill, VerticalAlignment := vertical_alignment.Fill, Distribution := option{1.0}}}
            set Shift += HazardSlantPerRow

        Bar := stack_box:
            Orientation := orientation.Vertical
            Slots := Bands

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
        # The fine print, built in ShowBroadcast and hidden until the mouse
        # rests on START SHOW. Reached here so it can ride on the slab.
        var StartTerms : text_block = text_block{}
        if (Terms := FinePrint?):
            set StartTerms = Terms

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
                # THE LIABILITY SITS UNDER THE PROGRAMME NAME, not along the
                # bottom of the slab. Kai's ruling. It is inside the row rather
                # than laid over it, in the same column the title is in, which
                # is what makes the two line up however wide the button gets.
                overlay_slot:
                    Widget := StartListingRow(StartTime, StartLabelText, StartTerms)
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 28.0, Top := 0.0, Right := 28.0, Bottom := 0.0}

        StartButton := button:
            Slot := button_slot:
                Widget := StartSlab
                HorizontalAlignment := horizontal_alignment.Fill
                VerticalAlignment := vertical_alignment.Fill
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
                HorizontalAlignment := horizontal_alignment.Fill
                VerticalAlignment := vertical_alignment.Fill
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
                HorizontalAlignment := horizontal_alignment.Fill
                VerticalAlignment := vertical_alignment.Fill
                Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

        VaultButton.OnClick().Subscribe(OnCollectablesPressed)
        VaultButton.HighlightEvent().Subscribe(OnVaultHover)
        VaultButton.UnhighlightEvent().Subscribe(OnVaultUnhover)

        # PAID PROGRAMMING, the second dead channel. Dressed exactly like the
        # other one, because they are the same kind of thing: pressable, and
        # going nowhere.
        PaidEdgeBlock := color_block:
            DefaultColor := ConcreteGray
            DefaultOpacity := 1.0
            DefaultDesiredSize := vector2{X := 700.0, Y := 76.0}

        PaidLabelText := text_block:
            DefaultText := ScreenLine(PaidLabel)
            DefaultTextColor := ConcreteGray
            DefaultTextSize := 30.0
            DefaultJustification := text_justification.Left

        set PaidEdge = option{PaidEdgeBlock}
        set PaidText = option{PaidLabelText}

        PaidButton := button:
            Slot := button_slot:
                Widget := ListingSlab(PaidEdgeBlock, PaidTime, PaidLabelText)
                HorizontalAlignment := horizontal_alignment.Fill
                VerticalAlignment := vertical_alignment.Fill
                Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

        PaidButton.OnClick().Subscribe(OnPaidPressed)
        PaidButton.HighlightEvent().Subscribe(OnPaidHover)
        PaidButton.UnhighlightEvent().Subscribe(OnPaidUnhover)

        # THE ROWS SHARE THE HEIGHT of the box the stack is anchored to, so
        # the schedule fills the screen at any shape. START SHOW takes a third
        # more than the rest, which is what keeps it reading as the primary.
        Stack := stack_box:
            Orientation := orientation.Vertical
            Slots := array:
                stack_box_slot:
                    Widget := StartButton
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Distribution := option{1.35}
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 10.0}
                stack_box_slot:
                    Widget := BoardButton
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Distribution := option{1.0}
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 8.0}
                stack_box_slot:
                    Widget := VaultButton
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Distribution := option{1.0}
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 8.0}
                stack_box_slot:
                    Widget := PaidButton
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Distribution := option{1.0}
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
    # The START SHOW row, which is the plain one with the liability stacked
    # under the programme name. Both sit in the same column, so they share a
    # left edge whatever the button is doing.
    StartListingRow(TimeText : string, TitleText : text_block, Terms : text_block) : stack_box =
        Clock := text_block:
            DefaultText := ScreenLine(TimeText)
            DefaultTextColor := BroadcastBlack
            DefaultTextSize := 24.0
            DefaultJustification := text_justification.Left

        Column := stack_box:
            Orientation := orientation.Vertical
            Slots := array:
                stack_box_slot:
                    Widget := TitleText
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Center
                stack_box_slot:
                    Widget := Terms
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 0.0, Top := 2.0, Right := 0.0, Bottom := 0.0}

        Row := stack_box:
            Orientation := orientation.Horizontal
            Slots := array:
                stack_box_slot:
                    Widget := Clock
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Center
                    Distribution := option{1.0}
                stack_box_slot:
                    Widget := Column
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Center
                    Distribution := option{3.0}

        Row

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
                # FILL WITH A SIX PIXEL INSET, not a fixed size centred in the
                # edge. The border used to be whatever was left over between a
                # 700 wide edge and a 688 wide middle, so the slab could not
                # stretch without the border growing into a frame with it.
                overlay_slot:
                    Widget := Inner
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Padding := margin{Left := 6.0, Top := 6.0, Right := 6.0, Bottom := 6.0}
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
    # NO GATE AT ALL, by Kai's ruling. The buzz used to be held off for a
    # fraction of a second after each one so it could not retrigger over
    # itself, and running quickly down the schedule meant hovers that made no
    # sound. Kai's words: it should play the moment the mouse hits the button,
    # and if the sound is longer than the move to the next one, it just plays
    # again. So it does, over the top of itself.
    PlayBuzzer(P : player):void =
        HoverBuzzer.Play()

    OnStartPressed(Message : widget_message):void =
        # The cash stinger fires before the broadcast comes down, so the ding
        # lands over the cut to the arena rather than after it. The sound is a
        # device out in the world and carries on playing once the screen is
        # gone, so nothing has to be held back to hear it.
        StartStinger.Play()

        # The ding stays on the press, so pressing is answered on the frame it
        # happens rather than three seconds later.
        if (not StandingBy?):
            set StandingBy = true
            if (ShowStandBy?):
                spawn{ RunStandByThenShow(Message.Player) }
            else:
                ReleaseTheMatch(Message.Player)

    # These are not menu items. They are channels, so pressing one changes the
    # channel: everything cuts to static, and the new picture arrives after it.
    OnLeaderboardPressed(Message : widget_message):void =
        set OnListings = false
        set PaidShowing = false
        ChangeChannel(BoardPanel)

    OnCollectablesPressed(Message : widget_message):void =
        set OnListings = false
        set PaidShowing = false
        ChangeChannel(VaultPanel)

    # Both panels share one BACK, because only one can ever be open. Passing
    # nothing as the destination means the listings themselves.
    OnBackPressed(Message : widget_message):void =
        set OnListings = true
        set PaidShowing = false
        ChangeChannel(false)

    # =================================================================
    # CHANGING CHANNEL (build item 4)
    # =================================================================

    ChangeChannel(Target : ?canvas):void =
        set ChannelToken += 1
        Token := ChannelToken

        # Any change at all is somebody doing something, so the idle clock
        # goes back to nothing. Every channel change passes through here.
        set IdleSeconds = 0.0

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
        if (Card := StandByCard?):
            Card.SetVisibility(widget_visibility.Collapsed)
        if (Paid := PaidPanel?):
            Paid.SetVisibility(widget_visibility.Collapsed)

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

    # One frame of noise. Three shades, picked fresh for every block, with
    # equal odds so the field averages out to the same brightness every frame.
    # See StaticDark above for why that matters more than the speed does.
    ScrambleStatic():void =
        for (Block : StaticBlocks):
            Roll := GetRandomInt(0, 2)
            var Shade : color = StaticMid
            if (Roll = 0):
                set Shade = StaticDark
            else if (Roll = 1):
                set Shade = StaticMid
            else:
                set Shade = StaticLight
            Block.SetColor(Shade)

    # THE ONE PLACE THE NOISE GOES ON AND OFF, which is why the sound lives
    # here rather than at each of the callers. Whatever puts snow on the screen
    # starts the hiss, and whatever takes it off stops it, with no way to get
    # the two out of step.
    SetStaticVisible(Wanted : logic):void =
        if (Sheet := StaticSheet?):
            if (Wanted?):
                Sheet.SetVisibility(widget_visibility.Visible)
            else:
                Sheet.SetVisibility(widget_visibility.Collapsed)

        if (Wanted?):
            if (not SnowPlaying?):
                set SnowPlaying = true
                SnowSound.Play()
        else:
            if (SnowPlaying?):
                set SnowPlaying = false
                SnowSound.Stop()

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

    # ANY ROW OF FLAT VERTICAL BARS, sharing the width equally. The test card's
    # three bands are all this with different colours in them, and every colour
    # is one of the locked palette so the card cannot drift out of the look.
    BuildBarStrip(Shades : []color) : stack_box =
        var Bars : []stack_box_slot = array{}

        for (Shade : Shades):
            Bar := color_block:
                DefaultColor := Shade
                DefaultOpacity := 1.0
                DefaultDesiredSize := vector2{X := 8.0, Y := 8.0}

            set Bars += array{stack_box_slot{Widget := Bar, HorizontalAlignment := horizontal_alignment.Fill, VerticalAlignment := vertical_alignment.Fill, Distribution := option{1.0}}}

        Strip := stack_box:
            Orientation := orientation.Horizontal
            Slots := Bars

        Strip

    BuildColourBars() : stack_box =
        BuildBarStrip(array{StaticWhite, LaserYellow, PlasmaBlue, PrizeGold, SponsorPink, DangerRed, ConcreteGray})

    # NO BUZZER on these two, by Kai's ruling. Only START SHOW buzzes. The
    # sound is the show starting, not a mouse wandering over the schedule.
    OnBoardHover(Message : widget_message):void =
        PlayBuzzer(Message.Player)
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
        PlayBuzzer(Message.Player)
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

            # The strip belongs to the title screen, so once the broadcast
            # comes down there is nothing left to write on. This reads the
            # screen rather than the match start flag for the same reason the
            # other four loops do: a flag left set by the previous playtest
            # stopped the ticker dead before it had scrolled a letter.
            if (not ScreenIsUp?):
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

    # THE LIVE BADGE, put up when the broadcast comes down. Smaller than the
    # ON AIR plaque and in the opposite corner, because the contestant needs the
    # arena more than they need a sign.
    ShowLiveBadge(P : player):void =
        if (ShowLive?):
            Badge := BuildLiveLight()

            # The invisible full-screen block, so the canvas has a size to be.
            Stretch := color_block:
                DefaultColor := BroadcastBlack
                DefaultOpacity := 0.0

            Layer := canvas:
                Slots := array:
                    canvas_slot:
                        Widget := Stretch
                        Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                        Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                        SizeToContent := false
                        ZOrder := 0
                    canvas_slot:
                        Widget := Badge
                        Anchors := anchors{Minimum := vector2{X := 0.025, Y := 0.045}, Maximum := vector2{X := 0.025, Y := 0.045}}
                        Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                        Alignment := vector2{X := 0.0, Y := 0.5}
                        SizeToContent := true
                        ZOrder := 1

            Slot := player_ui_slot:
                ZOrder := 107
                InputMode := ui_input_mode.None

            if (PlayerUI := GetPlayerUI[P]):
                PlayerUI.AddWidget(Layer, Slot)
                Print("DEBUG: LIVE badge up for the match.")
            else:
                Print("WARNING: the LIVE badge could not be drawn for this contestant.")

    # The badge itself. Built from the same pieces as the ON AIR plaque and
    # recorded in the same two places, so the blink already running drives it.
    BuildLiveLight() : overlay =
        Panel := color_block:
            DefaultColor := BroadcastBlack
            DefaultOpacity := 0.85
            DefaultDesiredSize := vector2{X := 132.0, Y := 44.0}

        Bulb := color_block:
            DefaultColor := DangerRed
            DefaultOpacity := 1.0
            DefaultDesiredSize := vector2{X := 16.0, Y := 16.0}

        set OnAirBulb = option{Bulb}

        Words := text_block:
            DefaultText := ScreenLine(LiveLabel)
            DefaultTextColor := DangerRed
            DefaultTextSize := 22.0
            DefaultJustification := text_justification.Left

        Row := stack_box:
            Orientation := orientation.Horizontal
            Slots := array:
                stack_box_slot:
                    Widget := Bulb
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 12.0, Bottom := 0.0}
                stack_box_slot:
                    Widget := Words
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
                    Widget := BuildScanlines(4)
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                overlay_slot:
                    Widget := Row
                    HorizontalAlignment := horizontal_alignment.Center
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

        set OnAirBox = option{Box}
        Box

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

        # Held on its own, because the BULB is what blinks. Blinking the whole
        # box took the words away with it, which reads as the plaque flickering
        # rather than as a light. Kai's ruling: the red dot blinks.
        set OnAirBulb = option{Bulb}

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

        # Recorded here rather than by the caller, so whichever copy was built
        # last is the one the blink drives and the one death puts out.
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

        set OnAirBox = option{Box}
        Box

    # The debt readout on its own, so the broadcast and the gameplay layer can
    # each have one. Whichever was built last is the one the counter rewrites.
    BuildDebtReadout() : text_block =
        Readout := text_block:
            DefaultText := ScreenLine(DebtLine(StartingDebt + DebtDrift))
            DefaultTextColor := DangerRed
            DefaultTextSize := 28.0
            DefaultJustification := text_justification.Right

        set DebtLabel = option{Readout}
        Readout

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

            if (Bulb := OnAirBulb?):
                if (BlinkVisible?):
                    set BlinkVisible = false
                    Bulb.SetVisibility(widget_visibility.Hidden)
                else:
                    set BlinkVisible = true
                    Bulb.SetVisibility(widget_visibility.Visible)

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
    # PAID PROGRAMMING (build item 8's second dead channel)
    #
    # A late night infomercial for the show itself. It is an ADVERT, not a
    # warning: cheerful and desperate, never menacing.
    #
    # It is the one card that sits LIGHTER than everything else, on charcoal
    # blue rather than broadcast black, because a real late night advert is
    # brighter than the programming around it.
    #
    # THE VHS TREATMENT IS LIGHTER HERE TOO. Faint scanlines, and ONE fringe
    # copy behind the slogan rather than two, because heavy fringing on this
    # card reads as broken instead of retro.
    # =================================================================

    BuildPaidPanel() : canvas =
        Backdrop := color_block:
            DefaultColor := StudioBlue
            DefaultOpacity := 1.0

        # THE PLAQUE. A filled gold slab with dark text sitting in it, rather
        # than gold text floating on the ground.
        PlaqueFill := color_block:
            DefaultColor := PrizeGold
            DefaultOpacity := 1.0
            DefaultDesiredSize := vector2{X := 760.0, Y := 74.0}

        PlaqueText := text_block:
            DefaultText := ScreenLine(PaidPlaqueLabel)
            DefaultTextColor := BroadcastBlack
            DefaultTextSize := 34.0
            DefaultJustification := text_justification.Center

        Plaque := overlay:
            Slots := array:
                overlay_slot:
                    Widget := PlaqueFill
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                overlay_slot:
                    Widget := PlaqueText
                    HorizontalAlignment := horizontal_alignment.Center
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

        # THE SLOGAN CARD. Black inside a hot pink border, because keeping the
        # middle black is what makes the yellow punch.
        Border := color_block:
            DefaultColor := SponsorPink
            DefaultOpacity := 1.0
            DefaultDesiredSize := vector2{X := 940.0, Y := 260.0}

        Inner := color_block:
            DefaultColor := BroadcastBlack
            DefaultOpacity := 1.0
            DefaultDesiredSize := vector2{X := 934.0, Y := 254.0}

        FringeCopy := text_block:
            DefaultText := ScreenLine(FirstSlogan())
            DefaultTextColor := FringeLeftColor
            DefaultTextSize := 72.0
            DefaultJustification := text_justification.Center

        TrueSlogan := text_block:
            DefaultText := ScreenLine(FirstSlogan())
            DefaultTextColor := LaserYellow
            DefaultTextSize := 72.0
            DefaultJustification := text_justification.Center

        set PaidSloganFringe = option{FringeCopy}
        set PaidSloganText = option{TrueSlogan}

        Card := overlay:
            Slots := array:
                overlay_slot:
                    Widget := Border
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                # A THREE PIXEL INSET, which is the brief's border thickness.
                # It used to be whatever was left between a 940 wide edge and a
                # 934 wide middle, so a stretching card would have grown its own
                # border into a frame along with it.
                overlay_slot:
                    Widget := Inner
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Padding := margin{Left := 3.0, Top := 3.0, Right := 3.0, Bottom := 3.0}
                overlay_slot:
                    Widget := FringeCopy
                    HorizontalAlignment := horizontal_alignment.Center
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 6.0, Bottom := 0.0}
                overlay_slot:
                    Widget := TrueSlogan
                    HorizontalAlignment := horizontal_alignment.Center
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

        # THE RING. Three rows: bulbs across the top, then a row holding the
        # left column, the card and the right column, then bulbs across the
        # bottom. No absolute positions, so it cannot drift apart.
        TopBox := BuildBulbRow(PaidBulbsAcross, orientation.Horizontal)
        TopBulbs := PaidBulbBuffer
        RightBox := BuildBulbRow(PaidBulbsDown, orientation.Vertical)
        RightBulbs := PaidBulbBuffer
        BottomBox := BuildBulbRow(PaidBulbsAcross, orientation.Horizontal)
        BottomBulbs := PaidBulbBuffer
        LeftBox := BuildBulbRow(PaidBulbsDown, orientation.Vertical)
        LeftBulbs := PaidBulbBuffer

        # The bottom row and the left column are laid out left to right and top
        # to bottom on screen, so they go into the ring backwards.
        var Ring : []color_block = array{}
        set Ring += TopBulbs
        set Ring += RightBulbs
        set Ring += Reversed(BottomBulbs)
        set Ring += Reversed(LeftBulbs)
        set PaidBulbs = Ring

        Middle := stack_box:
            Orientation := orientation.Horizontal
            Slots := array:
                stack_box_slot:
                    Widget := LeftBox
                    HorizontalAlignment := horizontal_alignment.Center
                    VerticalAlignment := vertical_alignment.Fill
                    Distribution := option{0.05}
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 18.0, Bottom := 0.0}
                stack_box_slot:
                    Widget := Card
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Distribution := option{1.0}
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                stack_box_slot:
                    Widget := RightBox
                    HorizontalAlignment := horizontal_alignment.Center
                    VerticalAlignment := vertical_alignment.Fill
                    Distribution := option{0.05}
                    Padding := margin{Left := 18.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

        # The two bulb rows keep a thin strip each and the card takes the
        # rest, whatever the box turns out to be.
        Marquee := stack_box:
            Orientation := orientation.Vertical
            Slots := array:
                stack_box_slot:
                    Widget := TopBox
                    HorizontalAlignment := horizontal_alignment.Fill
                    Distribution := option{0.14}
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 14.0}
                stack_box_slot:
                    Widget := Middle
                    HorizontalAlignment := horizontal_alignment.Fill
                    Distribution := option{1.0}
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 14.0}
                stack_box_slot:
                    Widget := BottomBox
                    HorizontalAlignment := horizontal_alignment.Fill
                    Distribution := option{0.14}
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

        Small := text_block:
            DefaultText := ScreenLine(PaidFinePrint)
            DefaultTextColor := PlasmaBlue
            DefaultTextSize := 22.0
            DefaultJustification := text_justification.Center

        # THE THREE POPUPS, three different shapes rather than three of one.
        # They sit OVER the marquee bulbs at the card's corners, by Kai's
        # ruling, because that is where an advert slaps a badge.
        # TWENTY EIGHT OF THEM, twice what there were, and they crowd right up
        # against the middle without ever crossing into it. Kai's note: more
        # ads, and only just not covering the centre.
        #
        # They are all different sizes, they overlap, and eight of them hang off
        # the edge of the screen and get cut in half. That is what a popup does.
        #
        # THE KEEP-OUT IS THE MIDDLE FIFTH OR SO of the screen, where the slogan
        # sits. Nothing here reaches into it, and several stop a hair short of
        # it on purpose.
        Popup01 := BuildBannerPopup()
        Popup02 := BuildStickerPopup()
        Popup03 := BuildWindowPopup()
        Popup04 := BuildBannerPopup()
        Popup05 := BuildStickerPopup()
        Popup06 := BuildStickerPopup()
        Popup07 := BuildWindowPopup()
        Popup08 := BuildBannerPopup()
        Popup09 := BuildBadgePopup()
        Popup10 := BuildBannerPopup()
        Popup11 := BuildBadgePopup()
        Popup12 := BuildStickerPopup()
        Popup13 := BuildWindowPopup()
        Popup14 := BuildBannerPopup()
        Popup15 := BuildBadgePopup()
        Popup16 := BuildBannerPopup()
        Popup17 := BuildWindowPopup()
        Popup18 := BuildWindowPopup()
        Popup19 := BuildStickerPopup()
        Popup20 := BuildStickerPopup()
        Popup21 := BuildWindowPopup()
        Popup22 := BuildBannerPopup()
        Popup23 := BuildStickerPopup()
        Popup24 := BuildBadgePopup()
        Popup25 := BuildBadgePopup()
        Popup26 := BuildBannerPopup()
        Popup27 := BuildWindowPopup()
        Popup28 := BuildStickerPopup()

        # Any input returns to the listings, which for a captured mouse means a
        # click anywhere at all. Same trick as the other dead channel.
        Blank := color_block:
            DefaultColor := BroadcastBlack
            DefaultOpacity := 0.0

        Sheet := button:
            Slot := button_slot:
                Widget := Blank
                HorizontalAlignment := horizontal_alignment.Fill
                VerticalAlignment := vertical_alignment.Fill
                Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

        Sheet.OnClick().Subscribe(OnPaidDismissed)

        Panel := canvas:
            Slots := array:
                canvas_slot:
                    Widget := Backdrop
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 0

                canvas_slot:
                    Widget := BuildHazardBar()
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 0.045}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 1
                canvas_slot:
                    Widget := BuildHazardBar()
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.955}, Maximum := vector2{X := 1.0, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 1

                canvas_slot:
                    Widget := Plaque
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.115}, Maximum := vector2{X := 0.5, Y := 0.115}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    SizeToContent := true
                    ZOrder := 2

                # THE CARD FILLS THE SCREEN. Pinned to a point it took the
                # size its contents asked for, which is 940 pixels however wide
                # the screen is, and it read as a small card adrift in a lot of
                # empty studio. Anchored to a box, everything inside it is
                # measured against the screen instead.
                canvas_slot:
                    Widget := Marquee
                    Anchors := anchors{Minimum := vector2{X := 0.07, Y := 0.28}, Maximum := vector2{X := 0.93, Y := 0.72}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 3

                canvas_slot:
                    Widget := Small
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.875}, Maximum := vector2{X := 0.5, Y := 0.875}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    SizeToContent := true
                    ZOrder := 4

                # THE TWENTY EIGHT PLACES AN ADVERT CAN LAND. Different sizes,
                # overlapping, several running off the edge on purpose, and none
                # of them reaching into the middle.
                canvas_slot:
                    Widget := Popup01
                    Anchors := anchors{Minimum := vector2{X := -0.05, Y := 0.01}, Maximum := vector2{X := 0.17, Y := 0.09}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 5
                canvas_slot:
                    Widget := Popup02
                    Anchors := anchors{Minimum := vector2{X := 0.14, Y := 0.02}, Maximum := vector2{X := 0.40, Y := 0.11}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 5
                canvas_slot:
                    Widget := Popup03
                    Anchors := anchors{Minimum := vector2{X := 0.42, Y := 0.00}, Maximum := vector2{X := 0.66, Y := 0.13}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 5
                canvas_slot:
                    Widget := Popup04
                    Anchors := anchors{Minimum := vector2{X := 0.68, Y := 0.02}, Maximum := vector2{X := 0.92, Y := 0.10}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 5
                canvas_slot:
                    Widget := Popup05
                    Anchors := anchors{Minimum := vector2{X := 0.88, Y := 0.01}, Maximum := vector2{X := 1.08, Y := 0.12}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 5
                canvas_slot:
                    Widget := Popup06
                    Anchors := anchors{Minimum := vector2{X := -0.06, Y := 0.12}, Maximum := vector2{X := 0.14, Y := 0.20}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 5
                canvas_slot:
                    Widget := Popup07
                    Anchors := anchors{Minimum := vector2{X := 0.10, Y := 0.13}, Maximum := vector2{X := 0.34, Y := 0.23}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 5
                canvas_slot:
                    Widget := Popup08
                    Anchors := anchors{Minimum := vector2{X := 0.36, Y := 0.14}, Maximum := vector2{X := 0.58, Y := 0.22}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 5
                canvas_slot:
                    Widget := Popup09
                    Anchors := anchors{Minimum := vector2{X := 0.60, Y := 0.12}, Maximum := vector2{X := 0.84, Y := 0.26}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 5
                canvas_slot:
                    Widget := Popup10
                    Anchors := anchors{Minimum := vector2{X := 0.86, Y := 0.15}, Maximum := vector2{X := 1.06, Y := 0.23}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 5
                canvas_slot:
                    Widget := Popup11
                    Anchors := anchors{Minimum := vector2{X := -0.04, Y := 0.25}, Maximum := vector2{X := 0.18, Y := 0.39}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 5
                canvas_slot:
                    Widget := Popup12
                    Anchors := anchors{Minimum := vector2{X := 0.16, Y := 0.27}, Maximum := vector2{X := 0.38, Y := 0.36}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 5
                canvas_slot:
                    Widget := Popup13
                    Anchors := anchors{Minimum := vector2{X := 0.40, Y := 0.26}, Maximum := vector2{X := 0.64, Y := 0.38}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 5
                canvas_slot:
                    Widget := Popup14
                    Anchors := anchors{Minimum := vector2{X := 0.66, Y := 0.28}, Maximum := vector2{X := 0.88, Y := 0.37}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 5
                canvas_slot:
                    Widget := Popup15
                    Anchors := anchors{Minimum := vector2{X := 0.86, Y := 0.26}, Maximum := vector2{X := 1.07, Y := 0.40}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 5
                canvas_slot:
                    Widget := Popup16
                    Anchors := anchors{Minimum := vector2{X := -0.05, Y := 0.42}, Maximum := vector2{X := 0.15, Y := 0.50}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 5
                canvas_slot:
                    Widget := Popup17
                    Anchors := anchors{Minimum := vector2{X := 0.10, Y := 0.44}, Maximum := vector2{X := 0.31, Y := 0.58}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 5
                canvas_slot:
                    Widget := Popup18
                    Anchors := anchors{Minimum := vector2{X := 0.69, Y := 0.43}, Maximum := vector2{X := 0.90, Y := 0.57}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 5
                canvas_slot:
                    Widget := Popup19
                    Anchors := anchors{Minimum := vector2{X := 0.88, Y := 0.45}, Maximum := vector2{X := 1.08, Y := 0.53}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 5
                canvas_slot:
                    Widget := Popup20
                    Anchors := anchors{Minimum := vector2{X := -0.04, Y := 0.61}, Maximum := vector2{X := 0.17, Y := 0.70}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 5
                canvas_slot:
                    Widget := Popup21
                    Anchors := anchors{Minimum := vector2{X := 0.14, Y := 0.62}, Maximum := vector2{X := 0.38, Y := 0.73}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 5
                canvas_slot:
                    Widget := Popup22
                    Anchors := anchors{Minimum := vector2{X := 0.40, Y := 0.61}, Maximum := vector2{X := 0.62, Y := 0.72}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 5
                canvas_slot:
                    Widget := Popup23
                    Anchors := anchors{Minimum := vector2{X := 0.64, Y := 0.63}, Maximum := vector2{X := 0.86, Y := 0.71}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 5
                canvas_slot:
                    Widget := Popup24
                    Anchors := anchors{Minimum := vector2{X := 0.84, Y := 0.60}, Maximum := vector2{X := 1.06, Y := 0.74}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 5
                canvas_slot:
                    Widget := Popup25
                    Anchors := anchors{Minimum := vector2{X := 0.00, Y := 0.76}, Maximum := vector2{X := 0.24, Y := 0.90}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 5
                canvas_slot:
                    Widget := Popup26
                    Anchors := anchors{Minimum := vector2{X := 0.26, Y := 0.78}, Maximum := vector2{X := 0.50, Y := 0.87}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 5
                canvas_slot:
                    Widget := Popup27
                    Anchors := anchors{Minimum := vector2{X := 0.52, Y := 0.80}, Maximum := vector2{X := 0.76, Y := 0.94}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 5
                canvas_slot:
                    Widget := Popup28
                    Anchors := anchors{Minimum := vector2{X := 0.74, Y := 0.76}, Maximum := vector2{X := 0.98, Y := 0.90}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 5

                canvas_slot:
                    Widget := BuildFaintScanlines(ScanlineCount)
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 6

                canvas_slot:
                    Widget := Sheet
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 7

        Panel

    # One side of the ring. The bulbs it makes are left in PaidBulbBuffer for
    # the caller, because a function returns one thing and both the widget and
    # its blocks are needed.
    BuildBulbRow(Count : int, Way : orientation) : stack_box =
        var Made : []color_block = array{}
        var Places : []stack_box_slot = array{}

        for (Index := 1..Count):
            Bulb := color_block:
                DefaultColor := ConcreteGray
                DefaultOpacity := 1.0
                DefaultDesiredSize := vector2{X := 16.0, Y := 16.0}

            set Made += array{Bulb}
            set Places += array{stack_box_slot{Widget := Bulb, HorizontalAlignment := horizontal_alignment.Center, VerticalAlignment := vertical_alignment.Center, Distribution := option{1.0}}}

        set PaidBulbBuffer = Made

        Row := stack_box:
            Orientation := Way
            Slots := Places

        Row

    Reversed(Blocks : []color_block) : []color_block =
        var Out : []color_block = array{}
        Count := Blocks.Length

        if (Count > 0):
            for (Index := 0..Count - 1):
                if (Item := Blocks[Count - 1 - Index]):
                    set Out += array{Item}

        Out

    # A 1990s starburst, the spiky badge an AS SEEN ON TV price gets slammed
    # across. A widget cannot be rotated and there is no shape but the
    # rectangle, so the spikes are faked: fifteen stacked bars following a round
    # profile, every other one pulled in short so the edge zigzags all the way
    # round.
    BuildStarburst() : stack_box =
        Widths := array{0.36, 0.40, 0.70, 0.64, 0.88, 0.78, 0.94, 0.84, 0.94, 0.78, 0.88, 0.64, 0.70, 0.40, 0.36}
        var Rows : []stack_box_slot = array{}

        for (Width : Widths):
            Gap := (1.0 - Width) / 2.0

            LeftGap := color_block:
                DefaultColor := PrizeGold
                DefaultOpacity := 0.0
            Bar := color_block:
                DefaultColor := PrizeGold
                DefaultOpacity := 1.0
            RightGap := color_block:
                DefaultColor := PrizeGold
                DefaultOpacity := 0.0

            Row := stack_box:
                Orientation := orientation.Horizontal
                Slots := array:
                    stack_box_slot{Widget := LeftGap, HorizontalAlignment := horizontal_alignment.Fill, VerticalAlignment := vertical_alignment.Fill, Distribution := option{Gap}}
                    stack_box_slot{Widget := Bar, HorizontalAlignment := horizontal_alignment.Fill, VerticalAlignment := vertical_alignment.Fill, Distribution := option{Width}}
                    stack_box_slot{Widget := RightGap, HorizontalAlignment := horizontal_alignment.Fill, VerticalAlignment := vertical_alignment.Fill, Distribution := option{Gap}}

            set Rows += array{stack_box_slot{Widget := Row, HorizontalAlignment := horizontal_alignment.Fill, VerticalAlignment := vertical_alignment.Fill, Distribution := option{1.0}}}

        Star := stack_box:
            Orientation := orientation.Vertical
            Slots := Rows

        Star

    # Popup one: the spiky gold badge with black words. Prize gold, because on
    # this screen the badge is selling a prize.
    BuildBadgePopup() : overlay =
        Label := text_block:
            DefaultText := ScreenLine("")
            DefaultTextColor := BroadcastBlack
            DefaultTextSize := PaidPopupTextSize
            DefaultJustification := text_justification.Center

        Burst := overlay:
            Slots := array:
                overlay_slot:
                    Widget := BuildStarburst()
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                overlay_slot:
                    Widget := Label
                    HorizontalAlignment := horizontal_alignment.Center
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 10.0, Top := 0.0, Right := 10.0, Bottom := 0.0}

        Burst.SetVisibility(widget_visibility.Collapsed)
        set PopupBusy += array{false}
        set PaidPopupBursts += array{Burst}
        set PaidPopupTexts += array{Label}
        Burst

    # Popup two: a solid hot pink banner with black words, the same shape the
    # NOW row has on the listings.
    BuildBannerPopup() : overlay =
        Fill := color_block:
            DefaultColor := SponsorPink
            DefaultOpacity := 1.0

        Label := text_block:
            DefaultText := ScreenLine("")
            DefaultTextColor := BroadcastBlack
            DefaultTextSize := PaidPopupTextSize
            DefaultJustification := text_justification.Center

        Banner := overlay:
            Slots := array:
                overlay_slot:
                    Widget := Fill
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                overlay_slot:
                    Widget := Label
                    HorizontalAlignment := horizontal_alignment.Center
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 10.0, Top := 0.0, Right := 10.0, Bottom := 0.0}

        Banner.SetVisibility(widget_visibility.Collapsed)
        set PopupBusy += array{false}
        set PaidPopupBursts += array{Banner}
        set PaidPopupTexts += array{Label}
        Banner

    # Popup three, and Kai's own: red, with a thick WHITE border and white
    # words. The white outline is a block behind the red one, showing through
    # as a frame, which is how a border is made when there is no border to set.
    BuildStickerPopup() : overlay =
        Edge := color_block:
            DefaultColor := StaticWhite
            DefaultOpacity := 1.0

        Inside := color_block:
            DefaultColor := DangerRed
            DefaultOpacity := 1.0

        Label := text_block:
            DefaultText := ScreenLine("")
            DefaultTextColor := StaticWhite
            DefaultTextSize := PaidPopupTextSize
            DefaultJustification := text_justification.Center

        Tag := overlay:
            Slots := array:
                overlay_slot:
                    Widget := Edge
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                overlay_slot:
                    Widget := Inside
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Padding := margin{Left := 5.0, Top := 5.0, Right := 5.0, Bottom := 5.0}
                overlay_slot:
                    Widget := Label
                    HorizontalAlignment := horizontal_alignment.Center
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 16.0, Top := 0.0, Right := 16.0, Bottom := 0.0}

        Tag.SetVisibility(widget_visibility.Collapsed)
        set PopupBusy += array{false}
        set PaidPopupBursts += array{Tag}
        set PaidPopupTexts += array{Label}
        Tag

    # Popup four: the fake ad window. A grey title bar with a close cross on
    # the right, and the words in the body under it. The cross does nothing:
    # a click anywhere on this channel leaves it, and that is the joke.
    BuildWindowPopup() : overlay =
        Frame := color_block:
            DefaultColor := ConcreteGray
            DefaultOpacity := 1.0

        Body := color_block:
            DefaultColor := BroadcastBlack
            DefaultOpacity := 1.0

        Cross := text_block:
            DefaultText := ScreenLine("X")
            DefaultTextColor := DangerRed
            DefaultTextSize := 18.0
            DefaultJustification := text_justification.Right

        Label := text_block:
            DefaultText := ScreenLine("")
            DefaultTextColor := LaserYellow
            DefaultTextSize := PaidPopupTextSize
            DefaultJustification := text_justification.Center

        Window := overlay:
            Slots := array:
                overlay_slot:
                    Widget := Frame
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                # The body leaves the top strip of the frame showing, and that
                # strip is the title bar. There is no title bar to make, so one
                # is made out of the gap.
                overlay_slot:
                    Widget := Body
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Padding := margin{Left := 3.0, Top := 26.0, Right := 3.0, Bottom := 3.0}
                overlay_slot:
                    Widget := Cross
                    HorizontalAlignment := horizontal_alignment.Right
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{Left := 0.0, Top := 1.0, Right := 8.0, Bottom := 0.0}
                overlay_slot:
                    Widget := Label
                    HorizontalAlignment := horizontal_alignment.Center
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 8.0, Top := 22.0, Right := 8.0, Bottom := 4.0}

        Window.SetVisibility(widget_visibility.Collapsed)
        set PopupBusy += array{false}
        set PaidPopupBursts += array{Window}
        set PaidPopupTexts += array{Label}
        Window

    # Faint scanlines, for this card only. A separate builder rather than a
    # setting, because DefaultOpacity demands a number the compiler can prove
    # sits between 0 and 1: the same wall amendment 70f hit.
    BuildFaintScanlines(LineCount : int) : stack_box =
        var Lines : []stack_box_slot = array{}

        for (Index := 1..LineCount):
            Bar := color_block:
                DefaultColor := ConcreteGray
                DefaultOpacity := 0.05
                DefaultDesiredSize := vector2{X := 8.0, Y := 2.0}

            set Lines += array{stack_box_slot{Widget := Bar, HorizontalAlignment := horizontal_alignment.Fill, VerticalAlignment := vertical_alignment.Top, Distribution := option{1.0}}}

        Layer := stack_box:
            Orientation := orientation.Vertical
            Slots := Lines

        Layer

    FirstSlogan()<transacts>:string =
        if (Line := PaidSlogans[0]):
            return Line
        ""

    # A different popup line every time, and never the one just used, by the
    # same nudge the fine print uses.
    NextPopupLine()<transacts>:string =
        Count := PaidPopupLines.Length

        if (Count > 1):
            var Pick : int = GetRandomInt(0, Count - 1)
            if (Pick = LastPopupShown):
                set Pick += 1
                if (Pick >= Count):
                    set Pick = 0

            set LastPopupShown = Pick
            if (Line := PaidPopupLines[Pick]):
                return Line

        if (Only := PaidPopupLines[0]):
            return Only
        ""

    # Every third bulb lit, and the lit ones one place further round than last
    # time. Gold for lit, concrete gray for dark, so no opacity is involved.
    LightTheRing():void =
        var Step : int = 3 - PaidBulbOffset
        if (Step >= 3):
            set Step = 0

        for (Bulb : PaidBulbs):
            if (Step = 0):
                Bulb.SetColor(PrizeGold)
            else:
                Bulb.SetColor(ConcreteGray)
            set Step += 1
            if (Step >= 3):
                set Step = 0

    RunMarqueeChase()<suspends>:void =
        loop:
            Sleep(PaidBulbChaseSeconds)
            if (not ScreenIsUp?):
                return
            if (PaidShowing?):
                set PaidBulbOffset += 1
                if (PaidBulbOffset >= 3):
                    set PaidBulbOffset = 0
                LightTheRing()

    RunSloganCycle()<suspends>:void =
        loop:
            Sleep(PaidSloganSeconds)
            if (not ScreenIsUp?):
                return
            if (PaidShowing?):
                set PaidSloganIndex += 1
                if (PaidSloganIndex >= PaidSlogans.Length):
                    set PaidSloganIndex = 0

                if (Line := PaidSlogans[PaidSloganIndex]):
                    if (Front := PaidSloganText?):
                        Front.SetText(ScreenLine(Line))
                    if (Ghost := PaidSloganFringe?):
                        Ghost.SetText(ScreenLine(Line))

    # One arrives, then a second, then a third, they hold, they all clear, and
    # it starts again from empty. Their own clock, by Kai's ruling: the slogans
    # change every two and a half seconds, which is far too fast to hang the
    # popups off.
    RunPopups()<suspends>:void =
        # SEVEN AT ONCE, on seven different holds, which is what makes them pile
        # up and clear raggedly instead of marching. Each claims a free place at
        # random, so seven running together simply means more of the twenty
        # eight are occupied at any moment.
        spawn{ RunPopupCycle(0.0, 1.0) }
        spawn{ RunPopupCycle(PaidPopupStaggerSeconds, 1.35) }
        spawn{ RunPopupCycle(PaidPopupStaggerSeconds * 2.0, 0.8) }
        spawn{ RunPopupCycle(PaidPopupStaggerSeconds * 3.0, 1.15) }
        spawn{ RunPopupCycle(PaidPopupStaggerSeconds * 4.0, 0.9) }
        spawn{ RunPopupCycle(PaidPopupStaggerSeconds * 5.0, 1.25) }
        spawn{ RunPopupCycle(PaidPopupStaggerSeconds * 6.0, 1.05) }

    # FOUR RUNNERS CHOOSING AT RANDOM. Kai's note: taking the places in turn
    # meant a popup at the top was always followed by one lower down, in the
    # same order every time, which reads as a pattern rather than as chaos.
    #
    # Each runner claims a place at random from whichever are free, holds it
    # while the advert is up, and lets it go afterwards. The claim is what
    # stops two runners landing on the same place; nothing else needs locking,
    # because Verse runs them one at a time rather than truly side by side.
    RunPopupCycle(Stagger : float, HoldScale : float)<suspends>:void =
        Sleep(Stagger)

        loop:
            if (not ScreenIsUp?):
                return

            if (PaidShowing?):
                if (Slot := ClaimPopup[]):
                    ShowPopup(Slot)
                    BouncePopup(Slot, PaidPopupShowSeconds * HoldScale)
                    ReleasePopup(Slot)

            Sleep(PaidPopupRestSeconds)

    # THE BOUNCE ITSELF. The words swell to the largest size, shrink back to
    # the smallest, and keep going for as long as the advert is up. It doubles
    # as the wait: this runs for exactly the hold, so the runner does not sleep
    # separately.
    #
    # The size is put back to normal on the way out, because the same widget is
    # used again by whichever runner claims this place next, and it would
    # otherwise arrive mid-swell.
    BouncePopup(Slot : int, Seconds : float)<suspends>:void =
        if (Label := PaidPopupTexts[Slot]):
            var Elapsed : float = 0.0
            var Scale : float = PaidPopupMinScale
            var Growing : logic = true

            loop:
                if (Elapsed >= Seconds):
                    Label.SetTextSize(PaidPopupTextSize)
                    return

                if (Growing?):
                    set Scale += PaidPopupBounceStep
                    if (Scale >= PaidPopupMaxScale):
                        set Scale = PaidPopupMaxScale
                        set Growing = false
                else:
                    set Scale -= PaidPopupBounceStep
                    if (Scale <= PaidPopupMinScale):
                        set Scale = PaidPopupMinScale
                        set Growing = true

                Label.SetTextSize(PaidPopupTextSize * Scale)
                Sleep(PaidPopupBounceSeconds)
                set Elapsed += PaidPopupBounceSeconds
        else:
            # No label to bounce, but the advert is still up, so still wait.
            Sleep(Seconds)

    # Take one of the free places at random. Fails if every one is in use,
    # which just means this runner waits a beat and asks again.
    ClaimPopup()<transacts><decides>:int =
        var Free : []int = array{}
        var Index : int = 0

        for (Busy : PopupBusy):
            if (not Busy?):
                set Free += array{Index}
            set Index += 1

        Count := Free.Length
        Count > 0
        Pick := Free[GetRandomInt(0, Count - 1)]
        set PopupBusy[Pick] = true
        Pick

    # Put the advert away and hand the place back.
    ReleasePopup(Slot : int):void =
        if (set PopupBusy[Slot] = false):
            HidePopup(Slot)

    ShowPopup(Slot : int):void =
        if (Burst := PaidPopupBursts[Slot], Label := PaidPopupTexts[Slot]):
            Label.SetText(ScreenLine(NextPopupLine()))
            Burst.SetVisibility(widget_visibility.Visible)

    HidePopup(Slot : int):void =
        if (Burst := PaidPopupBursts[Slot]):
            Burst.SetVisibility(widget_visibility.Collapsed)

    HideAllPopups():void =
        for (Burst : PaidPopupBursts):
            Burst.SetVisibility(widget_visibility.Collapsed)

    OnPaidPressed(Message : widget_message):void =
        set OnListings = false
        set PaidShowing = true
        set PaidBulbOffset = 0
        LightTheRing()
        ChangeChannel(PaidPanel)

    OnPaidDismissed(Message : widget_message):void =
        set OnListings = true
        set PaidShowing = false
        HideAllPopups()
        ChangeChannel(false)

    OnPaidHover(Message : widget_message):void =
        PlayBuzzer(Message.Player)
        if (Edge := PaidEdge?):
            Edge.SetColor(SponsorPink)
        if (Label := PaidText?):
            Label.SetTextColor(SponsorPink)

    OnPaidUnhover(Message : widget_message):void =
        if (Edge := PaidEdge?):
            Edge.SetColor(ConcreteGray)
        if (Label := PaidText?):
            Label.SetTextColor(ConcreteGray)

    # =================================================================
    # PLEASE STAND BY (build item 7)
    #
    # The card the station puts up when nobody is watching, and again between
    # pressing START SHOW and the arena appearing. Kai's ruling reversed the
    # earlier "idle only" call: it plays in both places now.
    #
    # IT IS THE REAL CARD, from the reference Kai pulled up: the colour bars
    # with a black band across them and PLEASE STAND BY in white. The bars are
    # the same seven the dead channel uses, so the two are one station losing
    # its picture in two different ways.
    #
    # NOTHING IS PRESSED TO LEAVE IT. Both goings are on a timer, which is why
    # there is no click sheet on it any more.
    #
    # The ON AIR light and the debt counter ride on their own layers above the
    # broadcast, so they stay lit on top of it. That is the better joke, and
    # both are ruled to be permanent anyway.
    # =================================================================

    BuildStandByCard() : canvas =
        # A REAL TEST CARD IS THREE BANDS, not one. Kai's reference picture has
        # the seven tall colour bars down most of it, then a short band of
        # different colours under them, then a darker strip along the bottom.
        # With only the first band it read as seven fat stripes rather than as
        # a television test card, which is what Kai meant by the vertical lines
        # being missing.
        Bars := BuildColourBars()
        # NOTHING GREY DOWN THE RIGHT EDGE of the lower two bands. The tall bar
        # on the right is concrete grey, and both strips under it ended grey as
        # well, so the three ran together into one big grey L down the side and
        # along the bottom. Blue and near-black break it.
        Lower := BuildBarStrip(array{PlasmaBlue, BroadcastBlack, SponsorPink, BroadcastBlack, LaserYellow, ConcreteGray, PlasmaBlue})
        Foot := BuildBarStrip(array{StaticDark, StaticWhite, StaticDark, ConcreteGray, BroadcastBlack, StaticMid, BroadcastBlack})

        Field := stack_box:
            Orientation := orientation.Vertical
            Slots := array:
                stack_box_slot:
                    Widget := Bars
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Distribution := option{0.70}
                stack_box_slot:
                    Widget := Lower
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Distribution := option{0.16}
                stack_box_slot:
                    Widget := Foot
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Distribution := option{0.14}

        Band := color_block:
            DefaultColor := BroadcastBlack
            DefaultOpacity := 1.0

        # White on the black band, the way the real card does it. No fringing:
        # this is the one thing on the screen that has to be read instantly.
        Words := text_block:
            DefaultText := ScreenLine(StandByLine)
            DefaultTextColor := StaticWhite
            DefaultTextSize := StandByTextSize
            DefaultJustification := text_justification.Center

        # A WAY OUT, FOR THE IDLE CARD ONLY. Kai's ruling has moved twice and
        # both halves of it are honoured here: nobody has to click, because the
        # card still leaves on its own, but somebody who has seen it enough can
        # click anywhere to be rid of it early.
        #
        # It stays collapsed for the card that plays after START SHOW. That one
        # is two and a half seconds on the way into the arena, and a stray click
        # skipping it would be an accident rather than a choice.
        Blank := color_block:
            DefaultColor := BroadcastBlack
            DefaultOpacity := 0.0

        Sheet := button:
            Slot := button_slot:
                Widget := Blank
                HorizontalAlignment := horizontal_alignment.Fill
                VerticalAlignment := vertical_alignment.Fill
                Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

        Sheet.OnClick().Subscribe(OnStandByDismissed)
        Sheet.SetVisibility(widget_visibility.Collapsed)
        set StandByExit = option{Sheet}

        Card := canvas:
            Slots := array:
                canvas_slot:
                    Widget := Field
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 0

                # HIGH, NOT CENTRED. The band sits about a third of the way
                # down on Kai's reference, not across the middle.
                canvas_slot:
                    Widget := Band
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.28}, Maximum := vector2{X := 1.0, Y := 0.44}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 1

                canvas_slot:
                    Widget := Words
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.36}, Maximum := vector2{X := 0.5, Y := 0.36}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    SizeToContent := true
                    ZOrder := 2

                # Above everything on the card, so nothing else can take the
                # click. Collapsed unless the card came up from sitting idle.
                canvas_slot:
                    Widget := Sheet
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 3

        Card

    # The idle clock. It only counts on the listings, and it stops for good
    # once the show starts, because by then the broadcast is off the screen.
    RunIdleWatch()<suspends>:void =
        loop:
            Sleep(StandByPollSeconds)

            if (not ScreenIsUp?):
                return

            if (OnListings? and not StandingBy?):
                set IdleSeconds += StandByPollSeconds
                if (IdleSeconds >= StandByIdleSeconds):
                    GoToStandBy()

    # Cut to the card through the same burst of snow every other channel
    # change cuts through, by reusing the channel machinery rather than
    # repeating it.
    GoToStandBy():void =
        if (Card := StandByCard?):
            set StandingBy = true
            set OnListings = false
            set PaidShowing = false
            Print("DEBUG: Nothing touched for {StandByIdleSeconds}s. Cutting to PLEASE STAND BY.")

            # The way out goes up with it. Only this card gets one.
            if (Exit := StandByExit?):
                Exit.SetVisibility(widget_visibility.Visible)

            ChangeChannel(option{Card})
            spawn{ LeaveStandByLater() }

    # THE ONE PLACE THE CARD'S SOUND GOES ON AND OFF, so it can never be out
    # of step with the picture. On when the card arrives, off when it leaves.
    SetStandBySound(Wanted : logic):void =
        if (Wanted?):
            if (not StandBySoundOn?):
                set StandBySoundOn = true
                StandBySound.Play()
        else:
            if (StandBySoundOn?):
                set StandBySoundOn = false
                StandBySound.Stop()

    # Nobody presses anything to get out of this. It waits out the burst of
    # snow that brought it up, holds, and puts the listings back.
    LeaveStandByLater()<suspends>:void =
        # The snow goes first, and only then is the card really on the screen.
        Sleep(StaticSeconds)
        SetStandBySound(true)

        Sleep(StandByHoldSeconds)
        SetStandBySound(false)

        # Already gone, because somebody clicked it away. Nothing to do.
        if (StandingBy?):
            set StandingBy = false
            set OnListings = true

            if (Exit := StandByExit?):
                Exit.SetVisibility(widget_visibility.Collapsed)
            Print("DEBUG: PLEASE STAND BY is over. Back to the listings.")
            ChangeChannel(false)

    # Clicked out of early. The card leaves the same way it would have on its
    # own, and the timer behind it finds the job already done and stands down.
    OnStandByDismissed(Message : widget_message):void =
        if (StandingBy?):
            set StandingBy = false
            set OnListings = true
            SetStandBySound(false)

            if (Exit := StandByExit?):
                Exit.SetVisibility(widget_visibility.Collapsed)

            Print("DEBUG: PLEASE STAND BY clicked away early.")
            ChangeChannel(false)

    # The card between the press and the arena. Kai's ruling, reversing the
    # earlier one: pressing start cuts to PLEASE STAND BY for a few seconds
    # and the show comes on behind it.
    RunStandByThenShow(P : player)<suspends>:void =
        set OnListings = false
        set PaidShowing = false

        # THE DING GETS THE TITLE SCREEN TO ITSELF. Kai's ruling: press, hear
        # the ding while the schedule is still up, and only then does the
        # picture cut to snow and the hiss start under it.
        Sleep(StartDingSeconds)

        if (Card := StandByCard?):
            ChangeChannel(option{Card})

            Sleep(StaticSeconds)
            SetStandBySound(true)

            Sleep(StandByBeforeShowSeconds)
            SetStandBySound(false)

        ReleaseTheMatch(P)

    # =================================================================
    # STARTING THE SHOW
    #
    # Takes the broadcast off air, gives the mouse and the HUD back, and lets
    # every waiting manager off the leash.
    # =================================================================

    ReleaseTheMatch(P : player):void =
        # The four loops that only make sense while the broadcast is up stop
        # here, and on this rather than on the match start flag.
        set ScreenIsUp = false

        # Belt and braces on the two sounds that follow a picture. Nothing
        # should still be playing by now, and if anything is, it would carry on
        # into the arena with no screen left to explain it.
        SetStandBySound(false)
        SetStaticVisible(false)

        if (Root := Screen?, PlayerUI := GetPlayerUI[P]):
            PlayerUI.RemoveWidget(Root)
            set Screen = false

        # NOTHING GOES BACK UP. Kai's ruling, reversing amendment 71 and the
        # ON AIR light's own: both belong to the title screen alone, so the
        # broadcast taking them down is the end of them.
        #
        # THE DEBT KEEPS COUNTING ANYWAY, unseen. It is only the readout that
        # is gone. Amendment 71 has collected cash paying the debt down during
        # the run and the save carrying it between runs, and stopping the sums
        # here would quietly throw both away.

        if (HideGameHUD?):
            GetPlayspace().GetHUDController().ResetElementsForPlayer(P, array{creative_hud_identifier_all{}})

        # AFTER the reset, not before. Putting the HUD back turns everything
        # on again, so anything meant to stay off has to be switched off on the
        # far side of it.
        if (HideFootstepIndicator?):
            GetPlayspace().GetHUDController().HideElementsForPlayer(P, array{hud_identifier_visual_sound_effect_movement{}})
            Print("DEBUG: Footstep indicator hidden for the match.")

        ShowLiveBadge(P)

        if (HideMinimap?):
            GetPlayspace().GetHUDController().HideElementsForPlayer(P, array{creative_hud_identifier_minimap{}, creative_hud_identifier_mimimap{}})
            Print("DEBUG: Minimap hidden for the match.")

        if (HideRoundInfo?):
            GetPlayspace().GetHUDController().HideElementsForPlayer(P, array{creative_hud_identifier_round_info{}})
            Print("DEBUG: Round info banner hidden for the match.")

        if (HideBuildMenu?):
            GetPlayspace().GetHUDController().HideElementsForPlayer(P, array{creative_hud_identifier_build_menu{}, creative_hud_identifier_crafting_resources{}})
            Print("DEBUG: Build menu hidden for the match.")

        if (ClearTopRight?):
            GetPlayspace().GetHUDController().HideElementsForPlayer(P, array{
                creative_hud_identifier_map_prompts{},
                creative_hud_identifier_player_count{},
                creative_hud_identifier_team_info{},
                creative_hud_identifier_storm_timer{},
                creative_hud_identifier_storm_notifications{},
                creative_hud_identifier_round_timer{},
                creative_hud_identifier_elimination_counter{}})
            Print("DEBUG: Top right corner cleared for the cash counter.")

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
