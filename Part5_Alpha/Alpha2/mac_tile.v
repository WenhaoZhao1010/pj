// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 


module mac_tile (clk, out_s, in_w, out_e, in_n, inst_w, inst_e, reset);

parameter bw = 4;
parameter psum_bw = 16;

output [psum_bw-1:0] out_s;
input  [bw-1:0] in_w;
output [bw-1:0] out_e; 
input  [1:0] inst_w;
output [1:0] inst_e;
input  [psum_bw-1:0] in_n;
input  clk;
input  reset;

reg [1:0] inst_q;
reg [bw-1:0] a_q;
reg [bw-1:0] b_q;
reg [psum_bw-1:0] c_q;
wire [psum_bw-1:0] mac_out;
reg load_ready_q;


// gating_a: activation非零时为1，零时为0
// gating_b: weight非零时为1，零时为0

wire gating_a;
wire gating_b;
assign gating_a = (a_q != {bw{1'b0}});  // activation != 0 → 1
assign gating_b = (b_q != {bw{1'b0}});  // weight != 0 → 1


// do_multiply = gating_a & gating_b
//= 1: 两个操作数都非零，需要执行乘法
//= 0: 至少一个为零，跳过乘法，直接输出c

wire do_multiply;
assign do_multiply = gating_a & gating_b;
reg [bw-1:0] last_valid_a;
reg [bw-1:0] last_valid_b;

always @(posedge clk) begin
    if (reset) begin
        last_valid_a <= {bw{1'b0}};
        last_valid_b <= {bw{1'b0}};
    end
    else begin
        if (do_multiply && inst_q[1]) begin
            last_valid_a <= a_q;
            last_valid_b <= b_q;
        end
    end
end


wire [bw-1:0] mac_input_a;
wire [bw-1:0] mac_input_b;
assign mac_input_a = do_multiply ? a_q : last_valid_a;
assign mac_input_b = do_multiply ? b_q : last_valid_b;

// synthesis translate_off
reg [31:0] total_cycles;
reg [31:0] gated_cycles;
reg [31:0] execute_cycles;
reg [31:0] toggle_count_mac_a;
reg [bw-1:0] mac_input_a_prev;

always @(posedge clk) begin
    if (reset) begin
        total_cycles <= 0;
        gated_cycles <= 0;
        execute_cycles <= 0;
        toggle_count_mac_a <= 0;
        mac_input_a_prev <= 0;
    end
    else begin
        total_cycles <= total_cycles + 1;
        
        if (inst_q[1]) begin
            execute_cycles <= execute_cycles + 1;
            if (!do_multiply) begin
                gated_cycles <= gated_cycles + 1;
            end
            if (mac_input_a != mac_input_a_prev)
                toggle_count_mac_a <= toggle_count_mac_a + 1;
        end
        
        mac_input_a_prev <= mac_input_a;
    end
end
mac #(.bw(bw), .psum_bw(psum_bw)) mac_instance (
    .a(mac_input_a),    // 【修改】使用选择后的activation
    .b(mac_input_b),    // 【修改】使用选择后的weight
    .c(c_q),
	.out(mac_out)
);


// do_multiply = 1 (gating_a & gating_b = 1): 输出 mac_out = a*b+c
// do_multiply = 0 (gating_a & gating_b = 0): 输出 c_q (跳过乘法，因为a*b=0)
assign out_e = a_q;
assign inst_e = inst_q;
assign out_s = do_multiply ? mac_out : c_q;  // 【修改】输出选择器
always @ (posedge clk) begin
	if (reset == 1) begin
			inst_q <= 0;
			load_ready_q <= 1'b1;
			a_q <= 0;
			b_q <= 0;
			c_q <= 0;
	end
	else begin
		inst_q[1] <= inst_w[1];
		c_q <= in_n;
        
		if (inst_w[1] | inst_w[0]) begin
			a_q <= in_w;
		end
        
		if (inst_w[0] & load_ready_q) begin
			b_q <= in_w;
			load_ready_q <= 1'b0;
		end
        
		if (load_ready_q == 1'b0) begin
			inst_q[0] <= inst_w[0];
		end
	end
end

endmodule
