

// EE 552 Final Project Ã¢ÂÂ Spring 2023
// Written by Izzy Lau
// Describes the various PE elements we use in the final project

`timescale 1ns/1ns
import SystemVerilogCSP::*;

module spe_tb;
    parameter ADDR_START = 32;
    parameter ADDR_END = 29;
    parameter OPCODE_START = 28;
    parameter OPCODE_END = 25;
    parameter DATA_START = 24;
    parameter DATA_END = 0;

    parameter FL = 4;
    parameter BL = 2;

	//Interface Vector instatiation: 4-phase bundled data channel
	Channel #(.hsProtocol(P4PhaseBD), .WIDTH(35)) intf  [1:0] (); 

	spe #(.PE_ID(0)) spe_mod(.in(intf[0]), .out(intf[1]));

	// Channel #(.hsProtocol(P4PhaseBD), .WIDTH(1)) start (); 
	data_bucket #(.WIDTH(35)) db(intf[1]);

	logic [ADDR_START:0] packet;
	logic [24:0] data = 0;

	always begin

		// create partial sum packets and send
        for(int i = 0; i < 5; i++) begin
            packet[ADDR_START:ADDR_END] = 4'b0;  
            packet[OPCODE_START:OPCODE_END] = 4'b0; 
            packet[DATA_START:DATA_END] = 25'(i);
            intf[0].Send(packet);
	  	    #FL;	
        end
		
        #FL;
        #BL;

		// send timestep flag
        packet[ADDR_START:ADDR_END] = 4'd0;  
        packet[OPCODE_START:OPCODE_END] = 4'd15; // indicate timestep done
        packet[DATA_START:DATA_END] = 25'b0; // irrelevant
        intf[0].Send(packet);
	
		#FL;

		// create partial sum packets and send
        for(int i = 0; i < 5; i++) begin
            packet[ADDR_START:ADDR_END] = 4'b0;  
            packet[OPCODE_START:OPCODE_END] = 4'b0; 
            packet[DATA_START:DATA_END] = 25'(i);
            intf[0].Send(packet);
	    	#FL;	
        end
		
        #FL;
        #BL;



        // send previous potential
		packet[ADDR_START:ADDR_END] = 4'd0;  
        packet[OPCODE_START:OPCODE_END] = 4'd2; // indicate previous potential
        packet[DATA_START:DATA_END] = 25'd60; // random
        intf[0].Send(packet);

		#100;
		$stop;
		
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