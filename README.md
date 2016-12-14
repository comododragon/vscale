# VScale RISC-V Processor with Xvec Extension

## Author

* André Bannwart Perina

## Introduction

This is a fork from VScale project (https://github.com/ucb-bar/vscale), featuring:

* A RV32IMXvec enabled RISC-V architecture;
	* **RV32I:** Base integer instruction set;
	* **M:** Standard extension for integer multiplication and division;
	* **Xvec:** Non-standard extension for vector operations;
* An interactive simulator.

## Licence

This project holds the original licence from the original project (see LICENSE file).

## Prerequisites

* Icarus Verilog is needed for simulation;
* GtkWave or any other waveform viewer is needed if you want to interpret the vcd files.

## How to Install and Simulate (with Icarus Verilog)

1. Clone repo and access folder:

```
git clone https://github.com/comododragon/vscale.git
cd vscale
```

2. For original (RV32IM) version:

```
make sim/VScaleHexTb
```

3. For full (RV32IMXvec) version:

```
make sim/XvecVScaleHexTb
```

4. Run (substitute ```VScaleHexTb``` by ```XvecVScaleHexTb``` if appropriate):

```
./sim/VScaleHexTb +max-cycles=1000 +loadmem=./example.hex +vpdfile=./example.vcd
```

* **max-cycles:** Maximum number of cycles before process aborts;
* **example.hex:** Example input file. Check section **Description of Hex File** for further details;
* **example.vcd:** Waveform file (use e.g. GtkWave to interpret it).

## Using the V-Scale Compiler (vsc)

The V-Scale Compiler (vsc) is an utility bundled with this project (in very preliminar phase) that
enables converting from plain C source codes directly to Hex files, readable by the simulator.
There are some prerequisites, however:

* ```python3``` must be installed;
* ```riscv-gnu-toolchain``` (https://github.com/riscv/riscv-gnu-toolchain) and ```riscv-llvm```
	(https://github.com/riscv/riscv-llvm) must be compiled, installed and on ```PATH```;
* C source codes should make no use of external libraries (e.g. ```stdio.h```).

To use it, simply:

```
python3 vsc.py CFILE HEXFILE
```

Where ```CFILE```is the C source code and ```HEXFILE``` the destination hex file.

## Description of Hex File

Hex files used as initial memory are described as:

* 8192 lines of 16 bytes described by hexadecimal characters;
* MSB to LSB = left to right;
* RISC-V PC starts at 0x200 (first bytes from the 33rd line);
* Check files in ```src/test/inputs/``` for examples.

## Xvec Extension

The Xvec non-standard extension enables support for vector operations on the architecture. It features:

* 4 vectors of 32 registers;
* Vector operations on all arithmetic and logic operations available in the standard ALU;
* Same instruction format from ALU operations.

### Vector description:

* **v0:** Zero-vector;
* **v1:** Standard all-purpose registers (RV32I's r0 to r32);
* **v2-xx:** All-purpose vectors.

### Xvec Instructions

Xvec has two opcodes, ```XVEC_OP``` and ```XVEC_OP_IMM```, which has the same structure as the standard
```OP``` and ```OP_IMM```:

* **XVEC_OP:**
	* **M:**
		* **1:** for SUB/SRA;
		* **0:** for ADD/SLL/SLT/SLTU/XOE/SRL/OR/AND;
	* **vs2/shamt:** Source vector 2 or shift amount;
	* **vs1:** Source vector 1;
	* **ALU:** Operation: (ADD|SUB)/SLL/SLT/SLTU/XOR/(SRL|SRA)/OR/AND;
	* **vd:** Destination vector;

	```
	[31:25] [ 24:20 ] [19:15] [14:12] [11:7] [ 6:0 ]
	0M00000 vs2/shamt   vs1     ALU     vd   0001011
	```

* **XVEC_OP_IMM:**
	* **M:**
		* **1:** for SRAI;
		* **0:** for SLLI/SRLI;
	* **imm:** Immediate value;
	* **shamt:** Shift amount;
	* **vs1:** Source vector 1;
	* **ALU:** Operation: ADDI/SLTI/SLTIU/XORI/ORI/ANDI/SLLI/(SRLI|SRAI);
	* **vd:** Destination vector;

	```
	[31:20] [19:15] [14:12] [11:7] [ 6:0 ]
	  imm     vs1     ALU     vd   0101011

	[31:25] [ 24:20 ] [19:15] [14:12] [11:7] [ 6:0 ]
	0M00000   shamt     vs1     ALU     vd   0101011
	```

Refer to the RISC-V specification for further info.


### Important note

The register addressing logic is the same for both register and vector operations. Therefore, the processor sees access to register X as being the same as accessing vector X, where X is between 0 and 31. As an example, if a load to register r3 is directly succeeded by a vector add aiming vector v3, the hazard logic will assume that both load and add are referring to the same place (since both have address 3), discarding the load and committing only the vector add (recall that all standard registers, such as r3, are placed on vector v1). **It is recommended therefore isolating vector operations from non-vector operations by using NOPs**.

## Future work

* Create hazard logic to differentiate between vector and non-vector addressing;
* Remove unused registers from register file (v0 and r0 are not effectively used but are instantiated);
* Create internal documentation on source codes;
* Use parameter to define the size of vectors (working on it).
