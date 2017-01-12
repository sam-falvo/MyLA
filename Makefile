SIM=iverilog -I rtl/verilog

.PHONY: test myla waves

test: myla

myla: bench/verilog/t_myla.v rtl/verilog/myla.v rtl/verilog/myla.vh
	$(SIM) -Irtl/verilog/ -Wall bench/verilog/t_myla.v rtl/verilog/myla.v
	vvp -n a.out

waves: myla
	gtkwave wtf.vcd
