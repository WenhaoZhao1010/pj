iverilog -o sim.out -f filelist
vvp sim.out
gtkwave core_tb.vcd debug.save.gtkw