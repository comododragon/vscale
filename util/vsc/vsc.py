#!/usr/bin/python3

from elf2hex import elf2hex
import os
import subprocess
import sys
import tempfile

if "__main__" == __name__:
	if 3 != len(sys.argv):
		sys.stderr.write("USAGE: {0} SRCFILE HEXFILE\n".format(sys.argv[0]))
		exit(1)

	try:
		hexLinkLdPath = os.path.join(os.path.dirname(os.path.realpath(__file__)), "hexlink.ld")
		if not os.path.exists(hexLinkLdPath):
			raise RuntimeError("File hexlink.ld is missing (must be on same folder as this python file)")

		tmpFolder = tempfile.mkdtemp()
		clangOutPath = os.path.join(tmpFolder, "clangout.s")
		gccOutPath = os.path.join(tmpFolder, "gccout")
		retVal = subprocess.call(["clang", "-target", "riscv", "-mriscv=RV32I", "-S", sys.argv[1], "-o", clangOutPath])
		if retVal != 0:
			raise RuntimeError("clang failed")
		retVal = subprocess.call(
			["riscv64-unknown-linux-gnu-gcc", "-m32", "-nostdlib", "-nostartfiles", "-T{0}".format(hexLinkLdPath), clangOutPath, "-o", gccOutPath])
		if retVal != 0:
			raise RuntimeError("riscv64-unknown-linux-gnu-gcc failed")
		elf2hex(gccOutPath, sys.argv[2])
	finally:
		if os.path.exists(gccOutPath):
			os.remove(gccOutPath)
		if os.path.exists(clangOutPath):
			os.remove(clangOutPath)
		if os.path.exists(tmpFolder):
			os.rmdir(tmpFolder)
