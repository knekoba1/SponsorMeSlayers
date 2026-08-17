# settings.py
#
# Every number the pipeline uses lives here, so nothing is buried in the code.
# This is the only file Kai ever needs to open.
#
# Game: Sponsor Me, Slayers!  (UEFN / Verse)

# ---------------------------------------------------------------------------
# THE PLAYER
# ---------------------------------------------------------------------------

# The player's ordinary run speed in metres per second.
#
# WARNING: this has never been measured. GDD_AMENDMENTS.md item 8 records it as
# an assumption: a Fortnite base of about 5.0 m/s times the 1.2 Movement Speed
# Multiplier on the Third Person Controls device. Amendment 8 explains how to
# measure it for real (fort_character.GetLinearVelocity, Fortnite digest 8440).
#
# When it is measured, change this one number and re-run. Every card corrects
# itself.
PLAYER_RUN_SPEED = 6.0

# The player has no sprint. Sprinting is switched off in Island Settings because
# it lowers the weapon, and GDD 2.2 requires continuous fire while moving. So the
# ceiling hostiles must stay under is the ordinary run speed above.


# ---------------------------------------------------------------------------
# THE RULES THE EVALUATOR ENFORCES
# ---------------------------------------------------------------------------

# GDD 5.5: "Completing a room cleared wave escalates difficulty by exactly 8%
# per tier."  Health carries the full 8%.
HEALTH_GROWTH_PER_TIER = 0.08

# GDD_AMENDMENTS.md item 8: speed scales every tier, but gently, so it never
# passes the player. A literal 8% would take a 4.0 m/s hostile to roughly 19 m/s
# by Tier 21, which makes kiting impossible (GDD 2.2) and flattens the Career
# Sponsor Rank ladder (GDD 2.6).
SPEED_GROWTH_PER_TIER = 0.021

# GDD_AMENDMENTS.md item 8: the ratios the Tier 1 Swarmer card already used.
RUN_AS_FRACTION_OF_SPRINT = 0.875
WALK_AS_FRACTION_OF_SPRINT = 0.625

# GDD 5.5: "scaling is hard-capped at Escalation Tier 21".
MAX_TIER = 21

# GDD 5.3: "the wave spawner caps concurrent active hostiles at 40 bots."
MAX_CONCURRENT_HOSTILES = 40

# Movement speed lives on the npc_character_definition and cannot be changed
# while the game is running (recorded in WaveManager.verse). So five cards cover
# all 21 tiers in blocks, exactly as the Cyber-Swarmer ladder does.
TIER_BLOCKS = [(1, 4), (5, 8), (9, 12), (13, 16), (17, 21)]


# ---------------------------------------------------------------------------
# THE CIRCUIT BREAKER
# ---------------------------------------------------------------------------

# How many times the Refiner may try to fix one failing ladder before the
# pipeline gives up and hands the problem to Kai instead of shipping something
# broken.
MAX_REFINE_ATTEMPTS = 3


# ---------------------------------------------------------------------------
# THE ENEMIES TO GENERATE
# ---------------------------------------------------------------------------
#
# GDD 5.4 commits to "2 cybernetic hostile models (melee Swarmer, heavy Ranged
# Tank)". Only the Swarmer exists. Kai's call on 2026-08-16 was to build all
# three of the hostiles the GDD names, which is a divergence from 5.4's count of
# two and needs its own amendments entry.
#
# For reference, the existing Cyber-Swarmer ladder is:
#   health  40 / 54 / 74 / 101 / 137
#   sprint  4.000 / 4.347 / 4.724 / 5.133 / 5.578
#
# The bands below are guide rails for the Generator, not hard rules. The
# Evaluator does not check them. It checks the GDD rules above.

ENEMIES = [
    {
        "id": "RangedTank",
        "display_name": "Heavy Ranged Tank",
        "role": (
            "Slow, heavily armoured, fires from mid range. The toughest of the "
            "three and the slowest to close distance. The player should have to "
            "commit real time to killing one. Named in GDD 5.4 as the second "
            "hostile model."
        ),
        "tier1_health_band": (90, 130),
        "tier1_sprint_band": (2.0, 2.8),
        "concurrent_band": (4, 8),
    },
    {
        "id": "RangedSentinel",
        "display_name": "Ranged Sentinel",
        "role": (
            "Fragile, nearly stationary, shoots from across the arena and "
            "appears in lines. Cannot be kited, because it does not chase. The "
            "player must move sideways while firing at it. GDD 3.3 describes it "
            "as the Sponsor Sniper's target: 'lines of distant, stationary "
            "Ranged Sentinels'."
        ),
        "tier1_health_band": (25, 45),
        "tier1_sprint_band": (0.5, 1.2),
        "concurrent_band": (3, 6),
    },
    {
        "id": "CyberBoar",
        "display_name": "Cyber-Boar",
        "role": (
            "Armoured melee charger. Fast, mid-range health, closes distance "
            "hard and gets staggered backward into other hostiles by the "
            "Shotgun's chain knockback. GDD 3.3 describes it as 'armored "
            "Cyber-Boars' launched backward by high-impact blasts."
        ),
        "tier1_health_band": (60, 90),
        "tier1_sprint_band": (3.4, 4.0),
        "concurrent_band": (5, 10),
    },
]
