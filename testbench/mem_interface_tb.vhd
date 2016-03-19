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
 
ENTITY mem_interface_tb IS
END mem_interface_tb;
 
ARCHITECTURE behavior OF mem_interface_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT mem_interface
    PORT(
         cpu_clk : IN  std_logic;
         reset : IN  std_logic;
         io_addr : IN  std_logic_vector(7 downto 0);
         io_d_in : IN  std_logic_vector(31 downto 0);
         io_d_out : OUT  std_logic_vector(31 downto 0);
         io_addr_strobe : IN  std_logic;
         io_read_strobe : IN  std_logic;
         io_write_strobe : IN  std_logic;
         io_ready : OUT  std_logic;
         app_af_cmd : OUT  std_logic_vector(2 downto 0);
         app_af_addr : OUT  std_logic_vector(30 downto 0);
         app_af_wren : OUT  std_logic;
         app_wdf_data : OUT  std_logic_vector(127 downto 0);
         app_wdf_wren : OUT  std_logic;
         app_wdf_mask_data : OUT  std_logic_vector(15 downto 0);
         rd_data_valid : IN  std_logic;
         rd_data_fifo_out : IN  std_logic_vector(127 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal cpu_clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal io_addr : std_logic_vector(7 downto 0) := (others => '0');
   signal io_d_in : std_logic_vector(31 downto 0) := (others => '0');
   signal io_addr_strobe : std_logic := '0';
   signal io_read_strobe : std_logic := '0';
   signal io_write_strobe : std_logic := '0';
   signal rd_data_valid : std_logic := '0';
   signal rd_data_fifo_out : std_logic_vector(127 downto 0) := (others => '0');

 	--Outputs
   signal io_d_out : std_logic_vector(31 downto 0);
   signal io_ready : std_logic;
   signal app_af_cmd : std_logic_vector(2 downto 0);
   signal app_af_addr : std_logic_vector(30 downto 0);
   signal app_af_wren : std_logic;
   signal app_wdf_data : std_logic_vector(127 downto 0);
   signal app_wdf_wren : std_logic;
   signal app_wdf_mask_data : std_logic_vector(15 downto 0);

   -- Clock period definitions
   constant cpu_clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: mem_interface PORT MAP (
          cpu_clk => cpu_clk,
          reset => reset,
          io_addr => io_addr,
          io_d_in => io_d_in,
          io_d_out => io_d_out,
          io_addr_strobe => io_addr_strobe,
          io_read_strobe => io_read_strobe,
          io_write_strobe => io_write_strobe,
          io_ready => io_ready,
          app_af_cmd => app_af_cmd,
          app_af_addr => app_af_addr,
          app_af_wren => app_af_wren,
          app_wdf_data => app_wdf_data,
          app_wdf_wren => app_wdf_wren,
          app_wdf_mask_data => app_wdf_mask_data,
          rd_data_valid => rd_data_valid,
          rd_data_fifo_out => rd_data_fifo_out
        );

   -- Clock process definitions
   cpu_clk_process :process
   begin
		cpu_clk <= '0';
		wait for cpu_clk_period/2;
		cpu_clk <= '1';
		wait for cpu_clk_period/2;
   end process;

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		reset <= '1';
      wait for 100 ns;	
		reset <= '0';

wait for cpu_clk_period*2.5;
      -- set flags 

		io_write_strobe <= '1';
		io_addr_strobe <= '1';
		io_addr <= X"05";
		io_d_in <= X"00000001";
		
		wait for cpu_clk_period;
		
		io_write_strobe <= '0';
		io_addr_strobe <= '0';
		
		wait for cpu_clk_period*2;
		-- set rd_p
		
		io_write_strobe <= '1';
		io_addr_strobe <= '1';
		io_addr <= X"08";
		io_d_in <= X"ABCD1234";
		
		wait for cpu_clk_period;
		
		io_write_strobe <= '0';
		io_addr_strobe <= '0';
		
		wait for cpu_clk_period*2;
		-- set wr_p
		io_write_strobe <= '1';
		io_addr_strobe <= '1';
		io_addr <= X"0C";
		io_d_in <= X"CFFF3210";
		
		wait for cpu_clk_period;
		
		io_write_strobe <= '0';
		io_addr_strobe <= '0';
		
wait for cpu_clk_period*5;
      -- read flags 

		rd_data_valid <= '0';
		io_read_strobe <= '1';
		io_addr_strobe <= '1';
		io_addr <= X"05";
		
		wait for cpu_clk_period;
		
		io_read_strobe <= '0';
		io_addr_strobe <= '0';
		
		wait for cpu_clk_period*2;
		-- read rd_p
		
		io_read_strobe <= '1';
		io_addr_strobe <= '1';
		io_addr <= X"08";
		
		wait for cpu_clk_period;
		
		io_read_strobe <= '0';
		io_addr_strobe <= '0';
		
		wait for cpu_clk_period*2;
		-- read wr_p
		io_read_strobe <= '1';
		io_addr_strobe <= '1';
		io_addr <= X"0C";
		
		wait for cpu_clk_period;
		
		io_read_strobe <= '0';
		io_addr_strobe <= '0';

wait for cpu_clk_period*10;
		-- do mem_write
		io_write_strobe <= '1';
		io_addr_strobe <= '1';
		io_addr <= X"04";
		io_d_in <= X"ABCD1234";
		
		wait for cpu_clk_period;
		
		io_write_strobe <= '0';
		io_addr_strobe <= '0';	
		
wait for cpu_clk_period*10;
		-- do mem_read
		io_read_strobe <= '1';
		io_addr_strobe <= '1';
		io_addr <= X"04";
		
		wait for cpu_clk_period;
		
		io_read_strobe <= '0';
		io_addr_strobe <= '0';
		
		wait for cpu_clk_period * 7;
		
		rd_data_valid <= '1';
		wait for cpu_clk_period * 2;
		rd_data_fifo_out <= X"12345678123456781234567812345678"; 

      wait;
   end process;

END;
