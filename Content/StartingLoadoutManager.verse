# StartingLoadoutManager.verse
#
# GDD Section 2.4 "First-Life Onboarding Ramp", which starts Room-Loop 1 with the
# "standard Pulse Blaster weapon".
#
# SCOPE. Two jobs. On every player spawn, tell a placed Item Granter device to give
# that specific player the pistol, with Equip Granted Item ticked on the granter so
# it arrives in their hands rather than in the inventory. Then, for the rest of the
# match, keep the Light Ammo pouch topped up so the pistol never runs dry.
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
# ON THE GRANTERS' OWN SETTINGS.
# Receiving Players must be Triggering Player, not All Players, or a grant aimed at
# one player arms everyone including NPCs. Grant on Game Start should be unticked,
# since this file now decides when.
#
# The ammo granter needs two more and both matter. Equip Granted Item must be
# UNTICKED, or every top-up snatches whatever weapon is in the player's hands.
# On Grant Action must be KEEP ALL. Its other three options are Clear Inventory,
# Clear Items and Clear Resources, and any of them would strip the player of the
# crate weapon this top-up exists to back up, every five seconds, for the whole
# match. Both confirmed by hand in UEFN 5.8 on 2026-08-17.

using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Simulation }

starting_loadout_manager := class(creative_device):

    # The placed Item Granter holding the Combat Pistol, with Equip Granted Item
    # ticked. Point this at it.
    @editable
    PistolGranter : item_granter_device = item_granter_device{}

    # The placed Item Granter holding Light Ammo. GDD 3.3 makes the Pulse Blaster
    # the "default infinite ammo weapon", and there is no per-weapon infinite ammo
    # switch a creator can reach: SetShotAmmoCost belongs to the creator-built
    # weapon system that amendment 7 closed off. Island Settings has Infinite
    # Reserve Ammo and Infinite Magazine Ammo, but both are island-wide and would
    # feed every crate weapon too. Rejected 2026-08-17. So the Light Ammo pouch is
    # topped up on a timer instead.
    #
    # THIS IS NOT PER-WEAPON AND CANNOT BE. Fortnite keeps ONE pouch per ammo
    # TYPE, shared by every weapon that fires it. Topping up Light Ammo tops up
    # anything using Light Ammo. Shotgun (Shells) and Sponsor Sniper (Heavy) are
    # unaffected. A stock Fortnite SMG is not.
    #
    # SO THE CRATE SMG MUST USE MEDIUM AMMO. Kai's ruling 2026-08-17, amendment
    # 21. GDD 3.3 describes that weapon by behaviour, rapid fire, 50-round
    # magazine, bleed, not by Fortnite's weapon category, so a Medium-ammo weapon
    # still satisfies it. Building it on Light Ammo would hand it infinite ammo
    # silently and break 3.3's "fallback when special weapons run out of ammo".
    @editable
    AmmoGranter : item_granter_device = item_granter_device{}

    # How often the Light Ammo pouch is topped up, in seconds. Kai's call
    # 2026-08-22: 30 rather than 5. At 5 the pouch was still near the carrying
    # cap when the next grant landed, and Fortnite drops the surplus on the floor
    # rather than absorbing it, so light ammo littered the arena all match. At 30
    # the player has spent more than one grant hands over, so there is no surplus
    # to spill. Raise it to 45 if any still appears.
    @editable
    AmmoTopUpSeconds : float = 30.0

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

        spawn{ TopUpAmmoForever() }

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
        # The pistol waits for PLAY. Amendment 70.
        AwaitMatchStart(Self)
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

        # A full pouch on arrival, so the slower timer above is never the thing
        # standing between the player and their first magazine.
        AmmoGranter.GrantItem(TargetAgent)

    OnItemGranted(ReceivingAgent : agent):void =
        Print("DEBUG: Loadout -- granter confirms an item was granted")

    # Runs for the whole match. It asks rather than checks, because the code cannot
    # see how much ammo a player is carrying. Same closed door as amendment 7.
    TopUpAmmoForever()<suspends>:void =
        AwaitMatchStart(Self)
        loop:
            Sleep(AmmoTopUpSeconds)
            for (P : GetPlayspace().GetPlayers()):
                AmmoGranter.GrantItem(P)
