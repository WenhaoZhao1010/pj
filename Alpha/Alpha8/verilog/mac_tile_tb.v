// Testbench for mac_tile module
`timescale 1ns / 1ps

module mac_tile_tb;

// Parameters matching the DUT
parameter a_bw = 2;
parameter w_bw = 4;
parameter psum_bw = 16;

// Signals for testing
reg clk;
reg ctrl;
reg [a_bw-1:0] in_x_0;
reg [a_bw-1:0] in_x_1;
reg [w_bw-1:0] in_w_0;
reg [w_bw-1:0] in_w_1;
reg [1:0] inst_w;
reg [psum_bw-1:0] in_psum_c_0;
reg [psum_bw-1:0] in_psum_c_1;
reg reset;

wire [psum_bw-1:0] out_s_0;
wire [psum_bw-1:0] out_s_1;
wire [a_bw-1:0] out_x_0;
wire [a_bw-1:0] out_x_1;
wire [w_bw-1:0] out_w_0;
wire [w_bw-1:0] out_w_1;
wire [1:0] inst_e;

// Instantiate the Device Under Test (DUT)
mac_tile #(
    .a_bw(a_bw),
    .w_bw(w_bw),
    .psum_bw(psum_bw)
) dut (
    .clk(clk),
    .ctrl(ctrl),
    .out_s_0(out_s_0),
    .out_s_1(out_s_1),
    .in_x_0(in_x_0),
    .in_x_1(in_x_1),
    .in_w_0(in_w_0),
    .in_w_1(in_w_1),
    .out_x_0(out_x_0),
    .out_x_1(out_x_1),
    .out_w_0(out_w_0),
    .out_w_1(out_w_1),
    .inst_w(inst_w),
    .inst_e(inst_e),
    .in_psum_c_0(in_psum_c_0),
    .in_psum_c_1(in_psum_c_1),
    .reset(reset)
);

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100MHz clock
end

// Test procedure
initial begin
    $display("Starting MAC Tile testbench...");
    $dumpfile("mac_tile_tb.vcd");
    $dumpvars(0, mac_tile_tb);
    
    // Initialize signals
    reset = 1;
    ctrl = 0;
    in_x_0 = 0;
    in_x_1 = 0;
    in_w_0 = 0;
    in_w_1 = 0;
    inst_w = 0;
    in_psum_c_0 = 0;
    in_psum_c_1 = 0;
    
    // Monitor signals
    $monitor("Time=%0t: ctrl=%b, in_x_0=%b, in_x_1=%b, in_w_0=%b, in_w_1=%b, out_s_0=%d, out_s_1=%d, inst_w=%b, inst_e=%b", 
             $time, ctrl, in_x_0, in_x_1, in_w_0, in_w_1, out_s_0, out_s_1, inst_w, inst_e);
    
    // Reset sequence
    #20 reset = 0;
    #10;
    
    ////////////////////////////////
    // Test 2-bit activation mode //
    ////////////////////////////////
    $display("--- Testing 2-bit activation mode ---");
    ctrl = 0; // 2-bit mode
    
    // Test case 1: Load weights
    in_w_0 = 4'b0010; // 2
    in_w_1 = 4'b0011; // 3
    inst_w = 2'b01;   // Load weights
    #10;
    inst_w = 2'b00;
    #10;
    
    // Test case 2: Execute with activations
    in_x_0 = 2'b01;   // 1
    in_x_1 = 2'b10;   // 2
    in_psum_c_0 = 16'd5;
    in_psum_c_1 = 16'd10;
    inst_w = 2'b10;   // Execute
    #10;
    inst_w = 2'b00;
    #20;
    
    ////////////////////////////////
    // Test 4-bit activation mode //
    ////////////////////////////////
    $display("--- Testing 4-bit activation mode ---");
    ctrl = 1; // 4-bit mode
    
    // Test case 3: Load weight (broadcast)
    in_w_0 = 4'b0101; // 5
    in_w_1 = 4'b0000; // Don't care
    inst_w = 2'b01;   // Load weights
    #10;
    inst_w = 2'b00;
    #10;
    
    // Test case 4: Execute with 4-bit activation
    // 4-bit activation = 6 (split as in_x_1=1, in_x_0=2)
    in_x_0 = 2'b10;   // Low 2 bits: 2
    in_x_1 = 2'b01;   // High 2 bits: 1
    in_psum_c_0 = 16'd0;
    in_psum_c_1 = 16'd0;
    inst_w = 2'b10;   // Execute
    #10;
    inst_w = 2'b00;
    #20;
    
    // Test case 5: Another 4-bit execution with partial sum
    in_x_0 = 2'b11;   // Low 2 bits: 3
    in_x_1 = 2'b11;   // High 2 bits: 3 (total: 15)
    in_psum_c_0 = 16'd10;
    in_psum_c_1 = 16'd0;
    inst_w = 2'b10;   // Execute
    #10;
    inst_w = 2'b00;
    #20;
    
    $display("Test completed.");
    $finish;
end

endmodule