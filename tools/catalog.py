#!/usr/bin/env python3
"""The function catalog for Tribes2.exe, with pcrecomp's own disassembler.

Tribes2.exe is a CodeWarrior build: no MSVC RTTI, so rtti.py finds no
vtables. Its virtual methods are found instead from the relocation table:
a relocated dword outside .text that points into .text is a vtable slot, a
callback or a jump-table arm. The seeds are those targets that are 16-byte
aligned (CodeWarrior's function alignment), follow padding or a ret, and are
no arm of a `jmp [reg*4 + table]`. A method only ever called through its
vtable (Torque's getClassRep, 0x00646E70) is otherwise never lifted, and the
call through it returns nothing.

About ten minutes; skipped when the catalog exists (--force redoes it).

    py -3 tools/catalog.py
Output: work/t2.seeds.json, work/t2.functions.json, log in work/t2.catalog.log
"""
import json
import os
import re
import struct
import subprocess
import sys

import pefile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(os.environ.get('PCRECOMP', os.path.join(ROOT, '..', 'pcrecomp')), 'tools')
WORK = os.path.join(ROOT, 'work')


def reloc_seeds(path):
    pe = pefile.PE(path)
    img = pe.get_memory_mapped_image()
    base = pe.OPTIONAL_HEADER.ImageBase
    text = next(s for s in pe.sections if s.Name.rstrip(b'\0') == b'.text')
    lo, hi = base + text.VirtualAddress, base + text.VirtualAddress + text.Misc_VirtualSize
    targets = set()
    for blk in pe.DIRECTORY_ENTRY_BASERELOC:
        for e in blk.entries:
            if e.type == 3 and not lo <= base + e.rva < hi:
                v = struct.unpack_from('<I', img, e.rva)[0]
                if lo <= v < hi:
                    targets.add(v)
    arms = set()
    for m in re.finditer(rb'\xff\x24[\x85\x8d\x95\x9d\xad\xb5\xbd]', img[lo - base:hi - base]):
        t = struct.unpack_from('<I', img, lo - base + m.end())[0] - base
        while 0 <= t <= len(img) - 4 and lo <= struct.unpack_from('<I', img, t)[0] < hi:
            arms.add(struct.unpack_from('<I', img, t)[0])
            t += 4
    return sorted(v for v in targets - arms if v % 16 == 0 and img[v - base - 1] in (0, 0xC3, 0xCC, 0x90))


def main():
    img = os.path.join(ROOT, 'game', 'Tribes2.exe')
    cat = os.path.join(WORK, 't2.functions.json')
    if os.path.exists(cat) and '--force' not in sys.argv:
        print('catalog already there (--force redoes it)')
        return 0
    os.makedirs(WORK, exist_ok=True)
    seeds = os.path.join(WORK, 't2.seeds.json')
    found = reloc_seeds(img)
    json.dump([{'address': v} for v in found], open(seeds, 'w'))
    print('%d seeds from relocated code pointers' % len(found))
    with open(os.path.join(WORK, 't2.catalog.log'), 'w') as log:
        cmd = [os.path.join(TOOLS, 'disasm', 'disasm32.py'), img, '-o', cat, '--seed-functions', seeds]
        if subprocess.run([sys.executable] + cmd, stdout=log, stderr=subprocess.STDOUT).returncode:
            print('disasm32.py failed, see work/t2.catalog.log')
            return 1
    for line in open(os.path.join(WORK, 't2.catalog.log')):
        if 'Functions:' in line or 'coverage' in line:
            print(line.strip())
    return 0


if __name__ == '__main__':
    sys.exit(main())
