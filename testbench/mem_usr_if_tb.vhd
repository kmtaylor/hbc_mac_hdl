--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:21:43 04/07/2014
-- Design Name:   
-- Module Name:   /home/kmtaylor/Xilinx/Projects/transceiver_ise/mem_usr_if_tb.vhd
-- Project Name:  transceiver_ise
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: mem_controller
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
 
ENTITY mem_usr_if_tb IS
END mem_usr_if_tb;
 
ARCHITECTURE behavior OF mem_usr_if_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT mem_controller
    PORT(
         ddr2_dq : INOUT  std_logic_vector(63 downto 0);
         ddr2_a : OUT  std_logic_vector(12 downto 0);
         ddr2_ba : OUT  std_logic_vector(1 downto 0);
         ddr2_ras_n : OUT  std_logic;
         ddr2_cas_n : OUT  std_logic;
         ddr2_we_n : OUT  std_logic;
         ddr2_cs_n : OUT  std_logic_vector(0 downto 0);
         ddr2_odt : OUT  std_logic_vector(0 downto 0);
         ddr2_cke : OUT  std_logic_vector(0 downto 0);
         ddr2_dm : OUT  std_logic_vector(7 downto 0);
         sys_rst_n : IN  std_logic;
         phy_init_done : OUT  std_logic;
         locked : IN  std_logic;
         rst0_tb : OUT  std_logic;
         cpu_clk : IN  std_logic;
         clk0 : IN  std_logic;
         clk0_tb : OUT  std_logic;
         clk90 : IN  std_logic;
         clkdiv0 : IN  std_logic;
         clk200 : IN  std_logic;
         app_wdf_afull : OUT  std_logic;
         app_af_afull : OUT  std_logic;
         rd_data_valid : OUT  std_logic;
         app_wdf_wren : IN  std_logic;
         app_af_wren : IN  std_logic;
         app_af_addr : IN  std_logic_vector(30 downto 0);
         app_af_cmd : IN  std_logic_vector(2 downto 0);
         rd_data_fifo_out : OUT  std_logic_vector(127 downto 0);
         app_wdf_data : IN  std_logic_vector(127 downto 0);
         app_wdf_mask_data : IN  std_logic_vector(15 downto 0);
         ddr2_dqs : INOUT  std_logic_vector(7 downto 0);
         ddr2_dqs_n : INOUT  std_logic_vector(7 downto 0);
         ddr2_ck : OUT  std_logic_vector(1 downto 0);
         ddr2_ck_n : OUT  std_logic_vector(1 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal sys_rst_n : std_logic := '0';
   signal locked : std_logic := '0';
   signal cpu_clk : std_logic := '0';
   signal clk0 : std_logic := '0';
   signal clk90 : std_logic := '0';
   signal clkdiv0 : std_logic := '0';
   signal clk200 : std_logic := '0';
   signal app_wdf_wren : std_logic := '0';
   signal app_af_wren : std_logic := '0';
   signal app_af_addr : std_logic_vector(30 downto 0) := (others => '0');
   signal app_af_cmd : std_logic_vector(2 downto 0) := (others => '0');
   signal app_wdf_data : std_logic_vector(127 downto 0) := (others => '0');
   signal app_wdf_mask_data : std_logic_vector(15 downto 0) := (others => '0');

	--BiDirs
   signal ddr2_dq : std_logic_vector(63 downto 0);
   signal ddr2_dqs : std_logic_vector(7 downto 0);
   signal ddr2_dqs_n : std_logic_vector(7 downto 0);

 	--Outputs
   signal ddr2_a : std_logic_vector(12 downto 0);
   signal ddr2_ba : std_logic_vector(1 downto 0);
   signal ddr2_ras_n : std_logic;
   signal ddr2_cas_n : std_logic;
   signal ddr2_we_n : std_logic;
   signal ddr2_cs_n : std_logic_vector(0 downto 0);
   signal ddr2_odt : std_logic_vector(0 downto 0);
   signal ddr2_cke : std_logic_vector(0 downto 0);
   signal ddr2_dm : std_logic_vector(7 downto 0);
   signal phy_init_done : std_logic;
   signal rst0_tb : std_logic;
   signal clk0_tb : std_logic;
   signal app_wdf_afull : std_logic;
   signal app_af_afull : std_logic;
   signal rd_data_valid : std_logic;
   signal rd_data_fifo_out : std_logic_vector(127 downto 0);
   signal ddr2_ck : std_logic_vector(1 downto 0);
   signal ddr2_ck_n : std_logic_vector(1 downto 0);

   -- Clock period definitions
   constant cpu_clk_period : time := 10 ns;
   constant clk0_period : time := 8 ns;
   constant clk90_period : time := 8 ns;
   constant clkdiv0_period : time := 16 ns;
   constant clk200_period : time := 5 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: mem_controller PORT MAP (
          ddr2_dq => ddr2_dq,
          ddr2_a => ddr2_a,
          ddr2_ba => ddr2_ba,
          ddr2_ras_n => ddr2_ras_n,
          ddr2_cas_n => ddr2_cas_n,
          ddr2_we_n => ddr2_we_n,
          ddr2_cs_n => ddr2_cs_n,
          ddr2_odt => ddr2_odt,
          ddr2_cke => ddr2_cke,
          ddr2_dm => ddr2_dm,
          sys_rst_n => sys_rst_n,
          phy_init_done => phy_init_done,
          locked => locked,
          rst0_tb => rst0_tb,
          cpu_clk => cpu_clk,
          clk0 => clk0,
          clk0_tb => clk0_tb,
          clk90 => clk90,
          clkdiv0 => clkdiv0,
          clk200 => clk200,
          app_wdf_afull => app_wdf_afull,
          app_af_afull => app_af_afull,
          rd_data_valid => rd_data_valid,
          app_wdf_wren => app_wdf_wren,
          app_af_wren => app_af_wren,
          app_af_addr => app_af_addr,
          app_af_cmd => app_af_cmd,
          rd_data_fifo_out => rd_data_fifo_out,
          app_wdf_data => app_wdf_data,
          app_wdf_mask_data => app_wdf_mask_data,
          ddr2_dqs => ddr2_dqs,
          ddr2_dqs_n => ddr2_dqs_n,
          ddr2_ck => ddr2_ck,
          ddr2_ck_n => ddr2_ck_n
        );

   -- Clock process definitions
   cpu_clk_process :process
   begin
		cpu_clk <= '1';
		wait for cpu_clk_period/2;
		cpu_clk <= '0';
		wait for cpu_clk_period/2;
   end process;
 
   clk0_process :process
   begin
		clk0 <= '1';
		wait for clk0_period/2;
		clk0 <= '0';
		wait for clk0_period/2;
   end process;
 
   clk90_process :process
   begin
		clk90 <= '0';
		wait for clk90_period/4;
		clk90 <= '1';
		wait for clk90_period/2;
		clk90 <= '0';
		wait for clk90_period/4;
   end process;
 
   clkdiv0_process :process
   begin
		clkdiv0 <= '1';
		wait for clkdiv0_period/2;
		clkdiv0 <= '0';
		wait for clkdiv0_period/2;
   end process;
 
   clk200_process :process
   begin
		clk200 <= '1';
		wait for clk200_period/2;
		clk200 <= '0';
		wait for clk200_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      sys_rst_n <= '0';
      wait for 100 ns;	
      sys_rst_n <= '1';

      wait for cpu_clk_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
