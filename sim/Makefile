XILINX_FLAGS += --ieee=none -fexplicit -g

XILINX_OBJS += \
	ieee-obj93.cf \
	xilinxcorelib-obj93.cf

SCRAMBLER_TB_FILES += \
	scrambler.vhd \
	scrambler_tb.vhd
SCRAMBLER_SIM_FLAGS += --stop-time=1000ns

USB_TB_FILES += \
	usb_fifo_interface.vhd \
	usb_fifo_interface_tb.vhd
USB_SIM_FLAGS += --stop-time=1000ns

FIFO_TB_FILES += \
	fifo_interface.vhd \
	fifo_interface_tb.vhd \
	fifo_tx_sim.vhd
FIFO_SIM_FLAGS += --stop-time=1000ns

all: usb_fifo_interface_tb scrambler_tb fifo_interface_tb

# Test Benches (Elaboration)
scrambler_tb: $(XILINX_OBJS) $(SCRAMBLER_TB_FILES:.vhd=.o)
	ghdl -m $(XILINX_FLAGS) "$@"
	./"$@" $(SCRAMBLER_SIM_FLAGS) --wave="$@".ghw

usb_fifo_interface_tb: $(XILINX_OBJS) $(USB_TB_FILES:.vhd=.o)
	ghdl -m $(XILINX_FLAGS) "$@"
	./"$@" $(USB_SIM_FLAGS) --wave="$@".ghw

fifo_interface_tb: $(XILINX_OBJS) $(FIFO_TB_FILES:.vhd=.o)
	ghdl -m $(XILINX_FLAGS) "$@"
	./"$@" $(FIFO_SIM_FLAGS) --wave="$@".ghw

# Xilinx libraries
xilinxcorelib-obj93.cf:
	ghdl -i --ieee=none --work=XilinxCoreLib ../Xilinx/sim/XilinxCoreLib/*.vhd
ieee-obj93.cf:
	ghdl -i --ieee=none --work=ieee ../Xilinx/sim/ieee/*.vhd

# Analysis
%.o: ../%.vhd
	ghdl -a $(XILINX_FLAGS) "$<"
%_tb.o: ../testbench/%_tb.vhd
	ghdl -a $(XILINX_FLAGS) "$<"
%_sim.o: ../Xilinx/sim/%_sim.vhd
	ghdl -a $(XILINX_FLAGS) "$<"

# Other Targets
clean:
	ghdl --remove
cleanall:
	ghdl --remove
	rm -f *.ghw
	rm -f *.cf

.PHONY: clean cleanall all
