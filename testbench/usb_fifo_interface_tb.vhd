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
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY usb_fifo_interface_tb IS
END usb_fifo_interface_tb;
 
ARCHITECTURE testbench OF usb_fifo_interface_tb IS 
 
   --Inputs
   signal usb_clk : std_logic := '0';
   signal cpu_clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal io_addr : std_logic_vector(7 downto 0) := (others => '0');
   signal io_d_in : std_logic_vector(31 downto 0) := (others => '0');
   signal io_addr_strobe : std_logic := '0';
   signal io_read_strobe : std_logic := '0';
   signal io_write_strobe : std_logic := '0';
   signal pkt_end : std_logic := '0';
   signal UsbEmpty : std_logic := '0';
   signal UsbFull : std_logic := '0';
   signal UsbEN : std_logic := '0';

 	--Outputs
   signal io_d_out : std_logic_vector(31 downto 0);
   signal io_ready : std_logic;
   signal UsbAdr : std_logic_vector(1 downto 0);
   signal UsbOE : std_logic;
   signal UsbWR : std_logic;
   signal UsbRD : std_logic;
   signal UsbPktEnd : std_logic;
   signal UsbIRQ : std_logic;

   signal UsbDB : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant usb_clk_period : time := 21 ns;
   constant cpu_clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: entity work.usb_fifo PORT MAP (
          usb_clk => usb_clk,
          cpu_clk => cpu_clk,
          reset => reset,
          io_addr => io_addr,
          io_d_in => io_d_in,
          io_d_out => io_d_out,
          io_addr_strobe => io_addr_strobe,
          io_read_strobe => io_read_strobe,
          io_write_strobe => io_write_strobe,
          io_ready => io_ready,
          pkt_end => pkt_end,
	  UsbIRQ => UsbIRQ,
	  UsbDB => UsbDB,
          UsbAdr => UsbAdr,
          UsbOE => UsbOE,
          UsbWR => UsbWR,
          UsbRD => UsbRD,
          UsbPktEnd => UsbPktEnd,
          UsbEmpty => UsbEmpty,
          UsbFull => UsbFull,
          UsbEN => UsbEN
        );

   -- Clock process definitions
   usb_clk_process :process
   begin
		usb_clk <= '0';
		wait for usb_clk_period/2;
		usb_clk <= '1';
		wait for usb_clk_period/2;
   end process;
 
   cpu_clk_process :process
   begin
		cpu_clk <= '0';
		wait for cpu_clk_period/2;
		cpu_clk <= '1';
		wait for cpu_clk_period/2;
   end process;
 

   -- Stimulus process
   cpu_stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      reset <= '1';
      wait for 100 ns;	
      reset <= '0';

      wait for cpu_clk_period*10;

      -- Do PKTEND
      pkt_end <= '1';
      wait for cpu_clk_period;
      pkt_end <= '0';
      
      -- Simulate USB read
      wait for cpu_clk_period * 26.5;
      io_addr <= X"10";
      io_addr_strobe <= '1';
      wait for cpu_clk_period;
      io_addr_strobe <= '0';
      wait for cpu_clk_period * 5;
      io_addr <= X"10";
      io_addr_strobe <= '1';
      io_read_strobe <= '1';
      wait for cpu_clk_period;
      io_addr_strobe <= '0';
      io_read_strobe <= '0';

      -- Simulate USB write
      wait for cpu_clk_period * 5;
      io_addr <= X"00";
      io_d_in <= X"ABCDEF12";
      io_addr_strobe <= '1';
      io_write_strobe <= '1';
      wait for cpu_clk_period;
      io_addr_strobe <= '0';
      io_write_strobe <= '0';
      wait for cpu_clk_period * 5;
      io_addr <= X"10";
      io_d_in <= X"ABCDEF12";
      io_addr_strobe <= '1';
      io_write_strobe <= '1';
      wait for cpu_clk_period;
      io_addr_strobe <= '0';
      io_write_strobe <= '0';
      wait;
   end process;

   usb_stim_proc: process
   begin		

      UsbEN <= '0';
      UsbEmpty <= '1';
      wait for usb_clk_period * 1.5;
      UsbEN <= '1';
      UsbDB <= (others => 'Z');
      -- Simulate USB read
      wait for usb_clk_period*11;
      UsbEmpty <= '0';

      wait for usb_clk_period * 2;

      -- Simulate set up time
      wait for 11 ns;
      UsbDB <= X"12";
      wait for usb_clk_period;
      UsbDB <= X"34";

      -- Insert stall
      UsbEmpty <= '1';
      wait for usb_clk_period*3;
      UsbEmpty <= '0';

      wait for usb_clk_period;
      UsbEmpty <= '0';

      UsbDB <= X"56";
      wait for usb_clk_period;
      UsbDB <= X"78";
      UsbEmpty <= '1';
      wait for usb_clk_period;
      UsbDB <= (others => 'Z');

      wait for usb_clk_period * 10;
      UsbEN <= '0';
      wait for usb_clk_period;
      UsbEN <= '1';
      wait;
   end process;

END;
