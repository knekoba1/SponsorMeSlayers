# PrizeVault.verse
#
# THE PRIZE VAULT. Fourteen consolation prizes the Network hands out instead of
# money, won from crates, kept between sessions, and shown on the title screen.
#
# WHERE IT COMES FROM. GDD 2.3 has hostiles bursting into "nostalgic household
# appliance props (retro TVs, toasters)". Kai's ruling of 2026-08-26 takes the
# appliances OUT of the kill drops, which become cash only, and makes them crate
# prizes instead. Amendment 79. The title screen already had a prize vault
# panel, but it was set dressing: five fixed rows, two of them lit. It becomes
# real here.
#
# THE NAMES ARE KAI'S TO WRITE AND ARE NOT WRITTEN HERE. Every slot ships with a
# plain placeholder that names the object and nothing more. The joke each prize
# tells is Kai's, in the same way announcer barks are, and no part of this file
# invents, redrafts or improves one. Fill PrizeNames in UEFN.
#
# WHY A LIST OF INDEXES AND NOT A ROW OF FLAGS. The save holds the index of each
# prize found. A row of flags would have to be the same length forever, and this
# list is expected to grow: Kai went from four prizes to fourteen inside one
# conversation. An index that is not in the list has not been found, and a save
# written before a prize existed is simply shorter than the list of prizes.
#
# ONE PRIZE PER CRATE, AND NEVER ONE ALREADY OWNED. A crate that rolls a prize
# asks this file to choose, and it chooses only from what is still missing. When
# the vault is full the crate falls back to its ordinary rewards, so a finished
# collection never costs the contestant a drop.

using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Random }
using { /Verse.org/Simulation }

