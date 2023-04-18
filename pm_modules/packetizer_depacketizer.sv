// EE 552 Final Project Spring 2023
// Written by Izzy Lau
// Defines the packetizer and depacketizer modules used in the PE and memory modules

`timescale 1ns/1ns
import SystemVerilogCSP::*;

module packetizer(interface dest_address, interface opcode, interface packet_data, interface packetizer_out);
	parameter ADDR_START = 32;
	parameter ADDR_END = 29;
	parameter OPCODE_START = 28;
	parameter OPCODE_END = 25;
	parameter DATA_START = 24;
	parameter DATA_END = 0;
	parameter BL = 1;


	logic [ADDR_START:0] packet;

    logic [OPCODE_START-OPCODE_END:0] op;
    logic signed [DATA_START-DATA_END:0] data;
	logic [ADDR_START-ADDR_END:0] addr;
	logic dn;

	always begin

		// Receive data to packetize
		dest_address.Receive(addr);
		opcode.Receive(op);
		packet_data.Receive(data);

		// Store data in packet
		packet[ADDR_START:ADDR_END] = addr;
		packet[OPCODE_START:OPCODE_END] = op;
		packet[DATA_START:DATA_END] = data;
	
		// Send data out
		$display("%m: Received data=%b to send to router", packet);
		packetizer_out.Send(packet);
		$display("%m: Sent data");

		#BL;
	end

endmodule



module depacketizer(interface depacketizer_in, interface dest_address, interface opcode, interface packet_data);
	parameter ADDR_START = 32;
	parameter ADDR_END = 29;
	parameter OPCODE_START = 28;
	parameter OPCODE_END = 25;
	parameter DATA_START = 24;
	parameter DATA_END = 0;
	parameter FL = 1;


	logic [ADDR_START:0] packet;

	always begin
		$display("Preparing to receive packet in %m");
		depacketizer_in.Receive(packet);
		$display("Received packet=%b in %m", packet);

		#FL; 
		
		fork
			// dest_address.Send(packet[ADDR_START:ADDR_END]);
			opcode.Send(packet[OPCODE_START:OPCODE_END]);
			packet_data.Send(packet[DATA_START:DATA_END]);
		join
		$display("%m: Sent opcode and packet data to PPE FB");
	end

endmodule

