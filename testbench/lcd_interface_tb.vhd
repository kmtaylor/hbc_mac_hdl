--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:59:53 03/19/2014
-- Design Name:   
-- Module Name:   /home/kmtaylor/Xilinx/Projects/cpu_test/lcd_interface_tb.vhd
-- Project Name:  cpu_test
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: lcd_interface
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
