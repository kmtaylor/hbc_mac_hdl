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

-- ghdl_flags: --stop-time=5000ns --wave=parallel_to_serial_tb.ghw
-- ghdl_deps: parallel_to_serial.vhd
-- ghdl_deps: build/cores/fifo_tx/fifo_tx.vhd

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
ENTITY parallel_to_serial_tb IS
END parallel_to_serial_tb;
 
ARCHITECTURE behavior OF parallel_to_serial_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT parallel_to_serial
    PORT(
         clk : IN  std_logic;
         reset : IN  std_logic;
	 trigger : IN std_logic;
	 trig_clk : IN std_logic;
         fifo_d_in : IN  std_logic_vector(31 downto 0);
         fifo_rden : OUT std_logic;
         fifo_empty : IN  std_logic;
         data_out : OUT  std_logic
        );
    END COMPONENT;
	 
	 COMPONENT fifo_tx PORT (
			rst : IN STD_LOGIC;
			wr_clk : IN STD_LOGIC;
			rd_clk : IN STD_LOGIC;
			din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
			wr_en : IN STD_LOGIC;
			rd_en : IN STD_LOGIC;
			dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			full : OUT STD_LOGIC;
			overflow : OUT STD_LOGIC;
			empty : OUT STD_LOGIC;
			underflow : OUT STD_LOGIC
		);
	END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal trigger : std_logic := '0';
   signal trig_clk : std_logic := '0';
   signal fifo_d_in : std_logic_vector(31 downto 0) := (others => '0');
   signal fifo_rden : std_logic := '0';
   signal fifo_empty : std_logic := '0';

 	--Outputs
   signal data_out : std_logic;

   -- Clock period definitions
   constant clk_period : time := 24 ns;
   constant cpu_clk_period : time := 10 ns;
	
	signal full, almost_full : std_logic;
	signal overflow, underflow : std_logic;
	
	signal cpu_data : std_logic_vector (31 downto 0);
	signal cpu_wren : std_logic;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: parallel_to_serial PORT MAP (
          clk => clk,
          reset => reset,
	  trigger => trigger,
	  trig_clk => trig_clk,
          fifo_d_in => fifo_d_in,
          fifo_rden => fifo_rden,
          fifo_empty => fifo_empty,
          data_out => data_out
      );
		  
	fifo0 : component fifo_tx PORT MAP (
			rst => reset,
			wr_clk => clk,
			rd_clk => clk,
			din => cpu_data,
			wr_en => cpu_wren,
			rd_en => fifo_rden,
			dout => fifo_d_in,
			full => full,
			overflow => overflow,
			empty => fifo_empty,
			underflow => underflow
		);
		
   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 
   cpu_clk_process :process
   begin
		trig_clk <= '0';
		wait for cpu_clk_period/2;
		trig_clk <= '1';
		wait for cpu_clk_period/2;
   end process;

   -- Stimulus process
   stim_proc: process
   begin		
		reset <= '1';
      -- hold reset state for 30 ns.
		cpu_wren <= '0';
		cpu_data <= X"A5B5CD0A";
      wait for clk_period * 2;	
		reset <= '0';
		wait for clk_period * 3;
		cpu_wren <= '1';



    wait for clk_period;
    cpu_wren <= '0';
    cpu_data <= X"5AA0555A";
    wait for clk_period;
    cpu_wren <= '1';
    wait for clk_period;
    cpu_wren <= '0';
	
    wait for clk_period * 6;
      
		-- insert cpu stimulus here 
    wait for cpu_clk_period;
    trigger <= '1';
    wait for cpu_clk_period;
    trigger <= '0';
		

    wait;
   end process;

END;
