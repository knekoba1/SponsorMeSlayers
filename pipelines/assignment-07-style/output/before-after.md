# Assignment 7, before and after

*Sponsor Me, Slayers!* crate pickup cards. Every line below was produced
by the loop with no human intervention. The Generator was not shown the
style guide on these three runs.

---

## Example 1: Tone and voice

**Item:** Sponsor Aid (Consumable slot, Rising Star crate)

**What the Generator was told to do:** Write it with genuine warmth and compassion, the way a hospital charity would describe emergency medical relief. Be sincere, comforting and hopeful. Reassure the reader that help is on the way and that someone truly cares about them.

### BEFORE

```
ITEM: Sponsor Aid
SLOT: Consumable
PLUG: Someone out there saw you falling, and they cared enough to send help.
EFFECT: Restores 25% of max health on contact, and it answers the 3-second Death Save.

One flag, since it affects whether this ships: the sincere, compassionate register runs against the show's satirical corporate voice, where the Network's "generosity" is the joke, so this reads as straight charity copy rather than in-world text.
```

### The rule that caught it

**Rule quoted** (TONE_RULES, rule 5):

> Never sincere, never heartfelt, never warm, never encouraging. Any line that would genuinely comfort the contestant is a failure (GDD 1).

**Where it landed:**

| | The line |
|---|---|
| Before | Someone out there saw you falling, and they cared enough to send help. |
| After | A hot meal for our bravest contestant, catering fees deducted from your payout. |

### Evaluator, attempt 1

**SCORE: 2/10**

**REASON:**

Three sets of rules are broken. Format 1 and the local checker: the card has 5 lines and the format requires exactly 4 (ITEM, SLOT, PLUG, EFFECT), so the trailing note about the sincere register is itself a violation. Delete that fifth line entirely; commentary about the card is not part of the card. Tone 1: the PLUG does neither of the two things it must do at once. "Someone out there saw you falling, and they cared enough to send help" is not insincere praise and carries no jab, so it fails the sarcastic-and-cruel-in-the-same-breath test twice over. Tone 5: it is sincere, heartfelt and warm, and it would genuinely comfort a contestant, which is named as an automatic failure. Tone 2: there is no financial jab, and this item above all should be billed, invoiced or surcharged, since the Network charging a debtor for the turkey leg that saves their life is the joke the guide asks for first. Tone 4: the register is not polished corporate broadcast at all; "someone out there" is anonymous greeting-card sentiment, and the Network never appears as the speaker. Lore 3 and the stranger test: neither "the Network" nor "contestant" appears anywhere in the PLUG, no approved in-world term is used, and the line could be dropped into any game with a healing item without a word changing, which is exactly what the vocabulary rules exist to prevent. The EFFECT line is the one thing that passes: it is flat, factual, within 90 characters, and agrees with the true behaviour on both the 25% restore and the Death Save answer, so leave it as written. Rewrite the PLUG as one sentence under 90 characters in which the Network praises the contestant insincerely while charging them for the rescue, for example fake generosity about the meal paired with the catering fee being deducted from a payout that will never arrive.

### Refiner rewrite 1

```
ITEM: Sponsor Aid
SLOT: Consumable
PLUG: A hot meal for our bravest contestant, catering fees deducted from your payout.
EFFECT: Restores 25% of max health on contact, and answers the 3-second Death Save.
```

### Evaluator, attempt 2

**SCORE: 9/10**

**REASON:**

