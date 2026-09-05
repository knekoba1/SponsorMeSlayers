# DeathSaveManager.verse
#
# GDD Section 3.4 "The 'Death Save' Window & Rescue Methods" and the loss half
# of Section 2.5 "Win/Loss Resolution & Loop Termination".
#
# SCOPE. The manual-run rescue only. A fatal blow holds the player at 1 health,
# the screen desaturates, a Sponsor Aid med kit lands within walking
# distance, and 3 seconds decide whether the run continues.
#
# DELIBERATELY NOT HERE: the Hype Call rescue teleport. GDD 3.4 scales its
# success rate by Hype tier, 35/50/65, and HypeMeterManager.verse has no tiers,
# no Hype Call key and no cooldown yet. GDD 3.4 says the med kit spawns
# "always", whether or not the Hype Call was used, so this half stands alone and
# is complete on its own terms. Add the teleport when the Hype meter grows tiers.
#
# ALSO NOT HERE: score. That belongs elsewhere.
#
# THE LOSING BUZZER IS HERE. GDD 5.4 budgets two game-show buzzer sounds and
# the GDD only ever describes one, the win. Kai's ruling 2026-08-17, amendment
# 23: the second is the Run Lost buzzer, sounded here. 2.5 presents Win and
# Loss as two halves of one section, and the loss had no sound of its own. The
# win buzzer lives in WaveManager.verse.
#
# CAREER RANK IS BANKED HERE, BUT NOT COMPUTED HERE. GDD 2.6's record is a
# weak_map keyed on the player, and writing to it after they leave is a runtime
# error, so EndRun is the last moment the write is safe. This file makes one
# call and knows nothing about ranks. See CareerRankManager.verse.
#
# ONE DEATH SAVE PER RUN. NO RECHARGE. Kailee's ruling, 2026-08-16.
# GDD 3.4's own first line is "The Death Save is restricted to once per life."
# Its second line, about a second fatal blow taken "before the player's health
# regenerates above 25%", could be read as allowing a fresh save once health
# recovers. It is not read that way here. The first line governs: SaveSpent is
# set once and never cleared, and a second fatal blow ends the run regardless of
# how much health the player had climbed back to. No amendment is needed,
# because this is the plain reading of the section's opening rule.
#
# WITHIN A RUN. Amendment 86 gave the game a PLAY AGAIN button, so "once per
# life" and "once per run" are no longer the same sentence. A restart is a fresh
# life and hands the rescue back; see WatchPlayer. Nothing about the anti-chain
# rule inside a single run has changed.
#
# THE SLOW MOTION CANNOT BE BUILT. GDD 3.4 asks for gameplay to "slow to a
# crawl". There is no time dilation anywhere in the Fortnite, UnrealEngine or
# Verse digests, zero mentions across all three. The grayscale carries the
# moment alone until Kailee rules on a substitute. Do not silently invent one.
#
# WHY A POLL AND NOT A DAMAGE EVENT.
# DamagedEvent fires after damage has been applied. If a single hit exceeds the
# player's remaining health the engine eliminates them before any Verse code
# runs, and there is no API to prevent that. So a blow that kills outright
# CANNOT be caught, by an event or by anything else.
#
# TriggerHealth is the dial. The Death Save fires when health drops to or below
# it, so raising it catches more blows earlier at the cost of firing before the
# player was truly dead. Start low, raise it only if the log below reports
# misses. The watch loop prints MISSED whenever a player stops being active
# without this file having ended the run on purpose, which is exactly the case
# that says raise it.
#
# ONE ENGINE RULE THIS FILE IS BUILT ON. SetHealth "will be clamped between 1.0
# and GetMaxHealth" and "cannot be directly set to 0.0" (Fortnite digest 8546).
# That is why holding the player alive at 1 is reliable, and why ending the run
# goes through Damage instead.
#
# THIS FILE DOES NOT STOP A RESPAWN, AND CANNOT.
# Ending the run here eliminates the player. Fortnite will then pick them back
# up and put them at a spawn pad unless respawning is switched off in Island
# Settings. Island Settings governs rules about the player and is not reachable
# from Verse at all. Without that switch, "run lost" means a brief nap.

using { /Fortnite.com/AI }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Random }
using { /Verse.org/Simulation }

