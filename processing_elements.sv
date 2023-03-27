// EE 552 Final Project – Spring 2023
// Written by Izzy Lau
// Describes the various PE elements we use in the final project

`timescale 1ns/1ns
`define WEIGHT 0
`define INPUT 1
`define WEIGHT_WIDTH 8
`define SUM_WIDTH 13
`define MAX_NUM_WEIGHTS 32 // local storage upper bound
`define MAX_NUM_INPUTS 32
`define IFMAP_MEM_ID 10

import SystemVerilogCSP::*;

module pe_partial (interface in, interface out);
  // Packet Format
  // |   29 - 26    |    25   |   24 - 0 |
  // | dest address |  opcode |   data   |
  parameter ADDR_START = 29;
  parameter ADDR_END = 26;
  parameter OPCODE = 25;
  parameter DATA_START = 24;
  parameter DATA_END = 0;

  // IFMAP and Kernel sizes
  parameter FILTER_SIZE = 5;
  parameter IFMAP_SIZE = 25;

  // Handshaking
  parameter FL = 2;
  parameter BL = 2;

  // Packet storage
  logic [ADDR_START:0] packet;
  logic [ADDR_START - ADDR_END + 1:0] dest_address = 0;
  logic opcode;
  logic signed [DATA_START - DATA_END + 1:0] data;
  logic [4:0] OUTPUT_DIM = IFMAP_SIZE - FILTER_SIZE + 1
  logic signed [WEIGHT_WIDTH-1:0] weights_mem [MAX_NUM_WEIGHTS:0]; // array of MAX_NUM_WEIGHTS 8-bit elements
  logic signed [MAX_NUM_INPUTS:0] inputs_mem; // array of MAX_NUM_INPUTS 1-bit elements
  logic signed [SUM_WIDTH:0] partial_sum;

  // Pointers
  logic [$clog2(MAX_NUM_WEIGHTS) - 1:0] wstore_ptr = 0;
  logic [$clog2(MAX_NUM_INPUTS) - 1:0] isum_ptr = 0

  always begin

    $display("*** %m %d",$time);	
    $display("Start receiving in module %m. Simulation time = %t", $time);
    in.Receive(packet);
    $display("Finished receiving in module %m. Simulation time = %t", $time);

    #FL; //Forward Latency: Delay from recieving inputs to send the results forward

    // Depacketize data
    dest_address = packet[ADDR_END:ADDR_START];
    output_idx = packet[IDX_END:IDX_START];
    opcode = packet[OPCODE];
    data = packet[DATA_END:DATA_START];

    // If a weight packet, store weights in the memory
    if(opcode == WEIGHT) begin
      weights_mem[wstore_ptr] = data[7:0]; // weights are always 8-bit values
      weights_mem[wstore_ptr+1] = data[15:8];
      wstore_ptr += 2;
    end
    // Once inputs are recieve, start the partial sum
    else if(opcode == INPUT) begin

      // Prepare to process the next set of inputs
      iptr = 0;
      isum_ptr = 0;

      // Store received 1-bit inputs in the memory
      inputs_mem[iptr] = data;

      // Begin partial sum calculations
      // Calculate in increments of FILTER_SIZE
      for(int w = 0, i = isum_ptr; i < FILTER_SIZE; w++, i++) begin
        partial_sum += (inputs_mem[i] * weights_mem[w]);
      end

      // Send data to SPE
      packet[ADDR_END:ADDR_START] = dest_address;
      packet[OPCODE] = 0; // irrelevant for the combining PE, use 0 as dummy
      packet[DATA_END:DATA_START] = partial_sum;
      dest_address = (dest_address + 1) % FILTER_SIZE; // cycle through all of the SPE's 0 - 4
      $display("Start sending in module %m. Simulation time = %t", $time);
      $display("Sending data = %d", data);
      out.send(packet);
      $display("Finished sending in module %m. Simulation time = %t", $time);
      #BL;

      // Prepare to read the next set of data
      if(isum_ptr + 1 % OUTPUT_DIM == 0) begin
        isum_ptr = iptr + FILTER_SIZE; // move to the next "row" of inputs
      end
      else begin
        isum_ptr = isum_ptr + 1; // slide the window of inputs by 1
      end

      // Request more inputs from I_MEM
      packet[ADDR_END:ADDR_START] = IFMAP_MEM_ID;
      packet[OPCODE] = 0; // opcode
      packet[DATA_END:DATA_START] = 0; // irrelevant

      //Communication action Send is about to start
      $display("Start sending in module %m. Simulation time = %t", $time);
      $display("Sending data = %d", data);
      out.send(packet);
      //Communication action Send is finished
      $display("Finished sending in module %m. Simulation time = %t", $time);
      #BL;//Backward Latency: Delay from the time data is delivered to the time next input can be accepted
      end
    end
endmodule
