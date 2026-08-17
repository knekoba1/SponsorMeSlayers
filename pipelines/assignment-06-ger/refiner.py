# refiner.py
#
# THE REFINER, part 3 of 4 in the Generate-Evaluate-Refine pipeline.
#
# Takes the ladder that failed and the Evaluator's plain-English reason, and
# asks Claude to fix exactly what was named. It does not re-generate from
# scratch: the ladder's design intent is kept, only the broken numbers move.

import json

import settings
from generator import ClaudeError, ask_claude, extract_json


def build_prompt(enemy, cards, evaluation):
    return f"""You previously generated a five-card enemy stat ladder for a
top-down twin-stick shooter. An automatic checker found rule violations.

HOSTILE: {enemy['display_name']}
ROLE: {enemy['role']}

THE LADDER YOU PRODUCED:
{json.dumps({"cards": cards}, indent=2)}

WHAT THE CHECKER FOUND:
{evaluation['reason']}

Fix every problem listed above. Change only what is broken; keep the design
intent of the ladder intact.

Reminders of the rules:
- Health rises by exactly {settings.HEALTH_GROWTH_PER_TIER:.0%} per tier,
  compounded from the Tier 1 card. Whole numbers.
- Sprint rises by {settings.SPEED_GROWTH_PER_TIER:.1%} per tier, compounded from
  the Tier 1 card. Three decimal places.
- Sprint must stay BELOW {settings.PLAYER_RUN_SPEED} m/s on every card. If the
  top card breaches it, lower the Tier 1 sprint and recompute the whole ladder.
  Never raise the player's speed.
- Run is {settings.RUN_AS_FRACTION_OF_SPRINT:.3f} of sprint, walk is
  {settings.WALK_AS_FRACTION_OF_SPRINT:.3f} of sprint, both to one decimal.
- No card may exceed {settings.MAX_CONCURRENT_HOSTILES} alive at once.
- The five cards cover tiers {", ".join(f"{a}-{b}" for a, b in settings.TIER_BLOCKS)}.

Reply with ONLY the corrected JSON object, same shape as before, and nothing
else."""


def refine(enemy, cards, evaluation):
    """Ask Claude to repair a failing ladder. Returns the corrected cards."""
    reply = ask_claude(build_prompt(enemy, cards, evaluation))
    data = extract_json(reply)

    corrected = data.get("cards")
    if not isinstance(corrected, list):
        raise ClaudeError("The Refiner's JSON had no 'cards' list.")
    return corrected
