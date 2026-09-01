# CheckMyProject.ps1
#
# Kai's safety net, built 2026-08-31 after 24 Verse scripts were moved out
# of Content while UEFN was running and the project stopped compiling.
#
# What it does: reports any file that has vanished from the project and
# puts it back. It only ever restores files that are GONE. It never
# overwrites a file you have edited, so it cannot lose work in progress.

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot
Set-Location $ProjectRoot

function Say($Text, $Colour) {
    if ($Colour) { Write-Host $Text -ForegroundColor $Colour }
    else { Write-Host $Text }
}

function Finish($Code) {
    Say ""
    [void](Read-Host "Press Enter to close this window")
    exit $Code
}

Say ""
Say "=======================================================" Cyan
Say "   Sponsor Me, Slayers!   -   Check My Project" Cyan
Say "=======================================================" Cyan
Say ""

# --- Can I reach the safety copy? --------------------------------------

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Say "PROBLEM: I cannot find Git on this computer." Red
    Say "Git is what holds the safety copy of your project, so without it"
    Say "I have nothing to restore from. Show Claude this message."
    Finish 1
}

if (-not (Test-Path (Join-Path $ProjectRoot ".git"))) {
    Say "PROBLEM: this is not your project folder." Red
    Say "This file needs to sit in C:\GameDev\SponsorMeSlayers_v2."
    Say "Show Claude this message."
    Finish 1
}

# --- What is here, and what is not? ------------------------------------

$Scripts = @(Get-ChildItem -Path (Join-Path $ProjectRoot "Content") -Filter *.verse -ErrorAction SilentlyContinue)
$Missing = @(git ls-files --deleted)
$Edited  = @(git diff --name-only --diff-filter=M)

Say ("Your Content folder currently holds " + $Scripts.Count + " game scripts.")
Say ""

if ($Missing.Count -eq 0) {
    Say "GOOD NEWS: nothing is missing. Your project is complete." Green
}
else {
    Say ("FOUND A PROBLEM: " + $Missing.Count + " file(s) have gone missing:") Yellow
    Say ""
    foreach ($File in $Missing) { Say ("      " + $File) }
    Say ""
    Say "That is what stops your game opening. Missing scripts get called by"
    Say "the scripts that are still here, and the game gives up looking."
    Say ""

    # Putting files back underneath a running UEFN is exactly what caused
    # the mess this script exists to prevent. Refuse, do not risk it.
    $Uefn = @(Get-Process -Name "UnrealEditorFortnite*" -ErrorAction SilentlyContinue)
    if ($Uefn.Count -gt 0) {
        Say "STOP: UEFN is open right now." Yellow
        Say ""
        Say "Putting files back while UEFN is running is what caused the"
        Say "trouble in the first place. It keeps its own list of your files"
        Say "and will not notice the new ones."
        Say ""
        Say "Close UEFN completely, then run this again." Cyan
        Finish 0
    }

    Say "Putting them back now..." Cyan
    foreach ($File in $Missing) {
        git checkout -- $File
    }

    $Remaining = @(git ls-files --deleted)
    if ($Remaining.Count -eq 0) {
        Say ""
        Say "DONE. Every missing file is back where it belongs." Green
        Say "Open UEFN and your project should build cleanly."
    }
    else {
        Say ""
        Say "I could not put these back:" Red
        foreach ($File in $Remaining) { Say ("      " + $File) }
        Say "Show Claude this message."
        Finish 1
    }
}

# --- Anything changed that Kai might not have changed on purpose? ------

if ($Edited.Count -gt 0) {
    Say ""
    Say "Also worth a look. These files have been edited since your last save:" Yellow
    Say ""
    foreach ($File in $Edited) { Say ("      " + $File) }
    Say ""
    Say "I have not touched any of them. If one of those is a surprise to"
    Say "you, mention it to Claude, because settings can drift on their own."
}

Finish 0
