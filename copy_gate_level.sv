`timescale 1ns/1fs


// Module c_element
module c_element (in1, in2, out);
    input in1, in2;
    output reg out;

    initial out = 0;

    always @(in1, in2) begin
        // Here we intentionally design a latch
        // as it follows the behavior of a c element
        if ((!in1) && (!in2)) out = 0;
        else if ((in1) && (in2)) out = 1;
    end

endmodule


// D Flip-flop
module dff (en, data_in, data_out);
    // (.en(), .data_in(), .data_out())
    parameter WIDTH = 8;
    input en;
    input [WIDTH-1:0] data_in;
    output reg [WIDTH-1:0] data_out;
    always @ (posedge en) data_out <= data_in;
endmodule


module control (l_req, l_ack, r_req, r_ack, dff_en);
    // (.l_req(), .l_ack(), .r_req(), .r_ack(), .dff_en())
    input l_req, r_ack;
    output l_ack, r_req, dff_en;

    wire w1;
    reg w2;

    // Assign the initial state
    initial begin
        w2 = 0;
    end

    // combinational gates
    assign w1 = (!l_req && w2 && r_ack) || (l_req && !w2 && !r_ack);

    // use the dff module
    dff #(.WIDTH(1)) dff_control (w1, !w2, w2);

    // assign the output signals
    assign dff_en = w1;
    assign l_ack = w2;
    assign r_req = w2;

endmodule


module data_copy(l_req, l_ack, r1_ack, r1_req, r2_ack, r2_req, in, out_1, out_2);
    parameter WIDTH = 8;
    parameter FL = 2;
    parameter BL = 4;
    input l_req, r1_ack, r2_ack;
    input [WIDTH-1:0] in;
    output l_ack, r1_req, r2_req;
    output reg [WIDTH-1:0] out_1, out_2;

    wire r_req_raw;
    reg r_ack_raw;
    wire dff_en;
    wire ack_comb;
    wire [WIDTH-1:0] data_raw;
    reg r1_req, r2_req;

    // Instantiate the control module
    control dc_ctl (.l_req(l_req), .l_ack(l_ack), .r_req(r_req_raw), 
                    .r_ack(r_ack_raw), .dff_en(dff_en));
    // Reg
    dff #(.WIDTH(WIDTH)) dc_reg (.en(dff_en), .data_in(in), .data_out(data_raw));

    // Combinational logic
    always @(data_raw) begin
        out_1 = #FL data_raw;
        out_2 = #FL data_raw;
    end

    // A c element to merge two acknowledgements to
    // generate a combined acknowledgement
    c_element c (r1_ack, r2_ack, ack_comb);

    // Handshake signals with delay lines
    always @(r_req_raw) begin
        r1_req = #FL r_req_raw;
        r2_req = #FL r_req_raw;
    end
    always @(ack_comb) begin
        r_ack_raw = #BL ack_comb;
    end
endmodule

module data_generator (req, ack, data);
    parameter WIDTH = 8;

    input ack;
    output reg req;
    output reg [WIDTH-1:0] data;

    reg phase;

    initial begin
        req = 0;
        phase = 1;
    end

    always begin
        req = phase;
        data = $random() % (2**WIDTH);
        $display("data = %b being sent to copy", data);
        wait (ack == phase);
        phase = ~phase;
    end
endmodule

module data_bucket(req, ack, data);
    parameter WIDTH = 8;

    input req;
    input [WIDTH-1:0] data;
    output reg ack;

    reg phase;
    reg [WIDTH-1:0] mem;

    //Variables added for performance measurements
    real cycleCounter=0, //# of cycles = Total number of times a value is received
       timeOfReceive=0, //Simulation time of the latest Receive 
       cycleTime=0; // time difference between the last two receives
    real averageThroughput=0, averageCycleTime=0, sumOfCycleTimes=0;

    initial begin
        ack = 0;
        phase = 1;
    end

    always begin
        timeOfReceive = $time;
        wait(req == phase);
        ack = phase;
        mem = data;
        $display("%m finished received data = %b", data);
        phase = ~phase;
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

module copy_gate_level_tb;
    wire l_req, l_ack, r1_ack, r1_req, r2_ack, r2_req;
    wire [7:0] in, out_1, out_2;

    data_generator dg (l_req, l_ack, in);
    data_copy copy (l_req, l_ack, r1_ack, r1_req, r2_ack, r2_req, in, out_1, out_2);
    data_bucket dg_0 (r1_req, r1_ack, out_1);
    data_bucket dg_1 (r2_req, r2_ack, out_2);

endmodule