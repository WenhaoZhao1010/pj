If you need to test the experimental results, please place all the files from the datafiles, verilog folders in the same folder, which is used by executing simulation experiments. 
The platform for simulation is Icarus Verilog. 

Simulation steps are:

Step 1 Open the folder cotaining all of the files from datafiles and verilog folders in the terminal.

Step 2 Write this command in the terminal: iverilog -o core_tb.vvp core_tb.v core.v corelet.v mac_array.v mac_row.v mac_tile.v mac.v l0.v ofifo.v sfu.v fifo_depth64.v fifo_depth8.v fifo_mux_16_1.v fifo_mux_8_1.v fifo_mux_2_1.v sram_32b_w2048.v

Step 3 After finishing step 2, please write this command in the terminal: vvp core_tb.vvp

Step 4 Get the experiments' results.

The experiments' results are shown below.
<img width="975" height="413" alt="image" src="https://github.com/user-attachments/assets/9caf4897-495c-4894-82ca-ca45549420c7" />
<img width="975" height="318" alt="image" src="https://github.com/user-attachments/assets/4436f448-510d-4394-9165-6b04511f2c36" />
<img width="975" height="387" alt="image" src="https://github.com/user-attachments/assets/432b58bc-739a-460b-b201-b019f5f6524c" />

