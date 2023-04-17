// EE 552 Final Project â Spring 2023
// Written by Izzy Lau
// Defines the Sum PE module which aggregates partial sums

`timescale 1ns/1ns
`define OP_PARTIAL_SUM_PPE5 5
`define OP_PARTIAL_SUM_PPE6 6
`define OP_PARTIAL_SUM_PPE7 7
`define OP_PARTIAL_SUM_PPE8 8
`define OP_PARTIAL_SUM_PPE9 9
`define OP_FIRST_TIMESTEP_DONE 15
`define OP_PREVIOUS_POTENTIAL 2
`define SUM_WIDTH 13
`define OMEM_ID 12

import SystemVerilogCSP::*;

module spe_functional_block (interface dptzr_opcode, dptzr_packet_data,
 		ptzr_dest_address, ptzr_opcode, ptzr_packet_data);

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

	parameter threshold = 64;

	// Packet storage
	logic [ADDR_START:0] packet;
	logic [ADDR_START - ADDR_END:0] dest_address;
	logic [OPCODE_START - OPCODE_END:0] opcode;
	logic [DATA_START - DATA_END:0] data;
	logic [DATA_START - DATA_END:0] prev_potential_val;

	logic [4:0] OUTPUT_DIM = IFMAP_SIZE - FILTER_SIZE + 1;

	logic [13:0] temp_vals [6:0];
	
	logic [DATA_START - DATA_END:0] sum = 0;

	logic[$clog2(FILTER_SIZE):0] ctr = 0;

		//logic [9:0] cnt_for_timestep = 0;
	
	logic [1:0] ts = 1;
	logic spike;
	logic [`SUM_WIDTH-1:0] new_potential;


	// logic [`SUM_WIDTH-1:0] partial_sums [29:0]; // STORES MAX  PARTIAL SUMS PER PPE
	logic f5, f6, f7, f8, f9 = 0; // track if we have all data for the partial sum
	// logic [3:0] pe5_ptr, pe6_ptr, pe7_ptr, pe8_ptr, pe9_ptr = 0; // tracks position in the array

	 // bounded queue of max size 6 elements
	logic [`SUM_WIDTH-1:0] ppe5_sums [$];
	logic [`SUM_WIDTH-1:0] ppe6_sums [$];
	logic [`SUM_WIDTH-1:0] ppe7_sums [$];
	logic [`SUM_WIDTH-1:0] ppe8_sums [$];
	logic [`SUM_WIDTH-1:0] ppe9_sums [$];




	always begin

		$display("%m: Waiting to receive data from depacketizer");	

		// Receive depacketized data
		fork
			// dptzr_dest_address.Receive(dest_address);
			dptzr_opcode.Receive(opcode);
			dptzr_packet_data.Receive(data);
		join
		#FL;
		$display("Received data from depacketizer");

		case(opcode)
			`OP_PARTIAL_SUM_PPE5, `OP_PARTIAL_SUM_PPE6, `OP_PARTIAL_SUM_PPE7, 
				`OP_PARTIAL_SUM_PPE8, `OP_PARTIAL_SUM_PPE9: begin
					$display("SPE %d: Received partial sum = %d from PPE", opcode, data);

					// store values in the queue
					if(opcode == `OP_PARTIAL_SUM_PPE5) begin
						ppe5_sums.push_back(data);
						// f5 = 1;
					end
					else if(opcode == `OP_PARTIAL_SUM_PPE6) begin
						ppe6_sums.push_back(data);
						// f6 = 1;
					end
					else if(opcode == `OP_PARTIAL_SUM_PPE7) begin
						// ppe7_sums = {ppe7_sums, data};
						ppe7_sums.push_back(data);
						// f7 = 1;
					end
					else if(opcode == `OP_PARTIAL_SUM_PPE8) begin
						ppe8_sums.push_back(data);
						// f8 = 1;
					end
					else if(opcode == `OP_PARTIAL_SUM_PPE9) begin
						ppe9_sums.push_back(data);
						// f9 = 1;
					end

					// Aggregate the partial sums
					if(ppe5_sums.size() & ppe6_sums.size() & ppe7_sums.size() & 
							ppe8_sums.size() & ppe9_sums.size()) begin
						temp_vals[0] = ppe5_sums.pop_front();
						temp_vals[1] = ppe6_sums.pop_front();
						temp_vals[2] = ppe7_sums.pop_front();
						temp_vals[3] = ppe8_sums.pop_front();
						temp_vals[4] = ppe9_sums.pop_front();
						$display("Received all partial sums: %d + %d + %d + %d + %d", temp_vals[0], temp_vals[1], temp_vals[2], temp_vals[3], temp_vals[4]);

						sum += temp_vals[0] + temp_vals[1] + temp_vals[2] + temp_vals[3] + temp_vals[4];
						// $display("sum = %d + %d + %d + %d + %d", temp_vals[0], temp_vals[1], temp_vals[2], temp_vals[3], temp_vals[4]);
						
					// end
					

					// sum += data;
					// temp_vals[ctr] = data;
					// ctr += 1; // increase count (for 5x5 filter, we have 5 per final value)

					// Finished aggregating
					// if(ctr == 5) begin
						
						
					// no previous potential during timestep 1
					if(ts == 1) begin
						$display("No previous potential val");
						prev_potential_val = 0;
					end
					else begin
					
						// Send request for previous timestep's membrane potential to Packetizer
						$display("Sending req for residual value to packetizer");
						ptzr_dest_address.Send(4'(`OMEM_ID));
						ptzr_opcode.Send(4'({3'(PE_ID), 1'(1)}));
						ptzr_packet_data.Send(25'({3'(PE_ID), 1'(1)}));
						#BL;

						// Receive the previous potential value from depacketizer
						dptzr_opcode.Receive(opcode);
						dptzr_packet_data.Receive(data);
						#FL;

						prev_potential_val = data;
						$display("Received residual value = %d", prev_potential_val);
					end

					new_potential = 13'(prev_potential_val + sum);
					$display("Old sum = %d", sum);
					$display("New value = %d", new_potential);
					
					if(new_potential > threshold) begin
						$display("New potential exceeds threshold: %d > %d", new_potential, threshold);
						$display("spike = 1");
						spike = 1;
						new_potential = new_potential - threshold;
						$display("Residual threshold: %d", new_potential);
					end
					else begin
						$display("New potential is below threshold: %d < %d", new_potential, threshold);
						$display("spike = 0");
						spike = 0;
					end
					
					// Send new membrane potential to Packetizer
					$display("Sending new potential and spike to packetizer to send to OMEM");
					ptzr_dest_address.Send(4'(`OMEM_ID));
					ptzr_opcode.Send(4'({3'(PE_ID), 1'(0)}));
					ptzr_packet_data.Send(25'({13'(new_potential), 1'(spike)}));
					#BL;

					// ctr = 0; // reset ctr
					sum = 0; // reset sum for next set of partial sums
					// f5 = 0;
					// f6 = 0;
					// f7 = 0;
					// f8 = 0;
					// f9 = 0;
				end
			end
			`OP_FIRST_TIMESTEP_DONE: begin
						ts = 2;
			end
		endcase

	end
endmodule