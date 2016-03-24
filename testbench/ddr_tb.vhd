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

-- ghdl_flags: --stop-time=350us --wave=ddr_tb.ghw
-- ghdl_deps: mem_interface.vhd
-- ghdl_deps: ddr.vhd

library ieee;
use ieee.std_logic_1164.all;

entity ddr_tb is
end ddr_tb;
 
architecture testbench of ddr_tb is 
 
    --Inputs
    signal reset_i : std_logic;
    signal mem_clk : std_logic;
    signal mem_clk_90 : std_logic;

    -- CPU interface
    signal io_addr : std_logic_vector (7 downto 0);
    signal io_d_in : std_logic_vector (31 downto 0);
    signal io_d_out : std_logic_vector (31 downto 0);
    signal io_addr_strobe : std_logic;
    signal io_read_strobe, io_write_strobe : std_logic;
    signal io_ready : std_logic;

    -- Mem interface
    signal app_af_cmd : std_logic;
    signal app_af_addr : std_logic_vector (31 downto 0);
    signal app_wdf_data : std_logic_vector (31 downto 0);
    signal app_af_wren : std_logic;
    signal app_wdf_mask_data : std_logic_vector (3 downto 0);
    signal rd_data_valid : std_logic;
    signal rd_data_fifo_out : std_logic_vector (31 downto 0);

    --Outputs
    signal ram_clk : std_logic;
    signal ram_clk_n : std_logic;
    signal ram_cke : std_logic;
    signal ram_cs_n : std_logic;
    signal ram_cmd : std_logic_vector (2 downto 0);
    signal ram_ba : std_logic_vector (1 downto 0);
    signal ram_addr : std_logic_vector (12 downto 0);
    signal ram_dm : std_logic_vector (1 downto 0);
    signal ram_dqs : std_logic_vector (1 downto 0);

    -- In/Out
    signal ram_dq : std_logic_vector (15 downto 0);
 
    -- Clock period definitions
    constant clk_period : time := 10 ns;

    signal open_0 : std_logic_vector (11 downto 0);
    signal open_1 : std_logic_vector (1 downto 0);
    signal open_3 : std_logic_vector (95 downto 0);
    
begin

    mem_interface : entity work.mem_interface port map (
	cpu_clk => mem_clk,
	reset => reset_i,
	io_addr => io_addr,
	io_d_in => io_d_in,
	io_d_out => io_d_out,
	io_addr_strobe => io_addr_strobe,
	io_read_strobe => io_read_strobe,
	io_write_strobe => io_write_strobe,
	io_ready => io_ready,

	app_af_cmd (0) => app_af_cmd,
	app_af_cmd (2 downto 1) => open_1,
	app_af_addr => app_af_addr (30 downto 0),
	app_wdf_data (31 downto 0) => app_wdf_data,
	app_wdf_data (127 downto 32) => open_3,
	app_af_wren => app_af_wren,
	app_wdf_mask_data (3 downto 0) => app_wdf_mask_data,
	app_wdf_mask_data (15 downto 4) => open_0,
	rd_data_valid => rd_data_valid,
	rd_data_fifo_out (31 downto 0) => rd_data_fifo_out,
	rd_data_fifo_out (127 downto 32) => (others => '0'));
 
    ddr: entity work.ddr port map (
	reset_i => reset_i,
	mem_clk => mem_clk,

	app_af_cmd => app_af_cmd,
	app_af_addr => app_af_addr,
	app_wdf_data => app_wdf_data,
	app_af_wren => app_af_wren,
	app_wdf_mask_data => app_wdf_mask_data,
	rd_data_valid => rd_data_valid,
	rd_data_fifo_out => rd_data_fifo_out,

	ram_clk => ram_clk,
	ram_clk_n => ram_clk_n,
	ram_cke => ram_cke,
	ram_cs_n => ram_cs_n,
	ram_cmd => ram_cmd,
	ram_ba => ram_ba,
	ram_addr => ram_addr,
	ram_dm => ram_dm,
	ram_dq => ram_dq,
	ram_dqs => ram_dqs);

    -- Clock process definitions
    clk_process : process begin
	mem_clk <= '0';
	wait for clk_period/2;
	mem_clk <= '1';
	wait for clk_period/2;
    end process;

    mem_clk_90 <= mem_clk after clk_period/4;

    -- Stimulus process
    stim_proc: process begin	
	reset_i <= '1';
	io_addr_strobe <= '0';
	io_read_strobe <= '0';
	io_write_strobe <= '0';
	io_d_in <= (others => '0');
	ram_dq <= "ZZZZZZZZZZZZZZZZ";
	wait for clk_period;
	reset_i <= '0';

	wait for clk_period*32000;
		-- set flags 
                io_write_strobe <= '1';
                io_addr_strobe <= '1';
                io_addr <= X"05";
                io_d_in <= X"00000001";

                wait for clk_period;

                io_write_strobe <= '0';
                io_addr_strobe <= '0';

                wait for clk_period*2;
                -- set rd_p

                io_write_strobe <= '1';
                io_addr_strobe <= '1';
                io_addr <= X"08";
                io_d_in <= X"12345678";

                wait for clk_period;

                io_write_strobe <= '0';
                io_addr_strobe <= '0';

                wait for clk_period*2;
                -- set wr_p
                io_write_strobe <= '1';
                io_addr_strobe <= '1';
                io_addr <= X"0C";
                io_d_in <= X"12345678";

                wait for clk_period;

                io_write_strobe <= '0';
                io_addr_strobe <= '0';

	wait for clk_period*5;
		-- read flags 
                io_read_strobe <= '1';
                io_addr_strobe <= '1';
                io_addr <= X"05";

                wait for clk_period;

                io_read_strobe <= '0';
                io_addr_strobe <= '0';

                wait for clk_period*2;
                -- read rd_p

                io_read_strobe <= '1';
                io_addr_strobe <= '1';
                io_addr <= X"08";

                wait for clk_period;

                io_read_strobe <= '0';
                io_addr_strobe <= '0';

                wait for clk_period*2;
                -- read wr_p
                io_read_strobe <= '1';
                io_addr_strobe <= '1';
                io_addr <= X"0C";

                wait for clk_period;

                io_read_strobe <= '0';
                io_addr_strobe <= '0';

	wait for clk_period*20;
                -- do mem_write
                io_write_strobe <= '1';
                io_addr_strobe <= '1';
                io_addr <= X"04";
                io_d_in <= X"ABCD1234";

                wait for clk_period;

                io_write_strobe <= '0';
                io_addr_strobe <= '0';

	wait for clk_period*20;
                -- do mem_read
                io_read_strobe <= '1';
                io_addr_strobe <= '1';
                io_addr <= X"04";

                wait for clk_period;

                io_read_strobe <= '0';
                io_addr_strobe <= '0';

	wait for clk_period*8;
		-- simulate data coming with CL=3
		wait for 4 ns;
		ram_dq <= X"1234";
		wait for clk_period/2;
		ram_dq <= X"5678";
		wait for clk_period/2;
		ram_dq <= "ZZZZZZZZZZZZZZZZ";

	
	wait;
    end process;

end;
