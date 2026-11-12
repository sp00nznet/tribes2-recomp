# Testing

There is no conformance harness yet (ROADMAP). The checks are headless runs,
on a private desktop that is never shown, muted, so they work over RDP and
never touch a screen.

1. **The bind.** `build\tribes2.exe` with no `--run`: expected
   `[bind] 0x00400000: ... 0 unresolved` (298 imports).
2. **The license screen.**
   `build\tribes2.exe --headless --run --watchdog 120 --shot 60 eula.bmp -- -nologin`
   writes `[shot] 800x600 -> eula.bmp`; the picture is the license text.
3. **Training 1.** Clicks through the license, warrior setup and the training
   menu (`--click X,Y@S`), then posted W presses (`--key 87@S`), with
   `--record t1.mp4 --watchdog 300`. Passes when the recording shows the drop
   and the HUD tutorial. `docs/screenshots/training1-contact.png` is one such
   run, a frame every 10 s.

`--watchdog S` ends a run and prints where the game was, so a hang reads as a
location rather than a timeout. `--conlog` in a `-DT2_TRACE=ON` build prints
the engine console, which is the first place to look when a script fails.