prize_vault_manager := class(creative_device):

    # =================================================================
    # THE PRIZES
    # =================================================================

    # THE WORDING IS A PLACEHOLDER AND IS KAI'S TO REPLACE. These name the object
    # and make no joke, on purpose. Kai asked to write the gags themselves once
    # the props were in, so nothing here should be taken as final copy.
    #
    # THE ORDER IS THE SAVE FORMAT. A prize is remembered by its position in this
    # list, so ADD to the end and never reorder: shuffling these swaps what every
    # existing save believes it owns.
    @editable
    PrizeNames : []string = array:
        "CHROME TOASTER"
        "WOOD-PANEL CRT TELEVISION"
        "WASHING MACHINE"
        "REFRIGERATOR"
        "MICROWAVE"
        "BOOMBOX"
        "LIGHT LAMP"
        "OFFICE CHAIR"
        "TOILET PAPER"
        "TRIP TO HAWAII"
        "TRAFFIC CONE"
        "PORTA-POTTY"
        "COFFIN"
        "CARDBOARD BOX"

    # One prop per name, in the SAME ORDER. Filled in UEFN, because the prop
    # library only exists inside the editor. A slot left empty still counts as a
    # prize and still saves; it simply has nothing to show on the crate, and the
    # log says so once.
    @editable
    PrizeProps : []creative_prop_asset = array{}

    # How much to shrink or grow each prop, one number per prize in the same
    # order. The library's props are wildly different sizes, so a fridge and a
    # roll of toilet paper need very different numbers to read as prizes sitting
    # on a crate. A short list is allowed: anything it does not reach is 1.0.
    @editable
    PrizeScales : []float = array{}

    # =================================================================
    # WIRING
    # =================================================================

    # The cash drop manager, so winning a prize also pays. A crate that hands
    # over a novelty fridge and nothing else would read as a wasted drop.
    @editable
    CashDrops : cash_drop_manager = cash_drop_manager{}

    @editable
    PrizeCashValue : int = 250

    # The stinger for winning one. Point it at the cash pickup's ding to start
    # with; loudness lives on the placed device, never here.
    @editable
    PrizeSound : audio_player_device = audio_player_device{}

    @editable
    LogVault : logic = true

    # =================================================================
    # STATE
    # =================================================================

    # Which prize each tier's open crate has been promised, so the prop shown on
    # the crate and the prize actually handed over are one decision rather than
    # two rolls that can disagree. -1 is "none chosen".
    var PromisedTo : []int = array{-1, -1, -1, -1}

    OnBegin<override>()<suspends>:void =
        if (PrizeProps.Length < PrizeNames.Length):
            Log("WARNING: Prize vault -- {PrizeNames.Length} prizes named but only {PrizeProps.Length} prop(s) filled in. The rest will win nothing to look at. Fill PrizeProps in UEFN.")

        Log("DEBUG: Prize vault ready with {PrizeNames.Length} prizes.")

    # =================================================================
    # WHAT THE CRATE ASKS
    # =================================================================

    # Is there anything left to win? The crate asks before it rolls, so a full
    # vault never costs the contestant a drop.
    HasPrizeLeft<public>(P : player)<transacts>:logic =
        Missing := MissingFor(P)
        if (Missing.Length > 0):
            return true
        false

    # Choose one for this tier's crate, from what is still missing, and remember
    # it. Called when the crate breaks open, not when it is picked up, so what
    # is shown and what is handed over are the same object.
    ChooseFor<public>(Tier : int, P : player):void =
        Missing := MissingFor(P)

        if (Missing.Length > 0, Pick := Missing[GetRandomInt(0, Missing.Length - 1)]):
            Remember(Tier, Pick)
            if (LogVault?):
                Log("DEBUG: Prize vault -- tier {Tier}'s crate is holding {NameOf(Pick)}.")
        else:
            Remember(Tier, -1)
            Log("WARNING: Prize vault -- tier {Tier}'s crate rolled a prize with nothing left to win.")

    # The prop to stand on the opened crate, if there is one.
    PropFor<public>(Tier : int)<transacts>:?creative_prop_asset =
        if (Index := PromisedTo[Tier], Index >= 0, Asset := PrizeProps[Index]):
            return option{Asset}
        false

    ScaleFor<public>(Tier : int)<transacts>:float =
        if (Index := PromisedTo[Tier], Index >= 0, Scale := PrizeScales[Index]):
            return Scale
        1.0

    # The contestant walked into the crate. The prize is theirs.
    Claim<public>(Tier : int, P : player):void =
        if (Index := PromisedTo[Tier], Index >= 0):
            Add(P, Index)
            PrizeSound.Play()
            CashDrops.AddPrizeMoney(PrizeCashValue)
            Log("PRIZE WON -- {NameOf(Index)}. The vault now holds {FoundFor(P).Length} of {PrizeNames.Length}.")
            Remember(Tier, -1)
        else:
            Log("WARNING: Prize vault -- tier {Tier} was claimed with no prize promised.")

    # =================================================================
    # THE SAVE
    #
    # The record itself belongs to CareerRankManager.verse, which owns the one
    # weak_map UEFN persists. This file only ever touches PrizesFound, and reads
    # the whole record and writes the whole record back so nothing else in it is
    # lost. Every read and write is guarded by IsActive, because the digest is
    # explicit that using an inactive player as a key is a runtime error.
    # =================================================================

    FoundFor<public>(P : player)<transacts>:[]int =
        if (P.IsActive[], Record := CareerRecords[P]):
            return Record.PrizesFound
        array{}

    HasFound<public>(P : player, Index : int)<transacts>:logic =
        for (Owned : FoundFor(P), Owned = Index):
            return true
        false

    MissingFor(P : player)<transacts>:[]int =
        var Missing : []int = array{}
        for (Index -> Name : PrizeNames):
            if (not HasFound(P, Index)?):
                set Missing += array{Index}
        Missing

    Add(P : player, Index : int):void =
        if (HasFound(P, Index)?):
            return

        if (P.IsActive[], Record := CareerRecords[P]):
            Grown := Record.PrizesFound + array{Index}
            if (set CareerRecords[P] = career_record:
                    BestScore := Record.BestScore
                    BestTier := Record.BestTier
                    RankIndex := Record.RankIndex
                    LifetimeBankroll := Record.LifetimeBankroll
                    JustPromoted := Record.JustPromoted
                    DebtDelta := Record.DebtDelta
                    PrizesFound := Grown
            ):
                Log("DEBUG: Prize vault saved. {Grown.Length} prize(s) held.")
            else:
                Log("WARNING: Prize vault -- the save refused the new prize.")
        else:
            Log("WARNING: Prize vault -- no record to save into, so {NameOf(Index)} was not kept.")

    # =================================================================
    # SMALL THINGS
    # =================================================================

    NameOf<public>(Index : int)<transacts>:string =
        if (Name := PrizeNames[Index]):
            return Name
        "UNNAMED PRIZE"

    Remember(Tier : int, Index : int):void =
        var Rebuilt : []int = array{}
        for (Slot -> Existing : PromisedTo):
            if (Slot = Tier):
                set Rebuilt += array{Index}
            else:
                set Rebuilt += array{Existing}
        set PromisedTo = Rebuilt
