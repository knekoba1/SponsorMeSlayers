# barks.py
#
# KAILEE'S BARK LINES. THIS FILE IS HERS AND NO AGENT MAY TOUCH IT.
#
# CLAUDE.md standing rule 3 and GDD Section 4: the sarcastic commentator lines
# are hand-written by the human designer. Claude may structure this database and
# map it to triggers, and may never invent, draft, rewrite or improve a line in
# it. The rest of this pipeline has no language model in it for that reason.
#
# HOW TO FILL IT IN. Replace each empty string with one line of commentary.
# Leave the ones you have not written as "" and the checker will tell you which
# are still open rather than complaining.
#
# The trigger names and the number of slots come from settings.py. Do not add or
# remove slots here; change the split there and re-run the checker.

BARKS = {
    # StartingLoadoutManager, on the first spawn
    "MatchStart": [
        "",
        "",
    ],

    # CareerRankManager, GDD 2.6's rank advance
    "RankUp": [
        "",
    ],

    # WaveManager, GDD 2.5's Room Won
    "WaveCleared": [
        "",
        "",
    ],

    # WaveManager, the next Escalation Tier starting
    "TierEscalation": [
        "",
        "",
    ],

    # HypeMeterManager, its CLUSTER KILL
    "MultiKill": [
        "",
        "",
        "",
    ],

    # HypeMeterManager, its CLOSE SHAVE
    "CloseShave": [
        "",
        "",
    ],

    # SimulatedAudience, crossing RisingStarAt
    "HypeRisingStar": [
        "",
    ],

    # SimulatedAudience, crossing SuperstarAt
    "HypeSuperstar": [
        "",
    ],

    # SimulatedAudience, crossing PrimeTimeAt
    "HypePrimeTime": [
        "",
    ],

    # CrateManager, a crate reaching its hover height
    "CrateLanded": [
        "",
        "",
    ],

    # CrateManager, a crate shot open
    "CrateOpened": [
        "",
        "",
    ],

    # DeathSaveManager, GDD 4.2's #DeathSaveTriggered
    "DeathSaveOpened": [
        "",
        "",
    ],

    # DeathSaveManager, the med kit reached in time
    "DeathSaveSurvived": [
        "",
    ],

    # DeathSaveManager, GDD 2.5's Run Lost
    "RunLost": [
        "",
        "",
        "",
    ],

}
