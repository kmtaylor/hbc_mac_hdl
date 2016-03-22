TARGET	:= toplevel

TARGET_CORE	:= $(TARGET).ngc

DESIGN_UNITS	:= $(shell cat toplevel.prj | awk '{print $$3}' | tr -d '"')

IP_CORES	:= ipcore_dir/fifo_rx.ngc ipcore_dir/fifo_tx.ngc
IP_CORES	+= ipcore_dir/mcs_0.ngc

MEM_MAP  	:= ipcore_dir/mcs_0.bmm
DEVICE		:= xc6slx9-tqg144-2

MAPPED_NETLIST	:= $(TARGET)_map.ncd
PLACED_NETLIST	:= $(TARGET)_par.ncd

PHYS_CONSTRAINTS := $(TARGET).pcf

# Generate bitstream
$(TARGET).bit: $(TARGET).ut $(PLACED_NETLIST)
	bitgen -f $^

# Place and route
$(PLACED_NETLIST): $(MAPPED_NETLIST) $(PHYS_CONSTRAINTS)
	par -w -ol high -mt 4 $< $@ $(PHYS_CONSTRAINTS)

# Map to device primitives
$(MAPPED_NETLIST): $(TARGET).ngd
	map -p $(DEVICE) -w -logic_opt off -ol high -t 1 -xt 0 \
		-register_duplication off -r 4 -global_opt off -mt 2 -ir off \
		-pr off -lc off -power off -o $@ $< $(PHYS_CONSTRAINTS)

# Link and read constraints
$(TARGET).ngd: $(TARGET_CORE) $(IP_CORES) $(MEM_MAP)
	ngdbuild -dd ngo -sd ipcore_dir -nt timestamp \
		-uc ../constraints/timing.ucf \
		-uc ../constraints/pin_map_spartan.ucf \
		-p $(DEVICE) $< $@ -bm $(MEM_MAP)

# Synthesis
$(TARGET_CORE): $(TARGET).xst $(TARGET).prj $(DESIGN_UNITS)
	mkdir -p xst/projnav.tmp
	xst -ifn $< -ofn $(TARGET).syr

clean:
	rm -f webtalk.log
	rm -rf xlnx_auto_0_xdb
	rm -rf _xmsgs
	rm -rf xst
	rm -rf ngo
	rm -f *.xml
	rm -f par_usage_statistics.html
	rm -f usage_statistics_webtalk.html
	rm -f *.drc
	rm -f *_map*
	rm -f *_par*
	rm -f *.bld
	rm -f *.lso
	rm -f *.n*
	rm -f *.xrpt
	rm -f *.pcf
	rm -f *.syr
	rm -f ipcore_dir/*_bd*
