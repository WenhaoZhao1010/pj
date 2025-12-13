module corelet(clk, reset, inst, data_to_l0, l0_rd, l0_wr, l0_full, l0_ready, ofifo_rd, ofifo_full, ofifo_ready, ofifo_valid, psum_out, data_sram_to_sfu, accumulate, relu, data_out, ctrl);
    parameter bw = 4;
    parameter l0_bw = 8;
    parameter x_bw = 2;
    parameter w_bw = 4;
    parameter psum_bw = 16;
    parameter col = 8;
    parameter row = 8;

    input clk, reset;
    input [1:0] inst; //inst [1:0] = {execute, kernel loading} 
    input [l0_bw*row-1:0] data_to_l0;
    input l0_rd, l0_wr;
    output l0_full, l0_ready;
    
    input ofifo_rd;
    output ofifo_full, ofifo_ready, ofifo_valid;
    output [psum_bw*col-1:0] psum_out; //data from ofifo to SRAM

    input [psum_bw*col-1:0] data_sram_to_sfu; //data from SRAM to sfu
    input accumulate, relu; //control signals for sfu
    output [psum_bw*col-1:0] data_out; //final output
    
    // New control input for 2-bit/4-bit mode selection
    input ctrl;

    wire [psum_bw*col-1:0] mac_out; //data from mac_array to ofifo
    wire [col-1:0] mac_out_valid; //valid from mac_array to ofifo

    wire [row*l0_bw-1:0] data_out_l0; //data from l0 to mac_array

    wire [psum_bw*col-1:0] in_n;

    assign in_n = {psum_bw*col{1'b0}};

    // Wires for reorganized weight inputs
    wire [row*w_bw-1:0] reorg_w_0;
    wire [row*w_bw-1:0] reorg_w_1;
    wire [row*x_bw-1:0] reorg_x_0;
    wire [row*x_bw-1:0] reorg_x_1;

    l0 #(.row(row), .bw(l0_bw)) l0_instance (
        .clk(clk),
        .reset(reset),
        .in(data_to_l0),
        .out(data_out_l0),
        .rd(l0_rd),
        .wr(l0_wr),
        .o_full(l0_full),
        .o_ready(l0_ready)
    );

    genvar i;
    for (i = 0; i < row; i = i + 1) begin : weight_reorg
        assign reorg_w_1[w_bw*(i+1)-1 : w_bw*i] = ctrl==0 ? data_out_l0[l0_bw*(i+1)-1 : l0_bw*i + 4] : data_out_l0[l0_bw*i + 3 : l0_bw*i]; // Upper 4 bits
        assign reorg_w_0[w_bw*(i+1)-1 : w_bw*i] = ctrl==0 ? data_out_l0[l0_bw*i + 3 : l0_bw*i] : data_out_l0[l0_bw*i + 3 : l0_bw*i];       // Lower 4 bits
        assign reorg_x_1[x_bw*(i+1)-1 : x_bw*i] = ctrl==0 ? data_out_l0[l0_bw*i+ 5 : l0_bw*i + 4] : data_out_l0[l0_bw*i+ 3 : l0_bw*i + 2];    // [5:4]
        assign reorg_x_0[x_bw*(i+1)-1 : x_bw*i] = ctrl==0 ? data_out_l0[l0_bw*i+ 1 : l0_bw*i] : data_out_l0[l0_bw*i+ 1 : l0_bw*i];        // [1:0]
    end

    mac_array #(.a_bw(x_bw), .w_bw(w_bw), .psum_bw(psum_bw), .col(col), .row(row)) mac_array_instance (
        .clk(clk),
        .reset(reset),
        .ctrl(ctrl),
        .in_x_0(reorg_x_0),      // Low bits of activations
        .in_x_1(reorg_x_1), // High bits of activations
        .in_w_0(reorg_w_0),
        .in_w_1(reorg_w_1),
        .inst_w(inst[1:0]),
        .out_s(mac_out),
        .valid(mac_out_valid),
        .in_psum_c(in_n)
    );

    // Updated ofifo instantiation using single output
    ofifo #(.col(col), .psum_bw(psum_bw)) ofifo_instance (
        .clk(clk),
        .wr(mac_out_valid),
        .rd(ofifo_rd),
        .reset(reset),
        .in(mac_out),
        .out(psum_out),
        .o_full(ofifo_full),
        .o_ready(ofifo_ready),
        .o_valid(ofifo_valid)
    );

    // genvar i;
    for (i=1; i<col+1; i=i+1) begin : sfu_num
        sfu #(.bw(bw), .psum_bw(psum_bw)) sfu_instance (
            .clk(clk),
            .acc(accumulate),
            .relu(relu),
            .reset(reset),
            .in(data_sram_to_sfu[psum_bw*i-1 : psum_bw*(i-1)]),
            .out(data_out[psum_bw*i-1 : psum_bw*(i-1)])
        );
    end

endmodule