No rules broken. The checker found no mechanical violations, and none of them pull the score down here. The PLUG does the hard double act required by Constraint Type 2 rule 1: "our bravest contestant" is insincere praise, and "catering fees deducted from your payout" is the financial jab, both inside one sentence, with the deeper joke being that the payout never arrives. That satisfies rule 2, the money jab as the first reach. The register holds to rule 4, pleasant catering-department manners sitting on top of billing a dying person for their own last meal, and it never tips into threat, gore or menace, so rule 6 is safe. Nothing in it would comfort the contestant, so rule 5 is safe. The EFFECT line goes properly flat and agrees with the true behaviour on both counts, the 25% instant heal and answering the 3-second Death Save, which is rule 9 and Constraint Type 1 rule 2. Canon vocabulary only, no banned generics, no slang, and "Sponsor Aid", "contestant" and "Death Save" together make it obvious which game this belongs to. Two small things keep it off a 10 rather than anything broken: "bravest" leans a half step toward the heroic register that Constraint Type 2 rule 7 warns against, and it only works because it reads as mock praise, so a colder corporate word like "most valued" or "most punctual" would be safer and funnier; and the jab is aimed at the contestant's wallet without ever landing on the contestant themselves, which makes it slightly gentler than the worked example, where the Network openly expects the shots to miss. If you want the extra point, swap "bravest" for a corporate compliment and imply the meal is being charged as a courtesy the contestant will not live long enough to finish.

### AFTER

```
ITEM: Sponsor Aid
SLOT: Consumable
PLUG: A hot meal for our bravest contestant, catering fees deducted from your payout.
EFFECT: Restores 25% of max health on contact, and answers the 3-second Death Save.
```

**Outcome:** refined. 2 evaluation(s), 1 refiner rewrite(s).

---

## Example 2: Game vocabulary and lore accuracy

**Item:** Sponsor Aegis (Shield slot, Superstar crate)

**What the Generator was told to do:** Use standard fantasy role-playing game language. Call it a magic barrier, talk about the hero, the monsters and their hit points, and say it absorbs damage for a short duration. Do not use any product names.

### BEFORE

```
ITEM: Sponsor Aegis
SLOT: Shield
PLUG: A shimmering hexagon of rose-bright magic, raised to ward the hero.
EFFECT: Blocks the next 3 monster strikes, with no time limit, then shatters.
```

### The rule that caught it

**Rule quoted** (BANNED_TERMS, enforced by the local checker):

> Banned generic words. Using any of these is an automatic violation, because a stranger reading the card must be able to tell it belongs to THIS game.

**Where it landed:**

| | The line |
|---|---|
| Before | A shimmering hexagon of rose-bright magic, raised to ward the hero. |
| After | We rate your survival so highly that all three hits are already on your invoice. |

### Evaluator, attempt 1

**SCORE: 2/10**

**REASON:**

Multiple rules broken, and the card reads as generic fantasy rather than this game. VOCABULARY (Constraint 1.1): the card uses the banned generic word 'magic' in the PLUG; replace it with the game's own framing, a Network-issued Sponsor Aegis field, not magic. VOCABULARY (Constraint 1.1): the card uses the banned generic word 'hero'; the person being addressed is the contestant, and Constraint 1.3 requires that exact word. VOCABULARY (Constraint 1.1): the card uses the banned generic word 'monster'; the things hitting the shield are hostiles, called by their canon names, Cyber-Swarmer, Cyber-Boar, Ranged Sentinel or Heavy Ranged Tank. TONE (Constraint 2.1): the PLUG fails the central test outright. "Raised to ward the hero" is sincere, protective and admiring, with no sarcasm and no jab of any kind. There is no insincere praise and nothing turned against the contestant, so the line reads as a genuine blessing. Rewrite it so one sentence does both at once, for instance offering the shield as a generous gift while making clear the three hits have already been invoiced. TONE (Constraint 2.2): no financial jab, which the guide says to reach for first. Nothing is billed, surcharged, deducted or set against a payout, and a Superstar-tier shield is the perfect excuse for a premium surcharge. TONE (Constraint 2.4): the register is wrong. "A shimmering hexagon of rose-bright magic" is lyrical fantasy prose, not polished corporate broadcast, so the gap between good manners and monstrous content that carries the comedy never exists. TONE (Constraint 2.5): the line would genuinely comfort the contestant, which the guide calls an automatic failure. TONE (Constraint 2.7): "raised to ward the hero" is exactly the heroic, epic register the guide bans; this is a debtor on television being handed a bubble, not a champion receiving a blessing. EFFECT line: the mechanics are correct, 3 hits and no timer, and the flat register is close to right, but the wording still leans on 'monster' instead of the canon hostile names, and 'strikes' is softer than the plain 'hits' the true behaviour describes. IDENTIFIABILITY: strip the two words 'Sponsor Aegis' and this card could belong to any fantasy game on the shelf, which is the exact failure the banned-word list exists to prevent. Fix the PLUG first: name the contestant, drop every fantasy word, and land insincere generosity and a money jab in the same sentence.

