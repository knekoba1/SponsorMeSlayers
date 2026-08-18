# CareerRankManager.verse
#
# GDD Section 2.6 "Career Sponsor Rank (Persistent Progression)", one of the four
# features GDD 5.7 names as uncuttable.
#
# WHAT THIS DOES. At the end of a run it reads the final score and the tier
# reached, banks whichever are personal bests, adds the run's cash to a lifetime
# bankroll, and promotes the player at most one rank. At the start of the next
# match it shows the holographic host title card, and fires the promotion bark
# if one is owed.
#
# NINE RULINGS SHAPED THIS FILE. All were made by Kailee on 2026-08-16 and are
# recorded in GDD_AMENDMENTS.md, item 12 and items 17 to 19. In short:
#
#   * Promotion is against FIXED targets, not the player's own record. GDD 2.6's
#     literal wording arguably says otherwise; this is a deliberate departure.
#   * Rank is driven by the BEST SINGLE RUN. The lifetime bankroll is tracked and
#     displayed but never drives the rank, because highest-tier-reached cannot
#     accumulate and a lifetime score would eventually kill the tier half.
#   * ONE promotion per run, so nobody skips title cards and barks.
#   * Rank NEVER falls.
#   * Persistence is Epic-account cloud save. GDD 2.6 calls it "locally-saved";
#     UEFN cannot do that. See item 17.
#   * The title card is a HUD card at MATCH START. There is no main menu in
#     UEFN. See item 18.
#   * The game is SINGLE-PLAYER. See item 19.
#
# WHY THE SAVE LOOKS LIKE THIS. UEFN's only persistence is a module-scoped var
# weak_map keyed on the player, saved by Epic against the player's Epic account.
# The Verse digest is explicit that using a player as that key when it is not
# active is a RUNTIME ERROR, not a silent no-op, so every read and write below
# is guarded by Player.IsActive[].

using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
# text_block lives here. color_block and canvas live in the UnrealEngine UI
# module below, so both imports are needed.
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Colors }
using { /Verse.org/Simulation }

# One player's career, as saved to their Epic account.
#
# RankIndex is the rank actually held, 0 through 4. It is stored separately from
# BestTier and BestScore on purpose: the one-promotion-per-run rule means the
# held rank can lag behind what the records already qualify for, and the gap is
# what pays out over later runs.
career_record := struct<concrete><computes><persistable>:
    BestScore : int = 0
    BestTier : int = 1
    RankIndex : int = 0
    LifetimeBankroll : int = 0
    JustPromoted : logic = false

# The save itself. Module scope is required: UEFN will not persist a var that
# lives inside a class.
var CareerRecords : weak_map(player, career_record) = map{}

