--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:04:16 03/20/2014
-- Design Name:   
-- Module Name:   /home/kmtaylor/Xilinx/Projects/cpu_test/fifo_interface_tb.vhd
-- Project Name:  cpu_test
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: fifo_interface
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

LIBRARY XilinxCoreLib;
 
ENTITY fifo_interface_tb IS
END fifo_interface_tb;
 
ARCHITECTURE behavior OF fifo_interface_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT fifo_interface
    PORT(
         clk : IN  std_logic;
         reset : IN  std_logic;
         io_addr : IN  std_logic_vector(7 downto 0);
         io_d_in : IN  std_logic_vector(31 downto 0);
         io_d_out : OUT  std_logic_vector(31 downto 0);
         io_addr_strobe : IN  std_logic;
         io_read_strobe : IN  std_logic;
         io_write_strobe : IN  std_logic;
         io_ready : OUT  std_logic;
         fifo_d_out : OUT  std_logic_vector(31 downto 0);
         fifo_wren : OUT  std_logic;
         fifo_d_in : IN  std_logic_vector(31 downto 0);
         fifo_rden : OUT  std_logic
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
			almost_full : OUT STD_LOGIC;
			overflow : OUT STD_LOGIC;
			empty : OUT STD_LOGIC;
			almost_empty : OUT STD_LOGIC;
			underflow : OUT STD_LOGIC
		);
	END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal io_addr : std_logic_vector(7 downto 0) := (others => '0');
   signal io_d_in : std_logic_vector(31 downto 0) := (others => '0');
   signal io_addr_strobe : std_logic := '0';
   signal io_read_strobe : std_logic := '0';
   signal io_write_strobe : std_logic := '0';
   signal fifo_d_in : std_logic_vector(31 downto 0) := (others => '0');

 	--Outputs
   signal io_d_out : std_logic_vector(31 downto 0);
   signal io_ready : std_logic;
   signal fifo_d_out : std_logic_vector(31 downto 0);
   signal fifo_wren : std_logic;
   signal fifo_rden : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
	
	signal full, almost_full : std_logic;
	signal overflow, underflow : std_logic;
	signal empty, almost_empty : std_logic;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: fifo_interface PORT MAP (
          clk => clk,
          reset => reset,
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
          fifo_rden => fifo_rden
        );
		  
	fifo0 : component fifo_tx PORT MAP (
			rst => reset,
			wr_clk => clk,
			rd_clk => clk,
			din => fifo_d_out,
			wr_en => fifo_wren,
			rd_en => fifo_rden,
			dout => fifo_d_in,
			full => full,
			almost_full => almost_full,
			overflow => overflow,
			empty => empty,
			almost_empty => almost_empty,
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
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 20 ns.
			reset <= '1';
      wait for 20 ns;
			reset <= '0';

      wait for clk_period * 20.5;

      -- insert stimulus here 
		io_write_strobe <= '1';
		io_addr_strobe <= '1';
		io_addr <= X"00";
		io_d_in <= X"12345678";
		
		wait for clk_period;
		
		io_write_strobe <= '0';
		io_addr_strobe <= '0';
		
		wait for clk_period * 6;
		
		io_read_strobe <= '1';
		io_addr_strobe <= '1';
				
		wait for clk_period;
		
		io_read_strobe <= '0';
		io_addr_strobe <= '0';
		
		wait for clk_period * 6;
		
		 -- insert stimulus here 
		io_write_strobe <= '1';
		io_addr_strobe <= '1';
		io_addr <= X"05";
		io_d_in <= X"12345678";
		
		wait for clk_period;
		
		io_write_strobe <= '0';
		io_addr_strobe <= '0';
		
		wait for clk_period * 2;
		
		io_read_strobe <= '1';
		io_addr_strobe <= '1';
		
		wait for clk_period;
		
		io_read_strobe <= '0';
		io_addr_strobe <= '0';

      wait;
   end process;

END;
