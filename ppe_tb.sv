// EE 552 Final Project – Spring 2023
// Written by Izzy Lau
// Describes the various PE elements we use in the final project

`timescale 1ns/1ns
import SystemVerilogCSP::*;

module ppe_tb;
  parameter ADDR_START = 29;
  parameter ADDR_END = 26;
  parameter OPCODE = 25;
  parameter FL = 4;
  parameter BL = 2;

    //Interface Vector instatiation: 4-phase bundled data channel
    Channel #(.hsProtocol(P4PhaseBD), .WIDTH(10)) intf  [1:0] (); 
  
    ppe ppe_mod(.in(intf[0]), .out(intf[1]));

    logic [ADDR_START:0] packet;
    packet[ADDR_START:ADDR_END] = 5; 
    packet[OPCODE] = 0; 
    packet[23:16] = 0; 
    packet[15:8] = 1; 
    packet[7:0] = 2; 

    always begin
      // create first weight packet
      packet[ADDR_START:ADDR_END] = 5;
      packet[OPCODE] = 0; 
      packet[23:16] = 0; 
      packet[15:8] = 1; 
      packet[7:0] = 2;

      intf[0].Send(packet);
      #FL;
      

      // create second weight packet
      packet[ADDR_START:ADDR_END] = 5; 
      packet[OPCODE] = 0; 
      packet[23:16] = 3; 
      packet[15:8] = 4; 
      packet[7:0] = 5; // dummy val since discarded

      intf[0].Send(packet);
      #FL;


      // create string of inputs
      logic [24:0] data;
      for(int i = 0; i < 25; i++) begin
        data[i] = i;
      end

      packet[ADDR_START:ADDR_END] = 5; 
      packet[OPCODE] = 1; // input 
      packet[24:0] = data;

      intf[0].Send(packet);
      #FL;

      intf[1].Receive();

    end


endmodule