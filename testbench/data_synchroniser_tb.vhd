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

-- ghdl_flags: --stop-time=10us --wave=data_synchroniser_tb.ghw
-- ghdl_deps: data_synchroniser.vhd

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity data_synchroniser_tb is
end data_synchroniser_tb;

architecture testbench of data_synchroniser_tb is

    signal reset : std_logic;
    signal serial_clk : std_logic;
    signal serial_clk_90 : std_logic;
    signal data_in_i : std_logic := '0';
    signal data_in : std_logic := '0';
    signal data_out : std_logic;

    constant clk_period : time := 24 ns;
    constant data_period : time := 25 ns;

    signal data_clk : std_logic := '0';
    signal data : unsigned (63 downto 0) := X"CA216BE669540152";
    signal data_in_p : unsigned (63 downto 0) := X"0000000000000000";
    signal data_out_p : unsigned (63 downto 0) := X"0000000000000000";

begin

    sync: entity work.data_synchroniser port map (
	reset => reset,
	serial_clk => serial_clk,
	serial_clk_90 => serial_clk_90,
	data_in => data_in,
	data_out => data_out);

    -- Clock process definitions
    clk_process : process begin
        serial_clk <= '0';
        wait for clk_period/2;
        serial_clk <= '1';
        wait for clk_period/2;
    end process;

    serial_clk_90 <= serial_clk after clk_period/4;

    data_process : process begin
	wait for data_period;
	data_in_i <= data(0);
	data <= shift_right(data, 1);
    end process;
    data_in <= data_in_i after 1 ns;

    data_clk_process : process begin
	data_clk <= not data_clk;
	wait for data_period/2;
    end process;

    reset_process : process begin
	reset <= '1';
	wait for 30 ns;
	reset <= '0';
	wait;
    end process;

    data_in_collect : process(data_clk) begin
	if data_clk'event and data_clk = '1' then
	    data_in_p(63) <= data_in;
	    data_in_p(62 downto 0) <= data_in_p(63 downto 1);
	end if;
    end process;

    data_out_collect : process(serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    data_out_p(63) <= data_out;
	    data_out_p(62 downto 0) <= data_out_p(63 downto 1);
	end if;
    end process;

end architecture testbench;
