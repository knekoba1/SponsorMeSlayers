# settings.py
#
# THE STYLE GUIDE, expressed as data so the agents can enforce it.
#
# Every rule below traces to a sentence in Kailee_Nekoba_GDD_Final_Draft.pdf or a
# dated ruling in GDD_AMENDMENTS.md. Nothing here was invented for the assignment.
# This is the only file that needs editing to change what the pipeline enforces.
#
# Game: Sponsor Me, Slayers!  (UEFN / Verse)

# ---------------------------------------------------------------------------
# WHAT THE PIPELINE WRITES
# ---------------------------------------------------------------------------
#
# Crate pickup cards. GDD 3.2 says supply crates "trigger instantly upon player
# collision to maintain momentum", so the readout that names what was just
# grabbed is on screen for a moment and then gone. Nine items exist across the
# four crate tiers and not one of them has its pickup text written.
#
# These are UI item cards, NOT announcer barks. The 25 announcer barks are
# hand-written by Kailee and no agent in this project may draft or rewrite them.


# ---------------------------------------------------------------------------
# CONSTRAINT TYPE 1 OF 3: GAME VOCABULARY AND LORE ACCURACY
# ---------------------------------------------------------------------------

# The exact in-world names. GDD 3.3 for the item names, GDD 2.2 and 5.4 for the
# hostiles, amendment 49 for the Cyber-Boar being a robot.
CANON_TERMS = [
    "Standard Pulse Blaster",
    "Submachine Gun",
    "Shotgun",
    "Sponsor Sniper",
    "Rocket Launcher",
    "Sponsor Aid",
    "Sponsor Aegis",
    "Flaming Ammo",
    "Icy Rounds",
    "Cyber-Swarmer",
    "Cyber-Boar",
    "Ranged Sentinel",
    "Heavy Ranged Tank",
    "Hype",
    "Sponsor Hype Meter",
    "Hype Call",
    "Escalation Tier",
    "Death Save",
    "the Network",
    "contestant",
    "Underdog",
    "Rising Star",
    "Superstar",
    "Prime Time",
]

# "SMG" is accepted shorthand for the Submachine Gun, because amendment 38's own
# crate tier table writes it that way.
ACCEPTED_SHORTHAND = {"SMG": "Submachine Gun"}

# Generic fantasy and shooter filler. Any of these on a card is a violation: it
# is the exact "if a stranger can't tell what game this is" failure. A game show
# run by a Network that never pays out does not sell potions or mana.
BANNED_TERMS = [
    "potion",
    "elixir",
    "mana",
    "magic",
    "spell",
    "hero",
    "adventurer",
    "warrior",
    "monster",
    "creature",
    "beast",
    "dungeon",
    "loot box",
    "hit points",
    "buff",
    "debuff",
    "DPS",
    "player character",
    "the user",
    "enemy unit",
    "power-up",
]

# Kailee's ruling, 2026-08-20: no slang and no meme vocabulary on a card. Slang
# has a short shelf life and the Network is a polished corporate broadcaster.
# These are checked the same way the generic words above are.
BANNED_SLANG = [
    "no cap",
    "rizz",
    "sus",
    "lowkey",
    "highkey",
    "bussin",
    "goated",
    "cringe",
    "yeet",
    "fr fr",
    "bestie",
    "girlboss",
    "main character energy",
    "it's giving",
    "slaps",
    "banger",
    "vibe",
]

BANNED_TERMS = BANNED_TERMS + BANNED_SLANG


# ---------------------------------------------------------------------------
# CONSTRAINT TYPE 2 OF 3: TONE AND VOICE
# ---------------------------------------------------------------------------
#
# GDD 1 (Setting and Narrative Tone): "broad, self-aware game-show comedy in the
# tradition of Smash TV and Total Carnage. Corporate hostility and glitz are
# played for laughs."
#
# GDD 1 (Contestant and Enemy Lore): contestants volunteer "to escape crushing
# financial debt", and "the Network notoriously never pays survivors because no
# player has ever completed a run alive".
#
# So the voice on a pickup card is the Network's own advertising copy: relentlessly
# upbeat about something that is plainly awful for the contestant.

