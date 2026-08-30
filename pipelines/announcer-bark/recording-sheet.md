# Announcer recording sheet

**Sponsor Me, Slayers!** &mdash; every line the host says, and what to
save it as. Generated from `barks.py`; do not edit by hand.

**60 clips** in total: 33 the host reacting to a
moment, and 27 sponsor reads used as filler.

## The voice

A hyped-up broadcast announcer who is openly making fun of the
contestant. A radio DJ with big lungs and no sympathy. Cheerful on the
surface, sarcastic underneath. He is never on the player's side.

**Repeated letters mean hold that sound.** Only 9 of the 41 stretch a
vowel, and never in DEAD AIR, where the joke is boredom.

**The tag on each line says who he is talking to:**

- `[AUD]` to the home audience, about the player
- `[YOU]` straight at the player
- `[TURN]` starts on the audience, then turns and hits the player mid-line

## What to do with the clips

1. Record each line and save it under the **filename** given below.
2. Import all of them into UEFN.
3. Make one **MSS Play Random Oneshot** preset per section, holding that
   section's clips.
4. Place ten Audio Player devices, point each at one preset, and wire it
   to the **device field** named in that section's heading.

A section left unwired simply stays quiet. A half-recorded host is safe
to ship.

---

## ShowIntro &mdash; 3 clip(s)

**Device field:** `ShowIntroVoice`  
**Plays when:** the moment START SHOW hands the arena over

**1. `showintro-01.wav`** &nbsp; `[AUD]`

> GOOOOOD EVENING, CHANNEL SIIIIX! AND HELLO TO TONIGHT'S VOLUNTEER. BRAVE. STUPID. BUT BRAVE.

**2. `showintro-02.wav`** &nbsp; `[AUD]`

> WELCOME BACK, SLAYERS! WE FOUND ANOTHER ONE WHO THINKS THEY'RE DIFFERENT!

**3. `showintro-03.wav`** &nbsp; `[YOU]`

> SIGNAL'S HOT, CHANNEL SIX IS LIVE! SPONSOR MEEEEE, SLAYERS! SELL IT LIKE YOUR LIFE'S ON IT. IT IS.

---

## RoundStart &mdash; 4 clip(s)

**Device field:** `RoundStartVoice`  
**Plays when:** a new room beginning

**4. `roundstart-01.wav`** &nbsp; `[AUD]`

> HERE THEY COME! WE'VE SEEN YOUR TAPE. WE'RE NOT WORRIED.

**5. `roundstart-02.wav`** &nbsp; `[AUD]`

> ROUND STARTS NOW! EYES OPEN, CHAMP. BOTH OF THEM.

**6. `roundstart-03.wav`** &nbsp; `[YOU]`

> OPEN THE GATES! LET'S SEE THAT FAMOUS STRATEGY OF YOURS. RUNNING. IT'S RUNNING.

**7. `roundstart-04.wav`** &nbsp; `[YOU]`

> IIIIT'S SHOW TIME! THE BAR IS LOW, CHAMP. CLEAR IT.

---

## KillStreak &mdash; 4 clip(s)

**Device field:** `KillStreakVoice`  
**Plays when:** three robots down close together

**8. `killstreak-01.wav`** &nbsp; `[AUD]`

> OOOOH! LOOK WHO FINALLY HIT SOMETHING!

**9. `killstreak-02.wav`** &nbsp; `[YOU]`

> RATINGS! DON'T LET IT GO TO YOUR HEAD. THERE'S NOT MUCH ROOM.

**10. `killstreak-03.wav`** &nbsp; `[YOU]`

> NOT BAD! FOR YOU. SPECIFICALLY FOR YOU.

**11. `killstreak-04.wav`** &nbsp; `[AUD]`

> SOMEBODY'S SHOWING OFF! ENJOY IT. IT NEVER LASTS.

---

## CashPickup &mdash; 3 clip(s)

**Device field:** `CashPickupVoice`  
**Plays when:** cash collected, roughly one pickup in eight

**12. `cashpickup-01.wav`** &nbsp; `[YOU]`

> DING DING DING! THAT GOES STRAIGHT TO WHAT YOU OWE US. YOU'RE ALMOST AT ZERO.

**13. `cashpickup-02.wav`** &nbsp; `[YOU]`

> OOOOH, SHIIIINY! LEGAL SAYS WE CAN'T CALL IT GOLD. SO. SHINY.

**14. `cashpickup-03.wav`** &nbsp; `[YOU]`

> CASH MONEY, FOLKS! PUT IT DOWN, CHAMP. YOU'RE STILL IN THE HOLE.

---

## CrateDrop &mdash; 3 clip(s)

**Device field:** `CrateDropVoice`  
**Plays when:** a sponsor crate finishing its descent

**15. `cratedrop-01.wav`** &nbsp; `[YOU]`

> YEAHHHHHH SPONSOR DROP! SOMEBODY OUT THERE FEELS SORRY FOR YOU!

**16. `cratedrop-02.wav`** &nbsp; `[AUD]`

