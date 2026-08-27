# StartScreenManager.verse
#
# GDD Section 2.1 "Core Gameplay Loop", and amendment 18 "There is no main menu
# to put the title card on". This file is the nearest thing UEFN allows to a
# main menu: a full-screen broadcast card at match start that holds the whole
# arena still until the contestant clicks PLAY with the mouse.
#
# SIX RULINGS SHAPED THIS FILE. All made by Kailee on 2026-08-24 and recorded in
# GDD_AMENDMENTS.md item 70. In short:
#
#   * The start screen comes FIRST. The rank title card of amendment 18 plays
#     after PLAY is clicked, not before it.
#   * NOTHING runs until PLAY. Not the hostiles, not the crate trickle, not
#     Hype decay, not the starting pistol, not the title card.
#   * It is a real screen with a mouse pointer, not a keypress. A full-screen
#     opaque panel hides the arena and takes the mouse until a button is hit.
#   * COLLECTABLES sits under PLAY, and is a PLACEHOLDER. Twelve locked slots,
#     because CollectablesManager.verse is not built yet.
#   * LEADERBOARD is the contestant's own best runs. Fortnite cannot rank one
#     player against another: an island may only read the save of the player
#     standing in front of it, never anybody else's.
#   * Fortnite's own HUD is hidden while the screen is up, or the health bar
#     and the hotbar draw straight over the top of the card.
#
# HOW THE HOLD WORKS, AND WHY IT LOOKS LIKE THIS. Every manager that must not
# run before PLAY calls AwaitMatchStart(Self) as the first line of its OnBegin.
# The flag it waits on lives at module scope, outside any class, so no manager
# needs a wire to this device in UEFN. That matters: seven references to set by
# hand is seven chances to miss one, and a missed one fails silently.
#
# The flag has to be a weak_map, oddly. Verse only allows a module-scope var to
# be a weak_map, which is a table keyed on a player. A single true or false
# would be the honest shape, so instead the map is keyed on the contestant and
# asked "has anybody clicked PLAY". Amendment 19 makes this game single-player,
# so the map never holds more than one row.

using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
# text_block, button_loud and button_regular live here. color_block, canvas and
# stack_box live in the UnrealEngine UI module below, so both imports are needed.
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Colors }
using { /Verse.org/Simulation }

# The gate. Holds true once PLAY has been clicked. See the file header for why
# this is a table rather than a plain true or false.
var MatchStartedFor : weak_map(player, logic) = map{}

# Called by every manager that must sit still until PLAY is clicked. Pass Self.
#
# This polls rather than waiting on an event, because a module-scope event
# cannot be declared at all. A tenth of a second is invisible to the player and
# this runs a handful of times per match.
AwaitMatchStart(Device : creative_device)<suspends>:void =
    # HALF A SECOND BEFORE THE FIRST LOOK, and it is not cosmetic. Restarting a
    # playtest inside the same editor session can leave this flag set from the
    # run before, and the broadcast clears it in its own OnBegin. Device OnBegin
    # order is not guaranteed, so without this pause a manager whose OnBegin ran
    # first reads the stale flag and starts the waves behind the title screen.
    # Half a second against a thirty second first wave is invisible.
    Sleep(0.5)

    loop:
        if (MatchHasStarted(Device)?):
            break
        Sleep(0.1)

# True if any active contestant has clicked PLAY.
MatchHasStarted(Device : creative_device)<transacts>:logic =
    for (P : Device.GetPlayspace().GetPlayers(), P.IsActive[], Started := MatchStartedFor[P], Started?):
        return true
    false

# =====================================================================
# ENDING A RUN AND STARTING ANOTHER, amendment 86.
#
# Everything below is what makes PLAY AGAIN possible. Before it, the gate only
# ever went one way: it opened when PLAY was clicked and stayed open, so every
# manager was written as a loop that never expected to stop.
#
# THE TRICK IS AwaitRunEnd PLUS race, not rewriting those loops. Put the
# never-ending work and AwaitRunEnd in a race and Verse cancels whichever
# loses. So a wave loop halfway through spawning is simply dropped where it
# stands, and the manager comes back round to wait for the next run.
#
# There is no event to subscribe to here for the same reason AwaitMatchStart
# polls: a module-scope event cannot be declared at all.
# =====================================================================

