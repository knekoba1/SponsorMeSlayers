# HypeMeterManager.verse
#
# GDD Section 3.1 "Hype Meter" -- risk-driven Hype, with a constant bleed.
#
# ORDINARY KILLS PAY NOTHING. 3.1 names the sources as "rapid multi-kills,
# close-shave dodges, and prize pickups", never plain kills. Paying per kill made
# the meter ratchet to full and park there, flattening all four crate tiers into
# one, because in a twin-stick at Smash TV density constant killing is the
# baseline rather than a flourish. Kai's ruling 2026-08-18.
#
# WHAT PAYS INSTEAD. A cluster of near-simultaneous kills pays a little, and
# taking a hit costs a lot. This is the genre's own answer: grazing in Touhou and
# CAVE, and Geometry Wars tying its multiplier to chaining kills without being
# hit, both reward surviving dangerously rather than killing efficiently. Close
# shaves, the biggest earner, are built here as of amendment 40: a hostile that
# closes inside two metres arms a shave, and it pays once the player has broken
# four metres clear of that same hostile.
#
# THE BLEED IS TWO RATES. GDD 3.1 gives one: "decays by 5% every 10 seconds of
# inactivity". Kai's ruling 2026-08-18 adds a constant 2 on top, so the meter
# always sags and has to be out-earned. The GDD's 5 is the idle rate and still
# applies as written. Recorded as an amendment.

using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
# text_block and text_justification live here; color_block, canvas and the
# rest live in the UnrealEngine UI module below, so both are needed.
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Colors }
using { /Verse.org/Simulation }

