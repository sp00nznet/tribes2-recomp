# Roadmap

## Next
- **Why Training 1 ends.** In the test run the mission returned to the
  training menu a few minutes in (posted W presses only; perhaps the
  tutorial's own failure, perhaps not). Check with a `--conlog` trace build.
- **Input for real play**: mouse look (the game reads window messages with
  DirectInput off), held keys rather than taps (`--key` taps for 150 ms).
- **The 6 `aam` sites** the lift leaves unimplemented.
- **Speed.** The generated C is built at `/Od`; the start-up script compile
  takes most of a minute. Try `/O2` (`-DPCRECOMP_GEN_OPT=ON`) once a mission runs.
- **A first installer release** (the launcher config and workflow exist; nothing is tagged).
- **Linux**: a Wine path for the Windows build, or the host on pcrecomp's win32hle.
- **A conformance harness** (REPO_RULES section 9): dry-run bind count, the
  license screen from `--shot`.
- **A farm build**: `netlab build tribes2-recomp` (recipe added, not run).
- **pcrecomp-tribes2 into pcrecomp main.**

## Later
- Online play: the WON servers are gone; community master servers speak a
  different protocol (TribesNext), out of scope for now.
