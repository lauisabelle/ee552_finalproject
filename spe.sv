// EE 552 Final Project – Spring 2023
// Written by Izzy Lau
// Defines the Sum PE module which aggregates partial sums

`timescale 1ns/1ns
`define OP_PARTIAL_SUM 0
`define OP_FIRST_TIMESTEP_DONE 15
`define OP_PREVIOUS_POTENTIAL 2
`define SUM_WIDTH 13
`define OMEM_ID 12
`define 

import SystemVerilogCSP::*;

module spe (interface in, interface out);

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
  
  logic first_timestep_flag = 1;
  logic spike;
  logic [`SUM_WIDTH-1:0] new_potential;

  always begin

    $display("*** %m %d",$time);	
    $display("Start receiving in module %m. Simulation time = %t", $time);
    in.Receive(packet);
    $display("Finished receiving in module %m. Simulation time = %t", $time);

    #FL; 

    // Depacketize data
    dest_address = packet[ADDR_START:ADDR_END];
    opcode = packet[OPCODE_START:OPCODE_END];
    data = packet[DATA_START:DATA_END];

    // If a partial sum, aggregate the value
    if(opcode == `OP_PARTIAL_SUM) begin

      sum += data;
      ctr += 1; // increase count (for 5x5 filter, we have 5 per final value)

      // Finished aggregating
      if(ctr == 5) begin

        if(first_timestep_flag) begin
          prev_potential_val = 0;
        end
        else begin
          // Send request for previous timestep's membrane potential
          packet = 0;
          packet[ADDR_START:ADDR_END] = `OMEM_ID;
          packet[OPCODE_START:OPCODE_END] = {PE_ID, 1}; // request for previous membrane potential
          packet[DATA_START:DATA_END] = {PE_ID, 1}; // dummy

          // Send the request
          out.Send(packet);
          #FL;

          // Receive the previous potential value
          in.Receive(packet);
          #BL;

          prev_potential_val = packet[0];
        end

        new_potential = prev_potential_val + sum;
        if(new_potential > threshold) begin
          spike = 1;
          new_potential = new_potential - threshold;
        end
        else begin
          spike = 0;
        end
        
        // Send new potential and spike to memory
        packet = 0;
        packet[ADDR_START:ADDR_END] = `OMEM_ID;
        packet[OPCODE_START:OPCODE_END] = {PE_ID, 0}; // 1 appended to SPE ID
        packet[13:0] = {new_potential, spike}; // spike is LSB of data packet


        $display("Start sending in module %m. Simulation time = %t", $time);
        $display("Sending data = %d", data);
        out.Send(packet);
        $display("Finished sending in module %m. Simulation time = %t", $time);
        #BL;
        
        ctr = 0; // reset ctr
        sum = 0; // reset sum for next set of partial sums
      end
    end

    else if(opcode == `OP_FIRST_TIMESTEP_DONE) begin
      first_timestep_flag = 0;
    end

  end
endmodule
