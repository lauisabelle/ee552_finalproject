// gate level design of the MAC module and its tb
// Mengyu Sun

`timescale 1ns/1ns

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

module mult (l0_req, l1_req, l0_ack, l1_ack, l0_data, l1_data, r_req, r_ack, r_data);
    parameter FL = 2;
    parameter BL = 1;

    input l0_req, l1_req;
    output l0_ack, l1_ack;
    output r_req;
    input r_ack;
    input [3:0] l0_data, l1_data;
    output reg [7:0] r_data;

    reg r_req, r_ack_raw;
    wire r_req_raw;
    wire l_ack;
    wire l_req;
    wire dff_en;
    wire [7:0] dff_out;

    c_element c (l0_req, l1_req, l_req);
    control ctl (l_req, l_ack, r_req_raw, r_ack_raw, dff_en);
    dff ff (dff_en, {l0_data, l1_data}, dff_out);

    always @(r_req_raw) r_req = #FL r_req_raw;
    always @(r_ack) r_ack_raw = #BL r_ack;
    always @(dff_out) r_data = #FL dff_out[7:4] * dff_out[3:0];

    assign l0_ack = l_ack;
    assign l1_ack = l_ack;

    // assign #FL r_req = r_req_raw;
    // assign #BL r_ack_raw = r_ack;
    // assign #FL r_data = dff_out[7:4] * dff_out[3:0];
    

endmodule


module sum (l0_req, l1_req, l0_ack, l1_ack, l0_data, l1_data, r_req, r_ack, r_data);
    parameter FL = 2;
    parameter BL = 1;

    input l0_req, l1_req;
    output l0_ack, l1_ack;
    output r_req;
    input r_ack;
    input [7:0] l0_data, l1_data;
    output reg [8:0] r_data;

    reg r_req, r_ack_raw;
    wire r_req_raw;
    wire l_ack;
    wire l_req;
    wire dff_en;
    wire [15:0] dff_out;

    c_element c (l0_req, l1_req, l_req);
    control ctl (l_req, l_ack, r_req_raw, r_ack_raw, dff_en);
    dff #(.WIDTH(16)) ff (dff_en, {l0_data, l1_data}, dff_out);
    always @(r_req_raw) r_req = #FL r_req_raw;
    always @(r_ack) r_ack_raw = #BL r_ack;
    always @(dff_out) r_data = #FL dff_out[7:0] + dff_out[15:8];

    assign l0_ack = l_ack;
    assign l1_ack = l_ack;

    // assign #FL r_req = r_req_raw;
    // assign #BL r_ack_raw = r_ack;
    // assign #FL r_data = dff_out[7:0] + dff_out[15:8];

endmodule


module data_bucket(req, ack, data);
    parameter WIDTH = 8;

    input req;
    input [WIDTH-1:0] data;
    output reg ack;

    reg phase;
    reg [WIDTH-1:0] mem;


    initial begin
        ack = 0;
        phase = 1;
    end

    always begin
        // timeOfReceive = $time;
        wait(req == phase);
        ack = phase;
        mem = data;
        $display("result = %d", data);
        // #2;
        phase = ~phase;
    end
endmodule

module data_generator (req, ack, data);
    parameter WIDTH = 4;
    parameter DELAY = 2;

    input ack;
    output reg req;
    output reg [WIDTH-1:0] data;

    reg phase;

    initial begin
        req = 0;
        phase = 1;
    end

    always begin
        #DELAY;
        req = phase;
        data = $random() % (2**WIDTH);
        $display("%m generated data = %d", data);
        wait (ack == phase);
        
        phase = ~phase;
    end
endmodule

module tb;

    wire w0_req, w0_ack;
    wire [3:0] w0_data;

    wire w1_req, w1_ack;
    wire [3:0] w1_data;

    wire i1_req, i1_ack;
    wire [3:0] i1_data;

    wire i0_req, i0_ack;
    wire [3:0] i0_data;

    wire m0_req, m0_ack;
    wire [7:0] m0_data;

    wire m1_req, m1_ack;
    wire [7:0] m1_data;

    wire s_req, s_ack;
    wire [8:0] s_data;

    data_generator #(.DELAY(2)) w0 (w0_req, w0_ack, w0_data);
    data_generator #(.DELAY(1)) w1 (w1_req, w1_ack, w1_data);
    
    data_generator #(.DELAY(3)) i0 (i0_req, i0_ack, i0_data);
    data_generator i1 (i1_req, i1_ack, i1_data);

    mult m0 (w0_req, i0_req, w0_ack, i0_ack, w0_data, i0_data, m0_req, m0_ack, m0_data);
    mult m1 (w1_req, i1_req, w1_ack, i1_ack, w1_data, i1_data, m1_req, m1_ack, m1_data);

    sum s (m0_req, m1_req, m0_ack, m1_ack, m0_data, m1_data, s_req, s_ack, s_data);

    data_bucket #(.WIDTH(8)) db (m0_req, m0_ack, m0_data);


endmodule