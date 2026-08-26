# ShotgunKnockback.verse
#
# GDD Section 3.3's weapon table, the Shotgun row: "Wide horizontal 5-pellet
# red-mist spread... CHAIN KNOCKBACK: High-impact blasts stagger enemies and
# launch armored Cyber-Boars backward into other hostiles."
#
# WHAT THIS IS FOR. Kai asked why a shotgun blast only ever kills one robot and
# whether it could kill several. It could not, and it is not what the GDD asks
# for either: the job of cutting through a line of hostiles belongs to the
# Sponsor Sniper's piercing beam. The shotgun's job is to SHOVE. This file is
# that shove.
#
# WHY IT CANNOT SIMPLY ASK WHAT GUN IS IN THE CONTESTANT'S HANDS. Verse is told
# that a robot was hurt, by whom, and by how much. It is NOT told what hurt it.
# `damage_result` carries a Source typed as `game_action_causer`, an interface
# the contestant's own character satisfies, and there is no weapon anywhere on
# it. Checked in the digest, not guessed.
#
# SO THE SHOTGUN IS "THE LAST GUN A CRATE HANDED OVER". Kai's ruling of
# 2026-08-26, chosen over the alternative, which was to shove on any hit above a
# set force. That alternative was rejected because it could not be aimed: the
# Heavy Sniper hits harder than the shotgun does, so any threshold that lets a
# blast through lets a sniper round through as well, and the homing rocket with
# it. Kai wanted the shove to be the shotgun's and nothing else's.
#
# WHAT THAT COSTS, HONESTLY. If the contestant takes a shotgun from a crate and
# then switches back to the pistol by hand, the pistol will shove until another
# crate hands over a different gun. Nothing in Verse can see that switch. It is
# the price of the ruling and it is written here so it is not later mistaken for
# a bug.
#
# AND KAI FOUND A BETTER TEST THE SAME DAY: a damage WINDOW rather than a floor,
# because the sniper lands above the band and the pistol below it. It is off
# until it has real numbers in it, which is what LogEveryHit is for. See the
# dials, and IsShotgunHit, which is where the two answers meet.
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
    @editable
    KnockbackForce : float = 90000.0

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

    # -- telling the shotgun apart by what it does ---------------------
    #
    # KAI'S IDEA, 2026-08-26, AND IT IS BETTER THAN THE RULING IT REPLACES.
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
    # THE NUMBERS ARE NOT GUESSED. Leave LogEveryHit on, play a minute with each
    # gun, and read the real figures out of the log before setting these two.
    # Until they are set from a real playtest, UseDamageWindow stays off and the
    # last-gun rule is what runs.
    @editable
    UseDamageWindow : logic = false

    @editable
    MinShotgunDamage : float = 0.0

    @editable
    MaxShotgunDamage : float = 0.0

    # Prints the damage of every hit, which is how the window above gets filled
    # in. Switch it off once it is.
    @editable
    LogEveryHit : logic = true

    @editable
    LogShoves : logic = true

    # =================================================================
    # STATE
    # =================================================================

    # Every hostile that has been subscribed, so a second subscription is never
    # made for the same one. A hostile subscribed twice is shoved twice per hit.
    var Watched : [agent]logic = map{}

    # When each hostile was last shoved, against SecondsElapsed below.
    var LastShoveAt : [agent]float = map{}

    # A clock of our own. Verse has no "seconds since the match began" that can
    # be read on demand, so one is counted here.
    var SecondsElapsed : float = 0.0

    OnBegin<override>()<suspends>:void =
        for (Spawner : AllSpawners()):
            Spawner.SpawnedEvent.Subscribe(OnHostileSpawned)

        Log("DEBUG: Shotgun knockback listening. Shotgun is reward slot {ShotgunSlot}.")

        spawn{ RunClock() }

    RunClock()<suspends>:void =
        loop:
            Sleep(0.1)
            set SecondsElapsed = SecondsElapsed + 0.1

    AllSpawners()<transacts>:[]npc_spawner_device =
        array{SwarmerSpawner, BoarSpawner, SentinelSpawner, TankSpawner}

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
        # THE TUNING LINE. Play a minute with each gun, then read the real
        # numbers off the log and set the window with them.
        if (LogEveryHit?):
            Log("DEBUG: Hit for {Result.Amount} damage. Last crate gun was slot {Crates.GetLastWeaponSlot()}.")

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

    # Was this hit the shotgun's?
    #
    # Two answers, and the window is the better one once it has real numbers in
    # it. A window of zero to zero would refuse everything, so a window that has
    # not been filled in falls back rather than silently switching the feature
    # off.
    IsShotgunHit(Result : damage_result)<transacts>:logic =
        if (UseDamageWindow?, MaxShotgunDamage > 0.0):
            if (Result.Amount >= MinShotgunDamage, Result.Amount <= MaxShotgunDamage):
                return true
            return false

        if (Crates.GetLastWeaponSlot() = ShotgunSlot):
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
                    Log("DEBUG: Shotgun shove -- {Force} away from the contestant.")

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
