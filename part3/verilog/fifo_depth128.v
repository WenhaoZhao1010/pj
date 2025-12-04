module fifo_depth128 (rd_clk, wr_clk, in, out, rd, wr, o_full, o_empty, reset);

  parameter bw = 4;
  parameter simd = 1;
  parameter lrf_depth = 1;

  input  rd_clk;
  input  wr_clk;
  input  rd;
  input  wr;
  input  reset;
  output o_full;
  output o_empty;
  input  [simd*bw-1:0] in;
  output [simd*bw-1:0] out;

  // Internal wires for MUX outputs
  wire [simd*bw-1:0] out_sub0_0, out_sub0_1, out_sub0_2, out_sub0_3;
  wire [simd*bw-1:0] out_sub0_4, out_sub0_5, out_sub0_6, out_sub0_7; // Added for 128 depth
  
  // Second stage MUX outputs (8 -> 1 using mux_16_1 partially or custom logic)
  // Let's reuse fifo_mux_16_1 for the second stage to select from the 8 groups above
  // We need to feed 8 inputs to a 16_1 mux, others can be 0 or duplicated
  wire [simd*bw-1:0] out_stage2;

  wire full, empty;

  // Pointers increased to 8 bits (7 bits for address [6:0], 1 bit for wrap-around [7])
  reg [7:0] rd_ptr;
  reg [7:0] wr_ptr;

  // Registers q0 to q127
  reg [simd*bw-1:0] q0, q1, q2, q3, q4, q5, q6, q7;
  reg [simd*bw-1:0] q8, q9, q10, q11, q12, q13, q14, q15;
  reg [simd*bw-1:0] q16, q17, q18, q19, q20, q21, q22, q23;
  reg [simd*bw-1:0] q24, q25, q26, q27, q28, q29, q30, q31;
  reg [simd*bw-1:0] q32, q33, q34, q35, q36, q37, q38, q39;
  reg [simd*bw-1:0] q40, q41, q42, q43, q44, q45, q46, q47;
  reg [simd*bw-1:0] q48, q49, q50, q51, q52, q53, q54, q55;
  reg [simd*bw-1:0] q56, q57, q58, q59, q60, q61, q62, q63;
  
  // New registers q64 to q127
  reg [simd*bw-1:0] q64, q65, q66, q67, q68, q69, q70, q71;
  reg [simd*bw-1:0] q72, q73, q74, q75, q76, q77, q78, q79;
  reg [simd*bw-1:0] q80, q81, q82, q83, q84, q85, q86, q87;
  reg [simd*bw-1:0] q88, q89, q90, q91, q92, q93, q94, q95;
  reg [simd*bw-1:0] q96, q97, q98, q99, q100, q101, q102, q103;
  reg [simd*bw-1:0] q104, q105, q106, q107, q108, q109, q110, q111;
  reg [simd*bw-1:0] q112, q113, q114, q115, q116, q117, q118, q119;
  reg [simd*bw-1:0] q120, q121, q122, q123, q124, q125, q126, q127;

  // Full/Empty logic for 128 depth
  // Empty when ptrs are identical
  assign empty = (wr_ptr == rd_ptr) ? 1'b1 : 1'b0;
  // Full when addresses match [6:0] but wrap-around bit [7] is different
  assign full  = ((wr_ptr[6:0] == rd_ptr[6:0]) && (wr_ptr[7] != rd_ptr[7])) ? 1'b1 : 1'b0;

  assign o_full  = full;
  assign o_empty = empty;

  // --- Read Multiplexing Logic ---
  // Stage 1: 8 groups of 16 registers each
  // Select using rd_ptr[3:0]
  
  // Group 0 (0-15)
  fifo_mux_16_1 #(.bw(bw)) mux_16_1_g0 (.in0(q0), .in1(q1), .in2(q2), .in3(q3), .in4(q4), .in5(q5), .in6(q6), .in7(q7),
                                        .in8(q8), .in9(q9), .in10(q10), .in11(q11), .in12(q12), .in13(q13), .in14(q14), .in15(q15),
                                        .sel(rd_ptr[3:0]), .out(out_sub0_0));
  // Group 1 (16-31)
  fifo_mux_16_1 #(.bw(bw)) mux_16_1_g1 (.in0(q16), .in1(q17), .in2(q18), .in3(q19), .in4(q20), .in5(q21), .in6(q22), .in7(q23),
                                        .in8(q24), .in9(q25), .in10(q26), .in11(q27), .in12(q28), .in13(q29), .in14(q30), .in15(q31),
                                        .sel(rd_ptr[3:0]), .out(out_sub0_1));
  // Group 2 (32-47)
  fifo_mux_16_1 #(.bw(bw)) mux_16_1_g2 (.in0(q32), .in1(q33), .in2(q34), .in3(q35), .in4(q36), .in5(q37), .in6(q38), .in7(q39),
                                        .in8(q40), .in9(q41), .in10(q42), .in11(q43), .in12(q44), .in13(q45), .in14(q46), .in15(q47),
                                        .sel(rd_ptr[3:0]), .out(out_sub0_2));
  // Group 3 (48-63)
  fifo_mux_16_1 #(.bw(bw)) mux_16_1_g3 (.in0(q48), .in1(q49), .in2(q50), .in3(q51), .in4(q52), .in5(q53), .in6(q54), .in7(q55),
                                        .in8(q56), .in9(q57), .in10(q58), .in11(q59), .in12(q60), .in13(q61), .in14(q62), .in15(q63),
                                        .sel(rd_ptr[3:0]), .out(out_sub0_3));
  // Group 4 (64-79)
  fifo_mux_16_1 #(.bw(bw)) mux_16_1_g4 (.in0(q64), .in1(q65), .in2(q66), .in3(q67), .in4(q68), .in5(q69), .in6(q70), .in7(q71),
                                        .in8(q72), .in9(q73), .in10(q74), .in11(q75), .in12(q76), .in13(q77), .in14(q78), .in15(q79),
                                        .sel(rd_ptr[3:0]), .out(out_sub0_4));
  // Group 5 (80-95)
  fifo_mux_16_1 #(.bw(bw)) mux_16_1_g5 (.in0(q80), .in1(q81), .in2(q82), .in3(q83), .in4(q84), .in5(q85), .in6(q86), .in7(q87),
                                        .in8(q88), .in9(q89), .in10(q90), .in11(q91), .in12(q92), .in13(q93), .in14(q94), .in15(q95),
                                        .sel(rd_ptr[3:0]), .out(out_sub0_5));
  // Group 6 (96-111)
  fifo_mux_16_1 #(.bw(bw)) mux_16_1_g6 (.in0(q96), .in1(q97), .in2(q98), .in3(q99), .in4(q100), .in5(q101), .in6(q102), .in7(q103),
                                        .in8(q104), .in9(q105), .in10(q106), .in11(q107), .in12(q108), .in13(q109), .in14(q110), .in15(q111),
                                        .sel(rd_ptr[3:0]), .out(out_sub0_6));
  // Group 7 (112-127)
  fifo_mux_16_1 #(.bw(bw)) mux_16_1_g7 (.in0(q112), .in1(q113), .in2(q114), .in3(q115), .in4(q116), .in5(q117), .in6(q118), .in7(q119),
                                        .in8(q120), .in9(q121), .in10(q122), .in11(q123), .in12(q124), .in13(q125), .in14(q126), .in15(q127),
                                        .sel(rd_ptr[3:0]), .out(out_sub0_7));

  // Stage 2: Select 1 from 8 groups
  // We use rd_ptr[6:4] to select among the 8 groups.
  // We can reuse fifo_mux_16_1 by wiring the first 8 inputs and setting selection logic carefully,
  // or cascade 2_1 MUXes. Let's use fifo_mux_16_1 for cleanliness, grounding unused inputs.
  
  // Note: fifo_mux_16_1 select is 4 bits. We feed {0, rd_ptr[6:4]} to select 0-7.
  fifo_mux_16_1 #(.bw(bw)) mux_stage2 (
      .in0(out_sub0_0), .in1(out_sub0_1), .in2(out_sub0_2), .in3(out_sub0_3),
      .in4(out_sub0_4), .in5(out_sub0_5), .in6(out_sub0_6), .in7(out_sub0_7),
      .in8({simd*bw{1'b0}}), .in9({simd*bw{1'b0}}), .in10({simd*bw{1'b0}}), .in11({simd*bw{1'b0}}),
      .in12({simd*bw{1'b0}}), .in13({simd*bw{1'b0}}), .in14({simd*bw{1'b0}}), .in15({simd*bw{1'b0}}),
      .sel({1'b0, rd_ptr[6:4]}), 
      .out(out)
  );

  always @ (posedge rd_clk) begin
    if (reset) begin
       rd_ptr <= 8'b00000000;
    end
    else if ((rd == 1) && (empty == 0)) begin
       rd_ptr <= rd_ptr + 1;
    end
  end

  always @ (posedge wr_clk) begin
    if (reset) begin
       wr_ptr <= 8'b00000000;
    end
    else begin 
       if ((wr == 1) && (full == 0)) begin
         wr_ptr <= wr_ptr + 1;
       end

       if ((wr == 1) && (full == 0)) begin // Safety check added
         case (wr_ptr[6:0])
           // Group 0
           7'b0000000 : q0  <= in; 7'b0000001 : q1  <= in; 7'b0000010 : q2  <= in; 7'b0000011 : q3  <= in;
           7'b0000100 : q4  <= in; 7'b0000101 : q5  <= in; 7'b0000110 : q6  <= in; 7'b0000111 : q7  <= in;
           7'b0001000 : q8  <= in; 7'b0001001 : q9  <= in; 7'b0001010 : q10 <= in; 7'b0001011 : q11 <= in;
           7'b0001100 : q12 <= in; 7'b0001101 : q13 <= in; 7'b0001110 : q14 <= in; 7'b0001111 : q15 <= in;
           // Group 1
           7'b0010000 : q16 <= in; 7'b0010001 : q17 <= in; 7'b0010010 : q18 <= in; 7'b0010011 : q19 <= in;
           7'b0010100 : q20 <= in; 7'b0010101 : q21 <= in; 7'b0010110 : q22 <= in; 7'b0010111 : q23 <= in;
           7'b0011000 : q24 <= in; 7'b0011001 : q25 <= in; 7'b0011010 : q26 <= in; 7'b0011011 : q27 <= in;
           7'b0011100 : q28 <= in; 7'b0011101 : q29 <= in; 7'b0011110 : q30 <= in; 7'b0011111 : q31 <= in;
           // Group 2
           7'b0100000 : q32 <= in; 7'b0100001 : q33 <= in; 7'b0100010 : q34 <= in; 7'b0100011 : q35 <= in;
           7'b0100100 : q36 <= in; 7'b0100101 : q37 <= in; 7'b0100110 : q38 <= in; 7'b0100111 : q39 <= in;
           7'b0101000 : q40 <= in; 7'b0101001 : q41 <= in; 7'b0101010 : q42 <= in; 7'b0101011 : q43 <= in;
           7'b0101100 : q44 <= in; 7'b0101101 : q45 <= in; 7'b0101110 : q46 <= in; 7'b0101111 : q47 <= in;
           // Group 3
           7'b0110000 : q48 <= in; 7'b0110001 : q49 <= in; 7'b0110010 : q50 <= in; 7'b0110011 : q51 <= in;
           7'b0110100 : q52 <= in; 7'b0110101 : q53 <= in; 7'b0110110 : q54 <= in; 7'b0110111 : q55 <= in;
           7'b0111000 : q56 <= in; 7'b0111001 : q57 <= in; 7'b0111010 : q58 <= in; 7'b0111011 : q59 <= in;
           7'b0111100 : q60 <= in; 7'b0111101 : q61 <= in; 7'b0111110 : q62 <= in; 7'b0111111 : q63 <= in;
           // Group 4 (New)
           7'b1000000 : q64 <= in; 7'b1000001 : q65 <= in; 7'b1000010 : q66 <= in; 7'b1000011 : q67 <= in;
           7'b1000100 : q68 <= in; 7'b1000101 : q69 <= in; 7'b1000110 : q70 <= in; 7'b1000111 : q71 <= in;
           7'b1001000 : q72 <= in; 7'b1001001 : q73 <= in; 7'b1001010 : q74 <= in; 7'b1001011 : q75 <= in;
           7'b1001100 : q76 <= in; 7'b1001101 : q77 <= in; 7'b1001110 : q78 <= in; 7'b1001111 : q79 <= in;
           // Group 5 (New)
           7'b1010000 : q80 <= in; 7'b1010001 : q81 <= in; 7'b1010010 : q82 <= in; 7'b1010011 : q83 <= in;
           7'b1010100 : q84 <= in; 7'b1010101 : q85 <= in; 7'b1010110 : q86 <= in; 7'b1010111 : q87 <= in;
           7'b1011000 : q88 <= in; 7'b1011001 : q89 <= in; 7'b1011010 : q90 <= in; 7'b1011011 : q91 <= in;
           7'b1011100 : q92 <= in; 7'b1011101 : q93 <= in; 7'b1011110 : q94 <= in; 7'b1011111 : q95 <= in;
           // Group 6 (New)
           7'b1100000 : q96 <= in; 7'b1100001 : q97 <= in; 7'b1100010 : q98 <= in; 7'b1100011 : q99 <= in;
           7'b1100100 : q100<= in; 7'b1100101 : q101<= in; 7'b1100110 : q102<= in; 7'b1100111 : q103<= in;
           7'b1101000 : q104<= in; 7'b1101001 : q105<= in; 7'b1101010 : q106<= in; 7'b1101011 : q107<= in;
           7'b1101100 : q108<= in; 7'b1101101 : q109<= in; 7'b1101110 : q110<= in; 7'b1101111 : q111<= in;
           // Group 7 (New)
           7'b1110000 : q112<= in; 7'b1110001 : q113<= in; 7'b1110010 : q114<= in; 7'b1110011 : q115<= in;
           7'b1110100 : q116<= in; 7'b1110101 : q117<= in; 7'b1110110 : q118<= in; 7'b1110111 : q119<= in;
           7'b1111000 : q120<= in; 7'b1111001 : q121<= in; 7'b1111010 : q122<= in; 7'b1111011 : q123<= in;
           7'b1111100 : q124<= in; 7'b1111101 : q125<= in; 7'b1111110 : q126<= in; 7'b1111111 : q127<= in;
         endcase
       end
    end
  end

endmodule