# WaveManager.verse
#
# Implements the win half of GDD Section 2.5 "Win/Loss Resolution & Loop
# Termination": "A room is cleared when the player successfully eliminates all
# spawned waves in the active Escalation Tier." Also implements the escalation
# curve of GDD Section 5.5, 8% per tier hard-capped at Escalation Tier 21, and
# respects the 40-bot concurrency cap of GDD Section 5.3.
#
# SCOPE. Waves, and the win buzzer that marks one being cleared. This device
# does not decide whether a run is won or lost, does not touch score, and does
# not touch Hype. Those belong elsewhere and are deliberately left out.
#
# THE BUZZER. GDD 2.5 sounds "a loud game-show buzzer" when a room is cleared,
# and GDD 1.1 calls it "a satirical game-show buzzer at wave completion". One
# wave is one room here, so both land on the same instant. It sounds at every
# tier including the Tier 21 cap: Kai's ruling 2026-08-17, amendment 23, since
# 1.1 ties the buzzer to wave completion and never to tiers, and going silent
# at the ceiling would read as a fault rather than a design choice.
#
# VERSE DRIVES THE SPAWNING, NOT THE EDITOR.
# GDD 5.5 asks for spawn density to climb with the tier, and the NPC Spawner's
# Spawn Count cannot be changed at runtime: nothing in npc_spawner_device sets
# it, and only other spawner devices even expose a getter. So the pacing is done
# here instead. This device calls Spawn() on its own interval and tops the arena
# up to a concurrent target it works out per tier. Both the rate
# (SpawnIntervalSeconds) and the density (ConcurrentAtTier1) are script values
# that scale, rather than fixed editor settings.
#
# HOSTILE HEALTH AND SPEED SCALE BY SWAPPING THE DEFINITION.
# GDD 5.5 scales three things per tier: spawn density, hostile health pools and
# movement speeds. The last two live on the NPC character definition and cannot
# be set at runtime, so the wave manager swaps which definition the spawner uses
# as the tier climbs, stepping through TierDefinitions from weakest to
# strongest. The swap happens between waves, when nothing is alive, so it can
# never catch a hostile mid-fight. Leave TierDefinitions empty and none of this
# happens at all.
#
# THE ONBOARDING RAMP, HOSTILES ONLY.
# GDD 2.4 introduces systems gradually over the first rooms. Kai's ruling
# 2026-08-21, amendment 56: the hostile half of that ramp is built and the
# HUD/Hype/crate blackout half is tabled. Boars join at room 2, Sentinels at
# room 3, Tanks at room 4, each type getting a room to itself before the next
# lands. That fills the gap 2.4 leaves by listing rooms 1, 2, 4 and 5 and
# skipping 3.
#
# THE RAMP RUNS ON EVERY RUN, not only the first life. A deliberate departure
# from 2.4's "Restart Skip", Kai's ruling 2026-08-21. A lost run ends the
# match, so a fresh run restarts this device at Tier 1 and the ramp returns by
# itself. Honouring Restart Skip would have meant remembering deaths between
# matches, and would have put Tanks in the opening seconds of every run after
# the first death, which is the thing the ramp exists to prevent.
#
# A LOCKED TYPE LEAVES ITS SEATS EMPTY. Locked types keep their share of the
# arena and never fill it, so room 1 runs at five tenths of the density, room 2
# at seven, room 3 at nine, room 4 onwards at full. The number to clear shrinks
# by the same fraction, so a thinner room is also a shorter one and every room
# still runs about two minutes, per Kai's ruling 2026-08-18. Renormalising the
# shares instead would have made room 1 twenty Swarmers, as busy as any later
# room, and would have hidden the ramp completely.
#
# HOW ONE WAVE RUNS.
#   1. Reset the spawner, work out this tier's wave size and concurrent target.
#   2. Enable the spawner, then call Spawn() every SpawnIntervalSeconds for as
#      long as fewer hostiles are alive than the concurrent target allows, until
#      WaveSize of them have appeared.
#   3. The spawn loop stops there, which is what makes the wave a fixed batch.
#      Nothing further arrives, because the device only ever spawns when this
#      script asks it to.
#   4. Count EliminatedEvent until every hostile from that batch is dead.
#   5. Advance the Escalation Tier, grow both the wave size and the concurrent
#      target by TierScalingPercent, wait DelayBetweenWaves, and go round again.
#
# A REQUESTED HOSTILE TAKES ABOUT TWO SECONDS TO ARRIVE.
# Spawn() returns at once but the hostile is not in the world yet, and until it
# is, CountLiveHostiles cannot see it. So the loop keeps a count of what it has
# already asked for, SpawnsInFlight, and treats those as if they were already
# standing there. Without it the loop asked all through the arrival gap and
# overshot the target by about six, which is how a room built for ten held
# sixteen on 2026-08-21. Amendment 57.
#
# ONE REQUIRED UEFN SETTING.
#   * The spawner's own automatic spawning must be OFF. This means ALL FOUR
#     spawner devices, not just one: on 2026-08-21 the Boar, Sentinel and Tank
#     devices each had Spawn On Timer set to Yes on a three-second period, so
#     three uninvited hostiles arrived every three seconds, in room 1, where the
#     ramp had let none of those types in. Amendment 57. With Spawn On Timer
#     disabled, an enabled spawner produces nothing by itself and every hostile
#     arrives because this script called Spawn(). If the device also spawns on
#     its own schedule, hostiles come from two sources at once and the
#     concurrent target is overshot.
#
# WHY THIS DEVICE NEVER CALLS Disable(). DO NOT ADD IT BACK.
# It used to, to cap a wave once WaveSize had spawned. That call was deleting
# the hostiles still alive at the moment it ran. Across three consecutive waves
# the number that vanished without firing EliminatedEvent was exactly the number
# alive when Disable() was called, every time. This happened with "Despawn AIs
# When Disabled" already unticked, so either that setting does not behave as
# documented in this version, or Disable() despawns regardless of it.
#
# With Spawn On Timer off the call has no job left to do, so it is gone. The
# wave is capped by the spawn loop finishing, not by switching the device off.
#
# TWO SAFETY VALVES, BOTH LOUD.
# A capstone demo must not be able to lock up, so neither wave phase can wait
# forever. If spawning stalls, or if the arena empties without the eliminations
# being counted, the wave moves on and prints a WARNING saying exactly what it
# expected versus what it got. Neither one can fail quietly.

using { /Fortnite.com/Assets }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }
using { /Verse.org/Colors }
using { /Verse.org/Simulation }

# text_block takes a message rather than a string, so the banner text has to pass
# through a localizes function. It holds no wording of its own.
BannerLine<localizes>(Value : string) : message = "{Value}"

