
// EE 552 Final Project Ã¢ÂÂ Spring 2023
// Written by Izzy Lau
// Defines the Partial PE module which computes partial sums

`timescale 1ns/1ns
`define OP_WEIGHT 0
`define OP_INPUT 1
`define OP_TIMESTEP_DONE 15

`define WEIGHT_WIDTH 8
`define SUM_WIDTH 13
`define NUM_WEIGHTS 5 // local storage upper bound
`define NUM_INPUTS 25
`define IMEM_ID 10

import SystemVerilogCSP::*;

module ppe (interface in, interface out);
  	// Packet Format
  	// |   32 - 29    |    28 - 25   |   24 - 0 |
	// | dest address |    opcode    |   data   |
	parameter ADDR_START = 32;
	parameter ADDR_END = 29;
	parameter OPCODE_START = 28;
	parameter OPCODE_END = 25;
	parameter DATA_START = 24;
	parameter DATA_END = 0;
	parameter PE_ID = -1;

	// IFMAP and Kernel sizes
	parameter FILTER_SIZE = 5;
	parameter IFMAP_SIZE = 25;

	// Handshaking
	parameter FL = 2;
	parameter BL = 2;

	// Packet storage
    logic [ADDR_START:0] packet;
    logic [OPCODE_START:OPCODE_END] opcode;
    logic signed [DATA_START - DATA_END:0] data;
    logic [4:0] OUTPUT_DIM = IFMAP_SIZE - FILTER_SIZE + 1;
	logic signed [`WEIGHT_WIDTH-1:0] weights_mem [`NUM_WEIGHTS:0]; // array of MAX_NUM_WEIGHTS 8-bit elements
	logic signed [`NUM_INPUTS-1:0] inputs_mem; // array of MAX_NUM_INPUTS 1-bit elements
	logic signed [`SUM_WIDTH:0] partial_sum = 0;

	// Pointers
	logic [$clog2(`NUM_WEIGHTS) - 1:0] wstore_ptr = 0;
	logic [$clog2(`NUM_INPUTS) - 1:0] isum_ptr = 0;
	integer i, w = 0;
	logic [1:0] ts = 1;

	logic [3:0] dest_pe = 0;

	logic [2:0] cnt_input_rows = 0; // counts num input rows received

	always begin

		$display("*** %m %d",$time);	
		$display("Start receiving in module %m. Simulation time = %t", $time);
		in.Receive(packet);
		$display("Finished receiving in module %m. Simulation time = %t", $time);

		#FL; 
		
		// Depacketize data
		opcode = packet[OPCODE_START:OPCODE_END];
		data = packet[DATA_START:DATA_END];

		case(opcode) 
			// If a weight packet, store weights in the memory
			`OP_WEIGHT: begin
					$display("OP:RECV -- WEIGHTS");
					weights_mem[wstore_ptr] = data[7:0]; // weights are always 8-bit values
					weights_mem[wstore_ptr+1] = data[15:8];
					weights_mem[wstore_ptr+2] = data[23:16];
					wstore_ptr += 3;
			end

			// Once inputs are received, start the partial sum
			`OP_INPUT: begin
					$display("OP:RECV -- INPUTS");
					// Prepare to process the next set of inputs
					isum_ptr = 0;

					// Increase count
					cnt_input_rows += 1;

					// Store received 1-bit inputs in the memory
					inputs_mem = data;

					// Do OUTPUT_DIM number of calculations before requesting more inputs
					for(int j = 0; j < OUTPUT_DIM; j++) begin
						partial_sum = 0;
						for(w = 0, i = isum_ptr; w < FILTER_SIZE; w++, i++) begin
							partial_sum += (inputs_mem[i] * weights_mem[w]);
						end

						// Send data to SPE
						packet = 0;
						packet[ADDR_START:ADDR_END] = 4'(dest_pe);
						packet[OPCODE_START:OPCODE_END] = 4'd0; 
						packet[DATA_START:DATA_END] = 25'(partial_sum);
						dest_pe = (dest_pe + 1) % FILTER_SIZE; // cycle through all of the SPE's 0 - 4
						$display("Sending partial_sum=%d to spe=%d", partial_sum, dest_pe);
						out.Send(packet);
						$display("Finished sending in module %m. Simulation time = %t", $time);
						#BL;

						// Prepare to read the next set of data
						if(isum_ptr + 1 % OUTPUT_DIM == 0) begin
							isum_ptr = i + FILTER_SIZE; // move to the next "row" of inputs
						end
						else begin
							isum_ptr = isum_ptr + 1; // slide the window of inputs by 1
						end
					end
					packet = 0;

					if(cnt_input_rows < 5) begin
						$display("Requesting more inputs from IMEM. This is ts=%d, req=%d", ts, cnt_input_rows);
						// Request more inputs from I_MEM
						packet = 0;
						packet[ADDR_START:ADDR_END] = 4'(`IMEM_ID);
						packet[OPCODE_START:OPCODE_END] = 4'(PE_ID);
						packet[DATA_START:DATA_END] = 25'(0); // irrelevant

						//Communication action Send is about to start
						$display("Start sending in module %m. Simulation time = %t", $time);
						$display("Sending data = %d", data);
						out.Send(packet);
						//Communication action Send is finished
						$display("Finished sending in module %m. Simulation time = %t", $time);
						#BL;//Backward Latency: Delay from the time data is delivered to the time next input can be accepted
					end 
			end
			`OP_TIMESTEP_DONE: begin
				$display("OP:RECV -- TIMESTEP DONE");
				ts = 2;
				cnt_input_rows = 0; // reset
			end
		endcase
	end
endmodule