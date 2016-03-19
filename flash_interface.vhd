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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library transceiver;
use transceiver.bits.all;

entity flash_interface is
    generic (
	DIVIDER : natural := 100);
    port (
	cpu_clk, reset  : in std_logic;
	io_addr	    : in vec8_t;
	io_d_out    : out vec32_t;
	io_d_in	    : in vec32_t;
	io_addr_strobe : in std_logic;
	io_read_strobe, io_write_strobe : in std_logic;
	io_ready    : out std_logic;
	flash_sclk : out std_logic;
	flash_mosi : out std_logic;
	flash_miso : in std_logic;
	flash_ss : out std_logic);
end flash_interface;

architecture flash_interface_arch of flash_interface is

    constant FLASH_ADDR : vec8_t := HEX(FLASH_ADDR);
	    
    signal io_addr_reg : vec8_t;
    signal io_data_reg : vec32_t;
	
    signal io_write : std_logic;
    signal enabled : std_logic;
    signal do_ack : std_logic;
    signal do_spi_op : std_logic;
    signal ack_pending : std_logic;
    signal spi_busy : std_logic;

    signal data_do_valid : std_logic;
    signal data_do, data_do_r : vec8_t;
    signal data_wren : std_logic;

begin

    spi_flash : entity work.spi_master
        generic map (
            N => 8,
            CPOL => '0',
            CPHA => '0',
            PREFETCH => 3,
	    SPI_2X_CLK_DIV => DIVIDER/2)
        port map (
            sclk_i => cpu_clk,
	    pclk_i => cpu_clk,
	    rst_i => reset,

            spi_ssel_o => flash_ss,
            spi_sck_o => flash_sclk,
            spi_mosi_o => flash_mosi,
            spi_miso_i => flash_miso,
            di_req_o => open,
            di_i => io_data_reg(7 downto 0),
            wren_i => data_wren,
            wr_ack_o => open,
            do_valid_o => data_do_valid,
            do_o => data_do);

    spi_write : process(cpu_clk, reset) begin
	if reset = '1' then
	    data_wren <= '0';
	elsif cpu_clk'event and cpu_clk = '1' then
	    if (enabled and io_write) = '1' then
		data_wren <= do_spi_op;
	    else
		data_wren <= '0';
	    end if;
	end if;
    end process spi_write;

    spi_sync : process(cpu_clk, reset) begin
	if reset = '1' then
	    spi_busy <= '1';
	elsif cpu_clk'event and cpu_clk = '0' then
	    if ack_pending = '0' then
		spi_busy <= '1';
	    elsif data_do_valid = '1' then
		data_do_r <= data_do;
		spi_busy <= '0';
	    end if;
	end if;
    end process spi_sync;

    busy_proc : process(cpu_clk, reset) begin
	if reset = '1' then
	    do_ack <= '0';
	    ack_pending <= '0';
	elsif cpu_clk'event and cpu_clk = '1' then
	    if do_spi_op = '1' then
		if enabled = '1' then
		    if io_write = '1' then
			ack_pending <= '1';
		    else
			do_ack <= '1';
		    end if;
		end if;
	    else
		if ack_pending = '1' then
		    if spi_busy = '0' then
			do_ack <= '1';
			ack_pending <= '0';
		    end if;
		else
		    do_ack <= '0';
		end if;
	    end if;
	end if;
    end process busy_proc;

    -- Get IO data
    io_proc : process(cpu_clk, reset) begin
	if reset = '1' then
	    do_spi_op <= '0';
	-- Read IO bus on falling edge
	elsif cpu_clk'event and cpu_clk = '0' then
	    if io_read_strobe = '1' then
		io_write <= '0';
		do_spi_op <= '1';
	    elsif io_write_strobe = '1' then
		io_write <= '1';
		io_data_reg <= io_d_in;
		do_spi_op <= '1';
	    else
		do_spi_op <= '0';
	    end if;
	end if;
    end process io_proc;
    
    -- ACK process
    ack_proc : process(cpu_clk, reset) begin
	if reset = '1' then
	    io_ready <= '0';
	    io_d_out <= (others => 'Z');
	elsif cpu_clk'event and cpu_clk = '0' then
	    if enabled = '1' then
		if do_ack = '1' then
		    io_ready <= '1';
		    if io_write = '0' then
			io_d_out <= align_byte(data_do_r, FLASH_ADDR);
		    end if;
		else
		    io_ready <= '0';
		    io_d_out <= (others => 'Z');
		end if;
	    end if;
	end if;
    end process ack_proc;
    
    -- Get address from IO bus
    get_io_addr : process(cpu_clk, reset) begin
	if reset = '1' then
	    io_addr_reg <= (others => '0');
	elsif cpu_clk'event and cpu_clk = '0' then
	    if io_addr_strobe = '1' then
		io_addr_reg <= io_addr;
	    end if;
	end if;
    end process get_io_addr;
    
    -- Assert enabled
    with io_addr_reg (7 downto 0) select enabled
	<=  '1' when FLASH_ADDR,
	    '0' when others;

end flash_interface_arch;

