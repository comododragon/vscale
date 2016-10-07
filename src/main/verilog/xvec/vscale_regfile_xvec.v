`include "rv32_opcodes.vh"

`include "xvec/xvec_defines.vh"

module vscale_regfile_xvec (
		clk,
		ra1,
		rd1,
		ra2,
		rd2,
		wen,
		wa,
		wd,
		xvec_mode_DX,
		xvec_mode_WB,
	);

	input clk;
	input [`REG_ADDR_WIDTH-1:0] ra1;
	output [(32 * `XPR_LEN)-1:0] rd1;
	input [`REG_ADDR_WIDTH-1:0] ra2;
	output [(32 * `XPR_LEN)-1:0] rd2;
	input wen;
	input [`REG_ADDR_WIDTH-1:0] wa;
	input [(32 * `XPR_LEN)-1:0] wd;
	input xvec_mode_DX;
	input xvec_mode_WB;
	
	// TODO: Remover o r0, é tudo zero!
	reg [`XPR_LEN-1:0] data [0:31][0:(`XVEC_SIZE-1)];
	wire wen_internal;

	assign wen_internal = wen && (|wa);

	assign rd1 = (|ra1)?
					xvec_mode_DX?
						{data[31][ra1], data[30][ra1], data[29][ra1], data[28][ra1],
							data[27][ra1], data[26][ra1], data[25][ra1], data[24][ra1],
							data[23][ra1], data[22][ra1], data[21][ra1], data[20][ra1],
							data[19][ra1], data[18][ra1], data[17][ra1], data[16][ra1],
							data[15][ra1], data[14][ra1], data[13][ra1], data[12][ra1],
							data[11][ra1], data[10][ra1], data[9][ra1], data[8][ra1],
							data[7][ra1], data[6][ra1], data[5][ra1], data[4][ra1],
							data[3][ra1], data[2][ra1], data[1][ra1], data[0][ra1]}
						:
						{`XVEC_NORM_BITS_REM'h0, data[ra1][1]}
					:
					0;

	assign rd2 = (|ra2)?
					xvec_mode_DX?
						{data[31][ra2], data[30][ra2], data[29][ra2], data[28][ra2],
							data[27][ra2], data[26][ra2], data[25][ra2], data[24][ra2],
							data[23][ra2], data[22][ra2], data[21][ra2], data[20][ra2],
							data[19][ra2], data[18][ra2], data[17][ra2], data[16][ra2],
							data[15][ra2], data[14][ra2], data[13][ra2], data[12][ra2],
							data[11][ra2], data[10][ra2], data[9][ra2], data[8][ra2],
							data[7][ra2], data[6][ra2], data[5][ra2], data[4][ra2],
							data[3][ra2], data[2][ra2], data[1][ra2], data[0][ra2]}
						:
						{`XVEC_NORM_BITS_REM'h0, data[ra2][1]}
					:
					0;

	integer i;
	always @(posedge clk) begin
		if(wen_internal) begin
			if(!xvec_mode_WB) begin
				data[wa][1] = wd[`XPR_LEN-1:0];
			end
			else begin
				for(i = 0; i < 32; i = i + 1)
					data[i][wa] = wd >> (i * `XPR_LEN);
			end
		end
	end

`ifndef SYNTHESIS
	integer ii;
	integer jj;
	initial begin
		for(ii = 0; ii < 32; ii = ii + 1) begin
			for(jj = 0; jj < `XVEC_SIZE; jj = jj + 1) begin
				data[ii][jj] = $random;
			end
		end
	end
`endif

endmodule
