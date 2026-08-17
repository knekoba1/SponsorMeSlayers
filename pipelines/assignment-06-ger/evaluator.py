# evaluator.py
#
# THE EVALUATOR, part 2 of 4 in the Generate-Evaluate-Refine pipeline.
#
# There is no AI in this file. It is arithmetic.
#
# That is deliberate, and it is the course's own advice. From Class 8: "instead
# of having an agent playtest the game, just write a unit test that evaluates
# the player experience. Now you have a deterministic check; you're not using
# tokens every time you test."
#
# Every rule below traces to a line in Kailee_Nekoba_GDD_Final_Draft.pdf or to
# GDD_AMENDMENTS.md. A grader can open either document and find the sentence.

import settings

# What a failure costs, out of 10.
COST_SHAPE = 2
COST_HEALTH = 2
COST_SPEED_CEILING = 4  # breaks kiting (GDD 2.2), which 5.7 calls uncuttable
COST_SPEED_GROWTH = 1
COST_RATIOS = 1
COST_CONCURRENCY = 2

REQUIRED_FIELDS = (
    "name",
    "tier_start",
    "tier_end",
    "health",
    "walk",
    "run",
    "sprint",
    "max_concurrent",
)


def _is_number(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def _check_shape(cards):
    """Is this even a well-formed five-card ladder covering tiers 1 to 21?"""
    problems = []

    if len(cards) != len(settings.TIER_BLOCKS):
        problems.append(
            f"Expected {len(settings.TIER_BLOCKS)} cards, got {len(cards)}."
        )
        return problems

    for index, card in enumerate(cards):
        label = card.get("name", f"card {index + 1}")

        for field in REQUIRED_FIELDS:
            if field not in card:
                problems.append(f"{label}: missing the '{field}' value.")
            elif field != "name" and not _is_number(card[field]):
                problems.append(f"{label}: '{field}' is not a number.")

        expected_start, expected_end = settings.TIER_BLOCKS[index]
        if card.get("tier_start") != expected_start or card.get("tier_end") != expected_end:
            problems.append(
                f"{label}: covers tiers {card.get('tier_start')}-{card.get('tier_end')}, "
                f"but card {index + 1} must cover tiers {expected_start}-{expected_end}."
            )

        end = card.get("tier_end")
        if _is_number(end) and end > settings.MAX_TIER:
            problems.append(
                f"{label}: reaches Tier {end}. GDD 5.5 hard-caps escalation at "
                f"Tier {settings.MAX_TIER}."
            )

    return problems


def _check_health(cards):
    """GDD 5.5: difficulty rises by exactly 8% per tier, compounded."""
    problems = []
    base = cards[0]["health"]

    for card in cards:
        steps = card["tier_start"] - 1
        expected = round(base * (1 + settings.HEALTH_GROWTH_PER_TIER) ** steps)
        actual = card["health"]
        if abs(actual - expected) > 1:
            problems.append(
                f"{card['name']}: health is {actual}, but "
                f"{settings.HEALTH_GROWTH_PER_TIER:.0%} per tier compounded from "
                f"{base} over {steps} tiers gives {expected} (GDD 5.5)."
            )

    previous = None
    for card in cards:
        if previous is not None and card["health"] <= previous:
            problems.append(
                f"{card['name']}: health {card['health']} is not higher than the "
                f"previous card's {previous}. Difficulty must rise (GDD 5.5)."
            )
        previous = card["health"]

    return problems


def _check_speed_ceiling(cards):
    """Amendment 8: a hostile must never outrun the player."""
    problems = []
    for card in cards:
        if card["sprint"] >= settings.PLAYER_RUN_SPEED:
            problems.append(
                f"{card['name']}: sprint {card['sprint']} m/s is at or above the "
                f"player's run speed of {settings.PLAYER_RUN_SPEED} m/s. Kiting "
                f"becomes impossible (GDD 2.2), and the Career Sponsor Rank "
                f"ladder flattens (GDD 2.6) because every run ends at the same "
                f"tier regardless of skill."
            )
    return problems


def _check_speed_growth(cards):
    """Amendment 8: speed scales at 2.1% per tier, compounded."""
    problems = []
    base = cards[0]["sprint"]

    for card in cards:
        steps = card["tier_start"] - 1
        expected = base * (1 + settings.SPEED_GROWTH_PER_TIER) ** steps
        if abs(card["sprint"] - expected) > 0.02:
            problems.append(
                f"{card['name']}: sprint is {card['sprint']}, but "
                f"{settings.SPEED_GROWTH_PER_TIER:.1%} per tier compounded from "
                f"{base} over {steps} tiers gives {expected:.3f} (Amendment 8)."
            )

    return problems


def _check_ratios(cards):
    """Amendment 8: run is 87.5% of sprint, walk is 62.5%."""
    problems = []
    for card in cards:
        expected_run = card["sprint"] * settings.RUN_AS_FRACTION_OF_SPRINT
        expected_walk = card["sprint"] * settings.WALK_AS_FRACTION_OF_SPRINT

        if abs(card["run"] - expected_run) > 0.06:
            problems.append(
                f"{card['name']}: run is {card['run']}, but "
                f"{settings.RUN_AS_FRACTION_OF_SPRINT:.3f} of sprint "
                f"{card['sprint']} gives {expected_run:.1f} (Amendment 8)."
            )
        if abs(card["walk"] - expected_walk) > 0.06:
            problems.append(
                f"{card['name']}: walk is {card['walk']}, but "
                f"{settings.WALK_AS_FRACTION_OF_SPRINT:.3f} of sprint "
                f"{card['sprint']} gives {expected_walk:.1f} (Amendment 8)."
            )
    return problems


def _check_concurrency(cards):
    """GDD 5.3: never more than 40 hostiles alive at once."""
    problems = []
    for card in cards:
        if card["max_concurrent"] > settings.MAX_CONCURRENT_HOSTILES:
            problems.append(
                f"{card['name']}: {card['max_concurrent']} alive at once exceeds "
                f"the {settings.MAX_CONCURRENT_HOSTILES}-bot cap in GDD 5.3."
            )
        if card["max_concurrent"] < 1:
            problems.append(
                f"{card['name']}: {card['max_concurrent']} alive at once means "
                f"the hostile never spawns."
            )
    return problems


def evaluate(cards, enemy):
    """Score a ladder out of 10 and say plainly what is wrong with it."""
    all_problems = []
    score = 10

    shape_problems = _check_shape(cards)
    if shape_problems:
        # Nothing else can be checked against a malformed ladder.
        reason = "\n".join(f"  - {p}" for p in shape_problems)
        return {
            "passed": False,
            "score": 0,
            "problems": shape_problems,
            "reason": (
                f"SCORE: 0/10\nREASON: the ladder is not the right shape, so no "
                f"other rule could be checked.\n{reason}"
            ),
        }

    for checker, cost in (
        (_check_health, COST_HEALTH),
        (_check_speed_ceiling, COST_SPEED_CEILING),
        (_check_speed_growth, COST_SPEED_GROWTH),
        (_check_ratios, COST_RATIOS),
        (_check_concurrency, COST_CONCURRENCY),
    ):
        problems = checker(cards)
        if problems:
            all_problems.extend(problems)
            score -= cost

    score = max(0, score)
    passed = not all_problems

    if passed:
        reason = (
            f"SCORE: 10/10\nREASON: every card for the "
            f"{enemy['display_name']} satisfies GDD 5.5 (8% per tier, capped at "
            f"Tier {settings.MAX_TIER}), GDD 5.3 (40-hostile cap) and "
            f"Amendment 8 (speed under the player's "
            f"{settings.PLAYER_RUN_SPEED} m/s run speed)."
        )
    else:
        listed = "\n".join(f"  - {p}" for p in all_problems)
        reason = (
            f"SCORE: {score}/10\nREASON: {len(all_problems)} rule violation(s) "
            f"in the {enemy['display_name']} ladder.\n{listed}"
        )

    return {
        "passed": passed,
        "score": score,
        "problems": all_problems,
        "reason": reason,
    }
