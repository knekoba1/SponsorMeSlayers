# BroadcastScreen.verse
#
# GDD Section 2.1 "Core Gameplay Loop" and amendment 18 "There is no main menu
# to put the title card on". This is the title screen, built as a television
# broadcast rather than a menu: the contestant is watching a channel, not
# choosing options.
#
# BUILD ITEMS 1, 2 AND 9. The brief Kailee gave on 2026-08-24 has nine numbered
# items, to be built one at a time in a set order. Done here: 1 the title
# screen, 2 sound, 9 the ON AIR light. Still owed, in Kai's order: 3 the sponsor
# ticker, which carries RSM STUDIOS as the station ident; 4 channel flicker with
# static; 5 the debt counter; 6 legal fine print; 7 please stand by; 8 TV
# listings framing, with ONE dead channel rather than two, by Kai's ruling.
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

    @editable
    StartLabel : string = "START SHOW"

    @editable
    LeaderboardLabel : string = "LEADERBOARD"

    @editable
    CollectablesLabel : string = "COLLECTABLES"

    @editable
    BackLabel : string = "BACK"

    # How many scanlines down the screen. Fifty over a 1080-tall screen puts a
    # line every 21 pixels or so.
    @editable
    ScanlineCount : int = 50

    # HOW DARK EACH SCANLINE IS. There is no dial for this on the Details
    # panel, and there cannot be one. The opacity setting on a shape does not
    # take an ordinary number: it demands one the compiler can prove sits
    # between 0 and 1, and a value typed into the editor later carries no such
    # proof. So it is written straight into BuildScanlines below, on the
    # DefaultOpacity line. 0.18 is faint. 0.3 is heavy tape wear.

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

    # False while the buzzer is in its cooldown. See BuzzerCooldownSeconds.
    var BuzzerReady : logic = true

    # The ON AIR light's box, held so the blink can show and hide it.
    var OnAirBox : ?overlay = false

    # True while the contestant is on the air. Goes false on death and never
    # comes back on its own, which stops the blink for good.
    var OnAirLit : logic = true

    # Which half of the blink the light is currently in.
    var BlinkVisible : logic = true

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

        Playspace := GetPlayspace()
        Playspace.PlayerAddedEvent().Subscribe(OnPlayerAdded)

        for (P : Playspace.GetPlayers()):
            ShowBroadcast(P)
            GoOnAir(P)

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

    ShowBroadcast(P : player):void =
        # An opaque block across the whole screen. This is what hides the
        # arena. The arena is still there behind it, there is simply nothing
        # to see.
        Backdrop := color_block:
            DefaultColor := BroadcastBlack
            DefaultOpacity := 1.0

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

                # -- the three channels --------------------------------
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

        set Screen = option{Root}

        # InputMode All is what puts the mouse pointer on screen and stops the
        # contestant walking about behind the broadcast. Without it there is no
        # cursor at all and nothing can be pressed.
        Slot := player_ui_slot:
            ZOrder := 100
            InputMode := ui_input_mode.All

        if (PlayerUI := GetPlayerUI[P]):
            PlayerUI.AddWidget(Root, Slot)

            if (HideGameHUD?):
                GetPlayspace().GetHUDController().HideElementsForPlayer(P, array{creative_hud_identifier_all{}})

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
                DefaultColor := BroadcastBlack
                # The scanline darkness. Written here rather than on the
                # Details panel, for the reason given up in the dials section.
                DefaultOpacity := 0.18
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
            DefaultDesiredSize := vector2{X := 560.0, Y := 96.0}

        StartLabelText := text_block:
            DefaultText := ScreenLine(StartLabel)
            DefaultTextColor := BroadcastBlack
            DefaultTextSize := 46.0
            DefaultJustification := text_justification.Center

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
                    Widget := StartLabelText
                    HorizontalAlignment := horizontal_alignment.Center
                    VerticalAlignment := vertical_alignment.Center
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

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
            DefaultDesiredSize := vector2{X := 470.0, Y := 76.0}

        BoardLabelText := text_block:
            DefaultText := ScreenLine(LeaderboardLabel)
            DefaultTextColor := LaserYellow
            DefaultTextSize := 34.0
            DefaultJustification := text_justification.Center

        set BoardEdge = option{BoardEdgeBlock}
        set BoardText = option{BoardLabelText}

        BoardButton := button:
            Slot := button_slot:
                Widget := ChannelSlab(BoardEdgeBlock, BoardLabelText)
                HorizontalAlignment := horizontal_alignment.Left
                VerticalAlignment := vertical_alignment.Center
                Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

        BoardButton.OnClick().Subscribe(OnLeaderboardPressed)
        BoardButton.HighlightEvent().Subscribe(OnBoardHover)
        BoardButton.UnhighlightEvent().Subscribe(OnBoardUnhover)

        VaultEdgeBlock := color_block:
            DefaultColor := PlasmaBlue
            DefaultOpacity := 1.0
            DefaultDesiredSize := vector2{X := 470.0, Y := 76.0}

        VaultLabelText := text_block:
            DefaultText := ScreenLine(CollectablesLabel)
            DefaultTextColor := LaserYellow
            DefaultTextSize := 34.0
            DefaultJustification := text_justification.Center

        set VaultEdge = option{VaultEdgeBlock}
        set VaultText = option{VaultLabelText}

        VaultButton := button:
            Slot := button_slot:
                Widget := ChannelSlab(VaultEdgeBlock, VaultLabelText)
                HorizontalAlignment := horizontal_alignment.Left
                VerticalAlignment := vertical_alignment.Center
                Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

        VaultButton.OnClick().Subscribe(OnCollectablesPressed)
        VaultButton.HighlightEvent().Subscribe(OnVaultHover)
        VaultButton.UnhighlightEvent().Subscribe(OnVaultUnhover)

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
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

        Stack

    # A dark slab with a colored edge. The edge is simply a bigger block behind
    # a smaller dark one; Verse has no border on a color block, so the border
    # is faked by letting six pixels of the block behind show all round.
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

    OnLeaderboardPressed(Message : widget_message):void =
        ShowPanel(BoardPanel)

    OnCollectablesPressed(Message : widget_message):void =
        ShowPanel(VaultPanel)

    # Both panels share one BACK, because only one can ever be open.
    OnBackPressed(Message : widget_message):void =
        if (Board := BoardPanel?):
            Board.SetVisibility(widget_visibility.Collapsed)
        if (Vault := VaultPanel?):
            Vault.SetVisibility(widget_visibility.Collapsed)
        if (Channels := ChannelGroup?):
            Channels.SetVisibility(widget_visibility.Visible)

    ShowPanel(Panel : ?canvas):void =
        if (Channels := ChannelGroup?):
            Channels.SetVisibility(widget_visibility.Collapsed)
        if (Open := Panel?):
            Open.SetVisibility(widget_visibility.Visible)

    # START SHOW is already pink, so its hover goes the other way: the slab
    # flips to laser yellow so the change is unmistakable.
    OnStartHover(Message : widget_message):void =
        PlayBuzzer(Message.Player)
        if (Fill := StartFill?):
            Fill.SetColor(LaserYellow)

    OnStartUnhover(Message : widget_message):void =
        if (Fill := StartFill?):
            Fill.SetColor(SponsorPink)

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
