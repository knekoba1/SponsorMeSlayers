# Pre-Build Declaration, Assignment 6

**Game:** *Sponsor Me, Slayers!* — a top-down twin-stick arcade shooter in UEFN/Verse.

**1. What content does my game generate manually, inconsistently, or not at all?**

Hostile stat cards. Each card sets an enemy's health, movement speed and spawn density
for a block of Escalation Tiers. My five Cyber-Swarmer cards were made by hand, one at a
time. The second hostile promised in GDD 5.4 was never built at all, and I am adding three
types (Ranged Tank, Ranged Sentinel, Cyber-Boar). That is fifteen more cards.

**2. What specific GDD rule must every card satisfy?**

GDD 5.5: difficulty rises by exactly 8% per tier, hard-capped at Escalation Tier 21.
GDD 5.3: never more than 40 hostiles alive at once. Plus my recorded clarification of 5.5:
movement speed must stay below the player's run speed.

**3. What does failure look like, concretely?**

A card that outruns the player. Kiting becomes impossible (GDD 2.2), and the Career
Sponsor Rank ladder flattens (GDD 2.6) because every run then ends at the same tier
regardless of skill.