career_rank_manager := class(creative_device):

    # ---------------------------------------------------------------------
    # WIRING
    # ---------------------------------------------------------------------

    # The cash drop manager, for the run's score. Read at run end via
    # GetRunScore.
    #
    # Deliberately NOT the score_manager_device. That device is not placed in
    # the map, and the call meant to drive it is wrong: hello_world_device.verse
    # line 321 calls Increment, which only changes how much the NEXT award is
    # worth, where it needs Activate, which actually grants points. So the
    # device has never held a real score. The Verse counter in that same file is
    # the number that is correct. See BUILD_ORDER.md item 25.
    @editable
    CashDrops : cash_drop_manager = cash_drop_manager{}

    # The wave manager, for the tier reached. Needs GetCurrentTier() on it.
    @editable
    Waves : wave_manager = wave_manager{}

    # Press to call the title card back up mid-run. Place an Input Trigger
    # device and pick which Creative Input Action it listens for; Fortnite
    # exposes a fixed list rather than arbitrary keys, and players can rebind it
    # under Keyboard Settings.
    @editable
    ShowCardInput : input_trigger_device = input_trigger_device{}

    # Optional. Walk into it to wipe this player's career. Off unless
    # DevResetEnabled is true, so a shipped build cannot trip it.
    @editable
    DevResetTrigger : trigger_device = trigger_device{}

    @editable
    DevResetEnabled : logic = false

    # ---------------------------------------------------------------------
    # THE LADDER (GDD 2.6, thresholds ruled 2026-08-16)
    # ---------------------------------------------------------------------
    #
    # Beating EITHER the tier or the score threshold qualifies for that rank.
    # Tier 3 is reachable in a couple of rooms so nobody stalls at Rookie.
    # Tier 21 is the hard cap in GDD 5.5, so the top title means the ceiling.
    #
    # The score rate is 10 points per pickup, read from hello_world_device.verse
    # line 303 (`set RunScore += 10`) rather than assumed. Combined with
    # WaveSize 10 at Tier 1 and ItemsPerKill 3, both scaling 8% per tier, the
    # four score thresholds approximate what a player collects reaching each
    # tier. If the rate ever changes, all four scale by the same factor. Mirror
    # any change made in UEFN back into this file, per CLAUDE.md section 10.

    @editable
    TierForUndercardFiller : int = 3
    @editable
    ScoreForUndercardFiller : int = 1000

    @editable
    TierForFanFavorite : int = 7
    @editable
    ScoreForFanFavorite : int = 2500

    @editable
    TierForRatingsMagnet : int = 13
    @editable
    ScoreForRatingsMagnet : int = 6500

    @editable
    TierForNetworksSweetheart : int = 21
    @editable
    ScoreForNetworksSweetheart : int = 15000

    # How long the title card stays on screen at match start.
    @editable
    TitleCardSeconds : float = 6.0

    RankNames : []string = array:
        "Debt-Ridden Rookie"
        "Undercard Filler"
        "Fan Favorite"
        "Ratings Magnet"
        "The Network's Sweetheart"

    var TitleCard : ?text_block = false
    var BankrollLine : ?text_block = false

    # True while a card is on screen, so a second request is ignored rather
    # than drawing a second card over the first.
    var CardOnScreen : logic = false

    # Set true when the key is pressed while a card is already up. The card
    # watches this and takes itself away, so the same key both shows and hides.
    var DismissRequested : logic = false

    # How often the card checks whether you have asked it to go. Ten times a
    # second reads as instant and costs nothing.
    PollSeconds : float = 0.1

    # ---------------------------------------------------------------------

    OnBegin<override>()<suspends>:void =
        Playspace := GetPlayspace()

        ShowCardInput.PressedEvent.Subscribe(OnShowCardPressed)

        if (DevResetEnabled?):
            DevResetTrigger.TriggeredEvent.Subscribe(OnDevResetTriggered)
            Print("DEBUG: Career Rank developer reset is ENABLED. Turn DevResetEnabled off before shipping.")

        # Subscribed before the existing players are handled, so anyone arriving
        # while that loop runs is still caught. This matches the pattern in
        # DeathSaveManager.verse and StartingLoadoutManager.verse.
        #
        # WITHOUT THIS THE CARD NEVER DRAWS. At OnBegin the playspace is usually
        # empty: the device starts before the player has spawned, so the loop
        # below runs over nobody. Proven by playtest on 2026-08-16, where the
        # "Title card shown" diagnostic never printed once.
        Playspace.PlayerAddedEvent().Subscribe(OnPlayerAdded)

        for (P : Playspace.GetPlayers()):
            ShowCardIfPromoted(P)

    OnPlayerAdded(P : player):void =
        ShowCardIfPromoted(P)

    # GDD 2.6 makes the card the thing advancing "unlocks", so Kai's ruling
    # 2026-08-17 is that it greets you only in the run after a promotion.
    # Showing it every match start handed an unearned title to a player who
    # had done nothing yet. The show-card key calls it up any time.
    ShowCardIfPromoted(P : player):void =
        Record := LoadRecord(P)
        if (Record.JustPromoted?):
            spawn{ ShowTitleCard(P) }

    # The card lives at match start (amendment 18), so it is gone a few seconds
    # in. This calls it back on demand rather than leaving a permanent widget on
    # screen, which GDD 2.4 warns against ("prevent HUD clutter") and which
    # GDD 5.4's three-widget HUD budget has no room for.
    #
    # Press once to show, press again to put it away. The CardOnScreen guard
    # still matters: without it, mashing the key stacks card on card.
    OnShowCardPressed(Agent : agent):void =
        if (CardOnScreen?):
            set DismissRequested = true
        else if (P := player[Agent]):
            spawn{ ShowTitleCard(P) }

    # -- Reading and writing the save -------------------------------------

    # Never touch CareerRecords without this. The digest warns that using an
    # inactive player as a module-scoped weak_map key is a runtime error.
    LoadRecord(P : player)<transacts>:career_record =
        if (P.IsActive[]):
            if (Existing := CareerRecords[P]):
                return Existing
        career_record{}

    SaveRecord(P : player, Record : career_record):void =
        if (P.IsActive[]):
            if (set CareerRecords[P] = Record):
                Print("DEBUG: Career saved -- rank {Record.RankIndex}, best tier {Record.BestTier}, best score {Record.BestScore}, lifetime {Record.LifetimeBankroll}")
            else:
                Print("WARNING: Career Rank could not be written for this player. The rank will not carry to the next run.")
        else:
            Print("WARNING: Career Rank was not saved because the player is no longer active.")

    # -- The ladder --------------------------------------------------------

    # The highest rank these records qualify for, 0 through 4. Either threshold
    # is enough on its own, per GDD 2.6's "beating either threshold".
    QualifiedRank(BestTier : int, BestScore : int)<transacts>:int =
        var Earned : int = 0
        if (BestTier >= TierForUndercardFiller or BestScore >= ScoreForUndercardFiller):
            set Earned = 1
        if (BestTier >= TierForFanFavorite or BestScore >= ScoreForFanFavorite):
            set Earned = 2
        if (BestTier >= TierForRatingsMagnet or BestScore >= ScoreForRatingsMagnet):
            set Earned = 3
        if (BestTier >= TierForNetworksSweetheart or BestScore >= ScoreForNetworksSweetheart):
            set Earned = 4
        Earned

    RankName(Index : int)<transacts>:string =
        if (Name := RankNames[Index]):
            return Name
        "Debt-Ridden Rookie"

    # -- Run end -----------------------------------------------------------
    #
    # Called by DeathSaveManager.EndRun just before the match is ended, because
    # the record has to be banked while the player is still active.

    OnRunEnded<public>(P : player):void =
        FinalScore := CashDrops.GetRunScore()
        FinalTier := Waves.GetCurrentTier()

        var Record : career_record = LoadRecord(P)

        # Personal bests only ever go up.
        var NewBestScore : int = Record.BestScore
        if (FinalScore > NewBestScore):
            set NewBestScore = FinalScore

        var NewBestTier : int = Record.BestTier
        if (FinalTier > NewBestTier):
            set NewBestTier = FinalTier

        # The bankroll accumulates every run regardless of how it went. This is
        # GDD 2.1 step 6's "accumulate exponential bankroll". It is displayed,
        # never used to promote.
        NewBankroll := Record.LifetimeBankroll + FinalScore

        Earned := QualifiedRank(NewBestTier, NewBestScore)

        # ONE rung per run. A run that qualifies for three ranks grants one, and
        # the rest pay out over later runs.
        var NewRankIndex : int = Record.RankIndex
        var Promoted : logic = false
        if (Earned > Record.RankIndex):
            set NewRankIndex = Record.RankIndex + 1
            set Promoted = true
            Print("DEBUG: Promoted to {RankName(NewRankIndex)}. Records qualify for {RankName(Earned)}, so {Earned - NewRankIndex} further promotion(s) are banked.")

        SaveRecord(P, career_record:
            BestScore := NewBestScore
            BestTier := NewBestTier
            RankIndex := NewRankIndex
            LifetimeBankroll := NewBankroll
            JustPromoted := Promoted
        )

    # -- Match start -------------------------------------------------------

    ShowTitleCard(P : player)<suspends>:void =
        set CardOnScreen = true
        set DismissRequested = false
        Record := LoadRecord(P)

        Card := text_block:
            DefaultText := TitleCardMessage(RankName(Record.RankIndex))
            DefaultTextColor := NamedColors.Cyan
            DefaultTextSize := 42.0

        Bankroll := text_block:
            DefaultText := BankrollMessage(Record.LifetimeBankroll)
            DefaultTextColor := NamedColors.Gold
            DefaultTextSize := 22.0

        set TitleCard = option{Card}
        set BankrollLine = option{Bankroll}

        Layout := canvas:
            Slots := array:
                canvas_slot:
                    Widget := Card
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.18}, Maximum := vector2{X := 0.5, Y := 0.18}}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                canvas_slot:
                    Widget := Bankroll
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.24}, Maximum := vector2{X := 0.5, Y := 0.24}}
                    Alignment := vector2{X := 0.5, Y := 0.5}

        if (PlayerUI := GetPlayerUI[P]):
            PlayerUI.AddWidget(Layout)

            if (Record.JustPromoted?):
                FirePromotionBark(P, Record.RankIndex)
                # Clear the flag so the promotion only announces once.
                SaveRecord(P, career_record:
                    BestScore := Record.BestScore
                    BestTier := Record.BestTier
                    RankIndex := Record.RankIndex
                    LifetimeBankroll := Record.LifetimeBankroll
                    JustPromoted := false
                )

            # Still clears itself after TitleCardSeconds if left alone, but
            # checks along the way whether the key has been pressed again.
            var Waited : float = 0.0
            loop:
                if (DismissRequested? or Waited >= TitleCardSeconds):
                    break
                Sleep(PollSeconds)
                set Waited += PollSeconds
            PlayerUI.RemoveWidget(Layout)

        # Cleared out here rather than inside the branch above, so a failed
        # GetPlayerUI cannot leave the flag stuck true and block every future
        # card for the rest of the run.
        set CardOnScreen = false

    # -- The bark ----------------------------------------------------------
    #
    # GDD 2.6: advancing "triggers a custom commentator bark at match start".
    #
    # !!! PLACEHOLDER. THE LINES ARE NOT WRITTEN. !!!
    #
    # Per CLAUDE.md standing rule 3 and the GDD revision log, every announcer
    # line is hand-written by Kailee. Claude must never draft, rewrite or
    # improve one. This function is the wiring only: it fires at the right
    # moment with the right rank, and does nothing until Kai fills in the text.
    #
    # Four lines are needed, one per promotion (into Undercard Filler, Fan
    # Favorite, Ratings Magnet and The Network's Sweetheart), or five with an
    # opener for Debt-Ridden Rookie. These count against the 25-bark budget in
    # GDD 5.4, leaving twenty or twenty-one for everything else.
    FirePromotionBark(P : player, RankIndex : int):void =
        Print("DEBUG: Promotion bark trigger fired for {RankName(RankIndex)}. No line written yet -- see CLAUDE.md standing rule 3.")

    # -- Developer reset ---------------------------------------------------
    #
    # GDD_AMENDMENTS.md item 17. Persistence is Epic-account cloud save, so a
    # rank accumulates while testing and there is no other way to see the early
    # ranks again. Never ship with DevResetEnabled true.

    OnDevResetTriggered(MaybeAgent : ?agent):void =
        if (Agent := MaybeAgent?, P := player[Agent]):
            SaveRecord(P, career_record{})
            Print("DEBUG: Career Rank reset to Debt-Ridden Rookie by the developer trigger.")

# Message helpers. Text widgets take a message, not a string, and message
# functions have to live at module scope.
TitleCardMessage<localizes>(RankTitle : string) : message = "{RankTitle}"
BankrollMessage<localizes>(Amount : int) : message = "Career earnings: ${Amount}"
