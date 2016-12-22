#!/usr/bin/env python3

from elf2hex import elf2hex
from getopt import GetoptError
from getopt import getopt
import os
import subprocess
import sys
import tempfile

if "__main__" == __name__:
	if len(sys.argv) < 3:
		sys.stderr.write("USAGE: {0} [OPTION]... SRCFILE HEXFILE\n".format(sys.argv[0]))
		sys.stderr.write("\twhere OPTION may be:\n")
		sys.stderr.write("\t\t-p, --clang-bin-path\n")
		sys.stderr.write("\t\t\tSpecify custom path for RISC-V clang binary. Default is clang.\n")
		sys.stderr.write("\t\t-q, --gcc-bin-path\n")
		sys.stderr.write("\t\t\tSpecify custom path for RISC-V gcc binary. Default is riscv32-unknown-linux-gnu-gcc.\n")
		sys.stderr.write("\t\t-cFoo, --clang-arg=Foo\n")
		sys.stderr.write("\t\t\tPass Foo argument to clang..\n")
		sys.stderr.write("\t\t-gFoo, --gcc-arg=Foo\n")
		sys.stderr.write("\t\t\tPass Foo argument to gcc..\n")
		exit(1)

	clangBin = "clang"
	gccBin = "riscv32-unknown-linux-gnu-gcc"
	clangArgsList = []
	gccArgsList = []
	try:
		optList, args = getopt(sys.argv[1:], "p:q:c:g:", ["clang-bin-path=", "gcc-bin-path=", "clang-arg=", "gcc-arg="])
		for o, a in optList:
			if o in ("-p", "--clang-bin-path"):
				clangBin = a
			if o in ("-q", "--gcc-bin-path"):
				gccBin = a
			elif o in ("-c", "--clang-arg"):
				clangArgsList.append(a)
			elif o in ("-g", "--gcc-arg"):
				gccArgsList.append(a)
	except GetoptError as err:
		sys.stderr.write(str(err) + "\n")
		exit(1)

	try:
		hexLinkLdPath = os.path.join(os.path.dirname(os.path.realpath(__file__)), "hexlink.ld")
		if not os.path.exists(hexLinkLdPath):
			raise RuntimeError("File hexlink.ld is missing (must be on same folder as this python file)")

		tmpFolder = tempfile.mkdtemp()
		clangOutPath = os.path.join(tmpFolder, "clangout.s")
		gccOutPath = os.path.join(tmpFolder, "gccout")
		retVal = subprocess.call([clangBin, "-target", "riscv", "-mriscv=RV32I", "-S", args[0], "-o", clangOutPath] + clangArgsList)
		if retVal != 0:
			raise RuntimeError("{0} failed".format(clangBin))
		retVal = subprocess.call(
			[gccBin, "-nostdlib", "-nostartfiles", "-T{0}".format(hexLinkLdPath), clangOutPath, "-o", gccOutPath] + gccArgsList)
		if retVal != 0:
			raise RuntimeError("{0} failed".format(gccBin))
		elf2hex(gccOutPath, args[1])
	finally:
		if os.path.exists(gccOutPath):
			os.remove(gccOutPath)
		if os.path.exists(clangOutPath):
			os.remove(clangOutPath)
		if os.path.exists(tmpFolder):
			os.rmdir(tmpFolder)
