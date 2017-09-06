`include "vscale_ctrl_constants.vh"

module xvec2_vscale_src_a_mux (
		src_a_sel,
		rs1_data,
		alu_src_a
	);

	input [`SRC_A_SEL_WIDTH-1:0] src_a_sel;
	input [`VEC_XPR_LEN-1:0] rs1_data;
	output reg [`VEC_XPR_LEN-1:0] alu_src_a;

	always @(*) begin
		alu_src_a = rs1_data;
	end

endmodule
