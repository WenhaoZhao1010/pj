// Input FIFO for OS mode
module ififo #(
    parameter bw   = 4,
    parameter col  = 8,
    parameter depth = 128
)(
    input clk,
    input reset,
    input wr,   
    input rd,   

    input  [bw*col-1:0] in,   
    output reg [bw*col-1:0] out,

    output o_full,
    output o_ready,  
    output reg o_valid   
);

    localparam ADDR_W = $clog2(depth);

    reg [bw*col-1:0] mem [0:depth-1];
    reg [ADDR_W-1:0] rd_ptr;
    reg [ADDR_W-1:0] wr_ptr;
    reg [ADDR_W:0]   count;

    assign o_full  = (count == depth);
    assign o_ready = ~o_full;

    always @(posedge clk) begin
        if (reset) begin
            rd_ptr  <= {ADDR_W{1'b0}};
            wr_ptr  <= {ADDR_W{1'b0}};
            count   <= {ADDR_W+1{1'b0}};
            out     <= {bw*col{1'b0}};
            o_valid <= 1'b0;

        end else begin
            if (wr && !o_full) begin
                mem[wr_ptr] <= in;
                wr_ptr      <= wr_ptr + 1'b1;
                count       <= count + 1'b1;
            end

            if (rd && (count != 0)) begin
                out     <= mem[rd_ptr];
                rd_ptr  <= rd_ptr + 1'b1;
                count   <= count - 1'b1;
                o_valid <= 1'b1;
            end else begin
                o_valid <= 1'b0;
            end
        end
    end

endmodule
