// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac_array (clk, ctrl, reset, out_s, in_x_0, in_x_1, in_w_0, in_w_1, inst_w, valid, in_psum_c);

    parameter a_bw = 2;
    parameter w_bw = 4;
    parameter psum_bw = 16;
    parameter col = 8;
    parameter row = 8;

    input  clk, reset;
    input  ctrl; // 0 represents 2bit activation, 1 represents 4bit activation
    output [psum_bw*col-1:0] out_s;
    output [col-1:0] valid;
    input  [row*a_bw-1:0] in_x_0; // Input activations low bits
    input  [row*a_bw-1:0] in_x_1; // Input activations high bits
    input  [row*w_bw-1:0] in_w_0; // Weight inputs
    input  [row*w_bw-1:0] in_w_1; // Weight inputs
    input  [1:0] inst_w;
    input  [psum_bw*col-1:0] in_psum_c;

    wire [row*col-1:0] temp_v;
    wire [(row+1)*col*psum_bw-1:0] temp_out_s;
    reg [row*2-1:0] temp_inst;

    assign valid = temp_v[col*row-1:col*(row-1)];
    assign temp_out_s[psum_bw*col-1:0] = in_psum_c;
    assign out_s = temp_out_s[psum_bw*col*(row+1)-1 : psum_bw*col*row];

    genvar i;
    for (i=1; i < row+1; i=i+1) begin : row_num
        mac_row #(.a_bw(a_bw), .w_bw(w_bw), .psum_bw(psum_bw), .col(col)) mac_row_instance (
            .clk(clk),
            .ctrl(ctrl),
            .reset(reset),
            .inst_w(temp_inst[2*i-1 : 2*(i-1)]),
            .in_x_0(in_x_0[a_bw*i-1 : a_bw*(i-1)]),
            .in_x_1(in_x_1[a_bw*i-1 : a_bw*(i-1)]),
            .in_w_0(in_w_0[w_bw*i-1 : w_bw*(i-1)]),
            .in_w_1(in_w_1[w_bw*i-1 : w_bw*(i-1)]),
            .valid(temp_v[col*i-1 : col*(i-1)]),
            .in_psum_c(temp_out_s[psum_bw*col*i-1 : psum_bw*col*(i-1)]),
            .out_s(temp_out_s[psum_bw*col*(i+1)-1 : psum_bw*col*i])
        );
    end

    always @ (posedge clk) begin
        if (reset) begin
            temp_inst <= 0;
        end
        else begin
            temp_inst <= {temp_inst[row*2-3:0], inst_w[1:0]};
        end
    end

endmodule