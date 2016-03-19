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

entity tx_fifo_interface is
    port (
	clk, reset  : in std_logic;
	trigger	    : in std_logic;
	io_addr	    : in vec8_t;
	io_d_in	    : in vec32_t;
	io_d_out    : out vec32_t;
	io_addr_strobe : in std_logic;
	io_read_strobe, io_write_strobe : in std_logic;
	io_ready    : out std_logic;
	fifo_d_out  : out vec32_t;
	fifo_wren   : out std_logic;
	fifo_d_in   : in vec32_t;
	fifo_rden   : out std_logic);
end tx_fifo_interface;

architecture tx_fifo_interface_arch of tx_fifo_interface is

    -- FIFO_ADDR must be word aligned
    constant FIFO_ADDR : vec8_t := HEX(FIFO_ADDR);
    constant FIFO_MASK_ADDR : vec8_t := HEX(FIFO_MASK_ADDR);
	    
    signal io_addr_reg : vec8_t;
    signal io_d_in_r : vec32_t;
	
    signal enabled : std_logic;
    signal mask_op : std_logic;
    signal do_fifo_rden : std_logic := '0';
    signal do_ack : std_logic := '0';
    signal reading : std_logic := '0';

    constant COUNTER_BITS : natural := bits_for_val(32);
    subtype counter_type is unsigned (COUNTER_BITS-1 downto 0);
    constant unity : unsigned (31 downto 0) := to_unsigned(1, 32);
    constant reset_32 : counter_type := to_unsigned(32, COUNTER_BITS);
    signal num_bits : counter_type := reset_32;
    signal bit_p : counter_type := reset_32;
    signal bit_p_i : counter_type;
    signal cur_buf : vec32_t;
    signal cur_buf_i : vec32_t;
    signal wrap_buf : vec32_t;
    signal wrap_buf_i : vec32_t;
    signal write_wrap_buf : std_logic;
    signal write_wrap_buf_i : std_logic;
    signal flush_i : std_logic;
    signal clear_cur_buf : std_logic;
    signal clear_cur_buf_i : std_logic;
    signal wrap_mask : vec32_t;
    signal nowrap_mask : vec32_t;
    signal new_mask : vec32_t;
    signal flush_req : std_logic;
    signal flush_req_reset : std_logic;

begin
    nowrap_mask <= std_logic_vector(
			shift_left(unity, to_integer(num_bits)) - 1);
    new_mask <= std_logic_vector(
			shift_left(unity, to_integer(num_bits - bit_p)) - 1);
    wrap_mask <= std_logic_vector(shift_left(
			shift_left(unity, to_integer(bit_p)) - 1,
			to_integer(num_bits - bit_p)));

    with write_wrap_buf select fifo_d_out
	<=  wrap_buf	when '1',
	    cur_buf	when others;

    push_sync : process(clk, reset) begin
	if reset = '1' then
	    cur_buf <= (others => '0');
	    wrap_buf <= (others => '0');
	    bit_p <= reset_32;
	    num_bits <= reset_32;
	    write_wrap_buf <= '0';
	    fifo_wren <= '0';
	    clear_cur_buf <= '0';
	    flush_req_reset <= '0';
	elsif clk'event and clk = '0' then
	    fifo_wren <= '0';
	    flush_req_reset <= '0';
	    if clear_cur_buf = '1' then
		cur_buf <= (others => '0');
		clear_cur_buf <= '0';
	    elsif flush_req = '1' then
		fifo_wren <= '1';
		clear_cur_buf <= '1';
		flush_req_reset <= '1';
		bit_p <= reset_32;
	    elsif do_ack = '1' and enabled = '1' and reading = '0' then
		if mask_op = '0' then
		    cur_buf <= cur_buf_i;
		    wrap_buf <= wrap_buf_i;
		    bit_p <= bit_p_i;
		    fifo_wren <= flush_i;
		    clear_cur_buf <= clear_cur_buf_i;
		    write_wrap_buf <= write_wrap_buf_i;
		else
		    num_bits <= counter_type(
				    io_d_in_r(COUNTER_BITS-1 downto 0));
		end if;
	    end if;
	end if;
    end process push_sync;

    push_proc : process(num_bits, bit_p, cur_buf, io_d_in_r, wrap_mask,
				nowrap_mask, new_mask) begin
	wrap_buf_i <= cur_buf or shift_right(io_d_in_r and wrap_mask,
					    to_integer(num_bits - bit_p));
	flush_i <= '0';
	write_wrap_buf_i <= '0';
	clear_cur_buf_i <= '0';
	if num_bits > bit_p then
	    bit_p_i <= reset_32 - (num_bits - bit_p);
	    cur_buf_i <= shift_left(io_d_in_r and new_mask,
				    32 - to_integer(num_bits - bit_p));
	    flush_i <= '1';
	    write_wrap_buf_i <= '1';
	else
	    cur_buf_i <= cur_buf or shift_left(io_d_in_r and nowrap_mask,
						to_integer(bit_p - num_bits));
	    if num_bits = bit_p then
		bit_p_i <= reset_32;
		flush_i <= '1';
		clear_cur_buf_i <= '1';
	    else
		bit_p_i <= bit_p - num_bits;
	    end if;
	end if;
    end process push_proc;

    trigger_proc : process(trigger, reset, flush_req_reset) begin
        if reset = '1' or flush_req_reset = '1' then
            flush_req <= '0';
        elsif trigger'event and trigger = '1' then
            flush_req <= '1';
        end if;
    end process trigger_proc;

    -- Get IO data
    io_proc : process(clk, reset) begin
	if reset = '1' then
	    do_fifo_rden <= '0';
	    do_ack <= '0';
	    io_d_in_r <= (others => '0');
	-- Read IO bus on falling edge
	elsif clk'event and clk = '0' then
	    if io_write_strobe = '1' then
		io_d_in_r <= io_d_in;
		do_ack <= '1';
		reading <= '0';
	    elsif io_read_strobe = '1' then
		do_fifo_rden <= '1';
		do_ack <= '1';
		reading <= '1';
	    else
		do_fifo_rden <= '0';
		do_ack <= '0';
	    end if;
	end if;
    end process io_proc;
    
    -- ACK process
    ack_proc : process(clk, reset) begin
	if reset = '1' then
	    io_ready <= '0';
	    io_d_out <= (others => 'Z');
	elsif clk'event and clk = '0' then
	    if enabled = '1' then
		if do_ack = '1' then
		    io_ready <= '1';
		    if reading = '1' then
			io_d_out <= fifo_d_in;
		    end if;
		else
		    io_ready <= '0';
		    io_d_out <= (others => 'Z');
		end if;
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
	<=  '1' when FIFO_ADDR,
	    '1' when FIFO_MASK_ADDR,
	    '0' when others;

    with io_addr_reg (7 downto 0) select mask_op
	<=  '1' when FIFO_MASK_ADDR,
            '0' when others;
	    
    fifo_enable : process (enabled, do_fifo_rden) begin
	if enabled = '1' then
	    fifo_rden <= do_fifo_rden;
	else
	    fifo_rden <= '0';
	end if;
    end process fifo_enable;

end tx_fifo_interface_arch;

