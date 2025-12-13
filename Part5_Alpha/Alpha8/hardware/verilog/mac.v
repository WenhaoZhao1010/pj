// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac (out, a, b, c);

parameter a_bw = 2;
parameter w_bw = 4;
parameter psum_bw = 16;

output signed [psum_bw-1:0] out; // new psum signed
input signed  [a_bw-1:0] a;  // activation unsigned
input signed  [w_bw-1:0] b;  // weight signed
input signed  [psum_bw-1:0] c; // previous psum signed


wire signed [psum_bw:0] product;
wire signed [psum_bw-1:0] psum;
wire signed [a_bw:0]   a_pad;

assign a_pad = {1'b0, a}; // force to be unsigned number
assign product = a_pad * b;

assign psum = product + c;
assign out = psum;

endmodule
