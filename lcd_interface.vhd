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

library transceiver;
use transceiver.bits.all;

entity lcd_interface is
    port (
	clk, reset : in std_logic;
	io_addr    : in vec8_t;
	io_d_in    : in vec32_t;
	io_d_out : out vec32_t;
	io_addr_strobe : in std_logic;
	io_read_strobe, io_write_strobe : in std_logic;
	io_ready : out std_logic;
	lcd_data : inout vec8_t;
	lcd_en    : out std_logic;
	lcd_rw    : out std_logic;
	lcd_rs    : out std_logic);
end lcd_interface;

architecture lcd_interface_arch of lcd_interface is

    constant LCD_DATA_ADDR : vec8_t := HEX(LCD_DATA_ADDR);
    constant LCD_CMD_ADDR : vec8_t := HEX(LCD_CMD_ADDR);

    type state_type is range 0 to 112;
    signal state, next_state, resume : state_type := 0;
    
    signal io_addr_reg : vec8_t;
    signal io_data_reg : vec8_t;
    signal lcd_data_reg : vec8_t;
    
    signal enabled : std_logic := '0';
    signal start : std_logic := '0';
    signal reading : std_logic := '0';

begin
    -- Get IO data
    io_proc : process(clk, reset) begin
	if reset = '1' then
	    io_data_reg <= (others => '0');
	-- Read IO bus on falling edge
	elsif clk'event and clk = '0' then
	    if io_write_strobe = '1' then
		io_data_reg <= io_d_in (7 downto 0);
		reading <= '0';
		start <= '1';
	    elsif io_read_strobe = '1' then
		reading <= '1';
		start <= '1';
	    else
		start <= '0';
	    end if;
	end if;
    end process io_proc;
    
    lcd_op : process(clk, reset) begin
	if reset = '1' then
	    lcd_data_reg <= (others => '0');
	    io_d_out <= (others => 'Z');
	    lcd_data <= (others => 'Z');
	    lcd_en <= '0';
	    lcd_rw <= '0';
	    io_ready <= '0';
	-- Update IO bus on falling edge
	elsif clk'event and clk = '0' then
	    if enabled = '1' and reading = '1' then
		case state is
		    when 1 =>
			lcd_rw <= '1';
			lcd_en <= '1';
		    when 3 =>
			resume <= 4;
		    when 4 =>
			lcd_en <= '0';
			lcd_data_reg <= lcd_data;
		    when 5 =>
			resume <= 6;
		    when 7 =>
			resume <= 8;
		    when 8 =>
			io_ready <= '1';
			io_d_out <= align_byte(lcd_data_reg, LCD_DATA_ADDR);
		    when 9 =>
			io_ready <= '0';
			io_d_out <= (others => 'Z');
		    when others =>
		end case;
	    elsif enabled = '1' and reading = '0' then
		case state is
		    when 1    =>
			lcd_rw <= '0';
			lcd_en <= '1';
		    when 2 =>
			lcd_data <= io_data_reg;
		    when 3 =>
			resume <= 4;
		    when 4 =>
			lcd_en <= '0';
		    when 5 =>
			resume <= 6;
		    when 6 =>
			lcd_data <= (others => 'Z');
		    when 7 =>
			resume <= 8;
		    when 8 =>
			io_ready <= '1';
		    when 9 =>
			io_ready <= '0';
		    when others =>
		end case;
	    end if;
	end if;
    end process lcd_op;
    
    with state select next_state
	<=  0  when 0,
	    50 when 3,
	    50 when 5,
	    50 when 7,
	    0  when 9,
	    resume when 112,
	    (state + 1) when others;

    update_sm : process(clk, reset) begin
	if reset = '1' then
	    state <= 0;
	elsif clk'event and clk = '1' then
	    if start = '1' then
		state <= 1;
	    else
		state <= next_state;
	    end if;
	end if;
    end process update_sm;

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
    
    -- Decode rs
    with io_addr_reg select lcd_rs
	<=  '1' when LCD_DATA_ADDR,
	    '0' when LCD_CMD_ADDR,
	    '0' when others;
    
    -- Assert enabled
    with io_addr_reg select enabled
	<=  '1' when LCD_DATA_ADDR,
	    '1' when LCD_CMD_ADDR,
	    '0' when others;
	
end lcd_interface_arch;

