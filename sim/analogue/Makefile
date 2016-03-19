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

PROJECT := analogue

GHDL_TX_DATA := ../tx_data.time ../tx_data.value
GHDL_RX_DATA := ../rx_data.time ../rx_data.value

GHDL_TX_SOURCE := "v_tx"
GHDL_RX_NODE := "v(rx_data)"

OCTAVE_FILTER_IN := v_filter_in.octave
OCTAVE_FILTER_OUT := v_filter_out.octave

L_PAREN := (
R_PAREN := )

all: $(PROJECT).sim $(PROJECT).raw

# Analysis
%.raw: %.sim libngspice_ext.so.0 $(GHDL_TX_DATA)
	LD_LIBRARY_PATH=./ ngspice -b $< -r $@

%.net: %.sch %.sed
	gnetlist -g spice-sdb -o $(@:.net=.tmp) $<
	sed -f $(@:.net=.sed) $(@:.net=.tmp) > $@
	rm $(@:.net=.tmp)

%.sim: %.net %.cmd
	cat $^ > $@

libngspice_ext.so.0: libngspice_ext.c
	gcc -Wall -shared -fPIC -D_GNU_SOURCE \
		-DFILENAME=$(word 1,$(notdir $(basename $(GHDL_TX_DATA)))) \
		-DTX_SOURCE=$(GHDL_TX_SOURCE) \
		$< -o $@

spice_to_ghdl: spice_to_ghdl.c
	gcc -Wall -DFILENAME=$(PROJECT).raw $< -o $@ \
		-I/usr/include/gwave2 `pkg-config glib-2.0 --cflags` \
		-lspicefile `pkg-config glib-2.0 --libs` -D_GNU_SOURCE

spice_to_octave: spice_to_octave.c
	gcc -Wall -DFILENAME=$(PROJECT).raw $< -o $@ \
		-I/usr/include/gwave2 `pkg-config glib-2.0 --cflags` \
		-lspicefile `pkg-config glib-2.0 --libs` -D_GNU_SOURCE

%.octave: spice_to_octave $(PROJECT).raw
	$(eval base_name = 	$(notdir $(basename $@)))
	$(eval net_name = 	$(subst i_,i$(L_PAREN), \
				$(subst v_,v$(L_PAREN),$(base_name)))$(R_PAREN))
	./spice_to_octave $(PROJECT).raw "$(net_name)" $@ $(base_name)

$(GHDL_RX_DATA): spice_to_ghdl $(PROJECT).raw
	./spice_to_ghdl $(GHDL_RX_NODE) $(notdir $(basename $@))

schematic:
	gschem $(PROJECT).sch &>/dev/null &

view:
	gwave -s $(PROJECT).gwave &>/dev/null &

filter: $(OCTAVE_FILTER_IN) $(OCTAVE_FILTER_OUT)

ghdl_data: $(GHDL_RX_DATA) 

# Other Targets
clean:
	rm -f *.sim
	rm -f *.raw
	rm -f *.net
	rm -f *.octave
	rm -f *~
	rm -f spice_to_ghdl
	rm -f spice_to_octave
	rm -f libngspice_ext.so.0

.PHONY: clean all
FORCE:
