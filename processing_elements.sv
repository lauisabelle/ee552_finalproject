// EE 552 Final Project – Spring 2023
// Written by Izzy Lau
// Describes the various PE elements we use in the final project

`timescale 1ns/1ns
`define weight 0
`define input 1

import SystemVerilogCSP::*;


//Copy module
module pe_partial (interface in, interface out1, interface out2);
  // parameterizes the packet format
  // |   22 - 19    |    18 - 14     |   13   | 12 - 0 |
  // | dest address | final dest idx | opcode | data   |
  parameter ADDR_START = 22;
  parameter ADDR_END = 19;
  parameter IDX_START = 18;
  parameter IDX_END = 18;
  parameter OPCODE = 13;
  parameter DATA_START = 12;
  parameter DATA_END = 0;

  parameter FILTER_SIZE = 5;
  parameter IFMAP_SIZE = 25;
  parameter MAX_NUM_WEIGHTS = 32;
  parameter MAX_NUM_INPUTS = 32;

  parameter FL = 2;
  parameter BL = 2;

  
  parameter WEIGHT_WIDTH = 8
  parameter SUM_WIDTH = 13;

  // parameter KERNEL_SIZE = 5;
  // parameter DEST_PE_ID = -1; // indicates the PE that will aggregate this partial sum
  


  logic NUM_WEIGHTS = FILTER_SIZE;
  logic OUTPUT_SIZE = IFMAP_SIZE - FILTER+SIZE + 1
  logic NUM_INPUTS = OUTPUT_SIZE * OUTPUT_SIZE;
  

  logic signed [WEIGHT_WIDTH-1:0] weights_mem [MAX_NUM_WEIGHTS:0]; // array of MAX_NUM_WEIGHTS 8-bit elements
  logic signed [MAX_NUM_INPUTS:0] inputs_mem; // array of MAX_NUM_INPUTS 1-bit elements

  logic [ADDR_START:0] packet;
  logic [ADDR_START - ADDR_END + 1:0] dest_address;
  logic [IDX_START - IDX_END + 1: 0] output_idx;
  logic opcode;
  logic signed [DATA_START - DATA_END + 1:0] data;

  logic signed [SUM_WIDTH:0] partial_sum;
  logic [$clog2(OUTPUT_SIZE):0] ctr = 0; // couts where we are in the partial sum and how to wrap aroud in the input memory

  // pointers for the weight and input memory
  logic [$clog2(MAX_NUM_WEIGHTS) - 1:0] wstore_ptr = 0;
  logic [$clog2(MAX_NUM_INPUTS) - 1:0] i_storeptr = 0;

  logic [$clog2(MAX_NUM_INPUTS) - 1:0] isum_ptr = 0

  /* Operation

  Weights
  - If a weight packet is received, store it in the weight memory
  - We have 5 weights per partial PE (PPE), but we assume 2 weights are distributed per receive(simplified)
  - The 6th weight is dummy data (0)
  - Do not start processing inputs until the weighst are all received

  Weight Filter (each index is 8 bits)
  | 0  | 1  | 2  | 3  | 4  |
  | 5  | 6  | 7  | 8  | 9  |
  | 10 | 11 | 12 | 13 | 14 |
  | 15 | 16 | 17 | 18 | 19 |

  Weight Memory Format: stores 5 8-bit weights
              | 39 - 32    | 31 - 24 | 23 - 16 | 15 - 8 | 7 - 0 |

  For SPE 1:  | Weight 4 | Weight 3 | Weight 2 | Weight 1 | Weight 0 | 



  Inputs
  - If an input packet is received, store it in the input memory
    - We can receive 16 inputs per input packet
    - For a 25x25 ifmap, we may receive inputs across multiple rows in a single packet
    - When the input memory is full, we will overwrite starting at the top (like a circular FIFO)
  - Do the next input computation marked by the input pointer
  - Note: Inputs may be received at any time (though in a sequential order), so we track the curent input with a pointer

  */

  
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

  // If a weigh packet, store both weights in the memory
  if(opcode == weight) begin
    weights_mem[wstore_ptr] = data[7:0]; // weights are always 8-bit values
    weights_mem[wstore_ptr+1] = data[15:8];
    wstore_ptr += 2;
  end
  else if(opcode == input) begin

    // Store inputs in the memory
    // Check for size (limited to only 32 inputs at a time)
    inputs_mem[iptr] = data;
    istore_ptr += (DATA_END - DATA_START + 1) // packet contains many 1-bit inputs


    // Can compute partial sum since all weights have been received
    if(wptr == (FILTER_SIZE * WEIGHT_WIDTH)) begin
        // Extract subset of current weights
         // Compute the partial sum
        for(int wptr = 0, iptr = isum_ptr; iptr < KERNEL_SIZE; w++, i++) begin
          partial_sum += (inputs_mem[iptr] * weights_mem[wptr]); // can sub i, j for wptr iptr? Should I update them?
        end

    end
    
    if(ctr+1 % OUTPUT_SIZE == 0) begin
      ctr = 0; // move to the next "row" of inputs
      iptr = (iptr + FILTER_SIZE) % 32; // move to the next "row" of inputs
    end
    else begin
      iptr = (iptr + 1) % 32; // slide the window of inputs by 1
    end
   
   









    // Repacketize data
    packet[ADDR_END:ADDR_START] = DEST_PE_ID;
    // output_idx = packet[IDX_END:IDX_START]; STAYS THE SAME
    packet[OPCODE] = 0; // irrelevant for the combining PE, use 0 as dummy
    packet[DATA_END:DATA_START] = partial_sum;

      //Communication action Send is about to start
    $display("Start sending in module %m. Simulation time = %t", $time);
    $display("Sending data = %d", data);
    fork
      out.send(packet);
    join
    //Communication action Send is finished
    $display("Finished sending in module %m. Simulation time = %t", $time);
    #BL;//Backward Latency: Delay from the time data is delivered to the time next input can be accepted
    end
  end
endmodule
