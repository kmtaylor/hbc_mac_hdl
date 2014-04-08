--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   09:59:29 03/21/2014
-- Design Name:   
-- Module Name:   /home/kmtaylor/Xilinx/Projects/cpu_test/io_bus_arbitrator_tb.vhd
-- Project Name:  cpu_test
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: io_bus_arbitrator
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
 
ENTITY io_bus_arbitrator_tb IS
END io_bus_arbitrator_tb;
 
ARCHITECTURE behavior OF io_bus_arbitrator_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT io_bus_arbitrator
    PORT(
         io_d_out : OUT  std_logic_vector(31 downto 0);
         io_ready : OUT  std_logic;
         bus1_d_in : IN  std_logic_vector(31 downto 0);
         bus1_ready : in  std_logic;
         bus2_d_in : IN  std_logic_vector(31 downto 0);
         bus2_ready : in  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal bus1_d_in : std_logic_vector(31 downto 0) := (others => '0');
   signal bus2_d_in : std_logic_vector(31 downto 0) := (others => '0');

 	--Outputs
   signal io_d_out : std_logic_vector(31 downto 0);
   signal io_ready : std_logic;
   signal bus1_ready : std_logic;
   signal bus2_ready : std_logic;
   -- No clocks detected in port list. Replace <clock> below with 
   -- appropriate port name 
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: io_bus_arbitrator PORT MAP (
          io_d_out => io_d_out,
          io_ready => io_ready,
          bus1_d_in => bus1_d_in,
          bus1_ready => bus1_ready,
          bus2_d_in => bus2_d_in,
          bus2_ready => bus2_ready
        );

   -- Stimulus process
   stim_proc: process
   begin	
		bus1_d_in <= (others => 'Z');
		bus2_d_in <= (others => 'Z');
		bus1_ready <= '0';
		bus2_ready <= '0';
      -- hold reset state for 100 ns.
      wait for 100 ns;
		bus1_ready <= '1';
		bus1_d_in <= X"12345678";
		
		wait for 100 ns;
		bus2_ready <= '1';
		bus2_d_in <= X"87654321";
		
		wait for 100 ns;
		bus1_ready <= '0';
		
		wait for 100 ns;
		bus2_ready <= '0';

		wait;
   end process;

END;