> FREE STUFF, FOLKS! WE'RE NOT SAYING IT'LL HELP.

**17. `cratedrop-03.wav`** &nbsp; `[YOU]`

> INCOMING! THAT'S CHARITY, SWEETHEART. TAKE IT.

---

## LowHealth &mdash; 3 clip(s)

**Device field:** `LowHealthVoice`  
**Plays when:** health falling below 40 per cent

**18. `lowhealth-01.wav`** &nbsp; `[AUD]`

> OOOOOOH, THAT'S A LOT OF BLOOD FOR SOMEBODY WHO WAS SO CONFIDENT!

**19. `lowhealth-02.wav`** &nbsp; `[YOU]`

> HANG ON, SLAYER! ACTUALLY, DON'T. WE'RE AHEAD OF SCHEDULE.

**20. `lowhealth-03.wav`** &nbsp; `[AUD]`

> FOLKS, THEY'RE STRUGGLING! I KNOW. I'M AS SHOCKED AS YOU ARE.

---

## RoundClear &mdash; 3 clip(s)

**Device field:** `RoundClearVoice`  
**Plays when:** the last robot of a room going down

**21. `roundclear-01.wav`** &nbsp; `[TURN]`

> STILL ALIVE! NOBODY HERE HAD FAITH. NOBODY.

**22. `roundclear-02.wav`** &nbsp; `[YOU]`

> WAVE CLEARED! DON'T CELEBRATE, IT GETS WORSE.

**23. `roundclear-03.wav`** &nbsp; `[YOU]`

> ONE MORE IN THE BANK! OUR BANK. NOT YOURS. NEVER YOURS.

---

## SignOff &mdash; 2 clip(s)

**Device field:** `SignOffVoice`  
**Plays when:** the run lost, over the game over card

**24. `signoff-01.wav`** &nbsp; `[AUD]`

> THEY WERE GREAT TELEVISION, FOLKS! WHO'S NEXT?

**25. `signoff-02.wav`** &nbsp; `[TURN]`

> ANNND THAT'S OUR SHOOOOW! GOODNIGHT, CHANNEL SIIIIX!

---

## DeadAir &mdash; 5 clip(s)

**Device field:** `DeadAirVoice`  
**Plays when:** eighteen seconds of nothing happening

**26. `deadair-01.wav`** &nbsp; `[AUD]`

> WELL, THIS IS AWKWARD. THE ROBOTS ARE LATE. UNION THING.

**27. `deadair-02.wav`** &nbsp; `[YOU]`

> SOMEBODY DO SOMETHING. ANYTHING. I HAVE A QUOTA.

**28. `deadair-03.wav`** &nbsp; `[AUD]`

> STILL NOTHING! GREAT TELEVISION, EVERYBODY. GREAT.

**29. `deadair-04.wav`** &nbsp; `[?]`

> I AM CONTRACTUALLY REQUIRED TO KEEP TALKING. SO. HOW ARE YOU.

**30. `deadair-05.wav`** &nbsp; `[YOU]`

> THIS IS THE PART WE CUT IN EDITING.

---

## SponsorRead &mdash; 5 clip(s)

**Device field:** `SponsorReadVoice`  
**Plays when:** the same, taking turns with the dead air lines

**31. `sponsorread-01.wav`** &nbsp; `[?]`

> TONIGHT'S EPISODE IS BROUGHT TO YOU BY WHOEVER WAS UNFORTUNATE ENOUGH TO PICK UP THE PHONE.

**32. `sponsorread-02.wav`** &nbsp; `[AUD]`

> WHILE WE WAIT, A WORD FROM OUR SPONSORS... THIS PROGRAM IS MADE WITH ARTIFICIAL INTELLIGENCE. THE HUMAN RESPONSIBLE CAN'T CODE. THEY CONTRIBUTED MORAL SUPPORT AND NOTHING ELSE.

**33. `sponsorread-03.wav`** &nbsp; `[?]`

> THE NETWORK IS PROUD TO PRESENT... FEEL-GOOD FORMULA! GOOD MOOD SOLD SEPARATELY!

**34. `sponsorread-04.wav`** &nbsp; `[?]`

> CALL 1-800-SUCK-IT! THE VACUUM... THAT SUCKS!

**35. `sponsorread-05.wav`** &nbsp; `[?]`

> THIS VOICE WAS BROUGHT TO YOU BY THE FINE FOLKS AT ELEVENLABS! THE CREATOR TRIED TO DO IT THEMSELVES. WE HAVE THE TAPE. WE'RE NOT PLAYING IT.

---

## CrateCalled &mdash; 5 clip(s)

**Device field:** `?`  
**Plays when:** ?

**36. `cratecalled-01.wav`** &nbsp; `[AUD]`

> AN ORDER! LEGAL SAYS I HAVE TO SOUND EXCITED.

**37. `cratecalled-02.wav`** &nbsp; `[AUD]`

> CRATE ORDER GOING THROUGH! PLEASE ALLOW SEVERAL SECONDS FOR DELIVERY!

