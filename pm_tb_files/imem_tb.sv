
// EE 552 Final Project Spring 2023
// Written by Izzy Lau
// Test IMEM module

`timescale 1ns/1ns
import SystemVerilogCSP::*;

module imem_tb;
  parameter ADDR_START = 32;
    parameter ADDR_END = 29;
    parameter OPCODE_START = 28;
    parameter OPCODE_END = 25;
    parameter DATA_START = 24;
    parameter DATA_END = 0;
    parameter WIDTH_data = 8;
    parameter WIDTH_addr = 12;
    parameter WIDTH_out_data = 13;

    parameter FL = 4;
    parameter BL = 2;
    integer error_count, fpt, fpi_f, fpi_i1, fpi_i2, fpi_out1, fpi_out2, fpo, status;
    parameter DEPTH_F= 5;
    parameter DEPTH_I =25;
    parameter DEPTH_R =21;

    logic i1_data, i2_data, dn, st, s_r;
    logic [1:0] ts=1, l_index;
    logic [WIDTH_data-1:0] f_data;
    logic [WIDTH_addr-1:0] i1_addr = 0, i2_addr=0, f_addr=0, out_addr;



	//Interface Vector instatiation: 4-phase bundled data channel
	Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) load_start ();
	Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) ifmap_addr ();
	Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) ifmap_data ();
	Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) timestep ();
	Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) load_done ();
	Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) router_in ();
	Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) router_out ();


	imem imem_mod( .load_start(load_start), .ifmap_addr(ifmap_addr), .ifmap_data(ifmap_data), .timestep(timestep), 
            .load_done(load_done), .router_in(router_in), .router_out(router_out));

	
    data_bucket #(.WIDTH(33)) db(router_out);

	logic [ADDR_START:0] packet;
	logic [24:0] data = 0;

    initial begin
        fpi_i1 = $fopen("ifmap1.txt","r");
        fpi_i2 = $fopen("ifmap2.txt", "r");

    end

	always begin

        load_start.Send(1);

        for(integer i=0; i<DEPTH_I*DEPTH_I; i++) begin
            if (!$feof(fpi_i1)) begin
                status = $fscanf(fpi_i1,"%d\n", i1_data);
                $display("Ifmap1 data read:%d", i1_data);
                timestep.Send(ts);
                ifmap_addr.Send(i1_addr);
                ifmap_data.Send(i1_data);

                i1_addr++;
            end 
        end

	    ts++;

        // sending ifmap 2 (timestep2)

        for(integer i=0; i<DEPTH_I*DEPTH_I; i++) begin
            if (!$feof(fpi_i2)) begin
                status = $fscanf(fpi_i2,"%d\n", i2_data);
                $display("Ifmap2 data read:%d", i2_data);
                timestep.Send(ts);
                ifmap_addr.Send(i2_addr);
                ifmap_data.Send(i2_data);

                i2_addr++;
            end 
        end

        //Finish sending the matrix values
        load_done.Send(1); 

        // Send weights done
        packet[ADDR_START:ADDR_END] = 11;
        packet[OPCODE_START:OPCODE_END] = 4'b0;
        packet[DATA_START:DATA_END] = 0;
        router_in.Send(packet);
        #FL;
  
    
        // ** receiving input packets now ** 
        
        // send requests for more inputs
        for(int i = 5; i < 10; i++) begin
            packet = 0;
            packet[ADDR_START:ADDR_END] = 4'(i);
            packet[OPCODE_START:OPCODE_END] = 4'(i);
            packet[DATA_START:DATA_END] = 0;
            router_in.Send(packet);
            #FL;
        end
        for(int i = 5; i < 10; i++) begin
            packet = 0;
            packet[ADDR_START:ADDR_END] = 4'(i);
            packet[OPCODE_START:OPCODE_END] = 4'(i);
            packet[DATA_START:DATA_END] = 0;
            router_in.Send(packet);
            #FL;
        end
        for(int i = 5; i < 10; i++) begin
            packet = 0;
            packet[ADDR_START:ADDR_END] = 4'(i);
            packet[OPCODE_START:OPCODE_END] = 4'(i);
            packet[DATA_START:DATA_END] = 0;
            router_in.Send(packet);
            #FL;
        end
        for(int i = 5; i < 10; i++) begin
            packet = 0;
            packet[ADDR_START:ADDR_END] = 4'(i);
            packet[OPCODE_START:OPCODE_END] = 4'(i);
            packet[DATA_START:DATA_END] = 0;
            router_in.Send(packet);
            #FL;
        end



        // Timestep 2

        // signal end of timestep
        packet[ADDR_START:ADDR_END] = 4'd11;
        packet[OPCODE_START:OPCODE_END] = 4'd15;
        packet[DATA_START:DATA_END] = 25'b0;
        router_in.Send(packet);
        #FL;
  
    
        // ** receiving input packets now ** 
        
        for(int i = 5; i < 10; i++) begin
            packet[ADDR_START:ADDR_END] = 4'(i);
            packet[OPCODE_START:OPCODE_END] = 4'(i);
            packet[DATA_START:DATA_END] = 25'b0;
            router_in.Send(packet);
            #FL;
        end
        for(int i = 5; i < 10; i++) begin
            packet[ADDR_START:ADDR_END] = 4'd11;
            packet[OPCODE_START:OPCODE_END] = 4'(i);
            packet[DATA_START:DATA_END] = 25'b0;
            router_in.Send(packet);
            #FL;
        end
        for(int i = 5; i < 10; i++) begin
            packet[ADDR_START:ADDR_END] = 4'd11;
            packet[OPCODE_START:OPCODE_END] = 4'(i);
            packet[DATA_START:DATA_END] = 25'b0;
            router_in.Send(packet);
            #FL;
        end
        for(int i = 5; i < 10; i++) begin
            packet[ADDR_START:ADDR_END] = 4'(i);
            packet[OPCODE_START:OPCODE_END] = 4'(i);
            packet[DATA_START:DATA_END] = 25'b0;
            router_in.Send(packet);
            #FL;
        end
    
        #500000;
    end


endmodule









//Sample data_bucket module
module data_bucket (interface r);
  parameter WIDTH = 8;
  parameter BL = 2; //ideal environment    backward delay
  logic [WIDTH-1:0] ReceiveValue = 0;
  
  //Variables added for performance measurements
  real cycleCounter=0, //# of cycles = Total number of times a value is received
	   timeOfReceive=0, //Simulation time of the latest Receive 
	   cycleTime=0; // time difference between the last two receives
  real averageThroughput=0, averageCycleTime=0, sumOfCycleTimes=0;
  always
  begin
	
	//add a display here to see when this module starts its main loop
	$display("*** %m %d",$time);
	timeOfReceive = $time;
	
	//Communication action Receive is about to start
	$display("Start receiving in module %m. Simulation time = %t", $time);
	r.Receive(ReceiveValue);
	
	//Communication action Receive is finished
	$display("Finished receiving in module %m. Simulation time = %t", $time);
	$display("Received value %d", ReceiveValue);
	  #BL;
	cycleCounter += 1;		
	//Measuring throughput: calculate the number of Receives per unit of time  
	//CycleTime stores the time it takes from the begining to the end of the always block
	cycleTime = $time - timeOfReceive; // the difference of time between now and the last receive
	averageThroughput = cycleCounter/$time; 
	sumOfCycleTimes += cycleTime;
	averageCycleTime = sumOfCycleTimes / cycleCounter;
	$display("Execution cycle= %d, Cycle Time= %f, Average CycleTime=%f, Average Throughput=%f", cycleCounter, cycleTime, averageCycleTime, averageThroughput);
	
	
  end
endmodule