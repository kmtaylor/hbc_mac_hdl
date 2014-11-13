library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package bits is
    function bit_swap(input : std_logic_vector) return std_logic_vector;
end package bits;

package body bits is

    function bit_swap(input : std_logic_vector) return std_logic_vector is
	variable ret : std_logic_vector(input'length-1 downto 0) := 
							    (others => '0');
	variable j : natural;
    begin
        for i in input'range loop
	    j := input'length-1 - i;
	    ret(j) := input(i);
        end loop;
        return ret;
    end function bit_swap;
 
end package body bits;
