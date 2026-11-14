# One-click setup for the Tribes 2 static recompilation. Run it by
# double-clicking Setup.cmd; docs/building.md is the same thing by hand,
# command for command.
#
# It checks the tools, fetches pcrecomp (main), copies your Tribes 2 25034
# GameData folder into game\, builds the function catalog, lifts it to C,
# builds build\tribes2.exe and leaves "Tribes 2 (recomp).cmd". Each step is
# skipped when its output already exists (-Force redoes them). Everything goes
# to setup.log. -Yes installs what is missing without asking; -Game is the
# GameData folder. RECOMP_LAUNCHER=1 skips the "Press Enter" at the end.
param([switch]$Force, [switch]$Yes, [Alias('GameDir')][string]$Game = "")

$ErrorActionPreference = 'Stop'
$Branch = 'main'
$Stamp = 1036016517   # Tribes2.exe 25034's PE timestamp: the build the host's addresses are for
$Root = Split-Path -Parent $PSScriptRoot
$Toolkit = if ($env:PCRECOMP) { $env:PCRECOMP } else { Join-Path (Split-Path -Parent $Root) 'pcrecomp' }
$T = Join-Path $Toolkit 'tools'
$Log = Join-Path $Root 'setup.log'
$Steps = 6
Set-Location $Root
function Log($t) { try { Add-Content -Path $Log -Value $t -Encoding UTF8 -ErrorAction Stop } catch {} }
Log "==== setup $(Get-Date -Format s)"
function Say($t, $c = 'Gray') { Write-Host $t -ForegroundColor $c; Log $t }
function Pause-End { if (-not $env:RECOMP_LAUNCHER) { Read-Host "Press Enter to close" | Out-Null } }
function Step($n, $t) { Write-Host ""; Say "[$n/$Steps] $t" 'Cyan' }
function Fail($t) {
  Say ""; Say "Setup stopped: $t" 'Red'
  Say "The details are in $Log. Fix that and run Setup.cmd again; finished steps are skipped." 'Yellow'
  Pause-End; exit 1
}
# cmd.exe, which the build runs through, splits a path at '&'.
if ($Root -match '&') { Fail "this folder's path has an '&' in it, which the build cannot handle. Move the folder (for example to C:\tribes2-recomp)." }
function Ask($q) { if ($Yes) { Say "$q yes"; return $true }; $a = Read-Host "$q [Y/n]"; return -not ($a -match '^[nN]') }
function Refresh-Path { $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User') }
# Windows PowerShell turns a native program's stderr into errors, so 'Stop' is off while it runs.
function Exec([string[]]$cmd) {
  $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  $rest = @($cmd | Select-Object -Skip 1)
  & $cmd[0] @rest 2>&1 | ForEach-Object { Log "$_" }
  $code = $LASTEXITCODE
  $ErrorActionPreference = $old
  return $code
}
function Run($what, [string[]]$cmd) { Say "  $what..."; $code = Exec $cmd; if ($code -ne 0) { Fail "$what failed (exit code $code)." } }

Say "Tribes 2 - static recompilation setup" 'White'
Say "You need Tribes 2 25034 (Sierra's free release, tribes2gsi.exe, installed) and about 3 GB free."
Say "The catalog, the lift and the build take 20 to 40 minutes, once."

# ---------------------------------------------------------------- tools
Step 1 "Checking the tools"
function Find-Python {
  foreach ($c in @(@('py', '-3'), @('python'), @('python3'))) {
    if (-not (Get-Command $c[0] -ErrorAction SilentlyContinue)) { continue }
    $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    $rest = @($c | Select-Object -Skip 1)
    $v = (& $c[0] @rest --version 2>&1 | Out-String).Trim()
    $ErrorActionPreference = $old
    if ($v -match '^Python 3\.(\d+)' -and [int]$Matches[1] -ge 10) { return ,$c }
  }
  return $null
}
$pyargs = Find-Python
if (-not $pyargs) {
  if (-not (Ask "  Python 3.10+ is missing. Install Python 3.12 now (winget, for your user only, about 30 MB)?")) { Fail "Python 3 is required." }
  Exec @('winget', 'install', '-e', '--id', 'Python.Python.3.12', '--scope', 'user', '--accept-package-agreements', '--accept-source-agreements') | Out-Null
  Refresh-Path; $pyargs = Find-Python
  if (-not $pyargs) { Fail "Python installed, but Windows has not picked it up yet: close this window and run Setup.cmd again." }
}
Say "  Python: $($pyargs -join ' ')"
if ((Exec ($pyargs + @('-c', 'import pefile, capstone'))) -ne 0) {
  if (-not (Ask "  Install the Python packages pefile and capstone (pip, about 15 MB)?")) { Fail "pefile and capstone are required." }
  Run "Installing pefile and capstone" ($pyargs + @('-m', 'pip', 'install', '--user', 'pefile', 'capstone'))
}

if (-not (Test-Path (Join-Path $T 'lift\drive32.py'))) {
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Fail "git is needed to fetch pcrecomp. Install Git for Windows, then run Setup.cmd again." }
  if (-not (Ask "  Download the pcrecomp toolkit ($Branch branch) into $Toolkit (git, about 20 MB)?")) { Fail "pcrecomp is required at $Toolkit." }
  Run "Cloning pcrecomp" @('git', 'clone', '--depth', '1', '-b', $Branch, 'https://github.com/sp00nznet/pcrecomp', $Toolkit)
}
# The lifter needs fbld/fbstp (CodeWarrior's strtod), which an older main lacks.
if (-not (Select-String -Quiet -SimpleMatch 'fp_bcd_ld' (Join-Path $Toolkit 'runtime\recomp32\recomp_types.h'))) {
  Fail "pcrecomp at $Toolkit is older than ${Branch}: git -C `"$Toolkit`" checkout $Branch, then git -C `"$Toolkit`" pull"
}
Say "  pcrecomp: $Toolkit"

