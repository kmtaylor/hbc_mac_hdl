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

entity debounce is
	port (
		clk : in std_logic;
		d_in : in std_logic;
		q_out : out std_logic);
end debounce;

architecture debounce_arch of debounce is
	
	signal q1, q2, q3 : std_logic := '0';

begin

	process(clk) begin
		if (clk'event and clk = '1') then
			q1 <= d_in;
			q2 <= q1;
			q3 <= q2;
		end if;
	end process;
 
	q_out <= q1 and q2 and (not q3);

end debounce_arch;
