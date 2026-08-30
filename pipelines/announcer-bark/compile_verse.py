# compile_verse.py
#
# THE COMPILER. It turns settings.py's triggers and barks.py's lines into a
# Verse device the game can read.
#
# It writes an empty array for a trigger with nothing written yet, so the file
# always compiles and the game always runs. A trigger with no lines simply says
# nothing, which is the right behaviour for a half-written bark database.

from settings import TRIGGERS, VERSE_OUTPUT, VERSE_CLASS


def escape(text):
    # Verse strings take double quotes, and braces are interpolation.
    return (
        text.replace("\\", "\\\\")
            .replace('"', '\\"')
            .replace("{", "{{")
            .replace("}", "}}")
    )


def build(barks):
    out = []
    out.append("# BarkDatabase.verse")
    out.append("#")
    out.append('# GDD Section 4 "Announcer Bark" -- the commentator dialogue database and')
    out.append("# its trigger mapping. Amendment 90 sets the count at 41, all held in memory,")
    out.append("# because streaming them stuttered and ruined the comedic timing.")
    out.append("#")
    out.append("# WRITTEN BY pipelines/announcer-bark/compile_verse.py. DO NOT EDIT BY HAND:")
    out.append("# the next run overwrites it. The lines themselves are Kailee's and live in")
    out.append("# pipelines/announcer-bark/barks.py. No agent in this project may write,")
    out.append("# rewrite or improve them, per CLAUDE.md standing rule 3.")
    out.append("")
    out.append("using { /Fortnite.com/Devices }")
    out.append("using { /Verse.org/Random }")
    out.append("using { /Verse.org/Simulation }")
    out.append("")
    out.append(f"{VERSE_CLASS} := class(creative_device):")
    out.append("")
    out.append("    # One entry per trigger. An empty list means that moment has no line")
    out.append("    # written yet and the commentator stays quiet, which is deliberate.")
    out.append("    Lines : [string][]string = map{")

    # NO TRAILING COMMA ANYWHERE, and Verse is strict about it in a way most
    # languages are not: a comma before a closing brace is script error 3100,
    # "Expected expression or } , got }". It caught the first compile of this
    # file on 2026-08-28. So every separator is written BEFORE the next item
    # rather than after the last one.
    entries = [(key, [l.strip() for l in barks.get(key, []) if l.strip()], fires)
               for key, count, fires in TRIGGERS]

    for index, (key, written, fires) in enumerate(entries):
        tail = "," if index < len(entries) - 1 else ""
        out.append(f"        # {fires}")
        if not written:
            out.append(f'        "{key}" => array{{}}{tail}')
        else:
            out.append(f'        "{key}" => array{{')
            for spot, line in enumerate(written):
                comma = "," if spot < len(written) - 1 else ""
                out.append(f'            "{escape(line)}"{comma}')
            out.append(f"        }}{tail}")
    out.append("    }")
    out.append("")
    out.append("    # A line for this moment, or the empty string if none is written yet.")
    out.append("    # Random so a trigger with two or three lines does not repeat itself.")
    out.append("    GetBark<public>(Trigger : string):string =")
    out.append("        if (Found := Lines[Trigger], Found.Length > 0):")
    out.append("            if (Pick := Found[GetRandomInt(0, Found.Length - 1)]):")
    out.append("                Pick")
    out.append("            else:")
    out.append('                ""')
    out.append("        else:")
    out.append('            ""')
    out.append("")
    out.append("    # How many lines a trigger has, for the startup log.")
    out.append("    CountFor<public>(Trigger : string)<transacts>:int =")
    out.append("        if (Found := Lines[Trigger]):")
    out.append("            Found.Length")
    out.append("        else:")
    out.append("            0")
    out.append("")
    out.append("    OnBegin<override>()<suspends>:void =")
    out.append("        var Written : int = 0")
    out.append("        var Mapped : int = 0")
    out.append("        for (Trigger -> Found : Lines):")
    out.append("            set Written += Found.Length")
    out.append("            set Mapped += 1")
    out.append('        Print("DEBUG: Bark database up -- {Written} bark(s) across {Mapped} trigger(s).")')
    out.append("")

    return "\n".join(out)


def write(barks):
    import io, os
    text = build(barks)
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), VERSE_OUTPUT)
    io.open(path, "w", encoding="utf-8", newline="\n").write(text)
    return os.path.normpath(path), text.count("\n") + 1
