# StartingLoadoutManager.verse
#
# GDD Section 2.4 "First-Life Onboarding Ramp", which starts Room-Loop 1 with the
# "standard Pulse Blaster weapon", and GDD Section 3.2, which defines the player's
# slots as exactly four: Weapon, Consumable, Shield and Ammo Modifier. No melee or
# harvesting slot appears anywhere in the GDD.
#
# SCOPE. Two jobs and nothing else. Put the granted pistol into the player's hands,
# and take the pickaxe away. This device does NOT grant the pistol. The Class
# Designer does that and must keep doing it.
#
# WHY THIS IS A SCRIPT AND NOT A CHECKBOX.
# In UEFN 5.8 no device exposes either setting. The Class Designer's only User
# Option is its Item List. The Team Settings & Inventory device has no loadout
# options either. Both were searched by hand, and the digest agrees:
# class_designer_device exposes only GetClassMembers and IsOfClass. See
# GDD_AMENDMENTS.md item 7.
#
# Epic's web documentation describes Equip Granted Item, Grant Items On Respawn and
# Start With Pickaxe on the Class Designer. None of the three exists in 5.8. That
# page documents an older build. Do not go looking for them.
#
# HOW IT WORKS.
# The pistol and the pickaxe both sit in ordinary inventories hanging off the
# player's entity, so the walk is the same for both:
#
#   agent -> GetFortCharacter -> GetEntity -> FindDescendantComponents(inventory)
#
# then Equip() the item in the weapon hotbar, and RemoveItem() whatever is in the
# harvest tool inventory.
#
# THE RESPAWN HOOK.
# fort_playspace has no spawn or respawn event, only PlayerAddedEvent and
# PlayerRemovedEvent, which fire on joining and leaving the match. So joining is
# handled from the playspace and respawning has to come from a device. Two signal a
# spawn and hand back the agent: player_spawner_device.SpawnedEvent and
# team_settings_and_inventory_device.TeamMemberSpawnedEvent. Both are wired below.
# Either one alone is enough. Wiring both is harmless, it only doubles the log
# lines, because re-equipping an equipped pistol and re-removing an absent pickaxe
# both do nothing.
#
# WHY IT RETRIES INSTEAD OF WAITING A FIXED TIME.
# Nothing in the digest signals when the Class Designer has finished granting the
# pistol, so there is no event to wait on. A single guessed delay is exactly what
# has already cost this project several sessions. This tries, and keeps trying on
# an interval, until both halves succeed or the attempt budget runs out. Each half
# stops on its own, so a finished pickaxe removal does not keep re-running while
# the equip is still failing.

using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /Fortnite.com/Itemization }
using { /UnrealEngine.com/Itemization }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }

