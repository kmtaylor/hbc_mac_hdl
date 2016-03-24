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
use ieee.numeric_std.all;

library transceiver;
use transceiver.numeric.all;
use transceiver.bits.all;

entity walsh_decoder is
    port (
	clk : in std_logic;
	data : in walsh_code_t;
	sym : out walsh_sym_t);
end entity walsh_decoder;

architecture walsh_decoder_arch of walsh_decoder is
    
    signal reset : std_logic := '1';
    subtype distance_t is std_logic_vector (
		    bits_for_val(WALSH_CODE_SIZE)-1 downto 0);

    signal cur_walsh : walsh_code_t;
    signal cur_distance : distance_t;
    signal walsh_xnor : walsh_code_t;

    signal sym_counter : walsh_sym_t := (others => '0');
    signal max_index : walsh_sym_t;
    signal max : distance_t;

begin
    
    walsh_encoder : entity work.walsh_encode_lut
	port map (symbol => sym_counter, walsh => cur_walsh);

    walsh_xnor <= cur_walsh xnor data;

    walsh_distance : entity work.hamming_lut_16
	port map (val => walsh_xnor, weight => cur_distance);

    loop_proc : process (clk) begin
	if clk'event and clk = '1' then
	    if reset = '1' then
		reset <= '0';
		max <= (others => '0');
		sym <= max_index;
	    else
		sym_counter <= std_logic_vector(unsigned(sym_counter) + 1);
		if cur_distance > max then
		    max <= cur_distance;
		    max_index <= sym_counter;
		end if;
		if unsigned(sym_counter) = WALSH_CODE_SIZE-1 then
		    reset <= '1';
		end if;
	    end if;
	end if;
    end process loop_proc;

end architecture walsh_decoder_arch;
