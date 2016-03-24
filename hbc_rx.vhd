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

library ieee;
use ieee.std_logic_1164.all;

library transceiver;
use transceiver.bits.all;

entity hbc_rx is port (
    cpu_clk, cpu_reset : in std_logic;
    serial_clk, serial_clk_90, serial_reset : in std_logic;
    io_addr : in vec8_t;
    io_d_out : out vec32_t;
    io_addr_strobe : in std_logic;
    io_read_strobe : in std_logic;
    io_ready : out std_logic;
    hbc_rx_enable : in std_logic;
    hbc_rx_active : out std_logic;
    hbc_rx_fifo_almost_full : out std_logic;
    hbc_rx_fifo_empty : out std_logic;
    hbc_rx_pkt_ready : out std_logic;
    hbc_rx_pkt_ack : in std_logic;
    s_data_in : in std_logic);
end entity hbc_rx;

architecture hbc_rx_arch of hbc_rx is

    COMPONENT fifo_rx
        PORT (
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
            underflow : OUT STD_LOGIC
        );
    END COMPONENT;

    signal from_rx_fifo : vec32_t;
    signal rx_fifo_rden : std_logic;
    signal rx_fifo_wren : std_logic;
    signal rx_fifo_flush : std_logic;
    signal s2p_fifo_data : vec32_t;
    signal s_data_in_sync : std_logic;
    signal pkt_reset : std_logic;

begin

    fifo_int : entity work.rx_fifo_interface
        port map (
            clk => cpu_clk,
            reset => cpu_reset,
            io_addr => io_addr,
            io_d_out => io_d_out,
            io_addr_strobe => io_addr_strobe,
            io_read_strobe => io_read_strobe,
            io_ready => io_ready,
            fifo_d_in => from_rx_fifo,
            fifo_rden => rx_fifo_rden);

    rx_fifo : component fifo_rx
        port map (
            rst => cpu_reset,
            wr_clk => serial_clk,
            rd_clk => cpu_clk,
            din => s2p_fifo_data,
            wr_en => rx_fifo_wren,
            rd_en => rx_fifo_rden,
            dout => from_rx_fifo,
            full => open,
            prog_full => hbc_rx_fifo_almost_full,
            overflow => open,
            empty => hbc_rx_fifo_empty,
            underflow => open);

    synch : entity work.data_synchroniser
        port map (
            reset => pkt_reset,
            serial_clk => serial_clk,
            serial_clk_90 => serial_clk_90,
            data_in => s_data_in,
            data_out => s_data_in_sync);

    s_to_p : entity work.serial_to_parallel
        port map (
            reset_i => serial_reset,
            pkt_reset => pkt_reset,
            serial_clk => serial_clk,
            fifo_d_out => s2p_fifo_data,
            fifo_wren => rx_fifo_wren,
            fifo_full => '0',
	    enable => hbc_rx_enable,
            data_in => s_data_in_sync,
	    pkt_active => hbc_rx_active,
            pkt_ack => hbc_rx_pkt_ack,
            pkt_ready => hbc_rx_pkt_ready);

end architecture hbc_rx_arch;
