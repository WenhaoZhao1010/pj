// WS/OS reconfigurable PE tile
// os_en = 0 : weight-stationary (original behavior)
// os_en = 1 : output-stationary
module mac_tile (clk, out_s, in_w, out_e, in_n, inst_w, inst_e, reset, os_en, c_q_out);

parameter bw = 4;
parameter psum_bw = 16;

output [psum_bw-1:0] out_s;
output [bw-1:0] out_e; 
output [1:0] inst_e;
output [psum_bw-1:0] c_q_out;

input  [bw-1:0] in_w; // inst[1]:execute, inst[0]: kernel loading
input  [1:0] inst_w;
input  [psum_bw-1:0] in_n;
input  clk;
input  reset;
input  os_en;         // 0: WS, 1: OS

reg [1:0] inst_q;
reg [bw-1:0] a_q;
reg [bw-1:0] b_q;
reg [psum_bw-1:0] c_q;  // WS: latched in_n, OS: psum register
reg load_ready_q;

wire [psum_bw-1:0] mac_out;

mac #(.bw(bw), .psum_bw(psum_bw)) mac_instance (
    .a(a_q), 
    .b(b_q),
    .c(c_q),
    .out(mac_out)
);

assign out_e  = a_q;
assign inst_e = inst_q;
assign c_q_out = c_q;

wire [bw-1:0] weight_from_n;
assign weight_from_n = in_n[bw-1:0];  

wire [psum_bw-1:0] weight_down;
assign weight_down = {{(psum_bw-bw){weight_from_n[bw-1]}}, weight_from_n};


wire [psum_bw-1:0] out_s_ws;
wire [psum_bw-1:0] out_s_os;

assign out_s_ws = mac_out;                           
assign out_s_os = (inst_w[1] ? weight_down : c_q);   

assign out_s = (os_en == 1'b1) ? out_s_os : out_s_ws;

reg os_ready;
always @(posedge clk) begin
    if (reset == 1'b1) begin
        inst_q       <= 2'b00;
        a_q          <= {bw{1'b0}};
        b_q          <= {bw{1'b0}};
        c_q          <= {psum_bw{1'b0}};
        load_ready_q <= 1'b1;
        os_ready     <= 1'b0;

    end else begin
        if (os_en == 1'b0) begin
            inst_q[1] <= inst_w[1];
            c_q       <= in_n;
            os_ready  <= 1'b0;

            if (inst_w[1] | inst_w[0]) begin
                a_q <= in_w;
            end

            if (inst_w[0] & load_ready_q) begin
                b_q          <= in_w;
                load_ready_q <= 1'b0;
            end

            if (load_ready_q == 1'b0) begin
                inst_q[0] <= inst_w[0];
            end

        end else begin
            // ---------------------------------------------------------
            // Output-stationary mode
            //   - c_q keeps the running partial sum
            //   - weights stream from north to south (in_n 里带权重)
            //   - drain 时只读 c_q，不要再去改它
            // ---------------------------------------------------------
            // 指令沿着行传下去（execute / drain 波）
            inst_q <= inst_w;

            // OS 不用 load_ready_q 这套 FSM，固定拉高
            load_ready_q <= 1'b1;
            
             if (inst_w[1]) begin
                if (os_ready == 1'b0) begin
                    a_q <= in_w;
                    b_q <= weight_from_n;
                    os_ready <= 1'b1;
                end else begin
                    a_q <= in_w;
                    b_q <= weight_from_n;
                    c_q <= mac_out; 
                end
            end
        end
    end
end


endmodule
