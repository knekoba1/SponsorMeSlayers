"""harvest.py -- turn one UEFN playtest into an adversarial QA report.

Assignment 9. Kailee Nekoba.

WHY THIS EXISTS AT ALL. The adversarial agent lives inside the game, in
Content/AdversarialTester.verse, because that is the only place it can reach the
contestant, the robots and the arena. Verse cannot write a file. So the agent
prints one pipe-delimited line per finding into the UEFN session log, and this
script reads that log and writes the structured report the assignment asks for.

Pipes rather than JSON on the Verse side is deliberate: a quote character inside
a Verse string appears nowhere else in this project, and the report has to be
JSON, not the log line.

THE LINE FORMAT, and the agent's Report() is the other half of this contract:

    ADVQA|check|error_type|severity|location|system|context|seconds

Usage:
    python harvest.py                 read the newest UEFN log
    python harvest.py --log PATH      read a particular log
    python harvest.py --out DIR       write somewhere other than here
"""

import argparse
import csv
import json
import os
import re
from datetime import datetime, timezone

MARKER = "ADVQA|"

# UEFN keeps one log per editor session, not one per playtest, so a single log
# can hold several runs. The agent announces itself on arming, and that line is
# what splits them.
ARMED = "ADVQA: adversarial tester ARMED"
FIELDS = ["check", "error_type", "severity", "location", "system", "context", "seconds"]

# The log line carries its own timestamp in square brackets at the front.
STAMP = re.compile(r"^\[(\d{4}\.\d{2}\.\d{2}-\d{2}\.\d{2}\.\d{2}):(\d{3})\]")

DEFAULT_LOG_DIR = os.path.join(
    os.path.expanduser("~"),
    "AppData", "Local", "UnrealEditorFortnite", "Saved", "Logs",
)


def newest_log(folder):
    """The UEFN session log that was written to most recently.

    UEFN rotates its log on restart and leaves the old ones beside it with
    -backup- in the name, so the newest file is not always the one called
    UnrealEditorFortnite.log.
    """
    if not os.path.isdir(folder):
        raise SystemExit("No UEFN log folder at {}".format(folder))
    candidates = [
        os.path.join(folder, name)
        for name in os.listdir(folder)
        if name.startswith("UnrealEditorFortnite") and name.endswith(".log")
    ]
    if not candidates:
        raise SystemExit("No UnrealEditorFortnite log in {}".format(folder))
    return max(candidates, key=os.path.getmtime)


def parse(path):
    """Every ADVQA finding in one log, oldest first."""
    findings = []
    session = 0
    with open(path, "r", encoding="utf-8", errors="replace") as handle:
        for number, raw in enumerate(handle, start=1):
            if ARMED in raw:
                session += 1
                continue

            at = raw.find(MARKER)
            if at < 0:
                continue

            payload = raw[at + len(MARKER):].rstrip("\n").rstrip("\r")
            parts = payload.split("|")

            # The agent prints the field names once as its first line so the
            # log is readable on its own. That header is not a finding.
            if parts[:1] == ["check"]:
                continue
            if len(parts) != len(FIELDS):
                # A malformed line is reported rather than dropped silently. A
                # QA tool that hides its own faults is not one.
                findings.append({
                    "check": "HARVEST",
                    "error_type": "MALFORMED_LOG_LINE",
                    "severity": "low",
                    "location": "{}:{}".format(os.path.basename(path), number),
                    "system": "harvest.py",
                    "game_context": payload,
                    "seconds_into_run": None,
                    "session": session,
                    "timestamp": stamp_of(raw),
                    "log_line": number,
                })
                continue

            row = dict(zip(FIELDS, parts))
            findings.append({
                "check": row["check"],
                "error_type": row["error_type"],
                "severity": row["severity"],
                "location": row["location"],
                "system": row["system"],
                "game_context": row["context"],
                "seconds_into_run": as_float(row["seconds"]),
                "session": session,
                "timestamp": stamp_of(raw),
                "log_line": number,
            })
    return findings