$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
function Find-VS { if (Test-Path $vswhere) { & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath } }
$vs = Find-VS
if (-not $vs) {
  if (-not (Ask "  Install the Visual Studio 2022 Build Tools with the C++ workload (winget, about 3 GB, asks for admin)?")) { Fail "Visual Studio 2022 (or its Build Tools) with 'Desktop development with C++' is needed." }
  Exec @('winget', 'install', '-e', '--id', 'Microsoft.VisualStudio.2022.BuildTools', '--accept-package-agreements', '--accept-source-agreements',
         '--override', '--quiet --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended') | Out-Null
  $vs = Find-VS
  if (-not $vs) { Fail "the Visual Studio Build Tools did not install." }
}
Say "  Visual Studio: $vs"
foreach ($tool in @(@('cmake', 'Kitware.CMake', '30 MB'), @('ninja', 'Ninja-build.Ninja', '1 MB'))) {
  if (Get-Command $tool[0] -ErrorAction SilentlyContinue) { continue }
  if (-not (Ask "  Install $($tool[0]) now (winget, about $($tool[2]))?")) { Fail "$($tool[0]) is required." }
  Exec @('winget', 'install', '-e', '--id', $tool[1], '--accept-package-agreements', '--accept-source-agreements') | Out-Null
  Refresh-Path
  if (-not (Get-Command $tool[0] -ErrorAction SilentlyContinue)) { Fail "$($tool[0]) installed, but Windows has not picked it up yet: close this window and run Setup.cmd again." }
}

# ---------------------------------------------------------------- the game
Step 2 "Copying your Tribes 2 GameData into game\"
function Is-Install([string]$d) { return ($d -and (Test-Path (Join-Path $d 'Tribes2.exe')) -and (Test-Path (Join-Path $d 'base'))) }
if ((Is-Install 'game') -and -not $Force) { Say "  Already in game\ (skipping)." }
else {
  $Game = $Game.Trim('"', ' ')
  if (-not (Is-Install $Game)) {
    foreach ($d in @("${env:ProgramFiles(x86)}\Sierra\Tribes2\GameData", 'C:\Dynamix\Tribes2\GameData', 'C:\Sierra\Tribes2\GameData')) {
      if (Is-Install $d) { $Game = $d; Say "  Found it: $d"; break }
    }
  }
  if (-not (Is-Install $Game) -and $Yes) { Fail "Tribes 2 was not found. Give its GameData folder with -Game." }
  while (-not (Is-Install $Game)) {
    $Game = (Read-Host "  Paste your Tribes 2 GameData folder (the one with Tribes2.exe and base\)").Trim('"', ' ')
    if (-not (Is-Install $Game)) { Say "  No Tribes2.exe and base\ in that folder." 'Yellow' }
  }
  Say "  Copying $Game..."
  # /XD: this folder may be inside the install, and would copy into itself.
  $code = Exec @('robocopy', $Game, (Join-Path $Root 'game'), '/E', '/NFL', '/NDL', '/NJH', '/NP', '/XD', $Root)
  if ($code -ge 8) { Fail "copying the game failed (robocopy exit code $code)." }   # robocopy: <8 is success
}
$check = "import pefile,sys; sys.exit(0 if pefile.PE(r'game\Tribes2.exe',fast_load=True).FILE_HEADER.TimeDateStamp==$Stamp else 1)"
if ((Exec ($pyargs + @('-c', $check))) -ne 0) {
  Fail "game\Tribes2.exe is not the 25034 build (the 2001 CD build lifts, but quits 10 s into every mission). Install tribes2gsi.exe and give its GameData."
}

# ---------------------------------------------------------------- catalog, lift, build
$env:PCRECOMP = $Toolkit
Step 3 "Finding every function (about 10 minutes, once)"
if ((Test-Path 'work\t2.functions.json') -and -not $Force) { Say "  Already done (skipping)." }
else { Run "Cataloging" ($pyargs + @('tools\catalog.py', '--force')) }

Step 4 "Lifting to C (about 5 minutes)"
if ((Test-Path 'src\recomp\gen\recomp_dispatch.c') -and -not $Force) { Say "  Already done (skipping)." }
else { Run "Lifting" ($pyargs + @('run_lift.py')) }

Step 5 "Building build\tribes2.exe (10 to 20 minutes)"
# Always: the build only compiles what changed, so a pulled host fix reaches the exe.
if ($Force -and (Test-Path 'build')) { Remove-Item -Recurse -Force 'build' }
$env:CMAKE_ARGS = "-DPCRECOMP=$($Toolkit -replace '\\','/')"
Run "Compiling" @('cmd', '/c', ('call "' + (Join-Path $Root 'build.cmd') + '"'))

Step 6 "Making the shortcut"
$lnk = Join-Path $Root 'Tribes 2 (recomp).cmd'
Set-Content -Path $lnk -Encoding ASCII -Value @('@echo off', 'rem Plays the recompiled game, offline (the WON servers are gone).', 'cd /d "%~dp0"', 'start "" build\tribes2.exe --run -- -nologin')
Say "  $lnk"
Write-Host ""
Say "Done. Double-click 'Tribes 2 (recomp).cmd' to play." 'Green'
Pause-End
