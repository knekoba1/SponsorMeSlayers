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
# ONE KNOWN INTERACTION, ACCEPTED. The Death Save slow motion drives the same
# hostile movement multipliers. If a slow happens to expire inside a Death Save
# window, that one hostile returns to normal speed for the rest of it. It needs a
# thaw to land inside a three-second window to happen at all, and the alternative
# is wiring together two managers GDD 4.1 deliberately keeps apart.

using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Simulation }

# What Icy Rounds knows about one hostile.
icy_hostile := struct:
    # The health seen at the last sample, so a drop can be spotted.
    LastHealth : float
    # How much speed is currently taken off, 0.0 to MaxSlow.
    Slow : float
    # Seconds since the last landed hit. At StackSeconds the slow expires.
    SecondsSinceHit : float

ammo_modifier_manager := class(creative_device):

    # The spawner whose hostiles get slowed, the same one the wave manager and
    # the Hype meter watch.
    @editable
    HostileSpawner : npc_spawner_device = npc_spawner_device{}

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

    # Frost trails in the palette's #9FE8FF, amendment 36. ITS "STICK TO PLAYER"
    # SETTING MUST BE ON, or Begin(Agent) will not ride the hostile.
    @editable
    FrostGlow : vfx_creator_device = vfx_creator_device{}

    var IcyActive : logic = false
    var IcySeconds : float = 0.0
    var IcyHostiles : [agent]icy_hostile = map{}

    OnBegin<override>()<suspends>:void =
        Print("DEBUG: Ammo Modifier Manager ready. Icy Rounds runs {ModifierSeconds}s.")

    # Called by the crate manager when a Prime Time crate hands over Icy Rounds.
    # A second pickup while one is running restarts the clock rather than adding
    # to it, which is GDD 3.2's refresh rule.
    StartIcyRounds()<suspends>:void =
        set IcySeconds = 0.0
        if (IcyActive?):
            Print("DEBUG: Icy Rounds refreshed.")
        else:
            set IcyActive = true
            Print("DEBUG: Icy Rounds ON for {ModifierSeconds}s.")
            spawn{ RunIcyRounds() }

    RunIcyRounds()<suspends>:void =
        loop:
            Sleep(PollSeconds)
            set IcySeconds = IcySeconds + PollSeconds
            if (IcySeconds >= ModifierSeconds):
                break
            SampleHostiles()

        ThawEverything()
        set IcyHostiles = map{}
        set IcyActive = false
        Print("DEBUG: Icy Rounds expired.")

    # One pass over every live hostile. The known set is rebuilt from the live
    # ones each time, so eliminated hostiles fall out on their own.
    SampleHostiles():void =
        var Updated : [agent]icy_hostile = map{}
        for:
            Hostile : HostileSpawner.GetAgents()
            Character := Hostile.GetFortCharacter[]
            Character.IsActive[]
        do:
            Now := Character.GetHealth()
            var State : icy_hostile = icy_hostile{LastHealth := Now, Slow := 0.0, SecondsSinceHit := 0.0}
            if (Known := IcyHostiles[Hostile]):
                set State = Known

            var Slow : float = State.Slow
            var SinceHit : float = State.SecondsSinceHit + PollSeconds

            if (Now < State.LastHealth):
                if (Slow <= 0.0):
                    FrostGlow.Begin(Hostile)
                set Slow = Slow + SlowPerStack
                if (Slow > MaxSlow):
                    set Slow = MaxSlow
                set SinceHit = 0.0

            if (SinceHit >= StackSeconds, Slow > 0.0):
                set Slow = 0.0
                FrostGlow.End(Hostile)

            ApplySlow(Character, Slow)
            set Updated = ConcatenateMaps(Updated, map{Hostile => icy_hostile{LastHealth := Now, Slow := Slow, SecondsSinceHit := SinceHit}})

        set IcyHostiles = Updated

    # Puts every live hostile back to full speed and takes the frost off.
    ThawEverything():void =
        for:
            Hostile : HostileSpawner.GetAgents()
            Character := Hostile.GetFortCharacter[]
            Character.IsActive[]
        do:
            ApplySlow(Character, 0.0)
            FrostGlow.End(Hostile)

    ApplySlow(Character : fort_character, Slow : float):void =
        if (Navigatable := Character.GetNavigatable[]):
            Navigatable.SetMovementSpeedMultiplier(1.0 - Slow)
