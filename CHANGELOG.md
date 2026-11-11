# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[SemVer](https://semver.org/).

## [Unreleased]

### Added
- First boot of Tribes 2 (US retail CD, March 2001) on pcrecomp `native32`:
  `Tribes2.exe` lifted whole, 0 lift errors, no IDA. CodeWarrior build: the
  catalog seeds its virtual methods from relocated code pointers
  (`tools/catalog.py`).
- The engine runs in recompiled code: volumes, TorqueScript compile and
  execution, prefs, card profiles, the OpenGL device on the real driver,
  the licence screen and the full GUI load after it.
- `--headless`, `--shot S FILE.bmp` and `--record FILE.mp4` from the GL back
  buffer (`wglSwapBuffers` redirected), `--click X,Y@S` / `--key VK@S`,
  `--conlog` (the engine console, in a `-DT2_TRACE=ON` build), `--fullscreen`,
  and `-- ARGS` for the game's own command line.
- The front end answers posted clicks: licence, CD check (a mounted image),
  warrior setup, the training menu; Training 1 loads and the client enters
  it, until the CD build's SecuROM check quits the game 10 seconds later.
- Lifted build is now 25034 (Sierra's free release, unpacked from its Wise
  installer): no disc check. Training 1 runs in game: the drop, the HUD
  tutorial, movement from posted keys. Host: the console hook follows the
  new `Con::_printf` (0x00425D30); a refused mode change keeps the game in
  an 800x600 window.
