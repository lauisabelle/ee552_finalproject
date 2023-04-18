
// EE 552 Final Project Spring 2023
// Written by Izzy Lau
// Defines the Partial PE module which computes partial sums

`timescale 1ns/1ns
`define OP_WEIGHT 0
`define OP_INPUT 1

`define OP_HAS_INPUTS 2
`define OP_DOES_NOT_HAVE_INPUTS 3

`define OP_REQ_INPUTS 4

`define OP_TIMESTEP_DONE 15



`define WEIGHT_WIDTH 8
`define SUM_WIDTH 13
`define NUM_WEIGHTS 5 // local storage upper bound
`define NUM_INPUTS 25
`define IMEM_ID 11

`define WRITE_CMD 0
`define READ_CMD  1

import SystemVerilogCSP::*;

module weight_rf(interface command, interface write_addr, interface write_data, interface read_addr, interface read_data);
	parameter BL = 2;
	parameter FL = 2;
	
	logic cmd;
	logic [`WEIGHT_WIDTH-1:0] weights_mem [`NUM_WEIGHTS:0]; // array of MAX_NUM_WEIGHTS 8-bit elements
	logic [`WEIGHT_WIDTH-1:0] weight;
	logic [$clog2(`NUM_WEIGHTS) - 1:0] waddr;
	logic [$clog2(`NUM_WEIGHTS) - 1:0] raddr;
	
	always begin
		$display("%m: Waiting to receive cmd from functional block");
		command.Receive(cmd); // receive read, write command
		$display("%m: Received command");
		#FL;
		case(cmd)
			`WRITE_CMD: begin
				// write 3 weights to memory
				for(int i = 0; i < 3; i+=1) begin
					write_addr.Receive(waddr);
					write_data.Receive(weight);
					#FL;
					$display("Storing weight = %d at address=%d", weight, waddr);
					
					weights_mem[waddr] = weight; // weights are always 8-bit values
				end
			end

			`READ_CMD: begin
				// receive weight request and send along channel
				read_addr.Receive(raddr);
				#FL;
				$display("Sending weight = %d at address=%d", weights_mem[raddr], raddr);
				read_data.Send(weights_mem[raddr]);
				#BL;
			end
		endcase
	end
endmodule


module input_rf(interface command, interface write_data, interface write_addr, interface read_addr, interface read_data);
	parameter BL = 2;
	parameter FL = 2;
	
	logic cmd;
	logic [`NUM_INPUTS-1:0] inputs_mem; // array of MAX_NUM_INPUTS 1-bit elements
	logic [`NUM_INPUTS-1:0] inputs;
	logic [$clog2(`NUM_INPUTS) - 1:0] raddr;

	always begin

		command.Receive(cmd); // receive read, write command
		#FL;
		case(cmd)
			`WRITE_CMD: begin
				// write 25 inputs to memory
				write_data.Receive(inputs);
				inputs_mem = inputs;
				#FL;
			end

			`READ_CMD: begin
				read_addr.Receive(raddr);
				#FL;
				read_data.Send(inputs_mem[raddr]);
				#BL;
			end
		endcase
	end

endmodule

