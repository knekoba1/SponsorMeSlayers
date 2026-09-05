# SniperPiercing.verse
#
# GDD Section 3.3's weapon table, the Sponsor Sniper row: "PIERCING BEAM: Emits
# an overcharged energy beam that pierces through lines of distant, stationary
# Ranged Sentinels."
#
# KAI'S RULING, 2026-08-26: IT PIERCES EVERY KIND OF ROBOT. The GDD names only
# the Ranged Sentinel, which reads as the tactical use case rather than a limit,
# and Kai was asked directly and chose all four types. Recorded here because the
# wording of 3.3 says otherwise on a quick read.
#
# THE BULLET IS FORTNITE'S AND CANNOT BE CHANGED. A stock Heavy Sniper stops at
# the first thing it hits and nothing in Verse reaches inside a weapon to alter
# that. So the pierce is carried by hand: when a robot takes a sniper hit, a line
# is drawn from the contestant through that robot and out the far side, and every
# hostile standing on that line takes the same hit.
#
# IT IS THE SAME "WHICH GUN" PROBLEM THE SHOTGUN HAD. Verse is told who hurt a
# robot and by how much, never with what. See ShotgunKnockback.verse for the long
# version. The answer here is the same: the last gun a crate handed over, with a
# damage window available once real numbers have been read off a playtest.
#
# THE RE-ENTRY GUARD IS NOT OPTIONAL. Damaging the robots behind the first one
# fires their own damage events, which arrive back here, which would pierce again
# from each of them. Piercing is a flag that is up for the length of one beam and
# every event that arrives while it is up is ignored. Without it a single shot
# walks the arena until nothing is left standing.

using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/SpatialMath }
using { /Verse.org/Simulation }

