// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module sram_32b_w2048 #(
    parameter width=32,
    parameter num = 2048
)(clk, D, Q, CEN, WEN, A);

  input  clk;
  input  WEN;
  input  CEN;
  input  [width-1:0] D;
  input  [10:0] A;
  output [width-1:0] Q;

  reg [width-1:0] memory [num-1:0];
  reg [10:0] add_q;
  assign Q = memory[add_q];

  always @ (posedge clk) begin

   if (!CEN && WEN) // read 
      add_q <= A;
   if (!CEN && !WEN) // write
      memory[A] <= D; 

  end

endmodule