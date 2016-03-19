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

#include <preprocessor/constants.vhh>
#include "send_packet.vhh"

library ieee;
use ieee.std_logic_1164.all;

entity modulator_tb is
end modulator_tb;
 
architecture testbench of modulator_tb is 
 
    component fifo_tx port (
        rst : IN STD_LOGIC;
        wr_clk : IN STD_LOGIC;
        rd_clk : IN STD_LOGIC;
        din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        wr_en : IN STD_LOGIC;
        rd_en : IN STD_LOGIC;
        dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        full : OUT STD_LOGIC;
	prog_full : OUT STD_LOGIC;
        overflow : OUT STD_LOGIC;
        empty : OUT STD_LOGIC;
        underflow : OUT STD_LOGIC);
    end component fifo_tx;

    component fifo_rx port (
        rst : IN STD_LOGIC;
        wr_clk : IN STD_LOGIC;
        rd_clk : IN STD_LOGIC;
        din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        wr_en : IN STD_LOGIC;
        rd_en : IN STD_LOGIC;
        dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        full : OUT STD_LOGIC;
	prog_full : OUT STD_LOGIC;
        overflow : OUT STD_LOGIC;
        empty : OUT STD_LOGIC;
        underflow : OUT STD_LOGIC);
    end component fifo_rx;

   --Inputs
    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
    signal pkt_active : std_logic;
    signal enable : std_logic := '1';
    signal pkt_reset : std_logic;
    signal pkt_ack : std_logic := '0';
    signal io_addr : std_logic_vector(7 downto 0) := (others => '0');
    signal io_d_in : std_logic_vector(31 downto 0) := (others => '0');
    signal io_addr_strobe : std_logic := '0';
    signal io_read_strobe : std_logic := '0';
    signal io_write_strobe : std_logic := '0';
    signal io_ready : std_logic;
    signal sub_io_ready : std_logic;

    signal tmp_addr : std_logic_vector (7 downto 0);
    signal tmp_d : std_logic_vector (31 downto 0);
    signal tmp_addr_strobe : std_logic;
    signal tmp_write_strobe : std_logic;

    signal fi_addr : std_logic_vector (7 downto 0) := (others => '0');
    signal fi_d : std_logic_vector (31 downto 0) := (others => '0');
    signal fi_addr_strobe : std_logic := '0';
    signal fi_write_strobe : std_logic := '0';

    --Outputs
    signal sub_addr_out: std_logic_vector (7 downto 0);
    signal sub_d_out   : std_logic_vector (31 downto 0);
    signal sub_addr_strobe : std_logic;
    signal sub_write_strobe : std_logic;
    signal bus_master : std_logic;

    -- FIFO
    signal fifo_d_out : std_logic_vector (31 downto 0);
    signal fifo_wren, fifo_rden : std_logic;
    signal full, prog_full, overflow, empty, underflow : std_logic;
    signal from_fifo : std_logic_vector (31 downto 0);

    -- P2S
    signal serial_clk, parallel_to_serial_enable : std_logic;
    signal s_data_out : std_logic;
    signal s2p_full, s2p_prog_full, s2p_overflow : std_logic;
    signal s2p_empty, s2p_underflow : std_logic;

    -- S2P
    signal serial_clk_dly : std_logic;
    signal serial_clk_dly_90 : std_logic;
    signal s_data_sync : std_logic;
    signal s2p_fifo_wren : std_logic;
    signal s2p_fifo_data : std_logic_vector (31 downto 0);
    signal s2p_fifo_full : std_logic;
    signal s2p_fifo_rden : std_logic;
    signal s2p_from_fifo : std_logic_vector (31 downto 0);
    signal rx_fifo_data : std_logic_vector (31 downto 0);
    signal rx_fifo_io_ready : std_logic;
 
    -- Clock period definitions
    constant clk_period : time := 10 ns;
    constant s_clk_period : time := 24 ns;
    constant s_clk_dly_period : time := 23997 ps;
    
    type val_ft is file of std_logic;
    type time_ft is file of time;
    file val_file : val_ft open WRITE_MODE is "modulator_tb_stim.value";
    file time_file : time_ft open WRITE_MODE is "modulator_tb_stim.time";
    procedure write_val(val : std_logic) is begin
        write(val_file, val);
        write(time_file, now);
    end procedure write_val;
