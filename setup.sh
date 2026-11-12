#!/bin/sh
# No Linux or macOS build of Tribes 2 yet: the host is pcrecomp native32,
# MSVC x86 inline assembly, and no Wine or cross-compile path has been tried.
echo "The Tribes 2 recomp builds on Windows only for now: run Setup.cmd there." >&2
echo "A Linux path (Wine, or pcrecomp's win32hle) is on the ROADMAP." >&2
exit 1
