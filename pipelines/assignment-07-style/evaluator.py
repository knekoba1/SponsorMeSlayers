# evaluator.py
#
# THE EVALUATOR, part 2 of 4 in the Generate-Evaluate-Refine loop.
#
# Grades one crate pickup card against the style guide and returns a SCORE out of
# 10 plus a written REASON. It never returns a bare pass or fail: the Refiner
# cannot fix anything without being told what is wrong, in words.
#
# Two halves, on purpose:
#
#   1. HARD CHECKS, run locally in plain Python, no AI and no cost. Line shape,
#      character counts, exclamation marks, banned words. These are facts, and a
#      language model has no business having an opinion about them.
#
#   2. THE JUDGEMENT, run by Claude. Tone, voice, whether the joke is the show's
#      joke, whether the EFFECT line agrees with the item's real behaviour.
#
# The hard checks are handed to Claude as findings so its written reason includes
# them, and they also act as a floor: if a hard check failed, the card cannot pass
# no matter how generous the model feels.
#
# Game: Sponsor Me, Slayers!  (UEFN / Verse)

import re

import settings
import styleguide
from generator import ClaudeError, ask_claude

# Short all-capitals strings that are allowed inside card text.
CAPS_ALLOWED = {"SMG", "TV", "HUD"}


def split_lines(text):
    """The card's non-empty lines."""
    return [line.strip() for line in text.strip().splitlines() if line.strip()]


def read_fields(text):
    """Pull LABEL: value pairs out of the card. Missing labels come back absent."""
    fields = {}
    for line in split_lines(text):
        match = re.match(r"^\**\s*([A-Z][A-Z ]*?)\s*\**\s*:\s*(.*)$", line)
        if match:
            label = match.group(1).strip()
            if label in settings.CARD_LINES and label not in fields:
                fields[label] = match.group(2).strip().strip("*").strip()
    return fields


def hard_checks(text, item):
    """Everything that can be checked without a language model."""
    problems = []
    lines = split_lines(text)
    fields = read_fields(text)

    # Rule: exactly four lines, in order.
    if len(lines) != len(settings.CARD_LINES):
        problems.append(
            "FORMAT: the card has %d line(s), and the format requires exactly "
            "%d (%s)."
            % (len(lines), len(settings.CARD_LINES),
               ", ".join(settings.CARD_LINES))
        )

    missing = [label for label in settings.CARD_LINES if label not in fields]
    if missing:
        problems.append(
            "FORMAT: these required lines are missing or mislabelled: %s."
            % ", ".join(missing)
        )
    else:
        present_order = [
            label for label in
            [read_fields_label(line) for line in lines]
            if label in settings.CARD_LINES
        ]
        if present_order != settings.CARD_LINES:
            problems.append(
                "FORMAT: the lines are in the order %s, and the format requires "
                "%s." % (", ".join(present_order),
                         ", ".join(settings.CARD_LINES))
            )

    # Rule: the ITEM line is the exact canon name.
    if "ITEM" in fields:
        given = fields["ITEM"]
        expected = item["name"]
        resolved = settings.ACCEPTED_SHORTHAND.get(given, given)
        if resolved != expected:
            problems.append(
                "VOCABULARY: the ITEM line says %r and the canon name is %r."
                % (given, expected)
            )

    # Rule: the SLOT line is one of the four GDD 3.2 slots, and the right one.
    if "SLOT" in fields:
        given = fields["SLOT"]
        if given not in settings.VALID_SLOTS:
            problems.append(
                "VOCABULARY: the SLOT line says %r, which is not one of the "
                "four upgrade slots (%s)."
                % (given, ", ".join(settings.VALID_SLOTS))
            )
        elif given != item["slot"]:
            problems.append(
                "VOCABULARY: the SLOT line says %r and this item belongs in the "
                "%r slot." % (given, item["slot"])
            )

    # Rule: length ceiling on the two prose lines.
    for label in ("PLUG", "EFFECT"):
        if label in fields:
            length = len(fields[label])
            if length > settings.MAX_LINE_CHARS:
                problems.append(
                    "LENGTH: the %s line is %d characters and the ceiling is "
                    "%d. It needs to lose %d."
                    % (label, length, settings.MAX_LINE_CHARS,
                       length - settings.MAX_LINE_CHARS)
                )

    # Rule: exclamation marks.
    bangs = text.count("!")
    if bangs > settings.MAX_EXCLAMATION_MARKS:
        problems.append(
            "FORMAT: the card uses %d exclamation marks and the ceiling is %d."
            % (bangs, settings.MAX_EXCLAMATION_MARKS)
        )

    # Rule: no em dashes.
    if "—" in text or "–" in text:
        problems.append("FORMAT: the card contains a dash character that the "
                        "format does not allow. Use a comma or a full stop.")

    # The prose to inspect. When the card has no recognisable PLUG or EFFECT line
    # at all, the whole reply is the prose, otherwise off-brand vocabulary in a
    # shapeless blob of text would slip through unchecked.
    prose = " ".join(
        fields.get(label, "") for label in ("PLUG", "EFFECT")
    ).strip()
    if not prose:
        prose = text

    # Rule: banned generic vocabulary.
    for term in settings.BANNED_TERMS:
        # The trailing group catches the plural, so "monsters" fails on
        # "monster" the way a reader would expect it to.
        pattern = r"\b%s(?:s|es)?\b" % re.escape(term)
        if re.search(pattern, prose, re.IGNORECASE):
            problems.append(
                "VOCABULARY: the card uses the banned generic word %r. Replace "
                "it with the game's own term." % term
            )

    # Rule: no shouted words inside the prose.
    for word in re.findall(r"\b[A-Z]{3,}\b", prose):
        if word not in CAPS_ALLOWED and word not in settings.CARD_LINES:
            problems.append(
                "FORMAT: the card shouts the word %r in capitals, which the "
                "format does not allow." % word
            )

    return problems


