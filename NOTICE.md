# Notice

The MIT license in [LICENSE](LICENSE) covers what is ours in this repository:
the host (`src/runtime/host.c`), the lift and catalog drivers, the setup
scripts, the tools and the documentation. It does not cover the game.

*Tribes 2* is © 2001 Dynamix / Sierra, and its Torque engine is © GarageGames /
Dynamix. Neither is ours to license. Its executable, DLLs, volumes, scripts and
art are not in this repository and are excluded by `.gitignore`. The 2004 free
release made the game free to download, not free to redistribute here.

- You need your own copy of the game (Sierra's free 25034 release) to use any
  of this. Setup copies its `GameData` folder into `game/`; the pipeline reads
  it from there.
- Lifted code is a derivative work of the binary it came from. Anything the
  pipeline writes into `work/` or `src/recomp/gen*/` carries whatever license
  the original carries, not this one. The MIT grant stops at our own work.

The host is built on [pcrecomp](https://github.com/sp00nznet/pcrecomp)'s
`native32` runtime (MIT), fetched beside this repository, not copied into it.
There is no third-party code in this repository.
