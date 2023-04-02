
// EE 552 Final Project Spring 2023
// Written by Izzy Lau
// Defines the IFMAP Memory module which stores inputs and responds to input requests

`timescale 1ns/1ns
`define OP_WEIGHTS_DONE 0 // OPCODE: Can start sending inputs
`define OP_PPE_INPUT 1 // OPCODE: Code on PPE side
`define OP_PPE_5_REQ_INPUT 5 // OPCODE: PPE 5 requests more inputs
`define OP_PPE_6_REQ_INPUT 6 // OPCODE: PPE 6 requests more inputs
`define OP_PPE_7_REQ_INPUT 7 // OPCODE: PPE 7 requests more inputs
`define OP_PPE_8_REQ_INPUT 8 // OPCODE: PPE 8 requests more inputs
`define OP_PPE_9_REQ_INPUT 9 // OPCODE: PPE 9 requests more inputs
`define OP_TIMESTEP_DONE 10 // OPCODE: PPE 9 requests more inputs
`define WEIGHT_WIDTH 8
`define SUM_WIDTH 13
`define NUM_WEIGHTS 5 // local storage upper bound
`define NUM_INPUTS 25
`define IMEM_ID 10


import SystemVerilogCSP::*;

module imem (interface load_start, interface ifmap_addr, interface ifmap_data, 
        interface timestep, interface load_done, interface router_in, interface router_out);

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
    parameter WIDTH_addr = 12;

    // IFMAP and Kernel sizes
    parameter FILTER_SIZE = 5;
    parameter IFMAP_SIZE = 25;
    parameter OUTPUT_SIZE = 21;

    // Handshaking
    parameter FL = 2;
    parameter BL = 2;

    // Packet storage
    logic [ADDR_START:0] packet;
    logic [ADDR_START - ADDR_END:0] dest_address = 0;
    logic [OPCODE_START:OPCODE_END] opcode;
    logic signed [DATA_START - DATA_END:0] data;
    logic [4:0] OUTPUT_DIM = IFMAP_SIZE - FILTER_SIZE + 1;
    //logic signed [`WEIGHT_WIDTH-1:0] weights_mem [`NUM_WEIGHTS:0]; // array of MAX_NUM_WEIGHTS 8-bit elements
    //logic signed [`NUM_INPUTS-1:0] inputs_mem; // array of MAX_NUM_INPUTS 1-bit elements
    logic signed [`SUM_WIDTH:0] partial_sum = 0;

    // Pointers
  //  logic t1_mem [IFMAP_SIZE * IFMAP_SIZE : 0];
   // logic t2_mem [IFMAP_SIZE * IFMAP_SIZE : 0];

	logic [(IFMAP_SIZE*IFMAP_SIZE)-1:0]t1_mem ;
    logic [(IFMAP_SIZE*IFMAP_SIZE)-1:0]t2_mem;

    logic ls, ld;
    logic [1:0] ts;
    logic [WIDTH_addr-1:0] i_addr;
    logic i_data;

    logic beginSend = 0;

    logic [WIDTH_addr-1:0] pe5_ptr;
    logic [WIDTH_addr-1:0] pe6_ptr;
    logic [WIDTH_addr-1:0] pe7_ptr;
    logic [WIDTH_addr-1:0] pe8_ptr;
    logic [WIDTH_addr-1:0] pe9_ptr;

    logic[2:0] current_PE;

    // Initialization: Store inputs for both timesteps
    always begin 
        load_start.Receive(ls);
        #BL;

        if(ls) begin
            // Begin storing inputs in the memory

            // Timestep 1
            for(int i = 0; i < IFMAP_SIZE * IFMAP_SIZE; i++) begin
                timestep.Receive(ts);
                ifmap_addr.Receive(i_addr);
                ifmap_data.Receive(i_data);
                $display("T1: Received i_addr=%d, i_data=%d", i_addr, i_data);
                if(ts == 1) begin
                    t1_mem[i_addr] = 1'(i_data);
                    $display("t1_mem updated: %d", t1_mem[i_addr]);
                end
                else if(ts == 2) begin
                    t2_mem[i_addr] = 1'(i_data);
                end
                #BL;
            end
            
            // Timestep 2
            for(int i = 0; i < IFMAP_SIZE * IFMAP_SIZE; i++) begin
                timestep.Receive(ts);
                ifmap_addr.Receive(i_addr);
                ifmap_data.Receive(i_data);
                $display("T2: Received i_addr=%d, i_data=%d", i_addr, i_data);
                $display("ts = %d", ts);
                if(ts == 1) begin
                    t1_mem[i_addr] = 1'(i_data);
                end
                else if(ts == 2) begin
                    t2_mem[i_addr] = 1'(i_data);
                    $display("t2_mem updated: %d", t2_mem[i_addr]);
                end
                #BL;
            end
        end
	    ts = 1; // reset for sending inputs
        load_done.Receive(ld);
        #BL;
    end

    // Respond to router requests
    always begin

        router_in.Receive(packet);
        #BL;
        opcode = packet[OPCODE_START:OPCODE_END];
        $display("opcode = %d", opcode);
        // clear bits to prepare for sending
        packet = 0;
        
        case(opcode)
            `OP_WEIGHTS_DONE, `OP_TIMESTEP_DONE :  begin
                    if(opcode == `OP_TIMESTEP_DONE) begin
                        ts = 2;
                    end
                    // Send 1 row of data (25 inputs) to each of the PE modules
                    for(int i = 0; i < 5; i++) begin
                        packet[ADDR_START:ADDR_END] = i+5;
                        packet[OPCODE_START:OPCODE_END] = `OP_PPE_INPUT; 
                        if(ts == 1) begin
			                packet[DATA_START:DATA_END] = t1_mem[((i+1) * IFMAP_SIZE) - 1 -: IFMAP_SIZE];	
                        end
                        else begin
			                packet[DATA_START:DATA_END] = t2_mem[((i+1) * IFMAP_SIZE) - 1 -: IFMAP_SIZE];
                        end
                        router_out.Send(packet);
                        #FL;
                    end

                    // Initialize the pointers
                    pe5_ptr = 5 * IFMAP_SIZE;
                    pe6_ptr = 6 * IFMAP_SIZE;
                    pe7_ptr = 7 * IFMAP_SIZE;
                    pe8_ptr = 8 * IFMAP_SIZE;
                    pe9_ptr = 9 * IFMAP_SIZE;
            end
            
            `OP_PPE_5_REQ_INPUT : begin
                    packet[ADDR_START:ADDR_END] = `OP_PPE_5_REQ_INPUT; // SEND BACK TO WHERE IT CAME FROM
                    packet[OPCODE_START:OPCODE_END] = `OP_PPE_INPUT; 
                    $display("ptr = %d", pe5_ptr);
                    if(ts == 1) begin
                        $display("val = %b", t1_mem[(pe5_ptr + 24) -: IFMAP_SIZE]);
                        packet[DATA_START:DATA_END] = t1_mem[(pe5_ptr + 24) -: IFMAP_SIZE];
                    end
                    else begin
                        $display("val = %b", t2_mem[(pe5_ptr + 24) -: IFMAP_SIZE]);
                        packet[DATA_START:DATA_END] = t2_mem[(pe5_ptr + 24) -: IFMAP_SIZE];
                    end
                    router_out.Send(packet);
                    #FL;

                    pe5_ptr += 5 * IFMAP_SIZE; // prepare for next set
            end

            `OP_PPE_6_REQ_INPUT : begin
                    packet[ADDR_START:ADDR_END] = `OP_PPE_6_REQ_INPUT;
                    packet[OPCODE_START:OPCODE_END] = `OP_PPE_INPUT; 
                    $display("ptr = %d", pe6_ptr);
                    if(ts == 1) begin
                        $display("val = %b", t1_mem[(pe6_ptr + 24) -: IFMAP_SIZE]);
			            packet[DATA_START:DATA_END] = t1_mem[(pe6_ptr + 24) -: IFMAP_SIZE];
                    end
                    else begin
                        $display("val = %b", t2_mem[(pe6_ptr + 24) -: IFMAP_SIZE]);
			            packet[DATA_START:DATA_END] = t2_mem[(pe6_ptr + 24) -: IFMAP_SIZE];
                    end
                    router_out.Send(packet);
                    #FL;

                    pe6_ptr += 5 * IFMAP_SIZE; // prepare for next set
            end

            `OP_PPE_7_REQ_INPUT : begin
                    packet[ADDR_START:ADDR_END] = `OP_PPE_7_REQ_INPUT;
                    packet[OPCODE_START:OPCODE_END] = `OP_PPE_INPUT; 
                    $display("ptr = %d", pe7_ptr);
                    if(ts == 1) begin
                        $display("val = %b", t1_mem[(pe7_ptr + 24) -: IFMAP_SIZE]);
			            packet[DATA_START:DATA_END] = t1_mem[(pe7_ptr + 24) -: IFMAP_SIZE];
                    end
                    else begin
                        $display("val = %b", t2_mem[(pe7_ptr + 24) -: IFMAP_SIZE]);
			            packet[DATA_START:DATA_END] = t2_mem[(pe7_ptr + 24) -: IFMAP_SIZE];
                    end
                    router_out.Send(packet);
                    #FL;

                    pe7_ptr += 5 * IFMAP_SIZE; // prepare for next set
            end

            `OP_PPE_8_REQ_INPUT : begin
                    packet[ADDR_START:ADDR_END] = `OP_PPE_8_REQ_INPUT;
                    packet[OPCODE_START:OPCODE_END] = `OP_PPE_INPUT; 
                    $display("ptr = %d", pe8_ptr);
                    if(ts == 1) begin
                        $display("val = %b", t1_mem[(pe8_ptr + 24) -: IFMAP_SIZE]);
			            packet[DATA_START:DATA_END] = t1_mem[(pe8_ptr + 24) -: IFMAP_SIZE];
                    end
                    else begin
                        $display("val = %b", t2_mem[(pe8_ptr + 24) -: IFMAP_SIZE]);
                        packet[DATA_START:DATA_END] = t2_mem[(pe8_ptr + 24) -: IFMAP_SIZE];
                    end
                    router_out.Send(packet);
                    #FL;

                    pe8_ptr += 5 * IFMAP_SIZE; // prepare for next set
            end

            `OP_PPE_9_REQ_INPUT : begin
                    packet[ADDR_START:ADDR_END] = `OP_PPE_9_REQ_INPUT;
                    packet[OPCODE_START:OPCODE_END] = `OP_PPE_INPUT; 
                    $display("ptr = %d", pe9_ptr);
                    if(ts == 1) begin
                        $display("val = %b", t1_mem[(pe9_ptr + 24) -: IFMAP_SIZE]);
			            packet[DATA_START:DATA_END] = t1_mem[(pe9_ptr + 24) -: IFMAP_SIZE];
                    end
                    else begin
                        $display("val = %b", t2_mem[(pe9_ptr + 24) -: IFMAP_SIZE]);
			            packet[DATA_START:DATA_END] = t2_mem[(pe9_ptr + 24) -: IFMAP_SIZE];
                    end
                    router_out.Send(packet);
                    #FL;

                    pe9_ptr += 5 * IFMAP_SIZE; // prepare for next set
            end

            // `OP_TIMESTEP_DONE : begin 
            //     ts = 2;
            //     // Initialize the pointers
            //     pe5_ptr = 5 * IFMAP_SIZE;
            //     pe6_ptr = 6 * IFMAP_SIZE;
            //     pe7_ptr = 7 * IFMAP_SIZE;
            //     pe8_ptr = 8 * IFMAP_SIZE;
            //     pe9_ptr = 9 * IFMAP_SIZE;
            // end

        endcase
    end

endmodule