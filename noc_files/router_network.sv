// This file connects all elements in the NoC together to form the entire network.

`timescale 1ns/1ns

// Import system verilog csp file
import SystemVerilogCSP::*;


// 4 by 4
module router_network (interface pm0_in, interface pm0_out, interface pm1_in, interface pm1_out, interface pm2_in, interface pm2_out, interface pm3_in, interface pm3_out, interface pm4_in, interface pm4_out,
        interface pm5_in, interface pm5_out, interface pm6_in, interface pm6_out, interface pm7_in, interface pm7_out, interface pm8_in, interface pm8_out, interface pm9_in, interface pm9_out,
        interface pm10_in, interface pm10_out, interface pm11_in, interface pm11_out, interface pm12_in, interface pm12_out);
    parameter WIDTH_PACKAGE = 33;


    // 2 phase protocol
    // Vertical channels
    Channel #(.hsProtocol(P2PhaseBD), .WIDTH(WIDTH_PACKAGE)) vert  [31:0] ();
    // Horizontal channels
    Channel #(.hsProtocol(P2PhaseBD), .WIDTH(WIDTH_PACKAGE)) horiz  [31:0] ();
    // Channels for dummy PEs
    Channel #(.hsProtocol(P2PhaseBD), .WIDTH(WIDTH_PACKAGE)) intf  [5:0] ();

    // Instantiate routers
    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(4'b00_00)) router_0 (.left_in(horiz[0]), .left_out(horiz[1]), .down_out(vert[0]), .down_in(vert[1]),
         .right_in(horiz[3]), .right_out(horiz[2]), .up_out(vert[9]), .up_in(vert[8]), .pe_mem_in(pm0_in), .pe_mem_out(pm0_out));

    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(4'b01_00)) router_1 (.left_in(horiz[2]), .left_out(horiz[3]), .down_out(vert[2]), .down_in(vert[3]),
         .right_in(horiz[5]), .right_out(horiz[4]), .up_out(vert[11]), .up_in(vert[10]), .pe_mem_in(pm1_in), .pe_mem_out(pm1_out));

    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(4'b10_00)) router_2 (.left_in(horiz[4]), .left_out(horiz[5]), .down_out(vert[4]), .down_in(vert[5]),
         .right_in(horiz[7]), .right_out(horiz[6]), .up_out(vert[13]), .up_in(vert[12]), .pe_mem_in(pm2_in), .pe_mem_out(pm2_out));

    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(4'b11_00)) router_3 (.left_in(horiz[6]), .left_out(horiz[7]), .down_out(vert[6]), .down_in(vert[7]),
         .right_in(horiz[1]), .right_out(horiz[0]), .up_out(vert[15]), .up_in(vert[14]), .pe_mem_in(pm3_in), .pe_mem_out(pm3_out));

    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(4'b00_01)) router_4 (.left_in(horiz[8]), .left_out(horiz[9]), .down_out(vert[8]), .down_in(vert[9]),
         .right_in(horiz[11]), .right_out(horiz[10]), .up_out(vert[17]), .up_in(vert[16]), .pe_mem_in(pm4_in), .pe_mem_out(pm4_out));

    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(4'b01_01)) router_5 (.left_in(horiz[10]), .left_out(horiz[11]), .down_out(vert[10]), .down_in(vert[11]),
         .right_in(horiz[13]), .right_out(horiz[12]), .up_out(vert[19]), .up_in(vert[18]), .pe_mem_in(pm5_in), .pe_mem_out(pm5_out));

    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(4'b10_01)) router_6 (.left_in(horiz[12]), .left_out(horiz[13]), .down_out(vert[12]), .down_in(vert[13]),
         .right_in(horiz[15]), .right_out(horiz[14]), .up_out(vert[21]), .up_in(vert[20]), .pe_mem_in(pm6_in), .pe_mem_out(pm6_out));

    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(5'b11_01)) router_7 (.left_in(horiz[14]), .left_out(horiz[15]), .down_out(vert[14]), .down_in(vert[15]),
         .right_in(horiz[9]), .right_out(horiz[8]), .up_out(vert[23]), .up_in(vert[22]), .pe_mem_in(pm7_in), .pe_mem_out(pm7_out));

    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(4'b00_10)) router_8 (.left_in(horiz[16]), .left_out(horiz[17]), .down_out(vert[16]), .down_in(vert[17]),
         .right_in(horiz[19]), .right_out(horiz[18]), .up_out(vert[25]), .up_in(vert[24]), .pe_mem_in(pm8_in), .pe_mem_out(pm8_out));

    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(4'b01_10)) router_9 (.left_in(horiz[18]), .left_out(horiz[19]), .down_out(vert[18]), .down_in(vert[19]),
         .right_in(horiz[21]), .right_out(horiz[20]), .up_out(vert[27]), .up_in(vert[26]), .pe_mem_in(pm9_in), .pe_mem_out(pm9_out));

    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(4'b10_10)) router_10 (.left_in(horiz[20]), .left_out(horiz[21]), .down_out(vert[20]), .down_in(vert[21]),
         .right_in(horiz[23]), .right_out(horiz[22]), .up_out(vert[29]), .up_in(vert[28]), .pe_mem_in(pm10_in), .pe_mem_out(pm10_out));

    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(4'b11_10)) router_11 (.left_in(horiz[22]), .left_out(horiz[23]), .down_out(vert[22]), .down_in(vert[23]),
         .right_in(horiz[17]), .right_out(horiz[16]), .up_out(vert[31]), .up_in(vert[30]), .pe_mem_in(pm11_in), .pe_mem_out(pm11_out));

    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(4'b00_11)) router_12 (.left_in(horiz[24]), .left_out(horiz[25]), .down_out(vert[24]), .down_in(vert[25]),
         .right_in(horiz[27]), .right_out(horiz[26]), .up_out(vert[1]), .up_in(vert[0]), .pe_mem_in(pm12_in), .pe_mem_out(pm12_out));

    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(4'b01_11)) router_13 (.left_in(horiz[26]), .left_out(horiz[27]), .down_out(vert[26]), .down_in(vert[27]),
         .right_in(horiz[29]), .right_out(horiz[28]), .up_out(vert[3]), .up_in(vert[2]), .pe_mem_in(intf[1]), .pe_mem_out(intf[0]));
     
    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(4'b10_11)) router_14 (.left_in(horiz[28]), .left_out(horiz[29]), .down_out(vert[28]), .down_in(vert[29]),
         .right_in(horiz[31]), .right_out(horiz[30]), .up_out(vert[5]), .up_in(vert[4]), .pe_mem_in(intf[3]), .pe_mem_out(intf[2]));

    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(4'b11_11)) router_15 (.left_in(horiz[30]), .left_out(horiz[31]), .down_out(vert[30]), .down_in(vert[31]),
         .right_in(horiz[25]), .right_out(horiz[24]), .up_out(vert[7]), .up_in(vert[6]), .pe_mem_in(intf[5]), .pe_mem_out(intf[4]));

     dummy_pe dp0 (intf[0], intf[1]);
     dummy_pe dp1 (intf[2], intf[3]);
     dummy_pe dp2 (intf[4], intf[5]);



endmodule


// This is a dummy pe that doesn't do anything.
// It's only purpose is to be attached to the routers that are not connected to actual mem or pes.
module dummy_pe (interface in, interface out);
endmodule