# A RUN COUNTER WAS TRIED HERE AND CANNOT EXIST. Verse allows a module-scoped
# `var` only if it is a `weak_map`, and only reads and writes through a key:
# script error 3502, "Module-scoped `var` may only be partially read or written".
# That is the whole reason the gate above is a weak_map rather than a plain
# logic. If a generation number is ever needed, it has to be
# `var RunGenerationFor : weak_map(player, int)` and be read per contestant.
# Nothing needs one yet, so there is none.

# ENDS THE RUN FOR EVERYONE. The gate closes, so every manager sitting in
# AwaitMatchStart begins waiting again, and every manager racing AwaitRunEnd
# has its work cancelled wherever it had got to.
EndRunForAll(Device : creative_device):void =
    for (P : Device.GetPlayspace().GetPlayers()):
        if (set MatchStartedFor[P] = false):
            Log("DEBUG: run gate closed for a contestant.")
    Log("DEBUG: run ended.")

# OPENS THE GATE WITHOUT THE BROADCAST. This is PLAY AGAIN: straight back into
# a fresh run rather than back to the title card. LEAVE THE SHOW does not call
# this, which is the whole difference between the two buttons.
BeginRunForAll(Device : creative_device):void =
    for (P : Device.GetPlayspace().GetPlayers(), P.IsActive[]):
        if (set MatchStartedFor[P] = true):
            Log("DEBUG: run gate opened for a contestant.")

# The mirror of AwaitMatchStart: comes back the moment the run ends.
AwaitRunEnd(Device : creative_device)<suspends>:void =
    loop:
        if (MatchHasStarted(Device)?):
            Sleep(0.1)
        else:
            break

