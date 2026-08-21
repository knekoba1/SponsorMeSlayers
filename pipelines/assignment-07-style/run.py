# run.py
#
# THE LOOP and THE CIRCUIT BREAKER, part 4 of 4.
#
# Run it with:
#
#   python run.py          the three graded demonstrations
#   python run.py --all    the demonstrations, then a real card for all nine items
#
# The demonstrations are the graded part. Each one asks the Generator for
# deliberately off-brand copy, then lets the Evaluator and the Refiner sort it out
# with nobody intervening. Every before, every score, every reason and every after
# is written to output/before-after.md.
#
# --all then runs the same loop as production work and writes the nine finished
# cards to output/crate-cards.txt, ready to be typed into the UEFN HUD device.
#
# Game: Sponsor Me, Slayers!  (UEFN / Verse)

import os
import sys

import settings
import styleguide
from evaluator import evaluate
from generator import ClaudeError, generate_clean, generate_offbrand
from refiner import refine

HERE = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.join(HERE, "output")
DEMO_PATH = os.path.join(OUTPUT_DIR, "before-after.md")
CARDS_PATH = os.path.join(OUTPUT_DIR, "crate-cards.txt")
LOG_PATH = os.path.join(OUTPUT_DIR, "evaluator-log.txt")
GUIDE_PATH = os.path.join(OUTPUT_DIR, "style-guide-as-the-agents-see-it.txt")


def say(message=""):
    print(message, flush=True)


def indent(text, prefix="    "):
    return "\n".join(prefix + line for line in text.splitlines())


def loop(text, item, log):
    """Evaluate and refine one card until it passes or the breaker trips.

    Returns (final_text, history, status) where history is a list of one entry per
    attempt and status is 'clean', 'refined' or 'escalated'.
    """
    history = []
    attempts = 0

    while True:
        result = evaluate(text, item)
        history.append({"text": text, "evaluation": result})
        log.append(
            "Attempt %d, score %d/10\n%s\n"
            % (attempts + 1, result["score"], result["reason"])
        )

        say("    Evaluator: %d/10" % result["score"])
        if result["hard"]:
            for problem in result["hard"]:
                say("      - " + problem)

        if result["passed"]:
            return text, history, ("clean" if attempts == 0 else "refined")

        attempts += 1
        if attempts > settings.MAX_REFINE_ATTEMPTS:
            say("    CIRCUIT BREAKER: gave up after %d refine attempts."
                % settings.MAX_REFINE_ATTEMPTS)
            say("    This card needs Kailee. Nothing was written for it.")
            log.append(
                "CIRCUIT BREAKER TRIPPED after %d refine attempts. Escalated to "
                "Kailee.\n" % settings.MAX_REFINE_ATTEMPTS
            )
            return text, history, "escalated"

        say("    Refining (attempt %d of %d) ..."
            % (attempts, settings.MAX_REFINE_ATTEMPTS))
        text = refine(text, item, result)


def run_demos(log):
    """The three graded demonstrations, one per violation class."""
    say("PART 1: THE THREE DEMONSTRATIONS")
    say("=" * 62)
    say()

    records = []
    for case in settings.DEMO_CASES:
        item = styleguide.find_item(case["item"])
        say("%s  (violation class: %s)" % (case["id"], case["violation_class"]))
        say("  Item: %s" % item["name"])
        log.append("=== %s : %s ===" % (case["id"], case["violation_class"]))

        say("    Generating deliberately off-brand copy ...")
        before = generate_offbrand(case)

        after, history, status = loop(before, item, log)
        records.append(
            {
                "case": case,
                "item": item,
                "before": before,
                "history": history,
                "after": after,
                "status": status,
            }
        )
        say("    %s" % status.upper())
        say()

    return records


def run_production(log):
    """A real card for every item, with the style guide in the Generator's hand."""
    say("PART 2: THE PRODUCTION RUN")
    say("=" * 62)
    say()

    finished = []
    for item in settings.ITEMS:
        say("%s (%s)" % (item["name"], item["slot"]))
        log.append("=== production : %s ===" % item["name"])

        say("    Generating ...")
        text = generate_clean(item)
        text, history, status = loop(text, item, log)
        say("    %s" % status.upper())
        say()

        if status != "escalated":
            finished.append({"item": item, "text": text})

    return finished