TONE_RULES = [
    "SARCASTIC AND CRUEL IN THE SAME BREATH. This is the hardest rule and the "
    "most important one. Every PLUG line must do BOTH at once: say the opposite "
    "of what it means (insincere praise, mock congratulation, fake generosity, "
    "fake concern) AND land a jab at the contestant in the same sentence. Cruel "
    "but sincere fails. Sarcastic but harmless fails. GDD 1 asks for "
    "\"sarcastic on-screen commentary\" and for \"corporate hostility played "
    "for laughs\", and it wants them together.",
    "THE JAB IS USUALLY ABOUT MONEY. Contestants volunteer \"to escape crushing "
    "financial debt\" (GDD 1), so the funniest cruelty is financial: the item is "
    "billed, invoiced, surcharged, deducted, added to the balance, or counted "
    "against a payout that will never come. Reach for this first (Kailee's "
    "ruling, 2026-08-20).",
    "A DEATH JAB IS THE VARIATION, NOT THE DEFAULT. The Network may also point "
    "out that nobody has ever finished a run alive, that previous contestants "
    "did worse, or that the crowd is enjoying this. Use it for variety so nine "
    "cards do not tell the same joke (Kailee's ruling, 2026-08-20).",
    "The Network's register is polished corporate broadcast: pleasant, upbeat, "
    "well-mannered, and monstrous underneath. The comedy is the gap between the "
    "manners and the content (GDD 1).",
    "Never sincere, never heartfelt, never warm, never encouraging. Any line "
    "that would genuinely comfort the contestant is a failure (GDD 1).",
    "Played for laughs, never for menace, dread, horror or gore (GDD 1). It "
    "should land as a joke, not as a threat.",
    "No heroic or epic register. The contestant is a debtor on television, not "
    "a chosen one (GDD 1).",
    "No slang, no meme vocabulary, no internet speak. The comedy comes from the "
    "corporate polish sitting on top of something monstrous, not from the "
    "vocabulary (Kailee's ruling, 2026-08-20).",
    "The EFFECT line is the opposite voice: flat, factual, mechanically exact. "
    "The joke is the gap between the sales pitch and the plain fact.",
]


# ---------------------------------------------------------------------------
# CONSTRAINT TYPE 3 OF 3: FORMAT AND LENGTH
# ---------------------------------------------------------------------------
#
# GDD 2.4 introduces systems gradually "to flatten the learning curve and prevent
# HUD clutter", and GDD 3.2 makes the pickup instant. A card that cannot be read
# at a glance, mid-fight, is a card the player never reads at all.

CARD_LINES = ["ITEM", "SLOT", "PLUG", "EFFECT"]

# Hard ceiling for the PLUG and EFFECT lines, counted without the label.
MAX_LINE_CHARS = 90

# GDD 5.2 protects comedic timing. One exclamation mark is a game show. Four is
# noise, and the show's own title already spends one.
MAX_EXCLAMATION_MARKS = 1

# The four slots, named exactly as GDD 3.2 names them.
VALID_SLOTS = ["Weapon", "Consumable", "Shield", "Ammo Modifier"]

FORMAT_RULES = [
    "Exactly four lines, in this order: ITEM, SLOT, PLUG, EFFECT.",
    "Each line is the label, then a colon, then a single space, then the text.",
    "ITEM is the exact canon item name and nothing else.",
    "SLOT is one of: " + ", ".join(VALID_SLOTS) + ".",
    "PLUG is one sentence, at most {0} characters.".format(MAX_LINE_CHARS),
    "EFFECT is one sentence, at most {0} characters.".format(MAX_LINE_CHARS),
    "At most {0} exclamation mark across the whole card.".format(
        MAX_EXCLAMATION_MARKS
    ),
    "No em dashes, no bullet points, no markdown, no emoji, and no ALL CAPS "
    "words inside the PLUG or EFFECT text.",
]


# ---------------------------------------------------------------------------
# THE LOOP
# ---------------------------------------------------------------------------

# The Refiner is asked for a perfect 10. A card is accepted at 9, because the
# last point is a judgement call about whether a joke actually lands and looping
# forever chasing it would burn tokens for nothing.
PASS_SCORE = 9

# The Refiner is told to aim for this many characters rather than the ceiling.
# Language models cannot count characters reliably, and a first run lost a card
# to the circuit breaker at 91 characters against a ceiling of 90. Aiming short
# leaves room for the miscount.
REFINER_TARGET_CHARS = 78

# How many times the Refiner may try before the pipeline gives up and hands the
# card back to Kailee rather than shipping something off-brand.
#
# Raised from 3 to 5 on 2026-08-20. The tone rules got much crueller that day and
# the Evaluator got correspondingly harder to satisfy: a card would clear its
# vocabulary and format faults on the first rewrite and then sit at 7 or 8 out of
# 10 on voice alone, which burned the whole allowance. Five attempts lets the
# voice keep improving after the mechanical faults are gone. The bar itself was
# NOT lowered, which was the other way to fix this and the wrong one.
MAX_REFINE_ATTEMPTS = 5


# ---------------------------------------------------------------------------
# THE NINE ITEMS
# ---------------------------------------------------------------------------
#
# Slots from GDD 3.2. Behaviour from GDD 3.3. Tier pools from amendment 38.
# Rocket Launcher from amendment 39. Aegis hit count from amendment 41. Modifier
# duration from amendment 42. Flaming Ammo burn from amendment 44. Icy Rounds
# stacking from amendment 43.
#
# The "facts" string is what the EFFECT line must agree with. The Evaluator
# checks the card against it, which is how a wrong number counts as a lore
# violation rather than a style opinion.

