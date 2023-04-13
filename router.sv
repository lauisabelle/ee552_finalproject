// Router design for EE 552 NoC final project
// Mengyu Sun
// This router implements X-Y routing
// *************************************************************************************************************
// ***************************************************README****************************************************
// When instantiating a router module, configure the ROUTER_LOC parameter to set the location ID for the router.
// No need to configure other parameters.
// First 3 bits indicate the x coordinate. Last 2 bits indicate the y coordinate.
/* For example, for router No. 8, which can also be represented by (3,1). (This is based on the network arragement
   diagram included in the progress report for phase 2.)*/
// Thus, its ROUTER_LOC = 5'b01101
// All submodules used in router are included in this file. No need to add individual tb files for the NoC construction.
// For router 13 and 14, attach a data bucket to the pe_mem channel as they are not connected to PEs or MEMs
// **************************************************************************************************************



`timescale 1ns/1ns

// Import system verilog csp file
import SystemVerilogCSP::*;


// routers with 5 interfaces
/* 4 interfaces connecting to neighboring routers
 + 1 interface with PE or mem
 */
module router (interface left, interface right, interface up, interface down, interface pe_mem);
    parameter WIDTH_PACKAGE = 33;
    parameter WIDTH_ADDR = 4;
    parameter WIDTH_ADDR_DECODED = 5;
    // Belowe parameter needs to be re-configured when building the whole system
    parameter ROUTER_LOC = 5'b001_01; // we use router No.6 for testing

    // 2 phase protocol
    Channel #(.hsProtocol(P2PhaseBD), .WIDTH(WIDTH_PACKAGE)) intf  [17:0] ();

    copy #(.WIDTH_PACKAGE(WIDTH_PACKAGE)) c_0 (.left(left), .r0(intf[0]), .r1(intf[1]));
    copy #(.WIDTH_PACKAGE(WIDTH_PACKAGE)) c_1 (.left(right), .r0(intf[2]), .r1(intf[3]));
    copy #(.WIDTH_PACKAGE(WIDTH_PACKAGE)) c_2 (.left(up), .r0(intf[4]), .r1(intf[5]));
    copy #(.WIDTH_PACKAGE(WIDTH_PACKAGE)) c_3 (.left(down), .r0(intf[6]), .r1(intf[7]));
    copy #(.WIDTH_PACKAGE(WIDTH_PACKAGE)) c_4 (.left(intf[10]), .r0(intf[12]), .r1(intf[13]));
    copy #(.WIDTH_PACKAGE(WIDTH_PACKAGE)) c_5 (.left(intf[11]), .r0(intf[14]), .r1(intf[15]));
    copy #(.WIDTH_PACKAGE(WIDTH_PACKAGE)) c_6 (.left(intf[17]), .r0(intf[18]), .r1(intf[19]));
    copy #(.WIDTH_PACKAGE(WIDTH_PACKAGE)) c_7 (.left(pe_mem), .r0(intf[20]), .r1(intf[21]));

    arbiter_2channel #(.WIDTH_PACKAGE(WIDTH_PACKAGE)) arbiter_0 (.i0(intf[0]), .i1(intf[2]), .winner(intf[8]));
    arbiter_2channel #(.WIDTH_PACKAGE(WIDTH_PACKAGE)) arbiter_1 (.i0(intf[4]), .i1(intf[6]), .winner(intf[9]));
    arbiter_2channel #(.WIDTH_PACKAGE(WIDTH_PACKAGE)) arbiter_2 (.i0(intf[12]), .i1(intf[14]), .winner(intf[16]));
    arbiter_2channel #(.WIDTH_PACKAGE(WIDTH_PACKAGE)) arbiter_3 (.i0(intf[18]), .i1(intf[20]), .winner(intf[22]));


    merge #(.WIDTH_PACKAGE(WIDTH_PACKAGE)) merge_0 (.l0(intf[1]), .l1(intf[3]), .control(intf[8]), .right(intf[10]));
    merge #(.WIDTH_PACKAGE(WIDTH_PACKAGE)) merge_1 (.l0(intf[5]), .l1(intf[7]), .control(intf[9]), .right(intf[11]));
    merge #(.WIDTH_PACKAGE(WIDTH_PACKAGE)) merge_2 (.l0(intf[13]), .l1(intf[15]), .control(intf[16]), .right(intf[17]));
    merge #(.WIDTH_PACKAGE(WIDTH_PACKAGE)) merge_3 (.l0(intf[19]), .l1(intf[21]), .control(intf[22]), .right(intf[23]));

    decision_making #(.ROUTER_LOC(ROUTER_LOC)) dm (.in(intf[23]), .up(up), .down(down), .left(left), .right(right), .pe_mem(pe_mem));

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


//Sample data_bucket module
module data_bucket (interface r);
  parameter WIDTH = 8;
  parameter BL = 0; //ideal environment    backward delay
  logic [WIDTH-1:0] ReceiveValue = 0;
  
//   //Variables added for performance measurements
//   real cycleCounter=0, //# of cycles = Total number of times a value is received
//        timeOfReceive=0, //Simulation time of the latest Receive 
//        cycleTime=0; // time difference between the last two receives
//   real averageThroughput=0, averageCycleTime=0, sumOfCycleTimes=0;
  always
  begin
	
	//add a display here to see when this module starts its main loop
    // $display("*** %m started @ time = %0d",$time);

    // timeOfReceive = $time;
	
	//Communication action Receive is about to start
    // $display("%m started receiving @ time = %0d", $time);
    r.Receive(ReceiveValue);
    // $display("%m finished receiving @ time = %0d, data = %b", $time, ReceiveValue);
	//Communication action Receive is finished
    
	#BL;
    // cycleCounter += 1;		
    // //Measuring throughput: calculate the number of Receives per unit of time  
    // //CycleTime stores the time it takes from the begining to the end of the always block
    // cycleTime = $time - timeOfReceive; // the difference of time between now and the last receive
    // averageThroughput = cycleCounter/$time; 
    // sumOfCycleTimes += cycleTime;
    // averageCycleTime = sumOfCycleTimes / cycleCounter;
    // // $display("Execution cycle= %d, Cycle Time= %d, Average CycleTime=%f, Average Throughput=%f", cycleCounter, cycleTime, averageCycleTime, averageThroughput);
	
	
  end

endmodule






