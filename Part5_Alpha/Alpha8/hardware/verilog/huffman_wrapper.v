// Huffman Wrapper Module
// Wraps huffman_decoder and buffers col outputs before concatenating

module huffman_wrapper #(
    parameter col = 8,
    parameter bw = 8
)(
    input wire clk,
    input wire reset,
    input wire data_in,
    input wire data_valid,
    output [col*bw-1:0] data_out,
    output reg data_out_valid,
    output reg [10:0] address
);

// Internal signals
wire [7:0] decoder_data_out;
wire decoder_data_out_valid;
wire decoder_busy;

// Buffer to hold col values
reg [7:0] output_buffer_0;
reg [7:0] output_buffer_1;
reg [7:0] output_buffer_2;
reg [7:0] output_buffer_3;
reg [7:0] output_buffer_4;
reg [7:0] output_buffer_5;
reg [7:0] output_buffer_6;
reg [7:0] output_buffer_7;

// State definitions (8 states)
localparam WAIT_OUTPUT_0 = 0;
localparam WAIT_OUTPUT_1 = 1;
localparam WAIT_OUTPUT_2 = 2;
localparam WAIT_OUTPUT_3 = 3;
localparam WAIT_OUTPUT_4 = 4;
localparam WAIT_OUTPUT_5 = 5;
localparam WAIT_OUTPUT_6 = 6;
localparam WAIT_OUTPUT_7 = 7;

// State register
reg [2:0] state, next_state;

// Instantiate the Huffman decoder
huffman_decoder decoder_inst (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_valid(data_valid),
    .data_out(decoder_data_out),
    .data_out_valid(decoder_data_out_valid),
    .busy(decoder_busy)
);

assign data_out = {output_buffer_0, output_buffer_1, output_buffer_2, output_buffer_3,
                   output_buffer_4, output_buffer_5, output_buffer_6, output_buffer_7};

// Sequential logic
always @(posedge clk) begin
    if (reset) begin
        state <= WAIT_OUTPUT_0;
        output_buffer_0 <= 0;
        output_buffer_1 <= 0;
        output_buffer_2 <= 0;
        output_buffer_3 <= 0;
        output_buffer_4 <= 0;
        output_buffer_5 <= 0;
        output_buffer_6 <= 0;
        output_buffer_7 <= 0;
        data_out_valid <= 0;
        address <= -1;
    end else begin
        state <= next_state;
        
        case(state)
            WAIT_OUTPUT_0: begin
                if (decoder_data_out_valid) begin
                    output_buffer_0 <= decoder_data_out;
                end
                data_out_valid <= 0;
            end
            
            WAIT_OUTPUT_1: begin
                if (decoder_data_out_valid) begin
                    output_buffer_1 <= decoder_data_out;
                end
                data_out_valid <= 0;
            end
            
            WAIT_OUTPUT_2: begin
                if (decoder_data_out_valid) begin
                    output_buffer_2 <= decoder_data_out;
                end
                data_out_valid <= 0;
            end
            
            WAIT_OUTPUT_3: begin
                if (decoder_data_out_valid) begin
                    output_buffer_3 <= decoder_data_out;
                end
                data_out_valid <= 0;
            end
            
            WAIT_OUTPUT_4: begin
                if (decoder_data_out_valid) begin
                    output_buffer_4 <= decoder_data_out;
                end
                data_out_valid <= 0;
            end
            
            WAIT_OUTPUT_5: begin
                if (decoder_data_out_valid) begin
                    output_buffer_5 <= decoder_data_out;
                end
                data_out_valid <= 0;
            end
            
            WAIT_OUTPUT_6: begin
                if (decoder_data_out_valid) begin
                    output_buffer_6 <= decoder_data_out;
                end
                data_out_valid <= 0;
            end
            
            WAIT_OUTPUT_7: begin
                if (decoder_data_out_valid) begin
                    output_buffer_7 <= decoder_data_out;
                    // Concatenate all buffered values when the last one is received
                    data_out_valid <= 1;
                    // Increment address when output is valid
                    address <= address + 1;
                end else begin
                    data_out_valid <= 0;
                end
            end
        endcase
        
        // Clear valid flag after one cycle
        if (data_out_valid && !(state == WAIT_OUTPUT_7 && decoder_data_out_valid)) begin
            data_out_valid <= 0;
        end
    end
end

// Next state logic
always @(*) begin
    next_state = state;
    
    case(state)
        WAIT_OUTPUT_0: begin
            if (decoder_data_out_valid) begin
                next_state = WAIT_OUTPUT_1;
            end else begin
                next_state = WAIT_OUTPUT_0;
            end
        end
        
        WAIT_OUTPUT_1: begin
            if (decoder_data_out_valid) begin
                next_state = WAIT_OUTPUT_2;
            end else begin
                next_state = WAIT_OUTPUT_1;
            end
        end
        
        WAIT_OUTPUT_2: begin
            if (decoder_data_out_valid) begin
                next_state = WAIT_OUTPUT_3;
            end else begin
                next_state = WAIT_OUTPUT_2;
            end
        end
        
        WAIT_OUTPUT_3: begin
            if (decoder_data_out_valid) begin
                next_state = WAIT_OUTPUT_4;
            end else begin
                next_state = WAIT_OUTPUT_3;
            end
        end
        
        WAIT_OUTPUT_4: begin
            if (decoder_data_out_valid) begin
                next_state = WAIT_OUTPUT_5;
            end else begin
                next_state = WAIT_OUTPUT_4;
            end
        end
        
        WAIT_OUTPUT_5: begin
            if (decoder_data_out_valid) begin
                next_state = WAIT_OUTPUT_6;
            end else begin
                next_state = WAIT_OUTPUT_5;
            end
        end
        
        WAIT_OUTPUT_6: begin
            if (decoder_data_out_valid) begin
                next_state = WAIT_OUTPUT_7;
            end else begin
                next_state = WAIT_OUTPUT_6;
            end
        end
        
        WAIT_OUTPUT_7: begin
            if (decoder_data_out_valid) begin
                next_state = WAIT_OUTPUT_0;
            end else begin
                next_state = WAIT_OUTPUT_7;
            end
        end
        
        default: next_state = WAIT_OUTPUT_0;
    endcase
end

endmodule