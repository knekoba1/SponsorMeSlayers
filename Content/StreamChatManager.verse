# StreamChatManager.verse
#
# GDD Section 4, the Simulated Audience's other half: the simulated stream chat.
#
# WHERE THE WORDS COME FROM, AND WHY NOT FROM HERE.
# Every line and every handle lives in SimulatedAudience.verse. This file asks
# it for a line and draws the answer, and knows nothing about either list. That
# split is CLAUDE.md section 12: the audience must stay a swappable data source,
# so a different audience device says different things without a line of this
# file changing.
#
# WHAT IT REACTS TO, AND HOW IT KNOWS.
# Nothing signals this device. It watches, which keeps the number of wires in
# UEFN down to three:
#
#   * The hostile spawners, for kills, and for a burst of kills close together.
#   * The contestant's health, polled, for taking a hit and for being nearly
#     dead. A hit is what spams L, by Kai's ruling.
#   * The Hype meter, for the tier climbing, and the cash manager, for money.
#
# Crates falling, crates opening and waves clearing are not wired yet. Their
# lines exist in the audience and simply never come up. Each would want one more
# @editable pointed at the device that knows, and that is the only thing missing.
#
# WHERE IT SITS, AND HOW THE RIGHT EDGE WAS REACHED.
# GDD 3.5 puts this widget on the LEFT of the HUD. Amendment 75 overrides that:
# the left edge belongs to the Hype thermometer, which runs nearly the full
# height of the screen, and built to the letter the chat sat on top of it.
# Under the cash counter, pinned to the RIGHT edge 13 per cent down. It began
# down the LEFT edge and sat on top of the Hype thermometer, which is why it
# moved.
#
# THE ALIGNMENT IS 1.0 AND THE SHEET IS WHY IT WORKS. Earlier attempts set an
# alignment of 1.0 on its own and pushed the widget clean off the screen, because
# a canvas added to the player's screen sizes itself to what is in it, so both
# anchor and alignment measured across the CHAT BOX rather than across the
# screen. The stretched, fully transparent first slot fixes that at the root: it
# gives the canvas the screen's size, and every number below then means what it
# says. See ShowChatBox.
#
# A SHEET OVER THE ARENA IS SAFE AS LONG AS IT SAYS None. It was blamed for two
# aiming breaks on 2026-08-25 and it was not the cause either time; a widget
# added with no slot at all was, this one included. Aiming is uncuttable per GDD
# 5.7, so ui_input_mode.None below is load-bearing.
#
# IT IS FIRST ON THE SCOPE-CUT LIST. GDD 5.7 and CLAUDE.md section 8 make the
# stream chat cut number one if the schedule slips. Untick ShowChat and it is
# gone, and nothing else in the project reads this device.

using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/Diagnostics }
# vector2 lives in SpatialMath, and the anchors on a canvas slot are built from
# it, so a file that positions anything needs this even with no maths in it.
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }
using { /Verse.org/Colors }
using { /Verse.org/Random }
using { /Verse.org/Simulation }

