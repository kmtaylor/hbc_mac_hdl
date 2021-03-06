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

include preprocessor.mak

VHHFLAGS ?= -DXILINX_SPARTAN=1 -DUSE_MEM=1 -DUSE_SPI=1 -DUSE_1BIT_LED \
	    -DUSE_PSOC -DUSE_FLASH
export

all: $(VHDL_OUTPUT_FILES) cores testbench

cores:
	make -C cores

testbench:
	make -C testbench

clean:
	rm -f $(VHDL_OUTPUT_FILES)
	make -C cores clean
	make -C testbench clean

cleanall: clean
	make -C sim cleanall
	make -C sim/analogue clean
	make -C build cleanall

.PHONY: clean cores testbench