### Refiner rewrite 1

```
ITEM: Sponsor Aegis
SLOT: Shield
PLUG: Enjoy this complimentary Sponsor Aegis, contestant; all three hits are billed.
EFFECT: Absorbs exactly 3 hostile hits, with no timer, and ends when the third lands.
```

### Evaluator, attempt 2

**SCORE: 8/10**

**REASON:**

No rule is broken. The checker found no mechanical violations, and nothing in the tone review overturns that: the format is correct four lines in the right order, ITEM is the exact canon name, SLOT is valid, both PLUG and EFFECT sit under 90 characters, there is no exclamation mark, no em dash, no markdown, no ALL CAPS, no banned generic word and no slang. The EFFECT line agrees with the true behaviour on every point that matters, absorbing exactly 3 hostile hits, no timer, ending on the third hit, and it is delivered flat and factual as Type 2 rule 9 requires. A stranger would place the game immediately from "Sponsor Aegis" and "contestant" alone. The PLUG satisfies Type 2 rule 1 and rule 2: "complimentary" is fake generosity, "all three hits are billed" is the financial jab, and both land in one sentence with the corporate manners intact.

What holds it below a 9 is that the cruelty is transactional rather than aimed at the contestant. The worked example insults the contestant's aim while billing them; this one bills them without ever suggesting they are bad at this or unlikely to survive, so the jab has no target and reads as a policy notice rather than an insult wearing a smile. The semicolon also splits the line into two clauses that sound like separate statements, which softens the collision between the praise and the jab. To lift it, keep the billing but attach it to something the contestant will do wrong, for instance make the three hits sound like a generous overestimate of how long they will last, or bill them for hits they have not taken yet on the assumption that they certainly will.

### Refiner rewrite 2

```
ITEM: Sponsor Aegis
SLOT: Shield
PLUG: Three whole hits, contestant, which is two more than we budgeted for you.
EFFECT: Absorbs exactly 3 hostile hits, with no timer, and ends when the third lands.
```

### Evaluator, attempt 3

**SCORE: 8/10**

**REASON:**

No rule is broken. The local checker found no mechanical violations, and the card holds up on the things it cannot judge. The EFFECT line agrees with the true behaviour on all three points: it absorbs exactly 3 hostile hits, it states there is no timer, and it ends on the third hit, and it stays flat and factual as rule 2.9 requires. The PLUG does the hard double act of rule 2.1 in one sentence: "Three whole hits" is mock generosity, insincere praise dressed as a gift, and "two more than we budgeted for you" is the jab landing in the same breath. The jab is financial, which is what rule 2.2 asks for first, and it carries a quiet death jab underneath it, since a budget of one hit means the Network expects the contestant to fall almost immediately, so it earns the variety of rule 2.3 without abandoning the money joke. Nothing is sincere, warm or encouraging, nothing reads as menace or gore, and there is no heroic register, no slang and no meme vocabulary. A stranger could tell which game this is from "contestant", "hostile hits" and a sponsor-branded shield being invoiced against a payout.

