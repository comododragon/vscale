`include "vscale_ctrl_constants.vh"
`include "rv32_opcodes.vh"

`include "xvec/xvec_defines.vh"

module vscale_src_b_mux_xvec (
		src_b_sel,
		imm,
		rs2_data,
		alu_src_b
	);

	input [`SRC_A_SEL_WIDTH-1:0] src_b_sel;
	input [`XPR_LEN-1:0] imm;
	input [(`XVEC_VEC_LEN * `XPR_LEN)-1:0] rs2_data;
	output reg [(`XVEC_VEC_LEN * `XPR_LEN)-1:0] alu_src_b;

	always @(*) begin
		case(src_b_sel)
			`SRC_B_RS2:
				begin
					alu_src_b = rs2_data;
				end
			`SRC_B_IMM:
				// TODO: Fix this for `XVEC_VEC_LEN
				alu_src_b = {imm, imm, imm, imm, imm,
								imm, imm, imm, imm, imm, imm, imm, imm,
								imm, imm, imm, imm, imm, imm, imm, imm,
								imm, imm, imm, imm, imm, imm, imm, imm};
			`SRC_B_FOUR:
				alu_src_b = 'h4;
			default:
				alu_src_b = 'h0;
		endcase
	end

endmodule