**38. `cratecalled-03.wav`** &nbsp; `[?]`

> AN ORDER JUST CAME IN! EITHER SOMEBODY LOVES YOU OR SOMEBODY LOST A BET.

**39. `cratecalled-04.wav`** &nbsp; `[?]`

> ONE CRATE, COMING RIGHT UP! NO SHIPPING, NO HANDLING, NO PAPERWORK, NO QUESTIONS!

**40. `cratecalled-05.wav`** &nbsp; `[AUD]`

> CRATE ORDER CONFIRMED! CLOCK'S RUNNING, FOLKS!

---

## PrizeLanded &mdash; 14 clip(s)

**Device field:** `?`  
**Plays when:** ?

**41. `prizelanded-01.wav`** &nbsp; `[AUD]`

> BUT WAIT! IT'S A TOASTER! ONE SETTING. BURNT. NO REFUNDS.

**42. `prizelanded-02.wav`** &nbsp; `[AUD]`

> AND THE VAULT COUGHS UP... A BRAND NEW TELEVISION! ONE CHANNEL ONLY!

**43. `prizelanded-03.wav`** &nbsp; `[?]`

> HEADS UP! ITS THE HAND-CRANK WASHING MACHINE! NOW WITH ONE HUNDRED PERCENT MORE MANUAL LABOR!

**44. `prizelanded-04.wav`** &nbsp; `[?]`

> IT CHILLS! IT HUMS! NOT BY DESIGN... IT'S A REFRIGERATOR! SLIGHTLY HAUNTED

**45. `prizelanded-05.wav`** &nbsp; `[AUD]`

> IT HEATS IN MINUTES! IT'S A MICROWAVE! TURNTABLE SOLD SEPARATELY.

**46. `prizelanded-06.wav`** &nbsp; `[AUD]`

> BRING THE PARTY ANYWHERE! IT'S A BOOMBOX! BATTERIES NOT INCLUDED.

**47. `prizelanded-07.wav`** &nbsp; `[AUD]`

> LIGHT UP YOUR LIFE! IT'S A LAMP!

**48. `prizelanded-08.wav`** &nbsp; `[AUD]`

> ERGONOMIC! ADJUSTABLE! IT'S AN OFFICE CHAIR!

**49. `prizelanded-09.wav`** &nbsp; `[AUD]`

> SOFT! ABSORBENT! STRONG! ONE PLY TOILET PAPER

**50. `prizelanded-10.wav`** &nbsp; `[AUD]`

> A TRIP FOR TWO TO HAWAIIII! AIRFARE NOT INCLUDED. HAWAII NOT INCLUDED.

**51. `prizelanded-11.wav`** &nbsp; `[?]`

> DURABLE! WEATHERPROOF! CERTIFIED AUTHENTIC! IT'S A CONE.

**52. `prizelanded-12.wav`** &nbsp; `[?]`

> PRIVACY! PORTABILITY! AND IT'S ALL YOURS! GENTLY USED PORT-A-POTTY

**53. `prizelanded-13.wav`** &nbsp; `[?]`

> THERE IT IS, CHAMP. A PREOWNED COFFIN, TRY TO LOOK GRATEFUL.

**54. `prizelanded-14.wav`** &nbsp; `[?]`

> STURDY! SPACIOUS! A BOX FOR YOUR WINNINGS!

---

## FirstTank &mdash; 2 clip(s)

**Device field:** `?`  
**Plays when:** ?

**55. `firsttank-01.wav`** &nbsp; `[?]`

> SAY HELLO TO BIG STEVE! SEASON TWO CONTESTANT. TOOK THE SEVERANCE PACKAGE.

**56. `firsttank-02.wav`** &nbsp; `[?]`

> HE'S BIGGER! HE'S BADDER! HE'S BEEN HERE LONGER THAN YOU'VE BEEN ALIVE! LADIES AND GENTLEMEN, THE TAAAANK

---

## FirstBoar &mdash; 2 clip(s)

**Device field:** `?`  
**Plays when:** ?

**57. `firstboar-01.wav`** &nbsp; `[?]`

> HE'S GOT ARMOR! HE'S GOT TUSKS! HE'S GOT A SHOTGUN! IIIT'S THE BOOOOAR!

**58. `firstboar-02.wav`** &nbsp; `[?]`

> HE'S ARMORED! HE'S ANGRY! HE CAME OFF A CANCELLED SHOW! HEEERE'S THE BOOOOAR!

---

## FirstSniper &mdash; 2 clip(s)

**Device field:** `?`  
**Plays when:** ?

**59. `firstsniper-01.wav`** &nbsp; `[?]`

> OUR MARKSMAN JUST ARRIVED! SOMEWHERE. WE'RE NOT SAYING WHERE.

**60. `firstsniper-02.wav`** &nbsp; `[?]`

> THE SNIPER'S CLOCKED IN! LEGAL WON'T LET ME SAY HIS NAME. SOMETHING ABOUT AN ONGOING CASE. HE'S LOVELY THOUGH.

