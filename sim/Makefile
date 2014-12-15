XILINX_FLAGS += --ieee=none -fexplicit --warn-no-binding
GHDL_DIR := $(shell dirname `ghdl --dispconfig | grep "default prefix" | \
		sed 's/.*: //'`)

XILINX_OBJS += \
	ieee-obj93.cf \
	xilinxcorelib-obj93.cf \
	unisim-obj93.cf \
	simprim-obj93.cf

LOCAL_OBJS += \
	transceiver-obj93.cf

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
	parallel_to_serial.vhd \
	fifo_interface.vhd \
	fifo_tx_sim.vhd \
	data_synchroniser.vhd \
	serial_to_parallel.vhd \
	rx_fifo_interface.vhd \
	modulator_path_tb.vhd
MODULATOR_SIM_FLAGS += --stop-time=1000us --ieee-asserts=disable-at-0

MODULATOR_SYNTH_TB_FILES += \
	modulator.vhd \
	parallel_to_serial.vhd \
	fifo_interface.vhd \
	fifo_tx_sim.vhd \
	data_synchroniser.vhd \
	serial_to_parallel_timesim.vhd \
	rx_fifo_interface.vhd \
	modulator_path_tb.vhd
MODULATOR_SYNTH_SIM_FLAGS += --stop-time=1000us --ieee-asserts=disable-at-0

USB_TB_FILES += \
	usb_fifo_interface.vhd \
	usb_fifo_interface_tb.vhd
USB_SIM_FLAGS += --stop-time=1000ns

FIFO_TB_FILES += \
	fifo_interface.vhd \
	fifo_interface_tb.vhd \
	fifo_tx_sim.vhd
FIFO_SIM_FLAGS += --stop-time=1000ns

RX_FIFO_TB_FILES += \
	rx_fifo_interface.vhd \
	rx_fifo_interface_tb.vhd \
	fifo_tx_sim.vhd
RX_FIFO_SIM_FLAGS += --stop-time=1000ns

CLK_DIV_TB_FILES += \
	clk_div.vhd \
	clk_div_tb.vhd
CLK_DIV_SIM_FLAGS += --stop-time=100ns

P2S_TB_FILES += \
	parallel_to_serial.vhd \
	parallel_to_serial_tb.vhd \
	fifo_tx_sim.vhd
P2S_SIM_FLAGS += --stop-time=5000ns

NUMERIC_TB_FILES += \
	lib_numeric_tb.vhd
NUMERIC_SIM_FLAGS += --stop-time=10ns

all:
	@make -qp | awk -F ':' '/^[a-zA-Z0-9][^$$#\/\t=]*:([^=]|$$)/ \
	{split($$1,A,/ /); for(i in A) print A[i]}' | sed '/\.o/d' | grep tb

# Test Benches (Elaboration)
c_to_vhd_tb: $(XILINX_OBJS) $(LOCAL_OBJS) $(C_TO_VHD_FILES:.vhd=_pp.o)
	ghdl -m $(XILINX_FLAGS) "$@"
	./"$@" $(C_TO_VHD_SIM_FLAGS) --wave="$@".ghw

scrambler_tb: $(XILINX_OBJS) $(LOCAL_OBJS) $(SCRAMBLER_TB_FILES:.vhd=_pp.o)
	ghdl -m $(XILINX_FLAGS) "$@"
	./"$@" $(SCRAMBLER_SIM_FLAGS) --wave="$@".ghw

usb_fifo_interface_tb: $(XILINX_OBJS) $(LOCAL_OBJS) $(USB_TB_FILES:.vhd=_pp.o)
	ghdl -m $(XILINX_FLAGS) "$@"
	./"$@" $(USB_SIM_FLAGS) --wave="$@".ghw

fifo_interface_tb: $(XILINX_OBJS) $(LOCAL_OBJS) $(FIFO_TB_FILES:.vhd=_pp.o)
	ghdl -m $(XILINX_FLAGS) "$@"
	./"$@" $(FIFO_SIM_FLAGS) --wave="$@".ghw

