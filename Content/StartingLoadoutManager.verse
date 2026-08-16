# StartingLoadoutManager.verse
#
# GDD Section 2.4 "First-Life Onboarding Ramp", which starts Room-Loop 1 with the
# "standard Pulse Blaster weapon".
#
# SCOPE. One job. On every player spawn, tell a placed Item Granter device to give
# that specific player the pistol, with Equip Granted Item ticked on the granter so
# it arrives in their hands rather than in the inventory.
#
# This file does NOT equip anything itself and does not touch inventories. The
# granter does the work; this only decides who and when.
#
# WHY VERSE DRIVES THE GRANTER INSTEAD OF THE GRANTER DRIVING ITSELF.
# The Item Granter's own "Grant on Game Start" option fires too early. Playtested
# with it ticked and the pistol was still not in hand on spawn, almost certainly
# because it fires before the player's character exists. The spawn hook below fires
# at the right moment and hands back the specific agent who spawned.
#
# THE ROUTE THAT WAS TRIED AND CLOSED. Do not rebuild it.
# This file previously walked the Scene Graph from the player to their inventory:
# GetFortCharacter -> GetEntity -> FindDescendantComponents, then Equip() on the
# item found in the weapon hotbar. It compiled and ran and never once succeeded.
# GetFortCharacter and GetEntity succeeded on every attempt; the inventory
# component was never found, at attempt 1 or at attempt 20.
#
# The reason is that the fort_inventory_* components are the creator-built item
# system, not the inventory a Fortnite player already carries. Nothing in the
# digest returns one, takes one as a parameter, or says a player has one. The
# Class Designer's pistol goes into the classic Fortnite inventory, which that API
# does not expose. Full write-up in GDD_AMENDMENTS.md item 7.
#
# THERE IS NO PICKAXE. Do not add pickaxe handling back.
# The closed route above also tried to empty a harvest tool inventory. That was
# chasing something that does not exist. Island Settings, Player > Equipment, has
# Start With Pickaxe and it was already unticked. What showed in the HUD was an
# empty harvest slot, not a pickaxe, and it was removed by ticking Disable Harvest
# Slot in the same place. Neither is a device setting and neither is reachable from
# Verse. The only real gap was ever the pistol not being in hand.
#
# Island Settings is where player equipment rules live. Three device panels were
# searched before anyone looked there. See GDD_AMENDMENTS.md item 7.
#
# THE RESPAWN HOOK.
# fort_playspace has no spawn or respawn event, only PlayerAddedEvent and
# PlayerRemovedEvent, which fire on joining and leaving the match. So joining is
# handled from the playspace and respawning comes from a device. Both
# player_spawner_device.SpawnedEvent and TeamMemberSpawnedEvent are wired, because
# the playtest proved a hook fires on respawn but not which one. Clearing either
# field in UEFN disables that half with no code change.
#
# ON THE GRANTER'S OWN SETTINGS.
# Receiving Players must be Triggering Player, not All Players, or a grant aimed at
# one player arms everyone including NPCs. Grant on Game Start should be unticked,
# since this file now decides when.

using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Simulation }

starting_loadout_manager := class(creative_device):

    # The placed Item Granter holding the Combat Pistol, with Equip Granted Item
    # ticked. Point this at it.
    @editable
    PistolGranter : item_granter_device = item_granter_device{}

    # Fires every time a player spawns, including respawns. In UEFN this device is
    # called the Player Spawn Pad; player_spawner_device is its name in Verse.
    @editable
    SpawnPad : player_spawner_device = player_spawner_device{}

    # The second respawn hook. Point at the Team Settings & Inventory device.
    @editable
    TeamSettings : team_settings_and_inventory_device = team_settings_and_inventory_device{}

    # A moment's pause after the spawn event before granting, in case the character
    # is not quite ready to receive an item. Kept short; the player is standing
    # there empty-handed until it fires.
    @editable
    GrantDelay : float = 0.5

    # Counts grant requests so the log can pair a request with its confirmation.
    # Verse exposes no player name, so this is the closest thing to an identity.
    var GrantsRequested : int = 0

    OnBegin<override>()<suspends>:void =
        Playspace := GetPlayspace()

        # Subscribed before the existing players are handled, so anyone arriving
        # while that loop runs is still caught.
        Playspace.PlayerAddedEvent().Subscribe(OnPlayerJoined)
        SpawnPad.SpawnedEvent.Subscribe(OnAgentSpawned)
        TeamSettings.TeamMemberSpawnedEvent.Subscribe(OnAgentSpawned)

        # The granter's own confirmation. This is the line that says the pistol
        # actually arrived, as opposed to us merely asking for it.
        PistolGranter.ItemGrantedEvent.Subscribe(OnItemGranted)

        Players := Playspace.GetPlayers()
        Print("DEBUG: Starting loadout manager up -- {Players.Length} player(s) already here")
        for (JoinedPlayer : Players):
            OnAgentSpawned(JoinedPlayer)

    OnPlayerJoined(JoinedPlayer : player):void =
        Print("DEBUG: Loadout -- player joined")
        OnAgentSpawned(JoinedPlayer)

    # Launched with spawn so the pause happens off to one side and never holds up
    # the event that triggered it.
    OnAgentSpawned(SpawnedAgent : agent):void =
        spawn{ GrantAfterDelay(SpawnedAgent) }

    GrantAfterDelay(TargetAgent : agent)<suspends>:void =
        Sleep(GrantDelay)

        set GrantsRequested += 1
        RequestNumber := GrantsRequested

        # Verse gives no way to name a player, so the log says whether this is a
        # real player or some other agent, which is the distinction that matters.
        if (player[TargetAgent]):
            Print("DEBUG: Loadout -- grant request {RequestNumber} for a player, asking the granter now")
        else:
            Print("DEBUG: Loadout -- grant request {RequestNumber} for a NON-PLAYER agent, which is probably wrong")

        PistolGranter.GrantItem(TargetAgent)

    OnItemGranted(ReceivingAgent : agent):void =
        Print("DEBUG: Loadout -- granter confirms an item was granted")
