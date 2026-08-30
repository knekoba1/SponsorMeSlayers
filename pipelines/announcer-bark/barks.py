# barks.py
#
# KAILEE'S BARK LINES. THIS FILE IS HERS AND NO AGENT MAY WRITE ONE.
#
# CLAUDE.md standing rule 3 and GDD Section 4: the sarcastic commentator lines
# are hand-written by the human designer. Claude may structure this database and
# map it to triggers, and may never invent, draft, rewrite or improve a line in
# it. The rest of this pipeline has no language model in it for that reason.
#
# ALL 41 LINES ARRIVED FROM KAI ON 2026-08-28, in one document titled "SPONSOR
# ME, SLAYERS! - Announcer Lines". They are transcribed here character for
# character. Nothing was added, cut, reordered or tidied. Kai's own numbering
# 1 to 41 runs straight down this file, and the numbers are kept in the comments
# because two of Kai's notes refer to lines by number.
#
# KAI'S TWO STANDING NOTES ON THE TEXT, both from that document:
#   * Line 24, "THEY WERE GREAT TELEVISION, FOLKS! WHO'S NEXT?", is the locked
#     host line from the death screen notes. DO NOT REWORD IT.
#   * The trademark symbols came off lines 39 and 40 because nobody says "tee
#     em" out loud. They still belong on any ON-SCREEN version of those two.
#
# THE TAG ON EACH LINE IS A DELIVERY DIRECTION, NOT GAMEPLAY DATA, which is why
# it is a comment rather than a field. Kai's document defines them:
#   [AUD]  talking to the home audience about the player
#   [YOU]  talking straight at the player
#   [TURN] starts on the audience, then turns and hits the player mid-line
#
# THE VOICE, in Kai's words: "a hyped-up broadcast announcer who is openly
# making fun of the contestant. Think a radio DJ with big lungs and no sympathy.
# Cheerful on the surface, sarcastic underneath. He is never on the player's
# side." Repeated letters mean HOLD THAT SOUND. Only 9 of the 41 stretch a
# vowel, and never in DEAD AIR, where the joke is boredom.
#
# The show is on CHANNEL 6.
#
# The trigger names and the number of slots come from settings.py.

