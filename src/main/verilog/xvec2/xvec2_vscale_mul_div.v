`include "vscale_md_constants.vh"
`include "vscale_ctrl_constants.vh"
`include "rv32_opcodes.vh"

module xvec2_vscale_mul_div (
		clk,
		reset,
		req_valid,
		req_ready,
		req_in_1_signed,
		req_in_2_signed,
		req_op,
		req_out_sel,
		req_in_1,
		req_in_2,
		resp_valid,
		resp_result
	);

	input clk;
	input reset;
	input req_valid;
	output req_ready;
	input req_in_1_signed;
	input req_in_2_signed;
	input [`MD_OP_WIDTH-1:0] req_op;
	input [`MD_OUT_SEL_WIDTH-1:0] req_out_sel;
	input [`VEC_XPR_LEN-1:0] req_in_1;
	input [`VEC_XPR_LEN-1:0] req_in_2;
	output resp_valid;
	output [`VEC_XPR_LEN-1:0] resp_result;

	localparam md_state_width = 2;
	localparam s_idle = 0;
	localparam s_compute = 1;
	localparam s_setup_output = 2;
	localparam s_done = 3;

	reg [md_state_width-1:0] state;
	reg [md_state_width-1:0] next_state;
	reg [`MD_OP_WIDTH-1:0] op;
	reg [`MD_OUT_SEL_WIDTH-1:0] out_sel;
	reg [`VEC_SIZE-1:0] negate_output;
	reg [`DOUBLE_XPR_LEN-1:0] a [0:`VEC_SIZE-1];
	reg [`DOUBLE_XPR_LEN-1:0] b [0:`VEC_SIZE-1];
	reg [`LOG2_XPR_LEN-1:0] counter;
	reg [`DOUBLE_XPR_LEN-1:0] result [0:`VEC_SIZE-1];

	wire [`XPR_LEN-1:0] abs_in_1 [0:`VEC_SIZE-1];
	wire [`VEC_SIZE-1:0] sign_in_1;
	wire [`XPR_LEN-1:0] abs_in_2 [0:`VEC_SIZE-1];
	wire [`VEC_SIZE-1:0] sign_in_2;

	wire [`VEC_SIZE-1:0] a_geq;
	wire [`DOUBLE_XPR_LEN-1:0] result_muxed [0:`VEC_SIZE-1];
	wire [`DOUBLE_XPR_LEN-1:0] result_muxed_negated [0:`VEC_SIZE-1];
	wire [`XPR_LEN-1:0] final_result [0:`VEC_SIZE-1];

	function [`XPR_LEN-1:0] abs_input;
		input [`XPR_LEN-1:0] data;
		input is_signed;
		begin
			abs_input = (data[`XPR_LEN - 1] == 1'b1 && is_signed)? -data : data;
		end
	endfunction

	assign req_ready = (state == s_idle);
	assign resp_valid = (state == s_done);

	generate
		genvar i;

		for(i = 0; i < `VEC_SIZE; i = i + 1) begin
			assign resp_result[(((i + 1) * `XPR_LEN) - 1):(i * `XPR_LEN)] = result[i][`XPR_LEN-1:0];

			assign abs_in_1[i] = abs_input(req_in_1[(((i + 1) * `XPR_LEN) - 1):(i * `XPR_LEN)], req_in_1_signed);
			assign abs_in_2[i] = abs_input(req_in_2[(((i + 1) * `XPR_LEN) - 1):(i * `XPR_LEN)], req_in_2_signed);

			assign sign_in_1[i] = req_in_1_signed && req_in_1[((i + 1) * `XPR_LEN) - 1];
			assign sign_in_2[i] = req_in_2_signed && req_in_2[((i + 1) * `XPR_LEN) - 1];

			assign a_geq[i] = a[i] >= b[i];
			assign result_muxed[i] = (out_sel == `MD_OUT_REM)? a[i] : result[i];
			assign result_muxed_negated[i] = negate_output[i]? -(result_muxed[i]) : result_muxed[i];
			assign final_result[i] = (out_sel == `MD_OUT_HI)? result_muxed_negated[i][`XPR_LEN+:`XPR_LEN] : result_muxed_negated[i][0+:`XPR_LEN];
		end
	endgenerate

	always @(posedge clk) begin
		if(reset) begin
			state <= s_idle;
		end else begin
			state <= next_state;
		end
	end

	always @(*) begin
		case(state)
			s_idle: next_state = (req_valid)? s_compute : s_idle;
			s_compute: next_state = (counter == 0)? s_setup_output : s_compute;
			s_setup_output: next_state = s_done;
			s_done: next_state = s_idle;
			default: next_state = s_idle;
		endcase
	end

	generate
		for(i = 0; i < `VEC_SIZE; i = i + 1) begin
			always @(posedge clk) begin
				case(state)
					s_idle:
						begin
							if(req_valid) begin
								result[i] <= 0;
								a[i] <= {`XPR_LEN'b0, abs_in_1[i]};
								b[i] <= {abs_in_2[i], `XPR_LEN'b0} >> 1;
								negate_output[i] <= (op == `MD_OP_REM)? sign_in_1[i] : sign_in_1[i] ^ sign_in_2[i];
							end
						end
					s_compute:
						begin
							b[i] <= b[i] >> 1;
							if(op == `MD_OP_MUL) begin
								if(a[i][counter])
									result[i] <= result[i] + b[i];
							end
							else begin
								b[i] <= b[i] >> 1;
								if(a_geq[i]) begin
									a[i] <= a[i] - b[i];
									result[i] <= (`DOUBLE_XPR_LEN'b1 << counter) | result[i];
								end
							end
						end
					s_setup_output:
						begin
							result[i] <= {`XPR_LEN'b0, final_result[i]};
						end
				endcase
			end
		end
	endgenerate

	always @(posedge clk) begin
		case(state)
			s_idle:
				begin
					if(req_valid) begin
						out_sel <= req_out_sel;
						op <= req_op;
						counter <= `XPR_LEN - 1;
					end
				end
			s_compute:
				begin
					counter <= counter - 1;
				end
		endcase
	end

endmodule