wave_manager := class(creative_device):

    # ONE SPAWNER PER HOSTILE TYPE. Amendment 45: all four share the arena at
    # once, and SetNPCCharacterDefinition is refused across different character
    # types, so one device cannot serve them all. Named slots rather than array
    # rows, because a mis-ordered row is silent and a named slot is not.
    @editable
    SwarmerSpawner : npc_spawner_device = npc_spawner_device{}

    @editable
    BoarSpawner : npc_spawner_device = npc_spawner_device{}

    @editable
    SentinelSpawner : npc_spawner_device = npc_spawner_device{}

    @editable
    TankSpawner : npc_spawner_device = npc_spawner_device{}

    # How the concurrent target is divided. Amendment 45's mix is five Swarmers,
    # two Boars, two Sentinels and one Tank out of every ten alive. Shares rather
    # than counts, so the proportions hold as the tier climbs and the crowd grows.
    @editable
    SwarmerShare : float = 5.0

    @editable
    BoarShare : float = 2.0

    @editable
    SentinelShare : float = 2.0

    @editable
    TankShare : float = 1.0

    # THE ONBOARDING RAMP of GDD 2.4. The room each type first appears in, so
    # the player meets one new hostile at a time. Kai's ruling 2026-08-21.
    # Swarmers are always in from room 1, so they have no field here.
    #
    # Room and Escalation Tier are the same counter, per GDD 2.5, so these are
    # tier numbers. Set all three to 1 to switch the ramp off and have all four
    # types present from the first room, which is what the build did before.
    @editable
    BoarJoinsAtTier : int = 2

    @editable
    SentinelJoinsAtTier : int = 3

    @editable
    TankJoinsAtTier : int = 4

    # HOW MANY SENTINELS AND TANKS A WHOLE WAVE MAY CONTAIN, while they are still
    # meant to be rare. Kai's rulings 2026-08-22, from the room list Kai wrote
    # out twice: room 3 is Swarmers, a few Boars and two Sentinels; room 4 adds
    # one Tank.
    #
    # THESE ARE WHOLE-WAVE QUOTAS, NOT A LIMIT ON HOW MANY ARE ALIVE AT ONCE.
    # Kill the wave's one Tank and no other Tank arrives until the next wave.
    # That is the point of them: a heavy that returns the moment it dies is
    # constant pressure rather than an event, and Kai asked for it to keep
    # feeling like a big deal.
    #
    # The rationed slots do not leave the arena thin. A type that has used up its
    # quota drops out of the mix and the Swarmers fill the space, so the crowd
    # stays the size the tier says and only its make-up changes. Boars used to
    # help fill it and no longer do; see BoarsOnArrival.
    @editable
    SentinelsOnArrival : int = 2

    # From the room after they arrive until RareTypesEndAtTier. Kai's "two or
    # three a wave for a good stretch".
    @editable
    SentinelsWhileRare : int = 3

    @editable
    TanksOnArrival : int = 1

    # Kai's "one or two a wave" for the stretch after the Tank arrives.
    @editable
    TanksWhileRare : int = 2

    # Where the rationing stops and both types go back to taking their share of
    # the crowd like Swarmers and Boars. Kai's ruling 2026-08-22: about room
    # fifteen, so the Tank is a rare terror for eleven rooms before it ever
    # becomes ordinary.
    @editable
    RareTypesEndAtTier : int = 15

    # -- GDD 5.5's safety radius. See HoldTheSafetyRadius --------------

    # How close a robot may arrive to the contestant, in centimetres. GDD 5.5's
    # three metres.
    @editable
    SafetySpawnRadius : float = 300.0

    # Where one that arrives too close is put instead. Comfortably outside the
    # radius, so a robot is never nudged to exactly the line and reported again.
    @editable
    SafeSpawnDistance : float = 450.0

    # The arena, for clamping a moved robot back inside it.
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
    @editable
    ArenaHalfLength : float = 1220.0

    @editable
    ArenaHalfWidth : float = 720.0

    # How far inside the wall a moved robot is allowed to land.
    @editable
    SpawnInset : float = 80.0

    # THE BOAR IS RATIONED TOO NOW, KAI'S RULING 2026-08-27. It was deliberately
    # left out of the rationing above, back when it was meant to be an ordinary
    # robot alongside the Swarmer.
    #
    # WHY IT CHANGED. Kai: "there's still too many enemies like the shotgun
    # enemies, there's a lot of them". Room 2 went from no Boars at all to about
    # six in one step, because the Boar took its full 2-in-7 share of the crowd
    # the moment the ramp let it in. The 2026-08-27 log has Boars landing 50 to
    # 60 damage a blow, so six of them is a wall rather than a step up.
    #
    # SHORTER THAN THE OTHER TWO ON PURPOSE. The Sentinel and the Tank stay rare
    # until room 15 because Kai wanted a heavy to keep feeling like an event. The
    # Boar is not a heavy, it just needed an introduction, so it becomes ordinary
    # from room 6 and takes its full share from there.
    @editable
    BoarsOnArrival : int = 2

    # From the room after they arrive until BoarsEndAtTier.
    @editable
    BoarsWhileRare : int = 4

    @editable
    BoarsEndAtTier : int = 6

    # The placed Audio Player holding the win buzzer. GDD 5.4 budgets two
    # game-show buzzer sounds and this is the first; the second is the losing
    # buzzer in DeathSaveManager. Set this device to be heard everywhere rather
    # than fading with distance, or it is faint from the far side of the arena.
    @editable
    WinBuzzer : audio_player_device = audio_player_device{}

    # The cash manager, so a cleared room can be paid through its public
    # AddPrizeMoney. GDD 2.1 step 6 asks for "massive cash windfalls" for
    # clearing room waves and nothing paid them until 2026-08-28: the buzzer
    # sounded, the tier climbed, and the bankroll did not move.
    #
    # The money still lives in one place. This file only says a room was won and
    # how much it was worth; the cash manager owns the total and the readout.
    @editable
    CashDrops : cash_drop_manager = cash_drop_manager{}

    # The hostile character definitions to step through as the tier climbs,
    # ordered WEAKEST FIRST. This is how GDD 5.5's health and movement-speed
    # scaling is delivered, since both live on the definition and neither can be
    # changed at runtime.
    #
    # The tier range is split evenly across however many entries are here, so
    # five entries against MaxTier 21 gives tiers 1-4, 5-8, 9-12, 13-16, 17-21.
    # Add or remove entries and the split recomputes itself.
    #
    # Entry 0 is applied at match start, so this list is authoritative from
    # Tier 1 onwards and whatever the spawner was given in UEFN is overridden.
    #
    # Leave it empty to switch tier scaling off entirely: the spawner then keeps
    # whatever definition it was given in UEFN and nothing here touches it.
    # Every entry must be the same character type, or the swap will be refused.
    # One list per type, amendment 48, five cards each, weakest first. A type
    # with an empty list keeps whatever card its spawner was given in UEFN.
    @editable
    SwarmerDefinitions : []npc_character_definition = array{}

    @editable
    BoarDefinitions : []npc_character_definition = array{}

    @editable
    SentinelDefinitions : []npc_character_definition = array{}

    @editable
    TankDefinitions : []npc_character_definition = array{}

    # The Barrier devices standing in the arena's doorways. Each hostile is added
    # to every one of these ignore lists as it spawns and taken off again when it
    # dies, so hostiles walk through the doorway and the player cannot.
    #
    # WHY THIS IS DONE IN CODE. The Barrier's own Ignore Team and Ignore Class
    # settings were both tried on 2026-08-22, with the hostiles' team index of 2
    # and Can NPC Added to Ignore List ticked, and hostiles were still stopped.
    # AddToIgnoreList is a separate mechanism, described in the digest as being
    # "in addition to the Ignore Team and Ignore Class options", and it is the one
    # that works.
    #
    # IT WORKS ON THE HOSTILE, NOT ON WHAT THE HOSTILE IS. Kai's concern on
    # 2026-08-22 was that the look and the weapons are still being changed during
    # play. Nothing here reads a character definition, a model or a weapon, so
    # changing any of them cannot break this.
    #
    # Leave it empty and nothing happens, which is what you want if the doorways
    # are ever sealed instead.
    @editable
    ArenaBarriers : []barrier_device = array{}

    # HOW LONG A WAVE SHOULD LAST, IN SECONDS. The head count is worked out from
    # this rather than set by hand, so the dial is the thing Kai actually thinks
    # in. Kai's rulings 2026-08-22.
    #
    # WHY THIS REPLACED A FIXED WAVE SIZE. The 2026-08-18 ruling fixed the head
    # count so waves stayed the same length and escalation went into crowding.
    # In play it did the opposite: a fixed head count against a crowd that grows
    # 8% a tier means more targets in reach, so later waves finished FASTER. Kai
    # spotted that on 2026-08-22 and reversed the ruling. Length escalates on
    # purpose now, and 2m30 is the ceiling it may never pass.
    #
    # Wave one is the tutorial, so 45 seconds: long enough to learn running one
    # way while shooting another, see the first cash burst and catch one crate on
    # the 25-second trickle, short enough that the escalation arrives while the
    # player still cares.
    #
    # 30, Kai's ruling 2026-08-24, after 15 was tried and 45 was too long. That is
    # about 33 hostiles rather than 50, so the first escalation arrives while the
    # opening wave still has the player's attention.
    @editable
    WaveSecondsAtTier1 : float = 30.0

    # How many seconds longer each tier's wave runs than the one before. 6 takes
    # 30 seconds at Tier 1 to 150 at Tier 21, where GDD 5.5 caps escalation, so
    # the ramp and the cap still land together.
    @editable
    WaveSecondsPerTier : float = 6.0

    # The longest a wave may ever run, in seconds. Kai's ruling 2026-08-22:
    # "2m30 is the longest wave that will ever exist." This game has no end, so
    # every wave past Tier 21 sits here.
    @editable
    WaveSecondsMax : float = 150.0

    # How many hostiles the player kills a second, per hostile on screen. A
    # wave's head count is this times the crowd size times the seconds above.
    #
    # 0.11 from the 2026-08-22 log: 92 kills in 78 seconds with 10 on screen is
    # 1.18 a second, and the earlier 20-on-screen reading was about 2.2. A
    # measured first guess, not a law. If waves run long, lower it; if they end
    # early, raise it.
    @editable
    KillsPerSecondPerHostileOnScreen : float = 0.11

    # HOW MUCH OF A WAVE MAY BE SPENT WALKING HOSTILES IN, as a fraction of the
    # wave's own length. The rest is the time it takes to clear the last crowd.
    #
    # WHY THIS EXISTS. The head count above is a guess at how fast the player
    # kills, and until 2026-08-27 nothing checked whether there was even time to
    # get that many hostiles through the door one at a time. Kai's report: room 2
    # dragged and was nothing but Swarmers. It had ordered 36 hostiles at one
    # every 1.2 seconds, which is 43 seconds of pure arriving inside a wave
    # aiming at 36. Room 1 was fine only because its 20 fitted in its 30.
    #
    # 0.7 leaves about a third of the wave for killing the tail. Raise it and
    # waves run long again; lower it and they end with the arena half empty.
    @editable
    SpawnTimeShareOfWave : float = 0.7

    # How much longer a kill takes for each step up the hostile card ladder.
    # 1.36 from amendment 46's health table: the Boar ladder runs 80, 109, 148,
    # 202, 274, which is 1.36 times tougher a step, and the other three ladders
    # were built to the same ratio.
    @editable
    ToughnessPerCardStep : float = 1.36

    # How many hostiles may be alive at once at Escalation Tier 1. This is the
    # spawn density GDD 5.5 asks to scale, and it climbs per tier exactly like
    # the wave size does. A decimal for the same compounding reason.
    #
    # 10, DOWN FROM 20 AND EXPLICITLY TEMPORARY. Kai's ruling 2026-08-19, after
    # playing it: at 20 with only the pistol, hostiles built up faster than they
    # could be cleared, the measured kill rate being 0.18 a second, so the arena
    # boxed the player in rather than being outrun. Kai asked to be made faster
    # and that is not the fault: amendment 31 measured the player at 11.90 m/s
    # against a hostile top speed of 5.6, so speed is already more than double.
    # The arsenal is the bottleneck, not the density, so this rises again once
    # the crate weapons exist. It also makes GDD 3.1's four-kills-in-0.4-seconds
    # cluster reachable, which is currently the only source of Hype in the game.
    #
    # 20 was itself up from 3, Kai's ruling 2026-08-18: the GDD's references are
    # Smash TV and Total Carnage, which flood the screen, and 3 at a time is a
    # queue rather than a rush. That 3 came from a playtest where five at once
    # was unsurvivable, but that was before the pistol stopped running dry on
    # 2026-08-17, so it judged a fight where you could be caught with an empty
    # gun. Every hostile in the map is melee, and kiting exists to handle crowds.
    #
    # At 20 this reaches GDD 5.3's ceiling of 40 at about Tier 10, so the density
    # the GDD asks for actually arrives inside a run. Past that the 8% has to come
    # from tougher hostiles, which is what TierDefinitions is for.
    #
    # Was 10 from 2026-08-19, parked low until the crate weapons were proven.
    # Crates landed on 2026-08-20 and Kai raised it the same evening. 40 was not
    # taken directly because bullets and cash drops now share the ~100 prop budget
    # and GDD 5.1 makes 60 FPS a hard target.
    # 12 FROM 2026-08-27, DOWN FROM 20, AND THE SHARES ARE WHY IT READS AS 6.
    # Kai's report: "when I played all the enemies came in at once". The log
    # agreed and put a number on it -- sixteen robots in 4.9 seconds. Only the
    # Swarmer is unlocked in room 1 and its share is 5 of 10, so RampFraction
    # halves this: 12 gives SIX on screen in room 1, then 9, 13 and 15 as the
    # other three types join over rooms 2, 3 and 4. The 8% climb carries it up
    # from there to the 40 ceiling.
    @editable
    ConcurrentAtTier1 : float = 12.0

    # How often this device tries to add one hostile, in seconds. This is the
    # spawn rate, and it is a script value now rather than an editor setting.
    # 0.25 rather than 0.5. At two hostiles a second the spawner could only just
    # match the player's kill rate, so the arena never filled to its target.
    #
    # 1.2 FROM 2026-08-27, AND IT DOES NOT REOPEN THAT PROBLEM. The 0.25 above
    # made the arena fill in under five seconds, which Kai read as every robot
    # arriving at once, and the log measured sixteen in 4.9 seconds. The worry
    # behind 0.25 was arrivals losing a race against the player's kill rate: in
    # the 2026-08-27 log Kai was killing between 0.3 and 0.7 a second, so 0.83 a
    # second still outpaces them and the arena still reaches its cap. It just
    # takes about ten seconds to get there, which is the trickle rather than the
    # dump. If a later playtest shows the arena never filling, lower this before
    # touching ConcurrentAtTier1.
    #
    # 0.9 FROM 1.2 ON 2026-08-28, Kai playing: "they spawn in a tad too slow".
    # Still well off the 0.25 that put sixteen robots in the arena in 4.9
    # seconds, so the trickle the paragraph above argues for is intact; the room
    # simply fills a third faster. A wave's head count follows this by itself
    # through SpawnTimeShareOfWave, so a quicker door means a fuller room rather
    # than a longer one.
    @editable
    SpawnIntervalSeconds : float = 0.9

    # How long the spawn loop will keep asking for a hostile that never arrives
    # before it gives up on the rest of the wave, in seconds.
    #
    # Only time spent actually asking counts towards this. Waiting because the
    # arena is already as full as the concurrent target allows is normal play
    # and never counts, so a slow player can never trip it.
    @editable
    SpawnStallTimeoutSeconds : float = 15.0

    # How long the loop may go with nothing arriving at all, while it is still
    # waiting on hostiles it asked for, before it stops counting them. Without
    # it, one spawn that silently failed would hold a slot for the rest of the
    # wave and the room would run short for ever after.
    #
    # TWELVE, RAISED FROM SIX ON 2026-08-28, and the playtest log is why. It
    # fired twice in one run, and BOTH times a hostile arrived 0.13 seconds
    # afterwards. Nothing had been lost: the spawner device paces its own
    # deliveries and had simply gone quiet for a moment longer than the timeout
    # allowed. Six was measured against an arrival time of about two seconds on
    # 2026-08-21, before the wave loop ever had four hostiles queued at once.
    #
    # GIVING UP TOO EARLY IS NOT HARMLESS. The reservation is released and the
    # loop asks again, so hostiles already on their way arrive on top of the
    # replacements and the arena can carry more than the concurrent target it
    # was given. GDD 5.3 caps that at 40, and this was quietly pushing at it.
    #
    # It is time with NOTHING arriving, not time per hostile: any arrival at all
    # resets the clock, so a slow trickle never trips it and a dead spawner
    # still gets caught.
    @editable
    SpawnArrivalTimeoutSeconds : float = 12.0

    # How long the arena is left alone between the clear-out and the first wave
    # of a run. See the run loop at the foot of OnBegin: a run that follows LEAVE THE SHOW
    # had its robots taken away a tenth of a second after they arrived, because
    # the previous clear-out was still working. Half a second is the pause
    # nobody notices, sitting between START SHOW and the first robot walking in.
    @editable
    ClearOutSettleSeconds : float = 0.5

    # How much denser each wave gets per tier, as a percentage. GDD 5.5 fixes
    # this at exactly 8% per tier. It applies to the concurrent target ONLY;
    # wave size is fixed, so waves stay the same length and get busier. See
    # WaveSize above for the ruling.
    @editable
    TierScalingPercent : float = 8.0

    # Where the CROWD stops growing. GDD 5.5 hard-caps escalation at Escalation
    # Tier 21, about 5x starting difficulty. The tier number itself no longer
    # stops here, and nor does the difficulty: past this point rooms get tougher
    # instead of busier, per amendment 92 and EndlessToughnessPercent below.
    @editable
    MaxTier : int = 21

    # ENDLESS ESCALATION, PAST GDD 5.5'S CEILING. Amendment 92, Kai's ruling
    # 2026-08-28. The game is meant to be endless, and a run that stops getting
    # harder at room 21 stops being one.
    #
    # CROWDING CANNOT BE THE LEVER PAST 21. GDD 5.3 caps the arena at 40 live
    # bots and that is UEFN's own wall, not a preference, so "busier every room"
    # runs out of road. Toughness is the one lever the wall does not touch: from
    # Tier MaxTier + 1 on, every hostile arrives with this much more health than
    # the room before, compounding with no ceiling.
    #
    # Set to the same 8% GDD 5.5 uses for crowding, so the ramp past 21 reads as
    # a continuation rather than a new rule. Robots take twice the punishment by
    # room 30 and about ten times by room 51.
    @editable
    EndlessToughnessPercent : float = 8.0

    # WHAT CLEARING ROOM 1 PAYS. GDD 2.1 step 6's "massive cash windfall", and
    # massive is measured against the floor loot: a hostile bursts into 3 items
    # worth 10 each, so a whole room of pickups is a few hundred. Kai's ruling
    # 2026-08-28.
    @editable
    RoomBonusAtTier1 : float = 1000.0

    # How much more each room pays than the one before, as a percentage. Kai's
    # ruling 2026-08-28: 50%, so room 2 pays 1,500 and room 10 about 38,000.
    #
    # IT NEVER STOPS COMPOUNDING, deliberately. Kai first froze it at Tier 21
    # and then reversed that in the same sitting once the rooms themselves were
    # made to keep getting harder past 21. The pay has to keep pace with the
    # danger, and a show that boasts about money it never hands over should
    # quote absurd numbers.
    @editable
    RoomBonusGrowthPercent : float = 50.0

    # The ceiling on how many hostiles may be alive at once, capped at 40 bots
    # by GDD 5.3 to stay inside UEFN's budget. The per-tier concurrent target
    # scales up towards this and is never allowed past it.
    @editable
    MaxConcurrentHostiles : float = 40.0

    # The breather between one wave being cleared and the next starting, in
    # seconds.
    @editable
    DelayBetweenWaves : float = 3.0

    # GDD 1 asks for "flashing scoreboard visuals" and GDD 2.5 names the moment
    # "Room Won". Until now only the buzzer marked it and nothing did visually.
    # Kai's call 2026-08-20: big and centre, so it cannot be missed mid-fight.
    # Kept under DelayBetweenWaves so it is gone before the next wave arrives.
    @editable
    BannerSeconds : float = 2.0

    # Amendment 36 Layer 2: Broadcast Purple is the designated colour for "HUD
    # panel backgrounds, chat widget frame, title cards", and this is a title
    # card. Floodlight Warm for the text. Neither is a reserved Layer 3 gameplay
    # colour, so the banner can never be mistaken for something that hurts or heals.
    BannerPanelColor : color = MakeColorFromHex("7A2E8C")
    BannerTextColor : color = MakeColorFromHex("FFE9A8")

    # How often the wave loop looks at its counters while waiting for a wave to
    # be cleared, in seconds. Not editable: this is bookkeeping, not something
    # that changes how the game feels.
    PollSeconds : float = 0.25

    # How many polls in a row must find nothing alive before a wave is declared
    # cleared on that basis alone. Four polls is one second. One reading of zero
    # is not trusted, because a hostile can read as not-yet-active for a moment
    # while it is still arriving.
    EmptyPollsToClear : int = 4

    # The Escalation Tier of GDD 5.5. Starts at 1 and climbs by one per cleared
    # wave, with no ceiling since amendment 92. It used to stop at MaxTier.
    var CurrentTier : int = 1

    # Read-only access for other devices. CareerRankManager needs the tier
    # reached at the moment a run ends, per GDD 2.6. This only reports the
    # number; it changes nothing, and this file's scope is unchanged.
    GetCurrentTier<public>()<transacts>:int = CurrentTier

    # ROOMS WON AND ROBOTS SCRAPPED, for the game over card's stats panel.
    #
    # Neither could be worked out from what was already here. CurrentTier is a
    # difficulty number rather than a count, and EliminatedThisWave is wiped at
    # the start of every wave. These two are the run's own totals and nothing
    # resets them but a fresh run.
    var RoomsWon : int = 0
    var RunEliminations : int = 0

    GetRoomsWon<public>()<transacts>:int = RoomsWon
    GetRunEliminations<public>()<transacts>:int = RunEliminations

    # How long the wave in progress should run, in seconds. Grows by
    # WaveSecondsPerTier each tier and stops at WaveSecondsMax.
    var WaveSecondsExact : float = 0.0

    # The concurrent target carried as a decimal, so the 8% compounds properly.
    # Rounding every tier would throw the fraction away and the crowd would grow
    # too slowly.
    var ConcurrentExact : float = 0.0

    # How much tougher than the base cards this room's hostiles are, past Tier
    # MaxTier. Exactly 1.0 for the whole of Tiers 1-21, so nothing that has been
    # playtested changes. Carried as a decimal for the same reason
    # ConcurrentExact is: rounding every room throws the compounding away.
    var EndlessHealthExact : float = 1.0

    # What clearing the room in progress pays, carried as a decimal so the 50%
    # compounds properly. Rounded only at the moment it is handed over.
    var RoomBonusExact : float = 0.0

    # The same after the onboarding ramp has thinned it and GDD 5.3's ceiling has
    # capped it, still a decimal. The head count is worked out from this, and
    # ConcurrentTarget is just this rounded.
    var ConcurrentNowExact : float = 0.0

    # How many hostiles the wave in progress should spawn in total.
    var TargetThisWave : int = 0

    # How many may be alive at once during the wave in progress, already rounded
    # and already clamped to MaxConcurrentHostiles.
    var ConcurrentTarget : int = 0

    # Counters for the wave in progress. These track wave progress; they are not
    # used to decide how many are alive, which CountLiveHostiles answers.
    var SpawnedThisWave : int = 0
    var EliminatedThisWave : int = 0

    # How many of each type this wave has asked for, in the AllSpawners order.
    # Counted when asked for rather than when it arrives, because that is where
    # the decision is made and a request that never lands is already handled by
    # SpawnsInFlight. Reset at the start of every wave.
    var SpawnedByType : []int = array{0, 0, 0, 0}

    # Hostiles asked for that have not arrived yet. A spawn takes about two
    # seconds to appear and counts nowhere until it does, because
    # CountLiveHostiles can only see characters already in the world. Without
    # this the loop kept asking through that gap and overshot by about six, which
    # is how a room built for ten held sixteen. Measured from the log 2026-08-21.
    var SpawnsInFlight : int = 0

    # EVERY HOSTILE THIS RUN HAS SEEN ARRIVE. Emptied at the top of every run,
    # so an elimination that belongs to the run before can be told apart from
    # one that belongs to this one. See OnHostileEliminated for what went wrong
    # without it.
    var SpawnedThisRun : [agent]logic = map{}

    # Seconds since a hostile last actually arrived, used only to release
    # reservations that are never going to be filled.
    var SecondsSinceArrival : float = 0.0

    OnBegin<override>()<suspends>:void =
        for (Spawner : AllSpawners()):
            Spawner.SpawnedEvent.Subscribe(OnHostileSpawned)
            Spawner.EliminatedEvent.Subscribe(OnHostileEliminated)

        # AN EMPTY ARENA BEFORE THE SHOW STARTS. Amendment 103a.
        #
        # The 2026-08-28 log has three hostiles eliminated in the first three
        # seconds of a run that had never watched any of them arrive, and Kai
        # saw one of them vanish in front of them. They were standing in the
        # world before START SHOW was pressed, and the spawner reset that opens
        # the first wave took them away.
        #
        # Sweeping here means they are gone while the title card is still up,
        # where nobody is looking, rather than popping out of existence in a
        # live arena. Amendment 103's filter already stopped them paying out;
        # this stops them being seen at all.
        for (Spawner : AllSpawners()):
            Spawner.DespawnAll(false)

        # Seed the running values from the editable starting values.
        set WaveSecondsExact = WaveSecondsAtTier1
        set ConcurrentExact = ConcurrentAtTier1

        for (SlotIndex := 0..3):
            DefinitionCount := DefinitionsFor(SlotIndex).Length
            if (DefinitionCount > 0):
                Log("DEBUG: Tier scaling ACTIVE for spawner {SlotIndex} -- {DefinitionCount} cards, swapped between waves as the tier climbs.")
            else:
                Log("DEBUG: Tier scaling OFF for spawner {SlotIndex} -- its card list is empty, so it keeps whatever definition it was given in UEFN.")

        # Apply the Tier 1 entry before the first wave, so the list is
        # authoritative from the start rather than the arena running on
        # whatever definition the spawner happened to be given in UEFN.
        ApplyTierDefinition()

        # Nothing spawns until PLAY is clicked. Amendment 70.
        #
        # THE OUTER LOOP IS THE RESTART, amendment 86. RunWaves never ends by
        # itself, so it is raced against AwaitRunEnd: the moment PLAY AGAIN or
        # LEAVE THE SHOW closes the gate, the wave loop is cancelled wherever it
        # had got to, the floor is cleared, and this comes back round to wait.
        loop:
            AwaitMatchStart(Self)

            # THE CLEAR-OUT IS GIVEN TIME TO FINISH BEFORE THE FIRST WAVE.
            #
            # Kai, 2026-08-29, after pressing LEAVE THE SHOW and then START
            # SHOW: "something weird happened." The first three robots of the
            # new run were taken away a tenth of a second after they arrived.
            # There was not one damage line against them, so nothing shot them:
            # the last run's DespawnAll was still working through the arena and
            # caught them as they came out of the spawner.
            #
            # THE CASH AND THE COUNT MADE IT WORSE, not better. This run had
            # already watched them arrive, so amendment 103's filter let them
            # through: they paid out, and the wave counted down to seventeen
            # before the contestant had fired a shot.
            #
            # SWEPT AND THEN LEFT ALONE FOR A MOMENT. The sweep is the same
            # DespawnAll amendment 103a runs at match start, and the wait after
            # it is the whole point: the queue empties into an arena that is not
            # yet spawning, where there is nothing for it to take.
            #
            # THE MAP IS EMPTIED FIRST, so anything the sweep removes belongs to
            # nobody and pays out nothing. StartFreshRun empties it again, which
            # costs nothing and keeps that file's own promise intact.
            set SpawnedThisRun = map{}
            for (Spawner : AllSpawners()):
                Spawner.DespawnAll(false)
            Sleep(ClearOutSettleSeconds)

            StartFreshRun()

            race:
                RunWaves()
                AwaitRunEnd(Self)

            PackUp()

    # Puts the arena back to how it stood before the first wave of a run. Called
    # at the top of every run, including the first, so one path serves both.
    StartFreshRun():void =
        set CurrentTier = 1
        set WaveSecondsExact = WaveSecondsAtTier1
        set ConcurrentExact = ConcurrentAtTier1
        set RoomsWon = 0
        set RunEliminations = 0

        # Both of the endless-run figures go back to their room 1 values, or a
        # second run would open paying room 40 money at room 40 toughness.
        set EndlessHealthExact = 1.0
        set RoomBonusExact = RoomBonusAtTier1

        # Nothing alive is this run's until this run has watched it arrive. Also
        # emptied in PackUp, so one path serves a clean end and the other serves
        # a start that never had an end before it. Amendment 103.
        set SpawnedThisRun = map{}

        # The tier list is authoritative from the first wave rather than the
        # arena running on whatever card a spawner was last left holding.
        ApplyTierDefinition()

        # ONLY THE TYPES ROOM 1 IS ALLOWED, WHICH IS THE SWARMER ALONE.
        #
        # THIS LINE USED TO WAKE ALL FOUR AND IT PUT A BOAR, A SNIPER AND A TANK
        # IN ROOM ONE. Kai reported all three in room 1 on 2026-08-27. The file
        # header and amendment 57 both warn why: waking a spawner makes it
        # produce one hostile of its own accord, so a type the ramp has not
        # admitted must not be woken. That is the same fault as the Tank in room
        # 1 of 2026-08-21, reopened by amendment 86's restart work.
        #
        # StartWave already wakes each spawner on the one wave its type joins,
        # and the Swarmer answers 1, so room one wakes itself and nothing else
        # needs enabling here.
        for (SlotIndex -> Spawner : AllSpawners(), JoinTierFor(SlotIndex) <= CurrentTier):
            Spawner.Enable()

        Log("DEBUG: fresh run -- back to Tier 1, only the Swarmer's spawner awake.")

    # Clears the floor when a run ends.
    #
    # DISABLE IS USED ON PURPOSE HERE, and the file header warns against it for
    # good reason: it deletes hostiles that are still alive without firing
    # EliminatedEvent. Mid-wave that loses the count and hangs the room forever.
    # At the END of a run deleting them is exactly the point and no count is
    # waiting on them, so the thing that makes it dangerous is what makes it the
    # right tool. StartFreshRun switches the spawners back on.
    PackUp():void =
        for (Spawner : AllSpawners()):
            # DISABLE ON ITS OWN DOES NOT EMPTY THE ARENA, and this file said it
            # did for two days. The digest is exact: "Characters will despawn if
            # *Despawn AIs When Disabled* is set", and it is not set on the
            # placed spawners. In the 2026-08-28 playtest a restarted run opened
            # with NINE robots already alive, the ones that had just killed Kai,
            # standing exactly where they had been.
            #
            # DespawnAll is the call that actually clears them. Nobody is passed
            # as the instigator, so no contestant is credited with killing a
            # roomful of robots they never touched.
            Spawner.DespawnAll(false)
            Spawner.Disable()

        # And every one of them is forgotten, so the deaths that arrive from the
        # despawn above land in the next run as somebody else's business. See
        # OnHostileEliminated. Amendment 103.
        set SpawnedThisRun = map{}

        Log("DEBUG: run packed up -- every hostile despawned, spawners off and the floor cleared.")

    # The wave loop. Runs for as long as the match does.
    RunWaves()<suspends>:void =
        loop:
            StartWave()
            RunSpawnLoop()

            # The batch is out. Nothing else will arrive, because the device
            # only spawns when this script calls Spawn() and the spawn loop has
            # finished. Switching the device off here used to delete the
            # hostiles still alive; see the file header.
            LiveCount := CountLiveHostiles()
            Log("DEBUG: Wave fully spawned -- {LiveCount} hostiles in the arena")

            AwaitWaveCleared()
            CompleteWave()
            Sleep(DelayBetweenWaves)

    StartWave():void =
        set SpawnedThisWave = 0
        set EliminatedThisWave = 0
        set SpawnedByType = array{0, 0, 0, 0}
        set SpawnsInFlight = 0
        set SecondsSinceArrival = 0.0

        # In case the editor's Spawn Count is a total budget rather than a
        # concurrency cap. The digest describes Reset as "allowing spawning of a
        # new batch" without saying which it is, and calling it is harmless
        # either way.
        for (Spawner : AllSpawners()):
            Spawner.Reset()

        # The ramp thins the early rooms: a type that has not joined yet leaves
        # its share of the arena empty, so fewer hostiles are on screen.
        Fraction := RampFraction()

        # The crowd first, because the head count is worked out from it.
        var Crowd : float = ConcurrentExact * Fraction
        if (Crowd > MaxConcurrentHostiles):
            set Crowd = MaxConcurrentHostiles
        if (Crowd < 1.0):
            set Crowd = 1.0
        set ConcurrentNowExact = Crowd

        var Concurrent : int = 1
        if (RoundedConcurrent := Round[Crowd]):
            set Concurrent = RoundedConcurrent
        set ConcurrentTarget = Concurrent

        # The head count is the wave's length times how fast this crowd dies, so
        # the wave runs about as long as WaveSecondsExact says it should.
        var Size : int = 1
        if (RoundedSize := Round[WaveSecondsExact * KillsPerSecondPerHostileOnScreen * Crowd / ToughnessFactor()]):
            set Size = RoundedSize
        if (Size < 1):
            set Size = 1

        # THE DOOR IS THE OTHER LIMIT. See SpawnTimeShareOfWave for the whole
        # reason. A wave may not ask for more hostiles than the spawn rate can
        # actually walk in inside the wave's own length, or the room runs on long
        # past the length it is aiming at and reads as endless.
        Deliverable := DeliverableThisWave()
        if (Size > Deliverable):
            Log("DEBUG: Wave trimmed from {Size} to {Deliverable} hostiles -- at one every {SpawnIntervalSeconds}s that is all that can arrive inside {WaveSecondsExact}s.")
            set Size = Deliverable

        set TargetThisWave = Size

        LiveCount := CountLiveHostiles()
        Log("DEBUG: Wave started -- Escalation Tier {CurrentTier}, {TargetThisWave} hostiles to spawn, up to {ConcurrentTarget} alive at once, {LiveCount} alive right now, types in play {UnlockedTypeNames()}")

        # Waking a spawner makes it produce one hostile of its own accord, so a
        # type the ramp has not admitted must not be woken: that is where the
        # Tank in room 1 came from, 2026-08-21. Each device is woken on the one
        # wave its type joins and never again, so the freebie lands on the wave
        # that type was going to arrive in anyway. Amendment 57.
        for (SlotIndex -> Spawner : AllSpawners()):
            if (CurrentTier = JoinTierFor(SlotIndex)):
                Spawner.Enable()

    # Verse drives the spawning. While this wave still owes hostiles, top the
    # arena up towards ConcurrentTarget, one Spawn() per tick.
    #
    # SAFETY VALVE. Spawn() reports nothing, so a spawn that silently fails
    # would leave this loop asking forever and the wave would never end. If the
    # loop has been asking for SpawnStallTimeoutSeconds with room in the arena
    # and nothing has arrived, it gives up loudly and shrinks the wave to what
    # actually spawned, so the run carries on instead of deadlocking.
    RunSpawnLoop()<suspends>:void =
        # Seconds spent asking for a hostile with room available and getting
        # none. Reset to zero every time one actually arrives.
        var StalledSeconds : float = 0.0
        var SpawnedAtLastCheck : int = 0

        loop:
            if (SpawnedThisWave >= TargetThisWave):
                return

            LiveCount := CountLiveHostiles()

            # A request that never lands would otherwise hold its slot for the
            # rest of the wave, so a reservation this old is written off.
            if (SpawnsInFlight > 0):
                set SecondsSinceArrival += SpawnIntervalSeconds
                if (SecondsSinceArrival >= SpawnArrivalTimeoutSeconds):
                    Log("WARNING: {SpawnsInFlight} requested hostile(s) never arrived after {SecondsSinceArrival}s. Releasing the reservation and asking again. Check that nothing else is despawning hostiles.")
                    set SpawnsInFlight = 0
                    set SecondsSinceArrival = 0.0

            if (LiveCount + SpawnsInFlight < ConcurrentTarget):
                # There is room, so a hostile should be arriving. Whether one
                # did since the last tick decides if this counts as a stall.
                if (SpawnedThisWave > SpawnedAtLastCheck):
                    set StalledSeconds = 0.0
                    set SpawnedAtLastCheck = SpawnedThisWave
                else:
                    set StalledSeconds += SpawnIntervalSeconds

                if (StalledSeconds >= SpawnStallTimeoutSeconds):
                    Log("WARNING: Wave gave up waiting for hostiles to spawn. Expected {TargetThisWave}, got {SpawnedThisWave}, after {StalledSeconds}s of asking with room in the arena. Continuing with what spawned. Check the spawner's Spawn Count and that Verse is the only thing driving it.")
                    set TargetThisWave = SpawnedThisWave
                    return

                SpawnNext()

            Sleep(SpawnIntervalSeconds)

    # How many of this spawner's hostiles are actually in the world right now.
    #
    # GetAgents hands back everything the device has created, and its
    # description does not promise that eliminated ones are dropped from that
    # list. So every agent is checked with IsActive, which succeeds only for a
    # character that is in the world and has not been eliminated.
    CountLiveHostiles()<transacts>:int =
        var Count : int = 0
        for:
            Spawner : AllSpawners()
            Hostile : Spawner.GetAgents()
            FortCharacter := Hostile.GetFortCharacter[]
            FortCharacter.IsActive[]
        do:
            set Count += 1
        Count

    # Waits for every hostile in this wave to be eliminated.
    #
    # SAFETY VALVE. A hostile that leaves the arena without firing
    # EliminatedEvent would leave this loop waiting on a count that can never be
    # reached. So an empty arena also clears the wave: if nothing at all is
    # alive for EmptyPollsToClear polls in a row, the wave is over whatever the
    # counter says, and it says so loudly.
    #
    # That valve is not armed until at least one hostile has been confirmed
    # alive during this wave. Freshly spawned hostiles read as not-yet-active
    # for around a second while they arrive, and without the guard the valve
    # fired on that gap and ended waves before the fight had started.
    AwaitWaveCleared()<suspends>:void =
        var EmptyPolls : int = 0

        # Arms the empty-arena valve. Stays false until something has actually
        # been seen alive, so an arena that is merely not populated YET can
        # never be mistaken for one that has been cleared.
        var HasSeenLiveHostile : logic = false

        loop:
            if (EliminatedThisWave >= TargetThisWave):
                return

            LiveCount := CountLiveHostiles()
            if (LiveCount = 0):
                set EmptyPolls += 1
            else:
                set EmptyPolls = 0
                set HasSeenLiveHostile = true

            if (HasSeenLiveHostile?):
                if (EmptyPolls >= EmptyPollsToClear):
                    Log("WARNING: Wave cleared because nothing is alive, but only {EliminatedThisWave} of {TargetThisWave} eliminations were counted. {TargetThisWave - EliminatedThisWave} hostiles left the arena without firing EliminatedEvent.")
                    return

            Sleep(PollSeconds)

    CompleteWave():void =
        # GDD 2.5's "loud game-show buzzer", sounded the instant the room is
        # clear and before the tier moves, so it marks what the player just did
        # rather than what comes next.
        WinBuzzer.Play()

        # A plain count of rooms, kept separate from the tier because the two
        # are different things: one is how far you have got, the other is how
        # hard it is.
        set RoomsWon += 1

        # GDD 2.1 STEP 6'S CASH WINDFALL. Paid before the tier moves, so the
        # room just finished is the room that sets the price.
        var BonusPaid : int = 0
        if (Rounded := Round[RoomBonusExact]):
            set BonusPaid = Rounded
        if (BonusPaid > 0):
            CashDrops.AddPrizeMoney(BonusPaid)
            Log("DEBUG: Room {RoomsWon} cleared -- sponsor payout {BonusPaid}")
        else:
            Log("WARNING: room {RoomsWon} cleared and paid nothing. RoomBonusAtTier1 is {RoomBonusAtTier1}, which rounds to zero.")

        # The next room is worth more than this one, with no ceiling.
        set RoomBonusExact = RoomBonusExact * (1.0 + RoomBonusGrowthPercent / 100.0)

        # THE TIER NUMBER CLIMBS FOR EVER NOW. It used to stop at MaxTier, which
        # left the banner reading ESCALATION TIER 21 for the whole back half of
        # an endless run, with no sense of progress at all. Amendment 92.
        set CurrentTier += 1

        # Wave length and crowd size still grow only while under GDD 5.3's
        # 40-bot wall, so Tiers 1-21 behave exactly as they always have. Past
        # the wall the crowd stops growing and toughness takes over as the
        # escalation lever, because the wall is the engine's and cannot be
        # argued with.
        if (CurrentTier <= MaxTier):
            Multiplier := 1.0 + TierScalingPercent / 100.0
            set ConcurrentExact = ConcurrentExact * Multiplier
            set WaveSecondsExact = WaveSecondsExact + WaveSecondsPerTier
            if (WaveSecondsExact > WaveSecondsMax):
                set WaveSecondsExact = WaveSecondsMax
        else:
            set EndlessHealthExact = EndlessHealthExact * (1.0 + EndlessToughnessPercent / 100.0)
            Log("DEBUG: Tier {CurrentTier} is past MaxTier {MaxTier} -- hostiles now arrive at {EndlessHealthExact} times base health")

        # Swap the hostile for the new tier now, in the gap between waves.
        ApplyTierDefinition()

        # After the tier has moved, so the banner names the tier being entered.
        # The payout is the room just won, which is why it was worked out above.
        spawn{ ShowBanner("ROOM WON!", "ESCALATION TIER {CurrentTier}", "SPONSOR PAYOUT: ${Commas(BonusPaid)}") }

    # GDD 2.5's Room Won, on screen. Built as a whole canvas per showing rather
    # than one kept and hidden, because a wave ends every couple of minutes at
    # most and a widget that is never removed is a widget that leaks.
    ShowBanner(TopLine : string, BottomLine : string, PayoutLine : string)<suspends>:void =
        # Taller than it was, by exactly the room the payout line needs. The
        # panel grew downwards from a centre moved a little lower rather than
        # the two existing lines being shifted, so the banner still lands where
        # Kai signed it off.
        Panel := color_block:
            DefaultColor := BannerPanelColor
            DefaultOpacity := 0.75
            DefaultDesiredSize := vector2{X := 700.0, Y := 230.0}

        Top := text_block:
            DefaultText := BannerLine(TopLine)
            DefaultTextColor := BannerTextColor
            DefaultTextSize := 64.0
            DefaultJustification := text_justification.Center

        Bottom := text_block:
            DefaultText := BannerLine(BottomLine)
            DefaultTextColor := BannerTextColor
            DefaultTextSize := 32.0
            DefaultJustification := text_justification.Center

        # Gold, matching the winnings readout in the HUD corner, so the eye ties
        # the two together without anything having to say they are the same
        # money. Amendment 36 leaves gold free: it is not a Layer 3 gameplay
        # colour, so it cannot be mistaken for something that hurts or heals.
        Payout := text_block:
            DefaultText := BannerLine(PayoutLine)
            DefaultTextColor := NamedColors.Gold
            DefaultTextSize := 32.0
            DefaultJustification := text_justification.Center

        BannerCanvas := canvas:
            Slots := array:
                canvas_slot:
                    Widget := Panel
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.462}, Maximum := vector2{X := 0.5, Y := 0.462}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                canvas_slot:
                    Widget := Top
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.42}, Maximum := vector2{X := 0.5, Y := 0.42}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                canvas_slot:
                    Widget := Bottom
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.49}, Maximum := vector2{X := 0.5, Y := 0.49}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                canvas_slot:
                    Widget := Payout
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.525}, Maximum := vector2{X := 0.5, Y := 0.525}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.5, Y := 0.5}

        # Every player who has a UI right now, so the banner is removed from
        # exactly the ones it was added to and nothing is left behind.
        var Shown : []player_ui = array{}
        for (P : GetPlayspace().GetPlayers(), UI := GetPlayerUI[P]):
            UI.AddWidget(BannerCanvas)
            set Shown += array{UI}

        Sleep(BannerSeconds)

        for (UI : Shown):
            UI.RemoveWidget(BannerCanvas)

        # The tier has already moved, so this fraction describes the room about
        # to start, not the one just cleared.
        NextFraction := RampFraction()

        var NextCrowd : float = ConcurrentExact * NextFraction
        if (NextCrowd > MaxConcurrentHostiles):
            set NextCrowd = MaxConcurrentHostiles

        var NextConcurrent : int = ConcurrentTarget
        if (RoundedConcurrent := Round[NextCrowd]):
            set NextConcurrent = RoundedConcurrent

        var NextSize : int = TargetThisWave
        if (RoundedSize := Round[WaveSecondsExact * KillsPerSecondPerHostileOnScreen * NextCrowd / ToughnessFactor()]):
            set NextSize = RoundedSize

        # The same door limit StartWave applies, so the banner's preview says the
        # number the next wave will really ask for rather than the untrimmed one.
        # WaveSecondsExact has already moved on to the next wave by here.
        NextDeliverable := DeliverableThisWave()
        if (NextSize > NextDeliverable):
            set NextSize = NextDeliverable

        Log("DEBUG: Wave cleared -- Escalation Tier is now {CurrentTier} of a maximum {MaxTier}, next wave {NextSize} hostiles at up to {NextConcurrent} alive at once, aiming at {WaveSecondsExact}s")

    # How much slower this tier's hostiles die than the base cards, as a
    # multiplier of one. The head count is divided by it, so a wave of tougher
    # hostiles is a smaller wave and still lands near WaveSecondsExact.
    #
    # WITHOUT THIS THE CEILING MEANS NOTHING. A Tier 21 hostile takes about five
    # times the bullets of a Tier 1 one, so a wave built to run 2m30 would really
    # run eight or ten minutes. Claude's call 2026-08-22, delegated by Kai.
    #
    # Read off the Swarmer ladder, because Swarmers are most of every crowd. A
    # type with a different number of cards steps at its own pace, which this
    # ignores on purpose: one representative figure is enough for a length that
    # is already an estimate.
    ToughnessFactor()<transacts>:float =
        var Result : float = 1.0
        Count := SwarmerDefinitions.Length
        if (Count > 0):
            Index := TierDefinitionIndex(Count)
            for (Step := 1..Index):
                set Result = Result * ToughnessPerCardStep

        # Amendment 92's endless toughness counts here too, and for the same
        # reason the cards do: past Tier 21 a hostile takes longer to kill, so
        # a room of the old size would run long and read as endless. Exactly 1
        # for the whole of Tiers 1-21, so this line changes nothing there.
        set Result = Result * EndlessHealthExact
        Result

    # Which entry in TierDefinitions the current tier falls into.
    #
    # The tier range is divided evenly across however many entries the list
    # holds. The block size is the largest number of tiers that still fits every
    # entry inside MaxTier, so five entries and MaxTier 21 gives blocks of four:
    # tiers 1-4, 5-8, 9-12, 13-16, and the last entry absorbing 17-21. Nothing
    # is hardcoded, so adding or removing entries just works.
    #
    # This counts up in blocks rather than dividing. Verse's integer division is
    # not something this file relies on anywhere, and with MaxTier at 21 these
    # loops are trivially short.
    TierDefinitionIndex(Count : int)<transacts>:int =
        # The largest block size that still fits Count blocks inside MaxTier.
        var BlockSize : int = 1
        for (Candidate := 1..MaxTier):
            if (Candidate * Count <= MaxTier):
                set BlockSize = Candidate

        # How many whole blocks the current tier is past. The loop stops at
        # Count - 1, so the top entry absorbs any leftover tiers and the result
        # can never point past the end of the list.
        var Index : int = 0
        for (Step := 1..Count - 1):
            if (Step * BlockSize <= CurrentTier - 1):
                set Index = Step

        Index

    # Points the spawner at the hostile definition for the current tier.
    #
    # Called once at OnBegin so entry 0 is in force from Tier 1, and again from
    # CompleteWave in the gap between waves when nothing is alive. That gap is
    # deliberate: the digest does not say whether swapping a definition affects
    # hostiles already in the arena, and doing it there means there are none for
    # the question to apply to.
    #
    # Does nothing at all when TierDefinitions is empty.
    ApplyTierDefinition():void =
        for (SlotIndex -> Spawner : AllSpawners()):
            Definitions := DefinitionsFor(SlotIndex)
            Count := Definitions.Length
            if (Count > 0):
                Index := TierDefinitionIndex(Count)
                if (Definition := Definitions[Index]):
                    if (Spawner.SetNPCCharacterDefinition[Definition]):
                        Log("DEBUG: Tier {CurrentTier} -- spawner {SlotIndex} set to card {Index} of {Count}")
                    else:
                        Log("WARNING: SetNPCCharacterDefinition was refused for spawner {SlotIndex}, card {Index}, at Tier {CurrentTier}. It fails when the character type differs, so check every card in that one list is the same type. Those hostiles stay as they were.")
                else:
                    Log("WARNING: Spawner {SlotIndex} has no card {Index} at Tier {CurrentTier}; it has {Count}. Those hostiles stay as they were.")

    # The four spawners in a fixed order: 0 Swarmer, 1 Boar, 2 Sentinel, 3 Tank.
    # Everything else in this file indexes off this order.
    AllSpawners()<transacts>:[]npc_spawner_device =
        array{SwarmerSpawner, BoarSpawner, SentinelSpawner, TankSpawner}

    AllShares()<transacts>:[]float =
        array{SwarmerShare, BoarShare, SentinelShare, TankShare}

    DefinitionsFor(SlotIndex : int)<transacts>:[]npc_character_definition =
        var Result : []npc_character_definition = SwarmerDefinitions
        if (SlotIndex = 1):
            set Result = BoarDefinitions
        else if (SlotIndex = 2):
            set Result = SentinelDefinitions
        else if (SlotIndex = 3):
            set Result = TankDefinitions
        Result

    # How many of one spawner's hostiles are alive, counted as a float because
    # it is only ever compared against a share of the concurrent target.
    LiveFor(Spawner : npc_spawner_device)<transacts>:float =
        var Count : float = 0.0
        for:
            Hostile : Spawner.GetAgents()
            FortCharacter := Hostile.GetFortCharacter[]
            FortCharacter.IsActive[]
        do:
            set Count = Count + 1.0
        Count

    # The room each type joins in, indexed by the AllSpawners order. Swarmers
    # are slot 0 and always in, so they answer 1.
    JoinTierFor(SlotIndex : int)<transacts>:int =
        var Result : int = 1
        if (SlotIndex = 1):
            set Result = BoarJoinsAtTier
        else if (SlotIndex = 2):
            set Result = SentinelJoinsAtTier
        else if (SlotIndex = 3):
            set Result = TankJoinsAtTier
        Result

    # How much of a full room the ramp allows right now, as a fraction of one.
    # The shares of the types that have joined, over the shares of all four. At
    # the default five-two-two-one that is 0.5 in room 1, 0.7 in room 2, 0.9 in
    # room 3 and 1.0 from room 4 on. It scales the density and the number to
    # clear together, so a thinner room is also a shorter one.
    #
    # Falls back to a full room if every share is zero, so a mistyped share list
    # can never silently empty the arena. SpawnNext already warns about that.
    RampFraction()<transacts>:float =
        var Total : float = 0.0
        var Unlocked : float = 0.0
        for (SlotIndex -> Share : AllShares()):
            set Total = Total + Share
            if (CurrentTier >= JoinTierFor(SlotIndex)):
                set Unlocked = Unlocked + Share
        var Result : float = 1.0
        if (Total > 0.0):
            if (Unlocked > 0.0):
                set Result = Unlocked / Total
        Result

    # The most hostiles the spawn rate can actually walk into the arena inside
    # one wave's length. See SpawnTimeShareOfWave for why a wave is capped by
    # this as well as by the kill-rate guess.
    #
    # THE DIVISION SITS IN THE IF BECAUSE EVERY DIVISION IN VERSE CAN FAIL,
    # floats included, and a spawn interval of zero would be one that did.
    DeliverableThisWave()<transacts>:int =
        var Result : int = 1
        if (SpawnIntervalSeconds > 0.0):
            if (Rounded := Round[WaveSecondsExact * SpawnTimeShareOfWave / SpawnIntervalSeconds]):
                set Result = Rounded
        if (Result < 1):
            set Result = 1
        Result

    # Which types the ramp has let in, for the log. Reading "types in play
    # Swarmer" in room 1 is how a playtest confirms the ramp is actually on.
    UnlockedTypeNames()<transacts>:string =
        Names := array{"Swarmer", "Boar", "Sentinel", "Tank"}
        var Result : string = ""
        for (SlotIndex -> Name : Names):
            if (CurrentTier >= JoinTierFor(SlotIndex)):
                if (Result.Length > 0):
                    set Result = "{Result}, {Name}"
                else:
                    set Result = Name
        Result

    # How many of this type a whole wave may contain, or false if it is not
    # rationed. The Swarmer (slot 0) is never rationed; the other three are, each
    # only until its own end tier.
    #
    # THE BOAR HAS ITS OWN END TIER, which is why it is tested before the block
    # below rather than inside it. It becomes ordinary at room 6 while the
    # Sentinel and the Tank stay rare until room 15. See BoarsOnArrival.
    QuotaFor(SlotIndex : int)<transacts>:?int =
        var Result : ?int = false
        if (SlotIndex = 1):
            if (CurrentTier < BoarsEndAtTier):
                if (CurrentTier <= BoarJoinsAtTier):
                    set Result = option{BoarsOnArrival}
                else:
                    set Result = option{BoarsWhileRare}
        else if (CurrentTier < RareTypesEndAtTier):
            if (SlotIndex = 2):
                if (CurrentTier <= SentinelJoinsAtTier):
                    set Result = option{SentinelsOnArrival}
                else:
                    set Result = option{SentinelsWhileRare}
            else if (SlotIndex = 3):
                if (CurrentTier <= TankJoinsAtTier):
                    set Result = option{TanksOnArrival}
                else:
                    set Result = option{TanksWhileRare}
        Result

    # Whether a type may take any more of the arena right now. Three ways to be
    # out: no share, not let in by the ramp yet, or this wave's quota used up.
    CanSpawnType(SlotIndex : int)<transacts>:logic =
        Shares := AllShares()
        var Result : logic = false
        if:
            Share := Shares[SlotIndex]
            Share > 0.0
            CurrentTier >= JoinTierFor(SlotIndex)
        then:
            set Result = true
            if:
                Quota := QuotaFor(SlotIndex)?
                Used := SpawnedByType[SlotIndex]
                Used >= Quota
            then:
                set Result = false
        Result

    # Spawns one hostile from whichever type is furthest below its share of the
    # arena. That keeps the mix at roughly five-two-two-one however the crowd is
    # thinned, rather than letting the player clear all the Swarmers and leave a
    # room of Tanks.
    #
    # THREE THINGS TAKE A TYPE OUT OF THE RUNNING: a share of zero, a type the
    # ramp has not let in yet, and a type that has used up this wave's quota.
    # Whichever types are left divide the whole crowd between them, so a rationed
    # Tank leaves Swarmers and Boars in its place rather than a hole.
    #
    # The early rooms are still thinner, but that now comes from RampFraction
    # cutting the crowd itself rather than from slots being left empty here.
    SpawnNext():void =
        Spawners := AllSpawners()
        Shares := AllShares()

        var TotalShare : float = 0.0
        for (SlotIndex -> Share : Shares):
            if (CanSpawnType(SlotIndex)?):
                set TotalShare = TotalShare + Share
        if (TotalShare <= 0.0):
            Log("WARNING: No hostile type can spawn. If every share is zero, set one of SwarmerShare, BoarShare, SentinelShare or TankShare above zero.")
            return

        var BestIndex : int = -1
        var BestDeficit : float = 0.0
        for (SlotIndex -> Spawner : Spawners):
            if:
                Share := Shares[SlotIndex]
                CanSpawnType(SlotIndex)?
            then:
                Deficit := ConcurrentNowExact * Share / TotalShare - LiveFor(Spawner)
                if (Deficit > BestDeficit):
                    set BestDeficit = Deficit
                    set BestIndex = SlotIndex

        if (Chosen := Spawners[BestIndex]):
            Chosen.Spawn()
            set SpawnsInFlight += 1

            # Rebuilt rather than assigned into by index, which is the form this
            # file already uses for arrays elsewhere.
            var Counted : []int = array{}
            for (SlotIndex -> Used : SpawnedByType):
                if (SlotIndex = BestIndex):
                    set Counted += array{Used + 1}
                else:
                    set Counted += array{Used}
            set SpawnedByType = Counted

    OnHostileSpawned(SpawnedAgent : agent):void =
        # Let this one through the doorways. See ArenaBarriers.
        for (Barrier : ArenaBarriers):
            Barrier.AddToIgnoreList(SpawnedAgent)

        # GDD 5.5's three metre safety radius. See HoldTheSafetyRadius.
        HoldTheSafetyRadius(SpawnedAgent)

        # Amendment 92's endless toughness. Does nothing at all for the whole of
        # Tiers 1-21. See ApplyEndlessToughness.
        ApplyEndlessToughness(SpawnedAgent)

        set SpawnedThisWave += 1
        set SecondsSinceArrival = 0.0
        if (SpawnsInFlight > 0):
            set SpawnsInFlight -= 1
        LiveCount := CountLiveHostiles()

        # WRITING TO A MAP CAN FAIL IN VERSE, so it cannot stand on a line of
        # its own and the line that follows hangs off it. This one writes the
        # hostile down as belonging to this run, so its eventual death counts
        # and a leftover's does not. Amendment 103.
        if (set SpawnedThisRun[SpawnedAgent] = true):
            Log("DEBUG: Hostile spawned -- {SpawnedThisWave} of {TargetThisWave} this wave, {LiveCount} alive now, {SpawnsInFlight} still on the way")
        else:
            Log("WARNING: a hostile arrived but could not be written down as this run's, so its death will be ignored and the wave will run short.")

    # =================================================================
    # GDD 5.5'S SAFETY RADIUS: "spawns are blocked within a 3-metre safety
    # radius of the player".
    #
    # IT WAS NEVER RUNNING, and the adversarial QA agent is what found that on
    # 2026-08-28. Standing the contestant on a spawner, eight robots arrived
    # inside the radius in one session, the closest at 124cm. Nothing anywhere
    # in this file had ever compared a spawn to where the contestant was.
    #
    # MOVED OUT RATHER THAN BLOCKED, and the difference matters. Refusing the
    # spawn is the literal reading, and it makes a hiding place: in room 1 the
    # Swarmer is the only type unlocked, so a contestant standing on its spawner
    # would silence the room entirely and the wave's stall timeout would give up
    # on it. Letting the robot arrive and then putting it at a fair distance
    # honours what the rule is for, which is not being hit before you have seen
    # anything, and it can never stall a wave.
    #
    # STRAIGHT OUT FROM THE CONTESTANT, then clamped into the arena so the fix
    # cannot push a robot through a wall. In a corner the clamp can pull one
    # back inside the radius; that is rare, it is better than a robot outside
    # the room, and the agent's INV-08 will say so if it happens.
    # =================================================================

    HoldTheSafetyRadius(SpawnedAgent : agent):void =
        if:
            Contestant := GetPlayspace().GetPlayers()[0]
            Standing := Contestant.GetFortCharacter[]
            Standing.IsActive[]
            Body := SpawnedAgent.GetFortCharacter[]
        then:
            Mine := Standing.GetTransform().Translation
            Theirs := Body.GetTransform().Translation

            DX := Theirs.X - Mine.X
            DY := Theirs.Y - Mine.Y
            Gap := Sqrt(DX * DX + DY * DY)

            if (Gap < SafetySpawnRadius):
                # STRAIGHT OUT FROM THE CONTESTANT IS NOT ENOUGH, AND THE FIRST
                # VERSION OF THIS ONLY LOOKED AS IF IT WORKED. Amendment 111.
                #
                # It pushed the robot along the line away from the contestant and
                # then held that point inside the arena. With the contestant
                # standing AT a wall, away from them is out of the room, so the
                # hold pulled the robot straight back to the wall and put it
                # beside them again. The adversarial tester parked the contestant
                # at the west wall and caught five arrivals still inside the
                # radius a quarter second later, at 80cm to 152cm.
                #
                # AND THE LOG LINE HID IT, which is worth as much as the fix.
                # It printed SafeSpawnDistance, the distance it had ASKED for,
                # rather than the distance it got. Six lines a run said "moved
                # out to 450cm" while the robot was standing at 80.
                #
                # EIGHT DIRECTIONS AND THE BEST ONE WINS. Every compass point is
                # tried, each held inside the room, and the one that ends up
                # furthest from the contestant is used. Against a wall that is
                # along it or into the room; in the open it is much the same as
                # the old straight-out push.
                var BestX : float = Theirs.X
                var BestY : float = Theirs.Y
                var BestGap : float = Gap

                for (Way : CompassDirections()):
                    TryX := HeldInside(Mine.X + Way(0) * SafeSpawnDistance, ArenaHalfLength - SpawnInset)
                    TryY := HeldInside(Mine.Y + Way(1) * SafeSpawnDistance, ArenaHalfWidth - SpawnInset)
                    OffX := TryX - Mine.X
                    OffY := TryY - Mine.Y
                    Reach := Sqrt(OffX * OffX + OffY * OffY)
                    if (Reach > BestGap):
                        set BestGap = Reach
                        set BestX = TryX
                        set BestY = TryY

                Pushed := vector3{X := BestX, Y := BestY, Z := Theirs.Z}

                if (Body.TeleportTo[Pushed, IdentityRotation()]):
                    if (BestGap >= SafetySpawnRadius):
                        Log("DEBUG: Hostile arrived {Gap}cm away, inside GDD 5.5's {SafetySpawnRadius}cm safety radius. Moved to {BestGap}cm.")
                    else:
                        Log("WARNING: a hostile arrived {Gap}cm from the contestant and the best spot in the room is only {BestGap}cm away. The contestant is cornered somewhere the radius will not fit.")
                else:
                    Log("WARNING: a hostile arrived {Gap}cm from the contestant and could NOT be moved out of the safety radius.")

    # The eight compass points as unit directions, as pairs of X and Y. The
    # diagonals are one over the square root of two, which is what makes all
    # eight the same length and so all eight land the same distance out.
    CompassDirections()<transacts>:[]tuple(float, float) =
        array:
            (1.0, 0.0)
            (-1.0, 0.0)
            (0.0, 1.0)
            (0.0, -1.0)
            (0.7071, 0.7071)
            (0.7071, -0.7071)
            (-0.7071, 0.7071)
            (-0.7071, -0.7071)

    # PAST TIER 21, TOUGHNESS IS THE ESCALATION LEVER. See EndlessToughnessPercent.
    #
    # Raised on the body the moment it arrives, rather than through the tier
    # definition cards, because the cards run out at Tier 21 and an endless run
    # does not. It is also the only route: a card's health lives in the asset
    # and no script can edit one.
    #
    # The digest is plain about what SetMaxHealth does. MaxHealth "will be
    # clamped between 1.0 and Inf", and current health is "scaled up or down
    # based on the scale difference", so a robot raised the instant it spawns
    # arrives at full rather than at a fraction of its new maximum.
    ApplyEndlessToughness(SpawnedAgent : agent):void =
        if (EndlessHealthExact > 1.0):
            if (Body := SpawnedAgent.GetFortCharacter[]):
                Body.SetMaxHealth(Body.GetMaxHealth() * EndlessHealthExact)
            else:
                Log("WARNING: a hostile arrived with no character to raise the health of, so it fights at base toughness in Tier {CurrentTier}.")

    # Holds one coordinate inside plus or minus Limit.
    HeldInside(Value : float, Limit : float)<transacts>:float =
        var Held : float = Value
        if (Held > Limit):
            set Held = Limit
        if (Held < -Limit):
            set Held = -Limit
        Held

    OnHostileEliminated(Result : device_ai_interaction_result):void =
        # Taken off the ignore lists again, so a long run does not leave them
        # holding an entry for every hostile it ever spawned.
        if (DeadHostile := Result.Target?):
            for (Barrier : ArenaBarriers):
                Barrier.RemoveFromIgnoreList(DeadHostile)

        # LAST RUN'S ROBOTS DO NOT COUNT TOWARDS THIS ONE. Amendment 103.
        #
        # Clearing the arena at the end of a run kills everything left standing,
        # and those deaths arrive as ordinary eliminations moments later, inside
        # the run that has just started. In the 2026-08-28 playtest the first
        # three "kills" of a restarted run were leftovers, none of them shot at,
        # and the wave counter later reached MINUS THREE because it had counted
        # deaths that were never part of it.
        #
        # A hostile this run has not seen spawn is not this run's business.
        if (DeadHostile := Result.Target?, not SpawnedThisRun[DeadHostile]?):
            Log("DEBUG: Ignoring the elimination of a hostile that was not spawned this run. It belonged to the last one.")
            return

        set EliminatedThisWave += 1
        set RunEliminations += 1
        Remaining := TargetThisWave - EliminatedThisWave
        LiveCount := CountLiveHostiles()
        Log("DEBUG: Hostile eliminated -- {Remaining} left in this wave, {LiveCount} alive now")
