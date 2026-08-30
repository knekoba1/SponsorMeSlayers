# settings.py
#
# THE DESIGN FILE. The trigger list, the line budget and the word cap. Kai's
# lines live in barks.py and nothing here may change one of them.
#
# =====================================================================
# THE BUDGET IS 41, AMENDED FROM 25. KAI'S RULING, 2026-08-28.
#
# The GDD fixes the count at 25 in three places: 5.2 preloads "all 25", 5.4's
# asset budget lists "25 compiled announcer bark audio strings" under a
# commitment to strict asset caps, and 5.6 makes Week 5 "write and map the 25".
# Kai wrote 41 and ruled that the number moves rather than the writing. See
# amendment 90.
#
# THE SPLIT IS 33 AND 8, AND KAI'S REASON IS THE WHOLE DESIGN. 33 are the host's
# barks, fired by a moment in the game. The other 8 are SponsorRead, which are
# the ticker adverts spoken aloud, and Kai's own words for what they are for:
# "the ads are there to sprinkle in when the announcer runs out of things to say
# or has said something repeatedly". They are FILLER, drawn from when the moment
# pool has nothing fresh, not a reward for reaching a moment.
# =====================================================================

BARK_BUDGET = 45

# How many of the budget are the host reacting to a moment. The rest are ads.
MOMENT_BARKS = 33

# =====================================================================
# THE WORD CAP, RAISED FROM 14 TO 22 ON 2026-08-28.
#
# 14 was set before any line existed, to stop a bark still talking when the next
# thing happens. Five of Kai's 41 are longer than that and every one of them is
# long on purpose: the two longest are a DEAD AIR line and the AI disclosure,
# and DEAD AIR only exists because nothing is happening, so there is nothing for
# it to talk over. The longest line Kai wrote is 19 words.
#
# 22 leaves headroom without the cap becoming meaningless. It is a WARNING, not
# a rule: the checker says which lines are long and compiles them anyway.
# =====================================================================

# RAISED 22 -> 27 ON 2026-08-30 for Kai's ElevenLabs credit line, which is a
# SponsorRead. The cap exists so a bark is not still talking when the next
# thing happens, and an ad only ever plays because nothing is happening.
MAX_BARK_WORDS = 27

# =====================================================================
# THE TRIGGERS. These are Kai's own ten categories from the 2026-08-28 document,
# not the fourteen guessed at on 2026-08-24 before any line was written. The old
# list had triggers Kai wrote nothing for (RankUp, CloseShave, three Hype tiers,
# CrateOpened, DeathSaveOpened, DeathSaveSurvived) and lacked four Kai did write
# for (cash pickup, low health, dead air, the ads).
#
# THE LAST TWO ARE NOT WIRED TO ANYTHING YET and are marked so below. Everything
# above them names a system that already exists and already reaches that moment.
# =====================================================================

TRIGGERS = [
    ("ShowIntro",   3, "BroadcastScreen, the moment START SHOW hands the arena over"),
    ("RoundStart",  4, "WaveManager, a wave beginning"),
    ("KillStreak",  4, "HypeMeterManager, its CLUSTER KILL"),
    ("CashPickup",  3, "cash_drop_manager, a prop walked over"),
    ("CrateDrop",   3, "CrateManager, a crate reaching its hover height"),
    ("LowHealth",   3, "HypeMeterManager, the contestant below the Underdog Boost line"),
    ("RoundClear",  3, "WaveManager, GDD 2.5's Room Won"),
    ("SignOff",     2, "GameOverScreen, the run lost"),
    ("DeadAir",     7, "NOT WIRED YET. Needs an idle timer: nothing has happened for a while"),
    ("SponsorRead", 8, "NOT WIRED YET. The filler pool, drawn from when a moment has nothing fresh"),

    # ADDED 2026-08-29, Kai: "i dont see much for the announcer to say stuff when
    # the audience orders a crate or props though", and earlier the same day,
    # "should we add more lines like when the tank appears for the first time and
    # the boars and the sniper so the audience knows whats going on".
    #
    # THE BUDGET GOES 41 -> 53 BECAUSE OF THESE. Amendment 90 set 41; GDD 5.2's
    # rule is that every line is held in memory rather than streamed, which a
    # dozen more lines does not threaten.
    # A SLOT COUNT OF 0 MEANS "WAITING FOR KAI", NOT "CUT". The checker refuses
    # to compile when barks.py and this file disagree, so a moment Kai has not
    # written yet sits at 0 here and the number goes up with the words. The
    # trigger exists either way and the host simply stays quiet.
    ("CrateCalled",  5, "SimulatedAudience, the crowd chanting for a crate before it falls"),
    ("PrizeLanded",  0, "PrizeVault, a prize won off a crate"),
    ("FirstTank",    0, "NOT WIRED YET. The first Heavy Elite Tank of a run walking in"),
    ("FirstBoar",    0, "NOT WIRED YET. The first Cyber-Boar of a run"),
    ("FirstSniper",  0, "NOT WIRED YET. The first Ranged Sentinel of a run"),
]

VERSE_OUTPUT = "../../Content/BarkDatabase.verse"
VERSE_CLASS = "bark_database"
