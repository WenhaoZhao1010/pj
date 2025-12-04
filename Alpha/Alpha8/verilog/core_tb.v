// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
`timescale 1ns/1ps

module core_tb;

parameter bw = 8;
parameter psum_bw = 16;
parameter len_kij = 9;
parameter len_onij = 16;
parameter col = 8;
parameter row = 8;
parameter och_tile = 2;
parameter len_nij = 36;

reg clk = 0;
reg reset = 1;

wire [34:0] inst_q; 

reg [1:0]  inst_w_q = 0; 
reg [bw*row-1:0] D_xmem_q = 0;
reg CEN_xmem = 1;
reg WEN_xmem = 1;
reg [10:0] A_xmem = 0;
reg CEN_xmem_q = 1;
reg WEN_xmem_q = 1;
reg [10:0] A_xmem_q = 0;
reg CEN_pmem = 1;
reg WEN_pmem = 1;
reg [10:0] A_pmem = 0;
reg CEN_pmem_q = 1;
reg WEN_pmem_q = 1;
reg [10:0] A_pmem_q = 0;
reg ofifo_rd_q = 0;
reg ififo_wr_q = 0;
reg ififo_rd_q = 0;
reg l0_rd_q = 0;
reg l0_wr_q = 0;
reg execute_q = 0;
reg load_q = 0;
reg acc_q = 0;
reg acc = 0;
reg relu = 0;
reg relu_q = 0;
reg ctrl_q = 0;
reg huffman_data_in_q = 0;
reg huffman_en_q = 0;


reg [1:0]  inst_w; 
reg [bw*row-1:0] D_xmem;
reg [psum_bw*col-1:0] answer;
reg huffman_data_in;
reg huffman_en;


reg ofifo_rd;
reg ififo_wr;
reg ififo_rd;
reg l0_rd;
reg l0_wr;
reg execute;
reg load;
reg [8*30:1] stringvar;
reg [8*30:1] w_file_name;
wire ofifo_valid;
wire [col*psum_bw-1:0] sfp_out;
reg ctrl;

integer x_file, x_scan_file ; // file_handler
integer w_file, w_scan_file ; // file_handler
integer acc_file, acc_scan_file ; // file_handler
integer out_file, out_scan_file ; // file_handler
integer runans_file, runans_hex_file ; // file_handler
integer x_huffman_file, x_huffman_scan_file ; // file_handler
integer captured_data; 
integer t, i, j, k, kij, och_t;
integer error;

assign inst_q[34]   = relu_q;        // ReLU activation enable
assign inst_q[33]   = acc_q;         // Accumulation operation enable
assign inst_q[32]   = CEN_pmem_q;    // PMEM chip enable (0 = enabled, 1 = disabled)
assign inst_q[31]   = WEN_pmem_q;    // PMEM write enable (0 = write, 1 = read)
assign inst_q[30:20] = A_pmem_q;     // PMEM address (11 bits for 2048 memory locations)
assign inst_q[19]   = CEN_xmem_q;    // XMEM chip enable (0 = enabled, 1 = disabled)
assign inst_q[18]   = WEN_xmem_q;    // XMEM write enable (0 = write, 1 = read)
assign inst_q[17:7] = A_xmem_q;      // XMEM address (11 bits for 2048 memory locations)
assign inst_q[6]    = ofifo_rd_q;    // Output FIFO read enable
assign inst_q[5]    = huffman_en_q;    // Huffman decoding enable
assign inst_q[4]    = ctrl_q;        // Control bit for activation bitwidth (0 = 2bit, 1 = 4bit)
assign inst_q[3]    = l0_rd_q;       // L0 buffer read enable
assign inst_q[2]    = l0_wr_q;       // L0 buffer write enable
assign inst_q[1]    = execute_q;     // Execute operation enable
assign inst_q[0]    = load_q;        // Load operation enable //inst [1:0] = {execute, kernel loading} 


core  #(.bw(bw), .col(col), .row(row)) core_instance (
	.clk(clk), 
	.inst(inst_q),
	.ofifo_valid(ofifo_valid),
  .huffman_data_in(huffman_data_in_q),
        .d_xmem(D_xmem_q), 
        .sfp_out(sfp_out), 
	.reset(reset)); 




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
  ctrl     = 0;
  huffman_data_in = 0;
  huffman_en = 0;

  $dumpfile("core_tb.vcd");
  $dumpvars(0,core_tb);
  $display("########### Now begin 2b4b testbench ############"); 

  x_file = $fopen("activation2b4b.txt", "r");
  // Following three lines are to remove the first three comment lines of the file
  x_scan_file = $fscanf(x_file,"%s", captured_data);
  x_scan_file = $fscanf(x_file,"%s", captured_data);
  // x_scan_file = $fscanf(x_file,"%s", captured_data);

  //////// Reset /////////
  #0.5 clk = 1'b0;   reset = 1;
  #0.5 clk = 1'b1; 

  for (i=0; i<10 ; i=i+1) begin
    #0.5 clk = 1'b0;
    #0.5 clk = 1'b1;  
  end

  #0.5 clk = 1'b0;   reset = 0;
  #0.5 clk = 1'b1; 

  #0.5 clk = 1'b0;   
  #0.5 clk = 1'b1;   
  /////////////////////////

  /////// Activation data writing to memory ///////
  for (t=0; t<len_nij; t=t+1) begin  
    #0.5 clk = 1'b0;  
    x_scan_file = $fscanf(x_file,"%64b", D_xmem); 
    WEN_xmem = 0; 
    CEN_xmem = 0; 
    if (t>0) A_xmem = A_xmem + 1;
    #0.5 clk = 1'b1;   
  end

  #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
  #0.5 clk = 1'b1; 

  $fclose(x_file);
  /////////////////////////////////////////////////

  w_file_name = "weight2b4b.txt";
  w_file = $fopen(w_file_name, "r");
  // Following three lines are to remove the first three comment lines of the file
  w_scan_file = $fscanf(w_file,"%s", captured_data);
  w_scan_file = $fscanf(w_file,"%s", captured_data);
  // w_scan_file = $fscanf(w_file,"%s", captured_data);

//------------------------------------------------------------

  for (kij=0; kij<9; kij=kij+1) begin  // kij loop
    for (och_t=0; och_t<och_tile; och_t=och_t+1) begin

      
      #0.5 clk = 1'b0;   reset = 1;
      #0.5 clk = 1'b1; 

      for (i=0; i<10 ; i=i+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;  
      end

      #0.5 clk = 1'b0;   reset = 0;
      #0.5 clk = 1'b1; 

      #0.5 clk = 1'b0;   
      #0.5 clk = 1'b1;   

      /////// Kernel data writing to memory ///////

      A_xmem = 11'b10000000000;

      for (t=0; t<col; t=t+1) begin  
        #0.5 clk = 1'b0;  
        w_scan_file = $fscanf(w_file,"%64b", D_xmem); 
        WEN_xmem = 0; 
        CEN_xmem = 0; 
        if (t>0) A_xmem = A_xmem + 1; 
        #0.5 clk = 1'b1;  
      end

      #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
      #0.5 clk = 1'b1; 
      /////////////////////////////////////

      for (i=0; i<10 ; i=i+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;  
      end

      /////// Kernel data writing to L0 ///////

      WEN_xmem = 1; // Xmem read enable
      CEN_xmem = 0; // Xmem chip enable
      l0_wr = 1;    // L0 write enable
      l0_rd = 0;    // L0 read disable
      A_xmem = 11'b10000000000;   // address set to the start of kernel data

      for (i=0; i<col; i=i+1) begin
        #0.5 clk = 1'b0;
        A_xmem = A_xmem + 1; 
        #0.5 clk = 1'b1; 
      end

      #0.5 clk = 1'b0;
      l0_wr = 0;    // L0 write disable
      #0.5 clk = 1'b1;

      for (i=0; i<10 ; i=i+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;  
      end

      #0.5 clk = 1'b0;
      /////////////////////////////////////



      /////// Kernel loading to PEs ///////
      l0_rd = 1;  // L0 read enable
      #0.5 clk = 1'b1;

      for (i=0; i<col; i=i+1) begin
        #0.5 clk = 1'b0;
        load = 1;
        #0.5 clk = 1'b1; 
      end

      /////////////////////////////////////
    


      ////// provide some intermission to clear up the kernel loading ///
      #0.5 clk = 1'b0;  load = 0; l0_rd = 0;
      #0.5 clk = 1'b1;  
    

      for (i=0; i<10 ; i=i+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;  
      end
      /////////////////////////////////////



      /////// Activation data writing to L0 ///////
      
      WEN_xmem = 1; // Xmem read enable
      CEN_xmem = 0; // Xmem chip enable
      l0_wr = 1;    // L0 write enable
      l0_rd = 0;    // L0 read disable
      A_xmem = 0;   // address set to the start of kernel data

      for (i=0; i<len_nij; i=i+1) begin
        #0.5 clk = 1'b0;
        A_xmem = A_xmem + 1; 
        #0.5 clk = 1'b1; 
      end

      #0.5 clk = 1'b0;
      l0_wr = 0;    // L0 write disable
      #0.5 clk = 1'b1;
      
      for (i=0; i<10 ; i=i+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;  
      end

      #0.5 clk = 1'b0;
      /////////////////////////////////////



      /////// Execution ///////
      l0_rd = 1;    // L0 read enable
      #0.5 clk = 1'b1;

      for (i=0; i<len_nij; i=i+1) begin
        #0.5 clk = 1'b0;
        execute = 1;      // execute
        #0.5 clk = 1'b1; 
      end

      for (i=0; i<row+col ; i=i+1) begin
          #0.5 clk = 1'b0;
          #0.5 clk = 1'b1;  
      end

      #0.5 clk = 1'b0;  
      execute = 0;      // execute ends
      l0_rd = 0;        // L0 read disable
      #0.5 clk = 1'b1;  
      /////////////////////////////////////



      //////// OFIFO READ ////////
      // Ideally, OFIFO should be read while execution, but we have enough ofifo
      // depth so we can fetch out after execution.
      
      #0.5 clk = 1'b0;
      ofifo_rd = 1;     // OFIFO read enable
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

      for (i=0; i<10 ; i=i+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;  
      end

      /////////////////////////////////////

      $display("No. %d th och_tile, kij = %d execution completed.",och_t,kij);
    end // end of och_t loop
  end  // end of kij loop

/////////////////////////////////////////////////////////////////////////
//-------------------------------------------------------------------------
/////////////////////////////////////////////////////////////////////////

  ////////// Accumulation /////////
  acc_file = $fopen("address2b4b.txt", "r");
  out_file = $fopen("output2b4b.txt", "r");  
  runans_file = $fopen("runans.txt", "w");
  runans_hex_file = $fopen("runans_hex.txt", "w");

  // Following three lines are to remove the first three comment lines of the file
  out_scan_file = $fscanf(out_file,"%s", answer); 
  out_scan_file = $fscanf(out_file,"%s", answer); 
  // out_scan_file = $fscanf(out_file,"%s", answer); 

  error = 0;



  $display("############ Verification Start during accumulation #############"); 
for (och_t = 0; och_t < och_tile; och_t = och_t + 1) begin
    for (i=0; i<len_onij+1-och_t; i=i+1) begin 

    #0.5 clk = 1'b0; 
    #0.5 clk = 1'b1; 
    if (i>0||och_t>0) begin
     out_scan_file = $fscanf(out_file,"%128b", answer); // reading from out file to answer
     $fwrite(runans_file,"%128b\n", sfp_out); // write the sfp_out to runans file
     $fwrite(runans_hex_file,"%x\n", sfp_out); 
       if (sfp_out == answer)
         $display("%2d-th output featuremap Data matched! :D", i+och_t); 
       else begin
         $display("%2d-th output featuremap Data ERROR!!", i+och_t); 
         $display("sfpout: %128b", sfp_out);
         $display("answer: %128b", answer);
         error = 1;
       end
    end
   

    #0.5 clk = 1'b0; reset = 1;
    #0.5 clk = 1'b1;  
    #0.5 clk = 1'b0; reset = 0; 
    #0.5 clk = 1'b1;  
    
      for (j=0; j<len_kij+1; j=j+1) begin 

        #0.5 clk = 1'b0;   
          if (j<len_kij) begin CEN_pmem = 0; WEN_pmem = 1; acc_scan_file = $fscanf(acc_file,"%11b", A_pmem); end
                        else  begin CEN_pmem = 1; WEN_pmem = 1; end

          if (j>0)  acc = 1;  
        #0.5 clk = 1'b1;   
      end // end of kij loop
      // #0.5 clk = 1'b0; acc = 0;
      // #0.5 clk = 1'b1; 
    
  
    #0.5 clk = 1'b0; acc = 0;
    #0.5 clk = 1'b1; 

    #0.5 clk = 1'b0; relu = 1;
    #0.5 clk = 1'b1; 
    #0.5 clk = 1'b0; relu = 0;
    #0.5 clk = 1'b1; 

    end
  end // end of och_t loop

  if (error == 0) begin
  	$display("############ No error detected ##############"); 
  	$display("########### Project Completed !! ############"); 

  end

  $fclose(acc_file);
  $fclose(out_file);
  $fclose(runans_file);
  $fclose(runans_hex_file);
  //////////////////////////////////

  for (t=0; t<10; t=t+1) begin  
    #0.5 clk = 1'b0;  
    #0.5 clk = 1'b1;  
  end


//------------------------------------------------------------
//------------------------------------------------------------
// 4b4b testbench start from here
//------------------------------------------------------------
//------------------------------------------------------------
  $display("########### Now begin 4b4b testbench ############"); 

  x_file = $fopen("activation4b4b.txt", "r");
  // Following three lines are to remove the first three comment lines of the file
  x_scan_file = $fscanf(x_file,"%s", captured_data);
  x_scan_file = $fscanf(x_file,"%s", captured_data);
  // x_scan_file = $fscanf(x_file,"%s", captured_data);
  x_huffman_file = $fopen("activation4b4b_huffman.txt", "r");

  //////// Reset /////////
  #0.5 clk = 1'b0;   reset = 1; ctrl = 1; A_xmem = 0; A_pmem = 0;
  #0.5 clk = 1'b1; 

  for (i=0; i<10 ; i=i+1) begin
    #0.5 clk = 1'b0;
    #0.5 clk = 1'b1;  
  end

  #0.5 clk = 1'b0;   reset = 0;
  #0.5 clk = 1'b1; 

  #0.5 clk = 1'b0;   
  #0.5 clk = 1'b1;   
  /////////////////////////

  /////// Activation data writing to memory ///////

  $display("########### Now we disable huffman decoding ############"); 
  for (t=0; t<len_nij; t=t+1) begin  
    #0.5 clk = 1'b0;  
    x_scan_file = $fscanf(x_file,"%64b", D_xmem); 
    WEN_xmem = 0; 
    CEN_xmem = 0; 
    if (t>0) A_xmem = A_xmem + 1;
    #0.5 clk = 1'b1;   
  end

  // $display("########### Now we enable huffman decoding ############"); 
  // while (!$feof(x_huffman_file)) begin
  //   #0.5 clk = 1'b0;  
  //   huffman_en = 1;
  //   x_huffman_scan_file = $fscanf(x_huffman_file,"%1b", huffman_data_in); 
  //   #0.5 clk = 1'b1;   
  // end
  //   for (i=0; i<500 ; i=i+1) begin
  //   #0.5 clk = 1'b0;
  //   #0.5 clk = 1'b1;  
  // end
  // huffman_en = 0;

  #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
  #0.5 clk = 1'b1; 

  $fclose(x_file);
  $fclose(x_huffman_file);
  /////////////////////////////////////////////////

  w_file_name = "weight4b4b.txt";
  w_file = $fopen(w_file_name, "r");
  // Following three lines are to remove the first three comment lines of the file
  w_scan_file = $fscanf(w_file,"%s", captured_data);
  w_scan_file = $fscanf(w_file,"%s", captured_data);
  // w_scan_file = $fscanf(w_file,"%s", captured_data);

//------------------------------------------------------------

  for (kij=0; kij<9; kij=kij+1) begin  // kij loop
    // for (och_t=0; och_t<och_tile; och_t=och_t+1) begin

      
      #0.5 clk = 1'b0;   reset = 1;
      #0.5 clk = 1'b1; 

      for (i=0; i<10 ; i=i+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;  
      end

      #0.5 clk = 1'b0;   reset = 0;
      #0.5 clk = 1'b1; 

      #0.5 clk = 1'b0;   
      #0.5 clk = 1'b1;   

      /////// Kernel data writing to memory ///////

      A_xmem = 11'b10000000000;

      for (t=0; t<col; t=t+1) begin  
        #0.5 clk = 1'b0;  
        w_scan_file = $fscanf(w_file,"%64b", D_xmem); 
        WEN_xmem = 0; 
        CEN_xmem = 0; 
        if (t>0) A_xmem = A_xmem + 1; 
        #0.5 clk = 1'b1;  
      end

      #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
      #0.5 clk = 1'b1; 
      /////////////////////////////////////

      for (i=0; i<10 ; i=i+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;  
      end

      /////// Kernel data writing to L0 ///////

      WEN_xmem = 1; // Xmem read enable
      CEN_xmem = 0; // Xmem chip enable
      l0_wr = 1;    // L0 write enable
      l0_rd = 0;    // L0 read disable
      A_xmem = 11'b10000000000;   // address set to the start of kernel data

      for (i=0; i<col; i=i+1) begin
        #0.5 clk = 1'b0;
        A_xmem = A_xmem + 1; 
        #0.5 clk = 1'b1; 
      end

      #0.5 clk = 1'b0;
      l0_wr = 0;    // L0 write disable
      #0.5 clk = 1'b1;

      for (i=0; i<10 ; i=i+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;  
      end

      #0.5 clk = 1'b0;
      /////////////////////////////////////



      /////// Kernel loading to PEs ///////
      l0_rd = 1;  // L0 read enable
      #0.5 clk = 1'b1;

      for (i=0; i<col; i=i+1) begin
        #0.5 clk = 1'b0;
        load = 1;
        #0.5 clk = 1'b1; 
      end

      /////////////////////////////////////
    


      ////// provide some intermission to clear up the kernel loading ///
      #0.5 clk = 1'b0;  load = 0; l0_rd = 0;
      #0.5 clk = 1'b1;  
    

      for (i=0; i<10 ; i=i+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;  
      end
      /////////////////////////////////////



      /////// Activation data writing to L0 ///////
      
      WEN_xmem = 1; // Xmem read enable
      CEN_xmem = 0; // Xmem chip enable
      l0_wr = 1;    // L0 write enable
      l0_rd = 0;    // L0 read disable
      A_xmem = 0;   // address set to the start of kernel data

      for (i=0; i<len_nij; i=i+1) begin
        #0.5 clk = 1'b0;
        A_xmem = A_xmem + 1; 
        #0.5 clk = 1'b1; 
      end

      #0.5 clk = 1'b0;
      l0_wr = 0;    // L0 write disable
      #0.5 clk = 1'b1;
      
      for (i=0; i<10 ; i=i+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;  
      end

      #0.5 clk = 1'b0;
      /////////////////////////////////////



      /////// Execution ///////
      l0_rd = 1;    // L0 read enable
      #0.5 clk = 1'b1;

      for (i=0; i<len_nij; i=i+1) begin
        #0.5 clk = 1'b0;
        execute = 1;      // execute
        #0.5 clk = 1'b1; 
      end

      for (i=0; i<row+col ; i=i+1) begin
          #0.5 clk = 1'b0;
          #0.5 clk = 1'b1;  
      end

      #0.5 clk = 1'b0;  
      execute = 0;      // execute ends
      l0_rd = 0;        // L0 read disable
      #0.5 clk = 1'b1;  
      /////////////////////////////////////



      //////// OFIFO READ ////////
      // Ideally, OFIFO should be read while execution, but we have enough ofifo
      // depth so we can fetch out after execution.
      
      #0.5 clk = 1'b0;
      ofifo_rd = 1;     // OFIFO read enable
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

      for (i=0; i<10 ; i=i+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;  
      end

      /////////////////////////////////////

      $display("No. %d(kij) execution completed.",kij);
    // end // end of och_t loop
  end  // end of kij loop

/////////////////////////////////////////////////////////////////////////
//-------------------------------------------------------------------------
/////////////////////////////////////////////////////////////////////////

  ////////// Accumulation /////////
  acc_file = $fopen("address4b4b.txt", "r");
  out_file = $fopen("output4b4b.txt", "r");  
  runans_file = $fopen("runans4b4b.txt", "w");
  runans_hex_file = $fopen("runans4b4b_hex.txt", "w");

  // Following three lines are to remove the first three comment lines of the file
  out_scan_file = $fscanf(out_file,"%s", answer); 
  out_scan_file = $fscanf(out_file,"%s", answer); 
  // out_scan_file = $fscanf(out_file,"%s", answer); 

  error = 0;



  $display("############ Verification Start during accumulation #############"); 
// for (och_t = 0; och_t < och_tile; och_t = och_t + 1) begin
    for (i=0; i<len_onij+1; i=i+1) begin 

    #0.5 clk = 1'b0; 
    #0.5 clk = 1'b1; 
    if (i>0) begin
     out_scan_file = $fscanf(out_file,"%128b", answer); // reading from out file to answer
     $fwrite(runans_file,"%128b\n", sfp_out); // write the sfp_out to runans file
     $fwrite(runans_hex_file,"%x\n", sfp_out); 
       if (sfp_out == answer)
         $display("%2d-th output featuremap Data matched! :D", i); 
       else begin
         $display("%2d-th output featuremap Data ERROR!!", i); 
         $display("sfpout: %128b", sfp_out);
         $display("answer: %128b", answer);
         error = 1;
       end
    end
   

    #0.5 clk = 1'b0; reset = 1;
    #0.5 clk = 1'b1;  
    #0.5 clk = 1'b0; reset = 0; 
    #0.5 clk = 1'b1;  
    
      for (j=0; j<len_kij+1; j=j+1) begin 

        #0.5 clk = 1'b0;   
          if (j<len_kij) begin CEN_pmem = 0; WEN_pmem = 1; acc_scan_file = $fscanf(acc_file,"%11b", A_pmem); end
                        else  begin CEN_pmem = 1; WEN_pmem = 1; end

          if (j>0)  acc = 1;  
        #0.5 clk = 1'b1;   
      end // end of kij loop
      // #0.5 clk = 1'b0; acc = 0;
      // #0.5 clk = 1'b1; 
    
  
    #0.5 clk = 1'b0; acc = 0;
    #0.5 clk = 1'b1; 

    #0.5 clk = 1'b0; relu = 0;
    #0.5 clk = 1'b1; 
    #0.5 clk = 1'b0; relu = 0;
    #0.5 clk = 1'b1; 

    end
  // end // end of och_t loop

  if (error == 0) begin
  	$display("############ No error detected ##############"); 
  	$display("########### Project Completed !! ############"); 

  end

  $fclose(acc_file);
  $fclose(out_file);
  $fclose(runans_file);
  $fclose(runans_hex_file);
  //////////////////////////////////

  for (t=0; t<10; t=t+1) begin  
    #0.5 clk = 1'b0;  
    #0.5 clk = 1'b1;  
  end

  #10 $finish;

end

always @ (posedge clk) begin
   inst_w_q   <= inst_w; 
   D_xmem_q   <= D_xmem;
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
   l0_wr_q    <= l0_wr ;
   execute_q  <= execute;
   load_q     <= load;
   relu_q     <= relu;
   ctrl_q     <= ctrl;
   huffman_data_in_q <= huffman_data_in;
   huffman_en_q <= huffman_en;
end


endmodule




