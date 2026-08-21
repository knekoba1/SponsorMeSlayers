# run.py
#
# THE LOOP and THE CIRCUIT BREAKER, part 4 of 4.
#
# Run it with:
#
#   python run.py               the three graded demonstrations
#   python run.py --all         the demonstrations, then all nine real cards
#   python run.py --production  the nine real cards only
#   python run.py --replay      replay a saved run, no credentials needed
#   python run.py --report      rebuild before-after.md from the saved run
#
# The demonstrations are the graded part. Each one asks the Generator for
# deliberately off-brand copy, then lets the Evaluator and the Refiner sort it out
# with nobody intervening. Every before, every score, every reason and every after
# is written to output/before-after.md.
#
# The production run is the full five-agent pipeline: Proposer writes eight
# variations, the Adversarial Critic attacks them, the Judge prunes, and the
# winner goes through the same Evaluate-Refine loop. It writes the nine finished
# cards to output/crate-cards.txt, ready to be typed into the UEFN HUD device.
#
# Game: Sponsor Me, Slayers!  (UEFN / Verse)

import json
import os
import sys

import settings
import styleguide
from evaluator import evaluate
import proposer
from generator import ClaudeError, generate_offbrand
from refiner import refine

HERE = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.join(HERE, "output")
DEMO_PATH = os.path.join(OUTPUT_DIR, "before-after.md")
CARDS_PATH = os.path.join(OUTPUT_DIR, "crate-cards.txt")
LOG_PATH = os.path.join(OUTPUT_DIR, "evaluator-log.txt")
GUIDE_PATH = os.path.join(OUTPUT_DIR, "style-guide-as-the-agents-see-it.txt")

# The machine-readable record of a real run. --replay reads this back, which is
# how the loop can be watched on a machine with no Claude credentials at all.
TRANSCRIPT_PATH = os.path.join(OUTPUT_DIR, "transcript.json")

# The Proposer/Critic/Judge record: all eight variations per item, the
# critic's objections, and every score, so the pruning is auditable.
PANEL_PATH = os.path.join(OUTPUT_DIR, "proposal-panel.json")


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

    # The Refiner always works from the BEST card so far, not the most recent
    # one. Refining from the latest attempt makes the loop lose ground: one run
    # went 7, then 8, then 8, then regressed to 4, and every rewrite after that
    # was built on the 4. Rewriting from the best attempt means the loop can
    # only ever hold or improve, and the escalation path hands back the best card
    # instead of whatever the last roll of the dice produced.
    best_text = text
    best_result = None

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

        if best_result is None or result["score"] > best_result["score"]:
            best_text, best_result = text, result
        elif result["score"] < best_result["score"]:
            say("    (that is worse than the best so far at %d/10, so the next "
                "rewrite goes back to that one)" % best_result["score"])

        if result["passed"]:
            return text, history, ("clean" if attempts == 0 else "refined")

        attempts += 1
        if attempts > settings.MAX_REFINE_ATTEMPTS:
            say("    CIRCUIT BREAKER: gave up after %d refine attempts."
                % settings.MAX_REFINE_ATTEMPTS)
            say("    Best reached was %d/10. Handing that back to Kailee rather "
                "than shipping it." % best_result["score"])
            log.append(
                "CIRCUIT BREAKER TRIPPED after %d refine attempts. Best score "
                "%d/10. Escalated to Kailee.\n"
                % (settings.MAX_REFINE_ATTEMPTS, best_result["score"])
            )
            return best_text, history, "escalated"

        say("    Refining (attempt %d of %d) ..."
            % (attempts, settings.MAX_REFINE_ATTEMPTS))
        text = refine(best_text, item, best_result)


