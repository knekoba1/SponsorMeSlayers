# CashDropManager.verse
#
# Implements GDD Section 2.3 "Cash & Retro Prize Drops ('Ding-Ding-Ding!')"
# and Section 2.1 core-loop step 1, "Defeat Hostiles & Collect Cash," including
# the burst of coins, cash and appliances that bursts out of a dead hostile.
#
# Drops are created at runtime when a hostile dies and disposed of exactly
# DespawnSeconds later, per the prop budget in GDD Section 5.3.
#
# WHY THE ARC IS SCRIPTED AND NOT SIMULATED.
# Engine physics is not available to this system. Spawning a prop from Verse
# and calling SetDynamic(true) on it only does something if the asset carries a
# physics body, and a Content Browser search of this project's library returns
# no creative_prop_asset that has one. The only physics items in the library are
# physics_boulder_device and physics_tree_device, and both are placed devices
# (FortPlaysetItemDefinitions), which Verse cannot spawn.
#
# So the pop is drawn by hand instead. Every drop is teleported along a
# parabola, a few centimetres at a time, until it comes back down to the floor.
# It looks like a thrown object without any physics being involved, and it works
# with any prop asset at all. See RunLaunchArc below.
#
# Props made by SpawnProp do accept TeleportTo. That was tested directly: a
# spawned drop was visibly moved 500cm into the air and back. It is the fact the
# whole approach rests on, so it is recorded here rather than rediscovered.

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