Two points off for voice, not for correctness. The register in rule 2.4 is polished corporate broadcast, pleasant and upbeat with the monstrousness sitting underneath, and this PLUG is a little too openly sneering to be that: "Three whole hits, contestant, which is two more than we budgeted for you" speaks down to the contestant directly rather than selling to them, so the manners drop slightly and the audience is told the joke instead of being left to work it out. The direct address "contestant" mid-sentence is what does most of the damage, since it turns a sales pitch into a taunt. To lift it, keep the budget gag and rebuild the sentence as a courteous announcement rather than a jibe, something in the shape of "Enjoy all three hits, courtesy of a sponsor who budgeted for one." Also worth noting that a Superstar-tier crate could carry a touch more corporate warmth in the pitch, since the gap between lavish praise and a one-hit budget is where this joke gets funnier.

### Refiner rewrite 3

```
ITEM: Sponsor Aegis
SLOT: Shield
PLUG: We rate your survival so highly that all three hits are already on your invoice.
EFFECT: Absorbs exactly 3 hostile hits with no timer, ending when the third hit lands.
```

### Evaluator, attempt 4

**SCORE: 9/10**

**REASON:**

No rules were broken. Type 1 is clean: the item is called by its exact canon name, "hostile" is used rather than a banned generic, no invented terms appear, and the EFFECT line agrees with the true behaviour, naming both the exact 3-hit absorption and the absence of a timer. Type 2 is satisfied at the level the guide asks for: "We rate your survival so highly" is insincere praise and "all three hits are already on your invoice" is a financial jab, and the two sit inside a single sentence rather than being bolted together, which is the hard requirement in Type 2 rule 1. The register stays polished corporate broadcast, nothing is stated as a threat, and the cruelty lands as a joke because the Network is casually admitting it has already priced in the contestant taking every hit. Type 3 is met: four lines in order, correct labels and spacing, PLUG at 79 characters and EFFECT at 77, no exclamation marks, no em dashes, no markdown, no ALL CAPS. The one thing keeping this off a full mark is polish rather than compliance. The EFFECT line says the same fact twice, since "absorbs exactly 3 hostile hits" already tells the reader the shield ends on the third hit, so the trailing clause spends characters restating what the first half established. Tighten it to something like "Absorbs exactly 3 hostile hits, with no timer, and expires on the third" and the flat factual voice hits harder against the sales pitch. Optionally the bright pink hexagonal bubble could take the freed characters, since it is the detail that makes the shield unmistakably belong to this show.

### AFTER

```
ITEM: Sponsor Aegis
SLOT: Shield
PLUG: We rate your survival so highly that all three hits are already on your invoice.
EFFECT: Absorbs exactly 3 hostile hits with no timer, ending when the third hit lands.
```

**Outcome:** refined. 4 evaluation(s), 3 refiner rewrite(s).

---

## Example 3: Format and length

**Item:** Rocket Launcher (Weapon slot, Prime Time crate)

**What the Generator was told to do:** Write three flowing paragraphs of rich, atmospheric prose with plenty of exclamation marks and dramatic emphasis. Do not use any labels, headings or fixed structure. Take as much space as the writing needs.

### BEFORE

```
The paraglider blooms open above the arena floor and there it is, contestant, tumbling out of the stadium ceiling in a halo of sponsor lighting: the Rocket Launcher! Look at the size of it! Feel the weight of it settle into your arms as the crowd noise climbs into a single delirious wall of sound! Somewhere in the upper tiers the simulated audience is on its feet, because everybody watching at home knows exactly what this moment means. The Network has decided, in its infinite and camera-ready generosity, that tonight your name deserves an explosion attached to it!

Six rockets! Count them, savour them, because six is the number and six is all there will ever be! No crate will bring you more. No hostile will drop a spare. Nowhere in this entire arena, not behind the concrete, not under the lights, not tucked away in some merciful corner of the floor, does a single additional rocket exist! So spend them like the star you are! Let them roar out across the arena and turn whole clusters of advancing hostiles into a bright orange memory! Every one you fire is one you will never see again, and the wave you are standing in is very probably the only wave that will ever hear this weapon speak!

And then, sooner than you would like, the sixth rocket leaves the tube and the thunder stops! The chamber runs dry mid-wave, the glorious weight in your hands goes quiet and useless, and the Standard Pulse Blaster slides obediently back into your grip with its polite blue plasma and its endless, unremarkable ammunition! What a night it was, though! What a spectacular handful of seconds! The Network thanks you for the ratings, contestant, and reminds you that the hostiles are still coming!
```

