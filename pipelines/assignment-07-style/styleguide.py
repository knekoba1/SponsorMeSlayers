# styleguide.py
#
# Turns the rules in settings.py into the block of text that gets pasted into the
# Evaluator's and the Refiner's prompts.
#
# It lives in its own file so the Evaluator and the Refiner are provably judging
# and fixing against the SAME rules. If they each carried their own copy they
# would drift, and the loop would argue with itself forever.
#
# Game: Sponsor Me, Slayers!  (UEFN / Verse)

import settings


def numbered(rules):
    return "\n".join("  %d. %s" % (i, r) for i, r in enumerate(rules, 1))


def style_guide_text():
    """The whole style guide, as the agents see it."""
    shorthand = ", ".join(
        '"%s" is accepted shorthand for "%s"' % (short, full)
        for short, full in settings.ACCEPTED_SHORTHAND.items()
    )

    return """THE STYLE GUIDE FOR "SPONSOR ME, SLAYERS!"

The game is a top-down twin-stick arcade shooter set inside a dystopian televised
gladiatorial game show. Contestants volunteer for the broadcast to escape crushing
financial debt. The Network notoriously never pays survivors, because no contestant
has ever completed a run alive. The hostiles are rejected pilot-episode robots and
bankrupt former contestants who took mechanical chassis modifications as a
severance package. The tone is broad, self-aware game-show comedy in the tradition
of Smash TV and Total Carnage, with corporate hostility played for laughs.

You are writing a CRATE PICKUP CARD: the four-line readout that flashes on screen
the instant the contestant runs into a paraglider supply crate.

CONSTRAINT TYPE 1: GAME VOCABULARY AND LORE ACCURACY
{vocab_rules}

  Approved in-world terms:
{canon}

  Accepted shorthand: {shorthand}

  Banned generic words. Using any of these is an automatic violation, because a
  stranger reading the card must be able to tell it belongs to THIS game:
{banned}

CONSTRAINT TYPE 2: TONE AND VOICE
{tone}

CONSTRAINT TYPE 3: FORMAT AND LENGTH
{fmt}

THE SHAPE OF A CARD, exactly:

ITEM: <exact canon item name>
SLOT: <one of {slots}>
PLUG: <the Network's sales pitch, one sentence, max {maxchars} characters>
EFFECT: <what it actually does, flat and factual, one sentence, max {maxchars} characters>
""".format(
        vocab_rules=numbered(
            [
                "Every item, hostile and system is called by its exact in-world "
                "name from the approved list below. No invented names, no "
                "renaming, no generic substitutes.",
                "The EFFECT line must agree with the item's real behaviour. A "
                "wrong number, duration or hit count is a violation of this "
                "rule, not a matter of taste.",
                "The contestant is called the contestant. The organisation "
                "running the show is called the Network.",
            ]
        ),
        canon="\n".join("    - " + t for t in settings.CANON_TERMS),
        shorthand=shorthand,
        banned="\n".join("    - " + t for t in settings.BANNED_TERMS),
        tone=numbered(settings.TONE_RULES),
        fmt=numbered(settings.FORMAT_RULES),
        slots=" / ".join(settings.VALID_SLOTS),
        maxchars=settings.MAX_LINE_CHARS,
    )


def find_item(name):
    """Look up one item's slot, tier and true behaviour by name."""
    for item in settings.ITEMS:
        if item["name"] == name:
            return item
    raise KeyError("No item named %r in settings.ITEMS" % name)


def item_brief(item):
    """The facts about one item, for a prompt."""
    return (
        "ITEM NAME: %s\n"
        "SLOT: %s\n"
        "CRATE TIER: %s\n"
        "TRUE BEHAVIOUR, which the EFFECT line must agree with:\n%s"
        % (item["name"], item["slot"], item["tier"], item["facts"])
    )