cash_drop_manager := class(creative_device):

    # GDD 1.1: hostiles "dissolve into electrical sparks". Danger Red #FF3B30,
    # amendment 62. ITS "STICK TO PLAYER" SETTING MUST BE OFF, unlike the frost
    # and fire, because the thing it marks has just stopped existing.
    @editable
    DeathSparks : vfx_creator_device = vfx_creator_device{}

    # How long the burst lasts, in seconds.
    @editable
    DeathSparkSeconds : float = 0.5

    # All four hostile spawners, amendment 45. A type left out of this list
    # bursts into nothing when killed, which reads as a bug rather than a rule.
    @editable
    HostileSpawners : []npc_spawner_device = array{}

    # The loot that bursts out of a dead hostile: gold coin, cash bundle,
    # toaster, retro TV. Fill this in UEFN. Drops cycle through the list in
    # order, so every kill scatters a mix.
    @editable
    CashPropAssets : []creative_prop_asset = array{}

    # How much to shrink or grow each prop as it spawns. One entry per asset in
    # CashPropAssets, in the same order: the first number here is the size of
    # the first asset there. 1.0 is the asset's own size, 0.5 is half, 2.0 is
    # double. The library's props are wildly different sizes, the TV dwarfing
    # the cash bundle, and this is where that gets evened out.
    #
    # A short list is allowed. Any asset this does not reach spawns at 1.0, and
    # OnBegin says so at startup.
    @editable
    DropScales : []float = array{}

    @editable
    CashPickupSound : audio_player_device = audio_player_device{}

    @editable
    ScoreManager : score_manager_device = score_manager_device{}

    # How many loot props burst out of each dead hostile.
    @editable
    ItemsPerKill : int = 3

    # How far from the kill spot a drop starts, in centimetres. The launch arc
    # then carries it further out from there.
    @editable
    ScatterRadius : float = 100.0

    # How close the player has to walk before a drop counts as collected,
    # in centimetres. GDD 2.3: contact is the interaction, no pickup button.
    @editable
    PickupRadius : float = 150.0

    # How often a drop checks whether it has been reached, in seconds. Also the
    # step the magnet moves it by, so the two can never drift apart.
    @editable
    PickupPollSeconds : float = 0.1

    # How close a drop has to be before it flies to the player, in centimetres.
    # Amendment 50, and PROVISIONAL at 8 metres until the arena has a size.
    # Outside this it does not move at all, so a distant pile is still a choice.
    @editable
    MagnetRadius : float = 800.0

    # How fast it flies, centimetres per second. Above the player's measured
    # 1190 of amendment 31: a drop that cannot catch someone running away would
    # fix nothing.
    @editable
    MagnetSpeed : float = 1400.0

    # How long the magnet waits before pulling. The launch arc owns the prop's
    # position until it lands, about a second, and two things moving one prop
    # would fight over it every tick.
    @editable
    MagnetDelaySeconds : float = 1.0

    # The Hype Meter, told whenever the player collects loot they travelled to.
    # GDD 3.1 makes prize pickups a Hype source; this file is the only thing that
    # knows a pickup happened.
    #
    # IF THIS IS LEFT EMPTY NOTHING SAYS SO. An unset device reference falls back
    # to a fresh unplaced instance and the calls vanish, which is exactly how the
    # crates never fell for three sessions, amendment 63. The log line to look for
    # is "TRAVELLED PICKUP": if it never appears, this field is empty.
    @editable
    HypeMeter : hype_meter_manager = hype_meter_manager{}

    # Counts pulls that actually landed, so a magnet that is silently refused
    # can be told from one that is working.
    var MagnetPulls : int = 0

    # Outward travel speed during the launch arc, in CENTIMETRES per second.
    # Tuned by hand in playtest.
    @editable
    LaunchHorizontal : float = 150.0

    # Starting upward speed of the launch arc, in CENTIMETRES per second. This
    # alone decides how high the pop goes and how long it hangs. Tuned by hand
    # in playtest: with the default ArcGravity, 480 throws the drop about 120cm
    # up and keeps it in the air about 1 second, which carries it roughly 150cm
    # outward at the LaunchHorizontal above.
    @editable
    LaunchVertical : float = 480.0

    # How hard the arc is pulled back down, in centimetres per second, per
    # second. 980 is real-world gravity. Lower makes the pop floaty and slow,
    # higher makes it snappy and flat.
    @editable
    ArcGravity : float = 980.0

    # How long a drop stays on the floor before it vanishes. GDD 5.3 fixes
    # this at 5 seconds to protect the prop budget. The arc happens inside this
    # window, not on top of it.
    @editable
    DespawnSeconds : float = 5.0

    # The height the cash lands at, in world Z. The enemy's death position sets
    # only X and Y; this sets the height, so enemy body type and death pose no
    # longer affect it. Leave at 0 if the arena floor is at zero. Tune in UEFN.
    @editable
    FloorHeight : float = 0.0

    # How often the arc is redrawn, in seconds. About 33 updates a second, which
    # reads as smooth motion. Not editable: smaller is wasted work, larger looks
    # like the drop is skipping.
    ArcStepSeconds : float = 0.03

    # One full turn in radians. Used to pick a random compass direction.
    FullCircleRadians : float = 6.2831853

    var RunScore : int = 0
    var NextAssetIndex : int = 0

    # The winnings readout in the top-left corner.
    var WinningsText : ?text_block = false

    # Read-only access for other devices. CareerRankManager needs the run's
    # score at the moment a run ends, per GDD 2.6. This only reports the
    # number; it changes nothing.
    GetRunScore<public>()<transacts>:int = RunScore

    # A lump of cash from somewhere that is not a pickup. The prize vault uses
    # it, so a crate that hands over a novelty fridge still pays and does not
    # read as a wasted drop.
    #
    # IT DELIBERATELY PAYS NO HYPE. GDD 3.1's third Hype source is prize
    # pickups, and Kai's ruling of 2026-08-22 narrowed that to loot the player
    # actually crossed the floor for. A crate reward is already its own reward.
    AddPrizeMoney<public>(Amount : int):void =
        set RunScore += Amount
        if (Readout := WinningsText?):
            Readout.SetText(WinningsMessage(Commas(RunScore)))
        Log("Prize money: +{Amount}. Running total: {RunScore}")

    OnBegin<override>()<suspends>:void =
        for (Spawner : HostileSpawners):
            Spawner.EliminatedEvent.Subscribe(OnHostileEliminated)

        # Subscribed before the existing players are handled, for the reason
        # recorded in CareerRankManager.verse: at OnBegin the playspace is
        # usually still empty, so the loop below often runs over nobody.
        Playspace := GetPlayspace()
        Playspace.PlayerAddedEvent().Subscribe(OnPlayerAdded)
        for (P : Playspace.GetPlayers()):
            ShowWinnings(P)

        if (CashPropAssets.Length = 0):
            Log("WARNING: CashPropAssets is empty -- no cash will drop. Add the coin, cash bundle, toaster and TV prop assets in UEFN.")

        if (DropScales.Length < CashPropAssets.Length):
            Log("WARNING: DropScales has {DropScales.Length} entries but CashPropAssets has {CashPropAssets.Length}. Assets from index {DropScales.Length} onward will spawn at their own size. Add one scale per asset, in the same order.")

        spawn{ WatchForFreshRuns() }

    # PLAY AGAIN OPENS THE BANKROLL AT NOTHING. Amendment 86 ruled that cash
    # resets between runs while the prize vault and the career rank carry over,
    # and this is the piece of it still owed on 2026-08-28: a second run opened
    # holding every dollar the first one had won, so the game over card's total
    # was the two runs added together.
    #
    # Shaped as an outer loop, the same as the six managers amendment 87
    # re-armed, rather than as work raced against AwaitRunEnd. There is nothing
    # continuous here to cancel: everything else in this file hangs off events.
    #
    # THE FIRST RUN GOES THROUGH IT TOO and zeroes a score already at zero,
    # which costs nothing and means one path serves both.
    WatchForFreshRuns()<suspends>:void =
        loop:
            AwaitMatchStart(Self)

            set RunScore = 0
            if (Readout := WinningsText?):
                Readout.SetText(WinningsMessage(Commas(RunScore)))
            Log("DEBUG: fresh run -- winnings back to zero.")

            AwaitRunEnd(Self)

    OnPlayerAdded(P : player):void =
        ShowWinnings(P)

    # GDD 2.3 counts a run score on every pickup but never shows it. 5.4 lists
    # three HUD widgets and this is a fourth, so it is Kai's ruling of
    # THE TOP RIGHT CORNER, reached on 2026-08-25 after four failed attempts.
    #
    # WHY THE FIRST FOUR FAILED, recorded so the wrong lesson is not drawn from
    # them. A canvas added to the player's screen sizes itself to what is in it,
    # so an anchor at 97 per cent across was 97 per cent across the WORDS, not
    # across the screen, and the fourth attempt simply started the words at 72
    # per cent and left a gap of arena to their right. The only cure is to give
    # the canvas the screen's size, which means a sheet stretched over the
    # arena. See ShowWinnings below for the shape of it.
    #
    # AND THE SHEET IS NOT WHAT BROKE THE AIMING. It was blamed twice, and both
    # times the real culprit was a widget added with no slot, which leaves the
    # input mode at its default and takes the mouse. The chat hit the identical
    # bug the same night. Every layer this project puts over the arena now says
    # ui_input_mode.None out loud. Aiming is uncuttable per GDD 5.7, so if it
    # ever goes again, this line is the first thing to check and the first thing
    # to revert.
    #
    # WHAT DID SURVIVE the attempts: the words say CASH rather than WINNINGS,
    # and the text is 40 rather than 28. It sits lower than it used to, because
    # the LIVE badge has the very top of this edge now.
    ShowWinnings(P : player):void =
        Readout := text_block:
            DefaultText := WinningsMessage(Commas(RunScore))
            DefaultTextColor := NamedColors.Gold
            DefaultTextSize := 40.0

        set WinningsText = option{Readout}

        # THE INVISIBLE SHEET IS WHAT MAKES THE CORNER REACHABLE.
        #
        # A canvas holding only pinned widgets shrinks to fit them, so an anchor
        # of 97 per cent was 97 per cent across the WORDS and never across the
        # screen. This first slot is a colour block at zero opacity stretched
        # corner to corner, which gives the canvas the screen's own size, and
        # only then does the anchor below mean what it says.
        #
        # IT SAYS None ON THE WAY IN, AND THAT LINE IS NOT OPTIONAL. A sheet
        # over the arena broke Kai's aiming twice on 2026-08-25, both times
        # because the widget went up with no slot at all and took the mouse by
        # default. The digest is plain that None "does not consume any input".
        Layout := canvas:
            Slots := array:
                canvas_slot:
                    Widget := color_block{DefaultColor := NamedColors.Black, DefaultOpacity := 0.0}
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    SizeToContent := false
                    ZOrder := 0
                canvas_slot:
                    Widget := Readout
                    Anchors := anchors{Minimum := vector2{X := 0.97, Y := 0.05}, Maximum := vector2{X := 0.97, Y := 0.05}}
                    Alignment := vector2{X := 1.0, Y := 0.0}
                    ZOrder := 1

        if (PlayerUI := GetPlayerUI[P]):
            PlayerUI.AddWidget(Layout, player_ui_slot{ZOrder := 100, InputMode := ui_input_mode.None})

    OnHostileEliminated(Result : device_ai_interaction_result):void =
        Log("Hostile eliminated -- wiring cash drop next")
        if (Target := Result.Target?):
            Log("DEBUG: Target found, attempting drop")
            spawn{ DropCashAt(Target) }
            spawn{ BurstDeathSparks(Target) }
        else:
            Log("DEBUG: No Target on this Result -- cash drop skipped")

    # The confirmation flash of GDD 1.1. Purely visual, no effect on the game.
    #
    # It earns its place because at ten hostiles alive with only a pistol it is
    # genuinely hard to tell something that died from something still being
    # chipped at, and a flash answers that instantly.
    #
    # ONE DEVICE, SO ONE BURST AT A TIME. Two kills inside DeathSparkSeconds and
    # the effect jumps to the second body, cutting the first short. Accepted: the
    # alternative is one VFX device per concurrent hostile, and the burst is half
    # a second long.
    BurstDeathSparks(EliminatedAgent : agent)<suspends>:void =
        if (FortCharacter := EliminatedAgent.GetFortCharacter[]):
            Location := FortCharacter.GetTransform().Translation
            if (DeathSparks.TeleportTo[Location, IdentityRotation()]):
                DeathSparks.Begin()
                Sleep(DeathSparkSeconds)
                DeathSparks.End()

    DropCashAt(EliminatedAgent : agent)<suspends>:void =
        if:
            FortCharacter := EliminatedAgent.GetFortCharacter[]
            CashPropAssets.Length > 0
        then:
            CharacterLocation := FortCharacter.GetTransform().Translation
            Log("DEBUG: Body Z={CharacterLocation.Z} (ignored), Final drop Z={FloorHeight}")

            for (Item := 0..ItemsPerKill - 1):
                SpawnLocation := RandomScatterLocation(CharacterLocation)

                AssetIndex := NextAssetIndex
                if (NewIndex := Mod[NextAssetIndex + 1, CashPropAssets.Length]):
                    set NextAssetIndex = NewIndex

                if (Asset := CashPropAssets[AssetIndex]):
                    # Scale has to ride in on a transform. The Position/Rotation
                    # form of SpawnProp takes no scale argument at all and always
                    # uses the asset's own size, so the transform form is the
                    # only way to resize a prop as it spawns.
                    PropScale := ScaleForAsset(AssetIndex)
                    ScaleVector := vector3{X := PropScale, Y := PropScale, Z := PropScale}
                    SpawnTransform := transform{Translation := SpawnLocation, Rotation := IdentityRotation(), Scale := ScaleVector}
                    SpawnResult := SpawnProp(Asset, SpawnTransform)
                    if (Prop := SpawnResult(0)?):
                        Log("DEBUG: Spawned drop {Item + 1} of {ItemsPerKill}, asset {AssetIndex} at scale {PropScale}, at X={SpawnLocation.X} Y={SpawnLocation.Y} Z={SpawnLocation.Z}")
                        spawn{ RunDropLifetime(Prop, SpawnLocation) }
                    else:
                        Log("DEBUG: SpawnProp failed for asset index {AssetIndex}")
                else:
                    Log("DEBUG: Asset index {AssetIndex} lookup failed")
        else:
            Log("DEBUG: GetFortCharacter failed, or CashPropAssets is empty")

    # Rolls the spot a drop starts from. The offset starts inside a square, then
    # gets pulled back onto the edge of the circle if it landed outside, so
    # nothing ever starts further from the kill than ScatterRadius. Height is
    # always FloorHeight, so body type and death pose cannot affect it.
    RandomScatterLocation(CharacterLocation : vector3)<transacts>:vector3 =
        RawOffset := vector3{X := GetRandomFloat(-ScatterRadius, ScatterRadius), Y := GetRandomFloat(-ScatterRadius, ScatterRadius), Z := 0.0}
        OffsetDistance := Distance(RawOffset, vector3{X := 0.0, Y := 0.0, Z := 0.0})
        Offset := if (OffsetDistance > ScatterRadius) then RawOffset * (ScatterRadius / OffsetDistance) else RawOffset
        vector3{X := CharacterLocation.X + Offset.X, Y := CharacterLocation.Y + Offset.Y, Z := FloorHeight}

    # The size to spawn one asset at, looked up by its position in the list.
    # Falls back to 1.0, the asset's own size, when DropScales is shorter than
    # CashPropAssets. This deliberately cannot fail: a half-filled scale list
    # should never be able to stop loot dropping.
    ScaleForAsset(AssetIndex : int)<transacts>:float =
        var Scale : float = 1.0
        if (Found := DropScales[AssetIndex]):
            set Scale = Found
        Scale

    # One copy of this runs per dropped prop. It races the player against the
    # clock: whoever gets there first wins. Either way the prop is removed at
    # the end, so nothing outlives its 5 seconds (GDD 5.3).
    RunDropLifetime(Prop : creative_prop, SpawnLocation : vector3)<suspends>:void =
        # Fly the arc alongside the race rather than before it, so the
        # five-second clock starts the instant the drop appears and the player
        # can catch a drop out of the air.
        #
        # This is spawn, not branch. A spawned task keeps running after this
        # function ends, so RunLaunchArc checks the prop is still there on every
        # step and stops itself once the prop has been collected or disposed.
        spawn{ RunLaunchArc(Prop, SpawnLocation) }

        var CollectedBy : ?agent = false
        var TravelledFor : logic = false
        race:
            block:
                Result := AwaitPickup(Prop)
                set CollectedBy = option{Result(0)}
                set TravelledFor = Result(1)
            block:
                Sleep(DespawnSeconds)

        # Read the prop's final resting place for the pickup sound. Falls back
        # to where it spawned if the prop is already gone.
        var FinalLocation : vector3 = SpawnLocation
        if (Prop.IsValid[]):
            set FinalLocation = Prop.GetTransform().Translation

        if (CollectingAgent := CollectedBy?):
            OnCashCollected(CollectingAgent, FinalLocation, TravelledFor)
        else:
            Log("DEBUG: Drop despawned uncollected after {DespawnSeconds}s")

        if (Prop.IsValid[]):
            Prop.Dispose()

    # Throws one drop along a parabola by hand, with no engine physics.
    #
    # The idea is the same one a physics engine uses, just written out. The drop
    # holds an outward direction and an upward speed. Every ArcStepSeconds it is
    # moved a little way along that direction, moved up by its current upward
    # speed, and then that upward speed is reduced by ArcGravity. So it climbs,
    # slows, stops, and falls back, which is the arc. When it reaches the floor
    # it is set down exactly on FloorHeight and left there.
    #
    # Everything is in centimetres and centimetres per second, matching the
    # units TeleportTo uses.
    #
    # A normal flight is silent. Only a refused TeleportTo says anything, and it
    # reports how many steps in it got, because that is the useful part.
    RunLaunchArc(Prop : creative_prop, StartLocation : vector3)<suspends>:void =
        # A random compass direction. Taking Cos and Sin of one random angle
        # gives a direction of exactly length 1, so the outward speed comes out
        # the same whichever way the drop happens to be thrown.
        Angle := GetRandomFloat(0.0, FullCircleRadians)
        DirectionX := Cos(Angle)
        DirectionY := Sin(Angle)

        var CurrentX : float = StartLocation.X
        var CurrentY : float = StartLocation.Y
        var CurrentZ : float = StartLocation.Z
        var UpSpeed : float = LaunchVertical

        # Counts teleports that actually landed, so a failure message can say
        # how far the drop got before it stopped.
        var StepCount : int = 0

        loop:
            Sleep(ArcStepSeconds)

            if (Prop.IsValid[]):
                set CurrentX += DirectionX * LaunchHorizontal * ArcStepSeconds
                set CurrentY += DirectionY * LaunchHorizontal * ArcStepSeconds
                set CurrentZ += UpSpeed * ArcStepSeconds
                set UpSpeed -= ArcGravity * ArcStepSeconds

                # Back down to the floor. Set it down level and stop flying it.
                if (CurrentZ <= FloorHeight):
                    if (Prop.TeleportTo[vector3{X := CurrentX, Y := CurrentY, Z := FloorHeight}, IdentityRotation()]):
                        set StepCount += 1
                    else:
                        Log("DEBUG: Landing TeleportTo failed after {StepCount} steps -- drop rests where it stopped")
                    return

                if (Prop.TeleportTo[vector3{X := CurrentX, Y := CurrentY, Z := CurrentZ}, IdentityRotation()]):
                    set StepCount += 1
                else:
                    Log("DEBUG: Arc STOPPED at step {StepCount} -- TeleportTo failed mid-flight")
                    return
            else:
                # The drop was collected or despawned mid-flight. Nothing to do.
                return

    # Checks ten times a second whether anybody has walked close enough to the
    # drop, and hands back the first player who does. Measures against the
    # prop's live position, not where it spawned, because the loot is flying.
    #
    # It also hands back whether this drop was out of magnet reach at the moment
    # the magnet became eligible to pull it, which is what decides whether the
    # pickup pays Hype. Kai's ruling 2026-08-22, GDD 3.1's "prize pickups".
    #
    # THE TEST IS MADE ONCE, AND NOT AS "WAS IT EVER PULLED". After the magnet
    # wakes, any drop the player walks toward gets pulled for its last stretch, so
    # "ever pulled" would answer yes to everything the player travelled for. A
    # drop already inside the magnet's reach when it woke was never a decision;
    # one outside it could only ever arrive because the player closed the gap.
    AwaitPickup(Prop : creative_prop)<suspends>:tuple(agent, logic) =
        var Collector : ?agent = false
        var Elapsed : float = 0.0
        var Judged : logic = false
        var Travelled : logic = false
        loop:
            if (Prop.IsValid[]):
                PropLocation := Prop.GetTransform().Translation
                for:
                    Player : GetPlayspace().GetPlayers()
                    FortCharacter := Player.GetFortCharacter[]
                    Distance(FortCharacter.GetTransform().Translation, PropLocation) <= PickupRadius
                do:
                    set Collector = option{Player}

                if (not Collector?, Elapsed >= MagnetDelaySeconds):
                    if (not Judged?):
                        set Judged = true
                        set Travelled = OutOfMagnetReach(PropLocation)
                    PullTowardPlayer(Prop, PropLocation)

            if (Found := Collector?):
                return (Found, Travelled)

            set Elapsed = Elapsed + PickupPollSeconds
            Sleep(PickupPollSeconds)

    # Whether every player is further away than the magnet can reach. True means
    # this drop is not coming to anybody on its own.
    OutOfMagnetReach(PropLocation : vector3):logic =
        var Result : logic = true
        for:
            Player : GetPlayspace().GetPlayers()
            FortCharacter := Player.GetFortCharacter[]
            Distance(FortCharacter.GetTransform().Translation, PropLocation) <= MagnetRadius
        do:
            set Result = false
        Result

    # Moves one drop a single step toward the nearest player inside MagnetRadius.
    # Amendment 50. A drop with nobody in range does not move, which is what
    # keeps a pile across the arena worth deciding about.
    #
    # Flat pull: the height is pinned to FloorHeight so a drop slides along the
    # ground rather than rising toward the camera.
    PullTowardPlayer(Prop : creative_prop, PropLocation : vector3):void =
        var BestGap : float = MagnetRadius
        var Target : vector3 = PropLocation
        var Found : logic = false
        for:
            Player : GetPlayspace().GetPlayers()
            FortCharacter := Player.GetFortCharacter[]
        do:
            PlayerLocation := FortCharacter.GetTransform().Translation
            Gap := Distance(PlayerLocation, PropLocation)
            if (Gap <= BestGap):
                set BestGap = Gap
                set Target = PlayerLocation
                set Found = true

        if (Found?, BestGap > 0.0):
            Step := MagnetSpeed * PickupPollSeconds
            DirectionX := (Target.X - PropLocation.X) / BestGap
            DirectionY := (Target.Y - PropLocation.Y) / BestGap
            NewLocation := vector3{X := PropLocation.X + DirectionX * Step, Y := PropLocation.Y + DirectionY * Step, Z := FloorHeight}
            if (Prop.TeleportTo[NewLocation, IdentityRotation()]):
                set MagnetPulls += 1

    OnCashCollected(CollectingAgent : agent, DropLocation : vector3, TravelledFor : logic):void =
        set RunScore += 10
        if (Readout := WinningsText?):
            Readout.SetText(WinningsMessage(Commas(RunScore)))
        Log("DEBUG: Drop collected at X={DropLocation.X} Y={DropLocation.Y}")

        # GDD 3.1's "prize pickups". Only loot the player crossed the floor for
        # pays; see AwaitPickup for why.
        if (TravelledFor?):
            HypeMeter.OnPrizeCollected()

        # The instigator route was tried and did not work: Play(CollectingAgent)
        # with Can Be Heard By set to Instigator and Play Location set to
        # Instigating Player stayed silent, with the asset confirmed good in the
        # editor preview. So this is the other route the API documents. Register
        # adds the player as a target, then a plain Play() fires at everyone
        # currently registered.
        #
        # REQUIRES a UEFN setting: Play Location must be Registered Players.
        #
        # The speaker is no longer teleported to the drop. A sound played at a
        # player does not come from anywhere in the arena, so moving it was
        # doing nothing.
        CashPickupSound.Register(CollectingAgent)
        CashPickupSound.Play()

        ScoreManager.Increment(CollectingAgent)
        Log("Cash collected! Running total: {RunScore}")

# "WINNINGS: $1,250". Kept separate from the counting code so the wording can
# be changed without touching anything that matters.
WinningsMessage<localizes>(Amount : string) : message = "CASH: ${Amount}"

# Verse has no thousands separator, so this builds one: 1250 becomes "1,250".
Commas(Amount : int)<transacts>:string =
    Digits := "{Amount}"
    var Out : string = ""
    for (I -> Ch : Digits):
        set Out = "{Out}{Ch}"
        Remaining := Digits.Length - 1 - I
        if (Remaining > 0, Mod[Remaining, 3] = 0):
            set Out = "{Out},"
    Out
