module core #(
    parameter row = 8,
    parameter col = 8,
    parameter psum_bw = 16,
    parameter bw = 8,
    parameter l0_bw = 8,
    parameter x_bw = 2,
    parameter w_bw = 4
)(
    input clk,
    input reset,
    input [34:0] inst,
    input [l0_bw*row-1:0] d_xmem,
    input huffman_data_in,
    output ofifo_valid,
    output [psum_bw*col-1:0] sfp_out
);

wire [l0_bw*row-1:0] data_in;
wire [psum_bw*col-1:0] acc_in;
wire [psum_bw*col-1:0] data_out;
wire [psum_bw*col-1:0] spf_out;

// Huffman wrapper signals
wire [col*bw-1:0] huffman_data_out;
wire huffman_data_out_valid;
wire [10:0] huffman_address;

assign acc_in = pmem_data_out;
assign data_in = xmem_data_out;
assign sfp_out = spf_out;

wire [l0_bw*row-1:0] xmem_data_out;

// Select between d_xmem and huffman wrapper output for xmem input
wire [l0_bw*row-1:0] xmem_input_data;
wire [10:0] xmem_address;
wire CEN_xmem;
wire WEN_xmem;

assign xmem_input_data = (inst[5]) ? huffman_data_out : d_xmem;
assign xmem_address = (inst[5]) ? huffman_address : inst[17:7];
assign CEN_xmem = (inst[5]) ? (~huffman_data_out_valid) : inst[19];
assign WEN_xmem = (inst[5]) ? (~huffman_data_out_valid) : inst[18];

sram_w2048 #(
    .num(2048)
) xmemory_inst (
    .clk(clk),
    .D(xmem_input_data),
    .Q(xmem_data_out),
    .CEN(CEN_xmem),
    .WEN(WEN_xmem),
    .A(xmem_address)
);

// wire [127:0] pmem_data_in;
wire [psum_bw*col-1:0] pmem_data_out;

sram_w2048 #(
    .num(2048),
    .width(128)
) pmemory_inst (
    .clk(clk),
    .D(data_out),
    .Q(pmem_data_out),
    .CEN(inst[32]),
    .WEN(inst[31]),
    .A(inst[30:20])
);

// Instantiate Huffman wrapper
huffman_wrapper #(
    .col(col),
    .bw(bw)
) huffman_wrapper_inst (
    .clk(clk),
    .reset(reset),
    .data_in(huffman_data_in),        // Assuming serial data comes from instruction
    .data_valid(inst[5]),     // Enable Huffman decoding when inst[5] is high
    .data_out(huffman_data_out),
    .data_out_valid(huffman_data_out_valid),
    .address(huffman_address)
);

corelet #(
    .row(row),
    .col(col),
    .psum_bw(psum_bw),
    .bw(bw),
    .l0_bw(l0_bw),
    .x_bw(x_bw),
    .w_bw(w_bw)
) corelet_insts (
    .clk(clk),
    .reset(reset),
    .inst(inst[1:0]),
    .data_to_l0(data_in),
    .l0_rd(inst[3]),
    .l0_wr(inst[2]),
    .l0_full(),
    .l0_ready(),
    // .in_n(128'b0),
    .ofifo_rd(inst[6]),
    .ofifo_full(),
    .ofifo_ready(),
    .ofifo_valid(ofifo_valid),
    .psum_out(data_out),
    .data_sram_to_sfu(acc_in),
    .accumulate(inst[33]),
    .relu(inst[34]),
    .data_out(spf_out),
    .ctrl(inst[4])
);

endmodule