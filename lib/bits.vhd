library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package bits is
    function bool_to_bit(input : boolean) return std_logic;
    function ones(length : natural) return std_logic_vector;
    function zeros(length : natural) return std_logic_vector;
    function bit_swap(input : std_logic_vector) return std_logic_vector;
    function bits_for_val(val: natural) return natural;
    function shift_right(input : std_logic_vector; count : natural) 
	return std_logic_vector;
    function shift_left(input : std_logic_vector; count : natural) 
	return std_logic_vector;
    function pad(in_val : std_logic_vector; length : natural)
	return std_logic_vector;
    function concat_bit(vector : std_logic_vector; bit : std_logic)
	return std_logic_vector;
end package bits;

package body bits is

    function bool_to_bit(input : boolean) return std_logic is
    begin
	if input then
	    return '1';
	else
	    return '0';
	end if;
    end function bool_to_bit;

    function ones(length : natural) return std_logic_vector is
	variable r : std_logic_vector(length-1 downto 0);
    begin
	for i in length-1 downto 0 loop
	    r(i) := '1';
	end loop;
	return r;
    end function ones;

    function zeros(length : natural) return std_logic_vector is
	variable r : std_logic_vector(length-1 downto 0);
    begin
	for i in length-1 downto 0 loop
	    r(i) := '0';
	end loop;
	return r;
    end function zeros;
 
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

    function shift_right(input : std_logic_vector; count : natural) 
	return std_logic_vector is
    begin
	return std_logic_vector(shift_right(unsigned(input), count));
    end function shift_right;
 
    function shift_left(input : std_logic_vector; count : natural) 
	return std_logic_vector is
    begin
	return std_logic_vector(shift_left(unsigned(input), count));
    end function shift_left;

    function pad(in_val : std_logic_vector; length : natural)
	return std_logic_vector is
        variable retval : std_logic_vector (length-1 downto 0) :=
                (others => '0');
    begin
        retval(in_val'length-1 downto 0) := in_val;
        return retval;
    end function pad;

    function concat_bit(vector : std_logic_vector; bit : std_logic)
	return std_logic_vector is
    begin
	return vector(vector'length-2 downto 0) & bit;
    end function concat_bit;
 
end package body bits;
