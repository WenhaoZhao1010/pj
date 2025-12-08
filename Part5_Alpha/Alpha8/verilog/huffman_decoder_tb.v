// Testbench for Huffman Decoder
`timescale 1ns / 1ps

module huffman_decoder_tb;

    // Inputs
    reg clk;
    reg reset;
    reg data_in;
    reg data_valid;
    
    // Outputs
    wire [7:0] data_out;
    wire data_out_valid;
    wire busy;
    
    // Instantiate the Unit Under Test (UUT)
    huffman_decoder uut (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .data_valid(data_valid),
        .data_out(data_out),
        .data_out_valid(data_out_valid),
        .busy(busy)
    );
    
    // Clock generation
    always #5 clk = ~clk;
    
    // Initialize
    initial begin
        $dumpfile("huffman_decoder.vcd");
        $dumpvars(0, huffman_decoder_tb);
        
        // Initialize inputs
        clk = 0;
        reset = 0;  // Reset signal high active
        data_in = 0;
        data_valid = 0;  
        
        // Display header
        $display("Time\tData_In\tValid\tData_Out\tOut_Valid\tBusy");
        $display("--------------------------------------------------------");
        
        // Apply reset
        reset = 1;
        #10;
        reset = 0;
        
        // Small delay
        repeat(10) @(posedge clk);
        
        // Feed test data
        feed_test_data();
        
        // Wait for final results
        repeat(100) @(posedge clk);
        
        $display("Test completed");
        $finish;
    end
    
    // Monitor outputs
    always @(posedge clk) begin
        if (data_out_valid) begin
            $display("%0t\t%d\t%d\t0x%02x\t\t%d\t\t%d", 
                     $time, data_in, data_valid, data_out, data_out_valid, busy);
        end
    end
    
    // Task to feed test data
    task feed_test_data;
        reg [255:0] test_data;
        integer i;
        
        begin
            // Create test data stream based on Huffman encoding rules:
            // '0' -> 0x00 (1 bit)
            // '1' + 8 bits -> 8-bit value (9 bits)
            
            // Test sequence: 0, 1+0x50, 0, 1+0xA0, 0, 0, 1+0x05, 0
            // Binary: 0, 101010000, 0, 110100000, 0, 0, 100000101, 0
            
            // Concatenated bit stream:
            // 0 _ 101010000 _ 0 _ 110100000 _ 0 _ 0 _ 100000101 _ 0
            // 0 1 0 1 0 1 0 0 0 0 0 1 1 0 1 0 0 0 0 0 0 0 1 0 0 0 0 0 1 0 1 0
            test_data = 32'b0_1_0_1_0_1_0_0_0_0_0_1_1_0_1_0_0_0_0_0_0_0_1_0_0_0_0_0_1_0_1_0;
            
            $display("Feeding test data...");
            data_valid = 1;
            #5;
            // Feed each bit continuously
            for (i = 0; i < 32; i = i + 1) begin
                data_in = test_data[31-i];
                // data_valid is always 1 as specified
                #10;
            end
            
            // Feed additional test pattern
            // More test data: 0, 0, 1+0xFF, 0
            test_data = 11'b0_0_1_1_1_1_1_1_1_1_0;
            for (i = 0; i < 11; i = i + 1) begin
                data_in = test_data[10-i];
                #10;
            end
            test_data = 18'b1_0_1_1_1_1_1_1_1_1_0_1_1_1_1_1_1_1;
            for (i = 0; i < 18; i = i + 1) begin
                data_in = test_data[17-i];
                #10;
            end
            
            $display("Finished feeding test data");
        end
    endtask

endmodule