module core #(
    parameter row = 8,
    parameter col = 8,
    parameter psum_bw = 16,
    parameter bw = 4
)(
    input clk,
    input reset,
    input [34:0] inst,
    input [bw*row-1:0] d_xmem,
    output ofifo_valid,
    output [psum_bw*col-1:0] sfp_out
);

wire [bw*row-1:0] data_in;
wire [psum_bw*col-1:0] acc_in;
wire [psum_bw*col-1:0] data_out;
wire [psum_bw*col-1:0] spf_out;

assign acc_in = pmem_data_out;
assign data_in = xmem_data_out;
assign sfp_out = spf_out;

wire [31:0] xmem_data_out;

sram_32b_w2048 #(
    .num(2048)
) xmemory_inst (
    .clk(clk),
    .D(d_xmem),
    .Q(xmem_data_out),
    .CEN(inst[19]),
    .WEN(inst[18]),
    .A(inst[17:7])
);

wire [127:0] pmem_data_in;
wire [127:0] pmem_data_out;

sram_32b_w2048 #(
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

corelet #(
    .row(row),
    .col(col),
    .psum_bw(psum_bw),
    .bw(bw)
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
    .data_out(spf_out)
);

endmodule
