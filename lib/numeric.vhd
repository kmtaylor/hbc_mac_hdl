library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package numeric is
    constant WALSH_CODE_SIZE : natural := 16;
    constant WALSH_SYM_SIZE : natural := 4;
    subtype walsh_code_t is std_logic_vector(WALSH_CODE_SIZE-1 downto 0);
    subtype walsh_sym_t is std_logic_vector(WALSH_SYM_SIZE-1 downto 0);

    function bits_for_val(val: natural) return natural;
    function calc_hamming(slv, target : std_logic_vector) return natural;
    function phase_sum (reg : std_logic_vector; size : unsigned) return natural;
    function walsh_encode (input : walsh_sym_t) return walsh_code_t;
end package numeric;

package body numeric is

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

    function calc_hamming(slv, target : std_logic_vector) return natural is
	variable n_ones : natural := 0;
    begin
	for i in slv'range loop
	    if slv(i) = target(i) then
		n_ones := n_ones + 1;
	    end if;
	end loop;
	return n_ones;
    end function calc_hamming;
 
    function phase_sum (reg : std_logic_vector; size : unsigned)
    return natural is
	variable acc : natural := 0;
	variable i : integer;
	variable required : std_logic;
    begin
	-- Count correct phase samples in odd positions
	i := to_integer(size - 1);
	required := '1';
	while i >= 0 loop
	    if reg(i) = required then
		acc := acc + 1;
	    end if;
	    i := i - 2;
	end loop;
	-- Count correct phase samples in even positions
	i := to_integer(size - 2);
	required := '0';
	while i >= 0 loop
	    if reg(i) = required then
		acc := acc + 1;
	    end if;
	    i := i - 2;
	end loop;
	return acc;
    end function phase_sum;

    function walsh_encode (input : walsh_sym_t) return walsh_code_t is
    begin
	if input =  "1111" then
	    return X"9669";
	elsif input =  "1110" then
	    return X"C33C";
	elsif input =  "1101" then
	    return X"A55A";
	elsif input =  "1100" then
	    return X"F00F";
	elsif input =  "1011" then
	    return X"9966";
	elsif input =  "1010" then
	    return X"CC33";
	elsif input =  "1001" then
	    return X"AA55";
	elsif input =  "1000" then
	    return X"FF00";
	elsif input =  "0111" then
	    return X"9696";
	elsif input =  "0110" then
	    return X"C3C3";
	elsif input =  "0101" then
	    return X"A5A5";
	elsif input =  "0100" then
	    return X"F0F0";
	elsif input =  "0011" then
	    return X"9999";
	elsif input =  "0010" then
	    return X"CCCC";
	elsif input =  "0001" then
	    return X"AAAA";
	elsif input =  "0000" then
	    return X"FFFF";
	end if;
	return X"0000";
    end function walsh_encode;

    --function walsh_decode (input : std_logic_vector) return std_logic_vector) is
    --begin
    --end function walsh_decode;

end package body numeric;
