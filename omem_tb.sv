// EE 552 Final Project Spring 2023
// Written by Izzy Lau
// Tests the behavior of the output memory

`timescale 1ns/1ns
import SystemVerilogCSP::*;

module omem_tb;
 parameter ADDR_START = 32;
  parameter ADDR_END = 29;
  parameter OPCODE_START = 28;
  parameter OPCODE_END = 25;
  parameter DATA_START = 24;
  parameter DATA_END = 0;
  parameter FL = 4;
  parameter BL = 2;

	//Interface Vector instatiation: 4-phase bundled data channel
	Channel #(.hsProtocol(P4PhaseBD), .WIDTH(50)) intf  [1:0] (); 

    Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) start_r ();
	Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) out_spike_data ();
	Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) out_spike_addr ();
	Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) ts_r ();
	Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) layer_r ();
	Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) done_r ();
	Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) router_in ();
	Channel #(.hsProtocol(P4PhaseBD), .WIDTH(33)) router_out ();

	omem omem_mod(.start_r(start_r), .out_spike_data(out_spike_data), .out_spike_addr(out_spike_addr), 
        .ts_r(ts_r), .layer_r(layer_r), .done_r(done_r), .router_in(router_in), .router_out(router_out));

	// Channel #(.hsProtocol(P4PhaseBD), .WIDTH(1)) start (); 
	data_bucket #(.WIDTH(33)) db(router_out);

	logic [ADDR_START:0] packet;
	logic [24:0] data = 0;

    logic [1:0] spike_addr;
    logic [1:0] spike_data;
    logic [1:0] val;

	always begin

        // Send timestep 1 potentials
        for(int i = 0; i < 21*21; i++) begin
            packet = 0;
            packet[ADDR_START:ADDR_END] = 4'd12;  
            packet[OPCODE_START:OPCODE_END] = {3'(i%5), 1'(0)}; 
            packet[DATA_START:DATA_END] = {24'(i), 1'(i%2)};
		$display("Sending data = %b", {24'(i), 1'(i%2)});
		$display("Opcode = %d", {3'(i%5), 1'(0)});
            router_in.Send(packet);
		#FL;
        end

	#200;

        // Send timestep 2 requests
        for(int i = 0; i < 21*21; i++) begin
            packet = 0;
            packet[ADDR_START:ADDR_END] = 4'd12;  
            packet[OPCODE_START:OPCODE_END] = {3'(i%5), 1'(1)}; 
            packet[DATA_START:DATA_END] = {24'(i), 1'(i%2)};
            $display("Sending req for prev, packet=%b", packet);
            router_in.Send(packet);
		    #FL;
			#BL;

            
            //router_out.Receive(packet);
		    $display("Received prev packet");
		    #BL;
		    
            packet = 0;

            // Send new potential and spike
            packet[ADDR_START:ADDR_END] = 4'd12;  
            packet[OPCODE_START:OPCODE_END] = {3'(i%5), 1'(0)}; 
            packet[DATA_START:DATA_END] = ({24'(i), 1'(i%2)});
            $display("i=%d, data = %b", i, {24'(i), 1'(i%2)});
            $display("Sending new data, packet=%b", packet);
            
            router_in.Send(packet);
		#FL;

        end
	
	$display("waiting for start");
        start_r.Receive(val);
	$display("received start");
	#FL;

        ts_r.Receive(val);
        layer_r.Receive(val);
	#FL;

        for(int i = 0; i < 21*21; i++) begin
            out_spike_addr.Receive(spike_addr);
            out_spike_data.Receive(spike_data);
		#FL;
        end

        ts_r.Receive(val);
        layer_r.Receive(val);
	#FL;

        for(int i = 0; i < 21*21; i++) begin
            out_spike_addr.Receive(spike_addr);
            out_spike_data.Receive(spike_data);
	#FL;
        end

        done_r.Receive(val);
	#FL;

		
	#500000;
	$stop;
	end


endmodule









//Sample data_bucket module
module data_bucket (interface r);
  parameter WIDTH = 8;
  parameter BL = 2; //ideal environment    backward delay
  logic [WIDTH-1:0] ReceiveValue = 0;
  
  //Variables added for performance measurements
  real cycleCounter=0, //# of cycles = Total number of times a value is received
	   timeOfReceive=0, //Simulation time of the latest Receive 
	   cycleTime=0; // time difference between the last two receives
  real averageThroughput=0, averageCycleTime=0, sumOfCycleTimes=0;
  always
  begin
	
	//add a display here to see when this module starts its main loop
	$display("*** %m %d",$time);
	timeOfReceive = $time;
	
	//Communication action Receive is about to start
	$display("Start receiving in module %m. Simulation time = %t", $time);
	r.Receive(ReceiveValue);
	
	//Communication action Receive is finished
	$display("Finished receiving in module %m. Simulation time = %t", $time);
	$display("Received value %d", ReceiveValue);
	  #BL;
	cycleCounter += 1;		
	//Measuring throughput: calculate the number of Receives per unit of time  
	//CycleTime stores the time it takes from the begining to the end of the always block
	cycleTime = $time - timeOfReceive; // the difference of time between now and the last receive
	averageThroughput = cycleCounter/$time; 
	sumOfCycleTimes += cycleTime;
	averageCycleTime = sumOfCycleTimes / cycleCounter;
	$display("Execution cycle= %d, Cycle Time= %f, Average CycleTime=%f, Average Throughput=%f", cycleCounter, cycleTime, averageCycleTime, averageThroughput);
	
	
  end
endmodule