# demo.py
#
# PROOF THAT THE REFINER AND THE CIRCUIT BREAKER ACTUALLY RUN.
#
# run.py generated three hostile ladders and all three passed the Evaluator on
# the first attempt, so the Refiner and the Circuit Breaker never got exercised
# and their code was never proven. This file proves both, and it does it by
# calling the real loop in run.py rather than a copy of it.
#
# Part 1, THE REFINER, uses one real Claude call:
#   The Cyber-Boar ladder in output/tier-cards.csv tops out at 5.020 m/s. The
#   player's run speed has never been measured; GDD_AMENDMENTS.md item 8 records
#   it as an assumption of 6.0 and names the risk. If the real figure is 5.0,
#   that top card outruns the player and kiting dies (GDD 2.2). This part drops
#   the ceiling to 5.0, lets the Evaluator fail the real ladder, and lets the
#   Refiner repair it.
#
# Part 2, THE CIRCUIT BREAKER, makes no Claude calls at all:
#   A stubborn stand-in generator hands back the same broken ladder every time,
#   no matter what the Refiner is asked to fix. This is the failure a circuit
#   breaker exists for: not a bad rule, but an AI that keeps confidently
#   returning the same wrong answer. The loop tries settings.MAX_REFINE_ATTEMPTS
#   times, gets nowhere, and escalates to the designer instead of writing a
#   broken card into the spreadsheet.
#
# Nothing here overwrites the output of run.py. It writes one new file.
#
# Run it with:   python demo.py
#
# Game: Sponsor Me, Slayers!  (UEFN / Verse)

import copy
import csv
import os

import run
import settings
from generator import ClaudeError

HERE = os.path.dirname(os.path.abspath(__file__))
CSV_PATH = os.path.join(HERE, "output", "tier-cards.csv")
DEMO_PATH = os.path.join(HERE, "output", "demo-refiner-and-breaker.txt")

# The ceiling to test against in Part 1. Amendment 8: "If the real figure is
# nearer 5.0 than 6.0, then T4 at 5.1 and T5 at 5.6 both outrun the player."
LOWER_CEILING = 5.0

# Keep the real functions so they can be put back after each part.
REAL_GENERATE = run.generate
REAL_REFINE = run.refine

# A ladder that breaks three rules, handed back unchanged every time it is asked
# to be fixed. Health climbs by a flat 20 instead of compounding at 8% per tier
# (GDD 5.5), and sprint climbs by a flat step to 6.5 m/s, above the player's run
# speed (Amendment 8). Walk and run keep the correct ratios, so the Evaluator's
# complaints stay focused on the three real breaks.
STUBBORN_HEALTH = [75, 95, 115, 135, 155]
STUBBORN_SPRINT = [4.0, 4.5, 5.0, 5.5, 6.5]
STUBBORN_CONCURRENT = [5, 6, 7, 8, 10]


def find_enemy(enemy_id):
    for enemy in settings.ENEMIES:
        if enemy["id"] == enemy_id:
            return enemy
    raise SystemExit(f"No enemy called {enemy_id} in settings.ENEMIES.")