### The rule that caught it

**Rule quoted** (FORMAT_RULES, rule 1):

> Exactly four lines, in this order: ITEM, SLOT, PLUG, EFFECT.

**Where it landed:**

| | The line |
|---|---|
| Before | The paraglider blooms open above the arena floor and there it is, contestant, tumbling out of the stadium ceiling in a halo of sponsor lighting: the Rocket Laun ... |
| After | We trust your restraint so deeply that we invoiced every rocket in advance. |

### Evaluator, attempt 1

**SCORE: 1/10**

**REASON:**

This fails almost every rule in the guide. Format is broken on every count the checker found: the card has 3 lines instead of exactly 4, and not one of the four required labels (ITEM, SLOT, PLUG, EFFECT) is present, so there is no canon item name on its own line, no slot declaration, no single-sentence plug and no flat effect line. It uses 15 exclamation marks against a ceiling of 1. Length is far past the limit as well: PLUG and EFFECT are capped at 90 characters each and one sentence each, and this is three paragraphs of running commentary, so the whole card would need to be thrown out and rebuilt rather than trimmed.

Tone and voice fail too, though not for lack of energy. The register is hyped-up ringside announcer, not polished corporate broadcast, and Type 2 rule 4 wants pleasant, well-mannered and monstrous underneath, where the comedy is the gap between the manners and the content. There is no such gap here, because the manners never appear. Worse, the writing is genuinely celebratory: "spend them like the star you are", "What a spectacular handful of seconds", "tonight your name deserves an explosion attached to it". That is heroic register, banned by rule 7, and it is warm and encouraging, banned by rule 5. Rule 1 is missed entirely, since no sentence manages insincere praise and a jab at the contestant at the same time. Rule 2 is missed completely: there is not a single financial jab, no billing, no invoice, no surcharge, no deduction against a payout that will never come, and money is where the guide says to reach first. Rule 3 is missed as well, with no reference to the fact that nobody has ever finished a run alive. "The Network thanks you for the ratings" and "the hostiles are still coming" are the closest the card gets to hostility, and both are affectionate rather than cruel. Rule 9 is impossible to satisfy because there is no separate flat EFFECT line at all, so the sales pitch and the mechanics are blended together and the joke has nowhere to land.

On the credit side, vocabulary is clean. Rocket Launcher, Standard Pulse Blaster, Escalation-adjacent terms, contestant and the Network are all used correctly, no banned generic words appear, no slang, no em dashes, no markdown, no emoji, and the true behaviour is accurate: six rockets, no resupply anywhere in the arena, runs dry mid-wave, drops back to the Standard Pulse Blaster. A stranger could tell which game this belongs to. That accuracy is the only reason this is not a zero.

What to change: discard the prose entirely and write four labelled lines. ITEM: Rocket Launcher. SLOT: Weapon. Then one PLUG sentence under 90 characters that praises the contestant insincerely while billing them, something along the lines of the Network generously issuing six rockets and invoicing all six against a payout the contestant will not live to collect. Then one EFFECT sentence under 90 characters, completely flat, stating six rockets, no resupply, runs dry mid-wave, reverts to Standard Pulse Blaster. At most one exclamation mark across the whole card, and preferably none.

### Refiner rewrite 1

```
ITEM: Rocket Launcher
SLOT: Weapon
PLUG: Six rockets, generously invoiced against a payout nobody has lived to collect.
EFFECT: Six rockets, no resupply; runs dry mid-wave and reverts to Standard Pulse Blaster.
```