sniper_piercing_manager := class(creative_device):

    # =================================================================
    # WIRING
    # =================================================================

    # The four spawners, in Wave Manager's order: Swarmer, Boar, Sentinel, Tank.
    # Every one of them is searched, because the beam pierces all four.
    @editable
    SwarmerSpawner : npc_spawner_device = npc_spawner_device{}

    @editable
    BoarSpawner : npc_spawner_device = npc_spawner_device{}

    @editable
    SentinelSpawner : npc_spawner_device = npc_spawner_device{}

    @editable
    TankSpawner : npc_spawner_device = npc_spawner_device{}

    @editable
    Crates : crate_manager = crate_manager{}

    # Told when one beam kills more than the robot it was aimed at. GDD 3.1
    # counts rapid multi-kills as a Hype source, and the cluster rule in the
    # Hype meter cannot see this one: it wants four kills in four tenths of a
    # second, and a beam through a line kills two or three. Kai asked for it on
    # 2026-08-26 after pulling the shot off and finding it paid nothing.
    @editable
    Hype : hype_meter_manager = hype_meter_manager{}

    # =================================================================
    # DIALS
    # =================================================================

    # WHICH REWARD NUMBER IS THE SNIPER. A weapon number is a SLOT, not a gun:
    # 0 is whatever GranterUnderdog holds, the Heavy Sniper today.
    @editable
    SniperSlot : int = 0

    # How far past the robot that was hit the beam carries on, in centimetres.
    # The arena is about 3000 across, so this reaches most of the way down it.
    @editable
    PierceRange : float = 2500.0

    # How far off the line a robot may stand and still be caught, in
    # centimetres. This is the beam's forgiveness, and it is what decides
    # whether "lined up" means perfectly or roughly. A robot is about 60 wide.
    @editable
    BeamHalfWidth : float = 110.0

    # What the robots behind the first one take, against what the first one
    # took. 1.0 is the full hit, which is what "overcharged" in the GDD suggests.
    @editable
    PierceDamageShare : float = 1.0

    # The most robots one beam may carry through, first one aside. A cap so a
    # perfectly lined up wave cannot become a single-shot clear.
    #
    # RAISED FROM 4 TO 9. KAI'S RULING, 2026-09-05. Kai asked for a big Hype
    # bonus on a beam of more than five robots, and five was the ceiling: four
    # carried through plus the one actually shot. So "more than five" could
    # never happen. Ten is the new ceiling, chosen over seven and over no cap
    # at all, because an early room holds about twelve robots at once and one
    # shot still must not clear the room.
    @editable
    MaxPierced : int = 9

    # -- telling the sniper apart, same as the shotgun -----------------
    @editable
    UseDamageWindow : logic = false

    @editable
    MinSniperDamage : float = 0.0

    @editable
    MaxSniperDamage : float = 0.0

    @editable
    LogPierces : logic = true

    # =================================================================
    # STATE
    # =================================================================

    var Watched : [agent]logic = map{}

    # Up for the length of one beam. See the header: without it, one shot walks
    # the whole arena.
    var Piercing : logic = false

    OnBegin<override>()<suspends>:void =
        for (Spawner : AllSpawners()):
            Spawner.SpawnedEvent.Subscribe(OnHostileSpawned)

        Log("DEBUG: Sniper piercing listening. Sniper is reward slot {SniperSlot}.")

    AllSpawners()<transacts>:[]npc_spawner_device =
        array{SwarmerSpawner, BoarSpawner, SentinelSpawner, TankSpawner}

    OnHostileSpawned(Spawned : agent):void =
        # One subscription per hostile, ever. Subscribing twice pierces twice.
        if (Watched[Spawned]):
            return

        if (set Watched[Spawned] = true):
            if (Character := Spawned.GetFortCharacter[]):
                Character.DamagedEvent().Subscribe(OnHostileDamaged)

    OnHostileDamaged(Result : damage_result):void =
        # ALREADY PIERCING. This is one of our own hits arriving back.
        if (Piercing?):
            return

        if (not DamageWasOurs(Result)?):
            return

        if (not IsSniperHit(Result)?):
            return

        if (Hurt := fort_character[Result.Target]):
            Pierce(Hurt, Result.Amount)

    # =================================================================
    # THE BEAM
    # =================================================================

    Pierce(FirstHit : fort_character, Amount : float):void =
        if (Contestant := FirstContestant()?, Shooter := Contestant.GetFortCharacter[]):
            From := Shooter.GetTransform().Translation
            Through := FirstHit.GetTransform().Translation

            # Flat, in plain numbers. The beam is a line along the ground: the
            # arena is seen from above and everything stands on one floor, so
            # height would only add noise.
            DirX := Through.X - From.X
            DirY := Through.Y - From.Y
            Span := Sqrt(DirX * DirX + DirY * DirY)

            # Point blank, or a robot standing on the contestant. There is no
            # line to follow and normalising it would divide by nothing.
            if (Span > 1.0, UnitX := DirX / Span, UnitY := DirY / Span):
                set Piercing = true

                var Carried : int = 0
                var Felled : int = 0
                Damaged := Amount * PierceDamageShare

                # THE CAP IS A CONDITION, NOT A break. Verse only allows break
                # inside a `loop`, and this is a `for`. Once the cap is reached
                # the rest of the list is walked and skipped, which costs a
                # handful of comparisons and nothing else.
                for (Behind : LiveHostiles()):
                    if (Carried < MaxPierced, Body := Behind.GetFortCharacter[], Body.IsActive[]):
                        Spot := Body.GetTransform().Translation

                        # Where this robot stands relative to the one that was
                        # actually shot.
                        OffX := Spot.X - Through.X
                        OffY := Spot.Y - Through.Y

                        # ALONG is how far down the beam it is. Negative means
                        # it is between the contestant and the first robot,
                        # which the bullet already passed, so it is skipped.
                        Along := OffX * UnitX + OffY * UnitY

                        if (Along > 1.0, Along <= PierceRange):
                            # ASIDE is how far off the line it stands, by
                            # Pythagoras: the whole distance squared, less the
                            # part that lies along the beam.
                            WholeSquared := OffX * OffX + OffY * OffY
                            AsideSquared := WholeSquared - Along * Along

                            if (AsideSquared <= BeamHalfWidth * BeamHalfWidth):
                                Body.Damage(Damaged)
                                set Carried = Carried + 1

                                # DID THAT KILL IT? Asked straight after the
                                # damage, while the answer is still true. A
                                # robot that is no longer active is one the beam
                                # finished, and those are what the Hype meter is
                                # told about.
                                if (not Body.IsActive[]):
                                    set Felled = Felled + 1

                                if (LogPierces?):
                                    Log("DEBUG: Sniper beam pierced a robot {Along} down the line for {Damaged}.")

                set Piercing = false

                # THE ROBOT THAT WAS AIMED AT COUNTS TOO, which is why this is
                # Felled plus one. A beam that killed nothing behind the target
                # is an ordinary shot and pays nothing: the meter is only told
                # when the beam did something the cluster rule cannot see.
                if (Felled > 0):
                    Hype.OnSniperMultiKill(Felled + 1)

                if (LogPierces?, Carried = 0):
                    Log("DEBUG: Sniper beam pierced nothing. Nothing was lined up behind the target.")

    # Every hostile currently in the arena, from all four spawners, because the
    # beam pierces every kind.
    LiveHostiles()<transacts>:[]agent =
        var Found : []agent = array{}
        for (Spawner : AllSpawners()):
            set Found = Found + Spawner.GetAgents()
        Found

    # =================================================================
    # THE TWO TESTS, both the same shape as the shotgun's
    # =================================================================

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

    IsSniperHit(Result : damage_result)<transacts>:logic =
        if (UseDamageWindow?, MaxSniperDamage > 0.0):
            if (Result.Amount >= MinSniperDamage, Result.Amount <= MaxSniperDamage):
                return true
            return false

        if (Crates.GetLastWeaponSlot() = SniperSlot):
            return true
        false

    FirstContestant()<transacts>:?player =
        Contestants := GetPlayspace().GetPlayers()
        if (First := Contestants[0]):
            return option{First}
        false