def run_demos(log):
    """The three graded demonstrations, one per violation class."""
    say("PART 1: THE THREE DEMONSTRATIONS")
    say("=" * 62)
    say()

    records = []
    for case in settings.DEMO_CASES:
        # The joke angle is a production-only instruction. A demonstration is
        # about catching a tone, vocabulary or format failure, and judging the
        # off-brand draft against an angle it was never given would fail it for
        # the wrong reason. So the whole demonstration runs without one.
        item = dict(styleguide.find_item(case["item"]))
        item.pop("joke", None)
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
    """A real card for every item, the full five-agent pipeline.

    Proposer writes eight variations, the Adversarial Critic attacks all of them,
    the Judge scores and prunes, and only then does the winner go into the
    ordinary Evaluate-Refine loop to be polished to a pass.

    The demonstrations in run_demos deliberately skip the first three stages. Their
    job is to start off-brand and be caught, and a Judge picking the best of eight
    would hide the failure the assignment asks to see.
    """
    say("PART 2: THE PRODUCTION RUN")
    say("=" * 62)
    say()
    say("Five agents per item: Proposer, Adversarial Critic, Judge, then the")
    say("Evaluator and Refiner loop on the winner.")
    say()

    finished = []
    panel = []
    for item in settings.ITEMS:
        say("%s (%s)" % (item["name"], item["slot"]))
        log.append("=== production : %s ===" % item["name"])

        winner, record = proposer.best_of(item, say)
        log.append("Judge scores: %s" % ", ".join(
            "#%d %.1f" % (row["index"], row["score"]) for row in record["scores"]
        ))
        log.append("Why the winner: %s" % record["why_the_winner"])
        panel.append({"item_name": item["name"], "panel": record})

        text, history, status = loop(winner, item, log)
        say("    %s" % status.upper())
        say()

        if status != "escalated":
            finished.append({"item": item, "text": text})

    with open(PANEL_PATH, "w", encoding="utf-8") as handle:
        json.dump(panel, handle, indent=2)

    return finished


def plug_line(text):
    """The PLUG line of a card, or the first sentence if it has no PLUG line."""
    for line in text.splitlines():
        stripped = line.strip().strip("*").strip()
        if stripped.upper().startswith("PLUG:"):
            return stripped[5:].strip()
    flat = " ".join(text.split())
    return (flat[:160] + " ...") if len(flat) > 160 else flat


def rule_trace(record):
    """The rule that caught this example, and where the correction landed.

    Assignment 4's feedback praised the multi-pass loop but noted the inline
    demonstration was "only fully visible for one of your three content types".
    This block is printed for every example, so the trace from the exact rule text
    to the violating line to the corrected line is visible for all of them.
    """
    case = record["case"]
    parts = [
        "### The rule that caught it",
        "",
        "**Rule quoted** (%s):" % case.get("rule_source", "the style guide"),
        "",
        "> %s" % case.get("rule_quoted", "(not recorded)"),
        "",
        "**Where it landed:**",
        "",
        "| | The line |",
        "|---|---|",
        "| Before | %s |" % plug_line(record["before"]).replace("|", r"\|"),
        "| After | %s |" % plug_line(record["after"]).replace("|", r"\|"),
        "",
    ]

    # A catch on a later pass is the thing worth showing: it proves the checker
    # re-scans every rewrite rather than filtering once and trusting the result.
    later = []
    for number, entry in enumerate(record["history"], 1):
        if number == 1:
            continue
        hard = entry["evaluation"]["hard"] if "evaluation" in entry else entry["hard"]
        for problem in hard:
            later.append("pass %d: %s" % (number, problem))
    if later:
        parts += [
            "**Caught again on a later pass**, which is the loop re-scanning its "
            "own corrections rather than filtering once:",
            "",
        ]
        parts += ["- " + line for line in later]
        parts += [""]

    return parts


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
        ] + rule_trace(record)

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

    saved = []
    for record in records:
        saved.append(
            {
                "case": record["case"],
                "item_name": record["item"]["name"],
                "item_slot": record["item"]["slot"],
                "item_tier": record["item"]["tier"],
                "before": record["before"],
                "after": record["after"],
                "status": record["status"],
                "attempts": [
                    {
                        "text": entry["text"],
                        "score": entry["evaluation"]["score"],
                        "reason": entry["evaluation"]["reason"],
                        "hard": entry["evaluation"]["hard"],
                    }
                    for entry in record["history"]
                ],
            }
        )
    with open(TRANSCRIPT_PATH, "w", encoding="utf-8") as handle:
        json.dump(saved, handle, indent=2)


