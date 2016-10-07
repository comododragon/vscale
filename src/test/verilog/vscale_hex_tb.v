`include "vscale_ctrl_constants.vh"
`include "vscale_csr_addr_map.vh"

`define STDIN 32'h80000000
`define STDERR 32'h80000002

module vscale_hex_tb();

	localparam hexfile_words = 8192;

	reg clk;
	reg reset;

	wire htif_pcr_resp_valid;
	wire [`HTIF_PCR_WIDTH-1:0] htif_pcr_resp_data;

	reg [255:0] reason = 0;
	reg [1023:0] loadmem = 0;
	reg [1023:0] vpdfile = 0;
	reg [63:0] max_cycles = 0;
	reg [63:0] trace_count = 0;

	reg [127:0] hexfile [hexfile_words-1:0];

	integer simControlInteractivity;
	integer simControlReadChar;
	integer simControlReadInt;
	integer simControlReadInt2;
	integer simControlReadInt3;
	integer simControlFreezeClk = 0;
	integer simControlDummyOutput;
	integer simControlAux;
	integer simControlAux2;

	task consumeTrailingCharacters;
		integer readChar;
		begin
			readChar = $fgetc(`STDIN);

			while(readChar != 'hA)
				readChar = $fgetc(`STDIN);
		end
	endtask

	task pressToContinue;
		input integer level;
		integer readChar;
		integer i;
		begin
			for(i = 0; i < level; i = i + 1)
				$write(">");

			$write(" Press ENTER to continue...");

			readChar = $fgetc(`STDIN);
			if(readChar != 'hA)
				consumeTrailingCharacters;
		end
	endtask

	vscale_sim_top DUT (
		.clk(clk & !simControlFreezeClk),
		.reset(reset),
		.htif_pcr_req_valid(1'b1),
		.htif_pcr_req_ready(),
		.htif_pcr_req_rw(1'b0),
		.htif_pcr_req_addr(`CSR_ADDR_TO_HOST),
		.htif_pcr_req_data(`HTIF_PCR_WIDTH'b0),
		.htif_pcr_resp_valid(htif_pcr_resp_valid),
		.htif_pcr_resp_ready(1'b1),
		.htif_pcr_resp_data(htif_pcr_resp_data)
	);

	initial begin
		$display(">> VScale Interactive Simulation");
		$display(">> Select simulation mode:");
		$display(">> \t0: Silent");
		$display(">> \t1: Interactive");
		$display(">> \tq: Quit");

		$write(">> Your destiny: ");
		simControlReadChar = $fgetc(`STDIN);

		if(simControlReadChar != 'hA)
			consumeTrailingCharacters;

		case (simControlReadChar)
			'h30:
				simControlInteractivity = 0;
			'h31:
				simControlInteractivity = 1;
			'h71:
				begin
					$display(">> Sayonara bai bai!");
					$finish;
				end
			default:
				begin
					$display(">> Invalid option. Sayonara bai bai!");
					$finish;
				end
		endcase
	end

	initial begin
		clk = 0;
		reset = 1;
	end

	always #5 clk = !clk;

	integer i = 0;
	integer j = 0;

	initial begin
		if(!$value$plusargs("max-cycles=%d", max_cycles)) begin
			$fdisplay(`STDERR, ">> FAILED: No max-cycles specified");
			$finish;
		end
		if(!$value$plusargs("loadmem=%s", loadmem)) begin
			$fdisplay(`STDERR, ">> FAILED: No loadmem specified");
			$finish;
		end
		if(!$value$plusargs("vpdfile=%s", vpdfile)) begin
			$fdisplay(`STDERR, ">> FAILED *** No vpdfile specified");
			$finish;
		end
		if(loadmem) begin
			$readmemh(loadmem, hexfile);
			for(i = 0; i < hexfile_words; i = i + 1) begin
				for(j = 0; j < 4; j = j + 1) begin
					DUT.hasti_mem.mem[4 * i + j] = hexfile[i][32 * j +: 32];
				end
			end
		end
		$dumpfile(vpdfile);
		$dumpvars(1, DUT);
		#100 reset = 0;
	end

	always @(negedge clk) begin
		if(!reset) begin
			if(simControlInteractivity) begin
				$display(">> PC_IF = 0x%08x\tPC_DX = 0x%08x\tPC_WB = 0x%08x", DUT.vscale.pipeline.PC_IF, DUT.vscale.pipeline.PC_DX, DUT.vscale.pipeline.PC_WB);
				$display(">> Interaction:");
				$display(">> \tr: Read a register");
`ifdef XVEC
				$display(">> \tv: Read register vector");
`endif
				$display(">> \tw: Manipulate a register");
				$display(">> \tt: Read from memory");
				$display(">> \te: Write memory");
				$display(">> \tq: Quit simulation");

				$write(">> Your destiny (simply ENTER to continue simulation): ");
				simControlReadChar = $fgetc(`STDIN);

				if(simControlReadChar != 'hA) begin
					consumeTrailingCharacters;
					simControlFreezeClk = 1'b1;
				end
				else begin
					simControlFreezeClk = 1'b0;
				end

				case(simControlReadChar)
					'h72:
						begin
							$display(">>> Read a register:");
							$display(">>> \t0-31: General-purpose registers 0-31");
							$display(">>> \t-1: All general-purpose registers");
							$display(">>> \t-2: All control status registers");
							$display(">>> \t-3: All registers");
							$display(">>> \tElse: Return");

							$write(">>> Your destiny: ");
							simControlDummyOutput = $fscanf(`STDIN, "%d", simControlReadInt);
							consumeTrailingCharacters;

							if(-1 == simControlReadInt) begin
								for(simControlAux = 0; simControlAux < 32; simControlAux = simControlAux + 4) begin
`ifndef XVEC
									$write(">>>> r%02d: 0x%08x\t", simControlAux,
																	DUT.vscale.pipeline.regfile.data[simControlAux]);
									$write(">>>> r%02d: 0x%08x\t", simControlAux + 1,
																	DUT.vscale.pipeline.regfile.data[simControlAux + 1]);
									$write(">>>> r%02d: 0x%08x\t", simControlAux + 2,
																	DUT.vscale.pipeline.regfile.data[simControlAux + 2]);
									$write(">>>> r%02d: 0x%08x", simControlAux + 3,
																	DUT.vscale.pipeline.regfile.data[simControlAux + 3]);
`else
									$write(">>>> r%02d: 0x%08x\t", simControlAux,
																	DUT.vscale.pipeline.regfile.data[simControlAux][1]);
									$write(">>>> r%02d: 0x%08x\t", simControlAux + 1,
																	DUT.vscale.pipeline.regfile.data[simControlAux + 1][1]);
									$write(">>>> r%02d: 0x%08x\t", simControlAux + 2,
																	DUT.vscale.pipeline.regfile.data[simControlAux + 2][1]);
									$write(">>>> r%02d: 0x%08x", simControlAux + 3,
																	DUT.vscale.pipeline.regfile.data[simControlAux + 3][1]);
`endif
									$write("\n");
								end

								pressToContinue(4);
							end
							else if(-2 == simControlReadInt) begin
								$display(">>>> TO BE IMPLEMENTED!");
							end
							else if(-3 == simControlReadInt) begin
								$display(">>>> TO BE IMPLEMENTED!");
							end
							else if(simControlReadInt >= 0 && simControlReadInt < 32) begin
`ifndef XVEC
								$display(">>>> r%02d: 0x%08x", simControlReadInt, DUT.vscale.pipeline.regfile.data[simControlReadInt]);
`else
								$display(">>>> r%02d: 0x%08x", simControlReadInt, DUT.vscale.pipeline.regfile.data[simControlReadInt][1]);
`endif

								pressToContinue(4);
							end
						end
`ifdef XVEC
					'h76:
						begin
							$display(">>> Read a register:");
							$display(">>> \t0-3: Register vector 0-3");
							$display(">>> \t-1: All vectors");
							$display(">>> \tElse: Return");

							$write(">>> Your destiny: ");
							simControlDummyOutput = $fscanf(`STDIN, "%d", simControlReadInt);
							consumeTrailingCharacters;

							if(-1 == simControlReadInt) begin
								for(simControlAux = 0; simControlAux < 4; simControlAux = simControlAux + 1) begin
									$write(">>>> VECTOR %02d =========\n", simControlAux);

									for(simControlAux2 = 0; simControlAux2 < 32; simControlAux2 = simControlAux2 + 4) begin
										$write(">>>> r%02d: 0x%08x\t", simControlAux2,
													DUT.vscale.pipeline.regfile.data[simControlAux2][simControlAux]);
										$write(">>>> r%02d: 0x%08x\t", simControlAux2 + 1,
													DUT.vscale.pipeline.regfile.data[simControlAux2 + 1][simControlAux]);
										$write(">>>> r%02d: 0x%08x\t", simControlAux2 + 2,
													DUT.vscale.pipeline.regfile.data[simControlAux2 + 2][simControlAux]);
										$write(">>>> r%02d: 0x%08x", simControlAux2 + 3,
													DUT.vscale.pipeline.regfile.data[simControlAux2 + 3][simControlAux]);
										$write("\n");
									end

									$write(">>>> ===================\n");
								end

								pressToContinue(4);
							end
							else if(simControlReadInt >= 0 && simControlReadInt < 4) begin
								for(simControlAux = 0; simControlAux < 32; simControlAux = simControlAux + 4) begin
									$write(">>>> r%02d: 0x%08x\t", simControlAux,
													DUT.vscale.pipeline.regfile.data[simControlAux][simControlReadInt]);
									$write(">>>> r%02d: 0x%08x\t", simControlAux + 1,
													DUT.vscale.pipeline.regfile.data[simControlAux + 1][simControlReadInt]);
									$write(">>>> r%02d: 0x%08x\t", simControlAux + 2,
													DUT.vscale.pipeline.regfile.data[simControlAux + 2][simControlReadInt]);
									$write(">>>> r%02d: 0x%08x", simControlAux + 3,
													DUT.vscale.pipeline.regfile.data[simControlAux + 3][simControlReadInt]);
									$write("\n");
								end

								pressToContinue(4);
							end
						end
`endif
					'h77:
						begin
							$display(">>> Manipulate a register:");
							$display(">>> \t0-31: General-purpose registers 0-31");
							$display(">>> \tElse: Return");

							$write(">>> Your destiny: ");
							simControlDummyOutput = $fscanf(`STDIN, "%d", simControlReadInt);
							consumeTrailingCharacters;

							if(simControlReadInt > 0 && simControlReadInt < 32) begin
								$write(">>>> Value (as hex w/o 0x): ");
								simControlDummyOutput = $fscanf(`STDIN, "%x", simControlReadInt2);
								consumeTrailingCharacters;

								$display(">>>> Setting 0x%08x at r%02d", simControlReadInt2, simControlReadInt);
`ifndef XVEC
								DUT.vscale.pipeline.regfile.data[simControlReadInt] = simControlReadInt2;
`else
								DUT.vscale.pipeline.regfile.data[simControlReadInt][1] = simControlReadInt2;
`endif

								pressToContinue(4);
							end
						end
					'h74:
						begin
							$display(">>> Read memory:");

							$write(">>> Start byte address (in hex w/o 0x): ");
							simControlDummyOutput = $fscanf(`STDIN, "%x", simControlReadInt);
							consumeTrailingCharacters;

							$write(">>> End byte address (in hex w/o 0x): ");
							simControlDummyOutput = $fscanf(`STDIN, "%x", simControlReadInt2);
							consumeTrailingCharacters;

							if((simControlReadInt >= 0 && simControlReadInt < (16 * hexfile_words)) &&
								(simControlReadInt2 >= 0 && simControlReadInt2 < (16 * hexfile_words))) begin
								$display(">>>>        addr    3 2 1 0");
								for(simControlAux = simControlReadInt; simControlAux <= simControlReadInt2; simControlAux = simControlAux + 4) begin
								$display(">>>> 0x%08x: 0x%08x", simControlAux, DUT.hasti_mem.mem[simControlAux >> 2]);
								end

								pressToContinue(4);
							end
						end
					'h65:
						begin
							$display(">>> TO BE IMPLEMENTED!");
						end
					'h71:
						begin
							$display(">>> Sayonara bai bai!");
							$finish;
						end
				endcase
			end
		end
	end

	always @(posedge clk) begin
		trace_count = trace_count + 1;

		if(max_cycles > 0 && trace_count > max_cycles)
		  reason = "timeout";

		if(!reset) begin
			if(htif_pcr_resp_valid && htif_pcr_resp_data != 0) begin
				if(htif_pcr_resp_data == 1)
					$finish;
				else
					$sformat(reason, "tohost = %d", htif_pcr_resp_data >> 1);
			end
		end

		if(reason) begin
			$fdisplay(`STDERR, ">> FAILED (%s) after %d simulation cycles", reason, trace_count);
			$finish;
		end
	end

endmodule
