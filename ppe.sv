
// EE 552 Final Project Ã¢ÂÂ Spring 2023
// Written by Izzy Lau
// Defines the Partial PE module which computes partial sums

`timescale 1ns/1ns
`define WEIGHT 0
`define INPUT 1
`define WEIGHT_WIDTH 8
`define SUM_WIDTH 13
`define NUM_WEIGHTS 5 // local storage upper bound
`define NUM_INPUTS 25
`define IMEM_ID 10

import SystemVerilogCSP::*;

module ppe (interface in, interface out);
  // Packet Format
  // |   32 - 29    |    28 - 25   |   24 - 0 |
  // | dest address |    opcode    |   data   |
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

  // Packet storage
  logic [ADDR_START:0] packet;
  logic [ADDR_START - ADDR_END:0] dest_address = 0;
  logic opcode;
  logic signed [DATA_START - DATA_END:0] data;
  logic [4:0] OUTPUT_DIM = IFMAP_SIZE - FILTER_SIZE + 1;
  logic signed [`WEIGHT_WIDTH-1:0] weights_mem [`NUM_WEIGHTS:0]; // array of MAX_NUM_WEIGHTS 8-bit elements
  logic signed [`NUM_INPUTS-1:0] inputs_mem; // array of MAX_NUM_INPUTS 1-bit elements
  logic signed [`SUM_WIDTH:0] partial_sum = 0;

  // Pointers
  logic [$clog2(`NUM_WEIGHTS) - 1:0] wstore_ptr = 0;
  logic [$clog2(`NUM_INPUTS) - 1:0] isum_ptr = 0;
  integer i, w = 0;

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

    // If a weight packet, store weights in the memory
    if(opcode == `WEIGHT) begin
      weights_mem[wstore_ptr] = data[7:0]; // weights are always 8-bit values
      weights_mem[wstore_ptr+1] = data[15:8];
	    weights_mem[wstore_ptr+2] = data[23:16];
      wstore_ptr += 3;
    end
    // Once inputs are received, start the partial sum
    else if(opcode == `INPUT) begin

      // Prepare to process the next set of inputs
      isum_ptr = 0;

      // Store received 1-bit inputs in the memory
      //inputs_mem[isum_ptr] = data;
	    inputs_mem = data;

      // Do OUTPUT_DIM number of calculations before requesting more inputs
      for(int j = 0; j < OUTPUT_DIM; j++) begin
	      partial_sum = 0;
        for(w = 0, i = isum_ptr; w < FILTER_SIZE; w++, i++) begin
          partial_sum += (inputs_mem[i] * weights_mem[w]);
        end

        // Send data to SPE
        packet[ADDR_START:ADDR_END] = dest_address;
        packet[OPCODE_START:OPCODE_END] = 4'd0; 
        packet[DATA_START:DATA_END] = partial_sum;
        dest_address = (dest_address + 1) % FILTER_SIZE; // cycle through all of the SPE's 0 - 4
        $display("Start sending in module %m. Simulation time = %t", $time);
        $display("Sending data = %d", partial_sum);
        out.Send(packet);
        $display("Finished sending in module %m. Simulation time = %t", $time);
        #BL;

        // Prepare to read the next set of data
        if(isum_ptr + 1 % OUTPUT_DIM == 0) begin
          isum_ptr = i + FILTER_SIZE; // move to the next "row" of inputs
        end
        else begin
          isum_ptr = isum_ptr + 1; // slide the window of inputs by 1
        end
      end
      packet = 0;
      // Request more inputs from I_MEM
      packet[ADDR_START:ADDR_END] = `IMEM_ID;
      packet[OPCODE_START:OPCODE_END] = PE_ID;
      packet[DATA_START:DATA_END] = 0; // irrelevant

      //Communication action Send is about to start
      $display("Start sending in module %m. Simulation time = %t", $time);
      $display("Sending data = %d", data);
      out.Send(packet);
      //Communication action Send is finished
      $display("Finished sending in module %m. Simulation time = %t", $time);
      #BL;//Backward Latency: Delay from the time data is delivered to the time next input can be accepted
      end
    end
endmodule