TARGET	:= toplevel

TARGET_CORE	:= xst/$(TARGET).ngc

DESIGN_UNITS	:= $(shell cat toplevel.prj | awk '{print $$3}' | tr -d '"')

IP_CORES	:= ipcore_dir/fifo_rx.ngc ipcore_dir/fifo_tx.ngc
IP_CORES	+= ipcore_dir/mcs_0.ngc

TIMING_UCF	:= ../constraints/timing.ucf
PIN_MAP_UCF	:= ../constraints/pin_map_spartan.ucf

MEM_MAP  	:= ipcore_dir/mcs_0.bmm
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
$(PLACED_NETLIST): $(MAPPED_NETLIST) $(PHYS_CONSTRAINTS)
	mkdir -p par
	cd par ; par -w -ol high -mt 4 ../$< ../$@ ../$(PHYS_CONSTRAINTS)

# Map to device primitives
$(MAPPED_NETLIST): $(XILINX_DATABASE)
	mkdir -p map
	cd map ; map -w -logic_opt off -ol high -t 1 -xt 0 \
		-register_duplication off -r 4 -global_opt off -mt 2 -ir off \
		-pr off -lc off -power off -o ../$@ ../$< ../$(PHYS_CONSTRAINTS)

# Link and read constraints
$(XILINX_DATABASE): $(TARGET_CORE) $(IP_CORES) $(MEM_MAP)
	mkdir -p ngd
	cd ngd ; ngdbuild -dd ngo -sd ../ipcore_dir -nt timestamp \
		-uc ../$(TIMING_UCF) -uc ../$(PIN_MAP_UCF) \
		-p $(DEVICE) ../$< ../$@ -bm ../$(MEM_MAP)

# Synthesis
$(TARGET_CORE): $(TARGET).xst $(TARGET).prj $(DESIGN_UNITS)
	mkdir -p xst/xst/projnav.tmp
	cd xst ; xst -ifn ../$< -ofn $(TARGET).syr

clean:
	rm -rf xst
	rm -rf ngd
	rm -rf map
	rm -rf par
	rm -rf bitgen
	rm -f $(PHYS_CONSTRAINTS)
	rm -f $(TARGET).bit
	rm -f ipcore_dir/*_bd*
