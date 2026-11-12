# Bring-up notes

What Tribes 2 needed, in the order it turned up. Each item says where the fix
lives: in this repository's host (`src/runtime/host.c`), or in pcrecomp
(branch `pcrecomp-tribes2`, based on `pcrecomp-stp`) when another game would
hit it too.

## The copy of the game

`Tribes 2 (USA).zip` is a raw CD image (`.bin/.cue`, one MODE1/2352 track).
Its 2048-byte user data is an ISO 9660 volume that 7-Zip opens. The disc holds
an InstallShield setup, DirectX 8, GLSetup, two demos and, in
`Tribes2\GameData`, the game itself uninstalled: `Tribes2.exe`, the Miles and
Immersion DLLs, `base\*.vl2` (zip volumes) and the start-up script
`console_start.cs`. That folder is copied as `game\`; no installer runs.

DRM: no SafeDisc/SecuROM/StarForce section or driver. Offline play runs
`VerifyCDCheck` (`scripts/server.cs`): the engine's `cdFileCheck` walks the
drives for a CD-ROM (`GetDriveTypeA` 5) whose volume label is the disc's
(`T2 INSTALL`) and which holds a file of it. Nothing is patched: the image
is mounted. The `.bin` is converted to an `.iso` (the 2048 user bytes of
each 2352-byte sector) and Windows mounts it as a CD-ROM drive
(Explorer's *Mount*, or `Mount-DiskImage`). The CD key is for the online
account, which needs the Sierra/WON servers that are long gone. Run offline:
`-- -nologin`.

**SecuROM, at mission start.** The game folder also holds `glon32.dr7`, a
PE with SecuROM 4's `.cms_t`/`.cms_d` sections (no kernel driver). When the
local client connection reaches state 3 (in the mission, ghosting), the
engine (`0x005DFF40`) checks the online login (`0x006CB4C0`), and offline it
reads `GLON32.DR7` (`0x00552F20`) and runs its check; when that fails it
posts a quit event 10 seconds later (`0x005E0F50` -> `PostQuitMessage`).
That code is not lifted and nothing here runs it or patches around it, so
with the CD build every mission ends 10 seconds after it starts.

The way past it is the official one: Sierra's last patch, 25034, and the free
release of Tribes 2 built on it (2004), which drop the disc requirement. It is
not on the CD and has to be downloaded (fan archives such as TribesNext's
carry the original installer); lifting that `Tribes2.exe` is what this repository now does.

## The 25034 build

`tribes2gsi.exe` (539 MB, `depot.tribes2.net/legacy/`, linked by TribesNext
as the full base game) is a Wise installer, not Inno. innoextract and 7-Zip
refuse it. Its overlay (from 0x3A00) is a run of raw DEFLATE streams, each
followed by a CRC32. The first is the installer's script, which lists the
`%MAINDIR%` paths in order; file N of that list is stream N+8. Walked and
named without running anything. Its `Tribes2.exe` (PE stamp 1036016517)
imports `IFC22` instead of `IFC21`, has no `GLON32` reference, and its
console printer moved to `0x00425D30`.

The card profile's full-screen switch: accepting `ChangeDisplaySettingsA`
without changing the mode gave a desktop-sized popup with the 800x600 frame
in a corner. The host now refuses the change, and the engine stays in its
800x600 window.

## Lifting

One module, `Tribes2.exe`, base `0x00400000`, relocations present. Built with
**Metrowerks CodeWarrior** (the `.exc` section, the CW runtime), so there is
no MSVC RTTI and `rtti.py` finds nothing.

- **Virtual methods.** A method only ever called through its vtable is in no
  `call`; Torque's per-class `getClassRep` (`0x00646E70`) was not lifted, and
  the call through it returned 0, so loading `PlayGui.gui` faulted on a NULL
  class. `tools/catalog.py` seeds `disasm32.py` with the relocation table's
  targets in `.text` that are 16-byte aligned, follow padding or a `ret`, and
  are no jump-table arm. 24,881 functions, 96.6% of `.text`.

- **fbld / fbstp / fxtract** were not implemented. CodeWarrior's strtod
  (`__dec2num`, `0x006D6550`) loads its digit string as packed BCD with
  `fbld`; lifted as nothing, every `atof` returned 0. Torque's `dAtob("1")`
  is `atof(s) != 0`, so every boolean pref read as false, and
  `$pref::Video::allowOpenGL` false made the engine drop OpenGL for the
  Direct3D wrapper (`OpenGL2D3D.dll`). Fixed in pcrecomp (`lift32.py`,
  `fp_bcd_ld`/`fp_bcd_st` in `recomp_types.h`).
- **Jump tables in `.data`.** CodeWarrior keeps switch tables in the data
  section; the extent walk only read tables inside `.text`, so the switch
  arms were left out of their function and lifted as alias entries that
  jumped back in through the dispatcher. The scanf engine (`0x006D0EF0`)
  then took one host stack frame per character it scanned and overflowed the
  16 MB stack on the first long string. Fixed in pcrecomp (`generate.py`
  `_jump_table(read=)`, `drive32.py` passes the image reader).

## Host

- **Command line.** `GetCommandLineA` is shimmed: the guest sees
  `Tribes2.exe` and whatever follows `--` on the host's command line.
- **OpenGL.** Torque loads `opengl32.dll` itself and looks everything up with
  `GetProcAddress`. `native32_redirect` only covered imports; pcrecomp's
  modules32 `GetProcAddress` shim now answers redirects too, which is how
  the host gets `wglSwapBuffers` (frames for `--shot`/`--record`, read back
  with `glReadPixels`) and `ChangeDisplaySettingsA`.
- **Full screen.** The GeForce card profile (`GeForce.cs`) turns full screen
  on whatever `-w` says. `ChangeDisplaySettingsA` is accepted and not made,
  so "full screen" is a popup window of the same size, which also works on
  the private desktop of `--headless`. `--fullscreen` lets it through.
- **The console.** `--conlog` (a `-DT2_TRACE=ON` build) prints every
  `Con::_printf` (`0x004218D0`) through pcrecomp's `recomp_trace_extra` hook;
  the guest's `va_list` is the host's on x86. `setLogMode` and
  `enableWinConsole` are compiled out of the retail build.

## Speed

The generated C at `/Od`: the start-up scripts compile and the license screen
comes up in about 25 seconds.
