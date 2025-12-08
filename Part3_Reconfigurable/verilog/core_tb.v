`timescale 1ns/1ps

module core_tb;

parameter bw        = 4;
parameter psum_bw   = 16;
parameter len_kij   = 9;
parameter len_onij  = 16;
parameter col       = 8;
parameter row       = 8;
parameter len_nij   = 36;

// OS_mode
parameter len_nij_os  = 120;    //
parameter len_onij_os = 8;     // nij_out = 8;
localparam [10:0] BASE_W = 11'b10000000000; 

reg clk   = 0;
reg reset = 1;
reg os_en = 0;

wire [34:0] inst_q; 

reg [1:0]  inst_w_q   = 0; 
reg [bw*row-1:0] D_xmem_q = 0;
reg        CEN_xmem   = 1;
reg        WEN_xmem   = 1;
reg [10:0] A_xmem     = 0;
reg        CEN_xmem_q = 1;
reg        WEN_xmem_q = 1;
reg [10:0] A_xmem_q   = 0;
reg        CEN_pmem   = 1;
reg        WEN_pmem   = 1;
reg [10:0] A_pmem     = 0;
reg        CEN_pmem_q = 1;
reg        WEN_pmem_q = 1;
reg [10:0] A_pmem_q   = 0;
reg        ofifo_rd_q = 0;
reg        ififo_wr_q = 0;
reg        ififo_rd_q = 0;
reg        l0_rd_q    = 0;
reg        l0_wr_q    = 0;
reg        execute_q  = 0;
reg        load_q     = 0;
reg        acc_q      = 0;
reg        acc        = 0;
reg        relu       = 0;
reg        relu_q     = 0;

reg [1:0]          inst_w; 
reg [bw*row-1:0]   D_xmem;
reg [psum_bw*col-1:0] answer;

reg ofifo_rd;
reg ififo_wr;
reg ififo_rd;
reg l0_rd;
reg l0_wr;
reg execute;
reg load;
reg [psum_bw*col-1:0] hw_row;

wire ofifo_valid;
wire [col*psum_bw-1:0] sfp_out;

integer x_file, x_scan_file;
integer w_file, w_scan_file;
integer acc_file, acc_scan_file;
integer out_file, out_scan_file;
integer captured_data; 
integer t, i, j, kij;
integer error;

integer r_dbg, c_dbg;
integer mac_cnt [0:row-1][0:col-1];         
reg [psum_bw-1:0] cq_prev [0:row-1][0:col-1]; 
reg [psum_bw-1:0] cq_now;

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

core  #(.bw(bw), .col(col), .row(row)) core_instance (
    .clk       (clk), 
    .inst      (inst_q),
    .ofifo_valid(ofifo_valid),
    .d_xmem    (D_xmem_q), 
    .sfp_out   (sfp_out), 
    .reset     (reset),
    .os_en     (os_en)
); 

function [psum_bw-1:0] get_cq;
    input integer rr;
    input integer cc;
    integer idx;
begin
    idx = col*rr + cc;
    get_cq = core_instance.corelet_insts.mac_array_instance.c_q_all[
                psum_bw*(idx+1)-1 -: psum_bw];
end
endfunction

function [bw-1:0] get_l0_out;
    input integer rr;
begin
    get_l0_out = core_instance.corelet_insts.l0_instance.out[
                   bw*(rr+1)-1 -: bw];
end
endfunction

function [bw-1:0] get_ififo_out;
    input integer cc;
begin
    get_ififo_out = core_instance.corelet_insts.ififo_instance.out[
                      bw*(cc+1)-1 -: bw];
end
endfunction


task automatic run_ws;
begin
    os_en = 1'b0;
    $display("========== Start WEIGHT-STATIONARY run ==========");

    inst_w   = 0; 
    D_xmem   = 0;
    CEN_xmem = 1;
    WEN_xmem = 1;
    A_xmem   = 0;
    CEN_pmem = 1;
    WEN_pmem = 1;
    A_pmem   = 0;
    ofifo_rd = 0;
    ififo_wr = 0;
    ififo_rd = 0;
    l0_rd    = 0;
    l0_wr    = 0;
    execute  = 0;
    load     = 0;
    acc      = 0;
    relu     = 0;
    error    = 0;

    // ---------------- Activation -> XMEM[0..35] ----------------
    x_file = $fopen("activation.txt", "r");
    x_scan_file = $fscanf(x_file,"%s", captured_data);
    x_scan_file = $fscanf(x_file,"%s", captured_data);
    x_scan_file = $fscanf(x_file,"%s", captured_data);

    #0.5 clk = 1'b0; reset = 1; #0.5 clk = 1'b1;
    repeat(10) begin #0.5 clk = 1'b0; #0.5 clk = 1'b1; end
    #0.5 clk = 1'b0; reset = 0; #0.5 clk = 1'b1;
    #0.5 clk = 1'b0;           #0.5 clk = 1'b1;

    for (t=0; t<len_nij; t=t+1) begin  
        #0.5 clk = 1'b0;  
        x_scan_file = $fscanf(x_file,"%32b", D_xmem); 
        WEN_xmem = 0; 
        CEN_xmem = 0; 
        if (t>0) A_xmem = A_xmem + 1;
        #0.5 clk = 1'b1;   
    end
    #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
    #0.5 clk = 1'b1; 
    $fclose(x_file);

    // ---------------- weight.txt ----------------
    w_file = $fopen("weight.txt", "r");
    w_scan_file = $fscanf(w_file,"%s", captured_data);
    w_scan_file = $fscanf(w_file,"%s", captured_data);
    w_scan_file = $fscanf(w_file,"%s", captured_data);

    for (kij=0; kij<9; kij=kij+1) begin  

        #0.5 clk = 1'b0; reset = 1; #0.5 clk = 1'b1; 
        repeat(10) begin #0.5 clk = 1'b0; #0.5 clk = 1'b1; end
        #0.5 clk = 1'b0; reset = 0; #0.5 clk = 1'b1;
        #0.5 clk = 1'b0;           #0.5 clk = 1'b1;

        // ---- weight -> XMEM[BASE_W..BASE_W+7] ----
        A_xmem = BASE_W;
        for (t=0; t<col; t=t+1) begin  
            #0.5 clk = 1'b0;  
            w_scan_file = $fscanf(w_file,"%32b", D_xmem); 
            WEN_xmem = 0; 
            CEN_xmem = 0; 
            if (t>0) A_xmem = A_xmem + 1; 
            #0.5 clk = 1'b1;  
        end
        #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
        #0.5 clk = 1'b1; 

        repeat(10) begin #0.5 clk = 1'b0; #0.5 clk = 1'b1; end

        // ---- XMEM -> L0 (kernel) ----
        WEN_xmem = 1;
        CEN_xmem = 0;
        l0_wr    = 1;
        l0_rd    = 0;
        A_xmem   = BASE_W;

        for (i=0; i<col; i=i+1) begin
            #0.5 clk = 1'b0;
            A_xmem = A_xmem + 1; 
            #0.5 clk = 1'b1; 
        end
        #0.5 clk = 1'b0; l0_wr = 0; #0.5 clk = 1'b1;

        repeat(10) begin #0.5 clk = 1'b0; #0.5 clk = 1'b1; end

        // ---- kernel load into PEs ----
        l0_rd = 1;
        #0.5 clk = 1'b1;
        for (i=0; i<col; i=i+1) begin
            #0.5 clk = 1'b0;
            load = 1;
            #0.5 clk = 1'b1; 
        end

        #0.5 clk = 1'b0;  load = 0; l0_rd = 0;
        #0.5 clk = 1'b1;  
        repeat(10) begin #0.5 clk = 1'b0; #0.5 clk = 1'b1; end

        // ---- Activation -> L0 ----
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
        #0.5 clk = 1'b0; l0_wr = 0; #0.5 clk = 1'b1;

        repeat(10) begin #0.5 clk = 1'b0; #0.5 clk = 1'b1; end

        l0_rd = 1;
        #0.5 clk = 1'b1;
        for (i=0; i<len_nij; i=i+1) begin
            #0.5 clk = 1'b0;
            execute = 1;
            #0.5 clk = 1'b1; 
        end
        for (i=0; i<row+col ; i=i+1) begin
            #0.5 clk = 1'b0; #0.5 clk = 1'b1;  
        end
        #0.5 clk = 1'b0; execute = 0; l0_rd = 0; #0.5 clk = 1'b1;  

        // ---- OFIFO -> psum mem ----
        #0.5 clk = 1'b0; ofifo_rd = 1; #0.5 clk = 1'b1;
        for (t=0; t<len_nij+1; t=t+1) begin  
            #0.5 clk = 1'b0;
            WEN_pmem = 0;
            CEN_pmem = 0;
            if (t>0) A_pmem = A_pmem + 1; 
            #0.5 clk = 1'b1;  
        end
        #0.5 clk = 1'b0; WEN_pmem = 1; CEN_pmem = 1; ofifo_rd = 0;
        #0.5 clk = 1'b1;
        repeat(10) begin #0.5 clk = 1'b0; #0.5 clk = 1'b1; end

        $display("[WS] No. %d execution completed.", kij);
    end

    $fclose(w_file);

    acc_file = $fopen("address.txt", "r");
    out_file = $fopen("output.txt", "r");  

    out_scan_file = $fscanf(out_file,"%s", answer); 
    out_scan_file = $fscanf(out_file,"%s", answer); 
    out_scan_file = $fscanf(out_file,"%s", answer); 

    error = 0;
    $display("[WS] ############ Verification Start during accumulation #############"); 

    for (i=0; i<len_onij+1; i=i+1) begin 
        #0.5 clk = 1'b0; #0.5 clk = 1'b1; 
        if (i>0) begin
            out_scan_file = $fscanf(out_file,"%128b", answer);
            if (sfp_out == answer)
                $display("[WS] %2d-th output featuremap Data matched! :D", i); 
            else begin
                $display("[WS] %2d-th output featuremap Data ERROR!!", i); 
                $display("sfpout: %128b", sfp_out);
                $display("answer: %128b", answer);
                error = 1;
            end
        end

        #0.5 clk = 1'b0; reset = 1; #0.5 clk = 1'b1;  
        #0.5 clk = 1'b0; reset = 0; #0.5 clk = 1'b1;  

        for (j=0; j<len_kij+1; j=j+1) begin 
            #0.5 clk = 1'b0;   
            if (j<len_kij) begin 
                CEN_pmem = 0; 
                WEN_pmem = 1; 
                acc_scan_file = $fscanf(acc_file,"%11b", A_pmem); 
            end else begin 
                CEN_pmem = 1; 
                WEN_pmem = 1; 
            end

            if (j>0)  acc = 1;  
            #0.5 clk = 1'b1;   
        end
  
        #0.5 clk = 1'b0; acc = 0; #0.5 clk = 1'b1; 
        #0.5 clk = 1'b0; relu = 1; #0.5 clk = 1'b1; 
        #0.5 clk = 1'b0; relu = 0; #0.5 clk = 1'b1; 
    end

    if (error == 0) begin
        $display("############ WS: No error detected ##############"); 
        $display("########### WS run Completed !! ############"); 
    end

    $fclose(acc_file);
    $fclose(out_file);

    for (t=0; t<10; t=t+1) begin  
        #0.5 clk = 1'b0; #0.5 clk = 1'b1;  
    end
end
endtask

// ====================================================================
task automatic run_os;
    integer produced;
begin
    os_en = 1'b1;
    $display("========== Start OUTPUT-STATIONARY run ==========");

    inst_w   = 0; 
    D_xmem   = 0;
    CEN_xmem = 1;
    WEN_xmem = 1;
    A_xmem   = 0;
    CEN_pmem = 1;
    WEN_pmem = 1;
    A_pmem   = 0;
    ofifo_rd = 0;
    ififo_wr = 0;
    ififo_rd = 0;
    l0_rd    = 0;
    l0_wr    = 0;
    execute  = 0;
    load     = 0;
    acc      = 0;
    relu     = 0;
    error    = 0;

    for (r_dbg = 0; r_dbg < row; r_dbg = r_dbg + 1) begin
        for (c_dbg = 0; c_dbg < col; c_dbg = c_dbg + 1) begin
            mac_cnt[r_dbg][c_dbg] = 0;
            cq_prev[r_dbg][c_dbg] = 0;
        end
    end

    // ------------ activation_os -> XMEM[0..71] ------------
    x_file = $fopen("activation_os.txt", "r");

    #0.5 clk = 1'b0; reset = 1; #0.5 clk = 1'b1;
    repeat(10) begin #0.5 clk = 1'b0; #0.5 clk = 1'b1; end
    #0.5 clk = 1'b0; reset = 0; #0.5 clk = 1'b1;
    #0.5 clk = 1'b0;           #0.5 clk = 1'b1;

    for (t=0; t<len_nij_os; t=t+1) begin  
        #0.5 clk = 1'b0;  
        x_scan_file = $fscanf(x_file,"%32b", D_xmem); 
        //$display("[FILE READ] t=%0d D_xmem=%032b", t, D_xmem);
        WEN_xmem = 0; 
        CEN_xmem = 0; 
        if (t>0) A_xmem = A_xmem + 1;
        #0.5 clk = 1'b1;   
    end
    #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
    #0.5 clk = 1'b1; 
    $fclose(x_file);

    // ------------ weight_os -> XMEM[BASE_W..BASE_W+71] ------------
    w_file = $fopen("weight_os.txt", "r");

    A_xmem = BASE_W;
    for (t=0; t<len_nij_os; t=t+1) begin  
        #0.5 clk = 1'b0;  
        w_scan_file = $fscanf(w_file,"%32b", D_xmem); 
        WEN_xmem = 0; 
        CEN_xmem = 0; 
        if (t>0) A_xmem = A_xmem + 1;
        #0.5 clk = 1'b1;   
    end
    #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
    #0.5 clk = 1'b1; 
    $fclose(w_file);

    // ------------ XMEM -> IFIFO (weight) ------------
    CEN_xmem = 0;  WEN_xmem = 1;
    A_xmem   = BASE_W;
    ififo_wr = 1;
    l0_wr    = 0;

    for (t=0; t<len_nij_os; t=t+1) begin
        #0.5 clk = 1'b0;
        if (t>0) A_xmem = A_xmem + 1;
        #0.5 clk = 1'b1;
    end
    #0.5 clk = 1'b0; ififo_wr = 0; CEN_xmem = 1; #0.5 clk = 1'b1;

    // ------------ XMEM -> L0 (activation) ------------
    CEN_xmem = 0;  WEN_xmem = 1;
    A_xmem   = 0;
    l0_wr    = 1;

    for (t=0; t<len_nij_os; t=t+1) begin
        #0.5 clk = 1'b0;
        if (t>0) A_xmem = A_xmem + 1;
        #0.5 clk = 1'b1;
    end
    #0.5 clk = 1'b0; l0_wr = 0; CEN_xmem = 1; #0.5 clk = 1'b1;

    repeat(5) begin #0.5 clk = 1'b0; #0.5 clk = 1'b1; end

    l0_rd    = 1;
    ififo_rd = 1;
    execute  = 0;
    load     = 0;

    repeat(2) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;
    end

    execute  = 1;

    for (t=0; t<len_nij_os; t=t+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;  

        if (execute == 1'b1) begin
            for (r_dbg = 0; r_dbg < row; r_dbg = r_dbg + 1) begin
                for (c_dbg = 0; c_dbg < col; c_dbg = c_dbg + 1) begin
                    cq_now = get_cq(r_dbg, c_dbg);
                    if (cq_now != cq_prev[r_dbg][c_dbg]) begin
                        mac_cnt[r_dbg][c_dbg] = mac_cnt[r_dbg][c_dbg] + 1;
                        cq_prev[r_dbg][c_dbg] = cq_now;
                    end
                end
            end

            //$display("t=%0d EXEC: cq(0,0)=%0d cq(1,0)=%0d cq(0,1)=%0d | L0_row0=%0d IFIFO_col0=%0d",
            //            t,
            //            $signed(get_cq(0,0)),
            //            $signed(get_cq(1,0)),
            //            $signed(get_cq(7,1)),
            //            get_l0_out(0),
            //           get_ififo_out(0));
        end
    end

    #0.5 clk = 1'b0;
    execute  = 0;
    load = 1;
    l0_rd    = 0;
    ififo_rd = 0;
    #0.5 clk = 1'b1;


    out_file = $fopen("output_os.txt", "r");

    $display("[OS] ############ Verification Start #############");
    error = 0;

    for (i = 0; i < row; i = i + 1) begin
        hw_row = core_instance.corelet_insts.mac_array_instance.c_q_all
                [psum_bw*col*(i+1)-1 -: psum_bw*col];

        out_scan_file = $fscanf(out_file, "%128b", answer);

        if (hw_row == answer) begin
            $display("[OS] %2d-th nij_out matched :D", i);
        end else begin
            $display("[OS] %2d-th nij_out Data ERROR!!", i);
            $display("hw   : %128b", hw_row);
            $display("gold : %128b", answer);
            error = 1;
        end
    end

    $fclose(out_file);

    if (error == 0) begin
        $display("############ OS : No error detected ##############");
    end

    for (t=0; t<10; t=t+1) begin  
        #0.5 clk = 1'b0; #0.5 clk = 1'b1;  
    end
end
endtask

// ====================================================================
//  initial
// ====================================================================
initial begin 
    $dumpfile("core_tb.vcd");
    $dumpvars(0,core_tb);

    run_ws();

    #0.5 clk = 1'b0; reset = 1; #0.5 clk = 1'b1;
    #0.5 clk = 1'b0;           #0.5 clk = 1'b1;
    #0.5 clk = 1'b0; reset = 0; #0.5 clk = 1'b1;

    run_os(); 

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
end
endmodule
