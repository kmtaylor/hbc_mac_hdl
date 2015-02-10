library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package bits is
    function bit_swap(input : std_logic_vector) return std_logic_vector;
    function bits_for_val(val: natural) return natural;
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

    function bits_for_val(val : natural) return natural is
        type u_array is array (0 to 4) of unsigned(31 downto 0);
        type n_array is array (0 to 4) of natural;
        constant mask : u_array := (X"00000002", X"0000000C", X"000000F0",
                                    X"0000FF00", X"FFFF0000");
        constant shift : n_array := (1, 2, 4, 8, 16);
        variable val_u : unsigned (31 downto 0);
        variable ret : natural;
    begin
        val_u := to_unsigned(val, 32);
        ret := 1;
        for i in 4 downto 0 loop
            if (val_u and mask(i)) /= to_unsigned(0, 32) then
                val_u := shift_right(val_u, shift(i));
                ret := ret + shift(i);
            end if;
        end loop;
        return ret;
    end function bits_for_val;
 
end package body bits;
