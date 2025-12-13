// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac_tile (clk, ctrl, out_s, in_x_0, in_x_1, in_w_0, in_w_1, out_x_0, out_x_1, out_w_0, out_w_1, inst_w, inst_e, in_psum_c, reset);

parameter a_bw = 2;
parameter w_bw = 4;
parameter psum_bw = 16;

input ctrl;// 0 represents 2bit activation, 1 represents 4bit activation
output [psum_bw-1:0] out_s;
input  [a_bw-1:0] in_x_0;
input  [a_bw-1:0] in_x_1;
input  [w_bw-1:0] in_w_0;
input  [w_bw-1:0] in_w_1; 
output [a_bw-1:0] out_x_0;
output [a_bw-1:0] out_x_1;
output [w_bw-1:0] out_w_0;
output [w_bw-1:0] out_w_1; 
input  [1:0] inst_w;// inst[1]:execute, inst[0]: kernel loading
output [1:0] inst_e;
input  [psum_bw-1:0] in_psum_c;
input  clk;
input  reset;

reg [1:0] inst_q;
reg [a_bw-1:0] a_q_0;      
reg [a_bw-1:0] a_q_1;      
reg [w_bw-1:0] b_q_0; // reg to hold weight for MAC0
reg [w_bw-1:0] b_q_1; // reg to hold weight for MAC1
reg [w_bw-1:0] out_w_0_q; // to pass weight to next mac_tile
reg [w_bw-1:0] out_w_1_q;
reg [psum_bw-1:0] c_q;
wire [psum_bw-1:0] mac_out_0;
wire [psum_bw-1:0] mac_out_1;
wire [psum_bw-1:0] mac_out_comb;
reg load_ready_q;

// 2-bit mode MAC instances (using lower 2 bits of activations)
mac #(.a_bw(a_bw), .w_bw(w_bw), .psum_bw(psum_bw)) mac_instance_0 (
    .out(mac_out_0),
    .a(a_q_0), 
    .b(b_q_0),
    .c(0)
);

mac #(.a_bw(a_bw), .w_bw(w_bw), .psum_bw(psum_bw)) mac_instance_1 (
    .out(mac_out_1),
    .a(a_q_1), 
    .b(b_q_1),
    .c(0)
);

assign out_x_0 = a_q_0;
assign out_x_1 = a_q_1;
assign out_w_0 = out_w_0_q;
assign out_w_1 = out_w_1_q;
assign inst_e = inst_q;
assign mac_out_comb = (mac_out_1 << 2) + mac_out_0; // Shift high bits left by 2 positions
assign out_s = ctrl ? (mac_out_comb + c_q) : (mac_out_0 + mac_out_1 + c_q); // Final output based on mode


always @ (posedge clk) begin
    if (reset) begin
        inst_q <= 0;
        load_ready_q <= 1'b1;
        a_q_0 <= 0;
        a_q_1 <= 0;
        b_q_0 <= 0;
        b_q_1 <= 0;
        c_q <= 0;
    end
    else begin
        inst_q[1] <= inst_w[1];
        c_q <= in_psum_c;
        
        if (inst_w[1]) begin
            a_q_0 <= in_x_0;
            a_q_1 <= in_x_1;
        end

		if (inst_w[0] && load_ready_q == 1'b0) begin
			out_w_0_q <= in_w_0;
			out_w_1_q <= in_w_1;
		end
        
        if (inst_w[0] & load_ready_q) begin
            // For 2-bit activation mode: load two different weights
            // For 4-bit activation mode: broadcast same weight to both
            b_q_0 <= ctrl ? in_w_0 : in_w_0;
            b_q_1 <= ctrl ? in_w_0 : in_w_1;  // Broadcast in 4-bit mode, separate in 2-bit mode
            load_ready_q <= 1'b0;
        end
        
        if (load_ready_q == 1'b0) begin
            inst_q[0] <= inst_w[0];
        end
    end
end

endmodule