BARKS = {
    # -- SHOW INTRO --
    # BroadcastScreen, the moment START SHOW hands the arena over
    "ShowIntro": [
        # 1. [AUD]
        "GOOOOOD EVENING, CHANNEL SIIIIX! AND HELLO TO TONIGHT'S VOLUNTEER. BRAVE. STUPID. BUT BRAVE.",
        # 2. [AUD]
        "WELCOME BACK, SLAYERS! WE FOUND ANOTHER ONE WHO THINKS THEY'RE DIFFERENT!",
        # 3. [TURN]
        "SIGNAL'S HOT, CHANNEL SIX IS LIVE! SPONSOR MEEEEE, SLAYERS! SELL IT LIKE YOUR LIFE'S ON IT. IT IS.",
    ],

    # -- ROUND START --
    # WaveManager, a wave beginning
    "RoundStart": [
        # 4. [YOU]
        "HERE THEY COME! WE'VE SEEN YOUR TAPE. WE'RE NOT WORRIED.",
        # 5. [YOU]
        "ROUND STARTS NOW! EYES OPEN, CHAMP. BOTH OF THEM.",
        # 6. [YOU]
        "OPEN THE GATES! LET'S SEE THAT FAMOUS STRATEGY OF YOURS. RUNNING. IT'S RUNNING.",
        # 7. [YOU]
        "IIIIT'S SHOW TIME! THE BAR IS LOW, CHAMP. CLEAR IT.",
    ],

    # -- DOING WELL / KILL STREAK --
    # HypeMeterManager, its CLUSTER KILL
    "KillStreak": [
        # 8. [AUD]
        "OOOOH! LOOK WHO FINALLY HIT SOMETHING!",
        # 9. [YOU]
        "RATINGS! DON'T LET IT GO TO YOUR HEAD. THERE'S NOT MUCH ROOM.",
        # 10. [YOU]
        "NOT BAD! FOR YOU. SPECIFICALLY FOR YOU.",
        # 11. [AUD]
        "SOMEBODY'S SHOWING OFF! ENJOY IT. IT NEVER LASTS.",
    ],

    # -- CASH AND PRIZE PICKUP --
    # cash_drop_manager, a prop walked over
    "CashPickup": [
        # 12. [YOU]
        "DING DING DING! THAT GOES STRAIGHT TO WHAT YOU OWE US. YOU'RE ALMOST AT ZERO.",
        # 13. [YOU]
        "OOOOH, SHIIIINY! LEGAL SAYS WE CAN'T CALL IT GOLD. SO. SHINY.",
        # 14. [YOU]
        "CASH MONEY, FOLKS! PUT IT DOWN, CHAMP. YOU'RE STILL IN THE HOLE.",
    ],

    # -- SPONSOR CRATE DROP --
    # CrateManager, a crate reaching its hover height
    "CrateDrop": [
        # 15. [YOU]
        "YEAHHHHHH SPONSOR DROP! SOMEBODY OUT THERE FEELS SORRY FOR YOU!",
        # 16. [AUD]
        "FREE STUFF, FOLKS! WE'RE NOT SAYING IT'LL HELP.",
        # 17. [YOU]
        "INCOMING! THAT'S CHARITY, SWEETHEART. TAKE IT.",
    ],

    # -- LOW HEALTH --
    # HypeMeterManager, the contestant below the Underdog Boost line
    "LowHealth": [
        # 18. [AUD]
        "OOOOOOH, THAT'S A LOT OF BLOOD FOR SOMEBODY WHO WAS SO CONFIDENT!",
        # 19. [YOU]
        "HANG ON, SLAYER! ACTUALLY, DON'T. WE'RE AHEAD OF SCHEDULE.",
        # 20. [AUD]
        "FOLKS, THEY'RE STRUGGLING! I KNOW. I'M AS SHOCKED AS YOU ARE.",
    ],

    # -- ROUND CLEAR --
    # WaveManager, GDD 2.5's Room Won
    "RoundClear": [
        # 21. [TURN]
        "STILL ALIVE! NOBODY HERE HAD FAITH. NOBODY.",
        # 22. [YOU]
        "WAVE CLEARED! DON'T CELEBRATE, IT GETS WORSE.",
        # 23. [YOU]
        "ONE MORE IN THE BANK! OUR BANK. NOT YOURS. NEVER YOURS.",
    ],

    # -- DEATH / SIGN-OFF --
    # GameOverScreen, the run lost
    "SignOff": [
        # 24. [AUD]
        "THEY WERE GREAT TELEVISION, FOLKS! WHO'S NEXT?",
        # 25. [TURN]
        "ANNND THAT'S OUR SHOOOOW! GOODNIGHT, CHANNEL SIIIIX!",
    ],

    # -- DEAD AIR --
    # NOT WIRED YET. Needs an idle timer: nothing has happened for a while
    "DeadAir": [
        # 26. [AUD]
        "WELL, THIS IS AWKWARD. THE ROBOTS ARE LATE. UNION THING.",
        # 27. [YOU]
        "SOMEBODY DO SOMETHING. ANYTHING. I HAVE A QUOTA.",
        # 28. [AUD]
        "STILL NOTHING! GREAT TELEVISION, EVERYBODY. GREAT.",
        # 30. [YOU]
        "I AM CONTRACTUALLY REQUIRED TO KEEP TALKING. SO. HOW ARE YOU.",
        # 32. [AUD]
        "THIS IS THE PART WE CUT IN EDITING.",
    ],

    # -- SPONSOR READS --
    # NOT WIRED YET. The filler pool, see settings.py
    "SponsorRead": [
        # 36. [AUD]
        "TONIGHT'S EPISODE IS BROUGHT TO YOU BY WHOEVER WAS UNFORTUNATE ENOUGH TO PICK UP THE PHONE.",
        # 37. [AUD]
        "WHILE WE WAIT, A WORD FROM OUR SPONSORS... THIS PROGRAM IS MADE WITH ARTIFICIAL INTELLIGENCE. THE HUMAN RESPONSIBLE CAN'T CODE. THEY CONTRIBUTED MORAL SUPPORT AND NOTHING ELSE.",
        # 40. [AUD]
        "THE NETWORK IS PROUD TO PRESENT... FEEL-GOOD FORMULA! GOOD MOOD SOLD SEPARATELY!",
        # 41. [AUD]
        "CALL 1-800-SUCK-IT! THE VACUUM... THAT SUCKS!",
        # 42. [AUD]
        "THIS VOICE WAS BROUGHT TO YOU BY THE FINE FOLKS AT ELEVENLABS! THE CREATOR TRIED TO DO IT THEMSELVES. WE HAVE THE TAPE. WE'RE NOT PLAYING IT.",
    ],


    # -- ADDED 2026-08-29, ALL EMPTY. These are Kai's to write, the same as
    # every other line in this file. An empty list means the host stays quiet
    # for that moment, which is safe to ship.

    # -- CRATE CALLED --
    # SimulatedAudience, the crowd chanting for a crate before it falls
    "CrateCalled": [
        # 1. [AUD]
        "AN ORDER! LEGAL SAYS I HAVE TO SOUND EXCITED.",
        # 2. [AUD]
        "CRATE ORDER GOING THROUGH! PLEASE ALLOW SEVERAL SECONDS FOR DELIVERY!",
        # 3. [YOU]
        "AN ORDER JUST CAME IN! EITHER SOMEBODY LOVES YOU OR SOMEBODY LOST A BET.",
        # 4. [AUD]
        "ONE CRATE, COMING RIGHT UP! NO SHIPPING, NO HANDLING, NO PAPERWORK, NO QUESTIONS!",
        # 5. [AUD]
        "CRATE ORDER CONFIRMED! CLOCK'S RUNNING, FOLKS!",
    ],

    # -- PRIZE LANDED --
    # PrizeVault, a prize won off a crate
    "PrizeLanded": [
        # IN PRIZE VAULT ORDER, one line per prize, so the split into a line
        # per prize is a move rather than a rewrite. Kai wrote 11 of the 14 on
        # 2026-08-30; the television, washing machine and coffin came over from
        # SponsorRead earlier the same day.
        #
        # 1. TOASTER, ONE SETTING: BURNT        [AUD]
        "BUT WAIT! IT'S A TOASTER! ONE SETTING. BURNT. NO REFUNDS.",
        # 2. NEW TELEVISION: ONE CHANNEL ONLY   [AUD]
        "AND THE VAULT COUGHS UP... A BRAND NEW TELEVISION! ONE CHANNEL ONLY!",
        # 3. HAND-CRANK WASHING MACHINE         [YOU]
        "HEADS UP! ITS THE HAND-CRANK WASHING MACHINE! NOW WITH ONE HUNDRED PERCENT MORE MANUAL LABOR!",
        # 4. REFRIGERATOR, LIGHTLY HAUNTED      [AUD]
        "IT CHILLS! IT HUMS! NOT BY DESIGN... IT'S A REFRIGERATOR!",
        # 5. MICROWAVE, TURNTABLE MISSING       [AUD]
        "IT HEATS IN MINUTES! IT'S A MICROWAVE! TURNTABLE SOLD SEPARATELY.",
        # 6. BOOMBOX, BATTERIES NOT INCLUDED    [AUD]
        "BRING THE PARTY ANYWHERE! IT'S A BOOMBOX! BATTERIES NOT INCLUDED.",
        # 7. LAMP: DARK SINCE SEASON 4          [AUD]
        "LIGHT UP YOUR LIFE! IT'S A LAMP!",
        # 8. OFFICE CHAIR: SINKS OVERTIME       [AUD]
        "ERGONOMIC! ADJUSTABLE! IT'S AN OFFICE CHAIR!",
        # 9. TOILET PAPER, ONE (1) PLY          [AUD]
        "SOFT! ABSORBENT! STRONG! ONE PLY TOILET PAPER",
        # 10. TRIP TO HAWAII* (*NOT INCLUDED)   [AUD]
        "A TRIP FOR TWO TO HAWAIIII! AIRFARE NOT INCLUDED. HAWAII NOT INCLUDED.",
        # 11. AUTHENTIC TRAFFIC CONE            [AUD]
        "DURABLE! WEATHERPROOF! CERTIFIED AUTHENTIC! IT'S A CONE.",
        # 12. A PORTA-POTTY TO CALL YOUR OWN    [AUD]
        "PRIVACY! PORTABILITY! AND IT'S ALL YOURS! GENTLY USED PORT-A-POTTY",
        # 13. PRE-OWNED COFFIN                  [YOU]
        "THERE IT IS, CHAMP. A PREOWNED COFFIN, TRY TO LOOK GRATEFUL.",
        # 14. A BOX, FOR YOUR WINNINGS          [AUD]
        "STURDY! SPACIOUS! A BOX FOR YOUR WINNINGS!",
    ],

    # -- FIRST TANK --
    "FirstTank": [
        # 45. [AUD]
        "SAY HELLO TO BIG STEVE! SEASON TWO CONTESTANT. TOOK THE SEVERANCE PACKAGE.",
        # 46. [AUD]
        "HE'S BIGGER! HE'S BADDER! HE'S BEEN HERE LONGER THAN YOU'VE BEEN ALIVE! LADIES AND GENTLEMEN, THE TAAAANK",
    ],

    # -- FIRST BOAR --
    "FirstBoar": [
        # 47. [AUD]
        "THE BOAR'S ON THE FLOOR! HE'S BEEN WRITTEN UP FOUR TIMES! IIIT'S THE BOOOOAR!",
        # 48. [AUD]
        "HE'S ARMORED! HE'S ANGRY! HE CAME OFF A CANCELLED SHOW! HEEERE'S THE BOOOOAR!",
    ],

    # -- FIRST SNIPER --
    "FirstSniper": [
        # 49. [AUD]
        "OUR MARKSMAN JUST ARRIVED! SOMEWHERE. WE'RE NOT SAYING WHERE.",
        # 50. [AUD]
        "THE SNIPER'S CLOCKED IN! LEGAL WON'T LET ME SAY HIS NAME. SOMETHING ABOUT AN ONGOING CASE. HE'S LOVELY THOUGH.",
    ],
}
