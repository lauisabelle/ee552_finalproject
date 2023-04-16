/* testbench.sv
   
   SP23 EE-552 Final project 
   
   INSTRUCTIONS:
   1. You can add/modify code to this file, if needed.

*/

`timescale 1ns/1ps

import SystemVerilogCSP::*;

//control testbench
module noc_snn_tb(interface load_start, ifmap_data, ifmap_addr, timestep, filter_data, filter_addr, load_done, start_r, ts_r, layer_r, out_spike_addr, out_spike_data, done_r);

// parameters
parameter WIDTH_data = 8;
parameter WIDTH_addr = 12;
parameter WIDTH_out_data = 13;
parameter DEPTH_F= 5;
parameter DEPTH_I =25;
parameter DEPTH_R =21;

logic i1_data, i2_data, dn, st, s_r;
logic [1:0] ts=1, l_index;
logic [WIDTH_data-1:0] f_data;
logic [WIDTH_addr-1:0] i1_addr = 0, i2_addr=0, f_addr=0, out_addr;
logic [WIDTH_out_data-1:0] out_data;

logic [WIDTH_out_data-1:0] comp1[DEPTH_R*DEPTH_R-1:0];
logic [WIDTH_out_data-1:0] comp2[DEPTH_R*DEPTH_R-1:0];

integer error_count, fpt, fpi_f, fpi_i1, fpi_i2, fpi_out1, fpi_out2, fpo, status;
 

// watchdog timer
 initial begin
 #100000000;
 $display("*** Stopped by watchdog timer ***");
 $finish;
 end 
 

// main execution
initial begin
// sending values to M module
   fpi_f = $fopen("filter.txt","r");
   fpi_i1 = $fopen("ifmap1.txt","r");
   fpi_i2 = $fopen("ifmap2.txt", "r");


   fpi_out1 = $fopen("out_spike1.txt","r");
   fpi_out2 = $fopen("out_spike2.txt","r");
   fpo = $fopen("test.dump","w");
   fpt = $fopen("transcript.dump");


   if(!fpi_f || !fpi_i1 || !fpi_i2)
   begin
       $display("A file cannot be opened!");
       $finish;
   end

//sending to the memory filter and feature map
   else begin
	  load_start.Send(1);
	   for(integer i=0; i<(DEPTH_F*DEPTH_F); i++) begin
	    if(!$feof(fpi_f)) begin
	     status = $fscanf(fpi_f,"%d\n", f_data);
	     $display("filter data read:%d", f_data);
	     filter_addr.Send(f_addr);
	     filter_data.Send(f_data); 
	     f_addr++;
	    end end
	   
// sending ifmap 1 (timestep1)

	for(integer i=0; i<DEPTH_I*DEPTH_I; i++) begin
	    if (!$feof(fpi_i1)) begin
	     status = $fscanf(fpi_i1,"%d\n", i1_data);
	     $display("Ifmap1 data read:%d", i1_data);
     		timestep.Send(ts);
	     ifmap_addr.Send(i1_addr);
	     ifmap_data.Send(i1_data);

	     i1_addr++;
	 end end

	ts++;

// sending ifmap 2 (timestep2)

	for(integer i=0; i<DEPTH_I*DEPTH_I; i++) begin
	    if (!$feof(fpi_i2)) begin
	     status = $fscanf(fpi_i2,"%d\n", i2_data);
	     $display("Ifmap2 data read:%d", i2_data);
	     timestep.Send(ts);
	     ifmap_addr.Send(i2_addr);
	     ifmap_data.Send(i2_data);

	     i2_addr++;
	 end end
   end

//Finish sending the matrix values
  load_done.Send(1); 
  $fdisplay(fpt,"%m sent load_done token at %t",$realtime);
  $display("%m sent load_done token at %t",$realtime);


// waiting for the signal indicating the start of receiving outputs
   start_r.Receive(s_r);
   $timeformat(-9, 4, "ns");
   $display("tb: start_r Received at %t", $realtime);
   $fdisplay(fpt,"%m start_r token received at %t",$realtime);


// comparing results
   error_count=0;


  if (s_r ==1) begin

   ts_r.Receive(ts);
   layer_r.Receive(l_index);
   $display("Received timestep %d, layer, %d", ts, l_index);
   
   if (ts ==1 && l_index ==1) begin
	   // load golden result: output_spike 1
   	   for(integer i=0; i<(DEPTH_R*DEPTH_R); i++) begin
	    if(!$feof(fpi_out1)) begin
	     status = $fscanf(fpi_out1,"%d\n", out_data);
	     $display("GodenResult data read (output_spike 1):%d", out_data);
	     comp1[i] = out_data;
	     $fdisplay(fpt,"comp1[%d]= %d",i,out_data); 
	   end end

	   // compare results
	   for (integer i = 0; i<DEPTH_R*DEPTH_R; i++) begin
	       // timestep 1
	       out_spike_addr.Receive(out_addr);
	       out_spike_data.Receive(out_data);
	       
		if (out_data != comp1[out_addr]) begin
       		$fdisplay(fpo,"%d != %d error!",out_data,comp1[i]);
       		$fdisplay(fpt,"%d != %d error!",out_data,comp1[i]);
       		$display("%d != %d error!",out_data,comp1[i]);
   //    		$fdisplay(fpt,"%d == comp[%d] = %d", out_data, i, comp1[i]);
   //    		$fdisplay(fpo," %d == comp[%d] = %d", out_data, i, comp1[i]);
       		error_count++;
   		end else begin
      		$fdisplay(fpt,"%d == comp1[%d] = %d", out_data, i, comp1[i]);
       		$fdisplay(fpo,"%d == comp1[%d] = %d", out_data, i, comp1[i]);
       		$display("Passing comparison! Receive result value : %d at %t",out_data, $realtime);
    		end
	   end
   end

   # 2;
   ts_r.Receive(ts);
   layer_r.Receive(l_index);


   if (ts ==2 && l_index ==1) begin
	   // load golden result: output_spike 2
   	   for(integer i=0; i<(DEPTH_R*DEPTH_R); i++) begin
	    if(!$feof(fpi_out2)) begin
	     status = $fscanf(fpi_out2,"%d\n", out_data);
	     $display("GodenResult data read (output_spike 2):%d", out_data);
	     comp2[i] = out_data;
	     $fdisplay(fpt,"comp2[%d]= %d",i,out_data); 
	   end end

	   // compare results
	   for (integer i = 0; i<DEPTH_R*DEPTH_R; i++) begin
	       // timestep 1
	       out_spike_addr.Receive(out_addr);
	       out_spike_data.Receive(out_data);
	       
		if (out_data != comp2[out_addr]) begin
       		$fdisplay(fpo,"%d != %d error!",out_data,comp2[i]);
       		$fdisplay(fpt,"%d != %d error!",out_data,comp2[i]);
       		$display("%d != %d error!",out_data,comp2[i]);
      // 		$fdisplay(fpt,"%d == comp[%d] = %d", out_data, i, comp2[i]);
      // 		$fdisplay(fpo," %d == comp[%d] = %d", out_data, i, comp2[i]);
       		error_count++;
   		end else begin
      		$fdisplay(fpt,"%d == comp2[%d] = %d", out_data, i, comp2[i]);
       		$fdisplay(fpo,"%d == comp2[%d] = %d", out_data, i, comp2[i]);
       		$display("Passing comparison! Receive result value : %d at %t",out_data, $realtime);
    		end
	   end
   end

end

   done_r.Receive(dn);
   if (dn==1) begin
	  $fdisplay(fpo,"total errors = %d",error_count);
	  $fdisplay(fpt,"total errors = %d",error_count);
	  $display("total errors = %d",error_count); 
	 
	  $display("%m Results compared, ending simulation at %t",$realtime);
	  $fdisplay(fpt,"%m Results compared, ending simulation at %t",$realtime);
	  $fdisplay(fpo,"%m Results compared, ending simulation at %t",$realtime);
	  $fclose(fpt);
	  $fclose(fpo);
	  $finish;
	end

end
endmodule







//testbench instantiation
module testbench;
 Channel #(.hsProtocol(P4PhaseBD), .WIDTH(18)) intf  [12:0] (); 


// TODO you can add parameters if needed
 
 
// control testbench
// TODO you can add more interfaces if needed
noc_snn_tb tb( .ifmap_data(intf[0]), .ifmap_addr(intf[1]), .timestep(intf[2]), .filter_data(intf[3]), .filter_addr(intf[4]), 
.load_done(intf[5]), .ts_r(intf[6]), .layer_r(intf[7]), .done_r(intf[8]), .out_spike_addr(intf[9]), .out_spike_data(intf[10]), .load_start(intf[11]), .start_r(intf[12]));

//memory module
// TODO you can add more interfaces if needed (DO NOT remove interfaces)
noc_pe_mem_snn dut(.ifmap_data(intf[0]), .ifmap_addr(intf[1]), .timestep(intf[2]), .filter_data(intf[3]), .filter_addr(intf[4]), 
.load_done(intf[5]), .ts_r(intf[6]), .layer_r(intf[7]), .done_r(intf[8]), .out_spike_addr(intf[9]), .out_spike_data(intf[10]), .load_start(intf[11]), .start_r(intf[12])); 




// TODO instantiate other modules here ...


endmodule


module noc_pe_mem_snn(interface ifmap_data, ifmap_addr, timestep, filter_data, filter_addr,
			load_done, ts_r, layer_r, done_r,
			out_spike_addr, out_spike_data,
			load_start, start_r);
    parameter WIDTH_PACKAGE = 33;

    // WMEM channels
    Channel #(.hsProtocol(P2PhaseBD), .WIDTH(WIDTH_PACKAGE)) ch_wmem  [1:0] ();
    
    // IMEM channels
    Channel #(.hsProtocol(P2PhaseBD), .WIDTH(WIDTH_PACKAGE)) ch_imem  [1:0] ();

    // OMEM channels
    Channel #(.hsProtocol(P2PhaseBD), .WIDTH(WIDTH_PACKAGE)) ch_omem  [1:0] ();

	// SPE channels
	Channel #(.hsProtocol(P4PhaseBD), .WIDTH(35)) ch_spe  [9:0] (); 

	// PPE channels
	Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) ch_ppe  [9:0] (); 

	wmem #(.PE_ID(10)) wmem_mod( .load_start(load_start), .filter_addr(filter_addr), .filter_data(filter_data),
            .load_done(load_done), .router_in(ch_wmem[0]), .router_out(ch_wmem[1]));

	imem #(.PE_ID(11)) imem_mod( .load_start(load_start), .ifmap_addr(ifmap_addr), .ifmap_data(ifmap_data), .timestep(timestep), 
            .load_done(load_done), .router_in(ch_imem[0]), .router_out(ch_imem[1]));

	omem #(.PE_ID(12)) omem_mod(.start_r(start_r), .out_spike_data(out_spike_data), .out_spike_addr(out_spike_addr), 
        .ts_r(ts_r), .layer_r(layer_r), .done_r(done_r), .router_in(ch_omem[0]), .router_out(ch_omem[1]));

	spe #(.PE_ID(0)) spe_mod0(.spe_in(ch_spe[0]), .spe_out(ch_spe[1]));
	spe #(.PE_ID(1)) spe_mod1(.spe_in(ch_spe[2]), .spe_out(ch_spe[3]));
	spe #(.PE_ID(2)) spe_mod2(.spe_in(ch_spe[4]), .spe_out(ch_spe[5]));
	spe #(.PE_ID(3)) spe_mod3(.spe_in(ch_spe[6]), .spe_out(ch_spe[7]));
	spe #(.PE_ID(4)) spe_mod4(.spe_in(ch_spe[8]), .spe_out(ch_spe[9]));

	ppe #(.PE_ID(5)) ppe_mod5(.ppe_in(ch_ppe[0]), .ppe_out(ch_ppe[1]));
	ppe #(.PE_ID(6)) ppe_mod6(.ppe_in(ch_ppe[2]), .ppe_out(ch_ppe[3]));
	ppe #(.PE_ID(7)) ppe_mod7(.ppe_in(ch_ppe[4]), .ppe_out(ch_ppe[5]));
	ppe #(.PE_ID(8)) ppe_mod8(.ppe_in(ch_ppe[6]), .ppe_out(ch_ppe[7]));
	ppe #(.PE_ID(9)) ppe_mod9(.ppe_in(ch_ppe[8]), .ppe_out(ch_ppe[9]));

    // pm0_in = incoming channel into router = outgoing channel out of PE
	router_network rn(.pm0_in(ch_spe[1]), .pm0_out(ch_spe[0]), .pm1_in(ch_spe[3]), .pm1_out(ch_spe[2]), .pm2_in(ch_spe[5]), .pm2_out(ch_spe[4]), .pm3_in(ch_spe[7]), .pm3_out(ch_spe[6]), .pm4_in(ch_spe[9]), .pm4_out(ch_spe[8]),
    	.pm5_in(ch_ppe[1]), .pm5_out(ch_ppe[0]), .pm6_in(ch_ppe[3]), .pm6_out(ch_ppe[2]), .pm7_in(ch_ppe[5]), .pm7_out(ch_ppe[4]), .pm8_in(ch_ppe[7]), .pm8_out(ch_ppe[6]), .pm9_in(ch_ppe[9]), .pm9_out(ch_ppe[8]),
        .pm10_in(ch_wmem[1]), .pm10_out(ch_wmem[0]), .pm11_in(ch_imem[1]), .pm11_out(ch_imem[0]), .pm12_in(ch_omem[1]), .pm12_out(ch_omem[0]));
endmodule
 
