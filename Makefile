# Copyright (C) 2016 Kim Taylor
#
# This file is part of hbc_mac.
#
# hbc_mac is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Foobar is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with hbc_mac.  If not, see <http://www.gnu.org/licenses/>.

VHHFLAGS ?= -DXILINX_SPARTAN=1 -DUSE_MEM=1 -DUSE_SPI=1 -DUSE_1BIT_LED \
	    -DUSE_PSOC -DUSE_FLASH

TRANSCEIVER_FILES += \
	processed/clk_div_pp.vhd					\
	processed/data_synchroniser_pp.vhd				\
	processed/debounce_pp.vhd					\
	processed/fifo_bus_arbitrator_pp.vhd				\
	processed/tx_fifo_interface_pp.vhd				\
	processed/hamming_lut_pp.vhd					\
	processed/lcd_interface_pp.vhd					\
	processed/mem_interface_pp.vhd					\
	processed/ddr_pp.vhd						\
	processed/modulator_pp.vhd					\
	processed/parallel_to_serial_pp.vhd				\
	processed/phase_align_pp.vhd					\
	processed/rx_fifo_interface_pp.vhd				\
	processed/scrambler_pp.vhd					\
	processed/serial_to_parallel_pp.vhd				\
	processed/toplevel_pp.vhd					\
	processed/usb_fifo_interface_pp.vhd				\
	processed/walsh_decoder_pp.vhd					\
	processed/walsh_enc_lut_pp.vhd					\
	processed/spi_slave_core_pp.vhd					\
	processed/spi_interface_pp.vhd					\
	processed/psoc_interface_pp.vhd					\
	processed/hbc_tx_pp.vhd						\
	processed/hbc_rx_pp.vhd						\
	processed/spi_master_core_pp.vhd				\
	processed/flash_interface_pp.vhd

all: $(TRANSCEIVER_FILES)

# Preprocessing
%_pp.vhd: ../%.vhd
	cpp $(VHHFLAGS) -DVHDL -D_QUOTE=\" -x assembler-with-cpp \
		-P -I ./ "$<" -o "$@"
%_core_pp.vhd: ../cores/%.vhd
	cpp $(VHHFLAGS) -DVHDL -D_QUOTE=\" -x assembler-with-cpp \
		-P -I ./ "$<" -o "$@"

# Other Targets
clean:
	rm processed/*_pp.vhd

.PHONY: clean cleanall all

.PRECIOUS: %_pp.vhd
