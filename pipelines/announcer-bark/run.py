# run.py
#
# THE ANNOUNCER BARK AGENT, end to end.
#
# GDD Section 4 gives this agent two jobs and only two: structure the dialogue
# database, and map it to triggers. It checks Kailee's file, reports what is
# still open, and compiles what is written into Verse.
#
# THERE IS NO LANGUAGE MODEL IN THIS PIPELINE. That is the point. CLAUDE.md
# standing rule 3 says the commentator's lines are hand-written by the designer,
# so the agent is built without the ability to write one.
#
#   python run.py            check and compile
#   python run.py --check    check only, write nothing

import sys

import check
import compile_verse


def main():
    barks = check.read_barks()
    problems, empty, filled = check.report(barks)

    if "--check" in sys.argv:
        return 1 if problems else 0

    if problems:
        print("\nNothing compiled. Fix the problems above and run again.")
        return 1

    if filled == 0:
        print(
            "\nNothing compiled, because no line is written yet. The Verse file is"
            " deliberately not created until there is something in it, since an"
            " untested generated file sitting in Content/ can only break the"
            " UEFN build."
        )
        return 0

    path, lines = compile_verse.write(barks)
    print(f"\nCompiled {filled} bark(s) into {path} ({lines} lines).")
    if empty:
        print(f"{len(empty)} slot(s) are still empty and stay silent in game.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