start_screen_manager := class(creative_device):

    # ---------------------------------------------------------------------
    # WHAT THE SCREEN SAYS
    #
    # Plain @editable strings, so the wording can be tried out in UEFN without
    # touching this file. Anything changed there must be mirrored back into the
    # defaults here in the same sitting, per CLAUDE.md section 10.
    # ---------------------------------------------------------------------

    @editable
    ShowTitle : string = "SPONSOR ME, SLAYERS!"

    @editable
    ShowSubtitle : string = "TONIGHT'S CONTESTANT: YOU"

    @editable
    ShowFooter : string = "THE NETWORK ACCEPTS NO LIABILITY FOR WHAT HAPPENS NEXT"

    @editable
    PlayLabel : string = "PLAY"

    @editable
    CollectablesLabel : string = "COLLECTABLES"

    @editable
    LeaderboardLabel : string = "LEADERBOARD"

    @editable
    BackLabel : string = "BACK"

    # Hide Fortnite's own HUD while the screen is up. Untick only for
    # debugging: with the HUD showing, the health bar and hotbar draw over the
    # card.
    @editable
    HideGameHUD : logic = true

    # ---------------------------------------------------------------------
    # THE TWELVE COLLECTABLES (amendment 69c)
    #
    # Placeholder only. These twelve are the approved set, cheapest first, and
    # every slot reads LOCKED because nothing saves ownership yet. When
    # CollectablesManager.verse is built, this list moves there and this screen
    # reads the save instead.
    # ---------------------------------------------------------------------

    # SUPERSEDED, AND NOT THE REAL LIST. Amendment 70f replaced this whole start
    # screen with the television broadcast in BroadcastScreen.verse, and this
    # device is not placed in the map: its startup line has never appeared in a
    # log. The twelve names below are from before the prize vault existed.
    #
    # THE REAL LIST IS PrizeVault.verse. Fourteen prizes, Kai's own wording,
    # saved to the Epic account. Do not edit these twelve expecting to see a
    # change: nothing draws them.
    #
    # THE FILE STAYS, THE SCREEN DOES NOT. AwaitMatchStart, MatchHasStarted,
    # MatchStartedFor, ScreenLine and Log all live at the bottom of this file and
    # eleven other scripts depend on them. Deleting the file would take the whole
    # project down. Flagged rather than removed in the 2026-08-26 audit.
    CollectableNames : []string = array:
        "TOASTER"
        "DESK FAN"
        "BLENDER"
        "ROTARY TELEPHONE"
        "BOOMBOX"
        "WAFFLE IRON"
        "MICROWAVE"
        "VACUUM CLEANER"
        "RETRO TV"
        "SEWING MACHINE"
        "WASHING MACHINE"
        "REFRIGERATOR"

    # The broadcast palette, matching the wave banner so the two read as one
    # show: purple panel, warm cream headline.
    BackdropColor : color = MakeColorFromHex("120A18")
    HeadlineColor : color = MakeColorFromHex("FFE9A8")
    BodyColor : color = MakeColorFromHex("FFFFFF")
    DimColor : color = MakeColorFromHex("C9A9D6")

    # ---------------------------------------------------------------------
    # LIVE STATE
    # ---------------------------------------------------------------------

    # The screen currently on show, so it can be taken away again on PLAY.
    var Screen : ?canvas = false

    # The two sub-panels, hidden until their button is clicked.
    var VaultPanel : ?canvas = false
    var BoardPanel : ?canvas = false

    # The three menu buttons, hidden while a sub-panel is open.
    var MenuGroup : ?stack_box = false

    OnBegin<override>()<suspends>:void =
        Playspace := GetPlayspace()
        Playspace.PlayerAddedEvent().Subscribe(OnPlayerAdded)

        for (P : Playspace.GetPlayers()):
            ShowStartScreen(P)

    # A contestant who arrives after this device has begun still gets the card,
    # unless the match is already live.
    OnPlayerAdded(P : player):void =
        if (MatchHasStarted(Self)?):
            Log("DEBUG: Start screen skipped for a contestant who joined after PLAY.")
        else:
            ShowStartScreen(P)

    # ---------------------------------------------------------------------
    # BUILDING THE SCREEN
    # ---------------------------------------------------------------------

    ShowStartScreen(P : player):void =
        # An opaque block across the whole screen. This is what hides the arena.
        # The arena is still there behind it, there is simply nothing to see.
        Backdrop := color_block:
            DefaultColor := BackdropColor
            DefaultOpacity := 1.0

        Headline := text_block:
            DefaultText := ScreenLine(ShowTitle)
            DefaultTextColor := HeadlineColor
            DefaultTextSize := 78.0
            DefaultJustification := text_justification.Center

        Subtitle := text_block:
            DefaultText := ScreenLine(ShowSubtitle)
            DefaultTextColor := DimColor
            DefaultTextSize := 26.0
            DefaultJustification := text_justification.Center

        Footer := text_block:
            DefaultText := ScreenLine(ShowFooter)
            DefaultTextColor := DimColor
            DefaultTextSize := 16.0
            DefaultJustification := text_justification.Center

        PlayButton := button_loud:
            DefaultText := ScreenLine(PlayLabel)

        VaultButton := button_regular:
            DefaultText := ScreenLine(CollectablesLabel)

        BoardButton := button_regular:
            DefaultText := ScreenLine(LeaderboardLabel)

        PlayButton.OnClick().Subscribe(OnPlayClicked)
        VaultButton.OnClick().Subscribe(OnCollectablesClicked)
        BoardButton.OnClick().Subscribe(OnLeaderboardClicked)

        Menu := stack_box:
            Orientation := orientation.Vertical
            Slots := array:
                stack_box_slot:
                    Widget := PlayButton
                    HorizontalAlignment := horizontal_alignment.Center
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 18.0}
                stack_box_slot:
                    Widget := VaultButton
                    HorizontalAlignment := horizontal_alignment.Center
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 12.0}
                stack_box_slot:
                    Widget := BoardButton
                    HorizontalAlignment := horizontal_alignment.Center
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

        Vault := BuildVaultPanel()
        Board := BuildBoardPanel(P)

        # Both sub-panels are built now and left hidden, so opening one is
        # instant and nothing has to be rebuilt on a click.
        Vault.SetVisibility(widget_visibility.Collapsed)
        Board.SetVisibility(widget_visibility.Collapsed)

        set MenuGroup = option{Menu}
        set VaultPanel = option{Vault}
        set BoardPanel = option{Board}

        Root := canvas:
            Slots := array:
                canvas_slot:
                    Widget := Backdrop
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 0
                canvas_slot:
                    Widget := Headline
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.16}, Maximum := vector2{X := 0.5, Y := 0.16}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    ZOrder := 1
                canvas_slot:
                    Widget := Subtitle
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.24}, Maximum := vector2{X := 0.5, Y := 0.24}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    ZOrder := 1
                canvas_slot:
                    Widget := Menu
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.52}, Maximum := vector2{X := 0.5, Y := 0.52}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    ZOrder := 2
                canvas_slot:
                    Widget := Footer
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.93}, Maximum := vector2{X := 0.5, Y := 0.93}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    ZOrder := 1
                canvas_slot:
                    Widget := Vault
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 3
                canvas_slot:
                    Widget := Board
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 3

        set Screen = option{Root}

        # InputMode All is what puts the mouse pointer on screen and stops the
        # contestant walking about behind the card. Without it there is no
        # cursor at all and no button can be clicked.
        Slot := player_ui_slot:
            ZOrder := 100
            InputMode := ui_input_mode.All

        if (PlayerUI := GetPlayerUI[P]):
            PlayerUI.AddWidget(Root, Slot)

            if (HideGameHUD?):
                GetPlayspace().GetHUDController().HideElementsForPlayer(P, array{creative_hud_identifier_all{}})

            Log("DEBUG: Start screen up. The match is holding until PLAY is clicked.")
        else:
            # Nothing can hold the match if the card never appeared, so start
            # the run rather than leave the contestant in an empty arena for
            # ever with no way out.
            Log("WARNING: Start screen could not be drawn for this contestant, so the match is starting without it.")
            ReleaseTheMatch(P)

    # The twelve locked slots, in two columns of six.
    BuildVaultPanel() : canvas =
        Heading := text_block:
            DefaultText := ScreenLine("THE PRIZE VAULT")
            DefaultTextColor := HeadlineColor
            DefaultTextSize := 46.0
            DefaultJustification := text_justification.Center

        Note := text_block:
            DefaultText := ScreenLine("TWELVE APPLIANCES, WON FROM SUPPLY CRATES. THEY KEEP BETWEEN RUNS.")
            DefaultTextColor := DimColor
            DefaultTextSize := 18.0
            DefaultJustification := text_justification.Center

        BackButton := button_regular:
            DefaultText := ScreenLine(BackLabel)

        BackButton.OnClick().Subscribe(OnBackClicked)

        Columns := stack_box:
            Orientation := orientation.Horizontal
            Slots := array:
                stack_box_slot:
                    Widget := VaultColumn(0, 5)
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 60.0, Bottom := 0.0}
                stack_box_slot:
                    Widget := VaultColumn(6, 11)
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

        Panel := canvas:
            Slots := array:
                canvas_slot:
                    Widget := Heading
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.14}, Maximum := vector2{X := 0.5, Y := 0.14}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                canvas_slot:
                    Widget := Note
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.20}, Maximum := vector2{X := 0.5, Y := 0.20}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                canvas_slot:
                    Widget := Columns
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.50}, Maximum := vector2{X := 0.5, Y := 0.50}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                canvas_slot:
                    Widget := BackButton
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.86}, Maximum := vector2{X := 0.5, Y := 0.86}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}

        Panel

    # One column of vault slots, FirstIndex through LastIndex of the twelve.
    VaultColumn(FirstIndex : int, LastIndex : int) : stack_box =
        var Rows : []stack_box_slot = array{}

        for (Index := FirstIndex..LastIndex):
            SlotNumber := Index + 1
            var SlotText : string = "{SlotNumber}.   LOCKED"
            if (Name := CollectableNames[Index]):
                set SlotText = "{SlotNumber}.   {Name}   [LOCKED]"

            Row := text_block:
                DefaultText := ScreenLine(SlotText)
                DefaultTextColor := DimColor
                DefaultTextSize := 24.0
                DefaultJustification := text_justification.Left

            set Rows += array{stack_box_slot{Widget := Row, HorizontalAlignment := horizontal_alignment.Left, Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 10.0}}}

        Column := stack_box:
            Orientation := orientation.Vertical
            Slots := Rows

        Column

    # The contestant's own record board.
    BuildBoardPanel(P : player) : canvas =
        Heading := text_block:
            DefaultText := ScreenLine("YOUR RECORD BOARD")
            DefaultTextColor := HeadlineColor
            DefaultTextSize := 46.0
            DefaultJustification := text_justification.Center

        Note := text_block:
            DefaultText := ScreenLine("YOUR FIVE BEST RUNS. THE NETWORK KEEPS SCORE WHETHER YOU LIKE IT OR NOT.")
            DefaultTextColor := DimColor
            DefaultTextSize := 18.0
            DefaultJustification := text_justification.Center

        BackButton := button_regular:
            DefaultText := ScreenLine(BackLabel)

        BackButton.OnClick().Subscribe(OnBackClicked)

        Panel := canvas:
            Slots := array:
                canvas_slot:
                    Widget := Heading
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.14}, Maximum := vector2{X := 0.5, Y := 0.14}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                canvas_slot:
                    Widget := Note
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.20}, Maximum := vector2{X := 0.5, Y := 0.20}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                canvas_slot:
                    Widget := BoardRows(P)
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.50}, Maximum := vector2{X := 0.5, Y := 0.50}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                canvas_slot:
                    Widget := BackButton
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.86}, Maximum := vector2{X := 0.5, Y := 0.86}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}

        Panel

    # Five rows, with the lifetime line underneath.
    #
    # Only the best single run is saved today, so row one is that run and rows
    # two to five are empty. The save keeps a real history the moment amendment
    # 70's third step lands, and then all five fill in.
    BoardRows(P : player) : stack_box =
        Record := ReadCareer(P)

        var Rows : []stack_box_slot = array{}

        for (Place := 1..5):
            var RowText : string = "{Place}.   ---"
            if (Place = 1, Record.BestScore > 0):
                set RowText = "{Place}.   ${Record.BestScore}   TIER {Record.BestTier}"

            Row := text_block:
                DefaultText := ScreenLine(RowText)
                DefaultTextColor := BodyColor
                DefaultTextSize := 30.0
                DefaultJustification := text_justification.Left

            set Rows += array{stack_box_slot{Widget := Row, HorizontalAlignment := horizontal_alignment.Left, Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 12.0}}}

        Lifetime := text_block:
            DefaultText := ScreenLine("CAREER EARNINGS: ${Record.LifetimeBankroll}")
            DefaultTextColor := HeadlineColor
            DefaultTextSize := 24.0
            DefaultJustification := text_justification.Left

        set Rows += array{stack_box_slot{Widget := Lifetime, HorizontalAlignment := horizontal_alignment.Left, Padding := margin{Left := 0.0, Top := 20.0, Right := 0.0, Bottom := 0.0}}}

        Board := stack_box:
            Orientation := orientation.Vertical
            Slots := Rows

        Board

    # Reads the career save written by CareerRankManager.verse. That save sits
    # at module scope, which makes it readable from here with no wire. Reading
    # only: the record is written in one place and this is not it.
    ReadCareer(P : player)<transacts>:career_record =
        if (P.IsActive[]):
            if (Existing := CareerRecords[P]):
                return Existing
        career_record{}

    # ---------------------------------------------------------------------
    # THE BUTTONS
    # ---------------------------------------------------------------------

    OnPlayClicked(Message : widget_message):void =
        ReleaseTheMatch(Message.Player)

    OnCollectablesClicked(Message : widget_message):void =
        ShowPanel(VaultPanel)

    OnLeaderboardClicked(Message : widget_message):void =
        ShowPanel(BoardPanel)

    # Both sub-panels share one BACK, because only one can ever be open.
    OnBackClicked(Message : widget_message):void =
        if (Vault := VaultPanel?):
            Vault.SetVisibility(widget_visibility.Collapsed)
        if (Board := BoardPanel?):
            Board.SetVisibility(widget_visibility.Collapsed)
        if (Menu := MenuGroup?):
            Menu.SetVisibility(widget_visibility.Visible)

    ShowPanel(Panel : ?canvas):void =
        if (Menu := MenuGroup?):
            Menu.SetVisibility(widget_visibility.Collapsed)
        if (Open := Panel?):
            Open.SetVisibility(widget_visibility.Visible)

    # PLAY. Takes the card away, gives the mouse and the HUD back, and lets
    # every waiting manager off the leash.
    ReleaseTheMatch(P : player):void =
        if (Root := Screen?, PlayerUI := GetPlayerUI[P]):
            PlayerUI.RemoveWidget(Root)
            set Screen = false

        if (HideGameHUD?):
            GetPlayspace().GetHUDController().ResetElementsForPlayer(P, array{creative_hud_identifier_all{}})

        if (P.IsActive[]):
            if (set MatchStartedFor[P] = true):
                Log("DEBUG: PLAY clicked. The match is live.")
            else:
                Log("WARNING: PLAY was clicked but the start flag could not be written, so the arena will stay empty. Restart the match.")
        else:
            Log("WARNING: PLAY was clicked by a contestant who is no longer active.")

# Text widgets take a message rather than a string, and a message has to come
# from a localizes function, so every line on this screen goes through here.
ScreenLine<localizes>(Content : string) : message = "{Content}"

# EVERY DIAGNOSTIC LINE IN THE PROJECT GOES THROUGH HERE.
#
# Verse's own Print draws its message on the screen as well as writing it to the
# log, and by this point the arena is buried under a wall of debug text. Passing
# a Duration of zero keeps the log line and takes the overlay off the game.
#
# This lives at module scope beside ScreenLine, so every file in the folder can
# reach it without a wire in UEFN. To get the on-screen text back for an
# afternoon of debugging, raise the number here and nowhere else.
Log<public>(Text : string):void =
    Print(Text, ?Duration := 0.0)
