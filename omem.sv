// EE 552 Final Project Spring 2023
// Written by Izzy Lau
// Defines the Output Memory module which stores spikes and residual values. 
// It also synchronizes at the end of the itmestep

`timescale 1ns/1ns
`define OP_SPE_0_SEND_DATA 0 // OPCODE: SPE 0 sends residual val and spike
`define OP_SPE_1_SEND_DATA 2 // OPCODE: SPE 1 sends residual val and spike
`define OP_SPE_2_SEND_DATA 4 // OPCODE: SPE 2 sends residual val and spike
`define OP_SPE_3_SEND_DATA 6 // OPCODE: SPE 3 sends residual val and spike
`define OP_SPE_4_SEND_DATA 8 // OPCODE: SPE 4 sends residual val and spike

`define OP_SPE_0_REQ_DATA 1 // OPCODE: SPE 0 requests previous value
`define OP_SPE_1_REQ_DATA 3 // OPCODE: SPE 0 requests previous value
`define OP_SPE_2_REQ_DATA 5 // OPCODE: SPE 0 requests previous value
`define OP_SPE_3_REQ_DATA 7 // OPCODE: SPE 0 requests previous value
`define OP_SPE_4_REQ_DATA 9 // OPCODE: SPE 0 requests previous value

`define OP_TIMESTEP_DONE 15 // OPCODE: PPE 9 requests more inputs

