sim/VScaleHexTb: $(wildcard src/test/verilog/*.v) $(wildcard src/main/verilog/*)
	mkdir -p sim/
	iverilog src/test/verilog/*.v src/main/verilog/* -I src/main/verilog/ -o sim/VScaleHexTb

sim/XvecVScaleHexTb: $(wildcard src/test/verilog/*.v) $(wildcard src/main/verilog/*) $(wildcard src/main/verilog/xvec/*)
	mkdir -p sim/
	iverilog src/test/verilog/*.v src/main/verilog/* src/main/verilog/xvec/* -I src/main/verilog/ -I src/main/verilog/xvec/ -o sim/XvecVScaleHexTb -DXVEC

clean:
	rm -f sim/VScaleHexTb
	rm -f sim/XvecVScaleHexTb
