"""Disassemble Tribes2.exe at a VA: py -3 tools/disasm_at.py 0x5F8C00 [count]"""
import sys
import pefile
from capstone import Cs, CS_ARCH_X86, CS_MODE_32
pe = pefile.PE(sys.argv[3] if len(sys.argv) > 3 else 'game/Tribes2.exe')
img = pe.get_memory_mapped_image()
base = pe.OPTIONAL_HEADER.ImageBase
va, n = int(sys.argv[1], 16), int(sys.argv[2]) if len(sys.argv) > 2 else 40
for i in list(Cs(CS_ARCH_X86, CS_MODE_32).disasm(img[va - base:va - base + 16 * n], va))[:n]:
    print('%08X  %-8s %s' % (i.address, i.mnemonic, i.op_str))
