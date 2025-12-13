module corelet(
    clk, 
    reset, 
    inst, 
    data_to_l0, 
    l0_rd, 
    l0_wr, 
    l0_full, 
    l0_ready, 
    ififo_wr,
    ififo_rd,
    ififo_full,
    ififo_ready,
    ififo_valid,
    ofifo_rd, 
    ofifo_full, 
    ofifo_ready, 
    ofifo_valid, 
    psum_out, 
    data_sram_to_sfu, 
    accumulate, 
    relu, 
    data_out, 
    os_en
);

    parameter bw      = 4;
    parameter psum_bw = 16;
    parameter col     = 8;
    parameter row     = 8;

    input clk, reset;
    input [1:0] inst;               // {execute, load/drain}
    input [bw*row-1:0] data_to_l0;
    input l0_rd, l0_wr;
    output l0_full, l0_ready;
    input  os_en;

    input  ififo_wr;
    input  ififo_rd;
    output ififo_full;
    output ififo_ready;
    output ififo_valid;

    input  ofifo_rd;
    output ofifo_full, ofifo_ready, ofifo_valid;
    output [psum_bw*col-1:0] psum_out;

    input  [psum_bw*col-1:0] data_sram_to_sfu;
    input  accumulate, relu;
    output [psum_bw*col-1:0] data_out;

    wire [psum_bw*col-1:0] mac_out;
    wire [col-1:0]         mac_out_valid;
    wire [row*bw-1:0]      data_out_l0;
    wire [psum_bw*col-1:0] in_n;

    // ---------------- L0 ----------------
    l0 #(.row(row), .bw(bw)) l0_instance (
        .clk   (clk),
        .reset (reset),
        .in    (data_to_l0),
        .out   (data_out_l0),
        .rd    (l0_rd),
        .wr    (l0_wr),
        .o_full(l0_full),
        .o_ready(l0_ready)
    );


    wire [bw*col-1:0] ififo_out;

    ififo #(.bw(bw), .col(col), .depth(128)) ififo_instance (
        .clk   (clk),
        .reset (reset),
        .wr    (ififo_wr),
        .rd    (ififo_rd),
        .in    (data_to_l0),    
        .out   (ififo_out),
        .o_full(ififo_full),
        .o_ready(ififo_ready),
        .o_valid(ififo_valid)
    );

    wire [psum_bw*col-1:0] in_n_os_raw;
    genvar gi;
    for (gi = 0; gi < col; gi = gi + 1) begin : gen_in_n_os
        wire [bw-1:0] w4 = ififo_out[bw*gi +: bw];
        wire [psum_bw-1:0] w_ext = {{(psum_bw-bw){w4[bw-1]}}, w4};
        assign in_n_os_raw[psum_bw*gi +: psum_bw] = w_ext;
    end

    assign in_n = (os_en == 1'b1) ? in_n_os_raw : {psum_bw*col{1'b0}};

    wire [psum_bw*col*row-1:0] os_cq_all;  
    mac_array #(.bw(bw), .psum_bw(psum_bw), .col(col), .row(row)) mac_array_instance (
        .clk   (clk),
        .reset (reset),
        .os_en (os_en),
        .in_w  (data_out_l0),
        .in_n  (in_n),
        .inst_w(inst[1:0]),
        .out_s (mac_out),
        .valid (mac_out_valid),
        .c_q_all(os_cq_all)
    );

    ofifo #(.col(col), .psum_bw(psum_bw)) ofifo_instance (
        .clk   (clk),
        .wr    (mac_out_valid),
        .rd    (ofifo_rd),
        .reset (reset),
        .in    (mac_out),
        .out   (psum_out),
        .o_full(ofifo_full),
        .o_ready(ofifo_ready),
        .o_valid(ofifo_valid)
    );

    genvar i;
    for (i=1; i<col+1; i=i+1) begin : sfu_num
        sfu #(.bw(bw), .psum_bw(psum_bw)) sfu_instance (
            .clk  (clk),
            .acc  (accumulate),
            .relu (relu),
            .reset(reset),
            .in   (data_sram_to_sfu[psum_bw*i-1 : psum_bw*(i-1)]),
            .out  (data_out[psum_bw*i-1 : psum_bw*(i-1)])
        );
    end

endmodule
