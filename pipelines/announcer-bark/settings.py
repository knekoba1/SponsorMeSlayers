# settings.py
#
# THE ANNOUNCER BARK AGENT'S ONLY DESIGN FILE.
#
# GDD Section 4 gives this agent one job: "Structures and compiles the sarcastic
# game-show commentator dialogue database in Verse, mapping barks to triggers.
# Creative dialogue is written manually by the human."
#
# So this file owns the TRIGGERS and the BUDGET. It does not own a single word of
# dialogue. Kailee's lines live in barks.py and nothing here reads, scores or
# rewrites them.
#
# Game: Sponsor Me, Slayers!  (UEFN / Verse)

# ---------------------------------------------------------------------------
# THE BUDGET
# ---------------------------------------------------------------------------
#
# GDD 5.3: "All 25 announcer barks load into memory at runtime. Never stream
# dialogue over the network; it caused stutter and ruined comedic timing." The
# cap is a hard 25 and the compiler refuses to emit past it.
BARK_BUDGET = 25

# GDD 5.3 again. A bark longer than this reads as a speech rather than a bark,
# and the commentator talks over the next thing that happens.
MAX_BARK_WORDS = 14

# ---------------------------------------------------------------------------
# THE TRIGGERS
# ---------------------------------------------------------------------------
#
# Kailee's ruling 2026-08-24 on the split. Each entry is the trigger key the
# Verse side will look up, how many lines it gets, and which system fires it.
# The "fires_from" column is what makes this checkable: every trigger names a
# file that already exists and already reaches that moment.
TRIGGERS = [
    ("MatchStart",        2, "StartingLoadoutManager, on the first spawn"),
    ("RankUp",            1, "CareerRankManager, GDD 2.6's rank advance"),
    ("WaveCleared",       2, "WaveManager, GDD 2.5's Room Won"),
    ("TierEscalation",    2, "WaveManager, the next Escalation Tier starting"),
    ("MultiKill",         3, "HypeMeterManager, its CLUSTER KILL"),
    ("CloseShave",        2, "HypeMeterManager, its CLOSE SHAVE"),
    ("HypeRisingStar",    1, "SimulatedAudience, crossing RisingStarAt"),
    ("HypeSuperstar",     1, "SimulatedAudience, crossing SuperstarAt"),
    ("HypePrimeTime",     1, "SimulatedAudience, crossing PrimeTimeAt"),
    ("CrateLanded",       2, "CrateManager, a crate reaching its hover height"),
    ("CrateOpened",       2, "CrateManager, a crate shot open"),
    ("DeathSaveOpened",   2, "DeathSaveManager, GDD 4.2's #DeathSaveTriggered"),
    ("DeathSaveSurvived", 1, "DeathSaveManager, the med kit reached in time"),
    ("RunLost",           3, "DeathSaveManager, GDD 2.5's Run Lost"),
]

# Where the compiled Verse database is written.
VERSE_OUTPUT = "../../Content/BarkDatabase.verse"

# The Verse class the database is compiled into. House style, CLAUDE.md
# section 10: snake_case class in a PascalCase file that matches it.
VERSE_CLASS = "bark_database"
