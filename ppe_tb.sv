// EE 552 Final Project – Spring 2023
// Written by Izzy Lau
// Describes the various PE elements we use in the final project

`timescale 1ns/1ns
import SystemVerilogCSP::*;

module ppe_tb;
  parameter ADDR_START = 29;
  parameter ADDR_END = 26;
  parameter OPCODE = 25;
  parameter FL = 4;
  parameter BL = 2;

    //Interface Vector instatiation: 4-phase bundled data channel
    Channel #(.hsProtocol(P4PhaseBD), .WIDTH(10)) intf  [1:0] (); 
  
    ppe ppe_mod(.in(intf[0]), .out(intf[1]));

    logic [ADDR_START:0] packet;
    packet[ADDR_START:ADDR_END] = 5; 
    packet[OPCODE] = 0; 
    packet[23:16] = 0; 
    packet[15:8] = 1; 
    packet[7:0] = 2; 

    // Channel #(.hsProtocol(P4PhaseBD), .WIDTH(1)) start (); 
    data_bucket #(.WIDTH(10)) db(intf[1]);

    always begin
      // create first weight packet
      packet[ADDR_START:ADDR_END] = 5;
      packet[OPCODE] = 0; 
      packet[23:16] = 0; 
      packet[15:8] = 1; 
      packet[7:0] = 2;

      intf[0].Send(packet);
      #FL;

      // convert to binary
      // take clog() to get number of bits
      // left justify to pad with zeros
      

      // create second weight packet
      packet[ADDR_START:ADDR_END] = 5; 
      packet[OPCODE] = 0; 
      packet[23:16] = 3; 
      packet[15:8] = 4; 
      packet[7:0] = 5; // dummy val since discarded

      intf[0].Send(packet);
      #FL;


      // create string of inputs
      logic [24:0] data;
      for(int i = 0; i < 25; i++) begin
        data[i] = i;
      end

      packet[ADDR_START:ADDR_END] = 5; 
      packet[OPCODE] = 1; // input 
      packet[24:0] = data;

      intf[0].Send(packet);
      #FL;

      // intf[1].Receive();

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