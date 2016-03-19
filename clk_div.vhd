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


library ieee;
use ieee.std_logic_1164.all;

entity clock_divider is
	generic (
		DIV_BY : integer := 20E3);
	port (
		clk : in std_logic;
		clk_div : out std_logic);
end clock_divider;

architecture clock_divider_arch of clock_divider is

    signal counter : integer := 0;
    signal clk_div_i : std_logic := '0';

    constant LIMIT : integer := DIV_BY / 2;
	
begin

    process (clk) begin
	if clk'event and clk = '1' then

	    clk_div_i <= clk_div_i;
	    counter <= counter + 1;

	    if counter = LIMIT then
		clk_div_i <= not(clk_div_i);
		counter <= 0;
	    end if;

	end if;
    end process;

    clk_div <= clk_div_i;

end clock_divider_arch;