def write_demo_report(records):
    parts = [
        "# Assignment 7, before and after",
        "",
        "*Sponsor Me, Slayers!* crate pickup cards. Every line below was produced",
        "by the loop with no human intervention. The Generator was not shown the",
        "style guide on these three runs.",
        "",
    ]

    for number, record in enumerate(records, 1):
        case = record["case"]
        parts += [
            "---",
            "",
            "## Example %d: %s" % (number, case["violation_class"]),
            "",
            "**Item:** %s (%s slot, %s crate)"
            % (record["item"]["name"], record["item"]["slot"],
               record["item"]["tier"]),
            "",
            "**What the Generator was told to do:** %s" % case["steer"],
            "",
            "### BEFORE",
            "",
            "```",
            record["before"],
            "```",
            "",
        ]

        for attempt_number, entry in enumerate(record["history"], 1):
            result = entry["evaluation"]
            parts += [
                "### Evaluator, attempt %d" % attempt_number,
                "",
                "**SCORE: %d/10**" % result["score"],
                "",
                "**REASON:**",
                "",
                result["reason"],
                "",
            ]
            if attempt_number < len(record["history"]):
                parts += [
                    "### Refiner rewrite %d" % attempt_number,
                    "",
                    "```",
                    record["history"][attempt_number]["text"],
                    "```",
                    "",
                ]

        parts += [
            "### AFTER",
            "",
            "```",
            record["after"],
            "```",
            "",
            "**Outcome:** %s. %d evaluation(s), %d refiner rewrite(s)."
            % (record["status"], len(record["history"]),
               len(record["history"]) - 1),
            "",
        ]

    with open(DEMO_PATH, "w", encoding="utf-8") as handle:
        handle.write("\n".join(parts))


def write_cards(finished):
    parts = [
        "Sponsor Me, Slayers! - crate pickup cards",
        "=" * 55,
        "",
        "Every card below passed the style guide at %d/10 or better."
        % settings.PASS_SCORE,
        "Type these into the HUD message device by hand. Nothing here has",
        "touched the game.",
        "",
    ]
    for entry in finished:
        parts += ["-" * 55, "", entry["text"], ""]

    with open(CARDS_PATH, "w", encoding="utf-8") as handle:
        handle.write("\n".join(parts) + "\n")


def main():
    do_all = "--all" in sys.argv
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    say("Sponsor Me, Slayers! - Style Guide Agent")
    say("=" * 62)
    say()
    say("Enforcing three constraint types, all drawn from the GDD:")
    say("  1. Game vocabulary and lore accuracy (GDD 3.3, amendments 38 to 44)")
    say("  2. Tone and voice (GDD 1)")
    say("  3. Format and length (GDD 2.4, GDD 3.2)")
    say()
    say("A card passes at %d/10. The Refiner gets %d attempts before the"
        % (settings.PASS_SCORE, settings.MAX_REFINE_ATTEMPTS))
    say("circuit breaker hands it back to Kailee.")
    say()

    # Dump the guide exactly as the two agents receive it. It is generated from
    # settings.py, so this file is proof that the rules being enforced are the
    # rules that were written down, and not a second copy that has drifted.
    with open(GUIDE_PATH, "w", encoding="utf-8") as handle:
        handle.write(styleguide.style_guide_text())

    log = []
    try:
        records = run_demos(log)
        write_demo_report(records)
        say("Wrote output\\before-after.md")
        say()

        if do_all:
            finished = run_production(log)
            write_cards(finished)
            say("Wrote %d cards to output\\crate-cards.txt" % len(finished))
            say()
    except ClaudeError as problem:
        say("STOPPED: %s" % problem)
        log.append("ERROR: %s" % problem)
        return 1
    finally:
        with open(LOG_PATH, "w", encoding="utf-8") as handle:
            handle.write("Evaluator log - Sponsor Me, Slayers!\n")
            handle.write("=" * 55 + "\n\n")
            handle.write("\n".join(log) + "\n")

    say("=" * 62)
    escalated = [r for r in records if r["status"] == "escalated"]
    say("Done. %d of %d demonstrations were fixed by the loop."
        % (len(records) - len(escalated), len(records)))
    if escalated:
        say("%d hit the circuit breaker and need Kailee." % len(escalated))
    say("Full evaluator notes are in output\\evaluator-log.txt")

    return 1 if escalated else 0


if __name__ == "__main__":
    sys.exit(main())
