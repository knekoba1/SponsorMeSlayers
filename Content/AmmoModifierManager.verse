# AmmoModifierManager.verse
#
# GDD Section 3.3 "Weapon & Boost Profiles" -- the ammo modifiers. Icy Rounds is
# built here. Flaming Ammo is not, because it still has no burn damage number,
# which amendment 15 records as blocking the build.
#
# WHY THIS IS ITS OWN FILE. CrateManager owns handing a reward over. This owns
# what an ammo modifier then does for the next thirty seconds. The crate manager
# calls StartIcyRounds() and knows nothing else about any of it.
#
# HITS ARE MEASURED, NOT DETECTED. Verse cannot ask which weapon hurt a hostile.
# Nothing in the arena hurts hostiles except the player, so a drop in a hostile's
# health is a hit from the player. Health is sampled every PollSeconds and a drop
# adds a stack. Amendment 43.
#
# THE ENGINE WILL NOT GO BELOW HALF SPEED. SetMovementSpeedMultiplier clamps at
# 0.5, found when the Death Save slow motion was built, amendment 32. Three
# stacks of -20% is 0.4 on paper, so the third lands at half speed instead.
# Amendment 43 accepts that rather than faking movement in Verse.
#
# STACKS ARE HELD AS A FRACTION, NOT A COUNT. MaxSlow of 0.6 is GDD 3.3's "max 3"
# at -20% each, said in the units the engine actually wants, which keeps whole
# numbers out of a calculation that is entirely fractional.
#
# FLAMING AMMO AND ICY ROUNDS SHARE ONE LOOP, AND MUST. Both work by spotting a
# drop in a hostile's health, and burn damage is itself a drop in health. Run
# separately, each would read the other's damage as a player's bullet. Health is
# therefore re-read after any burn is applied, so only real shots count.
#
# ONE KNOWN INTERACTION, ACCEPTED. The Death Save slow motion drives the same
# hostile movement multipliers. If a slow happens to expire inside a Death Save
# window, that one hostile returns to normal speed for the rest of it. It needs a
# thaw to land inside a three-second window to happen at all, and the alternative
# is wiring together two managers GDD 4.1 deliberately keeps apart.

using { /Fortnite.com/Characters }
using { /Fortnite.com/AI }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Simulation }

# What the ammo modifiers know about one hostile.
hostile_effect := struct:
    # The health seen at the end of the last sample, after any burn was applied,
    # so the next drop can only have come from the player.
    LastHealth : float
    # How much speed Icy Rounds is taking off, 0.0 to MaxSlow.
    Slow : float
    # Seconds since the last landed hit, for the Icy Rounds thaw.
    SecondsSinceHit : float
    # Seconds of burn left. 0.0 means not on fire.
    BurnSecondsLeft : float
    # Counts up to one second, then a burn tick is dealt.
    BurnTick : float

