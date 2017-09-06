`include "vscale_ctrl_constants.vh"
`include "rv32_opcodes.vh"

module xvec2_vscale_src_b_mux (
		src_b_sel,
		imm,
		rs2_data,
		alu_src_b
	);

	input [`SRC_B_SEL_WIDTH-1:0] src_b_sel;
	input [`VEC_XPR_LEN-1:0] imm;
	input [`VEC_XPR_LEN-1:0] rs2_data;
	output reg [`VEC_XPR_LEN-1:0] alu_src_b;

	always @(*) begin
		case(src_b_sel)
			`SRC_B_RS2: alu_src_b = rs2_data;
			`SRC_B_IMM: alu_src_b = imm;
			//`SRC_B_FOUR: alu_src_b = 4;
			default: alu_src_b = 0;
		endcase
	end

endmodule
