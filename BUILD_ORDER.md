# Build Order — Sponsor Me, Slayers!

Everything left to build, in the order to build it. Written 2026-08-16 after a full
read of `Kailee_Nekoba_GDD_Final_Draft.pdf` against the code actually in `Content/`.

Tick items off as they land. Two items are **BLOCKED** on decisions recorded as open
questions in `GDD_AMENDMENTS.md`.

---

## Already working

- [x] Twin-stick movement and mouse aiming (GDD 2.2) — *uncuttable*
- [x] Standard Pulse Blaster granted on spawn (GDD 3.3)
- [x] Cash and retro prize drops, with the 'ding-ding-ding' stinger and score (GDD 2.3)
- [x] Wave spawning, tier escalation, the 40-bot cap, per-tier hostile swaps (GDD 5.5, 5.3) — *uncuttable*
- [x] The Death Save window and the Sponsor Aid turkey leg (GDD 3.4)
- [x] Hype Meter bar widget, filling from kills (GDD 3.1) — *partial, see Priority 3*

---

## Priority 1 — Uncuttable and incomplete

GDD 5.7 names four features that ship no matter what. Two are done. These two are not.

- [ ] **1. Career Sponsor Rank** (GDD 2.6). Local save, compare final score and highest
      tier against records, the five-title ladder, the holographic host title card on the
      main menu, the custom commentator bark at match start.
      **BLOCKED — see open question 12.**
- [ ] **2. The win state's buzzer and arena reset** (GDD 2.5). Tiers advance already, but
      `WaveManager.verse:10` states outright that it "does not sound the game-show
      buzzer." The environmental reset is not built either. Small job.

---

## Priority 2 — The hole in the core loop

The core loop in GDD 2.1 is six steps. Steps 3 and 4 do not exist, so the loop runs at
four of six. This is the biggest gap in the game.

- [ ] **3. Simulated Audience: crate spawn parameters** (GDD Section 4). Per the Section 4
      handoff table it "handles random-coordinate crate spawn parameters," meaning it
      decides the **quality tier and the 3D coordinates**, then hands off to Gameplay
      Systems via `SpawnCrateEvent`. CLAUDE.md section 12 requires it stay swappable: it
      must be replaceable, stubbable, or drivable from fixed test data without touching a
      line of crate-spawning code. **Build this before the crates.**
- [ ] **4. The paraglider crate system** (GDD 3.2). Crates parachute from the stadium
      ceiling with high-contrast coloured paragliders, trigger instantly on player
      collision, and fill four slots: Weapon, Consumable, Shield, Ammo Modifier. Duplicate
      pickups refresh the active duration rather than stacking. That refresh rule is an
      anti-exploit rule, not an optimisation. Do not "fix" it into stacking.
- [ ] **5. The three crate weapons** (GDD 3.3). Submachine Gun with bleed, Shotgun with
      chain knockback, Sponsor Sniper with piercing beam. **Damage values BLOCKED — see
      open question 15.**
- [ ] **6. Sponsor Aegis shield** (GDD 3.3). Absorbs up to 3 hostile hits.
- [ ] **7. Sponsor Aid as a crate consumable** (GDD 3.3). Mostly exists from the Death
      Save work. **Heal amount BLOCKED — see open question 14.**

---

## Priority 3 — Finish the Hype Meter

Six of the eight pieces in GDD 3.1 are missing. `HypeMeterManager.verse` says so in its
own header.

- [ ] **8. The Underdog / Rising Star / Superstar bands.** **BLOCKED — see open question 13.**
- [ ] **9. Hype from prize pickups, rapid multi-kills, and close-shave dodges** (GDD 3.1).
      Kills currently grant a flat amount; multi-kill detection is not built.
- [ ] **10. The Underdog Boost.** +50% Hype generation below 40% health.
- [ ] **11. Decay.** 5% every 10 seconds of inactivity.
- [ ] **12. The manual Hype Call.** Hold the key 1 second, 10-second cooldown.
- [ ] **13. The Hype Call rescue teleport** in the Death Save (GDD 3.4). 35% at Underdog,
      50% at Rising Star, 65% at Superstar. Needs item 8 first.

---

## Priority 4 — The arena and the world

**This runs alongside the code and needs its own booked sessions.** It is UEFN placement
work rather than Verse, so it does not block anything above, but it must be substantially
done before the final playtest and cleanup week (GDD 5.6, Week 6, 2026-08-26 to 09-01).

- [ ] **14. Two static obstacle types** (GDD 1.1, 5.4): electrical power grids and broken
      concrete debris. **These are gameplay, not decoration.** GDD 1.1: they "block player
      movement and enemy pathfinding, forcing frantic tactical maneuvering." The MVP list
      commits to exactly two types.
- [ ] **15. Stadium dressing** (GDD 1.1): hazard-striped security fences, towering blinking
      floodlights, flashing high-contrast neon signs.
- [ ] **16. Enemy death VFX** (GDD 1.1): hostiles "dissolve into electrical sparks."

---

## Priority 5 — MVP asset commitments (GDD 5.4)

- [ ] **17. The second hostile model in UEFN.** Stat cards were generated on 2026-08-16 by
      the Assignment 6 pipeline and live in `pipelines/assignment-06-ger/output/`. The
      character definitions and the extra spawners are not built.
      **The Cyber-Boar ladder is not safe to build until the player's run speed is
      measured** — see amendment 8 and the pipeline's README.
- [ ] **18. Audio** (GDD 5.4): one retro synth-wave music track, two game-show buzzer
      sound effects.
- [ ] **19. The 25 announcer barks** (GDD 5.2, 5.4). **Kai writes every line.** Claude
      structures the database, maps barks to triggers, and handles loading and playback,
      and never drafts, rewrites or "improves" the text. All 25 load into memory at
      runtime; never stream them.

---

## Priority 6 — On the cut list, so build last

GDD 5.7 gives the cut order. Build them in reverse, so the first thing to be cut is the
last thing to be built.

- [ ] **20. Tiered paraglider crate scaling** (cut 4)
- [ ] **21. Flaming Ammo modifier** (cut 3)
- [ ] **22. Icy Rounds modifier** (cut 2)
- [ ] **23. The simulated stream chat HUD** (cut 1) — the other half of the Simulated
      Audience, per the Section 4 handoff table

---

## Not on any list

- [ ] **24. The first-life onboarding ramp** (GDD 2.4). Not built, and not on the cut
      list, so technically required. It is also the obvious candidate for a fifth cut, and
      it carries open question 16f: a Room-Loop 1 death has only one of the two Death Save
      escapes available, because Hype is switched off.

---

## THE SHIP GATE

**Kai's rule, 2026-08-16: no open question may still be open when the game ships.**

- [ ] Every item in the OPEN QUESTIONS section of `GDD_AMENDMENTS.md` reads **RESOLVED**,
      with the ruling and its date recorded.

The four blocking questions (12, 13, 14, 15) close naturally as their features get built.
The eight documentation-only ones (16a to 16h) need one dedicated editing pass over the
GDD, and nothing else in this list depends on them, so they can be cleared any time. Do
not leave them to the last day.