ammo_modifier_manager := class(creative_device):

    # All four spawners, amendment 45, the same ones the wave manager and the
    # Hype meter watch. A type left out here can never be frozen or set alight.
    @editable
    HostileSpawners : []npc_spawner_device = array{}

    # How long an ammo modifier lasts once collected. Amendment 42.
    @editable
    ModifierSeconds : float = 30.0

    # What one landed hit takes off a hostile's speed. GDD 3.3's -20%.
    @editable
    SlowPerStack : float = 0.2

    # GDD 3.3's "max 3", expressed as the total it adds up to.
    @editable
    MaxSlow : float = 0.6

    # How long after the last landed hit the slow expires. Amendment 43.
    @editable
    StackSeconds : float = 3.0

    # How often hostile health is sampled, in seconds.
    @editable
    PollSeconds : float = 0.1

    # How long a burn lasts on a hostile after the shot that lit it. Amendment 44.
    @editable
    BurnSeconds : float = 3.0

    # Damage a burning hostile takes each second. Amendment 44: the SMG's own
    # bleed, and the only damage figure the GDD ever states.
    @editable
    BurnPerSecond : float = 5.0

    # The fire trails of GDD 3.3, in Burn Orange #FF8A00, amendment 62. ITS
    # "STICK TO PLAYER" SETTING MUST BE ON.
    @editable
    BurnGlow : vfx_creator_device = vfx_creator_device{}

    # Frost trails in Frost Blue #A8DCFF, amendment 62. ITS "STICK TO PLAYER"
    # SETTING MUST BE ON, or Begin(Agent) will not ride the hostile.
    @editable
    FrostGlow : vfx_creator_device = vfx_creator_device{}

    var IcyActive : logic = false
    var IcySeconds : float = 0.0
    var FlamingActive : logic = false
    var FlamingSeconds : float = 0.0
    var SamplerRunning : logic = false
    var AnyEffectLive : logic = false
    var HostileEffects : [agent]hostile_effect = map{}

    OnBegin<override>()<suspends>:void =
        Print("DEBUG: Ammo Modifier Manager ready. Modifiers run {ModifierSeconds}s.")

    # Called by the crate manager. A second pickup while one is running restarts
    # the clock rather than adding to it, which is GDD 3.2's refresh rule.
    StartIcyRounds()<suspends>:void =
        set IcySeconds = 0.0
        if (IcyActive?):
            Print("DEBUG: Icy Rounds refreshed.")
        else:
            set IcyActive = true
            Print("DEBUG: Icy Rounds ON for {ModifierSeconds}s.")
        StartSampler()

    StartFlamingAmmo()<suspends>:void =
        set FlamingSeconds = 0.0
        if (FlamingActive?):
            Print("DEBUG: Flaming Ammo refreshed.")
        else:
            set FlamingActive = true
            Print("DEBUG: Flaming Ammo ON for {ModifierSeconds}s.")
        StartSampler()

    StartSampler()<suspends>:void =
        if (not SamplerRunning?):
            set SamplerRunning = true
            spawn{ RunSampler() }

    # Runs while either modifier is on, and keeps running afterwards until the
    # last burn has finished and the last hostile has thawed, so an effect lit in
    # the modifier's final second still plays out in full.
    RunSampler()<suspends>:void =
        loop:
            Sleep(PollSeconds)

            if (IcyActive?):
                set IcySeconds = IcySeconds + PollSeconds
                if (IcySeconds >= ModifierSeconds):
                    set IcyActive = false
                    Print("DEBUG: Icy Rounds expired.")

            if (FlamingActive?):
                set FlamingSeconds = FlamingSeconds + PollSeconds
                if (FlamingSeconds >= ModifierSeconds):
                    set FlamingActive = false
                    Print("DEBUG: Flaming Ammo expired.")

            SampleHostiles()

            if (not IcyActive?, not FlamingActive?, not AnyEffectLive?):
                break

        ThawEverything()
        set HostileEffects = map{}
        set SamplerRunning = false
        Print("DEBUG: Ammo modifiers all finished.")

    # One pass over every live hostile. The known set is rebuilt from the live
    # ones each time, so eliminated hostiles fall out on their own.
    SampleHostiles():void =
        var Updated : [agent]hostile_effect = map{}
        var StillLive : logic = false
        for:
            Spawner : HostileSpawners
            Hostile : Spawner.GetAgents()
            Character := Hostile.GetFortCharacter[]
            Character.IsActive[]
        do:
            Now := Character.GetHealth()
            var State : hostile_effect = hostile_effect{LastHealth := Now, Slow := 0.0, SecondsSinceHit := 0.0, BurnSecondsLeft := 0.0, BurnTick := 0.0}
            if (Known := HostileEffects[Hostile]):
                set State = Known

            var Slow : float = State.Slow
            var SinceHit : float = State.SecondsSinceHit + PollSeconds
            var BurnLeft : float = State.BurnSecondsLeft
            var BurnTick : float = State.BurnTick

            # Health only ever falls because the player shot it. Burn damage is
            # excluded by re-reading health at the end of this pass.
            if (Now < State.LastHealth):
                set SinceHit = 0.0
                if (IcyActive?):
                    if (Slow <= 0.0):
                        FrostGlow.Begin(Hostile)
                    set Slow = Slow + SlowPerStack
                    if (Slow > MaxSlow):
                        set Slow = MaxSlow
                if (FlamingActive?):
                    if (BurnLeft <= 0.0):
                        BurnGlow.Begin(Hostile)
                        set BurnTick = 0.0
                    set BurnLeft = BurnSeconds

            if (SinceHit >= StackSeconds, Slow > 0.0):
                set Slow = 0.0
                FrostGlow.End(Hostile)

            if (BurnLeft > 0.0):
                set BurnLeft = BurnLeft - PollSeconds
                set BurnTick = BurnTick + PollSeconds
                if (BurnTick >= 1.0):
                    set BurnTick = BurnTick - 1.0
                    Character.Damage(BurnPerSecond)
                if (BurnLeft <= 0.0):
                    set BurnLeft = 0.0
                    BurnGlow.End(Hostile)

            ApplySlow(Character, Slow)

            if (Slow > 0.0):
                set StillLive = true
            if (BurnLeft > 0.0):
                set StillLive = true

            # Read again, so the burn's own damage is never mistaken next pass
            # for the player landing another shot.
            After := Character.GetHealth()
            set Updated = ConcatenateMaps(Updated, map{Hostile => hostile_effect{LastHealth := After, Slow := Slow, SecondsSinceHit := SinceHit, BurnSecondsLeft := BurnLeft, BurnTick := BurnTick}})

        set HostileEffects = Updated
        set AnyEffectLive = StillLive

    # Puts every live hostile back to full speed and takes the effects off.
    ThawEverything():void =
        for:
            Spawner : HostileSpawners
            Hostile : Spawner.GetAgents()
            Character := Hostile.GetFortCharacter[]
            Character.IsActive[]
        do:
            ApplySlow(Character, 0.0)
            FrostGlow.End(Hostile)
            BurnGlow.End(Hostile)

    ApplySlow(Character : fort_character, Slow : float):void =
        if (Navigatable := Character.GetNavigatable[]):
            Navigatable.SetMovementSpeedMultiplier(1.0 - Slow)
