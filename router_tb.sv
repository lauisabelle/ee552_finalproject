// test bench for one router

`timescale 1ns/1ns

// Import system verilog csp file
import SystemVerilogCSP::*;

module router_tb;
    parameter WIDTH_PACKAGE = 33;

    Channel #(.hsProtocol(P2PhaseBD), .WIDTH(WIDTH_PACKAGE)) intf  [9:0] ();

    data_generator dg_left (intf[0]);
    data_generator dg_down (intf[1]);
    data_generator dg_right (intf[2]);
    data_generator dg_up (intf[3]);
    data_generator dg_pemem (intf[4]);

    data_bucket db_left (intf[5]);
    data_bucket db_down (intf[6]);
    data_bucket db_right (intf[7]);
    data_bucket db_up (intf[8]);
    data_bucket db_pemem (intf[9]);

    // router No. 9
    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(4'b01_10)) router_9 (.left_in(intf[0]), .left_out(intf[5]), .down_in(intf[1]), .down_out(intf[6]),
         .right_in(intf[2]), .right_out(intf[7]), .up_in(intf[3]), .up_out(intf[8]), .pe_mem_in(intf[4]), .pe_mem_out(intf[9]));
endmodule


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
  // $display("Generated dest_id = %0d", dest_id);
  #FL;   // change FL and check the change of performance
    
  //Communication action Send is about to start
  // $display("%m started sending data @ time = %0d, data = %b", $time, SendValue);
  r.Send(SendValue);
  $display("%m finished sending package @ time = %0d, destination = %0d", $time, dest_id);
  //Communication action Send is finished
	

  end
endmodule

//Sample data_bucket module
module data_bucket (interface r);
  parameter WIDTH = 33;
  parameter BL = 0; //ideal environment    backward delay
  logic [WIDTH-1:0] ReceiveValue = 0;
  
  always
  begin
	
	//add a display here to see when this module starts its main loop
    // $display("*** %m started @ time = %0d",$time);

    // timeOfReceive = $time;
	
	//Communication action Receive is about to start
    // $display("%m started receiving @ time = %0d", $time);
    r.Receive(ReceiveValue);
    $display("%m finished receiving @ time = %0d, data = %b", $time, ReceiveValue[32:29]);
	//Communication action Receive is finished
    
	#BL;
	
  end

endmodule