// Test bench for the merge module
// Mengyu Sun

`timescale 1ns/1fs

// Import system verilog csp file
import SystemVerilogCSP::*;


module merge (interface l0, interface l1, interface control, interface right);
    parameter WIDTH_PACKAGE = 33;
    parameter FL = 2;
    parameter BL = 1;
    
    logic [WIDTH_PACKAGE-1:0] data;
    logic ctl;

    always begin
        control.Receive(ctl);
        if (ctl == 0) begin 
            l0.Receive(data);
            $display("Control signal = 0, receiveing data from channel 0");
        end
        else begin
            l1.Receive(data);
            $display("Control signal = 1, receiveing data from channel 1");
        end
        #FL;
        right.Send(data);
        $display("merge sending data = %b", data);
        #BL;
    end
endmodule

//Sample data_generator module
module data_generator (interface r);
  parameter WIDTH = 8;
  parameter FL = 0; //ideal environment   forward delay
  logic [WIDTH-1:0] SendValue=0;
  always
  begin 
    
	//add a display here to see when this module starts its main loop
  // $display("*** %m started @ time = %0d",$time);
	
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
    // $display("*** %m started @ time = %0d",$time);

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
    $display("Execution cycle= %d, Cycle Time= %d, 
    Average CycleTime=%f, Average Throughput=%f", cycleCounter, cycleTime, 
    averageCycleTime, averageThroughput);
	
	
  end

endmodule


// Constructing the testbench
module testbench;
    // use default 2 phase protocol.
    Channel #(.WIDTH(8)) intf  [3:0] ();

    // Instantiate modules in the testbench
    data_generator #(.WIDTH(8)) dg_0 (intf[0]);
    data_generator #(.WIDTH(8)) dg_1 (intf[1]);
    data_generator #(.WIDTH(1)) cg (intf[2]);
    merge #(.WIDTH_PACKAGE(8)) m (intf[0], intf[1], intf[2], intf[3]);
    data_bucket #(.WIDTH(8)) db (intf[3]);

    initial #10000 $stop;
endmodule