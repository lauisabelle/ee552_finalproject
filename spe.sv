// EE 552 Final Project â Spring 2023
// Written by Izzy Lau
// Defines the Sum PE module which aggregates partial sums

`timescale 1ns/1ns
`define OP_PARTIAL_SUM 0
`define OP_PREVIOUS_POTENTIAL 1
`define OP_FIRST_TIMESTEP_DONE 3
`define SUM_WIDTH 13
`define OMEM_ID 10

import SystemVerilogCSP::*;

module ppe (interface in, interface out);
  // Packet Format
  // |   29 - 26    |    25   |   24 - 0 |
  // | dest address |  opcode |   data   |
  parameter ADDR_START = 29;
  parameter ADDR_END = 26;
  parameter OPCODE = 25;
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
  logic [ADDR_START - ADDR_END + 1:0] dest_address;
  logic opcode;
  logic [DATA_START - DATA_END + 1:0] data;
  logic [DATA_START - DATA_END + 1:0] prev_potential_val;

  logic [4:0] OUTPUT_DIM = IFMAP_SIZE - FILTER_SIZE + 1;
  
  logic [`SUM_WIDTH-1:0] sum = 0;
  logic[$clog2(OUTPUT_DIM):0] ctr = 0;;
  logic first_timestep_flag;
  logic spike;
  logic [SUM_WIDTH-1:0] new_potential;

  always begin

    $display("*** %m %d",$time);	
    $display("Start receiving in module %m. Simulation time = %t", $time);
    in.Receive(packet);
    $display("Finished receiving in module %m. Simulation time = %t", $time);

    #FL; 

    // Depacketize data
    dest_address = packet[ADDR_START:ADDR_END];
    opcode = packet[OPCODE];
    data = packet[DATA_START:DATA_END];

    // If a partial sum, aggregate the value
    if(opcode == `OP_PARTIAL_SUM) begin

      sum += data;
      ctr += 1; // increase count (for 5x5 filter, we have 5 per final value)

      // Finished aggregating
      if(ctr == 5) begin
        
        // First timestep --> don't request previous value
        if(first_timestep_flag) begin

          // Send partial sum to the output memory
          packet[ADDR_START:ADDR_END] = `OMEM_ID;
          packet[OPCODE] = 0; // aggregated membrane potential
          packet[DATA_START:DATA_END] = sum;

          // Communication action Send is about to start
          $display("Start sending in module %m. Simulation time = %t", $time);
          $display("Sending data = %d", data);
          out.Send(packet);
          $display("Finished sending in module %m. Simulation time = %t", $time);
          #BL;

          // ctr = 0; // reset ctr
          // sum = 0; // reset sum for next set of partial sums
        end
    
        // Second timestep --> fetch the membrane potential
        else begin
          
          // Send request for previous timestep's membrane potential
          packet[ADDR_START:ADDR_END] = `OMEM_ID;
          packet[OPCODE] = 1; // request for previous membrane potential
          packet[DATA_START:DATA_END] = 0; // dummy

          // Send the request
          out.Send(packet);

          #FL;

          // Receive the previous potential value
          out.Receive(packet);
          
          #BL;

          prev_potential_val = packet[DATA_START:DATA_END];
          new_potential = prev_potential_val + sum;

          if(new_potential > threshold) begin
            spike = 1;
            new_potential = new_potential - threshold;
          end
          else begin
            spike = 0;
          end

          // Send new potential and spike to memory
          packet[ADDR_START:ADDR_END] = `OMEM_ID;
          packet[OPCODE] = {1, PE_ID}; // 1 appended to SPE ID
          packet[DATA_START:DATA_END] = append sum and spike together somehow;


          $display("Start sending in module %m. Simulation time = %t", $time);
          $display("Sending data = %d", data);
          out.Send(packet);
          $display("Finished sending in module %m. Simulation time = %t", $time);
          #BL;
        end
        ctr = 0; // reset ctr
        sum = 0; // reset sum for next set of partial sums

      end
    end

    else if(opcode == `OP_PREVIOUS_POTENTIAL) begin
      first_timestep_flag = 0;
    end


    // else if(opcode == `OP_PREVIOUS_POTENTIAL) begin

      
    // end

  end
endmodule