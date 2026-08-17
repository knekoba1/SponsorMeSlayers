# generator.py
#
# THE GENERATOR, part 1 of 4 in the Generate-Evaluate-Refine pipeline.
#
# Asks Claude to propose a full five-card stat ladder for one hostile type.
# It is deliberately allowed to get the arithmetic wrong. Catching that is the
# Evaluator's job, and "what did the pipeline catch that you would have missed?"
# is worth 2 points on the rubric.
#
# Claude is reached through the `claude` command line tool that is already
# installed and logged in on this machine. No API key, no extra cost.

import json
import re
import shutil
import subprocess

import settings


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
            f"Claude did not answer within {timeout_seconds} seconds."
        )

    if finished.returncode != 0:
        raise ClaudeError(
            f"The claude command failed (exit code {finished.returncode}).\n"
            f"{finished.stderr.strip()}"
        )

    reply = (finished.stdout or "").strip()
    if not reply:
        raise ClaudeError("Claude returned an empty reply.")
    return reply


def extract_json(text):
    """Pull a JSON object out of Claude's reply, fenced or not."""
    fenced = re.search(r"```(?:json)?\s*(.*?)```", text, re.DOTALL)
    if fenced:
        text = fenced.group(1)

    start = text.find("{")
    end = text.rfind("}")
    if start == -1 or end == -1 or end < start:
        raise ClaudeError(
            "Claude's reply did not contain a JSON object.\n"
            f"Reply began: {text[:200]}"
        )

    try:
        return json.loads(text[start : end + 1])
    except json.JSONDecodeError as problem:
        raise ClaudeError(f"Claude's JSON could not be read: {problem}")


def build_prompt(enemy):
    blocks = ", ".join(f"{a}-{b}" for a, b in settings.TIER_BLOCKS)
    low_health, high_health = enemy["tier1_health_band"]
    low_sprint, high_sprint = enemy["tier1_sprint_band"]
    low_count, high_count = enemy["concurrent_band"]

    return f"""You are generating enemy stat cards for a top-down twin-stick
arcade shooter called "Sponsor Me, Slayers!", built in Unreal Editor for
Fortnite.

Produce a five-card difficulty ladder for one hostile type.

HOSTILE: {enemy['display_name']}
ROLE: {enemy['role']}

Each card covers a block of Escalation Tiers: {blocks}. Movement speed cannot be
changed while the game is running, which is why five cards cover all
{settings.MAX_TIER} tiers instead of one card per tier.

RULES, taken from the game's design document:
1. Health rises by exactly {settings.HEALTH_GROWTH_PER_TIER:.0%} per tier,
   compounded. A card's health is the Tier 1 health multiplied by
   1.{int(settings.HEALTH_GROWTH_PER_TIER * 100):02d} raised to the power of
   (the card's first tier minus 1). Round to a whole number.
2. Sprint speed rises by {settings.SPEED_GROWTH_PER_TIER:.1%} per tier,
   compounded the same way. Round to three decimal places.
3. Sprint speed must stay BELOW {settings.PLAYER_RUN_SPEED} metres per second on
   every card. That is the player's run speed. A hostile that outruns the player
   makes evasion impossible.
4. Run speed is {settings.RUN_AS_FRACTION_OF_SPRINT:.3f} times sprint. Walk
   speed is {settings.WALK_AS_FRACTION_OF_SPRINT:.3f} times sprint. Round both
   to one decimal place.
5. No more than {settings.MAX_CONCURRENT_HOSTILES} of this hostile alive at once.

STARTING POINTS (guidance, not rules):
- Tier 1 health somewhere around {low_health} to {high_health}
- Tier 1 sprint somewhere around {low_sprint} to {high_sprint} m/s
- Between {low_count} and {high_count} alive at once, rising gently across cards

Reply with ONLY a JSON object in exactly this shape, and nothing else:

{{
  "cards": [
    {{
      "name": "{enemy['id']}_T1",
      "tier_start": 1,
      "tier_end": 4,
      "health": 0,
      "walk": 0.0,
      "run": 0.0,
      "sprint": 0.000,
      "max_concurrent": 0
    }}
  ]
}}

Give five cards, one per tier block, named {enemy['id']}_T1 through
{enemy['id']}_T5."""


def generate(enemy):
    """Ask Claude for a five-card ladder. Returns a list of card dictionaries."""
    reply = ask_claude(build_prompt(enemy))
    data = extract_json(reply)

    cards = data.get("cards")
    if not isinstance(cards, list):
        raise ClaudeError("Claude's JSON had no 'cards' list.")
    return cards