`define WEIGHT_WIDTH 8
`define SUM_WIDTH 13
`define NUM_WEIGHTS 5 // local storage upper bound
`define NUM_INPUTS 25
`define IMEM_ID 10


import SystemVerilogCSP::*;

module omem (interface start_r, interface out_spike_data, interface out_spike_addr, 
        interface ts_r, interface layer_r, interface done_r, interface router_in, interface router_out);

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

    // Packet storage
    logic [ADDR_START:0] packet;
    logic [ADDR_START - ADDR_END:0] dest_address = 0;
    logic [OPCODE_START:OPCODE_END] opcode;
    logic signed [DATA_START - DATA_END:0] data;
    logic [4:0] OUTPUT_DIM = IFMAP_SIZE - FILTER_SIZE + 1;


	logic [(OUTPUT_SIZE*OUTPUT_SIZE)-1:0]t1_spike_mem ;
    logic [(OUTPUT_SIZE*OUTPUT_SIZE)-1:0]t2_spike_mem;

    logic [`SUM_WIDTH-1:0] t1_residue_mem [(OUTPUT_SIZE*OUTPUT_SIZE)-1:0];
    logic [`SUM_WIDTH-1:0] t2_residue_mem [(OUTPUT_SIZE*OUTPUT_SIZE)-1:0];

    logic [`SUM_WIDTH-1:0] new_potential;
    logic spike;
    logic [`SUM_WIDTH-1:0] spe_id;


    logic [WIDTH_addr-1:0] pe0_ptr = 0;
    logic [WIDTH_addr-1:0] pe1_ptr = 1;
    logic [WIDTH_addr-1:0] pe2_ptr = 2;
    logic [WIDTH_addr-1:0] pe3_ptr = 3;
    logic [WIDTH_addr-1:0] pe4_ptr = 4;

    logic [1:0] ts = 1;


    // Receive spikes, residual values, and requests for previous values
    always begin 
        router_in.Receive(packet);
        data = packet[DATA_START:DATA_END];
	    opcode = packet[OPCODE_START:OPCODE_END];

        // Even: Store data, Odd: Send data
        if(opcode % 2 == 0) begin
            new_potential = data[DATA_START:DATA_END+1];
            spike = data[DATA_END]; // spike is LSB
		    $display("Received store request, data = %b", data);
        end
        else begin
            spe_id = packet[OPCODE_START:OPCODE_END+1];
		    $display("Received send request from spe_id= %b", spe_id);
        end

        #BL;
        packet = 0;

        case(opcode)
            `OP_SPE_0_SEND_DATA :  begin
                    if(ts == 1) begin
                        $display("ts1: spike = %d", spike);
                        $display("ts1: new_potential = %d", new_potential);
                        $display("ts1: pe0_ptr = %d", pe0_ptr);
                        t1_spike_mem[pe0_ptr] = spike;
                        t1_residue_mem[pe0_ptr] = new_potential;
                    end
                    else if(ts == 2) begin
                        $display("ts1: spike = %d", spike);
                        $display("ts1: new_potential = %d", new_potential);
                        $display("ts1: pe0_ptr = %d", pe0_ptr);
                        t2_spike_mem[pe0_ptr] = spike;
                        t2_residue_mem[pe0_ptr] = new_potential;
                    end
                    pe0_ptr += 5;
            end
            `OP_SPE_1_SEND_DATA :  begin
                    if(ts == 1) begin
                        $display("ts1: spike = %d", spike);
                        $display("ts1: new_potential = %d", new_potential);
                        $display("ts1: pe1_ptr = %d", pe1_ptr);
                        t1_spike_mem[pe1_ptr] = spike;
                        t1_residue_mem[pe1_ptr] = new_potential;
                    end
                    else if(ts == 2) begin
                        $display("ts2: spike = %d", spike);
                        $display("ts2: new_potential = %d", new_potential);
                        $display("ts2: pe1_ptr = %d", pe1_ptr);
                        t2_spike_mem[pe1_ptr] = spike;
                        t2_residue_mem[pe1_ptr] = new_potential;
                    end
                    pe1_ptr += 5;
            end
            `OP_SPE_2_SEND_DATA :  begin
                    if(ts == 1) begin
                        $display("ts1: spike = %d", spike);
                        $display("ts1: new_potential = %d", new_potential);
                        $display("ts1: pe2_ptr = %d", pe2_ptr);
                        t1_spike_mem[pe2_ptr] = spike;
                        t1_residue_mem[pe2_ptr] = new_potential;
                    end
                    else if(ts == 2) begin
                        $display("ts2: spike = %d", spike);
                        $display("ts2: new_potential = %d", new_potential);
                        $display("ts2: pe2_ptr = %d", pe2_ptr);
                        t2_spike_mem[pe2_ptr] = spike;
                        t2_residue_mem[pe2_ptr] = new_potential;
                    end
                    pe2_ptr += 5;
            end
            `OP_SPE_3_SEND_DATA :  begin
                    if(ts == 1) begin
                        $display("ts1: spike = %d", spike);
                        $display("ts1: new_potential = %d", new_potential);
                        $display("ts1: pe3_ptr = %d", pe3_ptr);
                        t1_spike_mem[pe3_ptr] = spike;
                        t1_residue_mem[pe3_ptr] = new_potential;
                    end
                    else if(ts == 2) begin
                        $display("ts2: spike = %d", spike);
                        $display("ts2: new_potential = %d", new_potential);
                        $display("ts2: pe3_ptr = %d", pe3_ptr);
                        t2_spike_mem[pe3_ptr] = spike;
                        t2_residue_mem[pe3_ptr] = new_potential;
                    end
                    pe3_ptr += 5;
            end
            `OP_SPE_4_SEND_DATA :  begin
                    if(ts == 1) begin
                        $display("ts1: spike = %d", spike);
                        $display("ts1: new_potential = %d", new_potential);
                        $display("ts1: pe4_ptr = %d", pe4_ptr);
                        t1_spike_mem[pe4_ptr] = spike;
                        t1_residue_mem[pe4_ptr] = new_potential;
                    end
                    else if(ts == 2) begin
                        $display("ts2: spike = %d", spike);
                        $display("ts2: new_potential = %d", new_potential);
                        $display("ts2: pe4_ptr = %d", pe4_ptr);
                        t2_spike_mem[pe4_ptr] = spike;
                        t2_residue_mem[pe4_ptr] = new_potential;
                    end
                    pe4_ptr += 5;
            end

            `OP_SPE_0_REQ_DATA :  begin
                    packet[ADDR_START:ADDR_END] = 4'(spe_id); // respond to sender of request packet
                    packet[OPCODE_START:OPCODE_END] = 4'(spe_id); // irrelevant
                    packet[DATA_START:DATA_END] = 25'(t1_residue_mem[pe0_ptr]); // only t1 is used for requested residual data
                    $display("ts2: sending data to spe = %d", spe_id);
                    $display("ts2: residue = %d", t1_residue_mem[pe0_ptr]);
                    router_out.Send(packet); 
                    #FL;  
            end
            `OP_SPE_1_REQ_DATA :  begin
                    packet[ADDR_START:ADDR_END] = 4'(spe_id); // respond to sender of request packet
                    packet[OPCODE_START:OPCODE_END] = 4'(spe_id); // irrelevant
                    packet[DATA_START:DATA_END] = 25'(t1_residue_mem[pe1_ptr]); // only t1 is used for requested residual data
                    $display("ts2: sending data to spe = %d", spe_id);
                    $display("ts2: residue = %d", t1_residue_mem[pe1_ptr]);
                    router_out.Send(packet);
                    #FL;  
            end
            `OP_SPE_2_REQ_DATA :  begin
                    packet[ADDR_START:ADDR_END] = 4'(spe_id); // respond to sender of request packet
                    packet[OPCODE_START:OPCODE_END] = 4'(spe_id); // irrelevant
                    packet[DATA_START:DATA_END] = 25'(t1_residue_mem[pe2_ptr]); // only t1 is used for requested residual data
                    $display("ts2: sending data to spe = %d", spe_id);
                    $display("ts2: residue = %d", t1_residue_mem[pe2_ptr]);
                    router_out.Send(packet);
                    #FL;  
            end
            `OP_SPE_3_REQ_DATA :  begin
                    packet[ADDR_START:ADDR_END] = 4'(spe_id); // respond to sender of request packet
                    packet[OPCODE_START:OPCODE_END] = 4'(spe_id); // irrelevant
                    packet[DATA_START:DATA_END] = 25'(t1_residue_mem[pe3_ptr]); // only t1 is used for requested residual data
                    $display("ts2: sending data to spe = %d", spe_id);
                    $display("ts2: residue = %d", t1_residue_mem[pe3_ptr]);
                    router_out.Send(packet);
                    #FL;  
            end
            `OP_SPE_4_REQ_DATA :  begin
                    packet[ADDR_START:ADDR_END] = 4'(spe_id); // respond to sender of request packet
                    packet[OPCODE_START:OPCODE_END] = 4'(spe_id); // irrelevant
                    packet[DATA_START:DATA_END] = 25'(t1_residue_mem[pe4_ptr]); // only t1 is used for requested residual data
                    $display("ts2: sending data to spe = %d", spe_id);
                    $display("ts2: residue = %d", t1_residue_mem[pe4_ptr]);
                    router_out.Send(packet);
                    #FL;  
            end
        endcase

        // End of timestep (received all sums)
        if(pe0_ptr == 445) begin // last index is 440, then 5 was added

            if(ts == 1) begin
                // Send end of timestep packet to all modules
                for(int i = 0; i < 11; i++) begin
                    $display("Sending timestep packet to pe_id=%d", i);
                    packet = 0;
                    packet[ADDR_START:ADDR_END] = 4'(i); // respond to sender of request packet
                    packet[OPCODE_START:OPCODE_END] = 4'(`OP_TIMESTEP_DONE); // irrelevant
                    router_out.Send(packet);
                    #FL;
                end

                // Reset pointers for next timestep
                pe0_ptr = 0;
                pe1_ptr = 1;
                pe2_ptr = 2;
                pe3_ptr = 3;
                pe4_ptr = 4;

                // Set for next timestep
                ts = 2;

            end
            
            // Send output spikes to testbench
            else begin
                $display("%m: Sending start_r, ts_r, layer_r signals");
                start_r.Send(1);
                ts_r.Send(1);
                layer_r.Send(1);
                #FL;

                for(int i = 0; i < OUTPUT_SIZE * OUTPUT_SIZE; i++) begin
                    out_spike_addr.Send(i);
                    out_spike_data.Send(t1_spike_mem[i]);
                    $display("Sending ts=1: spike=%d, addr=%d", i, t1_spike_mem[i]);
                    #FL;
                end

                ts_r.Send(2);
                layer_r.Send(1);
                #FL;

                for(int i = 0; i < OUTPUT_SIZE * OUTPUT_SIZE; i++) begin
                    out_spike_addr.Send(i);
                    out_spike_data.Send(t2_spike_mem[i]);
                    $display("Sending ts=2: spike=%d, addr=%d", i, t2_spike_mem[i]);
                    #FL;
                end

                done_r.Send(1);
                #FL;
            end 
        end
    end
endmodule