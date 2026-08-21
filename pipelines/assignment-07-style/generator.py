# generator.py
#
# THE GENERATOR, part 1 of 4 in the Generate-Evaluate-Refine loop.
#
# Writes crate pickup card copy. It has two modes:
#
#   generate_offbrand(case)  the three graded demonstrations. The Generator is
#                            NOT shown the style guide and is deliberately
#                            steered into breaking one rule. Catching that is
#                            the Evaluator's job, unaided.
#
#   generate_clean(item)     the production run. The Generator IS shown the style
#                            guide, and the loop cleans up whatever still slips.
#
# Claude is reached through the `claude` command line tool that is already
# installed and logged in on this machine. No API key, no extra cost. This is the
# same transport assignment 6 used.
#
# Game: Sponsor Me, Slayers!  (UEFN / Verse)

import shutil
import subprocess

import settings
import styleguide


class ClaudeError(Exception):
    """Raised when the claude command cannot be reached or returns nothing."""


def ask_claude(prompt, timeout_seconds=300):
    """Send one prompt to Claude and return its reply as plain text."""
    claude_path = shutil.which("claude")
    if claude_path is None:
        raise ClaudeError(
            "The 'claude' command was not found. It should be at "
            "C:\\Users\\kaile\\.local\\bin\\claude.exe"
        )

    try:
        finished = subprocess.run(
            [claude_path, "-p", prompt],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=timeout_seconds,
        )
    except subprocess.TimeoutExpired:
        raise ClaudeError(
            "Claude did not answer within %d seconds." % timeout_seconds
        )

    if finished.returncode != 0:
        raise ClaudeError(
            "The claude command failed (exit code %d).\n%s"
            % (finished.returncode, (finished.stderr or "").strip())
        )

    reply = (finished.stdout or "").strip()
    if not reply:
        raise ClaudeError("Claude returned an empty reply.")
    return reply


def strip_fences(text):
    """Drop a markdown code fence if the reply arrived wrapped in one."""
    lines = [line for line in text.strip().splitlines()]
    if lines and lines[0].strip().startswith("```"):
        lines = lines[1:]
    if lines and lines[-1].strip().startswith("```"):
        lines = lines[:-1]
    return "\n".join(lines).strip()


def build_offbrand_prompt(case):
    """A prompt with NO style guide in it, steered into one specific violation.

    When the case sets "keep_shape", the Generator is handed the four-line card
    shape and nothing else: no tone rules, no vocabulary list. That isolates the
    violation, so the tone demonstration breaks only tone and the vocabulary
    demonstration breaks only vocabulary. The format demonstration is given no
    shape at all, which is how it breaks format and length.
    """
    item = styleguide.find_item(case["item"])

    if case.get("keep_shape"):
        shape = """
LAY IT OUT IN EXACTLY FOUR SHORT LINES, like this, and keep each of the last two
lines to one short sentence of well under {maxchars} characters:

ITEM: {name}
SLOT: {slot}
PLUG: <one short sentence introducing it>
EFFECT: <one short sentence saying what it does>
""".format(
            maxchars=settings.MAX_LINE_CHARS,
            name=item["name"],
            slot=item["slot"],
        )
    else:
        shape = ""

    return """Write the in-game pickup description for a supply crate item in a
video game.

{brief}

HOW TO WRITE IT:
{steer}
{shape}
Reply with the description text only. No preamble, no explanation, no notes about
what you did.""".format(
        brief=styleguide.item_brief(item),
        steer=case["steer"],
        shape=shape,
    )


def build_clean_prompt(item):
    """A prompt that DOES include the style guide, for the production run."""
    return """{guide}

Write the crate pickup card for the following item.

{brief}

Reply with the four lines only. No preamble, no explanation, no notes.""".format(
        guide=styleguide.style_guide_text(), brief=styleguide.item_brief(item)
    )


def generate_offbrand(case):
    """Produce deliberately off-brand copy for one demonstration case."""
    return strip_fences(ask_claude(build_offbrand_prompt(case)))


def generate_clean(item):
    """Produce a first-draft card with the style guide in hand."""
    return strip_fences(ask_claude(build_clean_prompt(item)))
