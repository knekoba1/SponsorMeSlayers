# PropDamageProbe.verse
#
# GDD Section 3.2 "Color-Coded Paraglider Crates", and amendment 65.
#
# MEASUREMENT ONLY. TEMPORARY. DELETE ONCE ANSWERED.
# One job: print who the Prop Manipulator device says damaged a prop. It does
# not change a crate, does not stop a hit and does not decide anything.
#
# THE QUESTION IT ANSWERS.
# Amendment 65 needs to know who broke a crate. A creative_prop reports no
# damage at all, so the first build used a hidden Objective device as the
# counter. That counts correctly but drags Fortnite's own health and shield
# bars in with it, which Kai rejected on 2026-08-22, and being solid it also
# stopped the player's bullets before they ever reached it.
#
# prop_manipulator_device advertises exactly what is wanted: DamagedEvent and
# DestroyedEvent, each sending the agent responsible. If it works here, the
# crate itself becomes the thing you shoot and both bars disappear.
#
# THE RISK, AND WHY THIS PROBE EXISTS. The device is documented as affecting
# "one or more props in a specified area". Crates are spawned by CrateManager
# while the match runs, so they do not exist when that area is worked out. If
# the device only ever watches props placed in the editor it will report
# nothing, and the idea is dead. That single fact is all this probe is for.
#
# HOW TO READ IT. Shoot a crate. Any line starting "PROBE:" means the device
# saw it and the idea works. No PROBE lines at all means it does not see
# spawned props.

using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Simulation }

prop_damage_probe := class(creative_device):

    # The Prop Manipulator whose area covers the arena floor. Point this at the
    # placed device; with nothing filled in the probe says so and stops.
    @editable
    PropWatcher : prop_manipulator_device = prop_manipulator_device{}

    OnBegin<override>()<suspends>:void =
        Print("DEBUG: Prop damage probe watching. Shoot a crate and look for PROBE lines.")

        PropWatcher.DamagedEvent.Subscribe(OnPropDamaged)
        PropWatcher.DestroyedEvent.Subscribe(OnPropDestroyed)

    OnPropDamaged(Culprit : agent):void =
        Print("PROBE: prop damaged. Was it the contestant: {Contestant(Culprit)}")

    OnPropDestroyed(Culprit : agent):void =
        Print("PROBE: prop DESTROYED. Was it the contestant: {Contestant(Culprit)}")

    # Whether the agent the device named is the contestant rather than a
    # hostile. Amendment 65 keeps only the contestant's hits.
    Contestant(Culprit : agent)<transacts>:string =
        if (player[Culprit]):
            "yes"
        else:
            "no, a hostile"
