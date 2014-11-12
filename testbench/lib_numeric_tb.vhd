use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;

library transceiver;
use transceiver.numeric.all;

entity numeric_tb is
end numeric_tb;
 
architecture test of numeric_tb is 
 
begin

    process
	variable l : line;
    begin
	write(l, bits_for_val(642398572));
	writeline(output, l);
	wait;
    end process;
 
end;
