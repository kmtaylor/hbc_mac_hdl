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

-- ghdl_flags: --stop-time=1000ns --wave=tx_fifo_interface_tb.ghw
-- ghdl_deps: tx_fifo_interface.vhd
-- ghdl_deps: build/cores/fifo_tx/fifo_tx.vhd

library ieee;
use ieee.std_logic_1164.all;

entity tx_fifo_interface_tb is
end tx_fifo_interface_tb;
 
architecture testbench of tx_fifo_interface_tb is 
 
    component fifo_tx port (
	rst : IN STD_LOGIC;
	wr_clk : IN STD_LOGIC;
	rd_clk : IN STD_LOGIC;
	din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
	wr_en : IN STD_LOGIC;
	rd_en : IN STD_LOGIC;
	dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
	full : OUT STD_LOGIC;
	prog_full : OUT STD_LOGIC;
	overflow : OUT STD_LOGIC;
	empty : OUT STD_LOGIC;
	underflow : OUT STD_LOGIC);
    end component fifo_tx;

   --Inputs
    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
    signal io_addr : std_logic_vector(7 downto 0) := (others => '0');
    signal io_d_in : std_logic_vector(31 downto 0) := (others => '0');
    signal io_addr_strobe : std_logic := '0';
    signal io_read_strobe : std_logic := '0';
    signal io_write_strobe : std_logic := '0';
    signal fifo_d_in : std_logic_vector(31 downto 0) := (others => '0');
    signal trigger : std_logic := '0';

     --Outputs
    signal io_d_out : std_logic_vector(31 downto 0);
    signal io_ready : std_logic;
    signal fifo_d_out : std_logic_vector(31 downto 0);
    signal fifo_wren : std_logic;
    signal fifo_rden : std_logic;

   -- Clock period definitions
    constant clk_period : time := 10 ns;
    
    signal full, prog_full : std_logic;
    signal overflow, underflow : std_logic;
    signal empty : std_logic;
 
begin
 
    -- Instantiate the Unit Under Test (UUT)
    uut: entity work.tx_fifo_interface port map (
	clk => clk,
	reset => reset,
	trigger => trigger,
	io_addr => io_addr,
	io_d_in => io_d_in,
	io_d_out => io_d_out,
	io_addr_strobe => io_addr_strobe,
	io_read_strobe => io_read_strobe,
	io_write_strobe => io_write_strobe,
	io_ready => io_ready,
	fifo_d_out => fifo_d_out,
	fifo_wren => fifo_wren,
	fifo_d_in => fifo_d_in,
	fifo_rden => fifo_rden);

    tx_fifo : component fifo_tx port map (
	rst => reset,
	wr_clk => clk,
	rd_clk => clk,
	din => fifo_d_out,
	wr_en => fifo_wren,
	rd_en => fifo_rden,
	dout => fifo_d_in,
	full => full,
	prog_full => prog_full,
	overflow => overflow,
	empty => empty,
	underflow => underflow);
	    
	  
    -- Clock process definitions
    clk_process : process begin
	clk <= '0';
	wait for clk_period/2;
	clk <= '1';
	wait for clk_period/2;
    end process;

    -- Stimulus process
    stim_proc: process begin	
	-- hold reset state for 20 ns.
	reset <= '1';
	wait for 20 ns;
	reset <= '0';

	wait for clk_period * 20.5;

	-- Set bits at address 0x01
	io_write_strobe <= '1';
	io_addr_strobe <= '1';
	io_d_in <= X"00000018";
	io_addr <= X"01";
	wait for clk_period;
	io_write_strobe <= '0';
	io_addr_strobe <= '0';
	
	wait for clk_period * 6;

	-- Write at address 0x00 (1)
	io_write_strobe <= '1';
	io_addr_strobe <= '1';
	io_d_in <= X"12345678";
	io_addr <= X"00";
	wait for clk_period;
	io_write_strobe <= '0';
	io_addr_strobe <= '0';
	
	wait for clk_period * 6;
	
	-- Trigger early
	trigger <= '1';
	wait for clk_period;
	trigger <= '0';
	wait for clk_period * 6;

	-- Read at address 0x00---------------------------------------------
	io_read_strobe <= '1';
	io_addr_strobe <= '1';
	wait for clk_period;
	io_read_strobe <= '0';
	io_addr_strobe <= '0';
      
	wait for clk_period * 6;
	
	-- Write at address 0x00 (1)
	io_write_strobe <= '1';
	io_addr_strobe <= '1';
	io_d_in <= X"12345678";
	io_addr <= X"00";
	wait for clk_period;
	io_write_strobe <= '0';
	io_addr_strobe <= '0';
	
	wait for clk_period * 6;
	
	-- Trigger early
	trigger <= '1';
	wait for clk_period;
	trigger <= '0';
	wait for clk_period * 6;

	-- Read at address 0x00---------------------------------------------
	io_read_strobe <= '1';
	io_addr_strobe <= '1';
	wait for clk_period;
	io_read_strobe <= '0';
	io_addr_strobe <= '0';
      
	wait for clk_period * 6;
	
