`include "rv32_opcodes.vh"
`include "xvec2_defines.vh"

module xvec2_vscale_vecfile(
		clk,
		ra1,
		rd1,
		ra2,
		rd2,
		wen,
		wa,
		wmask,
		wd
	);

	input clk;
	input [`VEC_ADDR_WIDTH-1:0] ra1;
	output [`VEC_XPR_LEN-1:0] rd1;
	input [`VEC_ADDR_WIDTH-1:0] ra2;
	output [`VEC_XPR_LEN-1:0] rd2;
	input wen;
	input [`VEC_ADDR_WIDTH-1:0] wa;
	input [`VEC_SIZE-1:0] wmask;
	input [`VEC_XPR_LEN-1:0] wd;

	reg [`XPR_LEN-1:0] data [31:0];
	wire wen_internal;

	// fpga-style zero register
	assign wen_internal = wen && |wa;

	// TODO: Ideally, the statements below should be created based on `VEC_ADDR_WIDTH (i.e. the number of concatenations would vary. How to do that?)
	wire [`VEC_ADDR_WIDTH+2:0] xra1 = ra1 << 2;
	wire [`VEC_ADDR_WIDTH+2:0] xra2 = ra2 << 2;
	wire [`VEC_ADDR_WIDTH+2:0] xwa = wa << 2;
	assign rd1 = (|xra1)? {data[xra1 + 3], data[xra1 + 2], data[xra1 + 1], data[xra1]} : 0;
	assign rd2 = (|xra2)? {data[xra2 + 3], data[xra2 + 2], data[xra2 + 1], data[xra2]} : 0;

	// TODO: Ideally, the statements below should be created based on `VEC_ADDR_WIDTH (i.e. the number of lines would vary. How to do that?)
	always @(posedge clk) begin
		if(wen_internal) begin
			if(wmask & 'b1)
				data[xwa] <= wd;
			if(wmask & 'b10)
				data[xwa + 1] <= wd >> `XPR_LEN;
			if(wmask & 'b100)
				data[xwa + 2] <= wd >> (2 * `XPR_LEN);
			if(wmask & 'b1000)
				data[xwa + 3] <= wd >> (3 * `XPR_LEN);
		end
	end

`ifndef SYNTHESIS
	integer i;
	initial begin
		for(i = 0; i < 32; i = i + 1) begin
			data[i] = $random;
		end
	end
`endif

endmodule
