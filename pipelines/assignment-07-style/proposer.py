# proposer.py
#
# THE PROPOSER, THE ADVERSARIAL CRITIC and THE JUDGE.
#
# This is the "Generate 10, Keep 3" pattern from Class 9, which the assignment's
# own notes call a cornerstone: never accept the first thing the model writes.
#
#   Proposer          writes PROPOSAL_COUNT genuinely different cards at once.
#   Adversarial Critic red-teams every one of them, hunting for the strongest
#                      objection it can find. It is told to be unfair.
#   Judge             scores each proposal out of 10 having read the critic, and
#                      prunes everything under JUDGE_THRESHOLD.
#
# The survivor then goes into the ordinary Evaluate-Refine loop in run.py, so the
# winner still has to earn its 9 out of 10 like anything else.
#
# Why the three roles are separate calls: Class 8's generator-evaluator contract.
# An agent that just wrote something "has all the generation process still in its
# memory" and will wave its own work through. Each role here is a fresh session
# that sees only what it is handed.
#
# The demonstrations in run.py deliberately do NOT use this. Their job is to start
# off-brand and be caught, and a judge picking the best of eight would hide the
# very failure the assignment asks to see.
#
# Game: Sponsor Me, Slayers!  (UEFN / Verse)

import json
import re

import settings
import styleguide
from generator import ClaudeError, ask_claude


def extract_json(text):
    """Pull a JSON object out of a reply, fenced or not."""
    fenced = re.search(r"```(?:json)?\s*(.*?)```", text, re.DOTALL)
    if fenced:
        text = fenced.group(1)

    start = text.find("{")
    end = text.rfind("}")
    if start == -1 or end == -1 or end < start:
        raise ClaudeError(
            "The reply contained no JSON object.\nReply began: %s" % text[:200]
        )
    try:
        return json.loads(text[start:end + 1])
    except json.JSONDecodeError as problem:
        raise ClaudeError("The JSON could not be read: %s" % problem)


def card_text(fields):
    """Turn one proposal's fields back into a four-line card."""
    return "ITEM: %s\nSLOT: %s\nPLUG: %s\nEFFECT: %s" % (
        fields.get("item", ""),
        fields.get("slot", ""),
        fields.get("plug", ""),
        fields.get("effect", ""),
    )


def propose(item):
    """Ask for several genuinely different cards for one item.

    The output contract is JSON, so the pipeline never has to guess where one
    proposal ends and the next begins.
    """
    prompt = """{guide}

You are the Proposer. Write {count} DIFFERENT crate pickup cards for the item
below. Not {count} rewordings of one joke: {count} different angles on the
Network's cruelty. Vary what is being billed, what is being praised, and who the
Network compares the contestant to.

{brief}

Reply with ONLY a JSON object in exactly this shape and nothing else:

{{
  "proposals": [
    {{"item": "...", "slot": "...", "plug": "...", "effect": "..."}}
  ]
}}

Give exactly {count} proposals.""".format(
        guide=styleguide.style_guide_text(),
        brief=styleguide.item_brief(item),
        count=settings.PROPOSAL_COUNT,
    )

    data = extract_json(ask_claude(prompt))
    proposals = data.get("proposals")
    if not isinstance(proposals, list) or not proposals:
        raise ClaudeError("The Proposer's JSON had no 'proposals' list.")
    return [card_text(p) for p in proposals]


def numbered_cards(cards):
    blocks = []
    for index, text in enumerate(cards, 1):
        blocks.append("PROPOSAL %d:\n%s" % (index, text))
    return "\n\n".join(blocks)


def critique(item, cards):
    """Red-team every proposal. Returns the critic's write-up as plain text."""
    prompt = """{guide}

You are the Adversarial Critic, the red team. Your job is to attack, not to
help. For each proposal below, find the STRONGEST objection you can: a lore
violation, a wrong number, a tone mismatch, a joke that does not land, a line
that reads as a threat rather than a broadcast, or a line that would fit any
game rather than this one.

Assume each proposal is worse than it looks. Do not praise anything. If a
proposal is genuinely sound, say so in one short line and move on.

{brief}

{cards}

Reply with one short paragraph per proposal, numbered to match. No preamble.""".format(
        guide=styleguide.style_guide_text(),
        brief=styleguide.item_brief(item),
        cards=numbered_cards(cards),
    )
    return ask_claude(prompt)


def judge(item, cards, critic_notes):
    """Score every proposal out of 10 and prune the weak ones.

    Returns (winner_text, table) where table is a list of
    {"index", "score", "note", "text", "kept"} for the record.
    """
    prompt = """{guide}

You are the Judge. Score each proposal below out of 10 against the style guide.
You have the Adversarial Critic's objections in hand: weigh them, but you are not
obliged to agree with an objection you think is wrong.

Prune ruthlessly. Anything under {threshold} is not good enough to reach a
player.

{brief}

{cards}

THE ADVERSARIAL CRITIC SAID:
{notes}

Reply with ONLY a JSON object in exactly this shape and nothing else:

{{
  "scores": [
    {{"proposal": 1, "score": 0.0, "note": "one sentence saying why"}}
  ],
  "winner": 1,
  "why_the_winner": "one or two sentences"
}}""".format(
        guide=styleguide.style_guide_text(),
        brief=styleguide.item_brief(item),
        cards=numbered_cards(cards),
        notes=critic_notes,
        threshold=settings.JUDGE_THRESHOLD,
    )

    data = extract_json(ask_claude(prompt))
    scores = data.get("scores")
    if not isinstance(scores, list) or not scores:
        raise ClaudeError("The Judge's JSON had no 'scores' list.")

    table = []
    for entry in scores:
        try:
            index = int(entry.get("proposal", 0))
            score = float(entry.get("score", 0))
        except (TypeError, ValueError):
            continue
        if not 1 <= index <= len(cards):
            continue
        table.append(
            {
                "index": index,
                "score": score,
                "note": entry.get("note", ""),
                "text": cards[index - 1],
                "kept": score >= settings.JUDGE_THRESHOLD,
            }
        )

    if not table:
        raise ClaudeError("The Judge scored nothing usable.")

    # Trust the Judge's own pick when it named one, otherwise take the top score.
    winner_index = data.get("winner")
    winner = None
    if isinstance(winner_index, int) and 1 <= winner_index <= len(cards):
        winner = cards[winner_index - 1]
    if winner is None:
        winner = max(table, key=lambda row: row["score"])["text"]

    return winner, table, data.get("why_the_winner", "")


def best_of(item, say):
    """Run Proposer, Critic and Judge for one item. Returns (winner, record)."""
    say("    Proposer: writing %d variations ..." % settings.PROPOSAL_COUNT)
    cards = propose(item)

    say("    Adversarial Critic: attacking all %d ..." % len(cards))
    notes = critique(item, cards)

    say("    Judge: scoring and pruning below %.1f ..." % settings.JUDGE_THRESHOLD)
    winner, table, why = judge(item, cards, notes)

    kept = [row for row in table if row["kept"]]
    say("    Judge kept %d of %d. Best was %.1f."
        % (len(kept), len(table), max(row["score"] for row in table)))

    record = {
        "proposals": cards,
        "critic_notes": notes,
        "scores": table,
        "winner": winner,
        "why_the_winner": why,
    }
    return winner, record
