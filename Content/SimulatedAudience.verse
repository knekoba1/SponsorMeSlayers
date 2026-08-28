# SimulatedAudience.verse
#
# GDD Section 4 "Simulated Audience" -- decides the quality tier and the landing
# spot of every paraglider crate, and does nothing else.
#
# WHY THIS IS ITS OWN FILE. The Section 4 handoff table gives this system the
# "random-coordinate crate spawn parameters" and gives Gameplay Systems the
# machinery that actually puts a crate in the arena. GDD 4.1 makes the human
# designer the only checkpoint between the two. Keeping them apart is what makes
# this system swappable: it can be replaced, stubbed, or fed fixed test numbers
# without touching a line of crate-spawning code. DO NOT MERGE THE TWO.
#
# THE HANDOFF. This file signals SpawnCrateEvent, named after GDD 4.2's payload,
# carrying a tier and a 3D location. Whoever drops crates awaits that event.
# This file spawns nothing and holds no reference to any crate device.
#
# WHEN A CRATE IS ORDERED. Two triggers, Kailee's ruling 2026-08-18:
#   1. Climbing into a higher Hype tier, which is GDD 2.1 step 3's "crossing
#      Hype thresholds", graded at the tier just entered.
#   2. A repeating trickle, graded at whatever tier the player is in when it
#      fires. 2.1 calls the loop recursive, and threshold crossings alone deliver
#      only three or four crates in a whole run, which leaves steps 3 and 4 of
#      that loop barely happening.
#
# TIERS ARE NUMBERS HERE, 0 to 3. Underdog 0, Rising Star 1, Superstar 2, Prime
# Time 3. The receiving side keeps one Supply Drop Spawner per tier, each with
# its own Supply FXColor for GDD 3.2's colour coding, so a number indexes that
# list directly. Prime Time is amendment 24 and is not in the GDD.

using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Random }
using { /Verse.org/Simulation }

# One crate order: the payload of GDD 4.2's SpawnCrateEvent.
crate_order := struct:
    # 0 Underdog, 1 Rising Star, 2 Superstar, 3 Prime Time.
    Tier : int
    # Where the crate should come down.
    LandingSpot : vector3