hype_meter_manager := class(creative_device):

    # All four hostile spawners, amendment 45. Order does not matter here, unlike
    # in WaveManager, because nothing in this file cares which type it is looking
    # at. Leave any of them out and those hostiles pay no Hype and offer no shave.
    @editable
    HostileSpawners : []npc_spawner_device = array{}

    # A cluster is ClusterCount kills inside ClusterWindowSeconds. The window is
    # deliberately shorter than the time it takes to kill two things one after
    # another, so only something that wipes a group at once can reach it.
    @editable
    ClusterCount : int = 4

    @editable
    ClusterWindowSeconds : float = 0.4

    # Small on purpose. Kai's call 2026-08-18: 20 and 10 both felt far too high.
    @editable
    HypePerCluster : float = 2.0

    # What each robot beyond the first on a single sniper beam is worth. Kept in
    # the same small range as the cluster above, for the reason recorded there.
    @editable
    HypePerSniperKill : float = 2.0

    # How much Hype fills the bulb at the bottom of the thermometer. Below this
    # the bulb is part full; above it, it is full and the column carries on. Ten
    # means the first ten points fill the bulb by degrees rather than all at
    # once. Raise it to make the bulb feel weightier, lower it to get to the
    # column sooner.
    @editable
    BulbFullAt : float = 10.0

    # What one hostile hit costs. This is what makes the meter fall as well as
    # rise, and it is why playing safe cannot climb it.
    @editable
    HypeLostPerHit : float = 10.0

    # GDD 3.1's "close-shave dodges", numbers from amendment 40.
    @editable
    HypePerShave : float = 3.0

    # What one prize pickup pays, when the player travelled to it. GDD 3.1 names
    # prize pickups as a Hype source and gives no number at all. 1 is Claude's
    # starting figure, delegated by Kai on 2026-08-22, and it is the first thing
    # to lower if the meter starts filling too easily.
    @editable
    HypePerTravelledPickup : float = 1.0

    # In centimetres. 200 is amendment 40's two metres: every hostile is melee
    # and swings at about arm's length, and GDD 5.3 already treats three metres
    # as the danger line, so two is inside the ring where the player could have
    # been hit rather than merely near something.
    @editable
    ShaveRadius : float = 200.0

    # In centimetres. Amendment 40's four-metre break.
    @editable
    ShaveBreakRadius : float = 400.0

    # How often hostile distances are measured. Finer than TickSeconds because
    # amendment 31 measured the contestant at 11.90 m/s, who would cross a
    # two-metre ring between two quarter-second samples.
    @editable
    ShavePollSeconds : float = 0.1

    # HOW LONG AFTER A PAID DODGE BEFORE ANOTHER CAN PAY, IN SECONDS.
    #
    # The check below runs ten times a second and pays whenever any hostile has
    # crossed the break line, so a single sprint through a crowd paid again and
    # again as they peeled off one at a time. Playtest 2026-08-24: three payments
    # inside three tenths of a second, and the meter reaching Prime Time in about
    # a minute. "One dodge, one payment" needed a clock to mean anything.
    @editable
    ShaveCooldownSeconds : float = 1.5

    # The constant bleed, applied every DrainEverySeconds.
    @editable
    AlwaysDrainPoints : float = 2.0

    # GDD 3.1's own rate, applied instead of the above once nothing has been
    # earned for IdleAfterSeconds. On a 0-to-100 meter, 5% is 5 points.
    @editable
    IdleDrainPoints : float = 5.0

    @editable
    DrainEverySeconds : float = 10.0

    @editable
    IdleAfterSeconds : float = 10.0

    # How often the cluster window, the bleed and the player's health are checked.
    @editable
    TickSeconds : float = 0.25

    MaxBarHeight : float = 300.0

    # =================================================================
    # THE THERMOMETER (GDD 3.1, and Kai's reference picture 2026-08-25)
    #
    # GDD 3.1 asks for a "vertical, thermometer-style" meter and the first build
    # gave it a plain bar. This is the instrument: a grey casing, a dark tube,
    # a coloured column climbing it, a bulb at the foot, and the four tiers
    # marked off up the side.
    #
    # THE TIER COLOURS ARE THE CRATE COLOURS. Kai's ruling. They are read
    # straight off the crate manager's own balloon materials, which run blue,
    # indigo, magenta, red from Underdog up to Prime Time, so the tier a
    # contestant is on is the colour of the parachute they are about to get.
    #
    # WHAT THE PICTURE ASKS FOR THAT A WIDGET CANNOT DO. The bulb is square,
    # because a colour block has no round corners. HYPE METER runs horizontally
    # beside the tube rather than turned on its side, because a widget cannot be
    # rotated; Kai chose beside over stacked letters.
    # =================================================================

    MeterBlack : color = MakeColorFromHex("0F1216")
    MeterGray : color = MakeColorFromHex("6E7580")
    MeterWhite : color = MakeColorFromHex("FFFFFF")

    # THE SHAPE OF A CIRCLE, AND OF A DOME, as a list of widths. There is no
    # round shape in the interface at all, so one is stacked out of square
    # blocks: each row is as wide as a circle is at that height, with a
    # transparent gap either side of it. The starburst popups on the infomercial
    # are drawn the same way.
    #
    # No row is a full 1.0, because a gap of zero is not a size a slot accepts.
    RoundProfile : []float = array{0.40, 0.64, 0.80, 0.90, 0.95, 0.96, 0.95, 0.90, 0.80, 0.64, 0.40}

    # The top half only, for capping the tube.
    DomeProfile : []float = array{0.40, 0.66, 0.82, 0.92, 0.96}

    # Underdog blue, Rising Star indigo, Superstar magenta, Prime Time red.
    UnderdogColour : color = MakeColorFromHex("25B4FF")
    RisingStarColour : color = MakeColorFromHex("6A3DF5")
    SuperstarColour : color = MakeColorFromHex("FF2D95")
    PrimeTimeColour : color = MakeColorFromHex("FF3B30")

    @editable
    MeterTitle : string = "HYPE METER"

    @editable
    UnderdogLabel : string = "UNDERDOG"

    @editable
    RisingStarLabel : string = "RISING STAR"

    @editable
    SuperstarLabel : string = "SUPERSTAR"

    @editable
    PrimeTimeLabel : string = "PRIME TIME"

    # WHERE THE TIERS CUT THE TUBE. Amendment 13 puts them at 40, 75 and 95, and
    # amendment 24 added the fourth tier above 95. Kai's reference picture shows
    # three because it was drawn before that ruling.
    @editable
    RisingStarAt : float = 40.0

    @editable
    SuperstarAt : float = 75.0

    @editable
    PrimeTimeAt : float = 95.0

    var CurrentHype : float = 0.0
    var HypeBar : ?color_block = false

    # EVERY BLOCK THE BULB IS MADE OF. It is not one square any more but a
    # stack of rows, so changing its colour means changing all of them.
    var BulbBlocks : []color_block = array{}
    var KillsInCluster : int = 0
    var SecondsSinceKill : float = 0.0
    var SecondsSinceHype : float = 0.0
    var SecondsSinceDrain : float = 0.0
    var Contestant : ?player = false
    var ArmedShaves : [agent]logic = map{}

    # Seconds left before a dodge can pay again. Counted down by the poll itself
    # rather than read off a clock, which Verse does not offer here.
    var ShaveCooldownLeft : float = 0.0

    OnBegin<override>()<suspends>:void =
        for (Spawner : HostileSpawners):
            Spawner.EliminatedEvent.Subscribe(OnHostileEliminated)
        Log("DEBUG: Hype Meter started, subscribed to the spawner.")
        # No Hype, no decay and no bar until PLAY. Amendment 70.
        AwaitMatchStart(Self)
        spawn{ WatchContestant() }
        spawn{ RunMeterTick() }
        spawn{ RunShaveWatch() }

    # Waits for the contestant, puts the bar on screen, then watches their health
    # so a hit can cost Hype. The bar used to be built only for players already in
    # the playspace the instant this device began, and in a playtest nobody is.
    # Single contestant by design; amendment 19 records the game as single-player.
    WatchContestant()<suspends>:void =
        loop:
            if (P := GetPlayspace().GetPlayers()[0]):
                set Contestant = option{P}
                ShowHypeBar(P)
                Log("DEBUG: Hype bar added for the contestant.")
                break
            Sleep(0.5)

        # The health seen on the previous check, so a drop can be spotted. 0.0
        # means nothing has been read yet.
        var LastHealth : float = 0.0
        loop:
            Sleep(TickSeconds)
            if:
                P := Contestant?
                Character := P.GetFortCharacter[]
                Character.IsActive[]
            then:
                Now := Character.GetHealth()
                if (LastHealth > 0.0, Now < LastHealth):
                    Log("DEBUG: hit taken. -{HypeLostPerHit} Hype.")
                    AddHype(-HypeLostPerHit)
                    # 3.1 pays for dodging, and a hit is the opposite, so every
                    # shave still waiting to be earned is cancelled.
                    set ArmedShaves = map{}
                set LastHealth = Now

    # The cluster window and both bleed rates, on one clock.
    RunMeterTick()<suspends>:void =
        loop:
            Sleep(TickSeconds)
            set SecondsSinceKill = SecondsSinceKill + TickSeconds
            set SecondsSinceHype = SecondsSinceHype + TickSeconds
            set SecondsSinceDrain = SecondsSinceDrain + TickSeconds

            # A cluster has to be near-simultaneous, so stale kills stop counting.
            if (SecondsSinceKill > ClusterWindowSeconds, KillsInCluster > 0):
                set KillsInCluster = 0

            if (SecondsSinceDrain >= DrainEverySeconds, CurrentHype > 0.0):
                set SecondsSinceDrain = 0.0
                if (SecondsSinceHype >= IdleAfterSeconds):
                    AddHype(-IdleDrainPoints)
                else:
                    AddHype(-AlwaysDrainPoints)

    # A hostile inside ShaveRadius arms a shave against itself, and it pays only
    # once the player has broken ShaveBreakRadius clear of that same hostile, so
    # what is paid for is escaping rather than being chased. Melee hostiles sit
    # inside two metres continuously while pursuing, and without the break rule
    # the meter would fill for standing still.
    #
    # A hostile killed while armed pays nothing. It was shot, not dodged, and the
    # cluster rule already covers killing.
    #
    # The armed set is rebuilt from the live hostiles on every pass rather than
    # edited in place, so eliminated hostiles fall out of it on their own and
    # nothing accumulates across a run.
    RunShaveWatch()<suspends>:void =
        loop:
            Sleep(ShavePollSeconds)
            if:
                P := Contestant?
                Character := P.GetFortCharacter[]
                Character.IsActive[]
            then:
                # Counted down every poll, whether or not anything escaped this
                # one. Only decrementing on quiet polls would let a continuous
                # stream of escapes hold the cooldown up forever.
                if (ShaveCooldownLeft > 0.0):
                    set ShaveCooldownLeft = ShaveCooldownLeft - ShavePollSeconds

                PlayerLocation := Character.GetTransform().Translation
                var StillArmed : [agent]logic = map{}
                var Escaped : int = 0
                for:
                    Spawner : HostileSpawners
                    Hostile : Spawner.GetAgents()
                    HostileCharacter := Hostile.GetFortCharacter[]
                    HostileCharacter.IsActive[]
                do:
                    Gap := Distance(PlayerLocation, HostileCharacter.GetTransform().Translation)
                    if (ArmedShaves[Hostile]?):
                        if (Gap >= ShaveBreakRadius):
                            set Escaped += 1
                        else:
                            set StillArmed = ConcatenateMaps(StillArmed, map{Hostile => true})
                    else:
                        if (Gap <= ShaveRadius):
                            set StillArmed = ConcatenateMaps(StillArmed, map{Hostile => true})

                # ONE DODGE, ONE PAYMENT. This used to pay per hostile escaped,
                # so breaking clear of a crowd of ten paid ten times and the
                # meter filled from one sprint. Kai spotted it on 2026-08-23,
                # and the log showed five payments inside half a second. GDD 3.1
                # calls the source "close-shave dodges", which is the manoeuvre
                # rather than the head count.
                if (Escaped > 0):
                    if (ShaveCooldownLeft <= 0.0):
                        Log("DEBUG: CLOSE SHAVE. Broke clear of {Escaped} hostile(s). +{HypePerShave} Hype.")
                        AddHype(HypePerShave)
                        set ShaveCooldownLeft = ShaveCooldownSeconds
                    else:
                        Log("DEBUG: Close shave ignored, {ShaveCooldownLeft} seconds still on the dodge cooldown.")

                set ArmedShaves = StillArmed

    ShowHypeBar(P : player)<suspends>:void =
        # The whole instrument is laid out inside its own canvas, in fractions
        # of that canvas rather than in pixels, so it holds its shape whatever
        # size the meter is given.
        #
        # WHERE THE TUBE RUNS. The column of mercury is empty at TubeBottom and
        # full at TubeTop, and every tier mark is placed by the same sum, so
        # moving a cut point on the device moves its mark with it.
        TubeTop := 0.055
        TubeBottom := 0.845
        Span := TubeBottom - TubeTop

        Casing := color_block:
            DefaultColor := MeterGray
            DefaultOpacity := 1.0

        Tube := color_block:
            DefaultColor := MeterBlack
            DefaultOpacity := 1.0

        # The column itself. Its height is the one thing that changes while the
        # match runs, so it is the one thing held onto.
        Bar := color_block:
            DefaultColor := UnderdogColour
            DefaultOpacity := 1.0
            DefaultDesiredSize := vector2{X := 40.0, Y := 0.0}

        set HypeBar = option{Bar}

        # THE BULB, ROUND. Kai's ruling: the square one did not read as a
        # thermometer. It is always full, the way a real one's is, and it takes
        # the tier colour along with the column above it.
        # UNLIT AT THE START. A real thermometer's bulb is always full, and
        # Kai read a full one at zero as Hype already in the meter. It sits dark
        # until the first Hype is earned and takes the tier colour from then on.
        BulbRim := BuildDisc(MeterGray, RoundProfile, false)
        Bulb := BuildDisc(MeterBlack, RoundProfile, true)

        # And a dome on top, so the tube is not a square-ended stick either.
        Cap := BuildDisc(MeterGray, DomeProfile, false)

        Title := color_block:
            DefaultColor := MeterBlack
            DefaultOpacity := 0.0

        TitleText := text_block:
            DefaultText := ScreenLine(MeterTitle)
            DefaultTextColor := MeterWhite
            DefaultTextSize := 20.0
            DefaultJustification := text_justification.Right

        Meter := canvas:
            Slots := array:
                # -- the casing, and the dark tube inside it -----------
                canvas_slot:
                    Widget := Cap
                    Anchors := anchors{Minimum := vector2{X := 0.30, Y := 0.005}, Maximum := vector2{X := 0.48, Y := 0.058}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 0
                canvas_slot:
                    Widget := Casing
                    Anchors := anchors{Minimum := vector2{X := 0.30, Y := 0.045}, Maximum := vector2{X := 0.48, Y := 0.86}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 0
                canvas_slot:
                    Widget := Tube
                    Anchors := anchors{Minimum := vector2{X := 0.315, Y := TubeTop}, Maximum := vector2{X := 0.465, Y := TubeBottom}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 1

                # -- the column, pinned by its foot so it climbs -------
                canvas_slot:
                    Widget := Bar
                    Anchors := anchors{Minimum := vector2{X := 0.39, Y := TubeBottom}, Maximum := vector2{X := 0.39, Y := TubeBottom}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 1.0}
                    SizeToContent := true
                    ZOrder := 2

                # -- the bulb --------------------------------------------
                canvas_slot:
                    Widget := BulbRim
                    Anchors := anchors{Minimum := vector2{X := 0.26, Y := 0.80}, Maximum := vector2{X := 0.52, Y := 1.00}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 1
                canvas_slot:
                    Widget := Bulb
                    Anchors := anchors{Minimum := vector2{X := 0.275, Y := 0.815}, Maximum := vector2{X := 0.505, Y := 0.985}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 2

                # -- HYPE METER, beside the tube -----------------------
                canvas_slot:
                    Widget := Title
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 0.28, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 0
                canvas_slot:
                    Widget := TitleText
                    Anchors := anchors{Minimum := vector2{X := 0.26, Y := 0.5}, Maximum := vector2{X := 0.26, Y := 0.5}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 1.0, Y := 0.5}
                    SizeToContent := true
                    ZOrder := 3

                # -- the four tiers, marked up the side ----------------
                canvas_slot:
                    Widget := TierTick(UnderdogColour)
                    Anchors := anchors{Minimum := vector2{X := 0.47, Y := TubeBottom - 0.006}, Maximum := vector2{X := 0.54, Y := TubeBottom + 0.006}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 3
                canvas_slot:
                    Widget := TierLabel(UnderdogLabel, UnderdogColour)
                    Anchors := anchors{Minimum := vector2{X := 0.56, Y := TubeBottom}, Maximum := vector2{X := 0.56, Y := TubeBottom}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.0, Y := 0.5}
                    SizeToContent := true
                    ZOrder := 3

                canvas_slot:
                    Widget := TierTick(RisingStarColour)
                    Anchors := anchors{Minimum := vector2{X := 0.47, Y := TubeBottom - Span * (RisingStarAt / 100.0) - 0.006}, Maximum := vector2{X := 0.54, Y := TubeBottom - Span * (RisingStarAt / 100.0) + 0.006}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 3
                canvas_slot:
                    Widget := TierLabel(RisingStarLabel, RisingStarColour)
                    Anchors := anchors{Minimum := vector2{X := 0.56, Y := TubeBottom - Span * (RisingStarAt / 100.0)}, Maximum := vector2{X := 0.56, Y := TubeBottom - Span * (RisingStarAt / 100.0)}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.0, Y := 0.5}
                    SizeToContent := true
                    ZOrder := 3

                canvas_slot:
                    Widget := TierTick(SuperstarColour)
                    Anchors := anchors{Minimum := vector2{X := 0.47, Y := TubeBottom - Span * (SuperstarAt / 100.0) - 0.006}, Maximum := vector2{X := 0.54, Y := TubeBottom - Span * (SuperstarAt / 100.0) + 0.006}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 3
                canvas_slot:
                    Widget := TierLabel(SuperstarLabel, SuperstarColour)
                    Anchors := anchors{Minimum := vector2{X := 0.56, Y := TubeBottom - Span * (SuperstarAt / 100.0)}, Maximum := vector2{X := 0.56, Y := TubeBottom - Span * (SuperstarAt / 100.0)}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.0, Y := 0.5}
                    SizeToContent := true
                    ZOrder := 3

                canvas_slot:
                    Widget := TierTick(PrimeTimeColour)
                    Anchors := anchors{Minimum := vector2{X := 0.47, Y := TubeBottom - Span * (PrimeTimeAt / 100.0) - 0.006}, Maximum := vector2{X := 0.54, Y := TubeBottom - Span * (PrimeTimeAt / 100.0) + 0.006}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 3
                canvas_slot:
                    Widget := TierLabel(PrimeTimeLabel, PrimeTimeColour)
                    Anchors := anchors{Minimum := vector2{X := 0.56, Y := TubeBottom - Span * (PrimeTimeAt / 100.0)}, Maximum := vector2{X := 0.56, Y := TubeBottom - Span * (PrimeTimeAt / 100.0)}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.0, Y := 0.5}
                    SizeToContent := true
                    ZOrder := 3

        # NEVER PUT A FULL-SCREEN WIDGET HERE AGAIN. Twice now: transparent
        # broke aiming, and hidden broke it too. Anything stretched over the
        # screen comes between the cursor and the world, whatever its visibility
        # is set to. Aiming is uncuttable per GDD 5.7; a readout landing in the
        # wrong corner is not. If a corner anchor misbehaves, move the anchor.
        HypeCanvas := canvas:
            Slots := array:
                canvas_slot:
                    Widget := Meter
                    Anchors := anchors{Minimum := vector2{X := 0.015, Y := 0.28}, Maximum := vector2{X := 0.235, Y := 0.82}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false

        # NO INPUT, EVER. This sits over the arena for the whole match, and a
        # layer that takes the mouse would take it away from aiming.
        Slot := player_ui_slot:
            ZOrder := 105
            InputMode := ui_input_mode.None

        if (PlayerUI := GetPlayerUI[P]):
            PlayerUI.AddWidget(HypeCanvas, Slot)
            Log("DEBUG: Hype thermometer up, tiers marked at {RisingStarAt}, {SuperstarAt} and {PrimeTimeAt}.")
        else:
            Log("WARNING: the Hype thermometer could not be drawn for this contestant.")

    # A ROUND SHAPE OUT OF SQUARE BLOCKS. Pass it the profile of what it is
    # drawing. Remember is set only for the bulb, whose blocks have to be found
    # again later so the tier colour can be put on them.
    BuildDisc(Shade : color, Widths : []float, Remember : logic) : stack_box =
        var Rows : []stack_box_slot = array{}

        for (Width : Widths):
            Gap := (1.0 - Width) / 2.0

            LeftGap := color_block:
                DefaultColor := Shade
                DefaultOpacity := 0.0

            Middle := color_block:
                DefaultColor := Shade
                DefaultOpacity := 1.0

            RightGap := color_block:
                DefaultColor := Shade
                DefaultOpacity := 0.0

            if (Remember?):
                set BulbBlocks += array{Middle}

            Row := stack_box:
                Orientation := orientation.Horizontal
                Slots := array:
                    stack_box_slot{Widget := LeftGap, HorizontalAlignment := horizontal_alignment.Fill, VerticalAlignment := vertical_alignment.Fill, Distribution := option{Gap}}
                    stack_box_slot{Widget := Middle, HorizontalAlignment := horizontal_alignment.Fill, VerticalAlignment := vertical_alignment.Fill, Distribution := option{Width}}
                    stack_box_slot{Widget := RightGap, HorizontalAlignment := horizontal_alignment.Fill, VerticalAlignment := vertical_alignment.Fill, Distribution := option{Gap}}

            set Rows += array{stack_box_slot{Widget := Row, HorizontalAlignment := horizontal_alignment.Fill, VerticalAlignment := vertical_alignment.Fill, Distribution := option{1.0}}}

        Disc := stack_box:
            Orientation := orientation.Vertical
            Slots := Rows

        Disc

    # One tier mark on the side of the tube.
    TierTick(Shade : color) : color_block =
        Tick := color_block:
            DefaultColor := Shade
            DefaultOpacity := 1.0

        Tick

    # One tier name, in the colour of the parachute that tier drops.
    TierLabel(Words : string, Shade : color) : text_block =
        Label := text_block:
            DefaultText := ScreenLine(Words)
            DefaultTextColor := Shade
            DefaultTextSize := 16.0
            DefaultJustification := text_justification.Left

        Label

    # Which tier the meter is standing in, as a colour. The column and the bulb
    # both take it, so the instrument itself says which parachute is coming.
    TierColour(Hype : float)<transacts>:color =
        if (Hype >= PrimeTimeAt):
            PrimeTimeColour
        else if (Hype >= SuperstarAt):
            SuperstarColour
        else if (Hype >= RisingStarAt):
            RisingStarColour
        else:
            UnderdogColour

    OnHostileEliminated(Result : device_ai_interaction_result):void =
        set KillsInCluster = KillsInCluster + 1
        set SecondsSinceKill = 0.0
        if (KillsInCluster >= ClusterCount):
            set KillsInCluster = 0
            Log("DEBUG: CLUSTER KILL. +{HypePerCluster} Hype.")
            AddHype(HypePerCluster)

    # GDD 3.1's "prize pickups", the third Hype source. Called by the cash drop
    # manager, and only for loot the player actually crossed the floor for, which
    # is Kai's ruling of 2026-08-22: the magnet of amendment 50 reaches 8 metres
    # in a 25-metre room and brings most piles over for free, and free money is
    # not a flourish.
    #
    # A FLAT AMOUNT IS ENOUGH BECAUSE THE FILTER DOES THE WORK. Paying per pickup
    # is the fault that made ordinary kills pay nothing: 180 drops were collected
    # in one 90-second run, so any per-item figure fills the meter in seconds.
    # Once only travelled-to drops count, most of that 180 pays nothing and a flat
    # point each is a reward rather than a flood.
    OnPrizeCollected():void =
        Log("DEBUG: TRAVELLED PICKUP. +{HypePerTravelledPickup} Hype.")
        AddHype(HypePerTravelledPickup)

    # GDD 3.1's "rapid multi-kills", for the one case the cluster rule above
    # cannot see.
    #
    # WHY THE CLUSTER RULE MISSES IT. A cluster is four kills inside four tenths
    # of a second, set that high on purpose so only wiping a group at once can
    # reach it. A sniper beam that runs a line of robots through kills two or
    # three, which is exactly the shot worth rewarding and exactly the number
    # that falls short. Kai asked for it on 2026-08-26 after pulling one off.
    #
    # IT IS PAID PER ROBOT BEYOND THE FIRST, so a beam through two pays once and
    # a beam through four pays three times. A single kill never comes through
    # here at all: the piercing manager only calls when the beam killed more
    # than the robot it was aimed at.
    OnSniperMultiKill(Killed : int):void =
        var Paid : float = 0.0
        for (Extra := 2..Killed):
            set Paid = Paid + HypePerSniperKill

        Log("DEBUG: SNIPER MULTI-KILL. {Killed} robots on one beam. +{Paid} Hype.")
        AddHype(Paid)

    AddHype(Amount : float):void =
        # Earning resets the idle clock. Losing must not, or the idle bleed would
        # keep restarting its own timer and never repeat.
        if (Amount > 0.0):
            set SecondsSinceHype = 0.0
        var NewHype : float = CurrentHype + Amount
        if (NewHype > 100.0):
            set NewHype = 100.0
        if (NewHype < 0.0):
            set NewHype = 0.0
        set CurrentHype = NewHype
        # Dark at nothing, so an empty meter looks empty.
        var Shade : color = TierColour(CurrentHype)
        if (CurrentHype <= 0.0):
            set Shade = MeterBlack
        if (Bar := HypeBar?):
            Bar.SetDesiredSize(vector2{X := 40.0, Y := MaxBarHeight * (CurrentHype / 100.0)})
            Bar.SetColor(Shade)
        PaintBulb(Shade)
        Log("Hype: {CurrentHype}")

    # THE BULB FILLS BY DEGREES, not all at once. Kai's report of 2026-08-26:
    # a couple of points of Hype lit the whole bottom of the thermometer, which
    # read as the meter jumping rather than rising.
    #
    # WHAT IT USED TO DO. Every block of the bulb was painted the tier colour the
    # instant Hype went above nothing, because the bulb was treated as one lamp
    # and only the column above it had a height. So the first kill of a run lit
    # the fattest part of the meter and everything after it crawled.
    #
    # HOW IT FILLS NOW. The bulb is a stack of rows, so each row is worth a slice
    # of the first BulbFullAt points and lights only once the Hype has passed it.
    # The rows were built top down, which is why the line being compared against
    # walks DOWNWARD from BulbFullAt to nothing: the first row in the list is the
    # top of the bulb and so the last one to light.
    PaintBulb(Shade : color):void =
        # Counted rather than converted, because Verse will not turn a whole
        # number into a fraction on its own.
        var RowsAsFloat : float = 0.0
        for (Block : BulbBlocks):
            set RowsAsFloat = RowsAsFloat + 1.0

        if (RowsAsFloat > 0.0, RowWorth := BulbFullAt / RowsAsFloat):
            var LineAbove : float = BulbFullAt

            for (Block : BulbBlocks):
                set LineAbove = LineAbove - RowWorth

                if (CurrentHype > LineAbove):
                    Block.SetColor(Shade)
                else:
                    Block.SetColor(MeterBlack)

    # Read by the Simulated Audience, which grades crates by the current Hype.
    # GDD Section 4 gives the meter and the crate parameters to one system.
    GetHype()<transacts>:float =
        CurrentHype
