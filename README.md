# VScale RISC-V Processor with Xvec2 Extension

## Author

* André Bannwart Perina

## Introduction

This is a fork from VScale project (https://github.com/ucb-bar/vscale), featuring:

* A RV32IMXvec enabled RISC-V architecture;
	* **RV32I:** Base integer instruction set;
	* **M:** Standard extension for integer multiplication and division;
	* **Xvec2:** Non-standard extension for vector operations (version 2.0);
* An interactive simulator.

## Licence

This project holds the original licence from the original project (see LICENSE file).

## Prerequisites

* Icarus Verilog is needed for simulation;
* GtkWave or any other waveform viewer is needed if you want to interpret the vcd files.

## How to Install and Simulate (with Icarus Verilog)

1. Clone repo and access folder:

```
git clone -b xvec2 https://github.com/comododragon/vscale.git
cd vscale
```

2. For original (RV32IM) version:

```
make sim/VScaleHexTb
```

3. For full (RV32IMXvec2) version:

```
make sim/Xvec2VScaleHexTb
```

4. Run (substitute ```VScaleHexTb``` by ```Xvec2VScaleHexTb``` if appropriate):

```
./sim/VScaleHexTb +max-cycles=1000 +loadmem=./example.hex +vpdfile=./example.vcd
```

* **max-cycles:** Maximum number of cycles before process aborts;
* **example.hex:** Example input file. Check section **Description of Hex File** for further details;
* **example.vcd:** Waveform file (use e.g. GtkWave to interpret it).

## Using the V-Scale Compiler (vsc)

The V-Scale Compiler (vsc) is an utility bundled with this project (in very preliminar phase) that enables converting from plain C source codes directly to Hex files, readable by the simulator. There are some prerequisites, however:

* ```python3``` must be installed;
* ```riscv-gnu-toolchain``` (https://github.com/riscv/riscv-gnu-toolchain) and ```riscv-llvm``` (https://github.com/riscv/riscv-llvm) must be compiled, installed and on ```PATH```;
* C source codes should make no use of external libraries (e.g. ```stdio.h```).

To use it, simply:

```
python3 vsc.py [OPTION]... CFILE HEXFILE
```

Where ```CFILE```is the C source code and ```HEXFILE``` the destination hex file.

```OPTION``` may be:
* ```-p```, ```--clang-bin-path```: Specify custom path for RISC-V clang binary. Default is ```clang```;
* ```-q```, ```--gcc-bin-path```: Specify custom path for RISC-V gcc binary. Default is ```riscv32-unknown-linux-gnu-gcc```;
* ```-cFoo```, ```--clang-arg=Foo```: Pass Foo argument to ```clang```;
* ```-gFoo```, ```--gcc-arg=Foo```: Pass Foo argument to ```gcc```.

## Description of Hex File

Hex files used as initial memory are described as:

* 8192 lines of 16 bytes described by hexadecimal characters;
* MSB to LSB = left to right;
* RISC-V PC starts at 0x200 (first bytes from the 33rd line);
* Check files in ```src/test/inputs/``` for examples.

## Xvec2 Extension

The Xvec non-standard extension (version 2.0) enables support for vector operations on the architecture. It features:

* 1 vector of 4 zero constants (vector 0) + 7 vectors of 4 registers each (vector 1 to 7);
* Specific instructions for load and store in these registers;
* Vector operations on all arithmetic and logic operations available in the standard ALU;
* Same instruction format from ALU operations.

### Differences from Xvec Version 1.0

* The general-purpose registers were part of vector register ```v1``` in Xvec. In Xvec2, these concepts were separated;
	* General-purpose registers: ```r0-31```;
	* Vector registers: ```r32-63``` grouped in quadruples (```v0-v7```);
* There was no load and store instructions for any register apart the general-purpose in Xvec. Therefore it was impossible to directly load/store anything other than ```v1```. With Xvec2, specific load and store functions were created to manage the vector registers. It is now possible to access any vector register from ```v1``` to ```v7```;
* There was no pipeline hazard logic for Xvec instructions. Xvec2 implements pipeline hazard logic (no need of bubble NOPs).

### Vector Description:

* **v0**: Registers ```r32```, ```r33```, ```r34```, ```r35``` (hardcoded to zeroes);
* **v1**: Registers ```r36```, ```r37```, ```r38```, ```r39```;
* **v2**: Registers ```r40```, ```r41```, ```r42```, ```r43```;
* **v3**: Registers ```r44```, ```r45```, ```r46```, ```r47```;
* **v4**: Registers ```r48```, ```r49```, ```r50```, ```r51```;
* **v5**: Registers ```r52```, ```r53```, ```r54```, ```r55```;
* **v6**: Registers ```r56```, ```r57```, ```r58```, ```r59```;
* **v7**: Registers ```r60```, ```r61```, ```r62```, ```r63```;

### Xvec2 Instructions

Xvec2 has two operation opcodes, ```XVEC2_OP``` and ```XVEC2_OP_IMM```, which has almost the same structure as the standard ```OP``` and ```OP_IMM```, apart from some unused bits in vector addressing:

* **XVEC2_OP:**
	* **M:**
		* **1:** for SUB/SRA;
		* **0:** for ADD/SLL/SLT/SLTU/XOR/SRL/OR/AND;
	* **vs2/shamt:** Source vector 2 or shift amount;
	* **vs1:** Source vector 1;
	* **ALU:** Operation: (ADD|SUB)/SLL/SLT/SLTU/XOR/(SRL|SRA)/OR/AND;
	* **vd:** Destination vector.

	```
	[31:25] [24:22] [21:20] [19:17] [16:15] [14:12] [11:9] [8:7] [ 6:0 ]
	0M00000   vs2     ---     vs1     ---     ALU     vd    ---  1111011

	[31:25] [24:20] [19:17] [16:15] [14:12] [11:9] [8:7] [ 6:0 ]
	0M00000  shamt    vs1     ---     ALU     vd    ---  1111011
	```

* **XVEC2_OP_IMM:**
	* **M:**
		* **1:** for SRAI;
		* **0:** for SLLI/SRLI;
	* **imm:** Immediate value;
	* **shamt:** Shift amount;
	* **vs1:** Source vector 1;
	* **ALU:** Operation: ADDI/SLTI/SLTIU/XORI/ORI/ANDI/SLLI/(SRLI|SRAI);
	* **vd:** Destination vector.

	```
	[31:20] [19:17] [16:15] [14:12] [11:9] [8:7] [ 6:0 ]
	  imm     vs1     ---     ALU     vd    ---  1011011

	[31:25] [24:20] [19:17] [16:15] [14:12] [11:9] [8:7] [ 6:0 ]
	0M00000  shamt    vs1     ---     ALU     vd    ---  1011011
	```

Xvec2 has two load/store opcodes, ```XVEC2_LOAD``` and ```XVEC2_STORE```, which has the same structure as the standard ```LOAD``` and ```STORE```:

* **XVEC2_LOAD:**
	* **imm:** Immediate value to be added on the address present at ```rs1```;
	* **rs1:** General-purpose (```r0-r31```) register holding the load address;
	* **func3:** Operation: LB/LH/LW/LBU/LHU;
	* **rd:** Destination register (```r32-r63```);
		* ```rd``` points to a single register in the vectors. Ignore the MSB when using this instruction (e.g. for ```r44```, use binary 01100 instead of 101100).

	```
	[31:20] [19:15] [14:12] [11:7] [ 6:0 ]
	  imm     rs1    func3    rd   0001011
	```

* **XVEC2_STORE:**
	* **imm:** Immediate value to be added on the address present at ```rs1```;
	* **rs2:** Register to be stored (```r32-r63```);
		* ```rs2``` points to a single register in the vectors. Ignore the MSB when using this instruction (e.g. for ```r44```, use binary 01100 instead of 101100);
	* **rs1:** General-purpose (```r0-r31```) register holding the store address;
	* **func3:** Operation: SB/SH/SW.

	```
	[ 31:25 ] [24:20] [19:15] [14:12] [ 11:7 ] [ 6:0 ]
	imm[11:5]   rs2     rs1    func3  imm[4:0] 0101011
	```

Refer to the RISC-V specification for further info on RV32 instructions.


## Simple Usage: From C to Simulation

Soon...

## Future Work

* Remove unused registers from register file (v0 and r0 are not effectively used but are instantiated);
* Create internal documentation on source codes;
* Use parameter to define the size of vectors.