def replay():
    """Replay a saved run, step by step, with no credentials needed.

    A grader cannot run this pipeline for real without either an API key or a
    logged-in `claude` command, so this reads back the exact transcript the loop
    produced: every draft, every score, every reason, in order. Nothing here
    calls Claude, and nothing here can invent a result, because no model is
    involved at all.
    """
    if not os.path.exists(TRANSCRIPT_PATH):
        say("No saved transcript found at output/transcript.json.")
        say("Run 'python run.py' with credentials first to record one.")
        return 1

    with open(TRANSCRIPT_PATH, encoding="utf-8") as handle:
        saved = json.load(handle)

    say("Sponsor Me, Slayers! - Style Guide Agent, REPLAY")
    say("=" * 62)
    say()
    say("This is a replay of a recorded run, not a live one. No model is being")
    say("called. Every score and reason below is exactly what the Evaluator")
    say("returned at the time, read back from output/transcript.json.")
    say()

    for number, record in enumerate(saved, 1):
        case = record["case"]
        say("-" * 62)
        say("EXAMPLE %d: %s" % (number, case["violation_class"]))
        say("Item: %s (%s slot)" % (record["item_name"], record["item_slot"]))
        say()
        say("The Generator was told to: %s" % case["steer"])
        say()
        say("BEFORE:")
        say(indent(record["before"]))
        say()

        for attempt_number, attempt in enumerate(record["attempts"], 1):
            say("  Evaluator, pass %d: SCORE %d/10"
                % (attempt_number, attempt["score"]))
            for problem in attempt["hard"]:
                say("    local checker: " + problem)
            say()
            say(indent(attempt["reason"], "    "))
            say()
            if attempt_number < len(record["attempts"]):
                say("  Refiner rewrite %d:" % attempt_number)
                say(indent(record["attempts"][attempt_number]["text"]))
                say()

        say("AFTER:")
        say(indent(record["after"]))
        say()
        say("Outcome: %s" % record["status"])
        say()

    say("=" * 62)
    fixed = len([r for r in saved if r["status"] != "escalated"])
    say("%d of %d examples were fixed by the loop." % (fixed, len(saved)))
    return 0


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


def rebuild_report():
    """Rewrite before-after.md from the saved transcript, with no model calls.

    The report format changed after a run had already been recorded, and paying
    for a second run to get a nicer document would be wasteful. The transcript
    holds every draft, score and reason, so the document can be rebuilt from it
    exactly.
    """
    if not os.path.exists(TRANSCRIPT_PATH):
        say("No saved transcript at output/transcript.json to rebuild from.")
        return 1

    with open(TRANSCRIPT_PATH, encoding="utf-8") as handle:
        saved = json.load(handle)

    by_id = {case["id"]: case for case in settings.DEMO_CASES}

    records = []
    for entry in saved:
        # Take the case definition from settings, not from the transcript: the
        # transcript may predate fields that were added to the case later.
        case = by_id.get(entry["case"]["id"], entry["case"])
        records.append(
            {
                "case": case,
                "item": {
                    "name": entry["item_name"],
                    "slot": entry["item_slot"],
                    "tier": entry["item_tier"],
                },
                "before": entry["before"],
                "after": entry["after"],
                "status": entry["status"],
                "history": [
                    {
                        "text": attempt["text"],
                        "evaluation": {
                            "score": attempt["score"],
                            "reason": attempt["reason"],
                            "hard": attempt["hard"],
                        },
                    }
                    for attempt in entry["attempts"]
                ],
            }
        )

    write_demo_report(records)
    say("Rebuilt output/before-after.md from the saved transcript.")
    say("%d example(s), no model calls made." % len(records))
    return 0


def main():
    if "--replay" in sys.argv:
        return replay()

    if "--report" in sys.argv:
        return rebuild_report()

    do_all = "--all" in sys.argv
    only_production = "--production" in sys.argv
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
        if only_production:
            finished = run_production(log)
            write_cards(finished)
            say("Wrote %d cards to output/crate-cards.txt" % len(finished))
            return 0

        records = run_demos(log)
        write_demo_report(records)
        say("Wrote output/before-after.md")
        say()

        if do_all:
            finished = run_production(log)
            write_cards(finished)
            say("Wrote %d cards to output/crate-cards.txt" % len(finished))
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
    say("Full evaluator notes are in output/evaluator-log.txt")

    return 1 if escalated else 0


if __name__ == "__main__":
    sys.exit(main())