def load_cards(display_name):
    """Read one hostile's five cards back out of output/tier-cards.csv."""
    cards = []
    with open(CSV_PATH, newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            if row["hostile"] != display_name:
                continue
            cards.append(
                {
                    "name": row["card_name"],
                    "tier_start": int(row["tier_start"]),
                    "tier_end": int(row["tier_end"]),
                    "health": int(row["health"]),
                    "walk": float(row["walk"]),
                    "run": float(row["run"]),
                    "sprint": float(row["sprint"]),
                    "max_concurrent": int(row["max_concurrent"]),
                }
            )
    if not cards:
        raise SystemExit(
            f"Found no {display_name} cards in {CSV_PATH}. Run run.py first."
        )
    return cards


def stubborn_ladder():
    """The same broken ladder, every single time."""
    cards = []
    for index, (start, end) in enumerate(settings.TIER_BLOCKS):
        sprint = STUBBORN_SPRINT[index]
        cards.append(
            {
                "name": f"CyberBoar_T{index + 1}",
                "tier_start": start,
                "tier_end": end,
                "health": STUBBORN_HEALTH[index],
                "walk": round(sprint * settings.WALK_AS_FRACTION_OF_SPRINT, 1),
                "run": round(sprint * settings.RUN_AS_FRACTION_OF_SPRINT, 1),
                "sprint": sprint,
                "max_concurrent": STUBBORN_CONCURRENT[index],
            }
        )
    return cards


def part_one(enemy, log):
    """Prove the Refiner repairs a real failure. One real Claude call."""
    run.say("=" * 60)
    run.say("PART 1 - THE REFINER (one real Claude call)")
    run.say("=" * 60)
    log.append("\n" + "=" * 55)
    log.append("PART 1 - THE REFINER")
    log.append(
        f"The real {enemy['display_name']} ladder from tier-cards.csv, checked "
        f"against a player run speed of {LOWER_CEILING} m/s instead of the "
        f"assumed {settings.PLAYER_RUN_SPEED} m/s (Amendment 8)."
    )
    log.append("=" * 55)

    real_cards = load_cards(enemy["display_name"])
    original_ceiling = settings.PLAYER_RUN_SPEED

    settings.PLAYER_RUN_SPEED = LOWER_CEILING
    run.generate = lambda _enemy: copy.deepcopy(real_cards)
    try:
        cards, status = run.process(enemy, log)
    except ClaudeError as problem:
        run.say(f"  STOPPED: {problem}")
        log.append(f"\nERROR: {problem}")
        return "error", None
    finally:
        settings.PLAYER_RUN_SPEED = original_ceiling
        run.generate = REAL_GENERATE

    return status, cards


def part_two(enemy, log):
    """Prove the Circuit Breaker escalates. No Claude calls."""
    run.say("=" * 60)
    run.say("PART 2 - THE CIRCUIT BREAKER (no Claude calls)")
    run.say("=" * 60)
    log.append("\n" + "=" * 55)
    log.append("PART 2 - THE CIRCUIT BREAKER")
    log.append(
        "A stubborn stand-in generator returns the same broken ladder every "
        "time the Refiner is asked to fix it. This is the failure the breaker "
        "exists for: an AI that keeps returning the same wrong answer."
    )
    log.append("=" * 55)

    run.generate = lambda _enemy: stubborn_ladder()
    run.refine = lambda _enemy, _cards, _evaluation: stubborn_ladder()
    try:
        cards, status = run.process(enemy, log)
    finally:
        run.generate = REAL_GENERATE
        run.refine = REAL_REFINE

    return status, cards


def main():
    os.makedirs(os.path.dirname(DEMO_PATH), exist_ok=True)
    enemy = find_enemy("CyberBoar")
    log = []

    refiner_status, refined_cards = part_one(enemy, log)
    breaker_status, _ = part_two(enemy, log)

    refiner_proven = refiner_status == "refined"
    breaker_proven = breaker_status == "escalated"

    verdict = [
        "",
        "=" * 55,
        "VERDICT",
        "=" * 55,
        f"Refiner repaired a real failure : "
        f"{'PROVEN' if refiner_proven else 'NOT PROVEN (status: ' + str(refiner_status) + ')'}",
        f"Circuit Breaker escalated       : "
        f"{'PROVEN' if breaker_proven else 'NOT PROVEN (status: ' + str(breaker_status) + ')'}",
    ]

    if refiner_proven and refined_cards:
        verdict.append("")
        verdict.append(f"The ladder the Refiner produced, all under {LOWER_CEILING} m/s:")
        for card in refined_cards:
            verdict.append(
                f"  {card['name']:<16} health {card['health']:>5}   "
                f"sprint {card['sprint']:.3f}"
            )

    for line in verdict:
        run.say(line)

    with open(DEMO_PATH, "w", encoding="utf-8") as handle:
        handle.write("Refiner and Circuit Breaker demonstration\n")
        handle.write("Sponsor Me, Slayers!  (UEFN / Verse)\n")
        handle.write("=" * 55 + "\n")
        handle.write("\n".join(log))
        handle.write("\n".join(verdict))
        handle.write("\n")

    run.say("")
    run.say(f"Written to output\\{os.path.basename(DEMO_PATH)}")

    return 0 if (refiner_proven and breaker_proven) else 1


if __name__ == "__main__":
    raise SystemExit(main())
