# ShotgunKnockback.verse
#
# GDD Section 3.3's weapon table, the Shotgun row: "Wide horizontal 5-pellet
# red-mist spread... CHAIN KNOCKBACK: High-impact blasts stagger enemies and
# launch armored Cyber-Boars backward into other hostiles."
#
# WHAT THIS IS FOR. Kai asked why a shotgun blast only ever kills one robot and
# whether it could kill several. The answer on 2026-08-26 was no: cutting through
# a line of hostiles belongs to the Sponsor Sniper's piercing beam, and the
# shotgun's job is to SHOVE.
#
# THAT RULING WAS REVERSED ON 2026-08-27, amendment 88. Kai played it and asked
# again, and the GDD's own shotgun row does ask for a "wide horizontal 5-pellet
# red-mist spread" as well as the chain knockback. So this file now does both:
# the shove, unchanged, and a FAN that catches everything in a wide short wedge
# in front of the contestant for half the blast.
#
# THE SNIPER KEEPS ITS JOB, and it is the SHAPE that protects it rather than a
# refusal. The fan is wide and short, eight metres of crowd standing on top of
# you. The beam is narrow and long, twenty-five metres across the arena. Neither
# does the other's work.
#
# WHY IT CANNOT SIMPLY ASK WHAT GUN IS IN THE CONTESTANT'S HANDS. Verse is told
# that a robot was hurt, by whom, and by how much. It is NOT told what hurt it.
# `damage_result` carries a Source typed as `game_action_causer`, an interface
# the contestant's own character satisfies, and there is no weapon anywhere on
# it. Checked in the digest, not guessed.
#
# SO THE SHOTGUN IS TOLD APART BY ITS BURST. Amendment 89, and it closed a gap
# Kai asked about directly: "this only applied to my shotgun right?" Three of the
# contestant's hits inside one tenth of a second is a blast and cannot be
# anything else, because a shotgun sprays its pellets in a single frame and every
# other gun here puts one thing on target at a time.
#
# TWO EARLIER ANSWERS, BOTH RETIRED, both worth keeping written down.
#
# The first was "the last gun a crate handed over", Kai's ruling of 2026-08-26.
# It cost this: take a shotgun from a crate, switch back to the pistol by hand,
# and the pistol shoved until another crate handed over a different gun. Nothing
# in Verse can see that switch. That is the gap amendment 89 closes.
#
# The second was Kai's own better idea the same day, a damage WINDOW rather than
# a floor, on the reasoning that a sniper round lands above the band and the
# pistol below it. THE LOG KILLED IT. Before building anything on 2026-08-27 the
# real numbers were read out: the shotgun does 23 a pellet and THE DRUM GUN DOES
# EXACTLY 23 TOO. No band holds one without the other. The idea was sound and the
# weapons defeated it.
#
# THE BOAR IS LAUNCHED, EVERYTHING ELSE IS STAGGERED, which is the GDD's own
# wording. The difference is BoarForceMultiplier and nothing more: same shove,
# harder. Which spawner a hostile came from is what says whether it is a Boar,
# because the four spawners are one per type in a fixed order.

using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/Diagnostics }
# VERSE.ORG'S SPATIAL MATHS, NOT THE TEMPORARY ONE, and the difference is not
# cosmetic. Two modules each define a vector3 and they are different types.
# ApplyLinearImpulse takes Verse.org's; a transform read off a character hands
# back the Temporary one. The first build refused the file over exactly that, so
# the impulse below is built fresh from plain numbers rather than passed along.
using { /Verse.org/SpatialMath }
using { /Verse.org/Simulation }

