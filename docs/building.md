# Building by hand

`Setup.cmd` runs exactly these steps (`tools/setup.ps1`).

Prerequisites: Windows 10/11, **Python 3.10+** with `pefile` and `capstone`,
**Visual Studio 2022** (or its Build Tools) with *Desktop development with
C++*, CMake and Ninja, ffmpeg on `PATH` for `--record` only, and pcrecomp
cloned **beside** this repository (`main`):

```
some-folder\
  pcrecomp\         <- git clone https://github.com/sp00nznet/pcrecomp
  tribes2-recomp\   <- this repository
```

`PCRECOMP` (Python) and `-DPCRECOMP=` (CMake, through `set CMAKE_ARGS=...`)
point at a toolkit checkout somewhere else. The lifter and the runtime header
must come from the same tree.

1. `py -3 -m pip install --user pefile capstone`
2. `xcopy /e /i X:\Tribes2\GameData game` (or `mklink /J game <your GameData>`).
   It must be 25034: `Tribes2.exe`'s PE timestamp is 1036016517.
3. `py -3 tools\catalog.py` (about 10 minutes). Expected:
   `[*] Functions: 26042 ...`
4. `py -3 run_lift.py` (about 5 minutes). Expected:
   `26042 functions in the dispatch table, lift errors 0`.
5. `build.cmd`. The generated C builds at `/Od` (`-DPCRECOMP_GEN_OPT=ON` for
   `/O2`). `build.cmd` uses the 64-bit-hosted x86 compiler: the 32-bit
   `cl.exe` runs out of heap on a 400-function chunk (C1002).
6. `build\tribes2.exe` (no `--run`) maps and binds, then stops. Expected:
   `[bind] 0x00400000: ... 0 unresolved`.
7. `build\tribes2.exe --run -- -nologin` plays.

On the farm: `netlab build tribes2-recomp` (the recipe exists; it has not been
run yet).

## The command line

```
build\tribes2.exe --run -- -nologin
build\tribes2.exe --headless --run --watchdog 300 --shot 60 eula.bmp --click 500,442@60 -- -nologin
```

| Flag | |
|---|---|
| `--run` | enter the game (without it: map, bind and stop) |
| `-- ARGS` | the game's own command line (`-nologin`, `-mission`, `-w`, ...) |
| `--headless` | a private desktop that is never shown (works over RDP); muted unless `PCRECOMP_MUTE=0` |
| `--mute` | mute the audio session |
| `--shot S FILE.bmp` | the frame presented at S seconds (up to 16) |
| `--record FILE.mp4` | every presented frame to ffmpeg |
| `--click X,Y@S`, `--key VK@S` | input at S seconds, posted to the game window |
| `--fullscreen` | let the game change the display mode (by default the change is refused and the game runs in a window) |
| `--watchdog S` | stop after S seconds and say where the game was |
| `--conlog` | the engine console on stdout (a `-DT2_TRACE=ON` build) |
| `--game DIR` | the game folder (default `game`) |
| `--native-trace`, `--callbacks` | one line per call into Windows, or back from it |

## Linux and macOS

Not yet. The host is `native32`, which is MSVC x86 inline assembly; no Wine or
cross-compile path has been tried, so `setup.sh` says so and exits.