stream_chat_manager := class(creative_device):

    # =================================================================
    # WHAT IT IS WIRED TO
    # =================================================================

    # All four hostile spawners, for the kill lines. Leave one out and kills
    # from it pass without comment; leave them all out and the crowd never
    # reacts to a kill at all.
    @editable
    HostileSpawners : []npc_spawner_device = array{}

    # Where every word comes from. Without this the chat is silent, which is
    # the swappability working rather than a fault.
    @editable
    Audience : simulated_audience = simulated_audience{}

    # How many handles join in on the chant. See OnCrowdWantsACrate.
    @editable
    CrateChantLines : int = 4

    # Read for the tier climbing lines. Nothing is written to it.
    @editable
    HypeMeter : hype_meter_manager = hype_meter_manager{}

    # Read for the cash lines. Nothing is written to it.
    @editable
    CashDrops : cash_drop_manager = cash_drop_manager{}

    # =================================================================
    # THE DIALS
    # =================================================================

    # Untick to take the chat off the screen entirely. It is cut number one on
    # the scope-cut list, so this is the switch that performs that cut.
    @editable
    ShowChat : logic = true

    # How many lines are on screen at once. Older ones fall off the top.
    @editable
    ChatLines : int = 7

    # How big the words are. Chat is meant to be readable and ignorable at once.
    @editable
    ChatTextSize : float = 15.0

    # WHERE THE BOX SITS, as a fraction of the screen: 0 is the left edge or the
    # top, 1 is the right edge or the bottom. The box hangs DOWN and RIGHT from
    # this corner, so this is its top left.
    #
    # MOVED FROM THE RIGHT TO THE LEFT ON 2026-08-30. Kai: "can you move the cha
    # to the upper left hand corner above teh hype meter." It used to hang off
    # the right edge at 0.97, which put it under the contestant's aiming hand
    # and nowhere near the Hype bar it keeps reacting to.
    #
    # IT HAS TO CLEAR THE HYPE METER, which starts 28% of the way down the
    # screen. Seven lines at this text size come to roughly an eighth of the
    # screen's height, so from 0.03 it ends around 0.15 and there is room to
    # spare. More ChatLines, or bigger text, eats into that.
    @editable
    ChatX : float = 0.015

    @editable
    ChatY : float = 0.03

    # Seconds between checks of health, Hype and cash.
    @editable
    PollSeconds : float = 0.25

    # THE SHORTEST GAP BETWEEN TWO MESSAGES. Without it a burst of kills posts a
    # dozen lines in one frame and the whole box turns over before it can be
    # read.
    @editable
    MinGapSeconds : float = 0.35

    # How long the chat goes quiet before it starts talking among itself.
    @editable
    IdleAfterSeconds : float = 4.0

    # Seconds between the idle lines once it has started.
    @editable
    IdleEverySeconds : float = 2.5

    # How often the bot interrupts, in seconds. It never reacts to anything, so
    # this is the only thing that brings it out.
    @editable
    BotEverySeconds : float = 22.0

    # HOW MANY LINES ONE HIT IS WORTH. Kai's ruling: taking damage should spam L.
    # Two or three at a time reads as a pile-on; one reads as a comment.
    @editable
    DamageLines : int = 3

    # Health below this fraction counts as nearly dead, and the crowd writes the
    # contestant off. 0.35 is a little above the Death Save trigger, so the
    # panic starts before the rescue does.
    @editable
    LowHealthFraction : float = 0.35

    # Kills inside this window count as one burst and get the multi-kill lines.
    @editable
    BurstSeconds : float = 1.5

    @editable
    BurstCount : int = 3

    # =================================================================
    # THE LOOK
    # =================================================================

    # The broadcast's palette, so the chat sits in the same show as the rest.
    ChatBlack : color = MakeColorFromHex("0F1216")
    ChatGray : color = MakeColorFromHex("6E7580")
    ChatWhite : color = MakeColorFromHex("FFFFFF")

    # The handles cycle through these, so two names running are rarely the same
    # colour and the box reads as a crowd rather than a list.
    HandleColours : []color = array:
        MakeColorFromHex("FF2D95")
        MakeColorFromHex("25B4FF")
        MakeColorFromHex("FFDD1C")
        MakeColorFromHex("FFC233")
        MakeColorFromHex("FF3B30")

    # =================================================================
    # LIVE STATE
    # =================================================================

    # THE LINES ON SCREEN, oldest first, and each one is TWO widgets: the
    # handle and what they said. Kai's ruling: the name is coloured and the
    # message is white, and one text block cannot be two colours at once.
    var Names : []text_block = array{}
    var Says : []text_block = array{}

    # Seconds since the last message of any kind, for the gap and the idling.
    var SinceLast : float = 0.0
    var SinceIdle : float = 0.0
    var SinceBot : float = 0.0

    # The contestant's health at the last look, so a drop can be spotted.
    var LastHealth : float = 0.0

    # True once the crowd has written them off, so the panic is not repeated
    # every quarter second. Cleared when they climb back out of it.
    var CalledIt : logic = false

    # The Hype tier at the last look, so a climb can be told from standing still.
    var LastTier : int = 0

    # The run score at the last look, so only new cash is remarked on.
    var LastScore : int = 0

    # Kills inside the current burst, and how long the burst has left.
    var BurstKills : int = 0
    var BurstLeft : float = 0.0

    # Which colour the next handle takes.
    var NextColour : int = 0

    # True once the box has been drawn. It stays true across a PLAY AGAIN,
    # because ShowChatBox has no matching remove and a second run would
    # otherwise stack a second box over the first. Amendment 86.
    var ChatBoxIsUp : logic = false

    # =================================================================
    # GOING LIVE
    # =================================================================

    OnBegin<override>()<suspends>:void =
        if (not ShowChat?):
            Log("DEBUG: Stream chat is switched off on the device.")
            return

        for (Spawner : HostileSpawners):
            Spawner.EliminatedEvent.Subscribe(OnHostileEliminated)

        # THE CRATE, BOTH HALVES OF IT. Kai, 2026-08-29: the crate "should be
        # granted upon audience request and it should say it in the stream chat".
        # The audience signals the chant a beat before it orders, and the order
        # itself is the crate on its way down. Two subscriptions, two moments.
        #
        # ChatCrateFalling has been written since the chat was built and nothing
        # has ever posted it; found on 2026-08-29 while listing the lines out for
        # Kai, alongside four other sets in the same state.
        # AWAITED, NOT SUBSCRIBED. A Verse `event` has no Subscribe. Several
        # waiters on one event are all woken by a signal, which is why the
        # crate manager can go on awaiting SpawnCrateEvent alongside this.
        spawn{ WatchForCrateChants() }
        spawn{ WatchForCrateOrders() }

        Playspace := GetPlayspace()
        Playspace.PlayerAddedEvent().Subscribe(OnPlayerAdded)

        # Nothing is drawn until the show starts. The title screen has its own
        # chat-free look and the broadcast covers the whole screen anyway.
        #
        # THE OUTER LOOP IS THE RESTART, amendment 86. Both watches are raced
        # against AwaitRunEnd rather than launched with spawn, because a spawn
        # cannot be cancelled: without it the crowd would carry on talking over
        # the game over card, and a second run would have two crowds posting
        # into the one box.
        loop:
            AwaitMatchStart(Self)

            # ONCE PER MATCH, NOT ONCE PER RUN. See ChatBoxIsUp.
            if (not ChatBoxIsUp?):
                set ChatBoxIsUp = true
                for (P : Playspace.GetPlayers()):
                    ShowChatBox(P)

            StartFreshRun()

            race:
                WatchWhoeverIsPlaying()
                RunIdleChatter()
                AwaitRunEnd(Self)

            Log("DEBUG: Stream chat packed up -- the crowd is quiet until the next run.")

    # Puts the crowd's memory of the run back to nothing, so a fresh run does
    # not open with a line about a hit taken or a tier reached last time.
    # Called at the top of every run, including the first, so one path serves
    # both.
    #
    # THE CASH MARK IS READ RATHER THAN ZEROED. Whatever the counter says right
    # now becomes the new baseline, which is right whether or not the score
    # itself has been reset yet.
    StartFreshRun():void =
        set SinceLast = 0.0
        set SinceIdle = 0.0
        set SinceBot = 0.0
        set LastHealth = 0.0
        set CalledIt = false
        set LastTier = 0
        set BurstKills = 0
        set BurstLeft = 0.0
        set LastScore = CashDrops.GetRunScore()
        Log("DEBUG: fresh run -- the chat's memory of the last one is cleared.")

    # The contestant watch, wrapped so it can be one arm of the race above.
    # Amendment 19 makes this game single-player, so the first player is the
    # contestant and there is never a second to watch.
    WatchWhoeverIsPlaying()<suspends>:void =
        loop:
            if (P := GetPlayspace().GetPlayers()[0]):
                WatchTheContestant(P)
                break
            Sleep(0.5)

    # A contestant who arrives after the show has started still gets the chat.
    OnPlayerAdded(P : player):void =
        if (MatchHasStarted(Self)?):
            ShowChatBox(P)
            spawn{ WatchTheContestant(P) }

    # =================================================================
    # THE BOX
    # =================================================================

    ShowChatBox(P : player):void =
        var Slots : []stack_box_slot = array{}
        var MadeNames : []text_block = array{}
        var MadeSays : []text_block = array{}

        for (Index := 1..ChatLines):
            # The handle, in its own colour.
            Name := text_block:
                DefaultText := ScreenLine("")
                DefaultTextColor := ChatGray
                DefaultTextSize := ChatTextSize
                DefaultJustification := text_justification.Left

            # What they said, always white, so the crowd's words read as one
            # voice and only the names are a jumble of colour.
            Said := text_block:
                DefaultText := ScreenLine("")
                DefaultTextColor := ChatWhite
                DefaultTextSize := ChatTextSize
                DefaultJustification := text_justification.Left

            set MadeNames += array{Name}
            set MadeSays += array{Said}

            Line := stack_box:
                Orientation := orientation.Horizontal
                Slots := array:
                    stack_box_slot:
                        Widget := Name
                        HorizontalAlignment := horizontal_alignment.Left
                        VerticalAlignment := vertical_alignment.Center
                        Padding := margin{Left := 0.0, Top := 0.0, Right := 6.0, Bottom := 0.0}
                    stack_box_slot:
                        Widget := Said
                        HorizontalAlignment := horizontal_alignment.Left
                        VerticalAlignment := vertical_alignment.Center
                        Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}

            set Slots += array{stack_box_slot{Widget := Line, HorizontalAlignment := horizontal_alignment.Left, Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 4.0}}}

        set Names = MadeNames
        set Says = MadeSays

        Column := stack_box:
            Orientation := orientation.Vertical
            Slots := Slots

        # A dim backing so pale text stays readable over a bright arena floor.
        Backing := color_block:
            DefaultColor := ChatBlack
            DefaultOpacity := 0.45

        Box := overlay:
            Slots := array:
                overlay_slot:
                    Widget := Backing
                    HorizontalAlignment := horizontal_alignment.Fill
                    VerticalAlignment := vertical_alignment.Fill
                    Padding := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                overlay_slot:
                    Widget := Column
                    HorizontalAlignment := horizontal_alignment.Left
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{Left := 14.0, Top := 10.0, Right := 14.0, Bottom := 10.0}

        # TOP RIGHT, UNDER THE CASH, and clear of the Hype thermometer, which
        # owns the left edge and which the chat was sitting on top of.
        #
        # THE FIRST SLOT IS AN INVISIBLE SHEET, and it is what makes the corner
        # reachable. A canvas holding only pinned widgets shrinks to fit them,
        # so an anchor of 97 per cent was 97 per cent across the CHAT BOX and
        # never across the screen. Stretched corner to corner at zero opacity,
        # it hands the canvas the screen's own size. The cash readout in
        # hello_world_device.verse does the identical thing.
        Layout := canvas:
            Slots := array:
                canvas_slot:
                    Widget := color_block{DefaultColor := ChatBlack, DefaultOpacity := 0.0}
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 0
                canvas_slot:
                    Widget := Box
                    Anchors := anchors{Minimum := vector2{X := ChatX, Y := ChatY}, Maximum := vector2{X := ChatX, Y := ChatY}}

                    # THE BOX HANGS DOWN AND RIGHT FROM THE ANCHOR. Alignment
                    # 0,0 pins its top left corner there. It used to be 1,0,
                    # pinning the top RIGHT, which is what a box on the right
                    # edge of the screen needs and the wrong thing entirely for
                    # one on the left.
                    Alignment := vector2{X := 0.0, Y := 0.0}
                    ZOrder := 1

        # AN EXPLICIT INPUT MODE, AND THIS IS THE IMPORTANT LINE.
        #
        # The chat went up with no slot at all the first time, which leaves the
        # input mode to whatever the default is, and Kai's aiming broke the
        # moment the device was placed. A panel this size taking the mouse is
        # exactly that. Every layer this project puts over the arena says None,
        # and this one had not been saying it.
        Slot := player_ui_slot:
            ZOrder := 104
            InputMode := ui_input_mode.None

        if (PlayerUI := GetPlayerUI[P]):
            PlayerUI.AddWidget(Layout, Slot)
            Log("DEBUG: Stream chat up, {ChatLines} lines.")
        else:
            Log("WARNING: the stream chat could not be drawn for this contestant.")

    # =================================================================
    # POSTING
    # =================================================================

    # One message. Everything that wants to say something comes through here, so
    # the gap between messages is enforced in one place and cannot be dodged.
    # The chant. A burst rather than one line, because Kai asked for it to be
    # "noticeable and repetitive so the player can notice it", and one line in a
    # box that is already busy is neither.
    WatchForCrateChants()<suspends>:void =
        loop:
            Tier := Audience.CrateDemandEvent.Await()
            Log("DEBUG: Chat -- the crowd is chanting for a tier {Tier} crate.")
            spawn{ PostBurst(Audience.ChatCrateDemandKind, CrateChantLines) }

    # And one line as it actually comes down.
    WatchForCrateOrders()<suspends>:void =
        loop:
            Order := Audience.SpawnCrateEvent.Await()
            Log("DEBUG: Chat -- a tier {Order.Tier} crate is on its way.")
            Post(Audience.ChatCrateFallingKind)

    Post(Kind : int):void =
        if (SinceLast < MinGapSeconds):
            return

        set SinceLast = 0.0
        set SinceIdle = 0.0

        Words := Audience.ChatLineFor(Kind)
        Handle := Audience.ChatHandleFor(Kind)
        if (Words = ""):
            return

        Shade := NextHandleColour()

        # THE BOX SCROLLS BY REWRITING, not by building. Every line takes the
        # words of the one below it and the last takes the new message, so the
        # widgets themselves never change and nothing has to be added to or
        # removed from the screen while the match runs.
        Count := Names.Length
        if (Count > 1):
            for (Index := 0..Count - 2):
                if (AboveName := Names[Index], BelowName := Names[Index + 1]):
                    AboveName.SetText(ScreenLine(BelowName.GetText()))
                    AboveName.SetTextColor(BelowName.GetTextColor())
                if (AboveSaid := Says[Index], BelowSaid := Says[Index + 1]):
                    AboveSaid.SetText(ScreenLine(BelowSaid.GetText()))

        if (LastName := Names[Count - 1], LastSaid := Says[Count - 1]):
            LastName.SetText(ScreenLine("{Handle}:"))
            LastName.SetTextColor(Shade)
            LastSaid.SetText(ScreenLine(Words))

    # A burst of the same kind, for the pile-on when a hit lands. The gap is
    # deliberately stepped over here, because a pile-on IS several at once.
    PostBurst(Kind : int, Times : int)<suspends>:void =
        for (Index := 1..Times):
            set SinceLast = MinGapSeconds
            Post(Kind)
            Sleep(0.12)

    NextHandleColour()<transacts>:color =
        Count := HandleColours.Length
        if (Count > 0):
            if (Shade := HandleColours[NextColour]):
                var Following : int = NextColour + 1
                if (Following >= Count):
                    set Following = 0
                set NextColour = Following
                return Shade
        ChatGray

    # =================================================================
    # WHAT THE CROWD IS WATCHING
    # =================================================================

    OnHostileEliminated(Result : device_ai_interaction_result):void =
        set BurstKills += 1
        set BurstLeft = BurstSeconds

        if (BurstKills >= BurstCount):
            set BurstKills = 0
            set BurstLeft = 0.0
            Post(Audience.ChatMultiKillKind)
        else:
            Post(Audience.ChatKillKind)

    # Health, Hype and cash, all on the one clock.
    WatchTheContestant(P : player)<suspends>:void =
        loop:
            Sleep(PollSeconds)

            set SinceLast += PollSeconds
            set SinceIdle += PollSeconds
            set SinceBot += PollSeconds

            if (BurstLeft > 0.0):
                set BurstLeft -= PollSeconds
                if (BurstLeft <= 0.0):
                    set BurstKills = 0

            if (Character := P.GetFortCharacter[]):
                Health := Character.GetHealth()
                Most := Character.GetMaxHealth()

                # A HIT LANDED. Kai's ruling: this is what spams L.
                if (LastHealth > 0.0, Health < LastHealth):
                    spawn{ PostBurst(Audience.ChatDamageKind, DamageLines) }

                # NEARLY DEAD, said once rather than every quarter second.
                if (Most > 0.0):
                    Fraction := Health / Most
                    if (Fraction <= LowHealthFraction, not CalledIt?):
                        set CalledIt = true
                        Post(Audience.ChatLowHealthKind)
                    else if (Fraction > LowHealthFraction, CalledIt?):
                        set CalledIt = false

                set LastHealth = Health

            # THE TIER CLIMBING. Read from the meter rather than counted here,
            # so the chat and the crates agree about what tier means.
            Tier := TierForHype(HypeMeter.GetHype())
            if (Tier > LastTier):
                Post(Audience.ChatHypeKind)
            set LastTier = Tier

            # CASH. Only a change is worth a line, and only now and then, or
            # every pickup in a shower would post one.
            Score := CashDrops.GetRunScore()
            if (Score > LastScore):
                if (GetRandomInt(0, 3) = 0):
                    Post(Audience.ChatCashKind)
            set LastScore = Score

    # The crowd talking among itself when nothing is happening, and the bot
    # talking over the crowd whatever is happening.
    RunIdleChatter()<suspends>:void =
        loop:
            Sleep(IdleEverySeconds)

            if (SinceBot >= BotEverySeconds):
                set SinceBot = 0.0
                Post(Audience.ChatBotKind)
            else if (SinceIdle >= IdleAfterSeconds):
                # One in four idle lines is somebody backseating, which is what
                # a real chat does when the play is quiet.
                if (GetRandomInt(0, 3) = 0):
                    Post(Audience.ChatBackseatKind)
                else:
                    Post(Audience.ChatIdleKind)

    # Amendment 13's bands, the same four the audience and the meter use.
    TierForHype(Hype : float)<transacts>:int =
        if (Hype >= 95.0):
            3
        else if (Hype >= 75.0):
            2
        else if (Hype >= 40.0):
            1
        else:
            0
