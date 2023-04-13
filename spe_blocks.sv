// EE 552 Final Project – Spring 2023
// Written by Izzy Lau
// Defines the Sum PE module which aggregates partial sums

`timescale 1ns/1ns
`define OP_PARTIAL_SUM 0
`define OP_FIRST_TIMESTEP_DONE 15
`define OP_PREVIOUS_POTENTIAL 2
`define SUM_WIDTH 13
`define OMEM_ID 12

import SystemVerilogCSP::*;

module spe_functional_block (interface in, out, 
	dptzr_opcode, dptzr_packet_data,
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
	
	logic [DATA_START - DATA_END:0] sum = 0;

	logic[$clog2(FILTER_SIZE):0] ctr = 0;

		//logic [9:0] cnt_for_timestep = 0;
	
	logic [1:0] ts = 1;
	logic spike;
	logic [`SUM_WIDTH-1:0] new_potential;

	always begin

		$display("%m: Waiting to receive data from depacketizer");	
		// $display("Start receiving in module %m. Simulation time = %t", $time);
		// in.Receive(packet);
		// $display("Finished receiving in module %m. Simulation time = %t", $time);

		// #FL; 

		// Receive depacketized data
		fork
			dptzr_opcode.Receive(opcode);
			dptzr_packet_data.Receive(data);
		join
		#FL;
		$display("Received data from depacketizer");

		// Depacketize data
		// dest_address = packet[ADDR_START:ADDR_END];
		// opcode = packet[OPCODE_START:OPCODE_END];
		// data = packet[DATA_START:DATA_END];

		case(opcode)
			`OP_PARTIAL_SUM: begin
					$display("Received partial sum = %d", data);
					sum += data;
					ctr += 1; // increase count (for 5x5 filter, we have 5 per final value)

					// Finished aggregating
					if(ctr == 5) begin
						
						// no previous potential during timestep 1
						if(ts == 1) begin
							$display("No previous potential val");
							prev_potential_val = 0;
						end
						else begin
							
							// Send request for previous timestep's membrane potential
							// packet = 0;
							// packet[ADDR_START:ADDR_END] = 4'(`OMEM_ID);
							// packet[OPCODE_START:OPCODE_END] = 4'({3'(PE_ID), 1'(1)}); // request for previous membrane potential
							// packet[DATA_START:DATA_END] = 25'({3'(PE_ID), 1'(1)}); // dummy

							// Send request for previous timestep's membrane potential to Packetizer
							$display("Sending req for residual value to packetizer");
							ptzr_dest_address.Send(4'(`OMEM_ID));
							ptzr_opcode.Send(4'({3'(PE_ID), 1'(1)}));
							ptzr_packet_data.Send(25'({3'(PE_ID), 1'(1)}));
							#BL;


							// Send the request
							// $display("Sending req for residual value");
							// out.Send(packet);
							// #FL;

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
						
						// Send new potential and spike to memory
						// packet = 0;
						// packet[ADDR_START:ADDR_END] = 4'(`OMEM_ID);
						// packet[OPCODE_START:OPCODE_END] = 4'({3'(PE_ID), 1'(0)}); // 1 appended to SPE ID
						// packet[13:0] = 25'({13'(new_potential), 1'(spike)}); // spike is LSB of data packet


						// Send request for previous timestep's membrane potential to Packetizer
						$display("Sending new potential and spike to packetizer to send to OMEM");
						ptzr_dest_address.Send(4'(`OMEM_ID));
						ptzr_opcode.Send(4'({3'(PE_ID), 1'(0)}));
						ptzr_packet_data.Send(25'({13'(new_potential), 1'(spike)}));
						#BL;


						// $display("Start sending in module %m. Simulation time = %t", $time);
						// $display("Sending data = %d", data);
						// out.Send(packet);
						// $display("Finished sending in module %m. Simulation time = %t", $time);
						// #BL;
						
						ctr = 0; // reset ctr
						sum = 0; // reset sum for next set of partial sums
					end
			end
			`OP_FIRST_TIMESTEP_DONE: begin
						ts = 2;
			end
		endcase

	end
endmodule