def collapse(findings):
    """Fold a repeated finding into one row with a count.

    WHY. Some invariants are true for as long as a state lasts, not for an
    instant. INV-05 asks whether the contestant is outside the room, and while
    they are, it is true at every look. Left alone that is 201 rows for what a
    developer would call one escape, and a report padded with the same fact is
    harder to act on, not easier.

    Only CONSECUTIVE repeats of the same check in the same session are folded,
    and location is deliberately NOT part of the test: a contestant sliding
    about outside the room reports a slightly different position every look, so
    matching on location would fold nothing. Any other finding in between ends
    the episode, which is what keeps two real escapes as two rows. The row keeps
    the first position seen and the seconds it ran from and to.
    """
    out = []
    for f in findings:
        last = out[-1] if out else None
        same = (
            last is not None
            and last["check"] == f["check"]
            and last["error_type"] == f["error_type"]
            and last["session"] == f["session"]
        )
        if same:
            last["occurrences"] += 1
            last["last_seconds"] = f["seconds_into_run"]
            continue
        row = dict(f)
        row["occurrences"] = 1
        row["first_seconds"] = f["seconds_into_run"]
        row["last_seconds"] = f["seconds_into_run"]
        out.append(row)
    return out


def stamp_of(raw):
    found = STAMP.match(raw.lstrip())
    if not found:
        return None
    return "{}.{}".format(found.group(1), found.group(2))


def as_float(text):
    try:
        return round(float(text), 2)
    except (TypeError, ValueError):
        return None


def summarise(findings):
    """Counts a developer can act on before reading a single row."""
    by_type = {}
    by_check = {}
    by_severity = {}
    by_system = {}
    by_session = {}
    for f in findings:
        key = "session {}".format(f.get("session"))
        by_session[key] = by_session.get(key, 0) + 1
        by_type[f["error_type"]] = by_type.get(f["error_type"], 0) + 1
        by_check[f["check"]] = by_check.get(f["check"], 0) + 1
        by_severity[f["severity"]] = by_severity.get(f["severity"], 0) + 1
        by_system[f["system"]] = by_system.get(f["system"], 0) + 1
    return {
        "total_findings": len(findings),
        "by_error_type": dict(sorted(by_type.items(), key=lambda kv: -kv[1])),
        "by_check": dict(sorted(by_check.items())),
        "by_severity": dict(sorted(by_severity.items())),
        "by_system": dict(sorted(by_system.items(), key=lambda kv: -kv[1])),
        "by_session": dict(sorted(by_session.items())),
    }


def main():
    ap = argparse.ArgumentParser(description="Harvest an adversarial QA run from a UEFN log.")
    ap.add_argument("--log", help="path to a UEFN .log file")
    ap.add_argument("--logdir", default=DEFAULT_LOG_DIR, help="where UEFN keeps its logs")
    ap.add_argument("--out", default=os.path.dirname(os.path.abspath(__file__)))
    args = ap.parse_args()

    path = args.log or newest_log(args.logdir)
    raw_findings = parse(path)
    findings = collapse(raw_findings)

    report = {
        "game": "Sponsor Me, Slayers!",
        "author": "Kailee Nekoba",
        "assignment": "09 - Adversarial QA Agent",
        "agent": "Content/AdversarialTester.verse (adversarial_tester)",
        "harvested_at": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC"),
        "source_log": os.path.basename(path),
        "run_started": findings[0]["timestamp"] if findings else None,
        "run_ended": findings[-1]["timestamp"] if findings else None,
        "sessions_in_log": max([f.get("session", 0) for f in findings], default=0),
        "rows": len(findings),
        "raw_findings_before_collapsing_repeats": len(raw_findings),
        "summary": summarise(findings),
        "findings": findings,
    }

    os.makedirs(args.out, exist_ok=True)
    json_path = os.path.join(args.out, "report.json")
    csv_path = os.path.join(args.out, "report.csv")

    with open(json_path, "w", encoding="utf-8", newline="\n") as handle:
        json.dump(report, handle, indent=2)
        handle.write("\n")

    columns = ["check", "error_type", "severity", "location", "system",
               "game_context", "occurrences", "first_seconds", "last_seconds",
               "session", "timestamp", "log_line"]
    with open(csv_path, "w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=columns)
        writer.writeheader()
        for f in findings:
            writer.writerow({c: f.get(c) for c in columns})

    print("Read {}".format(path))
    print("Findings: {} rows, from {} raw lines".format(len(findings), len(raw_findings)))
    for kind, count in report["summary"]["by_error_type"].items():
        print("  {:<24} {}".format(kind, count))
    print("Wrote {}".format(json_path))
    print("Wrote {}".format(csv_path))

    if not findings:
        print("")
        print("No ADVQA lines in that log. Either the run has not happened yet,")
        print("or RunAdversarialTest is still unticked on the placed device.")


if __name__ == "__main__":
    main()
