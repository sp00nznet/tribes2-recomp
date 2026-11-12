# Contributing

Issues and pull requests are welcome.

## The one rule

**Nothing from the game goes in the repository.** No game files (`game/`,
`game-cd/`, `.vl2`, `.cs`, `.dso`), no lifted C (`src/recomp/gen/`), no
catalog or seed dumps (`work/`), no disassembly listings, nothing generated
from `Tribes2.exe`. The tool ships; its output is made on each person's machine
from their own copy. `.gitignore` covers the usual paths; check `git status`
before you commit anyway. Screenshots of the game running are fine.

## Before a pull request

1. Build from a clean lift: `py -3 tools\catalog.py --force`, `py -3 run_lift.py`
   (expected: `lift errors 0`), then `build.cmd`.
2. Run the headless checks in [docs/testing.md](docs/testing.md): the bind
   (`0 unresolved`), the license screen, and Training 1 in game. A new
   behavior comes with the run that shows it.

## Where a fix belongs

- A bug in the lifter, the catalog or the native bridge belongs in
  [pcrecomp](https://github.com/sp00nznet/pcrecomp), on a branch with its own
  PR (this game's toolkit work is on `pcrecomp-tribes2` until it merges).
- A host-side shim or hook for this game goes in `src/runtime/host.c`, with a
  comment that says what it fixes and why.
- A wall you got past goes in `docs/bringup.md`: what it looked like, what it
  was, what moved it.

## Where your code comes from

Contributions must be original or MIT-compatible. Don't port code from GPL
projects (Wine, DOSBox, emulators) or from TribesNext's client patch.
