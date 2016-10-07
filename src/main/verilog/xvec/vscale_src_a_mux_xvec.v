`include "vscale_ctrl_constants.vh"
`include "rv32_opcodes.vh"

`include "xvec/xvec_defines.vh"

module vscale_src_a_mux_xvec (
		src_a_sel,
		PC_DX,
		rs1_data,
		alu_src_a
	);

	input [`SRC_A_SEL_WIDTH-1:0] src_a_sel;
	input [`XPR_LEN-1:0] PC_DX;
	input [(32 * `XPR_LEN)-1:0] rs1_data;
	output reg [(32 * `XPR_LEN)-1:0] alu_src_a;

	always @(*) begin
		case(src_a_sel)
			`SRC_A_RS1:
				begin
					alu_src_a = rs1_data;
				end
			`SRC_A_PC:
				alu_src_a = {`XVEC_NORM_BITS_REM'h0, PC_DX};
			default:
				alu_src_a = 'h0;
		endcase
	end

endmodule