starting_loadout_manager := class(creative_device):

    # Fires every time a player spawns, including respawns. In UEFN this device is
    # called the Player Spawn Pad; player_spawner_device is its name in Verse.
    # Point this at one of the pads in the map. If the dropdown does not list them,
    # leave it blank and rely on TeamSettings below.
    @editable
    SpawnPad : player_spawner_device = player_spawner_device{}

    # The alternative respawn hook, for if the spawn pads cannot be referenced.
    # Point this at the Team Settings & Inventory device already in the map.
    @editable
    TeamSettings : team_settings_and_inventory_device = team_settings_and_inventory_device{}

    # How long to wait between attempts. Kept short, because the player is standing
    # in the arena holding nothing until this succeeds.
    @editable
    RetryInterval : float = 0.25

    # How many attempts before giving up and logging a WARNING. At the default
    # interval that is five seconds of trying.
    @editable
    MaxAttempts : int = 20

    OnBegin<override>()<suspends>:void =
        Playspace := GetPlayspace()

        # Subscribed before the existing players are handled, so anyone arriving
        # while that loop runs is still caught.
        Playspace.PlayerAddedEvent().Subscribe(OnPlayerJoined)
        SpawnPad.SpawnedEvent.Subscribe(OnAgentSpawned)
        TeamSettings.TeamMemberSpawnedEvent.Subscribe(OnAgentSpawned)

        Players := Playspace.GetPlayers()
        Print("DEBUG: Starting loadout manager up -- {Players.Length} player(s) already here")
        for (JoinedPlayer : Players):
            OnAgentSpawned(JoinedPlayer)

    OnPlayerJoined(JoinedPlayer : player):void =
        Print("DEBUG: Player joined -- fixing their starting loadout")
        OnAgentSpawned(JoinedPlayer)

    # Launched with spawn so the retrying happens off to one side and never holds
    # up the event that triggered it.
    OnAgentSpawned(SpawnedAgent : agent):void =
        spawn{ ApplyLoadout(SpawnedAgent) }

    # Retries until both halves are done or the attempt budget runs out. The two
    # halves are tracked separately so neither is repeated once it has succeeded.
    ApplyLoadout(TargetAgent : agent)<suspends>:void =
        var PistolEquipped : logic = false
        var PickaxeRemoved : logic = false
        var Attempt : int = 0

        loop:
            set Attempt += 1

            # Per-stage logging on the first and last attempt only, so a run that
            # succeeds immediately stays readable and a run that fails still says
            # exactly which step broke.
            var Loud : logic = false
            if (Attempt = 1):
                set Loud = true
            if (Attempt >= MaxAttempts):
                set Loud = true

            if (not PistolEquipped?):
                if (EquipStartingWeapon(TargetAgent, Loud)?):
                    set PistolEquipped = true

            if (not PickaxeRemoved?):
                if (RemoveHarvestTool(TargetAgent, Loud)?):
                    set PickaxeRemoved = true

            if (PistolEquipped?, PickaxeRemoved?):
                Print("DEBUG: Starting loadout done on attempt {Attempt}")
                break

            if (Attempt >= MaxAttempts):
                Print("WARNING: Starting loadout GAVE UP after {MaxAttempts} attempts. Pistol equipped: {PistolEquipped}. Pickaxe removed: {PickaxeRemoved}.")
                break

            Sleep(RetryInterval)

    # Walks from the agent to the pistol and equips it. Returns true once the
    # pistol is in the player's hands.
    #
    # NOTE. This equips the first equippable thing in the weapon hotbar. That is
    # correct while the Class Designer's Item List holds one entry. If more are
    # added, this will need to pick deliberately rather than take the first.
    EquipStartingWeapon(TargetAgent : agent, Loud : logic):logic =
        if (Character := TargetAgent.GetFortCharacter[]):
            if (Loud?):
                Print("DEBUG: Loadout equip -- fort_character found")

            if (PlayerEntity := Character.GetEntity[]):
                if (Loud?):
                    Print("DEBUG: Loadout equip -- entity found")

                for (Hotbar : PlayerEntity.FindDescendantComponents(fort_inventory_weapon_hotbar_component)):
                    Items := Hotbar.GetItems()
                    if (Loud?):
                        Print("DEBUG: Loadout equip -- weapon hotbar found, {Items.Length} item(s) in it")

                    for (ItemEntity : Items):
                        if (ItemPart := ItemEntity.GetComponent(item_component)[]):
                            Outcome := ItemPart.Equip()
                            if (Errors := Outcome.GetError[], Errors.Length > 0):
                                if (Loud?):
                                    Print("DEBUG: Loadout equip -- Equip() FAILED with {Errors.Length} error(s)")
                            else:
                                Print("DEBUG: Loadout equip -- pistol equipped")
                                return true
                        else:
                            if (Loud?):
                                Print("DEBUG: Loadout equip -- an inventory entry has no item_component")

                if (Loud?):
                    Print("DEBUG: Loadout equip -- nothing equippable found yet")
            else:
                if (Loud?):
                    Print("DEBUG: Loadout equip -- GetEntity FAILED")
        else:
            if (Loud?):
                Print("DEBUG: Loadout equip -- GetFortCharacter FAILED, no character yet")

        return false

    # Empties the harvest tool inventory, which is where the pickaxe lives.
    # Returns true once that inventory has been found and is empty.
    #
    # NOTE. If the inventory is not found at all this returns false and keeps
    # retrying, rather than treating "no inventory" as "no pickaxe". Early in a
    # spawn the absence almost certainly means "not built yet", and the WARNING
    # will say so if it never appears.
    RemoveHarvestTool(TargetAgent : agent, Loud : logic):logic =
        if (Character := TargetAgent.GetFortCharacter[]):
            if (PlayerEntity := Character.GetEntity[]):
                var FoundInventory : logic = false
                var StillThere : int = 0

                for (HarvestBag : PlayerEntity.FindDescendantComponents(fort_inventory_harvest_tool_component)):
                    set FoundInventory = true
                    Tools := HarvestBag.GetItems()
                    if (Loud?):
                        Print("DEBUG: Loadout pickaxe -- harvest tool inventory found, {Tools.Length} item(s) in it")

                    for (Tool : Tools):
                        Outcome := HarvestBag.RemoveItem(Tool)
                        if (Errors := Outcome.GetError[], Errors.Length > 0):
                            set StillThere += 1
                            if (Loud?):
                                Print("DEBUG: Loadout pickaxe -- RemoveItem FAILED with {Errors.Length} error(s)")
                        else:
                            Print("DEBUG: Loadout pickaxe -- removed one harvest tool")

                if (FoundInventory?, StillThere = 0):
                    return true

                if (Loud?):
                    Print("DEBUG: Loadout pickaxe -- not clear yet, {StillThere} still in the bag")
            else:
                if (Loud?):
                    Print("DEBUG: Loadout pickaxe -- GetEntity FAILED")
        else:
            if (Loud?):
                Print("DEBUG: Loadout pickaxe -- GetFortCharacter FAILED, no character yet")

        return false