--	-- Write at address 0x00 (2)
--	io_write_strobe <= '1';
--	io_addr_strobe <= '1';
--	io_d_in <= X"12345678";
--	io_addr <= X"00";
--	wait for clk_period;
--	io_write_strobe <= '0';
--	io_addr_strobe <= '0';
--	
--	wait for clk_period * 6;
--	
--	-- Write at address 0x00 (3)
--	io_write_strobe <= '1';
--	io_addr_strobe <= '1';
--	io_d_in <= X"12345678";
--	io_addr <= X"00";
--	wait for clk_period;
--	io_write_strobe <= '0';
--	io_addr_strobe <= '0';
--	
--	wait for clk_period * 6;
--	
--	-- Write at address 0x00 (4)
--	io_write_strobe <= '1';
--	io_addr_strobe <= '1';
--	io_d_in <= X"12345678";
--	io_addr <= X"00";
--	wait for clk_period;
--	io_write_strobe <= '0';
--	io_addr_strobe <= '0';
--	
--	wait for clk_period * 6;
--	
--	-- Read at address 0x00---------------------------------------------
--	io_read_strobe <= '1';
--	io_addr_strobe <= '1';
--	wait for clk_period;
--	io_read_strobe <= '0';
--	io_addr_strobe <= '0';
--	
--	wait for clk_period * 6;
--	
--	-- Read at address 0x00---------------------------------------------
--	io_read_strobe <= '1';
--	io_addr_strobe <= '1';
--	wait for clk_period;
--	io_read_strobe <= '0';
--	io_addr_strobe <= '0';
--	
--	wait for clk_period * 6;
--	
--	-- Read at address 0x00---------------------------------------------
--	io_read_strobe <= '1';
--	io_addr_strobe <= '1';
--	wait for clk_period;
--	io_read_strobe <= '0';
--	io_addr_strobe <= '0';
--	
--	wait for clk_period * 6;
--	
--	-- Write at address 0x00 (1)
--	io_write_strobe <= '1';
--	io_addr_strobe <= '1';
--	io_d_in <= X"12345678";
--	io_addr <= X"00";
--	wait for clk_period;
--	io_write_strobe <= '0';
--	io_addr_strobe <= '0';
--	
--	wait for clk_period * 6;
--	
--	-- Write at address 0x00 (2)
--	io_write_strobe <= '1';
--	io_addr_strobe <= '1';
--	io_d_in <= X"12345678";
--	io_addr <= X"00";
--	wait for clk_period;
--	io_write_strobe <= '0';
--	io_addr_strobe <= '0';
--	
--	wait for clk_period * 6;
--	
--	-- Write at address 0x00 (3)
--	io_write_strobe <= '1';
--	io_addr_strobe <= '1';
--	io_d_in <= X"12345678";
--	io_addr <= X"00";
--	wait for clk_period;
--	io_write_strobe <= '0';
--	io_addr_strobe <= '0';
--	
--	wait for clk_period * 6;
--	
--	-- Write at address 0x00 (4)
--	io_write_strobe <= '1';
--	io_addr_strobe <= '1';
--	io_d_in <= X"12345678";
--	io_addr <= X"00";
--	wait for clk_period;
--	io_write_strobe <= '0';
--	io_addr_strobe <= '0';
--	
--	wait for clk_period * 6;
--
--	-- Read at address 0x00---------------------------------------------
--	io_read_strobe <= '1';
--	io_addr_strobe <= '1';
--	wait for clk_period;
--	io_read_strobe <= '0';
--	io_addr_strobe <= '0';
--	
--	wait for clk_period * 6;
--	
--	-- Read at address 0x00---------------------------------------------
--	io_read_strobe <= '1';
--	io_addr_strobe <= '1';
--	wait for clk_period;
--	io_read_strobe <= '0';
--	io_addr_strobe <= '0';
--	
--	wait for clk_period * 6;
--	
--	-- Read at address 0x00---------------------------------------------
--	io_read_strobe <= '1';
--	io_addr_strobe <= '1';
--	wait for clk_period;
--	io_read_strobe <= '0';
--	io_addr_strobe <= '0';
--	
--	wait for clk_period * 6;
--	
--	 -- Write at address 0x05
--	io_write_strobe <= '1';
--	io_addr_strobe <= '1';
--	io_addr <= X"05";
--	io_d_in <= X"12345678";
--	wait for clk_period;
--	io_write_strobe <= '0';
--	io_addr_strobe <= '0';
--	
--	wait for clk_period * 2;
--	
--	-- Read at address 0x05
--	io_read_strobe <= '1';
--	io_addr_strobe <= '1';
--	wait for clk_period;
--	io_read_strobe <= '0';
--	io_addr_strobe <= '0';

	wait;
    end process;

end;
