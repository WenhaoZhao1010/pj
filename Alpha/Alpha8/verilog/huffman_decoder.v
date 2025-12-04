// Huffman Decoder for Activation Data
// Decoding scheme:
// - '0' -> 0x00 (1 bit to 8 bits)
// - '1' + 8 bits -> original value (9 bits to 8 bits)

module huffman_decoder (
    input wire clk,
    input wire reset,
    input wire data_in,          // Serial input data
    input wire data_valid,       // Valid signal for input data
    output [7:0] data_out,   // Decoded 8-bit output
    output reg data_out_valid,   // Valid signal for output data
    output reg busy              // Decoder busy signal
);

// State definitions
localparam PROCESS_FIRST_BIT = 0;
localparam READ_BIT_0 = 1;
localparam READ_BIT_1 = 2;
localparam READ_BIT_2 = 3;
localparam READ_BIT_3 = 4;
localparam READ_BIT_4 = 5;
localparam READ_BIT_5 = 6;
localparam READ_BIT_6 = 7;
localparam READ_BIT_7 = 8;

// State register
reg [3:0] state, next_state;

// Data buffer to hold incoming bits
reg [7:0] data_buffer;
assign data_out = data_buffer;

always @(posedge clk) begin
    if (reset) begin
        state <= PROCESS_FIRST_BIT;
        data_buffer <= 0;
        data_out_valid <= 0;
        busy <= 0;
    end else begin
        state <= next_state;
        
        case(state)
            PROCESS_FIRST_BIT: begin
                if (data_valid) begin
                    if (data_in == 0) begin
                        // Special case: '0' decodes to 0x00
                        data_buffer <= 8'b00000000;
                        data_out_valid <= 1;
                        busy <= 0;
                    end else begin
                        // First bit is '1', start collecting 8 bits
                        data_buffer <= 0;
                        busy <= 1;
                    end
                end else begin
                    data_out_valid <= 0;
                end
            end
            
            READ_BIT_0: begin
                if (data_valid) begin
                    data_buffer[7] <= data_in;
                end
                data_out_valid <= 0;
            end
            
            READ_BIT_1: begin
                if (data_valid) begin
                    data_buffer[6] <= data_in;
                end
                data_out_valid <= 0;
            end
            
            READ_BIT_2: begin
                if (data_valid) begin
                    data_buffer[5] <= data_in;
                end
                data_out_valid <= 0;
            end
            
            READ_BIT_3: begin
                if (data_valid) begin
                    data_buffer[4] <= data_in;
                end
                data_out_valid <= 0;
            end
            
            READ_BIT_4: begin
                if (data_valid) begin
                    data_buffer[3] <= data_in;
                end
                data_out_valid <= 0;
            end
            
            READ_BIT_5: begin
                if (data_valid) begin
                    data_buffer[2] <= data_in;
                end
                data_out_valid <= 0;
            end
            
            READ_BIT_6: begin
                if (data_valid) begin
                    data_buffer[1] <= data_in;
                end
                data_out_valid <= 0;
            end
            
            READ_BIT_7: begin
                if (data_valid) begin
                    data_buffer[0] <= data_in;
                    // All 8 bits collected
                    data_out_valid <= 1;
                    busy <= 0;
                end else begin
                    data_out_valid <= 0;
                end
            end
        endcase
        
        // Clear valid flag after one cycle except when actively setting it
        if (data_out_valid && !(state == PROCESS_FIRST_BIT && data_valid && data_in == 0) && 
            !(state == READ_BIT_7 && data_valid)) begin
            data_out_valid <= 0;
        end
    end
end

always @(*) begin
    next_state = state;
    
    case(state)
        PROCESS_FIRST_BIT: begin
            if (data_valid) begin
                if (data_in == 0) begin
                    // For '0' input, stay in the same state
                    next_state = PROCESS_FIRST_BIT;
                end else begin
                    // For '1' input, move to read the next 8 bits
                    next_state = READ_BIT_0;
                end
            end else begin
                next_state = PROCESS_FIRST_BIT;
            end
        end
        
        READ_BIT_0: begin
            if (data_valid) begin
                next_state = READ_BIT_1;
            end else begin
                next_state = READ_BIT_0;
            end
        end
        
        READ_BIT_1: begin
            if (data_valid) begin
                next_state = READ_BIT_2;
            end else begin
                next_state = READ_BIT_1;
            end
        end
        
        READ_BIT_2: begin
            if (data_valid) begin
                next_state = READ_BIT_3;
            end else begin
                next_state = READ_BIT_2;
            end
        end
        
        READ_BIT_3: begin
            if (data_valid) begin
                next_state = READ_BIT_4;
            end else begin
                next_state = READ_BIT_3;
            end
        end
        
        READ_BIT_4: begin
            if (data_valid) begin
                next_state = READ_BIT_5;
            end else begin
                next_state = READ_BIT_4;
            end
        end
        
        READ_BIT_5: begin
            if (data_valid) begin
                next_state = READ_BIT_6;
            end else begin
                next_state = READ_BIT_5;
            end
        end
        
        READ_BIT_6: begin
            if (data_valid) begin
                next_state = READ_BIT_7;
            end else begin
                next_state = READ_BIT_6;
            end
        end
        
        READ_BIT_7: begin
            if (data_valid) begin
                next_state = PROCESS_FIRST_BIT;
            end else begin
                next_state = READ_BIT_7;
            end
        end
        
        default: next_state = PROCESS_FIRST_BIT;
    endcase
end

endmodule