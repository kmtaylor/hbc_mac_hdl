-- Copyright (C) 2016 Kim Taylor
--
-- This file is part of hbc_mac.
--
-- hbc_mac is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- Foobar is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with hbc_mac.  If not, see <http://www.gnu.org/licenses/>.

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
ENTITY lcd_interface_tb IS
END lcd_interface_tb;
 
ARCHITECTURE behavior OF lcd_interface_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT lcd_interface
    PORT(
         clk : IN  std_logic;
         reset : IN  std_logic;
         io_addr : IN  std_logic_vector(7 downto 0);
         io_d_in : IN  std_logic_vector(7 downto 0);
         io_d_out : OUT  std_logic_vector(7 downto 0);
         io_addr_strobe : IN  std_logic;
         io_read_strobe : IN  std_logic;
         io_write_strobe : IN  std_logic;
         io_ready : OUT  std_logic;
         lcd_data : INOUT  std_logic_vector(7 downto 0);
         lcd_en : OUT  std_logic;
         lcd_rw : OUT  std_logic;
         lcd_rs : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal io_addr : std_logic_vector(7 downto 0) := (others => '0');
   signal io_d_in : std_logic_vector(7 downto 0) := (others => '0');
   signal io_addr_strobe : std_logic := '0';
   signal io_read_strobe : std_logic := '0';
   signal io_write_strobe : std_logic := '0';

	--BiDirs
   signal lcd_data : std_logic_vector(7 downto 0);

 	--Outputs
   signal io_d_out : std_logic_vector(7 downto 0);
   signal io_ready : std_logic;
   signal lcd_en : std_logic;
   signal lcd_rw : std_logic;
   signal lcd_rs : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: lcd_interface PORT MAP (
          clk => clk,
          reset => reset,
          io_addr => io_addr,
          io_d_in => io_d_in,
          io_d_out => io_d_out,
          io_addr_strobe => io_addr_strobe,
          io_read_strobe => io_read_strobe,
          io_write_strobe => io_write_strobe,
          io_ready => io_ready,
          lcd_data => lcd_data,
          lcd_en => lcd_en,
          lcd_rw => lcd_rw,
          lcd_rs => lcd_rs
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		reset <= '1';
      wait for 100 ns;	
		reset <= '0';

      wait for clk_period * 1.5;

      io_write_strobe <= '1';
		io_addr_strobe <= '1';
		io_addr <= X"02";
		io_d_in <= X"AB";
		
		wait for clk_period;
		
		io_write_strobe <= '0';
		io_addr_strobe <= '0';
		
		wait for 1600 ns;
		
		io_read_strobe <= '1';
		io_addr_strobe <= '1';
		io_addr <= X"03";
		--lcd_data <= X"CD";
		
		wait for clk_period;
		
		io_read_strobe <= '0';
		io_addr_strobe <= '0';

      wait;
   end process;

END;
