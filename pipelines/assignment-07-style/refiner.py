# refiner.py
#
# THE REFINER, part 3 of 4 in the Generate-Evaluate-Refine loop.
#
# Takes the card that failed and the Evaluator's written reason, and rewrites the
# card so it scores a 10. It works from the reason, not from a fresh look at the
# item, which is what makes the loop a loop: the Evaluator's words are the only
# instruction the Refiner gets.
#
# Nobody steps in between. That is the assignment's rule and it is also the point.
#
# Game: Sponsor Me, Slayers!  (UEFN / Verse)

import settings
import styleguide


def build_prompt(text, item, evaluation):
    return """{guide}

You are the Refiner. A card was written for this game and the Evaluator scored it
{score} out of 10.

THE ITEM THIS CARD IS FOR:
{brief}

THE CARD AS IT STANDS:
---
{text}
---

WHAT THE EVALUATOR SAID:
{reason}

Rewrite the card so it scores a perfect 10 out of 10 against the style guide
above. Fix every fault the Evaluator named. Keep whatever was already working.

Aim for about {target} characters on the PLUG line and about {target} on the
EFFECT line. The hard ceiling is {ceiling} and it is counted exactly, character
by character, including every space and full stop, so leave yourself room.

Reply with the four lines only, in the order ITEM, SLOT, PLUG, EFFECT. No
preamble, no explanation, no notes about what you changed.""".format(
        guide=styleguide.style_guide_text(),
        brief=styleguide.item_brief(item),
        text=text,
        reason=evaluation["reason"],
        score=evaluation["score"],
        target=settings.REFINER_TARGET_CHARS,
        ceiling=settings.MAX_LINE_CHARS,
    )


def refine(text, item, evaluation):
    """Rewrite one failing card from the Evaluator's reason. Returns new text."""
    from generator import ask_claude, strip_fences

    return strip_fences(ask_claude(build_prompt(text, item, evaluation)))
