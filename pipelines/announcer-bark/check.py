# check.py
#
# THE CHECKER. It reads settings.py and barks.py and reports, without opinions:
# which slots are still empty, whether the 25-bark budget in GDD 5.3 is broken,
# whether any line repeats, and whether any line is too long to be a bark.
#
# It never scores a line's writing and never suggests wording. Length and
# duplication are countable facts; tone is Kailee's.

from settings import TRIGGERS, BARK_BUDGET, MAX_BARK_WORDS


def read_barks():
    from barks import BARKS
    return BARKS


def check(barks):
    problems = []
    empty = []
    filled = 0
    seen = {}

    expected = {key: count for key, count, _ in TRIGGERS}
    budget = sum(expected.values())

    if budget > BARK_BUDGET:
        problems.append(
            f"The trigger split in settings.py asks for {budget} barks, "
            f"and GDD 5.3 allows {BARK_BUDGET}."
        )

    for key, count, _ in TRIGGERS:
        if key not in barks:
            problems.append(f"{key} has no entry in barks.py at all.")
            continue
        lines = barks[key]
        if len(lines) != count:
            problems.append(
                f"{key} has {len(lines)} slots in barks.py and "
                f"{count} in settings.py."
            )
        for index, line in enumerate(lines):
            text = line.strip()
            if not text:
                empty.append(f"{key}[{index}]")
                continue
            filled += 1
            words = len(text.split())
            if words > MAX_BARK_WORDS:
                problems.append(
                    f"{key}[{index}] is {words} words, over the "
                    f"{MAX_BARK_WORDS} a bark may be."
                )
            lowered = text.lower()
            if lowered in seen:
                problems.append(
                    f"{key}[{index}] repeats {seen[lowered]} word for word."
                )
            else:
                seen[lowered] = f"{key}[{index}]"

    for key in barks:
        if key not in expected:
            problems.append(
                f"{key} is in barks.py but not in settings.py, so nothing "
                f"will ever fire it."
            )

    return problems, empty, filled, budget


def report(barks):
    problems, empty, filled, budget = check(barks)

    print(f"Barks written: {filled} of {budget}. Budget is {BARK_BUDGET}.")

    if empty:
        print(f"\nStill to write ({len(empty)}):")
        for slot in empty:
            print(f"  {slot}")

    if problems:
        print(f"\nProblems ({len(problems)}):")
        for problem in problems:
            print(f"  {problem}")
    else:
        print("\nNo problems.")

    return problems, empty, filled
