// EE 552 Final Project Spring 2023
// Written by Izzy Lau
// PPE Module

`timescale 1ns/1ns
import SystemVerilogCSP::*;

`define NUM_INPUTS 25

module ppe(interface ppe_in, interface ppe_out);
    parameter PE_ID = -1;


// Depacketizer Interfaces
Channel #(.hsProtocol(P4PhaseBD), .WIDTH(4)) dptzr_dest_address (); 
Channel #(.hsProtocol(P4PhaseBD), .WIDTH(4)) dptzr_opcode (); 
Channel #(.hsProtocol(P4PhaseBD), .WIDTH(25)) dptzr_packet_data (); 

// Weight RF Interfaces
Channel #(.hsProtocol(P4PhaseBD), .WIDTH(1)) w_cmd (); 
Channel #(.hsProtocol(P4PhaseBD), .WIDTH(3)) w_waddr (); 
Channel #(.hsProtocol(P4PhaseBD), .WIDTH(8)) w_wdata (); 
Channel #(.hsProtocol(P4PhaseBD), .WIDTH(3)) w_raddr (); 
Channel #(.hsProtocol(P4PhaseBD), .WIDTH(8)) w_rdata (); 

// Input RF Interfaces
Channel #(.hsProtocol(P4PhaseBD), .WIDTH(1)) i_cmd (); 
Channel #(.hsProtocol(P4PhaseBD), .WIDTH($clog2(`NUM_INPUTS))) i_waddr (); 
Channel #(.hsProtocol(P4PhaseBD), .WIDTH(25)) i_wdata (); 
Channel #(.hsProtocol(P4PhaseBD), .WIDTH($clog2(`NUM_INPUTS))) i_raddr (); 
Channel #(.hsProtocol(P4PhaseBD), .WIDTH(1)) i_rdata (); 

// Packetizer Interfaces
Channel #(.hsProtocol(P4PhaseBD), .WIDTH(4)) ptzr_dest_address (); 
Channel #(.hsProtocol(P4PhaseBD), .WIDTH(4)) ptzr_opcode (); 
Channel #(.hsProtocol(P4PhaseBD), .WIDTH(25)) ptzr_packet_data (); 
Channel #(.hsProtocol(P4PhaseBD), .WIDTH(32)) packetizer_out (); 

// Module Declarations
depacketizer dptzr(.depacketizer_in(ppe_in), .dest_address(dptzr_dest_address), .opcode(dptzr_opcode), .packet_data(dptzr_packet_data));

ppe_functional_block #(.PE_ID(PE_ID)) ppe_fb(.w_cmd(w_cmd), .w_waddr(w_waddr), .w_wdata(w_wdata), .w_raddr(w_raddr), .w_rdata(w_rdata), 
    .i_cmd(i_cmd), .i_waddr(i_waddr), .i_wdata(i_wdata), .i_raddr(i_raddr), .i_rdata(i_rdata), 
    .dptzr_opcode(dptzr_opcode), .dptzr_packet_data(dptzr_packet_data), 
    .ptzr_dest_address(ptzr_dest_address), .ptzr_opcode(ptzr_opcode), .ptzr_packet_data(ptzr_packet_data));
    
weight_rf wrf(.command(w_cmd), .write_addr(w_waddr), .write_data(w_wdata), .read_addr(w_raddr), .read_data(w_rdata));

input_rf irf(.command(i_cmd), .write_addr(i_waddr), .write_data(i_wdata), .read_addr(i_raddr), .read_data(i_rdata));

packetizer ptzr(.dest_address(ptzr_dest_address), .opcode(ptzr_opcode), .packet_data(ptzr_packet_data), .packetizer_out(ppe_out));

endmodule