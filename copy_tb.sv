// test bench for the copy module
// Mengyu Sun

`timescale 1ns/1fs
// Import system verilog csp file
import SystemVerilogCSP::*;


// data_generator module for data generation
module data_generator (interface r);
  parameter WIDTH = 8;
  parameter FL = 0; //ideal environment   forward delay
  logic [WIDTH-1:0] SendValue=0;
  always
  begin 
    
	//add a display here to see when this module starts its main loop
  $display("*** %m started @ time = %0d",$time);
	
  SendValue = $random() % (2**WIDTH); // the range of random number is from 0 to 2^WIDTH
  #FL;   // change FL and check the change of performance
    
  //Communication action Send is about to start
  $display("%m started sending data @ time = %0d, data = %b", $time, SendValue);
  r.Send(SendValue);
  $display("%m finished sending data @ time = %0d, data = %b", $time, SendValue);
  //Communication action Send is finished
	

  end
endmodule

//Sample data_bucket module
module data_bucket (interface r);
  parameter WIDTH = 8;
  parameter BL = 0; //ideal environment    backward delay
  logic [WIDTH-1:0] ReceiveValue = 0;
  
  //Variables added for performance measurements
  real cycleCounter=0, //# of cycles = Total number of times a value is received
       timeOfReceive=0, //Simulation time of the latest Receive 
       cycleTime=0; // time difference between the last two receives
  real averageThroughput=0, averageCycleTime=0, sumOfCycleTimes=0;
  always
  begin
	
	//add a display here to see when this module starts its main loop
    $display("*** %m started @ time = %0d",$time);

    timeOfReceive = $time;
	
	//Communication action Receive is about to start
    $display("%m started receiving @ time = %0d", $time);
    r.Receive(ReceiveValue);
    $display("%m finished receiving @ time = %0d, data = %b", $time, ReceiveValue);
	//Communication action Receive is finished
    
	#BL;
    cycleCounter += 1;		
    //Measuring throughput: calculate the number of Receives per unit of time  
    //CycleTime stores the time it takes from the begining to the end of the always block
    cycleTime = $time - timeOfReceive; // the difference of time between now and the last receive
    averageThroughput = cycleCounter/$time; 
    sumOfCycleTimes += cycleTime;
    averageCycleTime = sumOfCycleTimes / cycleCounter;
    $display("Execution cycle= %d, Cycle Time= %d, Average CycleTime=%f, Average Throughput=%f", cycleCounter, cycleTime, 
    averageCycleTime, averageThroughput);
	
	
  end

endmodule


module copy (interface left, interface r0, interface r1);
    parameter WIDTH_PACKAGE = 33;
    parameter FL = 2;
    parameter BL = 1;
    
    logic [WIDTH_PACKAGE-1:0] data;

    always begin
        left.Receive(data);
        #FL;
        fork
            r0.Send(data);
            r1.Send(data);
        join
        #BL;
    end
endmodule


module copy_tb;
    parameter WIDTH = 8;
    // 2 phase hand shaking protocol
    Channel #(.WIDTH(WIDTH)) intf  [2:0] ();

    data_generator #(.WIDTH(WIDTH)) dg0 (.r(intf[0]));
    copy #(.WIDTH_PACKAGE(WIDTH)) c (.left(intf[0]), .r0(intf[1]), .r1(intf[2]));
    data_bucket #(.WIDTH(WIDTH)) db0 (.r(intf[1]));
    data_bucket #(.WIDTH(WIDTH)) db1 (.r(intf[2]));

endmodule