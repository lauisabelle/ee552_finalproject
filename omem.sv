
// EE 552 Final Project Spring 2023
// Written by Izzy Lau
// Defines the Output Memory module which stores spikes and residual values. 
// It also synchronizes at the end of the itmestep

`timescale 1ns/1ns
`define OP_SPE_0_SEND_DATA 0 // OPCODE: SPE 0 sends residual val and spike
`define OP_SPE_1_SEND_DATA 2 // OPCODE: SPE 0 sends residual val and spike
`define OP_SPE_2_SEND_DATA 4 // OPCODE: SPE 0 sends residual val and spike
`define OP_SPE_3_SEND_DATA 6 // OPCODE: SPE 0 sends residual val and spike
`define OP_SPE_4_SEND_DATA 8 // OPCODE: SPE 0 sends residual val and spike

`define OP_SPE_0_REQ_DATA 1 // OPCODE: SPE 0 requests previous value
`define OP_SPE_0_REQ_DATA 3 // OPCODE: SPE 0 requests previous value
`define OP_SPE_0_REQ_DATA 5 // OPCODE: SPE 0 requests previous value
`define OP_SPE_0_REQ_DATA 7 // OPCODE: SPE 0 requests previous value
`define OP_SPE_0_REQ_DATA 9 // OPCODE: SPE 0 requests previous value

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
    parameter FL = 2;
    parameter BL = 2;

    // Packet storage
    logic [ADDR_START:0] packet;
    logic [ADDR_START - ADDR_END:0] dest_address = 0;
    logic [OPCODE_START:OPCODE_END] opcode;
    logic signed [DATA_START - DATA_END:0] data;
    logic [4:0] OUTPUT_DIM = IFMAP_SIZE - FILTER_SIZE + 1;


	logic [(OUTPUT_SIZE*OUTPUT_SIZE)-1:0]t1_spike_mem ;
    logic [(OUTPUT_SIZE*OUTPUT_SIZE)-1:0]t2_spike_mem;

    logic [(OUTPUT_SIZE*OUTPUT_SIZE)-1:0]t1_residue_mem ;
    logic [(OUTPUT_SIZE*OUTPUT_SIZE)-1:0]t2_residue_mem;

    logic [SUM_WIDTH-1:0] new_potential;
    logic spike;
    logic [SUM_WIDTH-1:0] spe_id;


    logic [WIDTH_addr-1:0] pe0_ptr;
    logic [WIDTH_addr-1:0] pe1_ptr;
    logic [WIDTH_addr-1:0] pe2_ptr;
    logic [WIDTH_addr-1:0] pe3_ptr;
    logic [WIDTH_addr-1:0] pe4_ptr;

    logic [1:0] ts = 1;


    // Receive spikes and outputs
    always begin 
        router_in.Receive(packet);
        data = packet[DATA_START:DATA_END];

        // Even: Store data, Odd: Send data
        if(opcode % 2 == 0) begin
            new_potential = data[DATA_START:DATA_END+1];
            spike = data[DATA_END]; // spike is LSB
        end
        else begin
            spe_id = data[DATA_START:DATA_END+1];
        end


        #BL;
        packet = 0;

        case(opcode)
            `OP_SPE_0_SEND_DATA :  begin
                    if(ts == 1) begin
                        t1_spike_mem[pe0_ptr] = spike;
                        t1_residue_mem[pe0_ptr] = new_potential;
                    end
                    else if(ts == 2) begin
                        t2_spike_mem[pe0_ptr] = spike;
                        t2_residue_mem[pe0_ptr] = new_potential;
                    end
                    pe0_ptr += 5;
            end
            `OP_SPE_1_SEND_DATA :  begin
                    if(ts == 1) begin
                        t1_spike_mem[pe1_ptr] = spike;
                        t1_residue_mem[pe1_ptr] = new_potential;
                    end
                    else if(ts == 2) begin
                        t2_spike_mem[pe1_ptr] = spike;
                        t2_residue_mem[pe1_ptr] = new_potential;
                    end
                    pe1_ptr += 5;
            end
            `OP_SPE_2_SEND_DATA :  begin
                    if(ts == 1) begin
                        t1_spike_mem[pe2_ptr] = spike;
                        t1_residue_mem[pe2_ptr] = new_potential;
                    end
                    else if(ts == 2) begin
                        t2_spike_mem[pe2_ptr] = spike;
                        t2_residue_mem[pe2_ptr] = new_potential;
                    end
                    pe2_ptr += 5;
            end
            `OP_SPE_3_SEND_DATA :  begin
                    if(ts == 1) begin
                        t1_spike_mem[pe3_ptr] = spike;
                        t1_residue_mem[pe3_ptr] = new_potential;
                    end
                    else if(ts == 2) begin
                        t2_spike_mem[pe3_ptr] = spike;
                        t2_residue_mem[pe3_ptr] = new_potential;
                    end
                    pe3_ptr += 5;
            end
            `OP_SPE_4_SEND_DATA :  begin
                    if(ts == 1) begin
                        t1_spike_mem[pe4_ptr] = spike;
                        t1_residue_mem[pe4_ptr] = new_potential;
                    end
                    else if(ts == 2) begin
                        t2_spike_mem[pe4_ptr] = spike;
                        t2_residue_mem[pe4_ptr] = new_potential;
                    end
                    pe4_ptr += 5;
            end

            `OP_SPE_0_REQ_DATA :  begin
                    packet[ADDR_START:ADDR_END] = spe_id; // respond to sender of request packet
                    packet[OPCODE_START:OPCODE_END] = spe_id; // irrelevant
                    packet[0] = t1_spike_mem[pe0_ptr]; // only t1 is used for requested residual data
                    // don't increase pe0_ptr since we will store the received data at this idx
                    router_out.Send(packet);
            end
            `OP_SPE_1_REQ_DATA :  begin
                    packet[ADDR_START:ADDR_END] = spe_id; // respond to sender of request packet
                    packet[OPCODE_START:OPCODE_END] = spe_id; // irrelevant
                    packet[0] = t1_spike_mem[pe1_ptr]; // only t1 is used for requested residual data
                    // don't increase pe0_ptr since we will store the received data at this idx
                    router_out.Send(packet);
            end
            `OP_SPE_2_REQ_DATA :  begin
                    packet[ADDR_START:ADDR_END] = spe_id; // respond to sender of request packet
                    packet[OPCODE_START:OPCODE_END] = spe_id; // irrelevant
                    packet[0] = t1_spike_mem[pe2_ptr]; // only t1 is used for requested residual data
                    // don't increase pe0_ptr since we will store the received data at this idx
                    router_out.Send(packet);
            end
            `OP_SPE_3_REQ_DATA :  begin
                    packet[ADDR_START:ADDR_END] = spe_id; // respond to sender of request packet
                    packet[OPCODE_START:OPCODE_END] = spe_id; // irrelevant
                    packet[0] = t1_spike_mem[pe3_ptr]; // only t1 is used for requested residual data
                    // don't increase pe0_ptr since we will store the received data at this idx
                    router_out.Send(packet);
            end
            `OP_SPE_4_REQ_DATA :  begin
                    packet[ADDR_START:ADDR_END] = spe_id; // respond to sender of request packet
                    packet[OPCODE_START:OPCODE_END] = spe_id; // irrelevant
                    packet[0] = t1_spike_mem[pe4_ptr]; // only t1 is used for requested residual data
                    // don't increase pe0_ptr since we will store the received data at this idx
                    router_out.Send(packet);
            end


            // THIS IS THE THING SIGNALING THE END DUMMY THERE IS NO OPCODE FOR THAT HERE
            `OP_TIMESTEP_DONE : begin
                ts = 2;
                pe0_ptr = 0;
                pe0_ptr = 1;
                pe0_ptr = 2;
                pe0_ptr = 3;
                pe0_ptr = 4;
            end
        endcase

        // End of timestep (received all sums)
        if(pe0_ptr == 445) begin // last index is 440, then 5 was added
            

            if(ts == 1) begin
                // Send end of timestep packet to all modules
                for(int i = 0; i < 11; i++) begin
                    packet = 0;
                    packet[OPCODE_START:OPCODE_END] = `OP_TIMESTEP_DONE; // irrelevant
                    packet[ADDR_START:ADDR_END] = i; // respond to sender of request packet
                    router_out.Send(packet);
                end

                // Reset pointers for next timestep
                pe0_ptr = 0;
                pe0_ptr = 1;
                pe0_ptr = 2;
                pe0_ptr = 3;
                pe0_ptr = 4;

            end
            
            // Send output spikes to testbench
            else begin

                start_r.Send(1);
                
                // Send data associated with timestep 1
                ts_r.Send(1);
                layer_r.Send(1);

                for(int i = 0; i < OUTPUT_SIZE * OUTPUT_SIZE; i++) begin
                    out_spike_addr.Send(i);
                    out_spike_data.Send(t1_spike_mem[i]);
                end

                ts_r.Send(2);
                layer_r.Send(1);

                for(int i = 0; i < OUTPUT_SIZE * OUTPUT_SIZE; i++) begin
                    out_spike_addr.Send(i);
                    out_spike_data.Send(t2_spike_mem[i]);
                end

                done_r.Receive(1);
                
            end 
        end
    end



endmodule