module ppe_functional_block(interface w_cmd, w_waddr, w_wdata, w_raddr, w_rdata,
    i_cmd, i_waddr, i_wdata, i_raddr, i_rdata, 
    dptzr_opcode, dptzr_packet_data,
 	ptzr_dest_address, ptzr_opcode, ptzr_packet_data);
  	// Packet Format
  	// |   32 - 29    |    28 - 25   |   24 - 0 |
	// | dest address |    opcode    |   data   |
	parameter ADDR_START = 32;
	parameter ADDR_END = 29;
	parameter OPCODE_START = 28;
	parameter OPCODE_END = 25;
	parameter DATA_START = 24;
	parameter DATA_END = 0;
	parameter FILTER_SIZE = 5;
	parameter IFMAP_SIZE = 25;
	parameter PE_ID = -1;

	// Handshaking
	parameter FL = 2;
	parameter BL = 2;

	// Packet storage
    logic [ADDR_START:0] packet;
    logic [ADDR_START:ADDR_END] dest_address;
    logic [OPCODE_START:OPCODE_END] opcode;
    logic signed [DATA_START - DATA_END:0] data;
    logic [4:0] OUTPUT_DIM = IFMAP_SIZE - FILTER_SIZE + 1;

	logic signed [`SUM_WIDTH:0] partial_sum = 0;

	// Pointers
	logic [$clog2(`NUM_WEIGHTS) - 1:0] wstore_ptr = 0;
	logic [$clog2(`NUM_WEIGHTS) - 1:0] w = 0;
	logic [$clog2(`NUM_INPUTS) - 1:0] isum_ptr = 0;
	logic [$clog2(`NUM_INPUTS) - 1:0] i = 0;

	logic [1:0] ts = 1;
	logic [3:0] dest_pe = 0;

	logic [3:0] dest_req_pe = 0; 
	// logic [2:0] cnt_input_rows = 0; // counts num input rows received
	logic [8:0] cnt = 0;

	logic input_data;
	logic [`WEIGHT_WIDTH-1:0] weight;


	logic [5:0] curr_row_idx;
	logic [5:0] req_row_idx;

	initial begin
		curr_row_idx = PE_ID - 6; // PPE_5 initially receives input row 0, start its value at -1
	end

	
	always begin
		$display("Waiting to receive data from depacketizer");

		// Receive depacketized data
		fork
			// dptzr_dest_address.Receive(dest_address);
			dptzr_opcode.Receive(opcode);
			dptzr_packet_data.Receive(data);
		join
		#FL;
		$display("Received data from depacketizer");

		case(opcode) 
			// Send weights to Weight Register File
			`OP_WEIGHT: begin
					$display("OP:RECV -- WEIGHTS");
					w_cmd.Send(`WRITE_CMD);
					for(int i = 0; i < 3; i+=1) begin
						w_waddr.Send(wstore_ptr + i);
						w_wdata.Send(data[((i+1) * 8) - 1 -: 8]);
						#BL;
					end
					wstore_ptr += 3;
			end

			// Once inputs are received, start the partial sum
			`OP_INPUT, `OP_HAS_INPUTS: begin
					$display("OP:RECV -- INPUTS");
					
					isum_ptr = 0; // Prepare to process the next set of inputs	
					cnt += 1;				

					// Send inputs to Input Register File
					i_cmd.Send(`WRITE_CMD);
					i_wdata.Send(data);

					curr_row_idx += 1; // increase ptr tracking which row of data we have

					#BL;


					// Do OUTPUT_DIM number of calculations before requesting more inputs
					for(int j = 0; j < OUTPUT_DIM; j++) begin
						partial_sum = 0;
						for(w = 0, i = isum_ptr; w < FILTER_SIZE; w++, i++) begin
							
							// Request inputs
							i_cmd.Send(`READ_CMD);
							i_raddr.Send(i); 
							
							// Request weights
							w_cmd.Send(`READ_CMD);
							w_raddr.Send(w);
							#BL;
							
							// Receive input and weight data
							i_rdata.Receive(input_data);
							w_rdata.Receive(weight);
							#FL;

							$display("%d + (%d * %d)", partial_sum, input_data, weight);
							partial_sum += (input_data * weight);
						end

						// Send data to Packetizer, which will be forwarded to SPE
						$display("PPE %d: Sending partial sum=%d to packetizer. This is ts=%d", PE_ID, partial_sum, ts);
						ptzr_dest_address.Send(dest_pe);
						ptzr_opcode.Send(PE_ID);
						ptzr_packet_data.Send(partial_sum);
						#BL;

						dest_pe = (dest_pe + 1) % FILTER_SIZE; // cycle through all of the SPE's 0 - 4
						isum_ptr = isum_ptr + 1; // slide the window of inputs by 1
					
					end

					// Request more inputs if we haven't received 21 rows yet
					if(cnt < OUTPUT_DIM) begin
						
						// Last PE always gets inputs from MEM
						if(PE_ID == 9) begin
							$display("Requesting more inputs from IMEM. This is ts=%d", ts);
							ptzr_dest_address.Send(`IMEM_ID);
							ptzr_opcode.Send(PE_ID); // lower 4 bits of opcode is the PE_ID
							ptzr_packet_data.Send(curr_row_idx + 1); // desired row
							#BL;
						end
						else begin
							// Request data from neighbor
							$display("Requesting more inputs from NEIGHBOR. This is ts=%d", ts);
							ptzr_dest_address.Send(PE_ID + 1);
							ptzr_opcode.Send(`OP_REQ_INPUTS); // lower 4 bits of opcode is the PE_ID
							ptzr_packet_data.Send({curr_row_idx + 1, 4'(PE_ID)}); 
							#BL;
						end
					end

			end
			`OP_DOES_NOT_HAVE_INPUTS: begin

					// Send request to memory since PPE did not have the input row we need
					ptzr_dest_address.Send(`IMEM_ID);
					ptzr_opcode.Send(PE_ID); // lower 4 bits of opcode is the PE_ID
					ptzr_packet_data.Send(curr_row_idx + 1); // irrelevant
					#BL;
			end
			`OP_REQ_INPUTS: begin

				dest_req_pe = data[3:0];
				req_row_idx = data[DATA_START:4];
				// data = 0;

				// get all inputs
				for(int i = 0; i < `NUM_INPUTS; i++) begin

					i_cmd.Send(`READ_CMD);
					i_raddr.Send(i); 

					// Receive input data
					i_rdata.Receive(input_data);
					data[i] = input_data;

				end
				
				$display("PE %d: Compare my_input_row = %d vs. req_input_row = %d", PE_ID, curr_row_idx, req_row_idx);
				// we have the correct data --> send to requesting PPE
				if(req_row_idx == curr_row_idx) begin
					$display("PE %d: Matches --> my_input_row = %d vs. req_input_row = %d", PE_ID, curr_row_idx, req_row_idx);
					$display("PE %d Sending input data=%b", PE_ID, data);

					// Send input data in packet
					ptzr_dest_address.Send(dest_req_pe);
					ptzr_opcode.Send(`OP_HAS_INPUTS); // lower 4 bits of opcode is the PE_ID
					ptzr_packet_data.Send(data); 

				end
				else begin // does not have the correct data
					ptzr_dest_address.Send(dest_req_pe);
					ptzr_opcode.Send(`OP_DOES_NOT_HAVE_INPUTS); 
					ptzr_packet_data.Send(0); // irrelevant
				end

			end
			`OP_TIMESTEP_DONE: begin
				$display("OP:RECV -- TIMESTEP DONE");
				ts = 2;
				cnt = 0;
				dest_pe = 0;
				curr_row_idx = PE_ID - 6;
				// cnt_input_rows = 0; // reset
			end
		endcase
	end
endmodule