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

library unisim;
use unisim.vcomponents.all;

entity walsh_encode_lut is
    port (
	symbol : in walsh_sym_t;
	walsh : out walsh_code_t);
end entity walsh_encode_lut;

architecture walsh_encode_lut_arch of walsh_encode_lut is

begin

    walsh_low_lut : RAM16X8S
	generic map (
	    INIT_00 => X"9669",
	    INIT_01 => X"3CC3",
	    INIT_02 => X"5AA5",
	    INIT_03 => X"F00F",
	    INIT_04 => X"6699",
	    INIT_05 => X"CC33",
	    INIT_06 => X"AA55",
	    INIT_07 => X"00FF") 
	port map (
	    O => walsh(7 downto 0),
	    A0 => symbol(0),
	    A1 => symbol(1),
	    A2 => symbol(2),
	    A3 => symbol(3),
	    D => X"00",
	    WCLK => '0',
	    WE => '0');

    walsh_high_lut : RAM16X8S
	generic map (
	    INIT_00 => X"6969",
	    INIT_01 => X"C3C3",
	    INIT_02 => X"A5A5",
	    INIT_03 => X"0F0F",
	    INIT_04 => X"9999",
	    INIT_05 => X"3333",
	    INIT_06 => X"5555",
	    INIT_07 => X"FFFF")
	port map (
	    O => walsh(15 downto 8),
	    A0 => symbol(0),
	    A1 => symbol(1),
	    A2 => symbol(2),
	    A3 => symbol(3),
	    D => X"00",
	    WCLK => '0',
	    WE => '0');

end architecture walsh_encode_lut_arch;
