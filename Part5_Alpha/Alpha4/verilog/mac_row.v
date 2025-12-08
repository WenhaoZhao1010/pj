// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac_row (clk, ctrl, out_s, in_x_0, in_x_1, in_w_0, in_w_1, valid, inst_w, in_psum_c, reset);

    parameter a_bw = 2;
    parameter w_bw = 4;
    parameter psum_bw = 16;
    parameter col = 8;

    input  clk, reset;
    input  ctrl; // 0 represents 2bit activation, 1 represents 4bit activation
    output [psum_bw*col-1:0] out_s;
    output [col-1:0] valid; //let fifo know
    input  [a_bw-1:0] in_x_0; // Input activations low bits
    input  [a_bw-1:0] in_x_1; // Input activations high bits
    input  [w_bw-1:0] in_w_0; // Weight inputs
    input  [w_bw-1:0] in_w_1; // Weight inputs
    input  [1:0] inst_w;
    input  [psum_bw*col-1:0] in_psum_c;

    wire [(col+1)*a_bw-1:0] temp_x_0;
    wire [(col+1)*a_bw-1:0] temp_x_1;
    wire [(col+1)*w_bw-1:0] temp_w_0;
    wire [(col+1)*w_bw-1:0] temp_w_1;
    wire [(col+1)*2-1:0] temp_inst;
    wire [psum_bw*col-1:0] temp_out_s;
    wire [psum_bw*col-1:0] temp_in_psum_c;

    assign temp_x_0[a_bw-1:0] = in_x_0;
    assign temp_x_1[a_bw-1:0] = in_x_1;
    assign temp_w_0[w_bw-1:0] = in_w_0;
    assign temp_w_1[w_bw-1:0] = in_w_1;
    assign temp_inst[1:0] = inst_w;
    assign temp_in_psum_c = in_psum_c;

    genvar i;
    for (i=1; i < col+1; i=i+1) begin : col_num
        mac_tile #(.a_bw(a_bw), .w_bw(w_bw), .psum_bw(psum_bw)) mac_tile_instance (
            .clk(clk),
            .ctrl(ctrl),
            .reset(reset),
            .in_x_0(temp_x_0[a_bw*i-1:a_bw*(i-1)]),
            .in_x_1(temp_x_1[a_bw*i-1:a_bw*(i-1)]),
            .in_w_0(temp_w_0[w_bw*i-1:w_bw*(i-1)]),
            .in_w_1(temp_w_1[w_bw*i-1:w_bw*(i-1)]),
            .out_x_0(temp_x_0[a_bw*(i+1)-1:a_bw*i]),
            .out_x_1(temp_x_1[a_bw*(i+1)-1:a_bw*i]),
            .out_w_0(temp_w_0[w_bw*(i+1)-1:w_bw*i]),
            .out_w_1(temp_w_1[w_bw*(i+1)-1:w_bw*i]),
            .inst_w(temp_inst[2*i-1:2*(i-1)]),
            .inst_e(temp_inst[2*(i+1)-1:2*i]),
            .in_psum_c(temp_in_psum_c[(psum_bw*i)-1:psum_bw*(i-1)]),
            .out_s(temp_out_s[(psum_bw*i)-1:psum_bw*(i-1)])
        );
        assign valid[i-1] = temp_inst[2*(i+1)-1];
    end

    assign out_s = temp_out_s;

endmodule