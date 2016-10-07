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
	always @(op, in1, in2, shamt) begin
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
