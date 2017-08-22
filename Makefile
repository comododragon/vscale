sim/VScaleHexTb: $(wildcard src/test/verilog/*.v) $(wildcard src/main/verilog/*)
	mkdir -p sim/
	iverilog src/test/verilog/*.v src/main/verilog/* -I src/main/verilog/ -o sim/VScaleHexTb

sim/Xvec2VScaleHexTb: $(wildcard src/test/verilog/*.v) $(wildcard src/main/verilog/*) $(wildcard src/main/verilog/xvec2/*)
	mkdir -p sim/
	iverilog src/test/verilog/*.v src/main/verilog/* src/main/verilog/xvec2/* -I src/main/verilog/ -I src/main/verilog/xvec2/ -o sim/Xvec2VScaleHexTb -DXVEC2

clean:
	rm -f sim/VScaleHexTb
	rm -f sim/Xvec2VScaleHexTb
