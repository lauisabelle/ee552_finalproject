// Test bench for the router network

`timescale 1ns/1ns

// Import system verilog csp file
import SystemVerilogCSP::*;

module router_network_tb;

    parameter WIDTH_PACKAGE = 33;

    Channel #(.hsProtocol(P2PhaseBD), .WIDTH(WIDTH_PACKAGE)) intf  [25:0] ();

    router_network dut (.pm0_in(intf[0]), .pm0_out(intf[13]), .pm1_in(intf[1]), .pm1_out(intf[14]), .pm2_in(intf[2]), .pm2_out(intf[15]), .pm3_in(intf[3]), .pm3_out(intf[16]), .pm4_in(intf[4]), .pm4_out(intf[17]),
            .pm5_in(intf[5]), .pm5_out(intf[18]), .pm6_in(intf[6]), .pm6_out(intf[19]), .pm7_in(intf[7]), .pm7_out(intf[20]), .pm8_in(intf[8]), .pm8_out(intf[21]), .pm9_in(intf[9]), .pm9_out(intf[22]),
            .pm10_in(intf[10]), .pm10_out(intf[23]), .pm11_in(intf[11]), .pm11_out(intf[24]), .pm12_in(intf[12]), .pm12_out(intf[25]));


    data_generator dg0 (intf[0]);
    data_generator dg1 (intf[1]);
    data_generator dg2 (intf[2]);
    data_generator dg3 (intf[3]);
    data_generator dg4 (intf[4]);
    data_generator dg5 (intf[5]);
    data_generator dg6 (intf[6]);
    data_generator dg7 (intf[7]);
    data_generator dg8 (intf[8]);
    data_generator dg9 (intf[9]);
    data_generator dg10 (intf[10]);
    data_generator dg11 (intf[11]);
    data_generator dg12 (intf[12]);

    data_bucket db0 (intf[13]);
    data_bucket db1 (intf[14]);
    data_bucket db2 (intf[15]);
    data_bucket db3 (intf[16]);
    data_bucket db4 (intf[17]);
    data_bucket db5 (intf[18]);
    data_bucket db6 (intf[19]);
    data_bucket db7 (intf[20]);
    data_bucket db8 (intf[21]);
    data_bucket db9 (intf[22]);
    data_bucket db10 (intf[23]);
    data_bucket db11 (intf[24]);
    data_bucket db12 (intf[25]);

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

    r.Receive(ReceiveValue);
    $display("%m finished receiving @ time = %0d, data = %b", $time, ReceiveValue[32:29]);
	//Communication action Receive is finished
    
	#BL;

  end

endmodule