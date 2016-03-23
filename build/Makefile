TARGET	:= hbc_mac

TARGET_CORE	:= xst/$(TARGET).ngc

DESIGN_UNITS	:= $(shell cat $(TARGET).prj | awk '{print $$3}' | tr -d '"')

IP_CORES	:= cores/fifo_rx.ngc
IP_CORES	+= cores/fifo_tx.ngc
IP_CORES	+= cores/mcs_0.ngc
IP_CORES	+= cores/pll_mem.vhd
IP_CORES	+= cores/pll_serial.vhd

TIMING_UCF	:= ../constraints/timing.ucf
PIN_MAP_UCF	:= ../constraints/pin_map_spartan.ucf

MEM_MAP  	:= cores/mcs_0/mcs_0.bmm
DEVICE		:= xc6slx9-tqg144-2

MAPPED_NETLIST	:= map/$(TARGET).ncd
PLACED_NETLIST	:= par/$(TARGET).ncd
XILINX_DATABASE := ngd/$(TARGET).ngd

PHYS_CONSTRAINTS := $(TARGET).pcf

# Generate bitstream
$(TARGET).bit: $(TARGET).ut $(PLACED_NETLIST)
	mkdir -p bitgen
	cd bitgen ; bitgen -f $(patsubst %, ../%, $^) $@
	ln -fs bitgen/$(TARGET).bit

# Place and route
$(PLACED_NETLIST): $(MAPPED_NETLIST)
	mkdir -p par
	cd par ; par -w -ol high -mt 4 ../$< ../$@ ../$(PHYS_CONSTRAINTS)

# Map to device primitives
$(MAPPED_NETLIST): $(XILINX_DATABASE)
	mkdir -p map
	cd map ; map -w -logic_opt off -ol high -t 1 -xt 0 \
		-register_duplication off -r 4 -global_opt off -mt 2 -ir off \
		-pr off -lc off -power off -o ../$@ ../$< ../$(PHYS_CONSTRAINTS)

# Link and read constraints
$(XILINX_DATABASE): $(TARGET_CORE) $(IP_CORES)
	mkdir -p ngd
	cd ngd ; ngdbuild -dd ngo -sd ../cores -nt timestamp \
		-uc ../$(TIMING_UCF) -uc ../$(PIN_MAP_UCF) \
		-p $(DEVICE) ../$< ../$@ -bm ../$(MEM_MAP)

# Synthesis
$(TARGET_CORE): $(TARGET).xst $(TARGET).prj $(DESIGN_UNITS)
	mkdir -p xst/xst/projnav.tmp
	cd xst ; xst -ifn ../$< -ofn $(TARGET).syr

# Core generation
cores/%.ngc cores/%.vhd: ../cores/%.xco
	$(eval CORE_DIR = $(notdir $(basename $@)))
	mkdir -p cores/$(CORE_DIR)
	ln -fs ../../../cores/coregen.cgp cores/$(CORE_DIR)
	cd cores/$(CORE_DIR) ; coregen -b ../../$< -p .
	ln -fs $(CORE_DIR)/$(notdir $@) $@

cleanall: clean clean_cores

clean:
	rm -rf xst
	rm -rf ngd
	rm -rf map
	rm -rf par
	rm -rf bitgen
	rm -f $(PHYS_CONSTRAINTS)
	rm -f $(TARGET).bit

clean_cores:
	rm -f $(IP_CORES)
	rm -rf $(basename $(IP_CORES))
