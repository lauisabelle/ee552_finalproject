// Test bench for the 2 channel arbiter
// Mengyu Sun

`timescale 1ns/1fs

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

module arbiter_2channel (interface i0, interface i1, interface winner);
    parameter WIDTH_PACKAGE = 33;
    parameter FL = 2;
    parameter BL = 1;
    
    logic [WIDTH_PACKAGE-1:0] data_i0;
    logic [WIDTH_PACKAGE-1:0] data_i1;
    logic winner_id;

    // We give channle i0 the priority at the beginning
    initial winner_id = 0;

    always begin
        /* For reference: (from svcsp.sv)
        typedef enum {idle, r_pend, s_pend, s12m_pend} ChannleStatus;
        */
        // Wait until either or both channels are pending to send
        wait(i0.status == 2 || i1.status == 2);
        // If both channels have something to send
        if (i0.status == 2 && i1.status == 2) begin
            winner_id = ~ winner_id;
            if (winner_id == 0) begin
                i0.Receive(data_i0);
                $display("channel 0 won the arbitration.");
                // winner = 1;
            end
            else begin
                i1.Receive(data_i1);
                $display("channel 1 won the arbitration.");
                // winner = 0;
            end
        end
        // If channel i0 has data to send
        else if (i0.status == 2) begin
            i0.Receive(data_i0);
            winner_id = 0;
            $display("channel 0 won the arbitration.");
        end
        else if (i1.status == 2) begin
            i1.Receive(data_i1);
            winner_id = 1;
            $display("channel 1 won the arbitration.");
        end
        #FL;
        winner.Send(winner_id);
        #BL;
    end
endmodule


module arbiter_tb;
    parameter WIDTH = 8;
    // 2 phase hand shaking protocol
    Channel #(.WIDTH(WIDTH)) intf  [2:0] ();

    data_generator #(.WIDTH(WIDTH)) dg0 (.r(intf[0]));
    data_generator #(.WIDTH(WIDTH)) dg1 (.r(intf[1]));
    arbiter_2channel #(.WIDTH_PACKAGE(WIDTH)) arbiter(.i0(intf[0]), .i1(intf[1]), .winner(intf[2]));
    data_bucket #(.WIDTH(WIDTH)) db (.r(intf[2]));
endmodule