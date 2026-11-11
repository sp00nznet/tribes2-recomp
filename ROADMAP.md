# Roadmap

## Next
- **Lift the 25034 build.** Training 1 loads and the client enters it, but the
  CD build's SecuROM check (`glon32.dr7`) ends every mission after 10 seconds
  ([docs/bringup.md](docs/bringup.md)). Sierra's last patch / 2004 free
  release (25034) has no disc check: download it, point `game\` at it, and
  re-run catalog, lift and build (addresses in the host's `--conlog` hook
  will move).
- **Speed.** The generated C is built at `/Od`; the start-up script compile
  takes most of a minute. Try `/O2` (`-DPCRECOMP_GEN_OPT=ON`) once a mission runs.
- **Setup.cmd and the launcher**, as in the other triage recomps.
- **A conformance harness** (REPO_RULES section 9): dry-run bind count, the
  licence screen from `--shot`.
- **A farm build**: `netlab build tribes2-recomp` (recipe added, not run).
- **pcrecomp-tribes2 into pcrecomp main.**

## Later
- Online play: the WON servers are gone; community master servers speak a
  different protocol (TribesNext), out of scope for now.
