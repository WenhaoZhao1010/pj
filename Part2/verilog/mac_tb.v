// Testbench for mac module
`timescale 1ns / 1ps

module mac_tb;

// Parameters matching the DUT
parameter a_bw = 2;
parameter w_bw = 4;
parameter psum_bw = 8;

// Signals for testing
reg signed [a_bw-1:0] a;
reg signed [w_bw-1:0] b;
reg signed [psum_bw-1:0] c;
wire signed [psum_bw-1:0] out;

// Instantiate the Device Under Test (DUT)
mac #(
    .a_bw(a_bw),
    .w_bw(w_bw),
    .psum_bw(psum_bw)
) dut (
    .out(out),
    .a(a),
    .b(b),
    .c(c)
);

// Test procedure
initial begin
    $display("Starting MAC testbench...");
    $monitor("Time=%0t: a=%b(%d), b=%b(%d), c=%b(%d), out=%b(%d)", 
             $time, a, a, b, b, c, c, out, out);
    
    // Dump waves to VCD file
    $dumpfile("mac_tb.vcd");
    $dumpvars(0, mac_tb);
    
    // Test case 1: Basic positive values
    a = 2'b01;  // 1
    b = 4'b0010; // 2
    c = 8'b00000011; // 3
    #10;
    
    // Test case 2: Negative activation
    a = 2'b11;  // -1 (2's complement)
    b = 4'b0010; // 2
    c = 8'b00000101; // 5
    #10;
    
    // Test case 3: Negative weight
    a = 2'b01;  // 1
    b = 4'b1110; // -2 (2's complement)
    c = 8'b00000100; // 4
    #10;
    
    // Test case 4: Both negative
    a = 2'b11;  // -1
    b = 4'b1110; // -2
    c = 8'b00000001; // 1
    #10;
    
    // Test case 5: Maximum values
    a = 2'b01;  // 1 (maximum positive with current bit width)
    b = 4'b0111; // 7 (maximum positive)
    c = 8'b01111111; // 127 (maximum positive)
    #10;
    
    // Test case 6: Zero values
    a = 2'b00;  // 0
    b = 4'b0000; // 0
    c = 8'b00000000; // 0
    #10;
    
    $display("Test completed.");
    $finish;
end

endmodule