"""recording_sheet.py -- the sheet Kai reads from when recording the host.

Writes recording-sheet.md: every line to be recorded, in order, with the exact
filename each clip must be saved as and which UEFN device it belongs to.

WHY IT IS GENERATED RATHER THAN TYPED. The lines live in barks.py and nothing
else may hold a second copy of them. A sheet typed by hand would drift the first
time a line changed, and the drift would only show up as a clip that says
something the game does not.

The delivery tags are comments in barks.py rather than data, because they are
directions for the person performing the line and not something the game reads.
They are pulled back out here, because the person performing the line is exactly
who this file is for.

Usage:
    python recording_sheet.py
"""

import io
import os
import re

from settings import TRIGGERS, MOMENT_BARKS, BARK_BUDGET
from barks import BARKS

HERE = os.path.dirname(os.path.abspath(__file__))

# The moment -> device field on announcer_manager, so a clip can never be put
# in the wrong place.
DEVICE = {
    "ShowIntro": "ShowIntroVoice",
    "RoundStart": "RoundStartVoice",
    "KillStreak": "KillStreakVoice",
    "CashPickup": "CashPickupVoice",
    "CrateDrop": "CrateDropVoice",
    "LowHealth": "LowHealthVoice",
    "RoundClear": "RoundClearVoice",
    "SignOff": "SignOffVoice",
    "DeadAir": "DeadAirVoice",
    "SponsorRead": "SponsorReadVoice",
}

WHEN = {
    "ShowIntro": "the moment START SHOW hands the arena over",
    "RoundStart": "a new room beginning",
    "KillStreak": "three robots down close together",
    "CashPickup": "cash collected, roughly one pickup in eight",
    "CrateDrop": "a sponsor crate finishing its descent",
    "LowHealth": "health falling below 40 per cent",
    "RoundClear": "the last robot of a room going down",
    "SignOff": "the run lost, over the game over card",
    "DeadAir": "eighteen seconds of nothing happening",
    "SponsorRead": "the same, taking turns with the dead air lines",
}


def tags_from_source():
    """The [AUD] / [YOU] / [TURN] direction for each line, by Kai's numbering."""
    source = io.open(os.path.join(HERE, "barks.py"), encoding="utf-8").read()
    found = {}
    for number, tag in re.findall(r"#\s*(\d+)\.\s*\[(AUD|YOU|TURN)\]", source):
        found[int(number)] = tag
    return found


def main():
    tags = tags_from_source()
    out = []
    out.append("# Announcer recording sheet")
    out.append("")
    out.append("**Sponsor Me, Slayers!** &mdash; every line the host says, and what to")
    out.append("save it as. Generated from `barks.py`; do not edit by hand.")
    out.append("")
    out.append(f"**{BARK_BUDGET} clips** in total: {MOMENT_BARKS} the host reacting to a")
    out.append(f"moment, and {BARK_BUDGET - MOMENT_BARKS} sponsor reads used as filler.")
    out.append("")
    out.append("## The voice")
    out.append("")
    out.append("A hyped-up broadcast announcer who is openly making fun of the")
    out.append("contestant. A radio DJ with big lungs and no sympathy. Cheerful on the")
    out.append("surface, sarcastic underneath. He is never on the player's side.")
    out.append("")
    out.append("**Repeated letters mean hold that sound.** Only 9 of the 41 stretch a")
    out.append("vowel, and never in DEAD AIR, where the joke is boredom.")
    out.append("")
    out.append("**The tag on each line says who he is talking to:**")
    out.append("")
    out.append("- `[AUD]` to the home audience, about the player")
    out.append("- `[YOU]` straight at the player")
    out.append("- `[TURN]` starts on the audience, then turns and hits the player mid-line")
    out.append("")
    out.append("## What to do with the clips")
    out.append("")
    out.append("1. Record each line and save it under the **filename** given below.")
    out.append("2. Import all of them into UEFN.")
    out.append("3. Make one **MSS Play Random Oneshot** preset per section, holding that")
    out.append("   section's clips.")
    out.append("4. Place ten Audio Player devices, point each at one preset, and wire it")
    out.append("   to the **device field** named in that section's heading.")
    out.append("")
    out.append("A section left unwired simply stays quiet. A half-recorded host is safe")
    out.append("to ship.")
    out.append("")

    number = 0
    for key, count, _fires in TRIGGERS:
        lines = BARKS.get(key, [])
        out.append("---")
        out.append("")
        out.append(f"## {key} &mdash; {len(lines)} clip(s)")
        out.append("")
        out.append(f"**Device field:** `{DEVICE.get(key, '?')}`  ")
        out.append(f"**Plays when:** {WHEN.get(key, '?')}")
        out.append("")
        for spot, line in enumerate(lines, start=1):
            number += 1
            tag = tags.get(number, "?")
            # UNDERSCORE, NOT A HYPHEN. UEFN refuses to import an asset whose
            # name contains "-", with "Asset has an invalid name". Found the
            # hard way on 2026-08-30, after 60 clips had been generated and
            # imported under the old hyphenated names.
            name = "{}_{:02d}.wav".format(key.lower(), spot)
            out.append(f"**{number}. `{name}`** &nbsp; `[{tag}]`")
            out.append("")
            out.append(f"> {line}")
            out.append("")

    path = os.path.join(HERE, "recording-sheet.md")
    io.open(path, "w", encoding="utf-8", newline="\n").write("\n".join(out) + "\n")
    print("Wrote {} ({} clips).".format(path, number))


if __name__ == "__main__":
    main()
