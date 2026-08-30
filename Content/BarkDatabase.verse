# BarkDatabase.verse
#
# GDD Section 4 "Announcer Bark" -- the commentator dialogue database and
# its trigger mapping. Amendment 90 sets the count at 41, all held in memory,
# because streaming them stuttered and ruined the comedic timing.
#
# WRITTEN BY pipelines/announcer-bark/compile_verse.py. DO NOT EDIT BY HAND:
# the next run overwrites it. The lines themselves are Kailee's and live in
# pipelines/announcer-bark/barks.py. No agent in this project may write,
# rewrite or improve them, per CLAUDE.md standing rule 3.

using { /Fortnite.com/Devices }
using { /Verse.org/Random }
using { /Verse.org/Simulation }

bark_database := class(creative_device):

    # One entry per trigger. An empty list means that moment has no line
    # written yet and the commentator stays quiet, which is deliberate.
    Lines : [string][]string = map{
        # BroadcastScreen, the moment START SHOW hands the arena over
        "ShowIntro" => array{
            "GOOOOOD EVENING, CHANNEL SIIIIX! AND HELLO TO TONIGHT'S VOLUNTEER. BRAVE. STUPID. BUT BRAVE.",
            "WELCOME BACK, SLAYERS! WE FOUND ANOTHER ONE WHO THINKS THEY'RE DIFFERENT!",
            "SIGNAL'S HOT, CHANNEL SIX IS LIVE! SPONSOR MEEEEE, SLAYERS! SELL IT LIKE YOUR LIFE'S ON IT. IT IS."
        },
        # WaveManager, a wave beginning
        "RoundStart" => array{
            "HERE THEY COME! WE'VE SEEN YOUR TAPE. WE'RE NOT WORRIED.",
            "ROUND STARTS NOW! EYES OPEN, CHAMP. BOTH OF THEM.",
            "OPEN THE GATES! LET'S SEE THAT FAMOUS STRATEGY OF YOURS. RUNNING. IT'S RUNNING.",
            "IIIIT'S SHOW TIME! THE BAR IS LOW, CHAMP. CLEAR IT."
        },
        # HypeMeterManager, its CLUSTER KILL
        "KillStreak" => array{
            "OOOOH! LOOK WHO FINALLY HIT SOMETHING!",
            "RATINGS! DON'T LET IT GO TO YOUR HEAD. THERE'S NOT MUCH ROOM.",
            "NOT BAD! FOR YOU. SPECIFICALLY FOR YOU.",
            "SOMEBODY'S SHOWING OFF! ENJOY IT. IT NEVER LASTS."
        },
        # cash_drop_manager, a prop walked over
        "CashPickup" => array{
            "DING DING DING! THAT GOES STRAIGHT TO WHAT YOU OWE US. YOU'RE ALMOST AT ZERO.",
            "OOOOH, SHIIIINY! LEGAL SAYS WE CAN'T CALL IT GOLD. SO. SHINY.",
            "CASH MONEY, FOLKS! PUT IT DOWN, CHAMP. YOU'RE STILL IN THE HOLE."
        },
        # CrateManager, a crate reaching its hover height
        "CrateDrop" => array{
            "YEAHHHHHH SPONSOR DROP! SOMEBODY OUT THERE FEELS SORRY FOR YOU!",
            "FREE STUFF, FOLKS! WE'RE NOT SAYING IT'LL HELP.",
            "INCOMING! THAT'S CHARITY, SWEETHEART. TAKE IT."
        },
        # HypeMeterManager, the contestant below the Underdog Boost line
        "LowHealth" => array{
            "OOOOOOH, THAT'S A LOT OF BLOOD FOR SOMEBODY WHO WAS SO CONFIDENT!",
            "HANG ON, SLAYER! ACTUALLY, DON'T. WE'RE AHEAD OF SCHEDULE.",
            "FOLKS, THEY'RE STRUGGLING! I KNOW. I'M AS SHOCKED AS YOU ARE."
        },
        # WaveManager, GDD 2.5's Room Won
        "RoundClear" => array{
            "STILL ALIVE! NOBODY HERE HAD YOU. NOBODY.",
            "WAVE CLEARED! DON'T CELEBRATE, IT GETS WORSE.",
            "ONE MORE IN THE BANK! OUR BANK. NOT YOURS. NEVER YOURS."
        },
        # GameOverScreen, the run lost
        "SignOff" => array{
            "THEY WERE GREAT TELEVISION, FOLKS! WHO'S NEXT?",
            "ANNND THAT'S OUR SHOOOOW! GOODNIGHT, CHANNEL SIIIIX! WE BARELY KNEW YA, AND WE'RE FINE WITH THAT."
        },
        # NOT WIRED YET. Needs an idle timer: nothing has happened for a while
        "DeadAir" => array{
            "WELL, THIS IS AWKWARD. THE ROBOTS ARE LATE. UNION THING.",
            "SOMEBODY DO SOMETHING. ANYTHING. I HAVE A QUOTA.",
            "STILL NOTHING! GREAT TELEVISION, EVERYBODY. GREAT.",
            "WHILE WE WAIT, A WORD FROM OUR SPONSORS.",
            "I AM CONTRACTUALLY REQUIRED TO KEEP TALKING. SO. HOW ARE YOU.",
            "THIS IS THE PART WE CUT IN EDITING.",
            "FUN FACT: THE FLOOR IS EASIER TO CLEAN THAN IT USED TO BE. YOU'RE WELCOME."
        },
        # NOT WIRED YET. The filler pool, drawn from when a moment has nothing fresh
        "SponsorRead" => array{
            "AND THE VAULT COUGHS UP... A BRAND NEW TELEVISION! ONE CHANNEL ONLY!",
            "THERE IT IS, CHAMP. A PREOWNED COFFIN, TRY TO LOOK GRATEFUL.",
            "TONIGHT'S EPISODE IS BROUGHT TO YOU BY WHOEVER WAS UNFORTUNATE ENOUGH TO PICK UP THE PHONE.",
            "THIS PROGRAM IS MADE WITH ARTIFICIAL INTELLIGENCE. THE HUMAN RESPONSIBLE CAN'T CODE. THEY CONTRIBUTED MORAL SUPPORT AND NOTHING ELSE.",
            "HEADS UP! ITS THE HAND-CRANK WASHING MACHINE! NOW WITH ONE HUNDRED PERCENT MORE MANUAL LABOR! DON'T STAND UNDER IT.",
            "THE NETWORK IS PROUD TO PRESENT... FEEL-GOOD FORMULA! GOOD MOOD SOLD SEPARATELY!",
            "CALL 1-800-SUCK-IT! THE VACUUM THAT SUUUUCKS!",
            "THIS VOICE WAS BROUGHT TO YOU BY THE FINE FOLKS AT ELEVENLABS! THE CREATOR TRIED TO DO IT THEMSELVES. WE HAVE THE TAPE. WE'RE NOT PLAYING IT."
        },
        # SimulatedAudience, the crowd chanting for a crate before it falls
        "CrateCalled" => array{
            "AN ORDER! LEGAL SAYS I HAVE TO SOUND EXCITED. WOO.",
            "CRATE ORDER GOING THROUGH! PLEASE ALLOW SEVERAL SECONDS FOR DELIVERY!",
            "AN ORDER JUST CAME IN! EITHER SOMEBODY LOVES YOU OR SOMEBODY LOST A BET.",
            "ONE CRATE, COMING RIGHT UP! NO SHIPPING, NO HANDLING, NO PAPERWORK, NO QUESTIONS!",
            "CRATE ORDER CONFIRMED! CLOCK'S RUNNING, FOLKS!"
        },
        # PrizeVault, a prize won off a crate
        "PrizeLanded" => array{},
        # NOT WIRED YET. The first Heavy Elite Tank of a run walking in
        "FirstTank" => array{},
        # NOT WIRED YET. The first Cyber-Boar of a run
        "FirstBoar" => array{},
        # NOT WIRED YET. The first Ranged Sentinel of a run
        "FirstSniper" => array{}
    }

    # A line for this moment, or the empty string if none is written yet.
    # Random so a trigger with two or three lines does not repeat itself.
    GetBark<public>(Trigger : string):string =
        if (Found := Lines[Trigger], Found.Length > 0):
            if (Pick := Found[GetRandomInt(0, Found.Length - 1)]):
                Pick
            else:
                ""
        else:
            ""

    # How many lines a trigger has, for the startup log.
    CountFor<public>(Trigger : string)<transacts>:int =
        if (Found := Lines[Trigger]):
            Found.Length
        else:
            0

    OnBegin<override>()<suspends>:void =
        var Written : int = 0
        var Mapped : int = 0
        for (Trigger -> Found : Lines):
            set Written += Found.Length
            set Mapped += 1
        Print("DEBUG: Bark database up -- {Written} bark(s) across {Mapped} trigger(s).")