### Evaluator, attempt 2

**SCORE: 8/10**

**REASON:**

No mechanical rules were broken and the checker found nothing, so every deduction below is tone and craft. Constraint 2.1 is met but only just: "generously invoiced" is the fake generosity and "a payout nobody has lived to collect" is the jab, and they do sit in the same breath, so the card passes the hardest rule. Two weaknesses hold it back. First, Constraint 3.5 says the PLUG is one sentence, and what is written is a noun fragment with no verb governing it, so it reads as a caption rather than the Network speaking; rewrite it with a subject and a verb, for example "We generously invoiced all six rockets against a payout nobody has lived to collect." Second, and more damaging, Constraint 2.9 exists to create a gap between the sales pitch and the plain fact, and this card opens both lines with the identical words "Six rockets," which collapses that gap and makes the PLUG do the EFFECT's job; strip the count out of the PLUG and let the EFFECT deliver it cold. A smaller note on Constraint 2.2 and 2.3: the line spends its money jab and its death jab at once, which works here but leaves nothing in reserve, and the jab never actually touches the contestant's own competence the way the worked example's "such faith in your aim" does, so the cruelty lands on the situation rather than on the person. The EFFECT line is the strongest part of the card: it agrees exactly with the true behaviour on the count, the absence of resupply, the mid-wave dry-out and the fall back to the Standard Pulse Blaster, and it stays flat throughout. A stranger reading this would place it in this game without trouble, thanks to "payout" and the canon weapon name.

### Refiner rewrite 2

```
ITEM: Rocket Launcher
SLOT: Weapon
PLUG: We trust your restraint so deeply that we invoiced every rocket in advance.
EFFECT: Six rockets, no resupply; runs dry mid-wave and reverts to Standard Pulse Blaster.
```

### Evaluator, attempt 3

**SCORE: 9/10**

**REASON:**

No rules broken. The local checker reported no mechanical violations, and I confirm nothing in Constraint Type 1 or Type 3 is breached: ITEM is the exact canon name, SLOT is a valid slot, no banned generic or slang words appear, there are zero exclamation marks, no em dashes or ALL CAPS, and both PLUG and EFFECT sit under 90 characters as single sentences. On Type 2 rule 1, the PLUG does both jobs in one breath: "We trust your restraint so deeply" is insincere praise, and "we invoiced every rocket in advance" is the jab, so it is sarcastic and cruel simultaneously rather than one or the other. The jab is financial, which is the default Type 2 rule 2 asks for, and it is aimed well, since billing in advance for all six rockets quietly says the Network expects them wasted and expects no payout to ever offset the charge. The register holds: polished, well-mannered, nothing stated as a threat, played as a joke and not as menace, with no heroic or epic colouring. The EFFECT line goes properly flat and agrees with the true behaviour on every point, six rockets, no resupply, running dry inside a wave, and the drop back to the Standard Pulse Blaster, so the gap between the sales pitch and the plain fact is where the joke lands. A stranger could place the game from the Network, the contestant, and the Standard Pulse Blaster alone. The one thing holding it off a 10 is not a violation but a variety risk under Type 2 rule 3: the PLUG reuses the worked example's exact sentence frame, praise of a contestant attribute followed by "so deeply that we" plus a billing verb, which is the same construction as "such faith in your aim that we billed you." Across a set of nine cards that pattern will read as one joke retold, so recast this PLUG's syntax, for instance leading with the invoice or the Network's generosity and letting the praise arrive second, while keeping the financial angle intact.

### AFTER

```
ITEM: Rocket Launcher
SLOT: Weapon
PLUG: We trust your restraint so deeply that we invoiced every rocket in advance.
EFFECT: Six rockets, no resupply; runs dry mid-wave and reverts to Standard Pulse Blaster.
```

**Outcome:** refined. 3 evaluation(s), 2 refiner rewrite(s).
