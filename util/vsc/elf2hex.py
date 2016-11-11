#!/usr/bin/python3

import os
import subprocess
import sys

def elf2hex(elfFile, hexFile):
	if os.path.getsize(elfFile) > 0x20000:
		raise RuntimeError("File {0} exceeds 128 kB".format(elfFile))

	readElfProc = subprocess.Popen(["riscv64-unknown-linux-gnu-readelf", "--sections", elfFile], stdout = subprocess.PIPE, stderr = subprocess.PIPE)
	awkProc = subprocess.Popen(["awk", '/.text/ { printf "%d", $5 }'], stdin = readElfProc.stdout, stdout = subprocess.PIPE)
	readElfProc.stdout.close()
	startText = int(awkProc.communicate()[0], 16)
	if 0 == readElfProc.wait():
		if startText != 0x200:
			sys.stderr.write("WARNING: .text section for this file starts at 0x{0:x}. ".format(startText)
								+ "Standard RISC-V architectures start at 0x200. Your program may not function properly.\n")
	else:
		raise RuntimeError("File {0} is not an ELF executable file".format(elfFile))

	with open(elfFile, "rb") as ipf:
		with open(hexFile, "w") as opf:
			linesWritten = 0
			readBytes = ipf.read(16)
			while readBytes:
				if(len(readBytes) < 16):
					for i in range(0, (16 - len(readBytes))):
						opf.write("00")
				for i in range(0, len(readBytes)):
					opf.write("{:02x}".format(readBytes[(len(readBytes) - 1) - i]))
				opf.write("\n")
				readBytes = ipf.read(16)
				linesWritten = linesWritten + 1
			for i in range(0, 8192 - linesWritten):
				opf.write("00000000000000000000000000000000\n")


if "__main__" == __name__:
	if 3 != len(sys.argv):
		sys.stderr.write("USAGE: {0} ELFFILE HEXFILE\n".format(sys.argv[0]))
		exit(1)

	elf2hex(sys.argv[1], sys.argv[2])
