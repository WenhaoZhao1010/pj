// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac_array (clk, reset, out_s, in_w, in_n, inst_w, valid, os_en, c_q_all);

	parameter bw = 4;
	parameter psum_bw = 16;
	parameter col = 8;
	parameter row = 8;

	input  clk, reset;
	input  [row*bw-1:0] in_w; // inst[1]:execute, inst[0]: kernel loading
	input  [1:0] inst_w;
	input  [psum_bw*col-1:0] in_n;
	input  os_en;         // 0: WS, 1: OS

	output [col-1:0] valid;
	output [psum_bw*col-1:0] out_s;
	output [psum_bw*col*row-1:0] c_q_all;

	wire [row*col- 1:0] temp_v;
	wire [(row+1)*col*psum_bw-1:0] temp_in_n;
	reg [row*2-1:0] temp_inst;
	wire [psum_bw*col*row-1:0] temp_cq;

	assign valid = temp_v[col*row-1:col*(row-1)];
	assign temp_in_n[psum_bw*col-1:0] = in_n;
	assign out_s = temp_in_n[psum_bw*col*(row+1)-1 : psum_bw*col*(row)];
	assign c_q_all = temp_cq; 

	genvar i;
  	for (i=1; i < row+1 ; i=i+1) begin : row_num
		mac_row #(.bw(bw), .psum_bw(psum_bw)) mac_row_instance (
      		.clk(clk),
	  		.reset(reset),
			.os_en(os_en),
	  		.inst_w(temp_inst[2*i-1 : 2*(i-1)]),
	  		.in_w(in_w[bw*i-1 : bw*(i-1)]),
	  		.valid(temp_v[col*i-1 : col*(i-1)]),
	  		.in_n(temp_in_n[psum_bw*col*i-1 : psum_bw*col*(i-1)]),
	  		.out_s(temp_in_n[psum_bw*col*(i+1)-1 : psum_bw*col*i]),
			.c_q_row(temp_cq[psum_bw*col*i-1 : psum_bw*col*(i-1)]) 
      	);
  	end

	always @ (posedge clk) begin
    	if (reset == 1'b1) begin
            temp_inst <= {row*2{1'b0}};
        end else begin
            temp_inst <= {temp_inst[row*2-3:0], inst_w[1:0]};
        end
	end

endmodule
