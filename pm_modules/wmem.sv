
// EE 552 Final Project Spring 2023
// Written by Izzy Lau
// Defines the Filter Memory module which stores filter values

`timescale 1ns/1ns
`define OP_WEIGHT 0 // OPCODE: Send to PPE modules
`define OP_WEIGHTS_DONE 0
`define OP_TIMESTEP_DONE 15 
`define WEIGHT_WIDTH 8
`define SUM_WIDTH 13
`define NUM_WEIGHTS 5 // local storage upper bound
`define NUM_INPUTS 25
`define IMEM_ID 11


import SystemVerilogCSP::*;

module wmem (interface load_start, interface filter_addr, interface filter_data, 
      interface load_done, interface router_in, interface router_out);

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
    parameter FL = 12;
    parameter BL = 4;

    logic [ADDR_START:0] packet;
	logic [`WEIGHT_WIDTH-1:0] filter_mem [((`NUM_WEIGHTS)*(`NUM_WEIGHTS))-1:0];

    logic ls, ld = 0;

    logic [WIDTH_addr-1:0] f_addr;
    logic [`WEIGHT_WIDTH-1:0] f_data;

    logic[3:0] current_PPE = 5;
    logic[1:0] ts = 1;

    // Initialization: Store inputs for both timesteps
    always begin 
        load_start.Receive(ls);
        #BL;

        if(ls) begin
            // Begin storing filters in the memory
            for(int i = 0; i < `NUM_WEIGHTS * `NUM_WEIGHTS; i++) begin
                filter_addr.Receive(f_addr);
                filter_data.Receive(f_data);
                filter_mem[f_addr] = f_data;
                $display("Received f_addr=%d, f_data=%d", f_addr, f_data);
                #BL;
            end
        end
        load_done.Receive(ld);
        #BL;



        // Send weights to PE

     
        for(int i = 0; i < FILTER_SIZE * FILTER_SIZE; i+=5) begin
            packet = 0;
            packet[ADDR_START:ADDR_END] = current_PPE;
            packet[OPCODE_START:OPCODE_END] = `OP_WEIGHT;
            packet[DATA_START:DATA_END] = {filter_mem[i+2], filter_mem[i+1], filter_mem[i]};
            $display("Sending data = %d, %d, %d to PPE=%d", filter_mem[i], filter_mem[i+1], filter_mem[i+2], current_PPE);
            router_out.Send(packet); // send first 3 weights
            #FL;
            
            packet[DATA_START:DATA_END] = {filter_mem[i+4], filter_mem[i+3]};
            $display("Sending data = %d, %d to PPE=%d", filter_mem[i+3], filter_mem[i+4], current_PPE);
            router_out.Send(packet);
            #FL;
	    current_PPE += 1;
		$display("i=%d", i);
        end

        // Send signal to IMEM that weights have been dispersed
        packet = 0;
        packet[ADDR_START:ADDR_END] = `IMEM_ID;
        packet[OPCODE_START:OPCODE_END] = `OP_WEIGHTS_DONE;
        packet[DATA_START:DATA_END] = 0; // irrelevant
        $display("Sending weights done packet to IMEM");
        router_out.Send(packet); // send first 3 weights
        #FL;

    end


    //Receive timestep (not needed)
    always begin
       router_in.Receive(ts);
        #BL;
    end

endmodule