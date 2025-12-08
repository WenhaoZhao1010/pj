iverilog -o sim.out \
  ./verilog/core_tb.v \
  ./verilog/core.v \
  ./verilog/corelet.v \
  ./verilog/fifo_depth8.v \
  ./verilog/fifo_depth64.v \
  ./verilog/fifo_mux_2_1.v \
  ./verilog/fifo_mux_8_1.v \
  ./verilog/fifo_mux_16_1.v \
  ./verilog/l0.v \
  ./verilog/mac_array.v \
  ./verilog/mac_row.v \
  ./verilog/mac_tile.v \
  ./verilog/mac.v \
  ./verilog/ofifo.v \
  ./verilog/sfu.v \
  ./verilog/sram_w2048.v
vvp sim.out
gtkwave core_tb.vcd debug.save.gtkw