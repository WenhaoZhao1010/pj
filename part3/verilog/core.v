module core #(
    parameter row     = 8,
    parameter col     = 8,
    parameter psum_bw = 16,
    parameter bw      = 4
)(
    input                        clk,
    input                        reset,
    input                        os_en,         
    input      [34:0]            inst,
    input      [bw*row-1:0]      d_xmem,
    output                       ofifo_valid,
    output     [psum_bw*col-1:0] sfp_out        
);

    wire [bw*row-1:0]  data_in;         
    wire [31:0]        xmem_data_out;

    assign data_in = xmem_data_out;      

    sram_32b_w2048 #(
        .num(2048)
    ) xmemory_inst (
        .clk (clk),
        .D   (d_xmem),       
        .Q   (xmem_data_out),
        .CEN (inst[19]),
        .WEN (inst[18]),
        .A   (inst[17:7])
    );

    wire [psum_bw*col-1:0] pmem_data_in;     // 128b
    wire [psum_bw*col-1:0] pmem_data_out;   

    sram_32b_w2048 #(
        .num  (2048),
        .width(psum_bw*col)  
    ) pmemory_inst (
        .clk (clk),
        .D   (pmem_data_in), 
        .Q   (pmem_data_out),
        .CEN (inst[32]),
        .WEN (inst[31]),
        .A   (inst[30:20])
    );

    wire [psum_bw*col-1:0] psum_from_ofifo;  
    wire [psum_bw*col-1:0] sfu_out;          
    wire [psum_bw*col-1:0] os_relu_out;      

    corelet #(
        .row    (row),
        .col    (col),
        .psum_bw(psum_bw),
        .bw     (bw)
    ) corelet_insts (
        .clk       (clk),
        .reset     (reset),
        .inst      (inst[1:0]),           // {execute, load/drain}
        .data_to_l0(data_in),
        .l0_rd     (inst[3]),
        .l0_wr     (inst[2]),
        .l0_full   (),
        .l0_ready  (),
        .ififo_wr  (inst[5]),
        .ififo_rd  (inst[4]),
        .ififo_full(),
        .ififo_ready(),
        .ififo_valid(),
        .ofifo_rd  (inst[6]),
        .ofifo_full(),
        .ofifo_ready(),
        .ofifo_valid(ofifo_valid),
        .psum_out(psum_from_ofifo),
        .data_sram_to_sfu(pmem_data_out),
        .accumulate(os_en ? 1'b0 : inst[33]),
        .relu(os_en ? 1'b0 : inst[34]),
        .data_out(sfu_out),
        .os_en(os_en)
    );

    genvar gi;
    for (gi = 0; gi < col; gi = gi + 1) begin : gen_os_relu_lane
        wire signed [psum_bw-1:0] lane_raw;
        assign lane_raw = psum_from_ofifo[psum_bw*(gi+1)-1 -: psum_bw];
        wire [psum_bw-1:0] lane_relu;
        assign lane_relu = lane_raw[psum_bw-1] ? {psum_bw{1'b0}} : lane_raw;
        assign os_relu_out[psum_bw*(gi+1)-1 -: psum_bw] = lane_relu;
    end

    assign pmem_data_in = os_en ? {psum_bw*col{1'b0}} : psum_from_ofifo;
    assign sfp_out      = os_en ? os_relu_out      : sfu_out;

endmodule