begin
 
    -- Instantiate the Unit Under Test (UUT)
    modulator: entity work.modulator port map (
	clk => clk,
	reset => reset,
	io_addr => io_addr,
	io_d_in => io_d_in,
	io_addr_strobe => io_addr_strobe,
	io_write_strobe => io_write_strobe,
	io_ready => io_ready,
	bus_master => bus_master,
	sub_addr_out => sub_addr_out,
	sub_d_out => sub_d_out,
	sub_addr_strobe => sub_addr_strobe,
	sub_write_strobe => sub_write_strobe,
	sub_io_ready => sub_io_ready,
	fifo_almost_full => prog_full);

    process (bus_master, sub_addr_out, sub_d_out, sub_addr_strobe,
		    sub_write_strobe, fi_addr, fi_d, fi_addr_strobe,
		    fi_write_strobe) begin
	if bus_master = '1' then
	    tmp_addr <= sub_addr_out;
	    tmp_d <= sub_d_out;
	    tmp_addr_strobe <= sub_addr_strobe;
	    tmp_write_strobe <= sub_write_strobe;
	else
	    tmp_addr <= fi_addr;
	    tmp_d <= fi_d;
	    tmp_addr_strobe <= fi_addr_strobe;
	    tmp_write_strobe <= fi_write_strobe;
	end if;
    end process;

    tx_fifo_interface : entity work.tx_fifo_interface port map (
	clk => clk,
	reset => reset,
	trigger => '0',
	io_addr => tmp_addr,
	io_d_in => tmp_d,
	io_d_out => open,
	io_addr_strobe => tmp_addr_strobe,
	io_read_strobe => '0',
	io_write_strobe => tmp_write_strobe,
	io_ready => sub_io_ready,
	fifo_d_out => fifo_d_out,
	fifo_d_in => (others => '0'),
	fifo_wren => fifo_wren,
	fifo_rden => open);

    p_to_s : entity work.parallel_to_serial port map (
	clk => serial_clk,
	reset => reset,
	trigger => parallel_to_serial_enable,
	trig_clk => clk,
	fifo_d_in => from_fifo,
	fifo_rden => fifo_rden,
	fifo_empty => empty,
	data_out => s_data_out);

    tx_fifo : component fifo_tx port map (
        rst => reset,
        wr_clk => clk,
        rd_clk => serial_clk,
        din => fifo_d_out,
        wr_en => fifo_wren,
        rd_en => fifo_rden,
        dout => from_fifo,
        full => full,
	prog_full => prog_full,
        overflow => overflow,
        empty => empty,
        underflow => underflow);

    rx_fifo : component fifo_rx port map (
        rst => reset,
        wr_clk => serial_clk_dly,
        rd_clk => clk,
        din => s2p_fifo_data,
        wr_en => s2p_fifo_wren,
        rd_en => s2p_fifo_rden,
        dout => s2p_from_fifo,
        full => s2p_full,
	prog_full => s2p_prog_full,
        overflow => s2p_overflow,
        empty => s2p_empty,
        underflow => s2p_underflow);

    sync : entity work.data_synchroniser port map (
	reset => pkt_reset,
	serial_clk => serial_clk_dly,
	serial_clk_90 => serial_clk_dly_90,
	data_in => s_data_out,
	data_out => s_data_sync);

    s_to_p : entity work.serial_to_parallel port map (
	reset_i => reset,
	pkt_reset => pkt_reset,
	serial_clk => serial_clk_dly,
	fifo_d_out => s2p_fifo_data,
	fifo_wren => s2p_fifo_wren,
	fifo_full => s2p_fifo_full,
	data_in => s_data_sync,
	pkt_active => pkt_active,
	enable => enable, 
	pkt_ack => pkt_ack);

    rx_fifo_int : entity work.rx_fifo_interface port map (
            clk => clk,
            reset => reset,
            io_addr => io_addr,
            io_d_out => rx_fifo_data,
            io_addr_strobe => io_addr_strobe,
            io_read_strobe => io_read_strobe,
            io_ready => rx_fifo_io_ready,
            fifo_d_in => s2p_from_fifo,
            fifo_rden => s2p_fifo_rden); 

    -- Clock process definitions
    clk_process : process begin
	clk <= '0';
	wait for clk_period/2;
	clk <= '1';
	wait for clk_period/2;
    end process;

    s_clk_process : process begin
	serial_clk <= '0';
	wait for s_clk_period/2;
	serial_clk <= '1';
	wait for s_clk_period/2;
    end process;

#if 1
    serial_clk_dly <= serial_clk after 0 ns;
#else
    s_clk_dly_process : process begin
	serial_clk_dly <= '0';
	wait for s_clk_dly_period/2;
	serial_clk_dly <= '1';
	write_val(s_data_sync);
	wait for s_clk_dly_period/2;
    end process;
#endif

    serial_clk_dly_90 <= serial_clk_dly after s_clk_period/4;

    -- Stimulus process
    stim_proc: process begin	
	-- hold reset state for 60 ns.
	reset <= '1';
	parallel_to_serial_enable <= '0';
	wait for 60 ns;
	reset <= '0';

	wait for clk_period * 5.5;

	-- Trigger P2S
	TRIGGER()
	SEND_PACKET()

#if 0
	wait for clk_period * 120000;

	READ_RX_FIFO()
	READ_RX_FIFO()
	READ_RX_FIFO()
	READ_RX_FIFO()
	READ_RX_FIFO()
	READ_RX_FIFO()

	TRIGGER()
	SEND_PACKET()
#endif
	
	wait;
    end process;

end;
