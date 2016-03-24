-- Copyright (C) 2016 Kim Taylor
--
-- This file is part of hbc_mac.
--
-- hbc_mac is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- hbc_mac is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with hbc_mac.  If not, see <http://www.gnu.org/licenses/>.


library ieee;
use ieee.std_logic_1164.all;

library transceiver;
use transceiver.bits.all;

entity fifo_bus_arbitrator is
	port (	mod_bus_master	: in std_logic;
		
		io_addr    : in vec8_t;
        	io_d_in   : in vec32_t;
        	io_addr_strobe : in std_logic;
        	io_write_strobe : in std_logic;
        	io_io_ready : out std_logic;

		mod_addr    : in vec8_t;
        	mod_d_out   : in vec32_t;
        	mod_addr_strobe : in std_logic;
        	mod_write_strobe : in std_logic;
        	mod_io_ready : out std_logic;

		fifo_addr    : out vec8_t;
        	fifo_d_out   : out vec32_t;
        	fifo_addr_strobe : out std_logic;
        	fifo_write_strobe : out std_logic;
        	fifo_io_ready : in std_logic);
end fifo_bus_arbitrator;

architecture fifo_bus_arbitrator_arch of fifo_bus_arbitrator is

begin

	process(mod_bus_master, mod_addr, mod_d_out, mod_addr_strobe,
			mod_write_strobe, fifo_io_ready, io_addr,
			io_d_in, io_addr_strobe, io_write_strobe) begin
		if mod_bus_master = '1' then
			fifo_addr <= mod_addr;
			fifo_d_out <= mod_d_out;
			fifo_addr_strobe <= mod_addr_strobe;
			fifo_write_strobe <= mod_write_strobe;
			mod_io_ready <= fifo_io_ready;
			io_io_ready <= '0';
		else
			fifo_addr <= io_addr;
			fifo_d_out <= io_d_in;
			fifo_addr_strobe <= io_addr_strobe;
			fifo_write_strobe <= io_write_strobe;
			mod_io_ready <= '0';
			io_io_ready <= fifo_io_ready;
		end if;
	end process;
	
end fifo_bus_arbitrator_arch;

