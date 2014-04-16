--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   18:45:39 04/09/2014
-- Design Name:   
-- Module Name:   /home/kmtaylor/Xilinx/Projects/transceiver_ise/usb_fifo_interface_tb.vhd
-- Project Name:  transceiver_ise
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: usb_fifo
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY usb_fifo_interface_tb IS
END usb_fifo_interface_tb;
 
ARCHITECTURE behavior OF usb_fifo_interface_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT usb_fifo
    PORT(
         usb_clk : IN  std_logic;
         cpu_clk : IN  std_logic;
         reset : IN  std_logic;
         io_addr : IN  std_logic_vector(7 downto 0);
         io_d_in : IN  std_logic_vector(31 downto 0);
         io_d_out : OUT  std_logic_vector(31 downto 0);
         io_addr_strobe : IN  std_logic;
         io_read_strobe : IN  std_logic;
         io_write_strobe : IN  std_logic;
         io_ready : OUT  std_logic;
         pkt_end : IN  std_logic;
	 UsbIRQ : OUT std_logic;
	 UsbDB : INOUT std_logic_vector(7 downto 0);
         UsbAdr : OUT  std_logic_vector(1 downto 0);
         UsbOE : OUT  std_logic;
         UsbWR : OUT  std_logic;
         UsbRD : OUT  std_logic;
         UsbPktEnd : OUT  std_logic;
         UsbEmpty : IN  std_logic;
         UsbEN : IN  std_logic
        );
    END COMPONENT;
    

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
   uut: usb_fifo PORT MAP (
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
      wait for usb_clk_period;
      UsbDB <= X"56";
      wait for usb_clk_period;
      UsbDB <= X"78";
      UsbEmpty <= '1';
      wait for usb_clk_period;
      UsbDB <= (others => 'Z');

      wait;
   end process;

END;
