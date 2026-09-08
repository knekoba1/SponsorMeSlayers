# DeathSaveManager.verse
#
# GDD Section 3.4 "The 'Death Save' Window & Rescue Methods" and the loss half
# of Section 2.5 "Win/Loss Resolution & Loop Termination".
#
# SCOPE. The manual-run rescue only. A fatal blow holds the player at 1 health,
# the screen desaturates, a Sponsor Aid med kit lands within walking
# distance, and 3 seconds decide whether the run continues.
#
# AND THE RESCUE TELEPORT IS HERE TOO, SINCE 2026-09-07. Amendment 133.
#
# This paragraph used to say it was deliberately absent because "HypeMeterManager
# has no tiers, no Hype Call key and no cooldown yet". All three have existed for
# some time; the note simply outlived its reason. Kai asked for it by describing
# the problem: "you can get stuck with the swarm and they get all around you."
#
# IT ALL LIVES ON THIS SIDE, AND THE VERSE LINKER DECIDED THAT. The tidier split
# put the roll in HypeMeterManager, which owns the Hype Call key, and the linker
# refused it as a cycle: hype meter to death save to game over screen to cash
# drop manager and back, script error 9000. The hype meter references no other
# class in the project and several reference it, so this file listens to the same
# placed Input Trigger, asks the meter for the tier, rolls, and rescues.
#
# GDD 3.4's other half is untouched: the walk-to-it med kit still spawns
# "always", whether or not the Hype Call was used or succeeded.
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
# AND AFTER IT IS SPENT, ONLY AN EMPTY HEALTH BAR ENDS THE RUN. Kailee's ruling,
# 2026-09-07, amendment 127. Offered the GDD's narrower second line instead, so
# that a healed-up contestant would get a fresh save, Kai turned it down and kept
# one save per run: "no one death save per run and then after if i get to 0 then
# i die and the game ends."
#
# WHAT THAT CHANGES. TriggerHealth used to end the run on the spot at 25 health,
# because 25 is where the save has to be caught. Kai's run of 2026-09-07 ended
# with health still visibly on the bar and read as unfair: "i saw my health it
# wasnt 0". So the trigger is now the save's own business. While the save is in
# hand it works exactly as before, catching the contestant at 25 and holding
# them up. Once it is gone it does nothing at all, the last 25 points are the
# contestant's to spend, and the run ends when Fortnite eliminates them.
#
# IT DOES NOT BREAK THE ANTI-CHAIN RULE. 3.4 says a second fatal blow ends the
# run instantly, and it still does: a blow that empties the bar ends the run in
# the same moment with no window. What is gone is treating "dropped below 25" as
# though it were fatal, which was an implementation's convenience and never the
# document's words.
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
# THE DAMAGE EVENT AND THE POLL, AND WHY IT NEEDS BOTH. Corrected 2026-09-05.
#
# This used to say "why a poll and not a damage event", on the grounds that
# DamagedEvent fires after damage is applied, so a single hit exceeding the
# contestant's remaining health eliminates them before any Verse code runs.
# THAT PART IS STILL TRUE. A blow that kills outright cannot be caught, by an
# event or by anything else.
#
# BUT IT WAS THE WRONG CONCLUSION, and the 2026-09-05 log is why. The contestant
# read 50 health and then "killed outright". Two 25s landed inside the same
# twentieth of a second: the first was survivable and took them to exactly the
# trigger, and the poll had not come round again when the second arrived. The
# case that was losing runs was never the unstoppable one, it was a burst the
# poll was too slow to get between.
#
# So the event now catches the first hit and pushes health straight back up
# before the second lands, and the poll stays as a fallback for anything that
# drains a contestant without going through damage at all.
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
# THE TWO UI MODULES, for the overlay this file draws itself. text_block lives in
# the Fortnite one and color_block and canvas in the UnrealEngine one, which is
# why both are needed. Added 2026-09-05.
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/UI }
using { /Verse.org/Colors }
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

    # =================================================================
    # THE OVERLAY THIS FILE DRAWS ITSELF.
    #
    # KAI, after about twenty deaths and eight playtests chasing it: "it doesnt
    # do it bruh."
    #
    # WHAT WAS TRIED AND WHAT IT PROVED. The post process device above is wired
    # to the right actor, confirmed by matching its ID in the map file. Its
    # Enabled During Phase is Always, its strength is 0.65 over 0.2 seconds, its
    # priority was raised above the match-long VHS filter, that filter was
    # disabled entirely as a test, its Starting Strength was set to 1.0 so it
    # applied permanently with no blending at all, and the material was swapped
    # between PP_CCTV and PP_FilmNoir. Nothing appeared in any of those
    # combinations, and BlendingInCompleteEvent never fired once.
    #
    # THAT LAST FACT IS THE DIAGNOSIS. A material that does not render would
    # still fire the event. An event that never fires across twenty deaths and
    # two materials means the call is not reaching the placed device at all: the
    # same shape as the sniper's Hype meter earlier the same day, wired in the
    # map and answering to an empty copy at runtime.
    #
    # SO THE WINDOW GETS ITS OWN LAYER. It is not true desaturation, which a
    # widget cannot do, and that is a real cost against GDD 3.4's "screen
    # desaturates to grayscale". It is a full-screen wash that drains the colour
    # out of the picture, drawn by the same code that already draws the Hype
    # meter and the cash counter every run without trouble.
    #
    # THE POST PROCESS CALLS ARE LEFT IN. They cost nothing, and if that device
    # is ever made to work the two will simply stack.
    # =================================================================

    @editable
    ShowDeathSaveOverlay : logic = true

    # A cold grey wash. Not black, so the arena stays readable and the
    # contestant can still see the leg they are running at.
    @editable
    OverlayColour : color = MakeColorFromHex("9AA3AD")


    var OverlayUp : ?canvas = false

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
    # 3 -> 5, KAI'S RULING 2026-09-08: "death save neds to be 5 secomds". This is
    # the third time this dial has moved and the second time it has landed on 5,
    # so the whole history is here rather than in a commit message.
    #
    # GDD 3.4 SAYS THREE AND KAI HAS OVERRULED IT. Amendment 134a. The document is
    # not being read wrongly; it is being departed from on purpose, which is the
    # only way this number is allowed to move.
    #
    # IT WAS 5 BEFORE. Amendment 10 stretched it because the slow motion GDD 3.4
    # describes could not be built, and said it should come back towards 3 if a
    # substitute was ever found. One was, and 2026-08-18 restored the 3: hostiles
    # are slowed and the contestant sped up for the window, which delivers the
    # relative effect the slow motion existed for. See HostileSlowMultiplier.
    #
    # SO WHY 5 AGAIN. That substitute is real but it is not slow motion, and 3
    # seconds of it has now been played a great many times. Kai is the one doing
    # the playing. A Death Save nobody can reach is a cutscene about dying rather
    # than a chance to live, and GDD 3.4 wants the window to be winnable.
    @editable
    CountdownSeconds : float = 5.0

    # THE HYPE CALL KEY AND THE HYPE METER, for GDD 3.4's rescue teleport.
    # Amendment 133. Point the input at the SAME placed Input Trigger the Hype
    # Meter uses, and drag the placed Hype Meter device into the other slot.
    #
    # BOTH LIVE ON THIS SIDE BECAUSE OF THE VERSE LINKER. The first build put a
    # death_save_manager field on HypeMeterManager instead, which was the tidier
    # split, and the linker refused it as a cycle: hype meter to death save to
    # game over screen to cash drop manager and back to the hype meter, script
    # error 9000. The hype meter references no other class in the project and is
    # referenced by several, so the reference has to run this way round.
    #
    # LEAVE EITHER SLOT EMPTY AND THE RESCUE SIMPLY NEVER FIRES. The manual run
    # is untouched by any of this and still spawns its med kit always.
    @editable
    HypeCallInput : input_trigger_device = input_trigger_device{}

    @editable
    HypeMeter : hype_meter_manager = hype_meter_manager{}

    # THE WORDS ON THE GREY SCREEN. Kai asked the question that matters:
    # "do i need to build a screen to show it or something, how will the
    # audience know?" They would not have. The window's overlay was a coloured
    # wash and nothing else, so a contestant had no way of learning the key does
    # anything, and a rescue nobody presses is a rescue that does not exist.
    #
    # THE ODDS ARE ON IT ON PURPOSE. They are the only place in the game where
    # the Hype meter's tier is quoted at the contestant as a number, and seeing
    # 35% one death and 80% the next is what teaches the meter's whole point
    # faster than any explanation would.
    #
    # THE WORDING IS AN @editable BECAUSE IT IS THE SHOW'S VOICE, and that is
    # Kai's. This is HUD text rather than a commentator line, so standing rule 3
    # does not forbid a default, but the default is a placeholder to be rewritten
    # rather than the finished article.
    # Whether the grey wash is drawn at all, on top of the screen filter that is
    # already desaturating everything. See the note beside its opacity.
    @editable
    DimTheScreen : logic = true

    @editable
    ShowRescuePrompt : logic = true

    # HOW LONG EACH HALF OF A BLINK LASTS, in seconds. Kai's ruling, 2026-09-07:
    # the prompt should "flash on the screen near the top with lights" and not
    # cover the arena.
    #
    # WHY IT BLINKS AT ALL. Three seconds is no time to notice a new line of
    # text, and a contestant in this moment is looking at robots rather than
    # reading. Something that moves is seen; something that sits still is not.
    #
    # WHY IT IS UP TOP. It used to sit at three quarters down the screen, over
    # the floor the contestant is hunting a turkey leg on. The top strip is
    # where the show's own furniture already lives, so words there read as part
    # of the broadcast rather than as something in the way.
    @editable
    RescueFlashSeconds : float = 0.22

    # HOW FAR DOWN THE SCREEN THE PROMPT SITS, as a fraction. The odds line goes
    # RescueOddsGap below it.
    #
    # 0.10 -> 0.18 ON 2026-09-07. Kai: "the announcer text is covering it." It
    # was: the announcer's banner runs from 0.045 to 0.135, which the first
    # placement sat squarely inside. 0.18 clears it by a comfortable margin and
    # is still the top strip rather than the arena floor, which is what put the
    # prompt up here in the first place.
    #
    # Kai suggested the bottom instead, and the bottom is where the Hype meter's
    # own column and the chat lane already are. Below the banner keeps all the
    # broadcast furniture in one band.
    @editable
    RescuePromptY : float = 0.18

    @editable
    RescueOddsGap : float = 0.055

    # KAI'S OWN BRIEF, 2026-09-07: "it should say something like, are you stuck
    # or crowded, beg for a sponsor to save you, press shift. wordsmith it."
    # SURROUNDED does the work of both "stuck" and "crowded" in one word, which
    # matters on a line that has to be read in three seconds while being chased.
    # BEG is Kai's and stays: it is the joke, and a contestant asking politely is
    # not this show.
    #
    # NAME THE KEY, NOT THE ACTION. The first version said "PRESS HYPE CALL",
    # which is what the thing is called in this project and means nothing to
    # anyone who has not read the design document. Kai spotted it at once: the
    # words "dont make sense". Shift is the key, confirmed by Kai on 2026-09-07,
    # and it is free because sprinting is off in Island Settings.
    #
    # IF THE BINDING EVER CHANGES, THIS LINE HAS TO CHANGE WITH IT. Verse cannot
    # ask an Input Trigger which key it ended up on, and a player can rebind it
    # in Fortnite's own settings, so a typed key name is the best there is.
    @editable
    RescuePromptLine : string = "SURROUNDED? PRESS SHIFT AND BEG FOR A SPONSOR"

    # The odds, read as a sentence rather than a bare number. "THEY ARE 35%
    # INTERESTED" says what the percentage is OF, which "35% CHANCE" did not.
    # WHAT THE SCREEN SAYS WHEN THE SPONSORS PASS. Kai, 2026-09-07, in capitals:
    # "I WAS PRESSING SHIFT AND NOTHING HAPPENED."
    #
    # THEY WERE, AND IT WAS WORKING. The log has three presses in one window
    # rolling 0.71, 0.68 and 0.84 against a 0.35 chance, all refusals. A refusal
    # did nothing at all on screen, so a working feature and a broken one looked
    # identical from the floor.
    #
    # REWORDED ON KAI'S NOTE, same evening: "its a med kit, and usually if they
    # cant teleport they are stuck and they die." Both halves matter. The item
    # is a med kit and the line called it a leg, and the first version read as
    # helpful advice for a situation where there is usually no advice to give.
    # A contestant who was surrounded enough to need a teleport is still
    # surrounded. So the line shrugs rather than instructs, which is also the
    # only tone this show has for a contestant nobody wants to sponsor.
    #
    # KAI'S OWN LINE, and it points at the right thing. The med kit was never
    # the problem; the robots standing on the contestant are. It names the
    # Swarmers specifically, which is exactly true in the first room of every
    # lap and loosely true after that, and the joke is worth more than the
    # precision. If a contestant cornered by a Tank ever reads wrong, "THEY ARE
    # YOUR PROBLEM NOW" covers every type.
    @editable
    RescueFailedLine : string = "NO TAKERS. THE SWARMERS ARE YOUR PROBLEM NOW."

    # WHAT THE SCREEN SAYS WHEN THE SPONSORS BITE. Amendment 147, Kai's ask
    # 2026-09-08: "if i do get it it should say congrats, they took pity on you,
    # teleport granted or soemthing liek that word smith it".
    #
    # THE REFUSAL HAD WORDS AND THE SUCCESS DID NOT. A granted rescue teleported
    # the contestant and spawned the med kit and said nothing at all, so the two
    # outcomes were told in completely different languages: one explained
    # itself, the other just happened.
    #
    # KAI'S OWN WORDS, TIGHTENED. "Pity" and "teleport granted" are both Kai's
    # and both stay. "Congrats" went because this network does not congratulate
    # anybody, and the backhand is the joke: you were not rescued because you
    # were good, you were rescued because somebody felt sorry for you.
    #
    # Wording, not dialogue, the same as the two lines above it. The host's own
    # line for this moment is Kai's to write and is not here.
    @editable
    RescueGrantedLine : string = "A SPONSOR TOOK PITY ON YOU. TELEPORT GRANTED."

    @editable
    RescueChancePrefix : string = "THEY ARE "

    @editable
    RescueChanceSuffix : string = "% INTERESTED"

    # GDD 3.4'S RESCUE ODDS, by tier: "35% at Underdog, 50% at Rising Star, and
    # 65% at Superstar."
    #
    # THE FOURTH NUMBER IS NOT THE GDD'S. Prime Time was added by amendment 24,
    # after 3.4 was written, so the document has nothing to say about it. 0.80
    # continues the document's own steps of fifteen and keeps the best tier
    # better than the one below it. That is Claude's figure on Kai's standing
    # delegation of calls like this, not a ruling, and one number changes it.
    @editable
    RescueChanceByTier : []float = array{0.35, 0.50, 0.65, 0.80}

    # HOW FAR THE RESCUE TELEPORT THROWS THE CONTESTANT, in centimetres, and how
    # many directions it will try before giving up. GDD 3.4's Hype Call rescue,
    # built 2026-09-07 on Kai's ruling, amendment 133.
    #
    # KAI ASKED FOR IT BY DESCRIBING THE PROBLEM: "you can get stuck with the
    # swarm and they get all around you." A rescue that heals you where you
    # stand does not answer that; being surrounded is the thing being escaped.
    # So this is a real teleport and the distance is the whole of its value.
    #
    # EIGHT METRES BREAKS AN ENCIRCLEMENT without crossing the room. The arena
    # is wider than that in both directions, so the landing spot is still in the
    # fight rather than parked in a corner.
    @editable
    RescueThrowDistance : float = 800.0

    # KEPT AND NO LONGER READ. The rescue walks all eight compass points now,
    # so the count is the table's length rather than a number that could
    # disagree with it. Left in place so the placed device does not lose a saved
    # value.
    @editable
    RescueDirectionsToTry : int = 8

    # How far away the med kit lands, in centimetres. GDD 3.4 says "within
    # easy walking distance", so how far is our choice, not the document's.
    #
    # 300 rather than 600, from playtest. At 600 the three seconds felt rushed:
    # the leg landed outside the eye's reach from a locked overhead camera and
    # the player spent the window hunting rather than running. Shortening the
    # distance fixes that without touching the 3 seconds, which GDD 3.4 fixes.
    @editable
    SpawnDistance : float = 300.0

    # How close to a wall counts as "near it" for the rule above. Comfortably
    # more than SpawnDistance, so a throw is turned around before it can reach
    # the wall rather than after.
    @editable
    NearWallMargin : float = 600.0

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

    # What the contestant's health is held at through the window. Comfortably
    # more than several hits, because the point is that nothing can kill them
    # inside the three seconds. See HoldAliveFor for why this replaced leaning
    # on the shield.
    @editable
    WindowHoldHealth : float = 150.0

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

    # =================================================================
    # THE HEALING-OVER-TIME DIALS. See the block in WatchOneRun for why this
    # lives in Verse rather than in Island Settings.
    # =================================================================

    @editable
    RechargeEnabled : logic = true

    # Seconds clear of being hit before healing starts.
    @editable
    RechargeDelaySeconds : float = 5.0

    # How often a point is handed back, and how much.
    @editable
    RechargeEverySeconds : float = 1.0

    # 2 A SECOND. Kai halved this to 1 earlier on 2026-09-05 and then reopened
    # it the same evening on the right grounds: "can the healing be maybe 2
    # instead of 1 since i have 300 health."
    #
    # THE MAXIMUM IS WHAT MAKES THE ANSWER. Against a 300 pool and 25 point
    # hits, 2 a second means fifteen seconds clear of the crowd buys back less
    # than one hit. Measured on the 23:33 run: 37 points healed at 1 against 225
    # damage taken, so 74 at 2, a third of the punishment and not a rescue.
    @editable
    RechargePerTick : float = 2.0

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
    # 1250, PROVEN BY THE SPAWNERS THEMSELVES, 2026-09-05. The probe printed
    # where all four sit and they are at the four walls: Swarmer X -1672,
    # Boar X 1744, Sentinel Y 1241, Tank Y -1220. That matches the robot pile-ups
    # exactly and settles an argument that ran all afternoon. The 2600 of an hour
    # earlier came from reading a gate actor as Y -2560, which nothing else in
    # the game agrees with.
    ArenaHalfWidth : float = 1250.0

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

        # GDD 3.4'S RESCUE KEY. The same placed Input Trigger the Hype Meter
        # listens to; two subscribers on one device is fine, and each ignores
        # the presses that are not its business. See HypeCallInput.
        HypeCallInput.ReleasedEvent.Subscribe(OnHypeCallForRescue)

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
        set FatalBlowSeen = false
        set GuardedCharacter = false

        # Set the first time a Death Save is granted and NEVER cleared inside a
        # run. This is GDD 3.4's "once per life". See WatchPlayer above for what
        # a restart does to it, and the field itself for why it is not a local.
        set SaveSpent = false

        # So a player eliminated outright can be told apart from one who simply
        # has not spawned yet.
        var HasBeenAlive : logic = false

        # The health seen on the previous check, so a drop can be spotted.
        # 0.0 means nothing has been read yet.
        var LastHealth : float = 0.0

        # THE RECHARGE'S OWN READING, kept apart from LastHealth above so the
        # two can never fight over who saw what. LastHealth belongs to the log.
        var RechargeLastHealth : float = 0.0

        # Seconds since the contestant was last hurt, and seconds since the last
        # point of health was handed back.
        var SecondsSinceHit : float = 0.0
        var SecondsSinceHeal : float = 0.0

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
                # SUBSCRIBED ONCE, the first look this character is alive for.
                # A respawn makes a new character, and the run restarting is
                # what clears the flag, so this cannot stack.
                if (not HasBeenAlive?):
                    set GuardedCharacter = option{Character}
                    Character.DamagedEvent().Subscribe(OnContestantDamaged)
                    Log("DEBUG: Death Save -- watching the contestant's damage directly, trigger at {TriggerHealth} health.")

                set HasBeenAlive = true

                if (LogHits?):
                    Now := Character.GetHealth()
                    # A drop is a hit, because nothing else in the arena hurts
                    # the contestant.
                    if (LastHealth > 0.0, Now < LastHealth):
                        Log("DEBUG: Death Save -- took {LastHealth - Now} damage, now on {Now} health")

                    # A RISE IS REPORTED TOO, ADDED 2026-09-05. It used to be
                    # skipped as "a heal, a rescue or a fresh spawn, none of
                    # which is a hit", and that silence is exactly what made the
                    # health recharge impossible to check: Kai says the Island
                    # Settings switch is on, the 17:08 run healed and the 22:42
                    # run did not, and nothing in any log could tell us which
                    # was true because healing was never written down.
                    #
                    # A MEASUREMENT THAT ONLY RECORDS ONE DIRECTION CANNOT
                    # SETTLE AN ARGUMENT ABOUT THE OTHER. Same lesson as
                    # amendment 111.
                    if (LastHealth > 0.0, Now > LastHealth):
                        Log("DEBUG: Death Save -- healed {Now - LastHealth}, now on {Now} health")

                    set LastHealth = Now

                # =================================================================
                # HEALING OVER TIME, DONE HERE BECAUSE THE ENGINE WOULD NOT.
                #
                # KAI'S RULING, 2026-09-05. Kai kept dying eleven hits into every
                # run with no way back, so Island Settings' Health Recharge was
                # switched on: Delay 5, Period 1, Amount 2. It never healed a
                # single point. Kai confirmed all three values twice and the
                # switch was on, and with heals finally being written to the log
                # the 22:57 run showed only two heals in the whole run, both of
                # them items. Why the engine ignores it is still unknown.
                #
                # So it is done here instead, to the same three numbers, where it
                # cannot be silently ignored and every tick shows up in the log
                # as a rise.
                #
                # THE DELAY IS WHAT MAKES IT A GAME RATHER THAN A GIFT. Nothing
                # heals mid-brawl. Five seconds clear of the crowd is the price,
                # which is what makes GDD 2.2's kiting the way out of trouble
                # rather than a stylistic choice. It also keeps healing out of
                # the three second Death Save window, which sits well inside it.
                #
                # ONE POINT A SECOND RATHER THAN A TRICKLE EVERY POLL. The poll
                # runs twenty times a second and healing 0.1 each time would
                # bury the log and hammer SetHealth for nothing.
                #
                # SetHealth CLAMPS AT THE MAXIMUM (Fortnite digest 8546), so
                # overshooting the top is safe, but full health is checked anyway
                # so a contestant standing at full is not written to forever.
                if (RechargeEnabled?):
                    Health := Character.GetHealth()
                    Most := Character.GetMaxHealth()

                    if (RechargeLastHealth > 0.0, Health < RechargeLastHealth):
                        set SecondsSinceHit = 0.0
                        set SecondsSinceHeal = 0.0
                    else:
                        set SecondsSinceHit = SecondsSinceHit + PollSeconds

                    if (SecondsSinceHit >= RechargeDelaySeconds, Health < Most, Health > 0.0):
                        set SecondsSinceHeal = SecondsSinceHeal + PollSeconds
                        if (SecondsSinceHeal >= RechargeEverySeconds):
                            set SecondsSinceHeal = 0.0
                            Character.SetHealth(Health + RechargePerTick)

                    set RechargeLastHealth = Character.GetHealth()

                # THE TRIGGER ONLY MATTERS WHILE THE SAVE IS STILL THERE.
                # Amendment 127, Kai's ruling of 2026-09-07. Once it is spent
                # this branch does nothing at all, the contestant fights on with
                # whatever health is left, and the run ends when the bar is
                # genuinely empty. See the header for why.
                if (not SaveSpent?):
                    if (FatalBlowSeen? or Character.GetHealth() <= TriggerHealth):
                        set FatalBlowSeen = false
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
                        #
                        # AND SINCE AMENDMENT 127 THIS IS THE ORDINARY WAY A RUN
                        # ENDS, not only the freak case it was written for. Once
                        # the save is spent nothing catches a fatal blow any
                        # more, so the contestant is eliminated and arrives
                        # here. A run ending with the save still in hand is
                        # still the freak case: a single blow bigger than the
                        # whole remaining health bar.
                        Log("DEBUG: Death Save -- health reached zero and the contestant was eliminated. Ending the run.")
                        EndRunAfterOutrightKill(TargetPlayer)

    # THE KEY, HEARD WHILE THE WINDOW IS OPEN AND IGNORED EVERY OTHER TIME.
    #
    # THE COOLDOWN IS NOT CONSULTED, and GDD 3.4 is why: "Taking a fatal blow
    # instantly resets the player's Hype Call cooldown." Never asking comes to
    # the same thing as resetting it, and leaves whatever cooldown the
    # contestant had before the blow still running when they walk away.
    #
    # THE TIER IS READ AT THE PRESS rather than at the blow. A contestant on
    # Superstar when they were hit is on Superstar a second later, since nothing
    # drains fast enough to cross a line inside three seconds, and asking the
    # meter keeps one source of truth for where the lines are.
    #
    # A FAILED ROLL COSTS THE PRESS AND NOTHING ELSE. 3.4 is explicit that the
    # walk-to-it med kit spawns "always, whether or not the Hype Call was used or
    # succeeded", so the run to the turkey leg is still there.
    OnHypeCallForRescue(Payload : tuple(agent, float)):void =
        # SAID BEFORE ANY GUARD CAN SWALLOW IT. Amendment 147a. Kai, 2026-09-08:
        # "hweni pressed shift nothing happened i didnt see the no takers
        # thing". Both outcomes of a working rescue put words on the screen, so
        # silence means the roll never happened, and there were exactly two
        # candidates: the key never reached this device, or a guard below
        # returned without a word. This line tells the two apart in one run.
        # A `logic` CANNOT GO INSIDE A STRING. There is no ToString for it, so
        # `{WindowOpen}` is a compile error rather than the "false" it looks
        # like. The if/else expression is the house way round it, the same shape
        # AnnouncerManager uses to pick a bark.
        OpenNow := if (WindowOpen?) then "yes" else "no"
        AskedNow := if (RescueRolled?) then "yes" else "no"
        Log("DEBUG: Hype Call rescue -- key released, window open {OpenNow}, already asked {AskedNow}.")

        if (not WindowOpen?):
            Log("DEBUG: Hype Call rescue -- ignored, the Death Save window is not open.")
            return

        # See RescueRolled. Asked once, answered once.
        if (RescueRolled?):
            Log("DEBUG: Hype Call rescue -- already asked this window. The sponsors do not answer twice.")
            return

        # A PLAIN set, NOT AN if. Setting a logic cannot fail, so wrapping it in
        # an if is script error 3513, "expected an expression that can fail in
        # the if condition clause". A map set CAN fail, which is why the same
        # shape is correct a few lines away and wrong here.
        set RescueRolled = true
        Log("DEBUG: Hype Call rescue -- the ask is in.")

        Tier := HypeMeter.GetTier()
        Chance := RescueChanceNow()

        Roll := GetRandomFloat(0.0, 1.0)
        if (Roll < Chance):
            Log("DEBUG: HYPE CALL RESCUE -- rolled {Roll} against {Chance} at tier {Tier}. Saved.")
            ShowRescued()
            GrantHypeRescue()
        else:
            Log("DEBUG: Hype Call rescue FAILED -- rolled {Roll} against {Chance} at tier {Tier}. The turkey leg is still out there.")
            ShowRefusal()

    # THE SCREEN HAS TO SAY NO. See RescueFailedLine. The prompt becomes the
    # refusal and the odds line goes, so the contestant knows the ask landed and
    # knows to start running. The blink carries on, because a line that has just
    # changed under you is the one thing worth looking at.
    ShowRefusal():void =
        if (Call := RescueCall?):
            Call.SetText(ScreenLine(RescueFailedLine))
            Call.SetTextColor(NamedColors.Red)
        if (Odds := RescueOdds?):
            Odds.SetVisibility(widget_visibility.Hidden)

    # AND THE SCREEN HAS TO SAY YES. Amendment 147. The exact mirror of
    # ShowRefusal: the prompt becomes the answer and the odds go, because the
    # odds are a question and the question has been settled.
    #
    # GREEN, WHERE THE REFUSAL IS RED. The contestant has about a second to read
    # it before the grey lifts and the arena comes back, so colour carries the
    # meaning and the words confirm it.
    ShowRescued():void =
        if (Call := RescueCall?):
            Call.SetText(ScreenLine(RescueGrantedLine))
            Call.SetTextColor(NamedColors.Green)
        if (Odds := RescueOdds?):
            Odds.SetVisibility(widget_visibility.Hidden)

    # What a rescue would pay right now, 0 to 1. Read by the roll and by the
    # words on the overlay, so the number the contestant is shown is the number
    # they are actually playing against.
    RescueChanceNow()<transacts>:float =
        var Chance : float = 0.0
        if (Found := RescueChanceByTier[HypeMeter.GetTier()]):
            set Chance = Found
        Chance

    # GDD 3.4'S RESCUE TELEPORT, the half of the Death Save that has never
    # existed. Amendment 133, Kai's ruling of 2026-09-07.
    #
    # 3.4: "Pressing the key initiates a Hype-scaled rescue teleport... On
    # success, a Sponsor Aid item spawns directly at the player's feet."
    #
    # THE ROLL IS IN OnHypeCallForRescue ABOVE, and the tier it scales by is
    # asked of the Hype Meter, which owns where the lines are. This function is
    # only ever reached on a success.
    #
    # IT REALLY MOVES THEM, and Kai asked for it in those terms: "you can get
    # stuck with the swarm and they get all around you." A rescue that heals a
    # contestant where they stand leaves them exactly as surrounded as they
    # were. The throw is what makes it a rescue rather than a heal.
    #
    # THE AID STILL ARRIVES EITHER WAY, and 3.4 is explicit that the walk-to-it
    # med kit spawns "always", success or not. This one lands at the contestant's
    # feet after the throw, so it is picked up on the spot and the window ends
    # the same way it would have if they had run to the other one.
    GrantHypeRescue<public>():void =
        if (P := TargetPlayerNow()?, Character := P.GetFortCharacter[], Character.IsActive[]):
            Standing := Character.GetTransform().Translation

            # EIGHT COMPASS POINTS RATHER THAN AN ANGLE. No trigonometry is
            # needed for eight fixed directions, and a table cannot be off by a
            # factor of pi. The first one tried is random, so a contestant
            # rescued twice in a run is not thrown the same way twice.
            Ways := RescueDirections()
            Start := GetRandomInt(0, Ways.Length - 1)

            var Landed : logic = false
            for (Step := 0..Ways.Length - 1, not Landed?):
                var Pick : int = Start + Step
                if (Pick >= Ways.Length):
                    set Pick = Pick - Ways.Length

                if (Way := Ways[Pick]):
                    Away := vector3:
                        X := HeldInsideArena(Standing.X + RescueThrowDistance * Way.X, ArenaHalfLength - AidWallInset)
                        Y := HeldInsideArena(Standing.Y + RescueThrowDistance * Way.Y, ArenaHalfWidth - AidWallInset)
                        Z := Standing.Z

                    if (Character.TeleportTo[Away, IdentityRotation()]):
                        set Landed = true
                        Log("DEBUG: Death Save -- HYPE CALL RESCUE. Contestant thrown from X={Standing.X} Y={Standing.Y} to X={Away.X} Y={Away.Y}.")

            if (not Landed?):
                Log("WARNING: Death Save -- the Hype Call rescue found no clear spot in any direction. The contestant stays put and still gets the med kit.")

            # AND THE MED KIT AT THEIR FEET, wherever their feet now are.
            Feet := Character.GetTransform().Translation
            if (SponsorAidSpawner.TeleportTo[Feet, IdentityRotation()]):
                SponsorAidSpawner.Enable()
                SponsorAidSpawner.SpawnItem()
                Log("DEBUG: Death Save -- rescue med kit dropped at the contestant's feet, X={Feet.X} Y={Feet.Y}.")
            else:
                Log("WARNING: Death Save -- the rescue med kit spawner would not move to the contestant's feet.")

    # The eight ways a rescue can throw a contestant, as unit steps. The
    # diagonals use 0.7071 so a diagonal throw covers the same ground as a
    # straight one rather than half again as much.
    RescueDirections()<transacts>:[]vector2 =
        array:
            vector2{X := 1.0, Y := 0.0}
            vector2{X := 0.7071, Y := 0.7071}
            vector2{X := 0.0, Y := 1.0}
            vector2{X := -0.7071, Y := 0.7071}
            vector2{X := -1.0, Y := 0.0}
            vector2{X := -0.7071, Y := -0.7071}
            vector2{X := 0.0, Y := -1.0}
            vector2{X := 0.7071, Y := -0.7071}

    # Holds one coordinate inside the arena. The aid drop has its own version of
    # this shape; this one is a plain clamp because the rescue has already
    # chosen its direction.
    HeldInsideArena(Value : float, Limit : float)<transacts>:float =
        var Held : float = Value
        if (Held > Limit):
            set Held = Limit
        if (Held < -Limit):
            set Held = -Limit
        Held

    # The contestant, for the rescue above. The window only ever runs for one.
    TargetPlayerNow()<transacts>:?player =
        if (First := GetPlayspace().GetPlayers()[0]):
            return option{First}
        false

    # The 3-second window itself. Returns true if the player was saved.
    RunDeathSave(TargetPlayer : player, Character : fort_character)<suspends>:logic =
        set WindowOpen = true
        set RescueRolled = false

        # THE KEY IS THE RESCUE'S FOR THESE THREE SECONDS, and the contestant's
        # ordinary Hype Call is left exactly as it was: same cooldown, ready
        # again the moment they get up. See HypeMeterManager.HypeCallSuspended.
        HypeMeter.SetHypeCallSuspended(true)

        Log("DEBUG: Death Save -- FATAL BLOW. Window opening for {CountdownSeconds}s. This is the only save this run.")

        # Hold them alive. SetHealth clamps to a minimum of 1.0, so this cannot
        # accidentally finish them off.
        # HELD AT WindowHoldHealth, NOT AT 1. Pinning the contestant on one
        # point of health was the drama GDD 3.4 describes and it is also what
        # made the window lethal: a single hit inside it finished them. Kai:
        # "i need to be invincible for those 3 seconds."
        Character.SetHealth(WindowHoldHealth)

        # Whatever shield the player already had, so a Sponsor Aegis that was up
        # when the blow landed is put back afterwards rather than eaten by the
        # window's own shield.
        PriorShield := Character.GetShield()
        Character.SetShield(WindowShieldPoints)

        # Amendment 68 replaces GDD 3.4's grayscale with a CCTV filter. The field
        # is still called GrayscaleEffect so the placed device stays wired; only
        # what that device is set to has changed.
        # AND SAY WHETHER IT ACTUALLY ARRIVES. Added 2026-09-05 after Kai
        # changed the device to PP_FilmNoir, confirmed the change reached the
        # session, and still saw no black and white. Nothing in this file could
        # tell us whether the effect blended in at all.
        #
        # The device already publishes BlendingInCompleteEvent and it is wired
        # on the placed device; nothing had ever subscribed to it. If the line
        # below never prints, the device is not applying the effect and the
        # answer is one of its own settings, Enabled During Phase first. If it
        # does print and the screen still looks the same, the effect is arriving
        # and being drowned, most likely by the VHS filter that runs all match.
        GrayscaleEffect.BlendingInCompleteEvent.Subscribe(OnDeathSaveFilterIn)

        # ENABLED FIRST, WHICH THIS NEVER DID. The digest gives the device its
        # own Enable(Agent), separate from the Enabled During Phase setting Kai
        # has already confirmed is Always. A disabled device ignores BlendIn
        # silently, which fits what the log shows: the blend-in event has never
        # once fired.
        GrayscaleEffect.Enable(TargetPlayer)
        ShowOverlay(TargetPlayer)
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
            # WHERE THE CONTESTANT WAS, TOO, AND HOW FAR IT LANDED FROM THEM.
            # Added 2026-09-05 after Kai reported the med kit "fell out of
            # arena" and the one coordinate this line printed could not settle
            # it. The walls read off the UEFN panel and the positions the game
            # reports have disagreed all day, so this prints the two things that
            # are in the SAME coordinates as each other: where the contestant
            # stood and where the leg went, with the gap between them measured
            # rather than assumed.
            Gap := Distance(vector3{X := PlayerLocation.X, Y := PlayerLocation.Y, Z := 0.0}, vector3{X := DropLocation.X, Y := DropLocation.Y, Z := 0.0})
            Log("DEBUG: Death Save -- med kit out at X={DropLocation.X} Y={DropLocation.Y} Z={DropLocation.Z}. Contestant stood at X={PlayerLocation.X} Y={PlayerLocation.Y} Z={PlayerLocation.Z}. That is {Gap} away, and the pickup radius is {PickupRadius}.")

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
        set WindowOpen = false
        HypeMeter.SetHypeCallSuspended(false)
        GrayscaleEffect.BlendOut(TargetPlayer)
        HideOverlay(TargetPlayer)
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
                # HEALTH IS WHAT KEEPS THEM STANDING NOW, NOT THE SHIELD.
                # KAI'S RULING, 2026-09-05: "i need to be invincible for those 3
                # seconds, remember, and i died so fast."
                #
                # THE SHIELD WAS THE ONLY PROTECTION AND IT CAN BE WORTH NOTHING.
                # SetShield is documented as clamping to MaxShield, and MaxShield
                # is an Island Settings value. If shields are switched off in
                # this island, topping one up twenty times a second sets it to
                # zero twenty times a second, and every hit lands on the 1 health
                # the contestant is pinned at. That is a rescue window that kills
                # you, and it looked like nothing was happening at all.
                #
                # SO THE HOLD IS A HEALTH FLOOR, which depends on no setting
                # outside this file. At WindowHoldHealth against a 25 point hit
                # and a poll every 0.05s, nothing can take the contestant down
                # inside the window.
                #
                # THEY ARE STILL DOOMED IF THEY DO NOT REACH THE LEG. The window
                # ending unsaved calls EndRun, which does not ask how much health
                # they have. This buys the three seconds GDD 3.4 promises and
                # nothing beyond them.
                Character.SetHealth(WindowHoldHealth)

                # Still topped up, because it costs nothing and it is real
                # protection wherever shields ARE switched on.
                Character.SetShield(WindowShieldPoints)

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
    # A spot SpawnDistance away, on the floor, thrown AWAY from any wall the
    # contestant is standing near.
    #
    # KAI'S RULING, 2026-09-05: "if im too close to the walls or the corner it
    # changes, like if im too close to the left wall it will spawn 3m to the
    # right and vice versa for the right wall."
    #
    # WHAT THIS REPLACES AND WHY. The old version threw at a random angle, and if
    # that would clear a wall it re-threw straight at the middle of the arena.
    # Two things wrong with that. In a corner, the line to the middle runs along
    # the diagonal and can still clip the wall it came from. And it assumes the
    # room is centred on the origin, which is exactly the assumption that has
    # been in dispute all day.
    #
    # KAI'S RULE NEEDS NEITHER. It only asks which wall you are near, and flips
    # the throw on that axis alone. Near the left wall, the X part of the throw
    # goes right. Near the top, the Y part goes down. In a corner both flip and
    # it comes out diagonally inward without anything having to know where the
    # middle is.
    #
    # FLIPPING A SIGN KEEPS THE DISTANCE. The direction is a unit vector, and
    # negating one part of it leaves it a unit vector, so the leg still lands
    # exactly SpawnDistance away whichever way it ends up pointing. Rebuilding
    # the direction instead would have changed how far it was thrown.
    WalkingDistanceLocation(PlayerLocation : vector3)<transacts>:vector3 =
        Angle := GetRandomFloat(0.0, FullCircleRadians)
        var DirX : float = Cos(Angle)
        var DirY : float = Sin(Angle)

        # The furthest out the leg is ever allowed to land.
        Edge := ArenaHalfLength - AidWallInset
        Side := ArenaHalfWidth - AidWallInset

        # Near the far X wall and pointing at it, so point the other way.
        if (PlayerLocation.X > Edge - NearWallMargin, DirX > 0.0):
            set DirX = -DirX
        if (PlayerLocation.X < -(Edge - NearWallMargin), DirX < 0.0):
            set DirX = -DirX

        if (PlayerLocation.Y > Side - NearWallMargin, DirY > 0.0):
            set DirY = -DirY
        if (PlayerLocation.Y < -(Side - NearWallMargin), DirY < 0.0):
            set DirY = -DirY

        # Held inside as a backstop. With the flips above this should never do
        # anything, and it stays because a backstop that never fires costs
        # nothing and the one time it does is the time it was needed.
        vector3:
            X := HeldInside(PlayerLocation.X + DirX * SpawnDistance, Edge)
            Y := HeldInside(PlayerLocation.Y + DirY * SpawnDistance, Side)
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
    # THE PAYLOAD IS AN OPTIONAL AGENT, NOT AN AGENT. Script error 3509 named it
    # exactly: the event hands back `?agent`, because a post process effect can
    # finish blending in for everybody rather than for one player.
    # =================================================================
    # THE BLOW IS CAUGHT THE INSTANT IT LANDS, NOT ON THE NEXT LOOK.
    #
    # KAI'S RULING, 2026-09-05: "but then its really not a death save if its at
    # 100 right? why cant i be invincible when im at 25?"
    #
    # Kai was right and the proposal to raise the trigger to 100 was wrong. The
    # trigger stays at 25. The fault was never the number, it was how often it
    # was looked at.
    #
    # WHAT THE LOG SHOWED. The contestant went 50, then "killed outright, the
    # blow exceeded the remaining health". Two hits landed inside the same
    # twentieth of a second, so health went from 50 past 25 to gone, and a loop
    # checking every PollSeconds never saw a number it could act on. Raising the
    # trigger would only have moved where that gap sits.
    #
    # SO IT DOES NOT WAIT AND LOOK. `damageable` publishes DamagedEvent and
    # fort_character implements it, so the game says so the moment a hit lands.
    # The handler pushes health straight back up, which is what stops the SECOND
    # hit of a burst arriving on a contestant who has nothing left, and raises a
    # flag for the loop to open the window on.
    #
    # THE LOOP STILL CHECKS HEALTH AS WELL, as a fallback for anything that
    # drains a contestant without going through damage.
    # =================================================================

    # WHETHER THE THREE-SECOND WINDOW IS OPEN RIGHT NOW. Read by
    # HypeMeterManager, which owns the Hype Call key and therefore owns the
    # press that GDD 3.4 turns into a rescue. This file owns what a rescue
    # actually does; the split is the same one the crate handoff uses.
    var WindowOpen : logic = false

    # The two lines of the rescue prompt, held so they can be blinked, and a
    # token so a blink from a previous window abandons itself rather than
    # fighting the current one. The same trick the announcer's banner uses.
    var RescueCall : ?text_block = false
    var RescueOdds : ?text_block = false
    var PromptToken : int = 0

    # ONE ROLL PER WINDOW. GDD 3.4 describes pressing the key, singular, and the
    # odds only mean anything if they are asked once. Three presses at 35% is
    # really a 73% rescue, which is the Superstar rate handed out at the bottom
    # tier for mashing a key. Kai's three presses in one window are what found
    # this, in the same breath as the missing feedback.
    var RescueRolled : logic = false

    IsWindowOpen<public>()<transacts>:logic = WindowOpen

    var FatalBlowSeen : logic = false

    # TRUE ONCE THIS RUN'S ONE DEATH SAVE HAS BEEN USED. A field rather than a
    # local, because the damage handler below has to read it too: the moment the
    # save is gone, nothing may hold the contestant up any more. Cleared at the
    # top of every run by WatchOneRun, exactly as FatalBlowSeen is.
    var SaveSpent : logic = false

    var GuardedCharacter : ?fort_character = false

    # THE HOLD-UP IS PART OF THE SAVE, SO IT GOES WHEN THE SAVE DOES. Amendment
    # 127. This is what stops the second hit of a burst landing on a contestant
    # with nothing left, and it costs 25 points of the health bar to do it. Kai
    # watched a run end on 2026-09-07 with health still showing and called it
    # unfair, so once SaveSpent is true nothing is caught and nothing is
    # propped up: the last 25 points are the contestant's to spend, and a hard
    # hit can take them from a sliver straight to eliminated.
    OnContestantDamaged(Result : damage_result):void =
        if (Character := GuardedCharacter?, Character.IsActive[], not FatalBlowSeen?, not SaveSpent?):
            if (Character.GetHealth() <= TriggerHealth):
                set FatalBlowSeen = true
                Character.SetHealth(WindowHoldHealth)
                Log("DEBUG: Death Save -- fatal blow caught by the damage event, on {Character.GetHealth()} health. Held up before the next hit could land.")

    ShowOverlay(P : player):void =
        if (ShowDeathSaveOverlay?):
            Wash := color_block:
                DefaultColor := OverlayColour
                # A LITERAL, NOT A SETTING, AND TWO ERRORS SAY WHY.
                # DefaultOpacity wants a number Verse can PROVE sits between 0
                # and 1, which an @editable float cannot carry (error 3509).
                # GameOverScreen solves that with a Clamped helper returning
                # unit_float, and copying it here gave error 3502, "can't access
                # a type alias from a preceding expression", because that alias
                # is not in scope this far down a class body.
                #
                # Not worth a third build to chase. Change the number here to
                # make the wash heavier or lighter.
                #
                # 0.55 -> 0.2 ON 2026-09-07. Kai: "i think the gray is messing me
                # up because i cant see." Two layers cover the screen during
                # those three seconds and only one of them is the GDD's: 3.4 asks
                # for desaturation and the post process device does that on its
                # own, as a CCTV filter since amendment 68. This wash sat over
                # the top of it at more than half opacity, and between the two
                # the contestant could not see the arena they have three seconds
                # to cross. A window you cannot see through defeats its own
                # purpose. It is a tint now, and DimTheScreen turns it off
                # entirely if the filter reads better alone.
                DefaultOpacity := 0.2

            if (not DimTheScreen?):
                Wash.SetVisibility(widget_visibility.Hidden)

            # STRETCHED ACROSS THE WHOLE SCREEN, the lesson the Hype meter's
            # canvas had to learn twice: a canvas measures its slots against
            # itself, so a slot anchored 0 to 1 is what makes it the screen.
            # THE PERCENTAGE AS A WHOLE NUMBER. Round is failable, so a
            # refusal simply leaves it at nought rather than costing the
            # contestant their prompt.
            var Percent : int = 0
            if (Rounded := Round[RescueChanceNow() * 100.0]):
                set Percent = Rounded

            Call := text_block:
                DefaultText := ScreenLine(RescuePromptLine)
                DefaultTextColor := NamedColors.Yellow
                DefaultTextSize := 34.0
                DefaultJustification := text_justification.Center

            Odds := text_block:
                DefaultText := ScreenLine("{RescueChancePrefix}{Percent}{RescueChanceSuffix}")
                DefaultTextColor := NamedColors.White
                DefaultTextSize := 24.0
                DefaultJustification := text_justification.Center

            if (not ShowRescuePrompt?):
                Call.SetVisibility(widget_visibility.Hidden)
                Odds.SetVisibility(widget_visibility.Hidden)

            set RescueCall = option{Call}
            set RescueOdds = option{Odds}

            Sheet := canvas:
                Slots := array:
                    canvas_slot:
                        Widget := Wash
                        Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
                        Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                        SizeToContent := false
                        ZOrder := 0

                    # LOW ON THE SCREEN, not across the middle. The contestant
                    # is looking at the arena and hunting for a turkey leg in
                    # three seconds; words over the fight would cost them the
                    # run they are being told how to save.
                    canvas_slot:
                        Widget := Call
                        Anchors := anchors{Minimum := vector2{X := 0.5, Y := RescuePromptY}, Maximum := vector2{X := 0.5, Y := RescuePromptY}}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        ZOrder := 1

                    canvas_slot:
                        Widget := Odds
                        Anchors := anchors{Minimum := vector2{X := 0.5, Y := RescuePromptY + RescueOddsGap}, Maximum := vector2{X := 0.5, Y := RescuePromptY + RescueOddsGap}}
                        Alignment := vector2{X := 0.5, Y := 0.5}
                        ZOrder := 1

            # NO INPUT. The same rule every layer over the arena follows: taking
            # the mouse would take it away from aiming, and aiming is uncuttable
            # per GDD 5.7. Under the Hype meter's 105 so the meter stays readable.
            Slot := player_ui_slot:
                ZOrder := 90
                InputMode := ui_input_mode.None

            if (PlayerUI := GetPlayerUI[P]):
                PlayerUI.AddWidget(Sheet, Slot)
                set OverlayUp = option{Sheet}

                if (ShowRescuePrompt?):
                    set PromptToken = PromptToken + 1
                    spawn{ BlinkPrompt(PromptToken) }

                Log("DEBUG: Death Save -- the window's own overlay is up, prompt blinking at the top.")
            else:
                Log("WARNING: Death Save -- the overlay could not be drawn for this contestant.")

    # Blinks both lines together until the window closes. Abandons itself the
    # moment a newer window bumps the token, because a spawn cannot be cancelled.
    BlinkPrompt(Mine : int)<suspends>:void =
        var Bright : logic = true
        loop:
            if (Mine <> PromptToken):
                break

            Sleep(RescueFlashSeconds)

            # LITERALS, NOT A VARIABLE, AND THE COMMENT IN ShowOverlay SAYS
            # WHY. Opacity is typed as something Verse must PROVE sits between 0
            # and 1, which a float variable cannot carry. GameOverScreen has a
            # Clamped helper for this and copying it here fails with error 3502,
            # so the two states are written out instead.
            if (Bright?):
                set Bright = false
                if (Call := RescueCall?):
                    Call.SetTextOpacity(0.35)
                if (Odds := RescueOdds?):
                    Odds.SetTextOpacity(0.35)
            else:
                set Bright = true
                if (Call := RescueCall?):
                    Call.SetTextOpacity(1.0)
                if (Odds := RescueOdds?):
                    Odds.SetTextOpacity(1.0)

    HideOverlay(P : player):void =
        # Bumping the token is what stops the blink above.
        set PromptToken = PromptToken + 1
        set RescueCall = false
        set RescueOdds = false

        if (Sheet := OverlayUp?, PlayerUI := GetPlayerUI[P]):
            PlayerUI.RemoveWidget(Sheet)
            set OverlayUp = false
            Log("DEBUG: Death Save -- the window's overlay is down.")

    OnDeathSaveFilterIn(Agent : ?agent):void =
        Log("DEBUG: Death Save -- the screen filter finished blending in.")

    SlowHostiles(Multiplier : float):void =
        AmmoModifiers.SetWindowSlow(Multiplier)
