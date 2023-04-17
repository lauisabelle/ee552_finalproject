// Test bench for the routing decision making module
// Mengyu Sun

`timescale 1ns/1fs

// Import system verilog csp file
import SystemVerilogCSP::*;

// Special data_generator for this module
/* This module generates a 33-bit data package with different
destination each time.*/
module data_generator (interface r);
  parameter WIDTH = 33;
  parameter FL = 0; //ideal environment   forward delay
  logic [WIDTH-1:0] SendValue;
  logic [3:0] dest_id;
  always
  begin 
    
	//add a display here to see when this module starts its main loop
  // $display("*** %m started @ time = %0d",$time);

  dest_id = $urandom%12;
  SendValue = {dest_id, 29'b0};
  $display("Generated dest_id = %0d", dest_id);
  #FL;   // change FL and check the change of performance
    
  //Communication action Send is about to start
  // $display("%m started sending data @ time = %0d, data = %b", $time, SendValue);
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
    // $display("%m started receiving @ time = %0d", $time);
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
    // $display("Execution cycle= %d, Cycle Time= %d, Average CycleTime=%f, Average Throughput=%f", cycleCounter, cycleTime, averageCycleTime, averageThroughput);
	
	
  end

endmodule


module decision_making (interface in, interface up, interface down, interface left, interface right, interface pe_mem);
    parameter WIDTH_PACKAGE = 33;
    parameter WIDTH_ADDR = 4;
    parameter WIDTH_ADDR_DECODED = 5;
    //ROUTER_LOC needs to be re-configured when building the whole system
    parameter ROUTER_LOC = 5'b001_01; // we use router No.6 for testing
    parameter FL = 2;
    parameter BL = 1;

    logic [WIDTH_PACKAGE-1: 0] data_package;
    logic [WIDTH_ADDR-1: 0] dest_addr;
    logic [WIDTH_ADDR_DECODED-1: 0] addr_decoded;
    logic [1:0] y_dist;
    logic [2:0] x_dist;
    logic [2:0] x_id; // x coordinate of the router
    logic [1:0] y_id; // y coordinate of the router
    logic [1:0] x_dest; // x coordinate of the destination
    logic [2:0] y_dest; // y coordinate of the destination

    assign x_id = ROUTER_LOC[4:2];
    assign y_id = ROUTER_LOC[1:0];


    // Decode module
    // Translate 4-bit address into [x_addr, y_addr]
    always @(dest_addr) begin
        case (dest_addr)
            4'b0000: addr_decoded = 5'b00000; // 0
            4'b0001: addr_decoded = 5'b00100; // 1
            4'b0010: addr_decoded = 5'b01000; // 2
            4'b0011: addr_decoded = 5'b01100; // 3
            4'b0100: addr_decoded = 5'b10000; // 4
            4'b0101: addr_decoded = 5'b00001; // 5
            4'b0110: addr_decoded = 5'b00101; // 6
            4'b0111: addr_decoded = 5'b01001; // 7
            4'b1000: addr_decoded = 5'b01101; // 8
            4'b1001: addr_decoded = 5'b10001; // 9
            4'b1010: addr_decoded = 5'b00010; // 10
            4'b1011: addr_decoded = 5'b00110; // 11
            4'b1100: addr_decoded = 5'b01010; // 12
            default: addr_decoded = 5'b00000;
        endcase

        // Get x coordinate and y coordinate
        x_dest = addr_decoded[4:2];
        y_dest = addr_decoded[1:0];
    end

    always begin
        // Receive the data packet that wons the arbitration
        in.Receive(data_package);
        #FL;
        dest_addr = data_package[32:29];

        if (x_dest > x_id) begin
            x_dist = x_dest - x_id;
            if (x_dist == 4) begin
                left.Send(data_package);
                $display("Package sent to left channel.");
            end
            else if (x_dist == 3) begin
                left.Send(data_package);
                $display("Package sent to left channel.");
            end
            else if (x_dist == 2) begin
                right.Send(data_package);
                $display("Package sent to right channel.");
            end
            else if (x_dist == 1) begin
                right.Send(data_package);
                $display("Package sent to right channel.");
            end
        end
        else if (x_dest < x_id) begin
            x_dist = x_id - x_dest;
            if (x_dist == 4) begin 
                right.Send(data_package);
                $display("Package sent to right channel.");
            end
            else if (x_dist == 3) begin
                right.Send(data_package);
                $display("Package sent to right channel.");
            end
            else if (x_dist == 2) begin
                left.Send(data_package);
                $display("Package sent to left channel.");
            end
            else if (x_dist == 1) begin
                left.Send(data_package);
                $display("Package sent to left channel.");
            end
        end
        else begin // x_dist = x_id
            if (y_dest > y_id) begin
                y_dist = y_dest - y_id;
                if (y_dist == 2) begin
                    down.Send(data_package);
                    $display("Package sent to down channel.");
                end
                else if (y_dist == 1) begin
                    up.Send(data_package);
                    $display("Package sent to up channel.");
                end
            end
            else if (y_dest < y_id) begin
                y_dist = y_id - y_dest;
                if (y_dist == 2) begin
                    up.Send(data_package);
                    $display("Package sent to up channel.");
                end
                else if (y_dist == 1) begin
                    down.Send(data_package);
                    $display("Package sent to down channel.");
                end
            end
            else begin // y_dist == y_id && x_dist == x_id
                pe_mem.Send(data_package);
                $display("Package sent to pe_mem channel.");
            end
        end
    end

    
endmodule

module decision_making_tb;

    // Use default 2 phase hand shaking protocol
    Channel #(.WIDTH(33)) intf  [5:0] ();

    data_generator dg (.r(intf[5]));
    decision_making dut (.in(intf[5]), .up(intf[0]), .left(intf[1]),
                        .down(intf[2]), .right(intf[3]), .pe_mem(intf[4]));
    data_bucket db_up (.r(intf[0]));
    data_bucket db_left (.r(intf[1]));
    data_bucket db_down (.r(intf[2]));
    data_bucket db_right (.r(intf[3]));
    data_bucket db_pe_mem (.r(intf[4]));
endmodule