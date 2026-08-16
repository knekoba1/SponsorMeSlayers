# DeathSaveManager.verse
#
# GDD Section 3.4 "The 'Death Save' Window & Rescue Methods" and the loss half
# of Section 2.5 "Win/Loss Resolution & Loop Termination".
#
# SCOPE. The manual-run rescue only. A fatal blow holds the player at 1 health,
# the screen desaturates, a Sponsor Aid turkey leg lands within walking
# distance, and 3 seconds decide whether the run continues.
#
# DELIBERATELY NOT HERE: the Hype Call rescue teleport. GDD 3.4 scales its
# success rate by Hype tier, 35/50/65, and HypeMeterManager.verse has no tiers,
# no Hype Call key and no cooldown yet. GDD 3.4 says the turkey leg spawns
# "always", whether or not the Hype Call was used, so this half stands alone and
# is complete on its own terms. Add the teleport when the Hype meter grows tiers.
#
# ALSO NOT HERE: score, Career Rank, and the buzzer. Those belong elsewhere.
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

using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Random }
using { /Verse.org/Simulation }

death_save_manager := class(creative_device):

    # The golden roasted turkey leg of GDD 3.3. Fill this in UEFN.
    @editable
    SponsorAidAsset : creative_prop_asset = DefaultCreativePropAsset

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

    # How long the player has to reach the turkey leg. GDD 3.4 fixes this at 3
    # seconds. Changing it changes the design, not the feel.
    @editable
    CountdownSeconds : float = 3.0

    # How far away the turkey leg lands, in centimetres. GDD 3.4 says "within
    # easy walking distance". 600 is about four player-widths.
    @editable
    SpawnDistance : float = 600.0

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
    @editable
    TriggerHealth : float = 1.0

    # The height the turkey leg rests at, in world Z. Same reasoning as the cash
    # drops: the player's own Z varies with pose, so it is set explicitly.
    @editable
    FloorHeight : float = 0.0

    # How often health is checked, in seconds. Not editable: 20 times a second
    # is bookkeeping, and slowing it down only widens the window in which a
    # killing blow can slip past.
    PollSeconds : float = 0.05

    # One full turn in radians, for picking a random direction.
    FullCircleRadians : float = 6.2831853

    OnBegin<override>()<suspends>:void =
        Playspace := GetPlayspace()

        # Subscribed before the existing players are handled, so anyone
        # arriving while that loop runs is still caught.
        Playspace.PlayerAddedEvent().Subscribe(OnPlayerAdded)

        Players := Playspace.GetPlayers()
        Print("DEBUG: Death Save watching -- {Players.Length} player(s) already here, trigger at {TriggerHealth} health")
        for (JoinedPlayer : Players):
            spawn{ WatchPlayer(JoinedPlayer) }

    OnPlayerAdded(JoinedPlayer : player):void =
        Print("DEBUG: Death Save -- player joined, watching them")
        spawn{ WatchPlayer(JoinedPlayer) }

    # One copy runs per player for the whole match. All of this player's state
    # lives in these local variables, which is why there are no maps in this
    # file: a spawned loop per player keeps each player's state to themselves.
    WatchPlayer(TargetPlayer : player)<suspends>:void =
        # Set the first time a Death Save is granted and NEVER cleared. This is
        # GDD 3.4's "once per life", read as once per run. See the header.
        var SaveSpent : logic = false

        # So a player eliminated outright can be told apart from one who simply
        # has not spawned yet.
        var HasBeenAlive : logic = false

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

                if (Character.GetHealth() <= TriggerHealth):
                    if (SaveSpent?):
                        # GDD 3.4 anti-chain: the save is gone, so a second
                        # fatal blow ends the run with no window at all.
                        Print("DEBUG: Death Save -- SECOND fatal blow. The save was already spent this run, so no window is given.")
                        set EndedByThisFile = true
                        EndRun(Character)
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
                        Print("DEBUG: Death Save -- run ended by this device, as intended.")
                    else:
                        Print("WARNING: Death Save MISSED -- a player stopped being active without this device ending the run. The blow exceeded their remaining health and the engine eliminated them before this code could act. Raise TriggerHealth if this keeps happening.")

    # The 3-second window itself. Returns true if the player was saved.
    RunDeathSave(TargetPlayer : player, Character : fort_character)<suspends>:logic =
        Print("DEBUG: Death Save -- FATAL BLOW. Window opening for {CountdownSeconds}s. This is the only save this run.")

        # Hold them alive. SetHealth clamps to a minimum of 1.0, so this cannot
        # accidentally finish them off.
        Character.SetHealth(1.0)

        # GDD 3.4: the screen desaturates to grayscale.
        GrayscaleEffect.BlendIn(TargetPlayer)

        PlayerLocation := Character.GetTransform().Translation
        DropLocation := WalkingDistanceLocation(PlayerLocation)

        var Saved : logic = false
        var SpawnedProp : ?creative_prop = false

        SpawnResult := SpawnProp(SponsorAidAsset, DropLocation, IdentityRotation())
        if (TurkeyLeg := SpawnResult(0)?):
            set SpawnedProp = option{TurkeyLeg}
            Print("DEBUG: Death Save -- turkey leg down at X={DropLocation.X} Y={DropLocation.Y}")

            race:
                block:
                    AwaitPickup(TurkeyLeg, TargetPlayer)
                    set Saved = true
                block:
                    # The player must be held at 1 health for the whole window,
                    # or a second hit during it eliminates them mid-rescue.
                    HoldAliveFor(Character, CountdownSeconds)
        else:
            Print("WARNING: Death Save -- SpawnProp failed, so there is no turkey leg to run to. Check SponsorAidAsset is filled in UEFN. Giving the player the window anyway.")
            HoldAliveFor(Character, CountdownSeconds)

        # Whatever happened, the screen comes back and the prop goes away.
        GrayscaleEffect.BlendOut(TargetPlayer)
        if:
            LeftOver := SpawnedProp?
            LeftOver.IsValid[]
        then:
            LeftOver.Dispose()

        if (Saved?):
            Restored := Character.GetMaxHealth() * ReviveHealthPercent / 100.0
            Character.SetHealth(1.0 + Restored)
            Print("DEBUG: Death Save -- SAVED. Restored {Restored} health. There is no second save this run.")
        else:
            Print("DEBUG: Death Save -- window expired uncollected. Run over.")
            EndRun(Character)

        Saved

    # Keeps the player pinned at 1 health for the length of the window, so a
    # stray hit during the rescue cannot end it early.
    HoldAliveFor(Character : fort_character, Seconds : float)<suspends>:void =
        var Elapsed : float = 0.0
        loop:
            if (Elapsed >= Seconds):
                return
            Sleep(PollSeconds)
            set Elapsed += PollSeconds
            if:
                Character.IsActive[]
                Character.GetHealth() < 1.0
            then:
                Character.SetHealth(1.0)

    # Waits for this player to walk onto the turkey leg. GDD 2.3's rule applies
    # here too: contact is the interaction, there is no pickup button.
    AwaitPickup(TurkeyLeg : creative_prop, TargetPlayer : player)<suspends>:void =
        loop:
            Sleep(PollSeconds)
            if:
                TurkeyLeg.IsValid[]
                Character := TargetPlayer.GetFortCharacter[]
                Distance(Character.GetTransform().Translation, TurkeyLeg.GetTransform().Translation) <= PickupRadius
            then:
                return

    # A spot SpawnDistance away in a random compass direction, on the floor.
    # Cos and Sin of one random angle give a direction of exactly length 1, so
    # the leg lands the same distance away whichever way it is thrown.
    WalkingDistanceLocation(PlayerLocation : vector3)<transacts>:vector3 =
        Angle := GetRandomFloat(0.0, FullCircleRadians)
        vector3{X := PlayerLocation.X + Cos(Angle) * SpawnDistance, Y := PlayerLocation.Y + Sin(Angle) * SpawnDistance, Z := FloorHeight}

    # GDD 2.5's Run Lost. SetHealth cannot reach 0, so elimination has to come
    # from Damage. Score, Career Rank and the buzzer are not this file's job,
    # and stopping the respawn that follows is an Island Settings switch, not
    # anything this file can reach. See the header.
    EndRun(Character : fort_character):void =
        Character.Damage(Character.GetMaxHealth() * 2.0)
