`timescale 1ns/1ps

module dual_core_tb;

  parameter bw       = 4;
  parameter psum_bw  = 16;
  parameter len_kij  = 9;
  parameter len_onij = 16;
  parameter col      = 8;
  parameter row      = 8;
  parameter len_nij  = 36;

  reg clk   = 0;
  reg reset = 1;

  wire [34:0] inst_q;

  reg [1:0]           inst_w_q   = 0;
  reg [bw*row-1:0]    D_xmem     = 0;   
  reg [bw*row-1:0]    D_xmem_q0  = 0;  
  reg [bw*row-1:0]    D_xmem_q1  = 0; 

  reg CEN_xmem   = 1;
  reg WEN_xmem   = 1;
  reg [10:0] A_xmem   = 0;
  reg CEN_xmem_q = 1;
  reg WEN_xmem_q = 1;
  reg [10:0] A_xmem_q = 0;

  reg CEN_pmem   = 1;
  reg WEN_pmem   = 1;
  reg [10:0] A_pmem   = 0;
  reg CEN_pmem_q = 1;
  reg WEN_pmem_q = 1;
  reg [10:0] A_pmem_q = 0;

  reg ofifo_rd_q  = 0;
  reg ififo_wr_q  = 0;
  reg ififo_rd_q  = 0;
  reg l0_rd_q     = 0;
  reg l0_wr_q     = 0;
  reg execute_q   = 0;
  reg load_q      = 0;
  reg acc_q       = 0;
  reg acc         = 0;
  reg relu        = 0;
  reg relu_q      = 0;

  reg [1:0]        inst_w;
  reg [8*30:1]     stringvar;
  reg [8*30:1]     w_file_name;

  reg [psum_bw*col-1:0]      answer8;
  reg [2*psum_bw*col-1:0]    answer16;

  reg ofifo_rd;
  reg ififo_wr;
  reg ififo_rd;
  reg l0_rd;
  reg l0_wr;
  reg execute;
  reg load;

  wire ofifo_valid0;
  wire ofifo_valid1;
  wire [col*psum_bw-1:0]   sfp_out0;
  wire [col*psum_bw-1:0]   sfp_out1;
  wire [2*col*psum_bw-1:0] sfp_out_16ch;

  assign sfp_out_16ch = {sfp_out1, sfp_out0};

  integer x_file, x_scan_file;      
  integer w_file, w_scan_file;      
  integer acc_file, acc_scan_file; 
  integer out_file, out_scan_file;  
  integer captured_data;
  integer t, i, j, kij;
  integer error;

  assign inst_q[34]   = relu_q;
  assign inst_q[33]   = acc_q;
  assign inst_q[32]   = CEN_pmem_q;
  assign inst_q[31]   = WEN_pmem_q;
  assign inst_q[30:20]= A_pmem_q;
  assign inst_q[19]   = CEN_xmem_q;
  assign inst_q[18]   = WEN_xmem_q;
  assign inst_q[17:7] = A_xmem_q;
  assign inst_q[6]    = ofifo_rd_q;
  assign inst_q[5]    = ififo_wr_q;
  assign inst_q[4]    = ififo_rd_q;
  assign inst_q[3]    = l0_rd_q;
  assign inst_q[2]    = l0_wr_q;
  assign inst_q[1]    = execute_q;
  assign inst_q[0]    = load_q;

  core #(.bw(bw), .col(col), .row(row)) core0 (
      .clk        (clk),
      .inst       (inst_q),
      .ofifo_valid(ofifo_valid0),
      .d_xmem     (D_xmem_q0),
      .sfp_out    (sfp_out0),
      .reset      (reset)
  );

  core #(.bw(bw), .col(col), .row(row)) core1 (
      .clk        (clk),
      .inst       (inst_q),
      .ofifo_valid(ofifo_valid1),
      .d_xmem     (D_xmem_q1),
      .sfp_out    (sfp_out1),
      .reset      (reset)
  );

  initial begin
    inst_w   = 0;
    D_xmem   = 0;
    CEN_xmem = 1;
    WEN_xmem = 1;
    A_xmem   = 0;
    ofifo_rd = 0;
    ififo_wr = 0;
    ififo_rd = 0;
    l0_rd    = 0;
    l0_wr    = 0;
    execute  = 0;
    load     = 0;
    acc      = 0;
    relu     = 0;

    $dumpfile("dual_core_tb.vcd");
    $dumpvars(0, dual_core_tb);

    x_file = $fopen("activation.txt", "r");
    x_scan_file = $fscanf(x_file, "%s", captured_data);
    x_scan_file = $fscanf(x_file, "%s", captured_data);
    x_scan_file = $fscanf(x_file, "%s", captured_data);

    #0.5 clk = 1'b0; reset = 1;
    #0.5 clk = 1'b1;

    for (i=0; i<10; i=i+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;
    end

    #0.5 clk = 1'b0; reset = 0;
    #0.5 clk = 1'b1;

    #0.5 clk = 1'b0;
    #0.5 clk = 1'b1;

    for (t=0; t<len_nij; t=t+1) begin
      #0.5 clk = 1'b0;
      x_scan_file = $fscanf(x_file, "%32b", D_xmem); 
      WEN_xmem = 0;
      CEN_xmem = 0;
      if (t>0) A_xmem = A_xmem + 1;
      #0.5 clk = 1'b1;
    end

    #0.5 clk = 1'b0; WEN_xmem = 1; CEN_xmem = 1; A_xmem = 0;
    #0.5 clk = 1'b1;

    $fclose(x_file);

    w_file_name = "weight.txt";
    w_file = $fopen(w_file_name, "r");
    w_scan_file = $fscanf(w_file, "%s", captured_data);
    w_scan_file = $fscanf(w_file, "%s", captured_data);
    w_scan_file = $fscanf(w_file, "%s", captured_data);

    for (kij=0; kij<9; kij=kij+1) begin

      #0.5 clk = 1'b0; reset = 1;
      #0.5 clk = 1'b1;

      for (i=0; i<10; i=i+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;
      end

      #0.5 clk = 1'b0; reset = 0;
      #0.5 clk = 1'b1;

      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;

      A_xmem = 11'b10000000000;

      for (t=0; t<col; t=t+1) begin
        #0.5 clk = 1'b0;
        w_scan_file = $fscanf(w_file, "%32b", D_xmem);
        WEN_xmem = 0;
        CEN_xmem = 0;
        if (t>0) A_xmem = A_xmem + 1;
        #0.5 clk = 1'b1;
      end

      #0.5 clk = 1'b0; WEN_xmem = 1; CEN_xmem = 1; A_xmem = 0;
      #0.5 clk = 1'b1;

      for (i=0; i<10; i=i+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;
      end

      WEN_xmem = 1;
      CEN_xmem = 0;
      l0_wr    = 1;
      l0_rd    = 0;
      A_xmem   = 11'b10000000000;

      for (i=0; i<col; i=i+1) begin
        #0.5 clk = 1'b0;
        A_xmem = A_xmem + 1;
        #0.5 clk = 1'b1;
      end

      #0.5 clk = 1'b0;
      l0_wr = 0;
      #0.5 clk = 1'b1;

      for (i=0; i<10; i=i+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;
      end

      #0.5 clk = 1'b0;

      l0_rd = 1;
      #0.5 clk = 1'b1;

      for (i=0; i<col; i=i+1) begin
        #0.5 clk = 1'b0;
        load = 1;
        #0.5 clk = 1'b1;
      end

      #0.5 clk = 1'b0; load = 0; l0_rd = 0;
      #0.5 clk = 1'b1;

      for (i=0; i<10; i=i+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;
      end

      WEN_xmem = 1;
      CEN_xmem = 0;
      l0_wr    = 1;
      l0_rd    = 0;
      A_xmem   = 0;

      for (i=0; i<len_nij; i=i+1) begin
        #0.5 clk = 1'b0;
        A_xmem = A_xmem + 1;
        #0.5 clk = 1'b1;
      end

      #0.5 clk = 1'b0;
      l0_wr = 0;
      #0.5 clk = 1'b1;

      for (i=0; i<10; i=i+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;
      end

      #0.5 clk = 1'b0;

      l0_rd = 1;
      #0.5 clk = 1'b1;

      for (i=0; i<len_nij; i=i+1) begin
        #0.5 clk = 1'b0;
        execute = 1;
        #0.5 clk = 1'b1;
      end

      for (i=0; i<row+col; i=i+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;
      end

      #0.5 clk = 1'b0;
      execute = 0;
      l0_rd   = 0;
      #0.5 clk = 1'b1;

      #0.5 clk = 1'b0;
      ofifo_rd = 1;
      #0.5 clk = 1'b1;

      for (t=0; t<len_nij+1; t=t+1) begin
        #0.5 clk = 1'b0;
        WEN_pmem = 0;
        CEN_pmem = 0;
        if (t>0) A_pmem = A_pmem + 1;
        #0.5 clk = 1'b1;
      end

      #0.5 clk = 1'b0;
      WEN_pmem = 1;
      CEN_pmem = 1;
      ofifo_rd = 0;
      #0.5 clk = 1'b1;

      for (i=0; i<10; i=i+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;
      end

      $display("No. %0d kij execution completed.", kij);

    end // kij loop

    $fclose(w_file);

    acc_file = $fopen("address.txt", "r");
    out_file = $fopen("output.txt", "r");

    out_scan_file = $fscanf(out_file, "%s", answer8);
    out_scan_file = $fscanf(out_file, "%s", answer8);
    out_scan_file = $fscanf(out_file, "%s", answer8);

    error = 0;

    $display("############ Dual-core Verification Start #############");

    for (i=0; i<len_onij+1; i=i+1) begin

      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;

      if (i>0) begin
       out_scan_file = $fscanf(out_file, "%128b", answer8);
        answer16 = {answer8, answer8};  
        if (sfp_out_16ch == answer16) begin
          $display("%2d-th output: (Core0 and Core1) output featuremap Data matched! :D", i);
        end else begin
          $display("%2d-th output: (Core0 and Core1) output featuremap Data ERROR!!", i);
          $display("sfp_out_16ch: %256b", sfp_out_16ch);
          $display("answer16    : %256b", answer16);
          error = 1;
        end
      end

      
	  #0.5 clk = 1'b0; reset = 1;
      #0.5 clk = 1'b1;
      #0.5 clk = 1'b0; reset = 0;
      #0.5 clk = 1'b1;

      for (j=0; j<len_kij+1; j=j+1) begin
        #0.5 clk = 1'b0;
        if (j<len_kij) begin
          CEN_pmem = 0;
          WEN_pmem = 1;
          acc_scan_file = $fscanf(acc_file, "%11b", A_pmem);
        end else begin
          CEN_pmem = 1;
          WEN_pmem = 1;
        end

        if (j>0) acc = 1;
        #0.5 clk = 1'b1;
      end

      #0.5 clk = 1'b0; acc = 0;
      #0.5 clk = 1'b1;

      #0.5 clk = 1'b0; relu = 1;
      #0.5 clk = 1'b1;
      #0.5 clk = 1'b0; relu = 0;
      #0.5 clk = 1'b1;

    end // onij loop

    if (error == 0) begin
      $display("############ No error detected #############");
      $display("########### Project Completed ############");
    end

    $fclose(acc_file);

    for (t=0; t<10; t=t+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;
    end

    #10 $finish;

  end // initial

  always @(posedge clk) begin
    inst_w_q   <= inst_w;

    D_xmem_q0  <= D_xmem;  
    D_xmem_q1  <= D_xmem;

    CEN_xmem_q <= CEN_xmem;
    WEN_xmem_q <= WEN_xmem;
    A_pmem_q   <= A_pmem;
    CEN_pmem_q <= CEN_pmem;
    WEN_pmem_q <= WEN_pmem;
    A_xmem_q   <= A_xmem;
    ofifo_rd_q <= ofifo_rd;
    acc_q      <= acc;
    ififo_wr_q <= ififo_wr;
    ififo_rd_q <= ififo_rd;
    l0_rd_q    <= l0_rd;
    l0_wr_q    <= l0_wr;
    execute_q  <= execute;
    load_q     <= load;
    relu_q     <= relu;
  end

endmodule