def read_fields_label(line):
    """The label at the start of one line, or an empty string."""
    match = re.match(r"^\**\s*([A-Z][A-Z ]*?)\s*\**\s*:", line)
    return match.group(1).strip() if match else ""


def build_prompt(text, item, problems):
    findings = (
        "\n".join("  - " + p for p in problems)
        if problems
        else "  (none: every mechanical rule passed)"
    )

    return """{guide}

You are the Evaluator. Grade the card below against the style guide above.

THE ITEM THIS CARD IS FOR:
{brief}

THE CARD TO GRADE:
---
{text}
---

A local checker has already verified the mechanical rules. Its findings are facts,
not opinions. Include every one of them in your reason and let them pull the score
down:
{findings}

Now judge what the checker cannot: tone and voice, whether this sounds like the
Network selling something to a contestant it fully expects to die, whether the
EFFECT line agrees with the item's true behaviour, and whether a stranger reading
this card could tell which game it belongs to.

Reply in exactly this shape and nothing else:

SCORE: [X/10]
REASON: [name every rule that was broken and say plainly what to change. If
nothing was broken, say so.]""".format(
        guide=styleguide.style_guide_text(),
        brief=styleguide.item_brief(item),
        text=text,
        findings=findings,
    )


def parse_reply(reply):
    """Pull the score and the reason out of the Evaluator's answer."""
    score_match = re.search(r"SCORE\s*:?\s*\[?\s*(\d{1,2})", reply, re.IGNORECASE)
    if not score_match:
        raise ClaudeError(
            "The Evaluator's reply had no SCORE line.\nReply began: %s"
            % reply[:200]
        )
    score = int(score_match.group(1))
    score = max(1, min(10, score))

    reason_match = re.search(
        r"REASON\s*:?\s*\]?\s*(.*)", reply, re.IGNORECASE | re.DOTALL
    )
    reason = reason_match.group(1).strip() if reason_match else ""
    reason = reason.strip("[]").strip()
    if not reason:
        raise ClaudeError("The Evaluator gave a score with no reason.")
    return score, reason


def evaluate(text, item):
    """Grade one card.

    Returns a dictionary with:
      score    an integer out of 10
      reason   the written explanation the Refiner works from
      passed   True when the score reaches settings.PASS_SCORE
      hard     the list of mechanical problems found locally
    """
    problems = hard_checks(text, item)
    score, reason = parse_reply(ask_claude(build_prompt(text, item, problems)))

    # A mechanical failure is a fact. The card cannot pass while one stands, even
    # if the model was feeling generous.
    capped = False
    if problems and score >= settings.PASS_SCORE:
        score = settings.PASS_SCORE - 1
        capped = True

    if capped:
        reason = (
            "%s\n\n[Score held at %d/10 by the local checker: %d mechanical rule "
            "violation(s) are still present.]" % (reason, score, len(problems))
        )

    return {
        "score": score,
        "reason": reason,
        "passed": score >= settings.PASS_SCORE,
        "hard": problems,
    }