death_save_manager := class(creative_device):

    # Sponsor Aid. GDD 3.3 calls it a golden roasted med kit; amendment 67
    # makes it a med kit. Fill this in UEFN.
    # NO LONGER USED, 2026-08-24. The Sponsor Aid is an Item Spawner now, not
    # a prop, so it has no asset, no scale and no descent. Left in place rather
    # than deleted so the fall can be restored if Kai wants it back.
    @editable
    SponsorAidAsset : creative_prop_asset = DefaultCreativePropAsset

    # How much to shrink or grow the Sponsor Aid as it spawns. 1.0 is the
    # prop's own size, 2.0 is double. Props read small from a locked overhead
    # camera, and this is the one that has to be spotted in three seconds.
    # NO LONGER USED, 2026-08-24. The Sponsor Aid is an Item Spawner now, not
    # a prop, so it has no asset, no scale and no descent. Left in place rather
    # than deleted so the fall can be restored if Kai wants it back.
    @editable
    SponsorAidScale : float = 2.0

    # A VFX Creator device set to a bright green pulse in UEFN. GDD 3.3 gives
    # the Sponsor Aid a "bright green pulsing visual overlay", which is what
    # stops it being mistaken for the coins and toasters a dead hostile
    # scatters. Devices inherit TeleportTo from creative_object, so this one is
    # moved onto the item each time rather than sitting in a fixed spot.
    #
    # The colour and the pulse live on the placed device, not here. VFX Creator
    # rather than VFX Spawner: the spawner only offers pre-made effects, and the
    # creator can be customised.
    @editable
    SponsorAidGlow : vfx_creator_device = vfx_creator_device{}

    # THE ITEM SPAWNER THAT PUTS THE MED KIT OUT. Kai's ruling 2026-08-24.
    #
    # Amendment 67 made Sponsor Aid a med kit, and there is no med kit PROP in
    # the game at all, only the item, so there is nothing to spawn as scenery.
    # An Item Spawner is the only way to show the real thing, and it is the same
    # trick CrateManager uses to lay a gun out on an opened crate.
    #
    # WHAT IT COSTS. An item stays where it appears, so it cannot be flown down
    # an arc the way a prop can, and this med kit no longer falls. Kai 2026-08-24:
    # GDD 3.3's parachute belongs to the crate that carries the Sponsor Aid, and
    # that crate still parachutes. 3.4 asks only for walking distance. Kai chose
    # the med kit appearing under its green glow over a fall with no med kit.
    @editable
    SponsorAidSpawner : item_spawner_device = item_spawner_device{}

    # THE SNATCH-BACK, the same one CrateManager uses and pointed at the same
    # placed device. Kai's ruling 2026-08-29: the med kit must never sit in the
    # bag. Reaching the spot heals in code and disables the spawner in the same
    # instant, but the item lying there can still be grabbed in that split
    # second, exactly as on a crate.
    #
    # SET THE PLACED DEVICE'S "AFFECTED ITEMS" TO THE MED KIT AND NOTHING ELSE.
    # Left empty this does nothing, which is the behaviour before today.
    @editable
    MedKitRemover : item_remover_device = item_remover_device{}

    # A Post Process device with its Post Process Effect slot set to the
    # built-in PP_FilmNoir_C. This file only blends it in and out.
    #
    # THE DEVICE HAS NO SATURATION SETTING. It has no colour or contrast
    # settings either. Its entire look comes from the one effect asset in that
    # slot, so the device is a player rather than a mixing desk. None of UEFN's
    # 35 built-in effects is named grayscale; the black-and-white one is
    # PP_FilmNoir_C, because film noir is black and white. Searching that list
    # for "gray", "black" or "sat" finds nothing useful. See
    # GDD_AMENDMENTS.md item 9. Backups: PP_ComicNoir_C, PP_Desolate_C.
    @editable
    GrayscaleEffect : post_process_device = post_process_device{}

    # NO LONGER USED HERE, and kept only so unticking it on the placed device is
    # not needed. The match is no longer ended from this file: the game over
    # card owns what happens at the end of a run, and its own copy of this
    # device is what the two buttons currently activate.
    @editable
    RunEnder : end_game_device = end_game_device{}

    # The card that GDD 2.5's Run Lost now ends on. Amendment 76.
    @editable
    GameOver : game_over_screen = game_over_screen{}

    # WHO OWNS HOSTILE SPEED. Amendment 81, from the 2026-08-26 audit.
    #
    # This file used to write hostile movement speed itself, and so did the ammo
    # modifiers, and the last writer won. During a window this file's half-speed
    # was overwritten ten times a second, and closing the window set every robot
    # back to full speed, cancelling an Icy Rounds freeze the contestant had just
    # paid a crate for.
    #
    # The ammo modifier manager owns every speed write now. This file asks for
    # its slow and the two are multiplied together. POINT THIS AT THE AMMO
    # MODIFIER MANAGER DEVICE, or the window will not slow anything.
    @editable
    AmmoModifiers : ammo_modifier_manager = ammo_modifier_manager{}

    # NO LONGER USED HERE. The losing buzzer is the game over card's first beat
    # now, so point the card's Buzzer at this same placed Audio Player. Left
    # here rather than deleted, so the wiring on the placed device survives.
    @editable
    LossBuzzer : audio_player_device = audio_player_device{}

    # NO LONGER USED HERE. The card banks the run, because the rank stamp has to
    # show the rank the player leaves with. Banking it in both places would
    # count the run's cash twice.
    @editable
    CareerRank : career_rank_manager = career_rank_manager{}

    # The hostiles to slow during the window. All four spawners, amendment 45,
    # the same ones Wave Manager and the Hype Meter point at. Leave one out and
    # that type keeps running at full speed through the slow motion.
    @editable
    HostileSpawners : []npc_spawner_device = array{}

    # Speeds the player up for the length of the window. Set how much on the
    # placed device; Verse can only switch it on and off.
    @editable
    PlayerSpeedBoost : movement_modulator_device = movement_modulator_device{}

    # What hostile movement is multiplied by while the window is open. The engine
    # clamps this between 0.5 and 2, so 0.5 is the slowest a hostile can be made
    # to move and there is no point setting it lower.
    @editable
    HostileSlowMultiplier : float = 0.5

    # How often the slow is re-applied while the window is open, in seconds.
    # Hostiles that spawn mid-window arrive at full speed and need catching.
    @editable
    SlowRefreshSeconds : float = 0.25

    # How long the player has to reach the med kit.
    #
    # GDD 3.4's own figure, restored 2026-08-18. It was stretched to 5 because
    # the slow motion could not be built, and amendment 10 said it should come
    # back towards 3 if a substitute was ever found. One has: the hostiles are
    # slowed and the player is sped up during the window, which delivers the
    # same relative effect the slow motion existed for. See HostileSlowMultiplier.
    @editable
    CountdownSeconds : float = 3.0

    # How far away the med kit lands, in centimetres. GDD 3.4 says "within
    # easy walking distance", so how far is our choice, not the document's.
    #
    # 300 rather than 600, from playtest. At 600 the three seconds felt rushed:
    # the leg landed outside the eye's reach from a locked overhead camera and
    # the player spent the window hunting rather than running. Shortening the
    # distance fixes that without touching the 3 seconds, which GDD 3.4 fixes.
    @editable
    SpawnDistance : float = 300.0

    # How close the player must get to collect it, in centimetres. Matches the
    # cash drops, so pickup feels identical everywhere in the game.
    @editable
    PickupRadius : float = 150.0

    # How much health the Sponsor Aid restores, as a percentage of maximum.
    # GDD 3.3: "Restores 25% of the contestant's maximum health pool."
    @editable
    ReviveHealthPercent : float = 25.0

    # The health at or below which a blow counts as fatal. See the header: this
    # is the dial, and the log tells you when to turn it.
    #
    # 25 rather than 20, from the 2026-08-22 playtest. Hostiles hit for exactly
    # 25, so health steps 50, 25, 0 and never once lands inside a window that
    # closes at 20. The log reported MISSED. 25 catches the player on the last
    # hit they can survive, which is the blow before the fatal one.
    @editable
    TriggerHealth : float = 25.0

    # HOW MUCH SHIELD THE PLAYER IS GIVEN FOR THE LENGTH OF THE WINDOW, topped up
    # every PollSeconds so it cannot run out. Kai's ruling 2026-08-22.
    #
    # WITHOUT THIS THE WINDOW IS A FORMALITY. The 2026-08-22 playtest caught it:
    # the window opened and the player's character was gone a third of a second
    # later. HoldAliveFor below only ever watched for health falling BELOW 1,
    # which cannot happen, because a hit that exceeds a player's health
    # eliminates them outright rather than dropping them to zero. So being pinned
    # at 1 health among ten melee hostiles was not being held alive at all.
    #
    # Shield rather than health, on purpose. The health bar stays on its last
    # point, so the screen still reads as a hair from death, which is the whole
    # drama of GDD 3.4. 100 is Island Settings' Max Shields, checked 2026-08-19,
    # and a hostile hit is 20 to 25, so this absorbs four or five hits even
    # before the top-up.
    #
    # It does not weaken GDD 2.5's loss condition. The window still expires and
    # the run still ends; the player simply gets the three seconds 3.4 promises
    # rather than a third of one.
    @editable
    WindowShieldPoints : float = 100.0

    # How high above the floor the Sponsor Aid appears before it drops, in
    # centimetres. GDD 3.3 calls it a "Parachuting golden roasted med kit";
    # amendment 67 makes it a med kit, and only the look changed.
    # NO LONGER USED, 2026-08-24. The Sponsor Aid is an Item Spawner now, not
    # a prop, so it has no asset, no scale and no descent. Left in place rather
    # than deleted so the fall can be restored if Kai wants it back.
    @editable
    DropHeight : float = 800.0

    # How long the descent takes, in seconds. It runs alongside the countdown
    # rather than before it, so the player can catch the item out of the air and
    # a slow drop never steals time from the window.
    # NO LONGER USED, 2026-08-24. The Sponsor Aid is an Item Spawner now, not
    # a prop, so it has no asset, no scale and no descent. Left in place rather
    # than deleted so the fall can be restored if Kai wants it back.
    @editable
    DescentSeconds : float = 1.0

    # How often the descent is redrawn, in seconds. Not editable: about 33 steps
    # a second reads as smooth, and it matches CashDropManager's arc.
    # NO LONGER USED, 2026-08-24. The Sponsor Aid is an Item Spawner now, not
    # a prop, so it has no asset, no scale and no descent. Left in place rather
    # than deleted so the fall can be restored if Kai wants it back.
    DescentStepSeconds : float = 0.03

    # Prints every drop in health and what it left the player on. Measurement
    # aid, not gameplay: turn it off once the numbers are settled. Hits landing
    # inside the same PollSeconds check are reported as one larger drop, so
    # treat a very large number as several hostiles connecting at once rather
    # than one enormous hit.
    @editable
    LogHits : logic = true

    # The height the med kit rests at, in world Z. Same reasoning as the cash
    # drops: the player's own Z varies with pose, so it is set explicitly.
    @editable
    FloorHeight : float = 0.0

    # How often health is checked, in seconds. Not editable: 20 times a second
    # is bookkeeping, and slowing it down only widens the window in which a
    # killing blow can slip past.
    # HOW OFTEN THE CONTESTANT'S HEALTH IS CHECKED. Made tunable in the
    # 2026-08-26 audit: at 0.05 this is the busiest permanent loop in the game,
    # twenty checks a second for the whole match, and it was the one hot loop
    # with no dial on it. It cannot be raised far without missing the blow that
    # opens the window, so raise it in small steps and watch the log for MISSED.
    @editable
    PollSeconds : float = 0.05

    # One full turn in radians, for picking a random direction.
    FullCircleRadians : float = 6.2831853

    # THE ARENA'S HALF EXTENTS, so the med kit cannot be thrown through a wall.
    # Kai reported the med kit landing outside the wall on 2026-08-28. It threw
    # in a random compass direction with nothing checking the walls, so dying
    # anywhere near the edge threw the rescue out of the room, and GDD 3.4 says
    # a Sponsor Aid "always spawns within easy walking distance".
        # THE REAL WALLS, MEASURED 2026-08-28. 1220 by 720 from centre.
    #
    # It was 1050 by 550, which is SimulatedAudience's crate-drop rectangle and
    # was never the room. Every file that needed the walls copied that figure,
    # and the guard in TwinStickController then hauled Kai back every time they
    # ran at a wall they were entitled to touch. Measured properly by running
    # into all four walls and reading the positions out of the log: the east
    # wall sits past X 1184, the west past X -1223, and both the north and south
    # past Y 700.
    #
    # THE DROP RECTANGLE IS DELIBERATELY SMALLER and stays 1050 by 550, so a
    # crate never lands flush against a wall. Do not "fix" these two to match it
    # again.
    # 2560 BY 1280, corrected 2026-09-05. See WaveManager.verse for how the old
    # 1220 by 720 came to be wrong and what proves this one.
    @editable
    ArenaHalfLength : float = 1750.0

    @editable
    # THE Y AXIS REACHES 2560. Kai read the gate actors twice and both times the
    # panel gave Y -2560, Z 0, X 620 and 432. Taken at Kai's word: the gates are
    # in a wall at Y -2560, so the room reaches at least that far on Y.
    #
    # THE LOGGED ROBOT POSITIONS DO NOT AGREE and are recorded here rather than
    # argued with. Across 95 stuck-robot samples the robots pile up at Y -1190
    # and Y 1230 and never pass them, while on X they run out to -2247. If those
    # piles are a wall then Y stops at about 1250 and this number is too big.
    #
    # TOO BIG IS THE SAFE ERROR, WHICH IS WHY IT IS SET THIS WAY. These bounds
    # only ever CLAMP: they decide when a robot is called escaped and hauled
    # back, and where the contestant is held. Too small grabs robots that are
    # standing legitimately in the room, which is the fault that cost 2026-09-05
    # and 30,000 teleports in one session. Too large simply means the clamp
    # rarely fires, and a robot that genuinely stops is caught anyway by
    # BringToSpawnSide, which does not consult these numbers at all.
    ArenaHalfWidth : float = 2600.0

    # How far inside the wall the furthest the med kit may land is, in
    # centimetres, so it never lands flush against the boundary where reaching
    # it means standing in the wall.
    @editable
    AidWallInset : float = 100.0

    OnBegin<override>()<suspends>:void =
        Playspace := GetPlayspace()

        # Subscribed before the existing players are handled, so anyone
        # arriving while that loop runs is still caught.
        Playspace.PlayerAddedEvent().Subscribe(OnPlayerAdded)

        # See MedKitRemover above. Subscribed once and left alone: the spawner
        # is enabled and disabled every window, and a subscription survives it.
        SponsorAidSpawner.ItemPickedUpEvent.Subscribe(OnStrayMedKitPickedUp)

        Players := Playspace.GetPlayers()
        Log("DEBUG: Death Save watching -- {Players.Length} player(s) already here, trigger at {TriggerHealth} health")
        for (JoinedPlayer : Players):
            spawn{ WatchPlayer(JoinedPlayer) }

    # The turkey leg was pocketed rather than walked over. The rescue heal has
    # already been given by reaching the spot, so this is a spare, and a spare
    # must never sit in the bag.
    OnStrayMedKitPickedUp(Agent : agent):void =
        MedKitRemover.Remove(Agent)
        Log("DEBUG: Death Save -- a stray med kit reached the bag and was taken back out.")

    OnPlayerAdded(JoinedPlayer : player):void =
        Log("DEBUG: Death Save -- player joined, watching them")
        spawn{ WatchPlayer(JoinedPlayer) }

    # One copy runs per player for the whole match. All of this player's state
    # lives in these local variables, which is why there are no maps in this
    # file: a spawned loop per player keeps each player's state to themselves.
    WatchPlayer(TargetPlayer : player)<suspends>:void =
        # THE OUTER LOOP IS THE RESTART, amendment 86. Every flag this player
        # has is a local of WatchOneRun below, so a fresh run gets a fresh set
        # and the spent Death Save comes back on its own with nothing to clear
        # by hand. Racing AwaitRunEnd is what ends the old set.
        #
        # WITHOUT IT THE SECOND RUN HAS NO DEATH SAVE AT ALL. SaveSpent would
        # still be true when PLAY AGAIN opened the gate, so the first fatal blow
        # of run two would take the anti-chain branch: no window, no slow
        # motion, no turkey leg, straight to the sign-off card.
        #
        # GDD 3.4 SAYS ONCE PER LIFE, AND A FRESH RUN IS A FRESH LIFE. The
        # header below reads that line as once per run, which was the same thing
        # until PLAY AGAIN existed. Kailee's ruling of 2026-08-27 is that the
        # rescue comes back on a restart, which is what the section already asks
        # for. The anti-chain rule is untouched WITHIN a run.
        loop:
            AwaitMatchStart(Self)

            race:
                WatchOneRun(TargetPlayer)
                AwaitRunEnd(Self)

            Log("DEBUG: Death Save -- stood down until the next run.")

    WatchOneRun(TargetPlayer : player)<suspends>:void =
        # Set the first time a Death Save is granted and NEVER cleared inside a
        # run. This is GDD 3.4's "once per life". See WatchPlayer above for what
        # a restart does to it.
        var SaveSpent : logic = false

        # So a player eliminated outright can be told apart from one who simply
        # has not spawned yet.
        var HasBeenAlive : logic = false

        # The health seen on the previous check, so a drop can be spotted.
        # 0.0 means nothing has been read yet.
        var LastHealth : float = 0.0

        # Set immediately before this file ends a run on purpose, so the MISSED
        # warning below does not fire on our own deliberate elimination. Without
        # it, every correctly working run loss would report itself as a bug.
        var EndedByThisFile : logic = false

        loop:
            Sleep(PollSeconds)

            if:
                Character := TargetPlayer.GetFortCharacter[]
                Character.IsActive[]
            then:
                set HasBeenAlive = true

                if (LogHits?):
                    Now := Character.GetHealth()
                    # Only drops are reported. A rise means a heal, a rescue or
                    # a fresh spawn, none of which is a hit.
                    if (LastHealth > 0.0, Now < LastHealth):
                        Log("DEBUG: Death Save -- took {LastHealth - Now} damage, now on {Now} health")
                    set LastHealth = Now

                if (Character.GetHealth() <= TriggerHealth):
                    if (SaveSpent?):
                        # GDD 3.4 anti-chain: the save is gone, so a second
                        # fatal blow ends the run with no window at all.
                        Log("DEBUG: Death Save -- SECOND fatal blow. The save was already spent this run, so no window is given.")
                        set EndedByThisFile = true
                        EndRun(TargetPlayer)
                    else:
                        set SaveSpent = true
                        Survived := RunDeathSave(TargetPlayer, Character)
                        if (not Survived?):
                            set EndedByThisFile = true
            else:
                # Not active. Either we ended the run on purpose a moment ago,
                # or a blow killed outright and we never got a chance.
                if (HasBeenAlive?):
                    set HasBeenAlive = false
                    if (EndedByThisFile?):
                        set EndedByThisFile = false
                        Log("DEBUG: Death Save -- run ended by this device, as intended.")
                    else:
                        # GDD 2.5: the run is over. Without this Fortnite simply
                        # respawns them and the run carries on, which Kai saw on
                        # 2026-08-24 and did not want.
                        Log("DEBUG: Death Save -- killed outright. The blow exceeded the remaining health, so no window could open. Ending the run.")
                        EndRunAfterOutrightKill(TargetPlayer)

    # The 3-second window itself. Returns true if the player was saved.
    RunDeathSave(TargetPlayer : player, Character : fort_character)<suspends>:logic =
        Log("DEBUG: Death Save -- FATAL BLOW. Window opening for {CountdownSeconds}s. This is the only save this run.")

        # Hold them alive. SetHealth clamps to a minimum of 1.0, so this cannot
        # accidentally finish them off.
        Character.SetHealth(1.0)

        # Whatever shield the player already had, so a Sponsor Aegis that was up
        # when the blow landed is put back afterwards rather than eaten by the
        # window's own shield.
        PriorShield := Character.GetShield()
        Character.SetShield(WindowShieldPoints)

        # Amendment 68 replaces GDD 3.4's grayscale with a CCTV filter. The field
        # is still called GrayscaleEffect so the placed device stays wired; only
        # what that device is set to has changed.
        GrayscaleEffect.BlendIn(TargetPlayer)

        # GDD 3.4's slow motion, delivered the only way the engine allows.
        # Amendment 10 was right that there is no time dilation, but it never
        # checked the other half: hostile movement CAN be multiplied, and the
        # floor is 0.5. Slowing them while speeding the player up produces the
        # same relative effect the slow motion existed to create.
        PlayerSpeedBoost.Activate(TargetPlayer)
        SlowHostiles(HostileSlowMultiplier)

        PlayerLocation := Character.GetTransform().Translation
        DropLocation := WalkingDistanceLocation(PlayerLocation)

        var Saved : logic = false

        if (SponsorAidSpawner.TeleportTo[DropLocation, IdentityRotation()]):
            SponsorAidSpawner.Enable()
            SponsorAidSpawner.SpawnItem()
            Log("DEBUG: Death Save -- med kit out at X={DropLocation.X} Y={DropLocation.Y}")

            # Move the glow onto the item, then start it. If the teleport is
            # refused the effect would fire wherever it was last left, which is
            # worse than no glow at all, so it only starts when the move worked.
            if (SponsorAidGlow.TeleportTo[DropLocation, IdentityRotation()]):
                SponsorAidGlow.Begin()
            else:
                Log("DEBUG: Death Save -- glow could not be moved onto the item, leaving it off")

            race:
                block:
                    AwaitReachingSpot(DropLocation, TargetPlayer)
                    set Saved = true
                block:
                    # The player must be held at 1 health for the whole window,
                    # or a second hit during it eliminates them mid-rescue.
                    HoldAliveFor(Character, CountdownSeconds)
                block:
                    # Never finishes. The race cancels it the moment one of the
                    # other two wins, which is exactly when the slow should stop.
                    KeepHostilesSlow()
        else:
            Log("WARNING: Death Save -- the med kit spawner would not move, so there is nothing to run to. Check SponsorAidSpawner is filled in UEFN. Giving the player the window anyway.")
            HoldAliveFor(Character, CountdownSeconds)

        # Whatever happened, the screen comes back, the window's shield goes with
        # it, and the prop goes away.
        GrayscaleEffect.BlendOut(TargetPlayer)
        PlayerSpeedBoost.Deactivate(TargetPlayer)
        SlowHostiles(1.0)
        if (Character.IsActive[]):
            Character.SetShield(PriorShield)
        SponsorAidGlow.End()

        # The med kit goes with the window, collected or not. Whether disabling
        # the spawner also clears an item already sitting on the floor is the one
        # thing to watch on the next playtest, the same open question
        # CrateManager has about the gun it lays out.
        SponsorAidSpawner.Disable()

        if (Saved?):
            # Measured rather than asked for, the same way the crate's heal is.
            # SetHealth clamps at the maximum, so what was asked for and what
            # landed are not always the same number.
            Restored := Character.GetMaxHealth() * ReviveHealthPercent / 100.0
            Character.SetHealth(1.0 + Restored)
            Log("DEBUG: Death Save -- SAVED. Back on {Character.GetHealth()} health. There is no second save this run.")
        else:
            Log("DEBUG: Death Save -- window expired uncollected. Run over.")
            EndRun(TargetPlayer)

        Saved

    # Keeps the player standing for the length of the window. The shield does the
    # work; see WindowShieldPoints for why 1 health on its own did not.
    HoldAliveFor(Character : fort_character, Seconds : float)<suspends>:void =
        var Elapsed : float = 0.0
        loop:
            if (Elapsed >= Seconds):
                return
            Sleep(PollSeconds)
            set Elapsed += PollSeconds
            if (Character.IsActive[]):
                # The shield is what actually keeps them standing. Topped up
                # every poll, so no run of hits inside the window can empty it.
                Character.SetShield(WindowShieldPoints)

                # Kept for the case where something drains health without going
                # through damage at all. It has never been seen to fire.
                if (Character.GetHealth() < 1.0):
                    Character.SetHealth(1.0)

    # Waits for this player to walk onto the med kit. GDD 2.3's rule applies
    # here too: contact is the interaction, there is no pickup button.
    # The contestant reaching the spot the med kit was put out at. An item is
    # not a prop, so there is nothing to measure to and the landing spot is what
    # is known. Height is dropped from the measurement, because the character
    # stands about 85cm up and that was eating most of PickupRadius.
    AwaitReachingSpot(Spot : vector3, TargetPlayer : player)<suspends>:void =
        loop:
            Sleep(PollSeconds)
            if:
                Character := TargetPlayer.GetFortCharacter[]
                Standing := Character.GetTransform().Translation
                Distance(vector3{X := Standing.X, Y := Standing.Y, Z := 0.0}, vector3{X := Spot.X, Y := Spot.Y, Z := 0.0}) <= PickupRadius
            then:
                return

    # A spot SpawnDistance away in a random compass direction, on the floor.
    # Cos and Sin of one random angle give a direction of exactly length 1, so
    # the leg lands the same distance away whichever way it is thrown.
    WalkingDistanceLocation(PlayerLocation : vector3)<transacts>:vector3 =
        Angle := GetRandomFloat(0.0, FullCircleRadians)
        var LandingX : float = PlayerLocation.X + Cos(Angle) * SpawnDistance
        var LandingY : float = PlayerLocation.Y + Sin(Angle) * SpawnDistance

        # WOULD THAT THROW CLEAR A WALL? Then throw it straight back towards the
        # middle of the arena instead, at the same distance.
        #
        # Turning it inward is not the same as clamping it. Clamping alone drops
        # the leg flat against the wall the contestant is already stood at, so
        # in a corner it can land almost on top of them, and a rescue you walk
        # into by accident is not the three-second scramble GDD 3.4 describes.
        # Every direction is still equally likely away from the walls, which is
        # where a fatal blow usually lands.
        if (WouldClearAWall(LandingX, LandingY)?):
            Home := Sqrt(PlayerLocation.X * PlayerLocation.X + PlayerLocation.Y * PlayerLocation.Y)
            if (Home > 1.0, InwardX := -PlayerLocation.X / Home, InwardY := -PlayerLocation.Y / Home):
                set LandingX = PlayerLocation.X + InwardX * SpawnDistance
                set LandingY = PlayerLocation.Y + InwardY * SpawnDistance

        # And held inside regardless, because a contestant standing in a corner
        # can beat the turn above as well: pointing at the centre from there
        # still runs along the diagonal and can clip the wall it came from.
        vector3:
            X := HeldInside(LandingX, ArenaHalfLength - AidWallInset)
            Y := HeldInside(LandingY, ArenaHalfWidth - AidWallInset)
            Z := FloorHeight

    # Whether a point on the floor is outside the four walls, or close enough to
    # one to count. Written the outside way round on purpose: the caller wants
    # to know when to do something about it, and asking that directly avoids
    # negating a query.
    WouldClearAWall(X : float, Y : float)<transacts>:logic =
        if:
            X <= ArenaHalfLength - AidWallInset
            X >= -(ArenaHalfLength - AidWallInset)
            Y <= ArenaHalfWidth - AidWallInset
            Y >= -(ArenaHalfWidth - AidWallInset)
        then:
            false
        else:
            true

    # Holds one coordinate inside plus or minus Limit. The same helper
    # WaveManager uses for the spawn safety radius, and for the same reason.
    HeldInside(Value : float, Limit : float)<transacts>:float =
        var Held : float = Value
        if (Held > Limit):
            set Held = Limit
        if (Held < -Limit):
            set Held = -Limit
        Held

    # GDD 2.5's Run Lost. SetHealth cannot reach 0, so elimination has to come
    # from Damage. Score and the buzzer are not this file's job, and stopping
    # the respawn that follows is an Island Settings switch, not anything this
    # file can reach. Career Rank is banked here but not computed here. See the
    # header.
    # THE CHARACTER IS NO LONGER TAKEN. It was needed when this function dealt
    # the killing blow; the card leaves the contestant standing, so there is
    # nothing here to do with it. Dropped in the 2026-08-26 audit.
    EndRun(TargetPlayer : player):void =
        # THE RUN NOW ENDS ON A CARD, NOT ON AN ELIMINATION. Amendment 76, Kai's
        # brief of 2026-08-25. Three lines that used to be here have moved into
        # GameOverScreen.verse and must not come back:
        #
        #   * The buzzer. The card plays it as the first beat of its own six
        #     seconds, so sounding it here as well would double it.
        #   * CareerRank.OnRunEnded. The card banks the run itself, because the
        #     rank stamp has to show the rank the player leaves with. Banking it
        #     twice would count the run's cash into the lifetime bankroll twice.
        #   * The killing blow. The contestant is deliberately NOT eliminated
        #     any more: Fortnite deletes the body and takes the camera with it,
        #     and the card needs the arena still on screen behind it. The card
        #     freezes them where they stand instead.
        GameOver.Show(TargetPlayer)

    # A blow that exceeded the player's remaining health, so the engine
    # eliminated them before the window could open. Only Kai's own rocket splash
    # has ever done it: every hit a hostile lands is 25, which can never take
    # anyone from above the trigger to gone in one go.
    #
    # The character is already inactive here, so unlike EndRun this cannot damage
    # it or read its health. The buzzer, the career record and the match ender
    # all take the player rather than the character, which is what makes this
    # possible at all.
    EndRunAfterOutrightKill(TargetPlayer : player):void =
        # The same card, and it copes with there being no character left to
        # freeze: it says so in the log and shows anyway. The buzzer and the
        # banking both belong to the card now, for the reasons in EndRun.
        GameOver.Show(TargetPlayer)

    # Re-applies the slow while the window is open, for hostiles that spawn
    # during it. At a 0.25s spawn interval a 3-second window can admit a dozen.
    KeepHostilesSlow()<suspends>:void =
        loop:
            Sleep(SlowRefreshSeconds)
            SlowHostiles(HostileSlowMultiplier)

    # Multiplies every live hostile's movement speed. 1.0 puts them back to
    # normal. Hostiles that have already been eliminated are skipped, the same
    # IsActive check WaveManager.CountLiveHostiles uses and for the same reason.
    # ASKS RATHER THAN WRITES. See AmmoModifiers above for why this file no
    # longer touches a robot's speed directly. HostileSpawners is still filled in
    # because other parts of this file read it.
    SlowHostiles(Multiplier : float):void =
        AmmoModifiers.SetWindowSlow(Multiplier)