simulated_audience := class(creative_device):

    # The Hype meter this audience watches. GDD Section 4 gives the meter and the
    # crate parameters to the same system, so it is reading its own other half.
    @editable
    HypeMeter : hype_meter_manager = hype_meter_manager{}

    # Hype at or above this is Rising Star. Amendment 13, ruled 2026-08-18.
    # THE TIER THRESHOLDS ARE NOT KEPT HERE ANY MORE. They are asked of the Hype
    # Meter, which owns them, through the three getters below.
    #
    # WHY THEY MOVED. Found in the 2026-08-26 audit: the same three numbers were
    # typed into both devices, and both sets are ALSO tuned on the placed devices
    # where the saved value beats the script. Change one in UEFN and not the
    # other and the marks painted on the thermometer stop matching the tier of
    # crate that actually falls, with nothing on screen to say so.
    #
    # This device already held a reference to the Hype Meter to read the Hype
    # itself, so asking it for the thresholds too costs no new wiring.

    # Seconds between trickle crates. 25 is a starting guess meant to be tuned by
    # feel in UEFN. Mirror any change back into this default.
    @editable
    TrickleSeconds : float = 25.0

    # HOW FAR A CRATE MAY LAND FROM THIS DEVICE, AS A RECTANGLE RATHER THAN A
    # CIRCLE. PLACE THIS DEVICE IN THE MIDDLE OF THE ARENA: its own position is
    # the centre, and if it sits off to one side the whole zone shifts with it.
    #
    # WHY NOT A CIRCLE. The arena is five floor tiles by three, confirmed by Kai
    # 2026-08-22, which at 512 a tile is 25.6 by 15.4 metres. A circle wide enough
    # to use the length spills out of the sides, because the short axis is only
    # 7.7 metres from the middle. Crates were landing outside the room.
    #
    # 1050 and 550 leave roughly two metres of margin on every side, so a crate
    # never lands in a wall or close enough to one to be awkward to reach.
    #
    # This supersedes the circular radius twice ruled on 2026-08-22, at 1500 and
    # then 1100. Both were measured against the room's LENGTH, which was the
    # wrong axis: the short one is what a crate falls out of.
    #
    # THIS IS THE DROP RECTANGLE, NOT THE ROOM, and 2026-08-28 is when that
    # finally got written down. Five other files had copied these two figures as
    # if they were the walls, and the containment guard then hauled Kai back
    # every time they ran at a wall they were entitled to touch. The room was
    # measured that day and is 1220 by 720; these stay smaller on purpose, so a
    # crate never lands flush against a wall where it is awkward to reach.
    @editable
    ArenaHalfLength : float = 1050.0

    # The short axis, the three-tile one.
    @editable
    ArenaHalfWidth : float = 550.0

    # The floor the crate comes down to, matching DeathSaveManager's FloorHeight.
    @editable
    FloorHeight : float = 0.0

    # How often the Hype meter is checked for a tier change.
    @editable
    PollSeconds : float = 0.25

    # =================================================================
    # THE STREAM CHAT, and why the words live HERE
    #
    # GDD Section 4 gives the simulated audience the chat as well as the crate
    # parameters, and CLAUDE.md section 12 says the audience must stay a
    # swappable data source. So this file decides WHAT the crowd says and
    # StreamChatManager.verse decides how it is drawn. Replace this device with
    # one that says nothing and the chat goes quiet without a line of the widget
    # changing.
    #
    # THIS IS NOT ANNOUNCER DIALOGUE. CLAUDE.md section 0 rule 3 puts every line
    # the commentator says in Kai own hands. The crowd is not the commentator,
    # and these were drafted for Kai and approved by them on 2026-08-25.
    #
    # Rewrite any of it freely; the lists just get longer or shorter.
    # =================================================================

    ChatIdle : []string = array:
        "this guy again"
        "how much is he in for"
        "chat is this real"
        "RSM STUDIOS W"
        "first"
        "mods?"
        "KEKW"
        "who is this"
        "low viewer count arc"
        "brb toilet"
        "is he washed"
        "what's the debt at"
        "nobody has ever won this"
        "my uncle was on this show"
        "he's NPC coded"
        "stream's laggy"
        "hi chat"
        "lurking"
        "day 400 of watching people die"
        "unc is streaming again"
        "brainrot"
        "this is peak content"
        "6-7 viewers"
        "chat is yapping"
        "delulu"
        "nobody's beating the allegations"
        "aura check"
        "it's giving bankruptcy"
        "lurking with sound on"
        "low aura arc"

    ChatKill : []string = array:
        "W"
        "sheesh"
        "clip that"
        "actually insane"
        "he cooked THEM"
        "POGGERS"
        "one shot??"
        "EZ"
        "Clap"
        "cracked"
        "gigachad"
        "no shot"
        "get diffed"
        "deleted"
        "sent"
        "goodnight"
        "that's a highlight"
        "he's him"
        "+1000 aura"
        "GOATED"
        "he ATE"
        "standing on business"
        "no cap that was clean"
        "based"
        "he mogged him"
        "PepeLaugh"
        "OMEGALUL"
        "valid"
        "peak"
        "goated with the sauce"

    ChatMultiKill : []string = array:
        "1v9"
        "HOLY"
        "CHAT"
        "unreal"
        "aimbot fr"
        "they got diffed"
        "KEKW they folded"
        "rip bozos"
        "MULTI"
        "he's cooking"
        "nobody move"
        "frame that"
        "CHAT IS THIS REAL"
        "absolute unit"
        "AURA FARMING"
        "caught them in 4k"
        "he's got the rizz"
        "they're all NPCs"
        "sigma behaviour"
        "nah he's HIM"
        "OMEGALUL they folded"

    ChatDodge : []string = array:
        "ok wow"
        "buffered"
        "matrix"
        "touch grass fr"
        "SHEESH"
        "that was frame perfect"
        "lucky"
        "reaction diff"
        "nah that's cracked"
        "pixel perfect"
        "lag saved him"
        "aura"
        "+500 aura"
        "slippery"
        "no cap that was frames"
        "monkaS"
        "he's not real"

    ChatDamage : []string = array:
        "L"
        "L bozo"
        "LLLL"
        "skill issue"
        "KEKW"
        "unlucky"
        "take the L"
        "griefing"
        "sadge"
        "that's on you"
        "mid gameplay"
        "down bad"
        "get good"
        "uninstall"
        "my grandma dodges that"
        "washed"
        "that's a you problem"
        "yikes"
        "-1000 aura"
        "L + ratio"
        "bot behaviour"
        "malding"
        "WeirdChamp"
        "get real"
        "that's an ick"
        "cringe"
        "caught lacking"
        "he's yapping not dodging"
        "brother EW"
        "Sadge"
        "D:"

    ChatLowHealth : []string = array:
        "cooked"
        "he's cooked chat"
        "nooo"
        "SPONSOR HIM NOW"
        "F"
        "copium"
        "sadge"
        "pray"
        "one hit left LMAO"
        "call it"
        "he's done"
        "medic"
        "this is painful"
        "turn the stream off"
        "he's cooked no cap"
        "delulu if you think he lives"
        "copium refill"
        "monkaS"
        "call the ambulance"
        "-9999 aura"
        "it's giving funeral"

    ChatDeathSave : []string = array:
        "SOMEBODY SPONSOR HIM"
        "5 gifted if you can make it this round"
        "get up get up get up"
        "PLEASE"
        "hopium"
        "clutch or kick"
        "this is it chat"
        "10 gifted right now"
        "I'll sub if he lives"
        "CHAT PRAY"
        "not like this"
        "PRAYGE"
        "CHAT PLEASE"
        "20 gifted right now"
        "not the aura loss"
        "he's standing on business"
        "clutch time"
        "KEKW he's gone"

    ChatCrateFalling : []string = array:
        "PARACHUTE"
        "open it open it"
        "pls be machine gun"
        "thats a good one"
        "POG"
        "loot goblin time"
        "shoot it shoot it"
        "free real estate"
        "don't miss it"
        "LOOT"
        "PogU"
        "manifesting the machine gun"
        "bet"
        "it's giving Christmas"

    ChatCrateOpened : []string = array:
        "W drop"
        "mid loot"
        "KEKW that's it?"
        "actually good"
        "trash"
        "take it take it"
        "that's a downgrade"
        "GIGA DROP"
        "scam"
        "mid drop"
        "that's cap"
        "W drop no cap"
        "glazing this drop for no reason"

    ChatCash : []string = array:
        "cha-ching"
        "thats rent"
        "secure the bag"
        "number go up"
        "barely a dent"
        "he's rich"
        "minimum wage"
        "that's one payment"
        "fanum tax"
        "barely covers interest"
        "that's giving minimum wage"

    ChatWaveCleared : []string = array:
        "another one"
        "he's actually gonna do it"
        "tier check"
        "GG"
        "W round"
        "no way he survives the next one"
        "pace"
        "run it back"
        "sponsor arc"
        "GG no re"
        "he's cooking chat"
        "sponsor arc real"
        "aura restored"

    ChatHype : []string = array:
        "HE'S HEATING UP"
        "SUPERSTAR ARC"
        "ratings"
        "the algorithm loves this"
        "PogU"
        "viewers going up"
        "he's cooking chat"
        "main character"
        "THE AURA"
        "he's peaking"
        "ratings arc"
        "chat we're so back"
        "main character energy"

    ChatBackseat : []string = array:
        "use the wall"
        "behind you"
        "left LEFT"
        "shoot the crate"
        "stop running"
        "reload"
        "why is he standing there"
        "use the other gun"
        "stop yapping and shoot"
        "use the wall unc"
        "that's a skill issue"
        "reload bro"

    ChatBot : []string = array:
        "terms apply"
        "the Network is not liable"
        "void where prohibited"
        "results not typical"
        "this contestant waived all claims"
        "consult your physician"
        "reminder: sponsorships are non-refundable"
        "chat is monitored for tone"
        "that message has been logged"
        "moderation is automated and final"
        "this segment sponsored by GRIMLOCK CANNED MEAT"
        "prize values are estimates"
        "the toaster is not a guaranteed prize"
        "payment plans available to survivors"
        "no purchase necessary. no purchase possible."
        "your viewership constitutes consent"
        "silence is also consent"
        "the Network reserves the right to edit this broadcast"
        "the Network denies all of that"
        "please refrain from speculating about the contestant's outcome"
        "this contestant is not an employee, a guest, or a person of record"
        "clip removed at the Network's request"
        "do not attempt this at home. do not attempt this anywhere."
        "viewer discretion is not advised"
        "your enthusiasm has been recorded"
        "terms may change without notice"
        "please remain seated"
        "the Network thanks you for watching"
        "this is not a recording"

    ChatHandles : []string = array:
        "xX_ratioed"
        "m0m_2007"
        "tesatiord"
        "sludgedrinker"
        "DebtFree2088"
        "hype_or_die"
        "unc_watches"
        "toaster_enjoyer"
        "aura_farmer_04"
        "n0_cap_zone"
        "malding_irl"
        "chat_is_this_real"

    ChatBotHandle : string = "n3twork_bot"

    # GDD 4.2's SpawnCrateEvent, and the only thing this file offers the outside
    # world.
    SpawnCrateEvent : event(crate_order) = event(crate_order){}

    # The tier the player was in at the last check, so a climb can be told from
    # standing still. Starts at Underdog.
    var LastTier : int = 0

    OnBegin<override>()<suspends>:void =
        Log("DEBUG: Simulated Audience watching. Trickle every {TrickleSeconds}s, arena {ArenaHalfLength} by {ArenaHalfWidth} from centre.")
        # No crates ordered until PLAY is clicked. Amendment 70.
        #
        # THE OUTER LOOP IS THE RESTART, amendment 86. Both watches are raced
        # against AwaitRunEnd rather than launched with spawn, because a spawn
        # cannot be cancelled: without it the audience would keep ordering
        # crates through the game over card, and a second run would have two
        # trickles running at once.
        loop:
            AwaitMatchStart(Self)
            StartFreshRun()

            race:
                WatchForTierClimbs()
                RunTrickle()
                AwaitRunEnd(Self)

            Log("DEBUG: Audience packed up -- no more crates until the next run.")

    # Puts the audience back to how it stood before the first crate of a run.
    # Called at the top of every run, including the first, so one path serves
    # both. The remembered tier has to go back to Underdog or a fresh run that
    # starts at nothing would read as a fall rather than a climb, and the first
    # threshold crossed would order nothing.
    StartFreshRun():void =
        set LastTier = 0
        Log("DEBUG: fresh run -- audience back to Underdog, trickle clock restarted.")

    # Trigger 1. GDD 2.1 step 3, "crossing Hype thresholds".
    WatchForTierClimbs()<suspends>:void =
        loop:
            Sleep(PollSeconds)
            Current := TierForHype(HypeMeter.GetHype())
            if (Current > LastTier):
                Log("DEBUG: Hype climbed to {TierName(Current)}. Ordering a crate.")
                OrderCrate(Current)
            # Tracked downward too, so falling back and re-climbing orders another.
            set LastTier = Current

    # Trigger 2. The trickle, so the loop keeps turning between climbs.
    RunTrickle()<suspends>:void =
        loop:
            Sleep(TrickleSeconds)
            Tier := TierForHype(HypeMeter.GetHype())
            Log("DEBUG: Trickle due. Ordering a {TierName(Tier)} crate.")
            OrderCrate(Tier)

    # The handoff itself. Picks the spot, signals, and forgets.
    OrderCrate(Tier : int):void =
        Spot := RandomLandingSpot()
        Log("DEBUG: SpawnCrateEvent -- tier {Tier} ({TierName(Tier)}) at X={Spot.X} Y={Spot.Y} Z={Spot.Z}")
        SpawnCrateEvent.Signal(crate_order{Tier := Tier, LandingSpot := Spot})

    # Which tier a Hype reading falls in. Amendment 13's bands.
    TierForHype(Hype : float)<transacts>:int =
        if (Hype >= HypeMeter.GetPrimeTimeAt()):
            3
        else if (Hype >= HypeMeter.GetSuperstarAt()):
            2
        else if (Hype >= HypeMeter.GetRisingStarAt()):
            1
        else:
            0

    # A random point on the arena floor inside the rectangle this device sits in
    # the middle of. Even by construction: a flat random pick on each axis is
    # already spread evenly across a rectangle, which is why the circle's square
    # root correction is gone with it.
    RandomLandingSpot()<transacts>:vector3 =
        Centre := GetTransform().Translation
        vector3:
            X := Centre.X + GetRandomFloat(-ArenaHalfLength, ArenaHalfLength)
            Y := Centre.Y + GetRandomFloat(-ArenaHalfWidth, ArenaHalfWidth)
            Z := FloorHeight

    # For the log only.
    TierName(Tier : int)<transacts>:string =
        if (Tier >= 3):
            "Prime Time"
        else if (Tier = 2):
            "Superstar"
        else if (Tier = 1):
            "Rising Star"
        else:
            "Underdog"

    # =================================================================
    # WHAT THE CROWD SAYS, offered to the chat widget
    #
    # These three are the whole of the handoff. StreamChatManager asks for a
    # line and a handle and knows nothing about either list, which is what keeps
    # this device swappable per CLAUDE.md section 12.
    #
    # The kinds are plain numbers rather than an enum, so the widget can name a
    # moment without the two files having to share a type.
    # =================================================================

    ChatIdleKind<public> : int = 0
    ChatKillKind<public> : int = 1
    ChatMultiKillKind<public> : int = 2
    ChatDodgeKind<public> : int = 3
    ChatDamageKind<public> : int = 4
    ChatLowHealthKind<public> : int = 5
    ChatDeathSaveKind<public> : int = 6
    ChatCrateFallingKind<public> : int = 7
    ChatCrateOpenedKind<public> : int = 8
    ChatCashKind<public> : int = 9
    ChatWaveClearedKind<public> : int = 10
    ChatHypeKind<public> : int = 11
    ChatBackseatKind<public> : int = 12
    ChatBotKind<public> : int = 13

    ChatLineFor<public>(Kind : int)<transacts>:string =
        if (Kind = ChatKillKind):
            PickFrom(ChatKill)
        else if (Kind = ChatMultiKillKind):
            PickFrom(ChatMultiKill)
        else if (Kind = ChatDodgeKind):
            PickFrom(ChatDodge)
        else if (Kind = ChatDamageKind):
            PickFrom(ChatDamage)
        else if (Kind = ChatLowHealthKind):
            PickFrom(ChatLowHealth)
        else if (Kind = ChatDeathSaveKind):
            PickFrom(ChatDeathSave)
        else if (Kind = ChatCrateFallingKind):
            PickFrom(ChatCrateFalling)
        else if (Kind = ChatCrateOpenedKind):
            PickFrom(ChatCrateOpened)
        else if (Kind = ChatCashKind):
            PickFrom(ChatCash)
        else if (Kind = ChatWaveClearedKind):
            PickFrom(ChatWaveCleared)
        else if (Kind = ChatHypeKind):
            PickFrom(ChatHype)
        else if (Kind = ChatBackseatKind):
            PickFrom(ChatBackseat)
        else if (Kind = ChatBotKind):
            PickFrom(ChatBot)
        else:
            PickFrom(ChatIdle)

    # Who said it. The bot's lines always come from the bot.
    ChatHandleFor<public>(Kind : int)<transacts>:string =
        if (Kind = ChatBotKind):
            ChatBotHandle
        else:
            PickFrom(ChatHandles)

    # One line at random out of a list, or nothing at all if the list is empty.
    PickFrom(Lines : []string)<transacts>:string =
        Count := Lines.Length
        if (Count > 0):
            if (Line := Lines[GetRandomInt(0, Count - 1)]):
                return Line
        ""