ITEMS = [
    {
        "name": "Submachine Gun",
        "slot": "Weapon",
        "tier": "Underdog",
        "facts": "Rapid parallel yellow laser fire. 50-round magazine, 1.2 "
                 "second reload. Inflicts bleed for 5 damage per second over 3 "
                 "seconds. Best against low-health Cyber-Swarmers.",
    },
    {
        "name": "Shotgun",
        "slot": "Weapon",
        "tier": "Underdog",
        "facts": "Wide horizontal 5-pellet red-mist spread. 5-shell tube, 2.5 "
                 "second shell-by-shell reload. Chain knockback staggers "
                 "hostiles and launches Cyber-Boars backward into others.",
    },
    {
        "name": "Sponsor Sniper",
        "slot": "Weapon",
        "tier": "Rising Star",
        "facts": "Slow-charging red laser sight, sharp sonic crack. 1-round "
                 "chamber, 3.0 second bolt-action reload. Piercing beam goes "
                 "through lines of distant, stationary Ranged Sentinels.",
    },
    {
        "name": "Rocket Launcher",
        "slot": "Weapon",
        "tier": "Prime Time",
        "facts": "Arrives loaded with exactly six rockets and no resupply "
                 "exists anywhere in the arena. It runs dry inside one wave and "
                 "the contestant drops back to the Standard Pulse Blaster.",
    },
    {
        "name": "Sponsor Aid",
        "slot": "Consumable",
        "tier": "Rising Star",
        "facts": "A parachuting golden roasted turkey leg with a green pulsing "
                 "overlay. Restores 25% of maximum health instantly on contact. "
                 "Also the item that answers the 3-second Death Save.",
    },
    {
        "name": "Sponsor Aegis",
        "slot": "Shield",
        "tier": "Superstar",
        "facts": "A bright pink translucent hexagonal bubble. Absorbs exactly 3 "
                 "hostile hits and has no timer, so it lasts until the third "
                 "hit lands. Enables aggressive crowd-ramming.",
    },
    {
        "name": "Flaming Ammo",
        "slot": "Ammo Modifier",
        "tier": "Prime Time",
        "facts": "Orange neon incendiary trails. Lasts 30 seconds. Adds a "
                 "ticking burn of 5 damage per second over 3 seconds on top of "
                 "Submachine Gun, Shotgun or Sponsor Sniper shots.",
    },
    {
        "name": "Icy Rounds",
        "slot": "Ammo Modifier",
        "tier": "Prime Time",
        "facts": "Pale-blue crystalline trails, sharp ice-crack sound. Lasts 30 "
                 "seconds. Slows a hostile by 20% per stack up to 3 stacks, "
                 "for kiting dense melee swarms.",
    },
    {
        "name": "Standard Pulse Blaster",
        "slot": "Weapon",
        "tier": "not in crates, it is the default sidearm",
        "facts": "Glowing blue plasma, distinct sci-fi ping, moderate fire "
                 "rate. Infinite ammo. The fallback the contestant returns to "
                 "whenever a crate weapon runs out.",
    },
]


# ---------------------------------------------------------------------------
# THE THREE DEMONSTRATION CASES
# ---------------------------------------------------------------------------
#
# Each one steers the Generator into a DIFFERENT rule so the Evaluator has to
# catch three different kinds of failure. The Generator is not shown the style
# guide on these runs, which is the whole point: the loop has to find the problem
# on its own and fix it without anyone stepping in.
#
# "keep_shape" hands the Generator the four-line card shape and nothing else, no
# tone rules and no vocabulary list. That isolates the violation: demo 1 breaks
# only the tone rules, demo 2 breaks only the vocabulary rules, and demo 3 is
# given no shape at all so it breaks only format and length.

DEMO_CASES = [
    {
        "id": "demo-1-tone",
        "violation_class": "Tone and voice",
        "item": "Sponsor Aid",
        "keep_shape": True,
        "steer": "Write it with genuine warmth and compassion, the way a "
                 "hospital charity would describe emergency medical relief. Be "
                 "sincere, comforting and hopeful. Reassure the reader that "
                 "help is on the way and that someone truly cares about them.",
    },
    {
        "id": "demo-2-vocabulary",
        "violation_class": "Game vocabulary and lore accuracy",
        "item": "Sponsor Aegis",
        "keep_shape": True,
        "steer": "Use standard fantasy role-playing game language. Call it a "
                 "magic barrier, talk about the hero, the monsters and their "
                 "hit points, and say it absorbs damage for a short duration. "
                 "Do not use any product names.",
    },
    {
        "id": "demo-3-format",
        "violation_class": "Format and length",
        "item": "Rocket Launcher",
        "keep_shape": False,
        "steer": "Write three flowing paragraphs of rich, atmospheric prose "
                 "with plenty of exclamation marks and dramatic emphasis. Do "
                 "not use any labels, headings or fixed structure. Take as much "
                 "space as the writing needs.",
    },
]
