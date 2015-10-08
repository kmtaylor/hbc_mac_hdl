VHHFLAGS ?= -DFPGA_TYPE=SPARTAN

TRANSCEIVER_FILES += \
	processed/clk_div_pp.vhd					\
	processed/c_to_vhd_pp.vhd					\
	processed/data_synchroniser_pp.vhd				\
	processed/debounce_pp.vhd					\
	processed/fifo_bus_arbitrator_pp.vhd				\
	processed/tx_fifo_interface_pp.vhd				\
	processed/hamming_lut_pp.vhd					\
	processed/io_bus_arbitrator_pp.vhd				\
	processed/lcd_interface_pp.vhd					\
	processed/mem_interface_pp.vhd					\
	processed/modulator_pp.vhd					\
	processed/parallel_to_serial_pp.vhd				\
	processed/phase_align_pp.vhd					\
	processed/rx_fifo_interface_pp.vhd				\
	processed/scrambler_pp.vhd					\
	processed/serial_to_parallel_pp.vhd				\
	processed/toplevel_pp.vhd					\
	processed/usb_fifo_interface_pp.vhd				\
	processed/walsh_decoder_pp.vhd					\
	processed/walsh_enc_lut_pp.vhd

all: $(TRANSCEIVER_FILES)

# Preprocessing
%_pp.vhd: ../%.vhd
	cpp $(VHHFLAGS) -DVHDL -D_QUOTE=\" -x assembler-with-cpp \
		-P -I ./ "$<" -o "$@"

# Other Targets
clean:
	rm processed/*_pp.vhd

.PHONY: clean cleanall all

.PRECIOUS: %_pp.vhd

#ghdl -e -Wc,-fdump-tree-gimple
