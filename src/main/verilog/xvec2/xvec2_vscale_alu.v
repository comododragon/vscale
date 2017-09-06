`include "vscale_alu_ops.vh"
`include "rv32_opcodes.vh"

module xvec2_vscale_alu (
		op,
		in1,
		in2,
		out
	);

	input [`ALU_OP_WIDTH-1:0] op;
	input [`VEC_XPR_LEN-1:0] in1;
	input [`VEC_XPR_LEN-1:0] in2;
	output [`VEC_XPR_LEN-1:0] out;

	wire [`SHAMT_WIDTH-1:0] shamt;
	wire [`XPR_LEN-1:0] win1 [0:(`VEC_SIZE - 1)];
	wire [`XPR_LEN-1:0] win2 [0:(`VEC_SIZE - 1)];
	reg [`XPR_LEN-1:0] rout [0:(`VEC_SIZE - 1)];

	genvar gi;
	for(gi = 0; gi < `VEC_SIZE; gi = gi + 1) begin
		assign win1[gi] = in1 >> (gi * `XPR_LEN);
		assign win2[gi] = in2 >> (gi * `XPR_LEN);
	end
	// TODO: Fix this for `XVEC_VEC_LEN
	assign out = {rout[3], rout[2], rout[1], rout[0]};

	assign shamt = win2[0][`SHAMT_WIDTH-1:0];

	integer i;
	// TODO: ARGH THIS IS SO UGLY PLEASE FIX IT
	// TODO: Fix this for `VEC_SIZE
	always @(op, shamt, win1[0], win1[1], win1[2], win1[3], win2[0], win2[1], win2[2], win2[3]) begin
		case(op)
			`ALU_OP_ADD:
				begin
					for(i = 0; i < `VEC_SIZE; i = i + 1)
						rout[i] = win1[i] + win2[i];
				end
			`ALU_OP_SLL:
				begin
					for(i = 0; i < `VEC_SIZE; i = i + 1)
						rout[i] = win1[i] << shamt;
				end
			`ALU_OP_XOR:
				begin
					for(i = 0; i < `VEC_SIZE; i = i + 1)
						rout[i] = win1[i] ^ win2[i];
				end
			`ALU_OP_OR:
				begin
					for(i = 0; i < `VEC_SIZE; i = i + 1)
						rout[i] = win1[i] | win2[i];
				end
			`ALU_OP_AND:
				begin
					for(i = 0; i < `VEC_SIZE; i = i + 1)
						rout[i] = win1[i] & win2[i];
				end
			`ALU_OP_SRL:
				begin
					for(i = 0; i < `VEC_SIZE; i = i + 1)
						rout[i] = win1[i] >> win2[i];
				end
			/*`ALU_OP_SEQ:
				rout[0] = {31'b0, win1[0] == win2[0]};
			`ALU_OP_SNE:
				rout[0] = {31'b0, win1[0] != win2[0]};*/
			`ALU_OP_SUB:
				begin
					for(i = 0; i < `VEC_SIZE; i = i + 1)
						rout[i] = win1[i] - win2[i];
				end
			`ALU_OP_SRA:
				begin
					for(i = 0; i < `VEC_SIZE; i = i + 1)
						rout[i] = $signed(win1[i]) >>> shamt;
				end
			/*`ALU_OP_SLT:
				rout[0] = {31'b0, $signed(win1[0]) < $signed(win2[0])};
			`ALU_OP_SGE:
				rout[0] = {31'b0, $signed(win1[0]) >= $signed(win2[0])};
			`ALU_OP_SLTU:
				rout[0] = {31'b0, win1[0] < win2[0]};
			`ALU_OP_SGEU:
				rout[0] = {31'b0, win1[0] >= win2[0]};*/
			default:
				rout[0] = 0;
		endcase
	end

endmodule
