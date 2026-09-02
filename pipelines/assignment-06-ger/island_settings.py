# island_settings.py
#
# READS THE PLAYER'S MOVEMENT RULES OUT OF THE MAP INSTEAD OF ASSUMING THEM.
#
# WHY THIS EXISTS. Instructor feedback on Assignment 6: "Player run speed is an
# assumption (6.0 default, re-tested at 5.0), not a value pulled from the player
# controller. Reading it from the game at build time would prevent the evaluator
# from passing cards that fail in the live build."
#
# The suggested route does not exist. UEFN's Verse has no getter for a
# contestant's movement speed; GetTargetSpeed is on prop_mover_device, not on
# fort_character. Checked against the on-disk digest, not assumed.
#
# BUT THE NUMBERS ARE IN THE MAP. Island Settings is a placed actor, and a
# placed actor is a file on disk with its options written into it as plain
# name-and-value pairs. Two of the three terms behind the player's top speed are
# in there and can be read at build time with no editor, no playtest and no
# guessing:
#
#     bAllowSprinting              is the player allowed to sprint at all
#     MaxSprintingSpeedMultiplier  what sprinting multiplies their speed by
#
# The third term, the base run speed itself, is behind a named Fortnite preset
# (MovementSpeedTunings, currently "Ch 5 Movement") and is not written as a
# number anywhere in the project. So this module does not pretend to have
# measured it. It reads what is really there, computes the ceiling from it, and
# says out loud which part is still an assumption.
#
# WHAT THIS ACTUALLY BUYS. The danger was never the base number. It was drift:
# someone turns sprinting on, or nudges the multiplier, the player gets faster or
# slower, and the Evaluator carries on approving hostile ladders against a
# ceiling that no longer matches the game. That cannot happen silently now.

import os
import re
import struct

HERE = os.path.dirname(os.path.abspath(__file__))
PROJECT = os.path.abspath(os.path.join(HERE, "..", ".."))

# The Island Settings actor. One file per placed object is how UEFN stores a
# map, and this is the one holding the player rules.
ISLAND_SETTINGS = os.path.join(
    PROJECT, "Content", "__ExternalActors__", "SponsorMeSlayers_v2",
    "C", "R3", "W1IFAY9ONE4UTS5YWOQ6M4.uasset")

# The base run speed the Fortnite movement preset gives, in metres per second.
# STILL AN ASSUMPTION, and deliberately the only one left. It is named here on
# its own so it is impossible to miss, rather than buried inside a total.
ASSUMED_BASE_RUN_SPEED = 5.0

# A setting in a placed actor is written as its name, then two short tag fields,
# then the size of the value, then the value. Numbers are four bytes; text is a
# length followed by the characters.
SETTING = re.compile(
    rb"([A-Za-z_][A-Za-z0-9_]{2,60})\x00.\x00{7}.\x00{7}\x00{4}(....)\x00",
    re.S)


class SettingsUnreadable(Exception):
    """Raised when the map file cannot be read or does not hold what it should.

    Raised rather than defaulted on purpose. A pipeline that quietly falls back
    to a guess when it cannot find the real number is the exact failure the
    instructor's note is about.
    """


def read_settings(path=None):
    """Every option written on the Island Settings actor, as name to value."""
    target = path or ISLAND_SETTINGS
    if not os.path.exists(target):
        raise SettingsUnreadable(
            "Island Settings actor not found at {}. If the map has been "
            "resaved, the actor's filename changes; find it by searching "
            "Content/__ExternalActors__ for IslandSettings.".format(target))

    with open(target, "rb") as handle:
        data = handle.read()

    found = {}
    for match in SETTING.finditer(data):
        name = match.group(1).decode("ascii", "replace")
        size = struct.unpack("<i", match.group(2))[0]
        at = match.end()
        if size == 4:
            found[name] = struct.unpack_from("<f", data, at)[0]
            found[name + "__int"] = struct.unpack_from("<i", data, at)[0]
        else:
            length = struct.unpack_from("<i", data, at)[0] if size >= 4 else 0
            if 0 < length < 200:
                found[name] = data[at + 4:at + 4 + length - 1].decode(
                    "ascii", "replace")
    return found


def player_top_speed(path=None):
    """The fastest the contestant can travel, and how much of it is measured.

    Returns a dict rather than a bare number so the caller can print what was
    read and what is still assumed, which is the whole point of the exercise.
    """
    settings = read_settings(path)

    sprinting = settings.get("bAllowSprinting")
    multiplier = settings.get("MaxSprintingSpeedMultiplier")
    preset = settings.get("MovementSpeedTunings")

    if sprinting is None or multiplier is None:
        raise SettingsUnreadable(
            "bAllowSprinting or MaxSprintingSpeedMultiplier is missing from the "
            "Island Settings actor. Do not fall back to a guess; find out why.")

    can_sprint = str(sprinting).strip().lower() == "true"
    top = ASSUMED_BASE_RUN_SPEED * (float(multiplier) if can_sprint else 1.0)

    return {
        "top_speed": round(top, 3),
        "base_run_speed": ASSUMED_BASE_RUN_SPEED,
        "base_is_assumed": True,
        "movement_preset": preset,
        "sprinting_allowed": can_sprint,
        "sprint_multiplier": round(float(multiplier), 3),
        "read_from": os.path.relpath(path or ISLAND_SETTINGS, PROJECT),
    }


def describe(path=None):
    """One block a human can read before trusting a ladder."""
    facts = player_top_speed(path)
    lines = [
        "Player movement, read from the map at build time",
        "  file                 {}".format(facts["read_from"]),
        "  movement preset      {}".format(facts["movement_preset"]),
        "  sprinting allowed    {}".format(facts["sprinting_allowed"]),
        "  sprint multiplier    {}".format(facts["sprint_multiplier"]),
        "  base run speed       {} m/s   <-- STILL ASSUMED, the preset does not"
        " write a number".format(facts["base_run_speed"]),
        "  ceiling for hostiles {} m/s".format(facts["top_speed"]),
    ]
    if not facts["sprinting_allowed"]:
        lines.append(
            "  Sprinting is off in this island, so the multiplier does not "
            "apply and the ceiling is the plain run speed.")
    return "\n".join(lines)


if __name__ == "__main__":
    print(describe())
