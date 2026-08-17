# run.py
#
# THE LOOP and THE CIRCUIT BREAKER, part 4 of 4.
#
# Runs Generate -> Evaluate -> Refine for each hostile type. If the Refiner
# cannot fix a ladder within settings.MAX_REFINE_ATTEMPTS tries, the Circuit
# Breaker stops and hands the problem to Kai rather than writing something
# broken into the spreadsheet.
#
# Run it with:   python run.py
#
# Game: Sponsor Me, Slayers!  (UEFN / Verse)

import csv
import os
import sys

import settings
from evaluator import evaluate
from generator import ClaudeError, generate
from refiner import refine

HERE = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.join(HERE, "output")
CSV_PATH = os.path.join(OUTPUT_DIR, "tier-cards.csv")
REPORT_PATH = os.path.join(OUTPUT_DIR, "evaluator-report.txt")

CSV_COLUMNS = [
    "hostile",
    "card_name",
    "tier_start",
    "tier_end",
    "health",
    "walk",
    "run",
    "sprint",
    "max_concurrent",
]


def say(message=""):
    print(message, flush=True)


def print_rules():
    say("Reading rules from the GDD and the amendments log:")
    say(f"  - Health rises exactly {settings.HEALTH_GROWTH_PER_TIER:.0%} per tier (GDD 5.5)")
    say(f"  - Hard cap at Escalation Tier {settings.MAX_TIER} (GDD 5.5)")
    say(f"  - Never more than {settings.MAX_CONCURRENT_HOSTILES} hostiles alive at once (GDD 5.3)")
    say(f"  - Speed must stay under the player's {settings.PLAYER_RUN_SPEED} m/s run speed (Amendment 8)")
    say(f"  - Run is {settings.RUN_AS_FRACTION_OF_SPRINT:.1%} of sprint, walk is {settings.WALK_AS_FRACTION_OF_SPRINT:.1%} (Amendment 8)")
    say()
    say("NOTE: the player's run speed has never been measured. It is an")
    say("assumption recorded in Amendment 8. Measure it, change the one number")
    say("in settings.py, and re-run to correct every card.")
    say()


def process(enemy, log):
    """Generate, evaluate and refine one hostile's ladder.

    Returns (cards, status) where status is 'clean', 'refined' or 'escalated'.
    """
    say(f"--- {enemy['display_name']} ---")
    log.append(f"=== {enemy['display_name']} ({enemy['id']}) ===")

    say("  Generating ... (this takes a minute)")
    cards = generate(enemy)

    attempts = 0
    while True:
        result = evaluate(cards, enemy)
        log.append(f"\nAttempt {attempts + 1}:\n{result['reason']}")

        if result["passed"]:
            if attempts == 0:
                say(f"  PASS on the first try. Score {result['score']}/10.")
                return cards, "clean"
            say(f"  PASS after {attempts} fix(es). Score {result['score']}/10.")
            return cards, "refined"

        say(f"  FAIL. Score {result['score']}/10. {len(result['problems'])} problem(s):")
        for problem in result["problems"]:
            say(f"    - {problem}")

        attempts += 1
        if attempts > settings.MAX_REFINE_ATTEMPTS:
            say(f"  CIRCUIT BREAKER: gave up after {settings.MAX_REFINE_ATTEMPTS} attempts.")
            say("  This one needs Kai. Nothing was written for it.")
            log.append(
                f"\nCIRCUIT BREAKER TRIPPED after "
                f"{settings.MAX_REFINE_ATTEMPTS} refine attempts. "
                f"Escalated to Kai. No cards written for this hostile."
            )
            return cards, "escalated"

        say(f"  Refining (attempt {attempts} of {settings.MAX_REFINE_ATTEMPTS}) ...")
        cards = refine(enemy, cards, result)


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    say("Sponsor Me, Slayers! - hostile tier card pipeline")
    say("=" * 55)
    say()
    print_rules()

    log = []
    rows = []
    tally = {"clean": 0, "refined": 0, "escalated": 0}

    for enemy in settings.ENEMIES:
        try:
            cards, status = process(enemy, log)
        except ClaudeError as problem:
            say(f"  STOPPED: {problem}")
            log.append(f"\nERROR for {enemy['display_name']}: {problem}")
            tally["escalated"] += 1
            say()
            continue

        tally[status] += 1
        if status != "escalated":
            for card in cards:
                rows.append(
                    {
                        "hostile": enemy["display_name"],
                        "card_name": card["name"],
                        "tier_start": card["tier_start"],
                        "tier_end": card["tier_end"],
                        "health": card["health"],
                        "walk": card["walk"],
                        "run": card["run"],
                        "sprint": card["sprint"],
                        "max_concurrent": card["max_concurrent"],
                    }
                )
        say()

    with open(CSV_PATH, "w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=CSV_COLUMNS)
        writer.writeheader()
        writer.writerows(rows)

    with open(REPORT_PATH, "w", encoding="utf-8") as handle:
        handle.write("Evaluator report - Sponsor Me, Slayers!\n")
        handle.write("=" * 55 + "\n\n")
        handle.write("\n".join(log))
        handle.write("\n")

    say("=" * 55)
    say(f"Done. Wrote {len(rows)} cards to output\\tier-cards.csv")
    say(f"Full checker notes are in output\\evaluator-report.txt")
    say()
    say(f"  {tally['clean']} hostile ladder(s) passed first try")
    say(f"  {tally['refined']} needed fixing and were repaired")
    say(f"  {tally['escalated']} handed back to Kai by the circuit breaker")
    say()
    say("Open tier-cards.csv in Excel, read it, and type the numbers you want")
    say("into UEFN by hand. Nothing here has touched the game.")

    return 0 if tally["escalated"] == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
