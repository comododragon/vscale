`include "vscale_alu_ops.vh"
`include "rv32_opcodes.vh"

`include "xvec/xvec_defines.vh"

module vscale_alu_xvec (
		op,
		in1,
		in2,
		out,
		xvec_mode
	);

	input [`ALU_OP_WIDTH-1:0] op;
    input [(32 * `XPR_LEN)-1:0] in1;
    input [(32 * `XPR_LEN)-1:0] in2;
    output [(32 * `XPR_LEN)-1:0] out;
    input xvec_mode;

	wire [`SHAMT_WIDTH-1:0] shamt;
	wire [`XPR_LEN-1:0] win1 [0:31];
	wire [`XPR_LEN-1:0] win2 [0:31];
	reg [`XPR_LEN-1:0] rout [0:31];

	genvar gi;
	for(gi = 0; gi < 32; gi = gi + 1) begin
		assign win1[gi] = in1 >> (gi * `XPR_LEN);
		assign win2[gi] = in2 >> (gi * `XPR_LEN);
	end
	assign out = {rout[31], rout[30], rout[29], rout[28], rout[27], rout[26], rout[25], rout[24],
					rout[23], rout[22], rout[21], rout[20], rout[19], rout[18], rout[17], rout[16],
					rout[15], rout[14], rout[13], rout[12], rout[11], rout[10], rout[9], rout[8],
					rout[7], rout[6], rout[5], rout[4], rout[3], rout[2], rout[1], rout[0]};

	assign shamt = win2[0][`SHAMT_WIDTH-1:0];

	integer i;
	// TODO: ARGH THIS IS SO UGLY PLEASE FIX IT
	always @(op, shamt,
				win1[0], win1[1], win1[2], win1[3], win1[4], win1[5], win1[6], win1[7],
				win1[8], win1[9], win1[10], win1[11], win1[12], win1[13], win1[14], win1[15],
				win1[16], win1[17], win1[18], win1[19], win1[20], win1[21], win1[22], win1[23],
				win1[24], win1[25], win1[26], win1[27], win1[28], win1[29], win1[30], win1[31],
				win2[0], win2[1], win2[2], win2[3], win2[4], win2[5], win2[6], win2[7],
				win2[8], win2[9], win2[10], win2[11], win2[12], win2[13], win2[14], win2[15],
				win2[16], win2[17], win2[18], win2[19], win2[20], win2[21], win2[22], win2[23],
				win2[24], win2[25], win2[26], win2[27], win2[28], win2[29], win2[30], win2[31]
			) begin
		case(op)
			`ALU_OP_ADD:
				begin
					rout[0] = win1[0] + win2[0];
					if(xvec_mode) begin
						for(i = 1; i < 32; i = i + 1) begin
							rout[i] = win1[i] + win2[i];
						end
					end
				end
			`ALU_OP_SLL:
				begin
					rout[0] = win1[0] << shamt;
					if(xvec_mode) begin
						for(i = 1; i < 32; i = i + 1) begin
							rout[i] = win1[i] << shamt;
						end
					end
				end
			`ALU_OP_XOR:
				begin
					rout[0] = win1[0] ^ win2[0];
					if(xvec_mode) begin
						for(i = 1; i < 32; i = i + 1) begin
							rout[i] = win1[i] ^ win2[i];
						end
					end
				end
			`ALU_OP_OR:
				begin
					rout[0] = win1[0] | win2[0];
					if(xvec_mode) begin
						for(i = 1; i < 32; i = i + 1) begin
							rout[i] = win1[i] | win2[i];
						end
					end
				end
			`ALU_OP_AND:
				begin
					rout[0] = win1[0] & win2[0];
					if(xvec_mode) begin
						for(i = 1; i < 32; i = i + 1) begin
							rout[i] = win1[i] & win2[i];
						end
					end
				end
			`ALU_OP_SRL:
				begin
					rout[0] = win1[0] >> win2[0];
					if(xvec_mode) begin
						for(i = 1; i < 32; i = i + 1) begin
							rout[i] = win1[i] >> win2[i];
						end
					end
				end
			`ALU_OP_SEQ:
				rout[0] = {31'b0, win1[0] == win2[0]};
			`ALU_OP_SNE:
				rout[0] = {31'b0, win1[0] != win2[0]};
			`ALU_OP_SUB:
				begin
					rout[0] = win1[0] - win2[0];
					if(xvec_mode) begin
						for(i = 1; i < 32; i = i + 1) begin
							rout[i] = win1[i] - win2[i];
						end
					end
				end
			`ALU_OP_SRA:
				begin
					rout[0] = $signed(win1[0]) >>> shamt;
					if(xvec_mode) begin
						for(i = 1; i < 32; i = i + 1) begin
							rout[i] = $signed(win1[i]) >>> shamt;
						end
					end
				end
			`ALU_OP_SLT:
				rout[0] = {31'b0, $signed(win1[0]) < $signed(win2[0])};
			`ALU_OP_SGE:
				rout[0] = {31'b0, $signed(win1[0]) >= $signed(win2[0])};
			`ALU_OP_SLTU:
				rout[0] = {31'b0, win1[0] < win2[0]};
			`ALU_OP_SGEU:
				rout[0] = {31'b0, win1[0] >= win2[0]};
			// TODO: É correto desconsiderar xvec_mode?
			default:
				rout[0] = 0;
		endcase
	end

endmodule
