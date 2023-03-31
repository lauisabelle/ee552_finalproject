

// EE 552 Final Project Ã¢ÂÂ Spring 2023
// Written by Izzy Lau
// Verifies functionality of connected PPE and SPE

`timescale 1ns/1ns
import SystemVerilogCSP::*;

module ppe_spe_tb;
    parameter ADDR_START = 32;
    parameter ADDR_END = 29;
    parameter OPCODE_START = 28;
    parameter OPCODE_END = 25;
    parameter DATA_START = 24;
    parameter DATA_END = 0;

    parameter FL = 4;
    parameter BL = 2;

	//Interface Vector instatiation: 4-phase bundled data channel
	Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) intf  [2:0] (); 

	// Send partial sums from PPE to SPE
    ppe #(.PE_ID(5)) ppe_mod(.in(intf[0]), .out(intf[1]));
    spe #(.PE_ID(0)) spe_mod(.in(intf[1]), .out(intf[2]));


	// Channel #(.hsProtocol(P4PhaseBD), .WIDTH(1)) start (); 
	data_bucket #(.WIDTH(33)) db(intf[2]);

	logic [ADDR_START:0] packet = 0;
	logic [24:0] data = 0;

	always begin
		// create first weight packet
		packet[ADDR_START:ADDR_END] = 4'd5;  
   	 	packet[OPCODE_START:OPCODE_END] = 0; 
   	 	packet[23:16] = 8'd3; 
   	 	packet[15:8] = 8'd2; 
   	 	packet[7:0] = 8'd1; 

	  	intf[0].Send(packet);
	  	#FL;	

		// create second weight packet
		packet[ADDR_START:ADDR_END] = 4'd5; 
		packet[OPCODE_START:OPCODE_END] = 0;
		//packet[24] = 0;
		packet[23:16] = 8'd6; // dummy val since discarded
		packet[15:8] = 8'd5; 
		packet[7:0] = 8'd4; 

		intf[0].Send(packet);
		#FL;
		
		// send 25 inputs
		for(int i = 0; i < 25; i=i+1) begin
			data[i] = i%2;
		end

		packet[29:26] = 4'd5; 
		packet[OPCODE_START:OPCODE_END] = 1; // input 
		packet[24:0] = data;

		intf[0].Send(packet);
		#20;


		// send 25 inputs
		for(int i = 1; i < 26; i=i+1) begin
			data[i-1] = i%2;
		end

		packet[29:26] = 4'd5; 
		packet[OPCODE_START:OPCODE_END] = 1; // input 
		packet[24:0] = data;

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