rx_fifo_interface_tb: $(XILINX_OBJS) $(LOCAL_OBJS) \
			$(RX_FIFO_TB_FILES:.vhd=_pp.o)
	ghdl -m $(XILINX_FLAGS) "$@"
	./"$@" $(FIFO_SIM_FLAGS) --wave="$@".ghw

clk_div_tb: $(XILINX_OBJS) $(LOCAL_OBJS) $(CLK_DIV_TB_FILES:.vhd=_pp.o)
	ghdl -m $(XILINX_FLAGS) "$@"
	./"$@" $(CLK_DIV_SIM_FLAGS) --wave="$@".ghw

modulator_tb: $(XILINX_OBJS) $(LOCAL_OBJS) $(MODULATOR_TB_FILES:.vhd=_pp.o)
	ghdl -m $(XILINX_FLAGS) "$@"
	./"$@" $(MODULATOR_SIM_FLAGS) --wave="$@".ghw

modulator_synth_tb: $(XILINX_OBJS) $(LOCAL_OBJS) \
		$(MODULATOR_SYNTH_TB_FILES:.vhd=_pp.o)
	ghdl -m $(XILINX_FLAGS) modulator_tb
	./modulator_tb $(MODULATOR_SYNTH_SIM_FLAGS) --wave="$@".ghw

parallel_to_serial_tb: $(XILINX_OBJS) $(LOCAL_OBJS) $(P2S_TB_FILES:.vhd=_pp.o)
	ghdl -m $(XILINX_FLAGS) "$@"
	./"$@" $(P2S_SIM_FLAGS) --wave="$@".ghw

numeric_tb: $(LOCAL_OBJS) $(NUMERIC_TB_FILES:.vhd=_pp.o)
	ghdl -m $(XILINX_FLAGS) "$@"
	./"$@" $(NUMERIC_SIM_FLAGS) --wave="$@".ghw

# Xilinx libraries
xilinxcorelib-obj93.cf:
	ghdl -i --ieee=none --work=XilinxCoreLib \
		../Xilinx/sim/XilinxCoreLib/*.vhd
unisim-obj93.cf:
	ghdl -i --ieee=none --work=unisim ../Xilinx/sim/unisims/*.vhd \
		../Xilinx/sim/unisims/primitive/*.vhd
simprim-obj93.cf:
	ghdl -i --ieee=none --work=simprim ../Xilinx/sim/simprims/*.vhd \
		../Xilinx/sim/simprims/primitive/*.vhd
ieee-obj93.cf:
	ghdl -i --ieee=none --work=ieee ../Xilinx/sim/ieee/*.vhd \
		$(GHDL_DIR)/src/vital95/*.vhdl

transceiver-obj93.cf:
	ghdl -i --ieee=none --work=transceiver ../lib/*.vhd

# Preprocessing
%_pp.vhd: ../%.vhd
	cpp -DVHDL -D_QUOTE=\" -x assembler-with-cpp -P -I ../ "$<" -o "$@"

# Analysis
%_pp.o: ../processed/%_pp.vhd
	ghdl -i $(XILINX_FLAGS) "$<"
%_tb_pp.o: ../testbench/processed/%_tb_pp.vhd
	ghdl -i $(XILINX_FLAGS) "$<"
%_sim_pp.o: ../Xilinx/sim/processed/%_sim_pp.vhd
	ghdl -i $(XILINX_FLAGS) "$<"
%_synthesis_pp.o: netgen/synthesis/processed/%_synthesis_pp.vhd
	ghdl -i $(XILINX_FLAGS) "$<"
%_timesim_pp.o: netgen/par/processed/%_timesim_pp.vhd
	ghdl -i $(XILINX_FLAGS) "$<"

# Other Targets
clean:
	ghdl --remove
cleanall:
	ghdl --remove
	rm -f *.ghw
	rm -f *.cf
	rm -f *.o

.PHONY: clean cleanall all

.PRECIOUS: %_pp.vhd

#ghdl -e -Wc,-fdump-tree-gimple
