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

entity spi_interface is
    port (
	clk, reset  : in std_logic;
	io_addr	    : in vec8_t;
	io_d_out    : out vec32_t;
	io_d_in	    : in vec32_t;
	io_addr_strobe : in std_logic;
	io_read_strobe, io_write_strobe : in std_logic;
	io_ready    : out std_logic;
	hbc_data_int : out std_logic;
	hbc_ctrl_int : out std_logic;
	hbc_data_sclk : in std_logic;
	hbc_data_mosi : in std_logic;
	hbc_data_miso : out std_logic;
	hbc_data_ss : in std_logic;
	hbc_ctrl_sclk : in std_logic;
	hbc_ctrl_mosi : in std_logic;
	hbc_ctrl_miso : out std_logic;
	hbc_ctrl_ss : in std_logic);
end spi_interface;

architecture spi_interface_arch of spi_interface is

    -- FIFO_ADDR must be word aligned
    constant SPI_DATA_ADDR : vec8_t := HEX(SPI_DATA_ADDR);
    constant SPI_CTRL_ADDR : vec8_t := HEX(SPI_CTRL_ADDR);
	    
    signal io_addr_reg : vec8_t;
    signal io_data_reg : vec32_t;
	
    signal io_write : std_logic;
    signal enabled : std_logic;
    signal do_ack : std_logic;
    signal ctrl_op : std_logic;

    signal ctrl_do_valid : std_logic;
    signal ctrl_do, ctrl_do_r : vec8_t;
    signal ctrl_wren, ctrl_wren_status, ctrl_wren_data : std_logic;

    signal data_do_valid : std_logic;
    signal data_do, data_do_r : vec8_t;
    signal data_wren : std_logic;

    signal ctrl_byte : vec8_t;
    signal ctrl_byte_r : std_logic_vector(15 downto 0);
    signal ctrl_index : std_logic;
    signal ctrl_byte_req : std_logic;
    signal ctrl_write_while_busy : std_logic;
    signal ctrl_write_while_busy_ack : std_logic;

begin

    spi_data : entity work.spi_slave
        generic map (
            N => 8,
            CPOL => '0',
            CPHA => '0',
            PREFETCH => 3)
        port map (
            clk_i => clk,
            spi_ssel_i => hbc_data_ss,
            spi_sck_i => hbc_data_sclk,
            spi_mosi_i => hbc_data_mosi,
            spi_miso_o => hbc_data_miso,
            di_req_o => open,
            di_i => io_data_reg(7 downto 0),
            wren_i => data_wren,
            wr_ack_o => open,
            do_valid_o => data_do_valid,
            do_o => data_do);

    spi_cmd : entity work.spi_slave
        generic map (
            N => 8,
            CPOL => '0',
            CPHA => '0',
            PREFETCH => 3)
        port map (
            clk_i => clk,
            spi_ssel_i => hbc_ctrl_ss,
            spi_sck_i => hbc_ctrl_sclk,
            spi_mosi_i => hbc_ctrl_mosi,
            spi_miso_o => hbc_ctrl_miso,
            di_req_o => ctrl_byte_req,
            di_i => ctrl_byte,
            wren_i => ctrl_wren,
            wr_ack_o => open, 
            do_valid_o => ctrl_do_valid,
            do_o => ctrl_do);

    -- Commands are written as 16 bit vectors. One byte is status, the other
    -- is data
    ctrl_index_proc : process (clk) begin
	if clk'event and clk = '0' then
	    if (do_ack and io_write and ctrl_op) = '1' then
		ctrl_index <= '1';
		ctrl_byte_r <= io_data_reg(15 downto 0);
	    elsif ctrl_byte_req = '1' then
		if ctrl_index = '1' then
		    ctrl_wren_data <= '1';
		end if;
		if ctrl_write_while_busy = '1' then
		    ctrl_write_while_busy_ack <= '1';
		else
		    ctrl_index <= '0';
		end if;
	    else
		ctrl_write_while_busy_ack <= '0';
		ctrl_wren_data <= '0';
	    end if;
	end if;
    end process ctrl_index_proc;

    ctrl_data_out_proc : process (ctrl_index, io_data_reg) begin
	if ctrl_index = '1' then
	    ctrl_byte <= ctrl_byte_r(15 downto 8);
	else
	    ctrl_byte <= ctrl_byte_r(7 downto 0);
	end if;
    end process ctrl_data_out_proc;

    ctrl_wren <= ctrl_wren_status or ctrl_wren_data;

    -- Data has arrived on the control interface. Save it and signal an
    -- interrupt.
    ctrl_data_in_proc : process (clk) begin
	if clk'event and clk = '1' then
	    if ctrl_do_valid = '1' then
		ctrl_do_r <= ctrl_do;
	    end if;
	end if;
    end process ctrl_data_in_proc;
    hbc_ctrl_int <= ctrl_do_valid;

    -- Data has arrived on the data interface. Save it and signal an interrupt
    data_data_in_proc: process (clk) begin
	if clk'event and clk = '1' then
	    if data_do_valid = '1' then
		data_do_r <= data_do;
	    end if;
	end if;
    end process data_data_in_proc;
    hbc_data_int <= data_do_valid;

    -- Get IO data
    io_proc : process(clk, reset) begin
	if reset = '1' then
	    do_ack <= '0';
	-- Read IO bus on falling edge
	elsif clk'event and clk = '0' then
	    if io_read_strobe = '1' then
		io_write <= '0';
		do_ack <= '1';
	    elsif io_write_strobe = '1' then
		io_write <= '1';
		io_data_reg <= io_d_in;
		do_ack <= '1';
	    else
		do_ack <= '0';
	    end if;
	end if;
    end process io_proc;
    
    -- ACK process
    ack_proc : process(clk, reset) begin
	if reset = '1' then
	    io_ready <= '0';
	    io_d_out <= (others => 'Z');
	    ctrl_wren_status <= '0';
	    data_wren <= '0';
	    ctrl_write_while_busy <= '0';
	elsif clk'event and clk = '0' then
	    if enabled = '1' then
		if do_ack = '1' then
		    io_ready <= '1';
		    if io_write = '0' then
			if ctrl_op = '1' then
			    io_d_out <= align_byte(ctrl_do_r, SPI_CTRL_ADDR);
			else
			    io_d_out <= align_byte(data_do_r, SPI_DATA_ADDR);
			end if;
		    else
			if ctrl_op = '1' then
			    ctrl_wren_status <= '1';
			    ctrl_write_while_busy <= '1';
			else
			    data_wren <= '1';
			end if;
		    end if;
		else
		    ctrl_wren_status <= '0';
		    data_wren <= '0';
		    io_ready <= '0';
		    io_d_out <= (others => 'Z');
		end if;
	    end if;
	    if ctrl_write_while_busy_ack = '1' then
		ctrl_write_while_busy <= '0';
	    end if;
	end if;
    end process ack_proc;
    
    -- Get address from IO bus
    get_io_addr : process(clk, reset) begin
	if reset = '1' then
	    io_addr_reg <= (others => '0');
	elsif clk'event and clk = '0' then
	    if io_addr_strobe = '1' then
		io_addr_reg <= io_addr;
	    end if;
	end if;
    end process get_io_addr;
    
    -- Assert enabled
    with io_addr_reg (7 downto 0) select enabled
	<=  '1' when SPI_DATA_ADDR,
	    '1' when SPI_CTRL_ADDR,
	    '0' when others;

    with io_addr_reg (7 downto 0) select ctrl_op
	<=  '1' when SPI_CTRL_ADDR,
	    '0' when others;

end spi_interface_arch;

