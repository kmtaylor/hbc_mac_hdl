XILINX_FLAGS += --ieee=none -fexplicit -g

XILINX_OBJS += \
	ieee-obj93.cf \
	xilinxcorelib-obj93.cf

SCRAMBLER_TB_FILES += \
	scrambler.vhd \
	scrambler_tb.vhd
SCRAMBLER_SIM_FLAGS += --stop-time=1000ns

C_TO_VHD_FILES += \
	c_to_vhd.vhd \
	fifo_interface.vhd \
	c_to_vhd_tb.vhd
C_TO_VHD_SIM_FLAGS += --stop-time=3000ns

MODULATOR_TB_FILES += \
	modulator.vhd \
	fifo_interface.vhd \
	modulator_tb.vhd
MODULATOR_SIM_FLAGS += --stop-time=3000ns

USB_TB_FILES += \
	usb_fifo_interface.vhd \
	usb_fifo_interface_tb.vhd
USB_SIM_FLAGS += --stop-time=1000ns

FIFO_TB_FILES += \
	fifo_interface.vhd \
	fifo_interface_tb.vhd \
	fifo_tx_sim.vhd
FIFO_SIM_FLAGS += --stop-time=1000ns

CLK_DIV_TB_FILES += \
	clk_div.vhd \
	clk_div_tb.vhd
CLK_DIV_SIM_FLAGS += --stop-time=100ns

all: usb_fifo_interface_tb scrambler_tb modulator_tb

# Test Benches (Elaboration)
c_to_vhd_tb: $(XILINX_OBJS) $(C_TO_VHD_FILES:.vhd=.o)
	ghdl -m $(XILINX_FLAGS) "$@"
	./"$@" $(C_TO_VHD_SIM_FLAGS) --wave="$@".ghw

scrambler_tb: $(XILINX_OBJS) $(SCRAMBLER_TB_FILES:.vhd=.o)
	ghdl -m $(XILINX_FLAGS) "$@"
	./"$@" $(SCRAMBLER_SIM_FLAGS) --wave="$@".ghw

usb_fifo_interface_tb: $(XILINX_OBJS) $(USB_TB_FILES:.vhd=.o)
	ghdl -m $(XILINX_FLAGS) "$@"
	./"$@" $(USB_SIM_FLAGS) --wave="$@".ghw

fifo_interface_tb: $(XILINX_OBJS) $(FIFO_TB_FILES:.vhd=.o)
	ghdl -m $(XILINX_FLAGS) "$@"
#	./"$@" $(FIFO_SIM_FLAGS) --wave="$@".ghw

clk_div_tb: $(XILINX_OBJS) $(CLK_DIV_TB_FILES:.vhd=.o)
	ghdl -m $(XILINX_FLAGS) "$@"
	./"$@" $(CLK_DIV_SIM_FLAGS) --wave="$@".ghw

modulator_tb: $(XILINX_OBJS) $(MODULATOR_TB_FILES:.vhd=.o)
	ghdl -m $(XILINX_FLAGS) "$@"
	./"$@" $(MODULATOR_SIM_FLAGS) --wave="$@".ghw

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
	rm -f *.o

.PHONY: clean cleanall all
