// EE 552 Final Project Spring 2023
// Written by Izzy Lau
// SPE Module

`timescale 1ns/1ns
import SystemVerilogCSP::*;

module spe(interface spe_in, interface spe_out);

    parameter ADDR_START = 32;
	parameter ADDR_END = 29;
	parameter OPCODE_START = 28;
	parameter OPCODE_END = 25;
	parameter DATA_START = 24;
	parameter DATA_END = 0;
    parameter PE_ID = -1; 

    // Depacketizer Interfaces
    Channel #(.hsProtocol(P4PhaseBD), .WIDTH(4)) dptzr_dest_address (); 
    Channel #(.hsProtocol(P4PhaseBD), .WIDTH(10)) dptzr_opcode (); 
    Channel #(.hsProtocol(P4PhaseBD), .WIDTH(40)) dptzr_packet_data (); 

    // Packetizer Interfaces
    Channel #(.hsProtocol(P4PhaseBD), .WIDTH(4)) ptzr_dest_address (); 
    Channel #(.hsProtocol(P4PhaseBD), .WIDTH(10)) ptzr_opcode (); 
    Channel #(.hsProtocol(P4PhaseBD), .WIDTH(40)) ptzr_packet_data (); 
    Channel #(.hsProtocol(P4PhaseBD), .WIDTH(40)) packetizer_out (); 

    // Module Declarations
    depacketizer dptzr(.depacketizer_in(spe_in), .dest_address(dptzr_dest_address), .opcode(dptzr_opcode), .packet_data(dptzr_packet_data));

    spe_functional_block #(.ADDR_START(ADDR_START), .ADDR_END(ADDR_END), .OPCODE_START(OPCODE_START), .OPCODE_END(OPCODE_END), 
        .DATA_START(DATA_START), .DATA_END(DATA_END), .PE_ID(PE_ID)) ppe_fb(.dptzr_opcode(dptzr_opcode), .dptzr_packet_data(dptzr_packet_data), 
        .ptzr_dest_address(ptzr_dest_address), .ptzr_opcode(ptzr_opcode), .ptzr_packet_data(ptzr_packet_data));
        
    packetizer ptzr(.dest_address(ptzr_dest_address), .opcode(ptzr_opcode), .packet_data(ptzr_packet_data), .packetizer_out(spe_out));

endmodule