shotgun_knockback_manager := class(creative_device):

    # =================================================================
    # WIRING
    # =================================================================

    # The four spawners, in the SAME ORDER Wave Manager uses: Swarmer, Boar,
    # Sentinel, Tank. The order is what identifies a Boar, so getting it wrong
    # here launches the wrong robot rather than failing loudly.
    @editable
    SwarmerSpawner : npc_spawner_device = npc_spawner_device{}

    @editable
    BoarSpawner : npc_spawner_device = npc_spawner_device{}

    @editable
    SentinelSpawner : npc_spawner_device = npc_spawner_device{}

    @editable
    TankSpawner : npc_spawner_device = npc_spawner_device{}

    # Asked which gun a crate handed over last. See the header for why this
    # stands in for "what is being held".
    @editable
    Crates : crate_manager = crate_manager{}

    # =================================================================
    # DIALS
    # =================================================================

    # WHICH REWARD NUMBER IS THE SHOTGUN. A weapon number is a SLOT, not a gun:
    # 1 is whatever GranterRisingStar holds, which is the Radical Pump today. If
    # the guns are ever shuffled between granters, this number moves with the
    # shotgun and nothing else here changes.
    @editable
    ShotgunSlot : int = 1

    # How hard the shove is. This is an impulse, so it is divided by the robot's
    # own mass before it moves anything: a heavy Tank will travel less than a
    # Swarmer on the same number, which is the behaviour we want and not
    # something to correct for.
    # 180000 FROM 2026-08-27, DOUBLED. Kai on the fan: "the enemies need to fall
    # back". They were already being shoved at 90000 and it was not reading as a
    # shove, so the figure was simply too small to see under a crowd. This is the
    # one dial behind both the direct hit and every robot the fan catches.
    #
    # 450000 ON 2026-08-28, AND THE SCRIPT AND THE DEVICE HAD DRIFTED APART
    # AGAIN. The placed device was carrying 900000, five times what this file
    # said, and the 2026-08-28 log has every shove printing 900000 while this
    # default sat at 180000 being ignored.
    #
    # WHY IT MATTERS MORE THAN THE USUAL DRIFT. 900000 throws a robot clean out
    # of the room. Once it is out there it cannot path back in, so the wave
    # cannot finish until amendment 100's rescue teleports it back, and a robot
    # arriving out of nothing is the thing Kai has already objected to twice.
    # The shove was quietly manufacturing the problem the rescue exists to fix.
    #
    # 450000 IS BETWEEN THE TWO KNOWN POINTS. 180000 was already a doubling and
    # still did not read as a shove under a crowd; 900000 reads, and overshoots
    # the arena. The room is only 21 metres by 11, so there is not much room
    # between a shove you can see and a robot in the next postcode.
    @editable
    KnockbackForce : float = 450000.0

    # The Boar is LAUNCHED rather than staggered, per the GDD. Everything else
    # gets the plain figure above.
    @editable
    BoarForceMultiplier : float = 2.2

    # A little of the shove goes upward, so a staggered robot lifts off the
    # floor rather than skidding along it. Too much and they sail, which reads
    # as comedy rather than impact.
    @editable
    UpwardShare : float = 0.25

    # A robot cannot be shoved again until this many seconds have passed. An
    # automatic shotgun blast lands several pellets in one press, and without
    # this each pellet shoves again and the robot rockets away.
    @editable
    ShoveCooldownSeconds : float = 0.35

    # -- the fan, amendment 88 -----------------------------------------
    #
    # GDD 3.3's shotgun row asks for a "wide horizontal 5-pellet red-mist
    # spread", and until 2026-08-27 only the CHAIN KNOCKBACK half of that row was
    # built. Kai on 2026-08-26 ruled that killing several robots at once was the
    # sniper's job and the shotgun's job was to shove; on 2026-08-27, after
    # playing it, Kai reversed that and asked for the spread as well. The shove
    # is untouched and still fires exactly as before.
    #
    # THE SNIPER'S JOB IS PROTECTED BY THE SHAPE, not by refusing to build this.
    # The fan is wide and SHORT; the beam is narrow and LONG. Cutting a line
    # across the arena is still the Sponsor Sniper's and nothing else's.

    # How wide the fan is, in degrees either side of the line to the robot that
    # was actually hit. 80 makes a 160-degree fan, which is nearly everything in
    # front of the contestant. Kai asked for wider than the first offer.
    @editable
    FanHalfAngleDegrees : float = 80.0

    # How far the fan reaches, in centimetres. 800 is eight metres.
    #
    # 500 WAS TRIED FIRST AND KAI SAID "5m feels too short still, it needs to be
    # a big arc". The arena is about 21 metres by 11, so eight metres of
    # 160-degree fan is most of what is in front of the contestant without being
    # the whole room. The beam still reaches three times further.
    @editable
    FanRange : float = 800.0

    # What a robot caught in the fan takes, as a share of the hit that set the
    # fan off.
    #
    # A SHARE OF ONE PELLET, NOT OF THE BLAST, AND THAT IS WHY THIS IS 4 AND NOT
    # A HALF. A shotgun reports each pellet as its own hit: the 2026-08-27 log
    # has 170 hits of exactly 23 damage. So Kai's ruling of "half the blast"
    # written as 0.5 was really half a PELLET, about 11 damage, which is nothing
    # against a robot. A blast is roughly eight pellets, so half a blast is about
    # four pellets, and 4.0 is that. Raising this raises what the fan does; it
    # does not change what the robot actually shot takes, which is Fortnite's.
    #
    # 2.0 FROM 4.0 ON 2026-08-28, WHICH IS A QUARTER BLAST. Kai's ruling, and it
    # revises the half-blast one of 2026-08-27 rather than misreading it. The
    # reason is the knockback: at four pellets the fan measured around 400 a
    # robot in the log, almost nothing survived it, and Kai could not see any of
    # them being thrown because they were all dead before they moved. A shove
    # only reads on something still standing.
    #
    # WHAT IT TRADES. The shotgun kills fewer things per blast and becomes a
    # crowd-shover rather than a crowd-clearer. That is the trade Kai took
    # knowingly, having been offered one pellet as well.
    @editable
    # 2.0 -> 0.5, Kai 2026-08-29: "the whole group around me dies in one blast."
    # This revises amendment 88a's quarter blast, which itself revised
    # amendment 88's half. The reach is deliberately untouched: 80 degrees
    # either side at 8 metres is most of the room, and that is what makes the
    # shove read as a shove. What was wrong was that the same arc was also
    # lethal, so a blast cleared the crowd instead of scattering it. Half a
    # pellet leaves them thrown off their feet and still coming.
    FanDamageShare : float = 0.5

    # The most robots one blast may catch besides the one it actually hit.
    @editable
    MaxFanned : int = 8

    # -- telling the shotgun apart by ITS BURST, amendment 89 -----------
    #
    # THIS IS WHAT RUNS NOW. Both earlier answers are below it and both are
    # retired; they are kept because the paragraphs are the only record of why
    # each was wrong, and because deleting a wired @editable unwires it.
    #
    # THE TELL IS THE PELLETS, NOT THE DAMAGE. A shotgun sprays several pellets
    # that all land in the same instant. Every other gun in this game puts one
    # thing on target at a time: the pistol one bullet, the sniper one round, the
    # rocket one blast, the drum gun one bullet every ninth of a second. So
    # counting hits inside a single clock tick separates them with nothing to
    # tune per weapon and nothing that breaks when a crate gun is swapped.
    #
    # THE DAMAGE WINDOW BELOW CANNOT WORK, AND THE LOG IS WHY. Kai asked on
    # 2026-08-27 to close the last-gun gap, and the numbers were read out of the
    # 2026-08-27 log before building anything: the shotgun does 23 a pellet AND
    # THE DRUM GUN DOES EXACTLY 23 TOO, 53 hits of it. There is no band that
    # holds one and not the other. The idea was sound and the weapons defeated
    # it.
    #
    # WHAT THE LOG ALSO SETTLED. The pistol reads 25 on a body and 50 on a head.
    # The shotgun's pellets fall off with distance, from 23 down through 22.3,
    # 11.5, 10.5, 9.9 and 9.1, which is another reason a damage band was never
    # going to hold it.
    #
    # 3 RATHER THAN 2, and rather than 8. A blast is about eight pellets but not
    # all of them connect, and at range only a few do. Two would let a drum gun
    # through on a tick that happened to hold two bullets. Three has never been
    # reached by anything else in the log.
    @editable
    PelletsForBlast : int = 3

    # RETIRED. KAI'S IDEA, 2026-08-26, AND IT WAS BETTER THAN THE RULING IT
    # REPLACED, but the log above shows it cannot be made to work.
    # The first answer here was "the last gun a crate handed over", chosen
    # because an earlier suggestion of mine, shove on anything above a set
    # force, could not be aimed: a sniper round always beats a shotgun blast, so
    # any floor that lets one through lets the other through too.
    #
    # A WINDOW CAN BE AIMED WHERE A FLOOR CANNOT. A sniper round lands ABOVE the
    # window and the pistol BELOW it, so a band picks the shotgun out where a
    # floor never could. It also fixes what the last-gun rule could not: a
    # contestant who takes a shotgun and then switches back to the pistol by
    # hand, which nothing in Verse can see.
    #
    # NO LONGER USED. The three fields below are read by nothing. Ticking
    # UseDamageWindow does nothing at all; the pellet count above is the only
    # test. Left in place so the placed device stays wired.
    @editable
    UseDamageWindow : logic = false

    @editable
    MinShotgunDamage : float = 0.0

    @editable
    MaxShotgunDamage : float = 0.0

    # Prints the damage of every hit. It filled in the numbers quoted above and
    # is what proved the damage window could never work, so it has earned its
    # keep. Switch it off when the shotgun is left alone: it prints a line per
    # pellet.
    @editable
    LogEveryHit : logic = true

    @editable
    LogShoves : logic = true

    # =================================================================
    # HIT FEEDBACK (BUILD_ORDER item 31, Kai's ruling 2026-08-29)
    # =================================================================
    #
    # WHAT WAS ASKED FOR AND WHAT UEFN GIVES. Item 31 asked for three things:
    # screen shake, a few frames of freeze on impact, and hostiles flashing
    # white when hit. Only the third has any route at all in this build, and not
    # the literal one:
    #
    #   * NO SCREEN SHAKE. gameplay_camera_device exposes Enable, Disable, and
    #     adding and removing itself from an agent's camera stack. Nothing that
    #     moves it. Jolting a camera device about was the only alternative and
    #     Kai turned it down as something that would look wrong.
    #   * NO FREEZE. There is no time dilation anywhere in the digest. The only
    #     lever is how fast robots walk, which the Death Save already uses for
    #     its slow motion, and borrowing it for every bullet would blunt the one
    #     moment the game slows down on purpose.
    #   * NO WHITE FLASH. A robot cannot be tinted; amendment 49's finding that
    #     an NPC character definition has no colour setting still stands, and
    #     Character Cosmetic picks an outfit rather than a shade.
    #
    # So this is a spark burst on the robot instead, the same device and the
    # same trick the death sparks in hello_world_device.verse already use, but
    # fired on a hit rather than on a kill.
    #
    # A POOL, NOT ONE DEVICE. A VFX creator can only be in one place, and a
    # shotgun lands pellets on several robots inside a tenth of a second. One
    # device would be dragged across the arena mid-burst and the effect would
    # read as a smear. Each hit takes the next one in the list and they come
    # round again. Three or four is plenty; leave the list empty and nothing
    # happens at all, which is the behaviour before today rather than a fault.
    @editable
    HitSparks : []vfx_creator_device = array{}

    # Off switch, so the whole thing can be turned off from the device without
    # emptying the list and losing the wiring.
    @editable
    ShowHitSparks : logic = true

    # How long one burst stays up. Short on purpose: this is punctuation on a
    # bullet, not an event, and GDD 5.5 wants a locked 60 FPS with a hundred
    # props to spare.
    @editable
    HitSparkSeconds : float = 0.12

    # How long before the SAME robot can spark again. A shotgun press lands
    # several pellets on one robot and each one comes back as its own damage
    # event, so without this a single press would fire the whole pool at one
    # robot. Sits just under the shove's own cooldown.
    @editable
    HitSparkCooldownSeconds : float = 0.15

    # HOW LONG THE BURST LASTS WHEN THE PISTOL IS IN HAND.
    #
    # Kai, 2026-08-29: "i did but only for the shot gun knockback." The spark
    # always fired for every gun; a tenth of a second is simply too brief to
    # notice on one pistol shot, while a shotgun blast lights several robots at
    # once and cannot be missed. Kai asked for the longer burst on the pistol
    # alone.
    @editable
    PistolHitSparkSeconds : float = 0.25

    # HOW THE PISTOL IS RECOGNISED, AND WHY IT TAKES A WHOLE DEVICE.
    #
    # Fortnite will not say what is in a player's hands. GetLastWeaponSlot only
    # remembers which gun a crate last handed over, so once any crate weapon has
    # been picked up it can never say the pistol is back in hand. The one thing
    # in the build that can answer is conditional_button_device.IsHoldingItem,
    # established 2026-08-23.
    #
    # PLACE ONE OUTSIDE THE ARENA and put the Pulse Blaster in its first key item
    # slot. Nobody walks up to it and nothing is pressed; it is asked a question
    # and nothing more. Left empty every hit gets the short burst, which is the
    # behaviour before today rather than a fault.
    @editable
    PistolCheck : conditional_button_device = conditional_button_device{}

    # Which key item slot on that device holds the Pulse Blaster. The device has
    # three, numbered from 0.
    @editable
    PistolKeyItemIndex : int = 0


    # =================================================================
    # STATE
    # =================================================================

    # Every hostile that has been subscribed, so a second subscription is never
    # made for the same one. A hostile subscribed twice is shoved twice per hit.
    var Watched : [agent]logic = map{}

    # When each hostile was last shoved, against SecondsElapsed below.
    var LastShoveAt : [agent]float = map{}

    # When each hostile last sparked. Its own record rather than a share of
    # LastShoveAt: the shove is the shotgun's alone and the sparks belong to
    # every gun, so one cooldown could not serve both.
    var LastSparkAt : [agent]float = map{}

    # Which device in HitSparks the next hit will use.
    var NextSpark : int = 0

    # A clock of our own. Verse has no "seconds since the match began" that can
    # be read on demand, so one is counted here.
    var SecondsElapsed : float = 0.0

    # Up for the length of one fan. The fan's own damage comes back through
    # DamagedEvent, and without this a blast would fan, and every robot the fan
    # caught would fan again, without end. The sniper's beam guards itself the
    # same way with its Piercing flag.
    var Fanning : logic = false

    # When the last fan went out. One fan per BLAST, not one per robot the
    # pellets happened to find, which is a different thing from LastShoveAt
    # above: that one is per robot.
    var LastFanAt : float = -100.0

    # How many of the contestant's hits have landed inside the clock tick that is
    # running now. Zeroed by RunClock every tenth of a second. Amendment 89: this
    # is what tells the shotgun apart, because a blast puts all its pellets in one
    # instant and no other gun in this game puts more than one thing on target at
    # a time.
    var HitsThisTick : int = 0

    OnBegin<override>()<suspends>:void =
        for (Spawner : AllSpawners()):
            Spawner.SpawnedEvent.Subscribe(OnHostileSpawned)

        Log("DEBUG: Shotgun knockback listening. A blast is {PelletsForBlast} hits in one tenth of a second. Fan {FanHalfAngleDegrees} degrees either side, {FanRange} out, at {FanDamageShare}x a pellet.")

        spawn{ RunClock() }

    # THE TICK IS THE INSTANT, and a tenth of a second is the right size for it.
    # A blast's pellets all land in one frame, well inside one tick. A drum gun
    # at nine rounds a second lands about one per tick and can never reach three.
    RunClock()<suspends>:void =
        loop:
            Sleep(0.1)
            set SecondsElapsed = SecondsElapsed + 0.1
            set HitsThisTick = 0

    AllSpawners()<transacts>:[]npc_spawner_device =
        array{SwarmerSpawner, BoarSpawner, SentinelSpawner, TankSpawner}

    # Every robot the four spawners have ever made, live or not. The fan checks
    # IsActive on each as it goes, the same way the sniper's beam does.
    LiveHostiles()<transacts>:[]agent =
        var Found : []agent = array{}
        for (Spawner : AllSpawners()):
            set Found = Found + Spawner.GetAgents()
        Found

    # =================================================================
    # WATCHING FOR HITS
    # =================================================================

    OnHostileSpawned(Spawned : agent):void =
        # ONE SUBSCRIPTION PER HOSTILE, EVER. The same lesson the crate's fire
        # trigger cost a playtest to learn: subscribe twice and every hit counts
        # twice.
        if (Watched[Spawned]):
            return

        if (set Watched[Spawned] = true):
            Log("DEBUG: Watching a new hostile for shotgun hits.")

        if (Character := Spawned.GetFortCharacter[]):
            Character.DamagedEvent().Subscribe(OnHostileDamaged)

    OnHostileDamaged(Result : damage_result):void =
        # OUR OWN FAN COMING BACK AT US. See the Fanning flag.
        if (Fanning?):
            return

        # THE TUNING LINE. Play a minute with each gun, then read the real
        # numbers off the log and set the window with them.
        if (LogEveryHit?):
            Log("DEBUG: Hit for {Result.Amount} damage. Last crate gun was slot {Crates.GetLastWeaponSlot()}.")

        # NOT OUR DOING, NOTHING HAPPENS. Kai's question found this: the shove
        # used to fire on ANY damage a robot took. A robot shot by another
        # robot, or caught by the splash of the contestant's own rocket landing
        # nearby, was shoved just the same, as long as the last crate gun had
        # been the shotgun. Checked first because it is the cheapest of the two.
        if (not DamageWasOurs(Result)?):
            return

        # COUNTED BEFORE IT IS JUDGED. This has to come after DamageWasOurs, or a
        # robot shot by another robot would pad the count towards a blast that
        # never happened. Amendment 89.
        set HitsThisTick = HitsThisTick + 1

        # THE SPARK ON A HIT. Above the shotgun test on purpose: this belongs to
        # every gun the contestant carries, and everything below this point is
        # the shotgun's alone.
        #
        # A HIT THAT DID NOTHING GETS NOTHING. The log is full of "Hit for
        # 0.000000 damage", which is a robot already on its way out or a shot
        # that landed on something that could not be hurt. Sparking those would
        # light up robots that never took the shot.
        if (ShowHitSparks?, Result.Amount > 0.0):
            if (Struck := fort_character[Result.Target], Robot := Struck.GetAgent[], SparkIsDue(Robot)?):
                SparkOn(Struck, Robot)

        # NOT THE SHOTGUN, NOTHING HAPPENS.
        if (not IsShotgunHit(Result)?):
            return

        if (Hurt := fort_character[Result.Target]):
            if (Victim := Hurt.GetAgent[]):
                # The cooldown, so one press of a shotgun does not shove once
                # per pellet.
                if (Last := LastShoveAt[Victim], SecondsElapsed - Last < ShoveCooldownSeconds):
                    return

                if (set LastShoveAt[Victim] = SecondsElapsed):
                    Shove(Hurt, Victim)

                    # ONE FAN PER BLAST. A shotgun press lands several pellets,
                    # and they can find more than one robot, so the shove's
                    # per-robot cooldown is not enough on its own.
                    if (SecondsElapsed - LastFanAt >= ShoveCooldownSeconds):
                        set LastFanAt = SecondsElapsed
                        FanOut(Hurt, Victim, Result.Amount)

    # Has this robot's spark cooled down? See HitSparkCooldownSeconds: one
    # shotgun press arrives as several separate hits on the same robot, and
    # without this the whole pool would fire at one of them.
    SparkIsDue(Robot : agent)<transacts>:logic =
        if (Last := LastSparkAt[Robot], SecondsElapsed - Last < HitSparkCooldownSeconds):
            false
        else:
            true

    # Takes the next device in the pool and sends it to the robot that was hit.
    SparkOn(Struck : fort_character, Robot : agent):void =
        Count := HitSparks.Length
        if (Count > 0, Device := HitSparks[NextSpark]):
            if (set LastSparkAt[Robot] = SecondsElapsed):
                set NextSpark = NextSpark + 1
                if (NextSpark >= Count):
                    set NextSpark = 0
                spawn{ BurstHitSpark(Device, Struck) }

    # Up the robot's body rather than at its feet, and read fresh at the moment
    # of the hit so a robot that is walking is sparked where it now stands.
    #
    # GetViewLocation IS DOING THE HEIGHT, AND THAT IS WHY THERE IS NO DIAL FOR
    # IT. It is where the robot is looking from, so it lands around the head and
    # shoulders, which is what makes this read as a bullet going in rather than
    # something landing at its feet. Building a raised point by hand needs a
    # vector3, and this file cannot spell one: the header explains that it uses
    # Verse.org's spatial maths for the impulse, whose vector3 is a different
    # type from the one TeleportTo wants, and naming the other module in full was
    # refused by the compiler as well. Taking a location the engine already hands
    # back sidesteps the whole argument, and the rotation comes off the robot's
    # own transform for the same reason.
    BurstHitSpark(Device : vfx_creator_device, Struck : fort_character)<suspends>:void =
        Standing := Struck.GetTransform()
        if (Device.TeleportTo[Struck.GetViewLocation(), Standing.Rotation]):
            Device.Begin()
            Sleep(SparkSecondsNow())
            Device.End()

    # Long for the pistol, short for everything else. See PistolCheck: if that
    # device is not placed the question cannot be asked, the answer is no, and
    # every gun gets the short burst.
    SparkSecondsNow()<transacts>:float =
        if (Contestant := FirstContestant()?, Holder := agent[Contestant], PistolCheck.IsHoldingItem[Holder, PistolKeyItemIndex]):
            PistolHitSparkSeconds
        else:
            HitSparkSeconds

    # Did the contestant cause this hit?
    #
    # WHAT AN INSTIGATOR IS. A damage_result names who set the damage off, as a
    # game_action_instigator, which is an interface a character satisfies rather
    # than a player. So it is turned back into a character, then into an agent,
    # and compared against the contestant.
    #
    # NO INSTIGATOR MEANS NO. Damage from the environment or from code carries
    # nothing at all here, and none of that is the contestant's shotgun.
    DamageWasOurs(Result : damage_result)<transacts>:logic =
        if:
            Instigator := Result.Instigator?
            Causer := fort_character[Instigator]
            Blamed := Causer.GetAgent[]
            Contestant := FirstContestant()?
            Ours := agent[Contestant]
            Blamed = Ours
        then:
            true
        else:
            false

    # Was this hit the shotgun's?
    #
    # Two answers, and the window is the better one once it has real numbers in
    # it. A window of zero to zero would refuse everything, so a window that has
    # not been filled in falls back rather than silently switching the feature
    # off.
    # AMENDMENT 89: THE BURST IS THE ANSWER. Three of the contestant's hits
    # inside one tenth of a second is a shotgun blast and cannot be anything
    # else. See PelletsForBlast for why the two earlier tests were retired, and
    # why 3.
    #
    # THE THIRD PELLET IS WHAT FIRES, NOT THE FIRST. All of them land in the same
    # frame, so nothing is visibly late, and the shove that used to go off on a
    # single pistol shot no longer does.
    IsShotgunHit(Result : damage_result)<transacts>:logic =
        if (HitsThisTick >= PelletsForBlast):
            return true
        false

    # =================================================================
    # THE SHOVE
    # =================================================================

    Shove(Hurt : fort_character, Victim : agent):void =
        # AWAY FROM THE CONTESTANT, not away from the bullet. There is no impact
        # point on a damage_result, and the contestant is where the blast came
        # from anyway, so the line between the two is the direction of the shove.
        # It is also the line that sends a Boar back into whatever is behind it,
        # which is the whole trick the GDD asks for.
        if (Contestant := FirstContestant()?, Shooter := Contestant.GetFortCharacter[]):
            From := Shooter.GetTransform().Translation
            To := Hurt.GetTransform().Translation

            # Built from plain numbers on purpose. Reading .X off a transform is
            # allowed whichever module the vector came from; handing that vector
            # straight to ApplyLinearImpulse is not. Flat, because a shove that
            # follows the ground is what staggers, and the lift is added after.
            # THE TWO KINDS OF VECTOR DO NOT EVEN AGREE ON WHAT TO CALL A
            # DIRECTION. The Temporary one a transform hands back has X, Y and
            # Z. Verse.org's, which the impulse takes, has Forward, Left and Up,
            # and its own digest says which is which: Forward was X, Up was Z,
            # and Left was MINUS Y. That minus is not a typo and dropping it
            # would shove every robot the wrong way along one axis.
            Flat := vector3:
                Forward := To.X - From.X
                Left := -(To.Y - From.Y)
                Up := 0.0

            # A robot standing exactly on the contestant has no direction to be
            # pushed in, and a unit vector of nothing is nothing.
            if (Flat.Forward * Flat.Forward + Flat.Left * Flat.Left > 1.0):
                Direction := Flat.MakeUnitVector()
                Force := ForceFor(Victim)

                Impulse := vector3:
                    Forward := Direction.Forward * Force
                    Left := Direction.Left * Force
                    Up := Force * UpwardShare

                Hurt.ApplyLinearImpulse(Impulse)

                if (LogShoves?):
                    # THE NUMBER IS AN IMPULSE, NOT A DISTANCE, and the line used
                    # to read "{Force} away from the contestant", which invited
                    # anyone reading the log to take it for centimetres. How far
                    # a robot actually travels depends on its mass and on what it
                    # hits, and nothing here measures it.
                    Log("DEBUG: Shotgun shove -- impulse {Force} applied, directed away from the contestant.")

    # =================================================================
    # THE FAN, amendment 88
    # =================================================================

    # Everything standing in a wide, short wedge in front of the contestant takes
    # a share of the blast and is shoved with it.
    #
    # THE WEDGE POINTS AT THE ROBOT THAT WAS HIT, NOT WHERE THE MOUSE IS. There
    # is no aim direction on a damage_result, and the AimRotationProbe has been
    # reporting the same yaw of 90 on every line for days, so the mouse is not a
    # thing to trust here. The line from the contestant to the robot the pellets
    # actually found IS the direction of the blast, and it needs nothing read
    # from the engine that might be wrong.
    #
    # PLAIN ARITHMETIC, NO VECTOR HELPERS, deliberately. Two modules each define
    # a vector3 with different component names, and a transform hands back the
    # wrong one. The sniper's beam is written this way for the same reason.
    FanOut(FirstHit : fort_character, Victim : agent, Amount : float):void =
        if (Contestant := FirstContestant()?, Shooter := Contestant.GetFortCharacter[]):
            From := Shooter.GetTransform().Translation
            Through := FirstHit.GetTransform().Translation

            DirX := Through.X - From.X
            DirY := Through.Y - From.Y
            Span := Sqrt(DirX * DirX + DirY * DirY)

            # POINT BLANK HAS NO DIRECTION. A robot standing exactly on the
            # contestant gives a line of nothing to normalise.
            #
            # EVERY DIVISION IN VERSE CAN FAIL, FLOATS INCLUDED, so all three sit
            # inside this if rather than on lines of their own. 0.01745 is one
            # degree in radians, used instead of PiFloat/180 so the whole
            # conversion is a multiplication.
            if (Span > 1.0, UnitX := DirX / Span, UnitY := DirY / Span):
                CosHalf := Cos(FanHalfAngleDegrees * 0.0174532925)
                set Fanning = true

                var Caught : int = 0
                Damaged := Amount * FanDamageShare

                # THE CAP IS A CONDITION, NOT A break, because Verse only allows
                # break inside a loop and this is a for. Once the cap is reached
                # the rest of the list is walked and skipped.
                for (Other : LiveHostiles()):
                    if (Caught < MaxFanned, not (Other = Victim), Body := Other.GetFortCharacter[], Body.IsActive[]):
                        Spot := Body.GetTransform().Translation

                        OffX := Spot.X - From.X
                        OffY := Spot.Y - From.Y
                        Away := Sqrt(OffX * OffX + OffY * OffY)

                        # ALONG is how far this robot lies down the line of the
                        # blast. Dividing it by Away would give the cosine of the
                        # angle, so multiplying the other side by Away instead
                        # asks the same question without a division.
                        Along := OffX * UnitX + OffY * UnitY

                        if (Away > 1.0, Away <= FanRange, Along >= CosHalf * Away):
                            # THE SHOVE GOES FIRST, AND THE ORDER IS THE POINT.
                            # Kai on 2026-08-28: "i dont see the enemies knocking
                            # back, theyre just dying off the rip". The fan hits
                            # for four pellets, which the log measured at around
                            # 400, and most robots do not survive that. Damaging
                            # first meant the push was being applied to something
                            # that had already stopped existing.
                            #
                            # It does not guarantee a visible fling on a robot
                            # that dies anyway. It does mean the impulse is on a
                            # body that is still standing when it arrives, which
                            # is the most this can do without touching amendment
                            # 88's ruling that the fan deals half a blast.
                            Shove(Body, Other)
                            Body.Damage(Damaged)
                            set Caught = Caught + 1

                set Fanning = false

                if (LogShoves?, Caught > 0):
                    Log("DEBUG: Shotgun fan -- {Caught} more robot(s) caught for {Damaged} each.")

    # The Boar is launched, everything else is staggered.
    #
    # NO RETURN INSIDE THE LOOP. A return in a for is what the first build
    # objected to, so the loop sets a flag and the answer is given after it.
    ForceFor(Victim : agent)<transacts>:float =
        var IsBoar : logic = false
        for (Boar : BoarSpawner.GetAgents(), Boar = Victim):
            set IsBoar = true

        if (IsBoar?):
            KnockbackForce * BoarForceMultiplier
        else:
            KnockbackForce

    # The contestant. Single-player per amendment 19, so the first one is the
    # only one.
    #
    # IT IS A FUNCTION, WITH BRACKETS. Written without them it is a data member,
    # and the first build said so three ways at once: a transacts on a data
    # member, a for that is not a list, and a return outside a routine.
    FirstContestant()<transacts>:?player =
        Contestants := GetPlayspace().GetPlayers()
        if (First := Contestants[0]):
            return option{First}
        false
