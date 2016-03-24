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

-- ghdl_flags: --stop-time=1000ns
-- ghdl_flags: --wave=scrambler_tb.ghw
-- ghdl_deps: scrambler.vhd

library ieee;
use ieee.std_logic_1164.all;
 
entity scrambler_tb is
end entity scrambler_tb;
 
architecture testbench of scrambler_tb is

    constant clk_period : time := 10 ns;
    
    signal clk, reset : std_logic;
    signal reseed, seed_val, seed_clk : std_logic;

    signal io_addr : std_logic_vector (7 downto 0);
    signal io_d_out : std_logic_vector (31 downto 0);
    signal io_addr_strobe, io_read_strobe : std_logic;

begin 

    uut: entity work.scrambler
	port map (
	    cpu_clk => clk,
	    reset => reset,
	    reseed => reseed,
	    seed_val => seed_val,
	    seed_clk => seed_clk,
	    io_addr => io_addr,
	    io_d_out => io_d_out,
	    io_addr_strobe => io_addr_strobe,
	    io_read_strobe => io_read_strobe);
		  
   -- Clock process definitions
    clk_process: process begin
	clk <= '0';
	wait for clk_period/2;
	clk <= '1';
	wait for clk_period/2;
    end process;

    -- Stimulus process
    stim_proc: process begin		
	-- Init bus
	io_addr_strobe <= '0';
	io_read_strobe <= '0';
	-- Init control
	seed_val <= '0';
	reseed <= '0';
	seed_clk <= '0';

	-- Reset period
	reset <= '1';
	wait for clk_period * 2;	
	reset <= '0';
	wait for clk_period * 3.5;

	-- Reseed scrambler
	reseed <= '1';
	seed_val <= '0';
	wait for clk_period;
	seed_clk <= '1';
	wait for clk_period;
	seed_clk <= '0';
	reseed <= '0';
	seed_val <= '0';

	-- Do CPU read bad address
	wait for clk_period * 5;
	io_addr_strobe <= '1';
	io_read_strobe <= '1';
	io_addr <= X"00";
	wait for clk_period;
	io_addr_strobe <= '0';
	io_read_strobe <= '0';
	
	-- Do CPU read
	wait for clk_period * 5;
	io_addr_strobe <= '1';
	io_read_strobe <= '1';
	io_addr <= X"14";
	wait for clk_period;
	io_addr_strobe <= '0';
	io_read_strobe <= '0';
	
	-- Do CPU read
	wait for clk_period * 5;
	io_addr_strobe <= '1';
	io_read_strobe <= '1';
	io_addr <= X"14";
	wait for clk_period;
	io_addr_strobe <= '0';
	io_read_strobe <= '0';
	
	-- Do CPU read
	wait for clk_period * 5;
	io_addr_strobe <= '1';
	io_read_strobe <= '1';
	io_addr <= X"14";
	wait for clk_period;
	io_addr_strobe <= '0';
	io_read_strobe <= '0';
	
	wait;
   end process;

end architecture testbench;
