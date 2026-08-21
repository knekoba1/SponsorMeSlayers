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
# Claude is reached two ways, so this runs on someone else's machine as well as
# on Kailee's:
#
#   1. ANTHROPIC_API_KEY set  ->  the official anthropic Python SDK.
#   2. otherwise              ->  the `claude` command line tool, already
#                                 installed and logged in on Kailee's machine.
#                                 No API key, no extra cost. This is the
#                                 transport assignment 6 used.
#
# There is also a third way to see the loop work with no credentials at all:
# `python run.py --replay` replays the saved transcript. See run.py.
#
# Game: Sponsor Me, Slayers!  (UEFN / Verse)

import os
import shutil
import subprocess

import settings
import styleguide

# The model the pipeline judges and rewrites with.
MODEL = "claude-opus-5"

# Generous, because the Evaluator writes long reasons on purpose: the Refiner has
# nothing else to work from.
MAX_TOKENS = 16000


class ClaudeError(Exception):
    """Raised when Claude cannot be reached or returns nothing."""


def ask_claude(prompt, timeout_seconds=300):
    """Send one prompt to Claude and return its reply as plain text."""
    if os.environ.get("ANTHROPIC_API_KEY"):
        return ask_via_api(prompt)
    return ask_via_cli(prompt, timeout_seconds)


def ask_via_api(prompt):
    """Ask Claude through the official SDK. Used when an API key is present."""
    try:
        import anthropic
    except ImportError:
        raise ClaudeError(
            "ANTHROPIC_API_KEY is set but the anthropic package is not "
            "installed. Run 'pip install anthropic', or unset the key to fall "
            "back to the claude command line tool."
        )

    client = anthropic.Anthropic()
    try:
        response = client.messages.create(
            model=MODEL,
            max_tokens=MAX_TOKENS,
            messages=[{"role": "user", "content": prompt}],
        )
    except anthropic.APIError as problem:
        raise ClaudeError("The Claude API call failed: %s" % problem)

    reply = "".join(
        block.text for block in response.content if block.type == "text"
    ).strip()
    if not reply:
        raise ClaudeError("Claude returned an empty reply.")
    return reply


def ask_via_cli(prompt, timeout_seconds=300):
    """Ask Claude through the local `claude` command. No API key needed."""
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
        brief=styleguide.item_brief(item, include_joke=False),
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
