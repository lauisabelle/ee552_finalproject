// This file connects all elements in the NoC together to form the entire network.

`timescale 1ns/1ns

// Import system verilog csp file
import SystemVerilogCSP::*;

module noc;
    parameter WIDTH_PACKAGE = 33;


    // 2 phase protocol
    // Channels connecting routers
    Channel #(.hsProtocol(P2PhaseBD), .WIDTH(WIDTH_PACKAGE)) intf  [29:0] ();
    
    // Channels connecting PE/MEMs to routers
    Channel #(.hsProtocol(P2PhaseBD), .WIDTH(WIDTH_PACKAGE)) ch_pe_mem  [15:0] ();

    // WMEM channels
    Channel #(.hsProtocol(P2PhaseBD), .WIDTH(WIDTH_PACKAGE)) ch_wmem  [5:0] ();
    
    // IMEM channels
    Channel #(.hsProtocol(P2PhaseBD), .WIDTH(WIDTH_PACKAGE)) ch_imem  [6:0] ();

    // OMEM channels
    Channel #(.hsProtocol(P2PhaseBD), .WIDTH(WIDTH_PACKAGE)) ch_omem  [7:0] ();

   //Interface Vector instatiation: 4-phase bundled data channel
	// Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) load_start ();
	// Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) filter_addr ();
	// Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) filter_data ();
	// Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) load_done ();
	// Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) router_in ();
	// Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) router_out ();


	wmem wmem_mod( .load_start(ch_wmem[0]), .filter_addr(ch_wmem[1]), .filter_data(ch_wmem[2]),
            .load_done(ch_wmem[3]), .router_in(ch_wmem[4]), .router_out(ch_wmem[5]));



    // Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) load_start ();
	// Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) ifmap_addr ();
	// Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) ifmap_data ();
	// Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) timestep ();
	// Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) load_done ();
	// Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) router_in ();
	// Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) router_out ();


	imem imem_mod( .load_start(ch_imem[0]), .ifmap_addr(ch_imem[1]), .ifmap_data(ch_imem[2]), .timestep(ch_imem[3]), 
            .load_done(ch_imem[4]), .router_in(ch_imem[5]), .router_out(ch_imem[6]));


    // Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) start_r ();
	// Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) out_spike_data ();
	// Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) out_spike_addr ();
	// Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) ts_r ();
	// Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) layer_r ();
	// Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) done_r ();
	// Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) router_in ();
	// Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) router_out ();

	omem omem_mod(.start_r(ch_omem[0]), .out_spike_data(ch_omem[1]), .out_spike_addr(ch_omem[2]), 
        .ts_r(ch_omem[3]), .layer_r(ch_omem[4]), .done_r(ch_omem[5]), .router_in(ch_omem[6]), .router_out(ch_omem[7]));


    //Interface Vector instatiation: 4-phase bundled data channel
	Channel #(.hsProtocol(P4PhaseBD), .WIDTH(35)) ch_spe  [1:0] (); 

	spe spe_mod(.spe_in(ch_spe[0]), .spe_out(ch_spe[1]));



    //Interface Vector instatiation: 4-phase bundled data channel
	Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) ch_ppe  [1:0] (); 

	ppe ppe_mod(.ppe_in(ch_ppe[0]), .ppe_out(ch_ppe[1]));


    // Instantiate routers
    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(5'b000_00)) router_0 (.left(intf[15]), .right(intf[16]), .up(intf[5]), .down(intf[0]), .pe_mem(ch_pe_mem[0]));
    // TO DO: Connect SPE to router_0 below through channel ch_pe_mem[0]

    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(5'b001_00)) router_1 (.left(intf[16]), .right(intf[17]), .up(intf[6]), .down(intf[1]), .pe_mem(ch_pe_mem[1]));
    // TO DO: Connect SPE to router_1 below through channel ch_pe_mem[1]

    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(5'b010_00)) router_2 (.left(intf[17]), .right(intf[18]), .up(intf[7]), .down(intf[2]), .pe_mem(ch_pe_mem[2]));
    // TO DO: Connect SPE to router_2 below through channel ch_pe_mem[2]

    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(5'b011_00)) router_3 (.left(intf[18]), .right(intf[19]), .up(intf[8]), .down(intf[3]), .pe_mem(ch_pe_mem[3]));
    // TO DO: Connect SPE to router_3 below through channel ch_pe_mem[3]

    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(5'b100_00)) router_4 (.left(intf[19]), .right(intf[15]), .up(intf[9]), .down(intf[4]), .pe_mem(ch_pe_mem[4]));
    // TO DO: Connect SPE to router_4 below through channel ch_pe_mem[4]

    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(5'b000_01)) router_5 (.left(intf[20]), .right(intf[21]), .up(intf[10]), .down(intf[5]), .pe_mem(ch_pe_mem[5]));
    // TO DO: Connect PPE to router_5 below through channel ch_pe_mem[5]

    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(5'b001_01)) router_6 (.left(intf[21]), .right(intf[22]), .up(intf[11]), .down(intf[6]), .pe_mem(ch_pe_mem[6]));
    // TO DO: Connect PPE to router_6 below through channel ch_pe_mem[6]

    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(5'b010_01)) router_7 (.left(intf[22]), .right(intf[23]), .up(intf[12]), .down(intf[7]), .pe_mem(ch_pe_mem[7]));
    // TO DO: Connect PPE to router_7 below through channel ch_pe_mem[7]

    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(5'b011_01)) router_8 (.left(intf[23]), .right(intf[24]), .up(intf[13]), .down(intf[8]), .pe_mem(ch_pe_mem[8]));
    // TO DO: Connect PPE to router_8 below through channel ch_pe_mem[8]

    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(5'b100_01)) router_9 (.left(intf[24]), .right(intf[20]), .up(intf[14]), .down(intf[9]), .pe_mem(ch_pe_mem[9]));
    // TO DO: Connect PPE to router_9 below through channel ch_pe_mem[9]

    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(5'b000_10)) router_10 (.left(intf[25]), .right(intf[26]), .up(intf[0]), .down(intf[10]), .pe_mem(ch_pe_mem[10]));
    // TO DO: Connect WMEM to router_10 below through channel ch_pe_mem[10]

    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(5'b001_10)) router_11 (.left(intf[26]), .right(intf[27]), .up(intf[1]), .down(intf[11]), .pe_mem(ch_pe_mem[11]));
    // TO DO: Connect IMEM to router_11 below through channel ch_pe_mem[11]

    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(5'b010_10)) router_12 (.left(intf[27]), .right(intf[28]), .up(intf[2]), .down(intf[12]), .pe_mem(ch_pe_mem[12]));
    // TO DO: Connect OMEM to router_12 below through channel ch_pe_mem[12]

    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(5'b011_10)) router_13 (.left(intf[28]), .right(intf[29]), .up(intf[3]), .down(intf[13]), .pe_mem(ch_pe_mem[13]));
    // Since router 13 is a dummy router, we connect a data bucket to it, though it will never receive anything.
    data_bucket #(.WIDTH(WIDTH_PACKAGE)) db_0 (.r(intf[13]));

    router #(.WIDTH_PACKAGE(WIDTH_PACKAGE), .ROUTER_LOC(5'b100_10)) router_14 (.left(intf[29]), .right(intf[25]), .up(intf[4]), .down(intf[14]), .pe_mem(ch_pe_mem[14]));
    // Since router 14 is a dummy router, we connect a data bucket to it, though it will never receive anything.
    data_bucket #(.WIDTH(WIDTH_PACKAGE)) db_1 (.r(intf[14]));




endmodule