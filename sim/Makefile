# Copyright (C) 2016 Kim Taylor
#
# This file is part of hbc_mac.
#
# hbc_mac is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# hbc_mac is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with hbc_mac.  If not, see <http://www.gnu.org/licenses/>.

TESTBENCHES := clk_div_tb.vhd \
	       data_synchroniser_tb.vhd \
	       ddr_tb.vhd \
	       flash_interface_tb.vhd \
	       lib_numeric_tb.vhd \
	       loopback_tb.vhd \
	       parallel_to_serial_tb.vhd \
	       receiver_tb.vhd \
	       rx_fifo_interface_tb.vhd \
	       scrambler_tb.vhd \
	       spi_interface_tb.vhd \
	       transmitter_tb.vhd \
	       tx_fifo_interface_tb.vhd \
	       usb_fifo_interface_tb.vhd

IEEE_LIB := --ieee=synopsys
XILINX_FLAGS += $(IEEE_LIB) -fexplicit --warn-no-binding --warn-no-vital-generic

GHDL := ghdl
GHDL_MCODE := ghdl_mcode

GHDL_DIR := $(shell dirname `ghdl --dispconfig | grep "library directory" | \
		sed 's/.*: //'`)
GHDL_MCODE_DIR := $(shell ghdl_mcode --dispconfig | grep "library directory" | \
		sed 's/.*: //')

XILINX_LIB_DIR := /opt/Xilinx/14.7/ISE_DS/ISE/vhdl/src

XILINX_IEEE_FILES := numeric_std.vhd \
		     std_logic_1164.vhd std_logic_unsigned.vhd

#ieee-obj93.cf
XILINX_OBJS += \
	xilinxcorelib-obj93.cf \
	unisim-obj93.cf \
	simprim-obj93.cf

LOCAL_OBJS += \
	transceiver-obj93.cf \
	work-obj93.cf

all:
	@echo -e $(subst $(space),$(newline),$(TESTBENCHES:.vhd=))

ghdl_extract = $(shell grep $(1) $(2) | sed 's/.*$(1)://' | tr -d '\n')

-include $(addprefix deps/,$(TESTBENCHES:.vhd=.d))

%.vhd: %.vhd.in
	make -C $(dir $@) $(notdir $@)
.PRECIOUS: %.vhd

deps/%.d: ../testbench/%.vhd
	@mkdir -p deps
	$(eval testbench = $(notdir $(basename $@)))
	$(eval flags = $(call ghdl_extract, ghdl_flags, $<))
	$(eval deps = $(call ghdl_extract, ghdl_deps, $<))
	@echo $(testbench): $(addprefix ../, $(deps)) > $@
	@echo $(testbench)_deps  += $(addprefix ../, $(deps)) >> $@
	@echo $(testbench)_flags += $(flags) >> $@

%_tb: $(XILINX_OBJS) $(LOCAL_OBJS) 
	$(eval dep_list = $@_deps)
	$(GHDL) -i ../testbench/$@.vhd $($@_deps)
	$(GHDL) -m $(XILINX_FLAGS) $@
	./$@ $($@_flags)

%_synth_tb: $(XILINX_OBJS) $(LOCAL_OBJS)
	$(eval dep_list = $@_deps)
	$(GHDL_MCODE) -i $(XILINX_FLAGS) ../testbench/$@.vhd $($@_deps)
	$(GHDL_MCODE) -c $(XILINX_FLAGS) -r $@ $($@_flags)

# Xilinx libraries
xilinxcorelib-obj93.cf:
	$(GHDL) -i $(IEEE_LIB) --work=XilinxCoreLib \
		$(XILINX_LIB_DIR)/XilinxCoreLib/*.vhd
unisim-obj93.cf:
	$(GHDL) -i $(IEEE_LIB) --work=unisim \
		$(XILINX_LIB_DIR)/unisims/*.vhd \
		$(XILINX_LIB_DIR)/unisims/primitive/*.vhd
simprim-obj93.cf:
	$(GHDL) -i $(IEEE_LIB) --work=simprim \
		$(XILINX_LIB_DIR)/simprims/*.vhd \
		$(XILINX_LIB_DIR)/simprims/primitive/other/*.vhd
ieee-obj93.cf:
	$(GHDL) -i $(IEEE_LIB) --work=ieee  \
		$(patsubst %, $(XILINX_LIB_DIR)/ieee/%, $(XILINX_IEEE_FILES)) \
		$(GHDL_DIR)/src/vital2000/*.vhdl

transceiver-obj93.cf:
	$(GHDL) -i $(IEEE_LIB) --work=transceiver ../lib/*.vhd

work-obj93.cf:

# Other Targets
interpret_output:

clean:
	$(GHDL) --remove
cleanall:
	$(GHDL) --remove
	rm -rf deps
	rm -f *.ghw
	rm -f *.cf
	rm -f *.o
	rm -f *.time
	rm -f *.value
	rm -f output_data
	rm -f interpret_output

.PHONY: clean cleanall all

newline := \\n
empty :=
space := $(empty) $(empty)

#ghdl -e -Wc,-fdump-tree-gimple
