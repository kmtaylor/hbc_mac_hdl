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
    function sym_in_phase(sym : std_logic_vector) return boolean;
    function walsh_encode (input : walsh_sym_t) return walsh_code_t;
    function walsh_decode (input : walsh_code_t) return walsh_sym_t;
    function weight_threshold (weight : std_logic_vector) return std_logic;

    function bool_to_bit(input : boolean) return std_logic;
    function ones(length : natural) return std_logic_vector;
end package numeric;

package body numeric is

    constant WALSH_15 : walsh_code_t := X"9669";
    constant WALSH_14 : walsh_code_t := X"C33C";
    constant WALSH_13 : walsh_code_t := X"A55A";
    constant WALSH_12 : walsh_code_t := X"F00F";
    constant WALSH_11 : walsh_code_t := X"9966";
    constant WALSH_10 : walsh_code_t := X"CC33";
    constant WALSH_09 : walsh_code_t := X"AA55";
    constant WALSH_08 : walsh_code_t := X"FF00";
    constant WALSH_07 : walsh_code_t := X"9696";
    constant WALSH_06 : walsh_code_t := X"C3C3";
    constant WALSH_05 : walsh_code_t := X"A5A5";
    constant WALSH_04 : walsh_code_t := X"F0F0";
    constant WALSH_03 : walsh_code_t := X"9999";
    constant WALSH_02 : walsh_code_t := X"CCCC";
    constant WALSH_01 : walsh_code_t := X"AAAA";
    constant WALSH_00 : walsh_code_t := X"FFFF";

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
	variable sum : natural := 0;
    begin
	for i in slv'range loop
	    if slv(i) = target(i) then
		sum := sum + 1;
	    end if;
	end loop;
	return sum;
    end function calc_hamming;

    function weight_threshold (weight : std_logic_vector) return std_logic is
    begin
    	-- Do a 4 bit comparison to check for values greater than 55 
        if weight(6 downto 3) = X"8" then
            return '1';
        elsif weight(6 downto 3) = X"7" then
            return '1';
        else
            return '0';
        end if;
    end function weight_threshold;
 
    function sym_in_phase (sym : std_logic_vector) return boolean is
    begin
	if (sym(7 downto 0) = X"AA") or (sym(7 downto 0) = X"55") then
	    return true;
	else
	    return false;
	end if;
    end function sym_in_phase;

    function walsh_encode (input : walsh_sym_t) return walsh_code_t is
    begin
	if input =  "1111" then
	    return WALSH_15;
	elsif input =  "1110" then
	    return WALSH_14;
	elsif input =  "1101" then
	    return WALSH_13;
	elsif input =  "1100" then
	    return WALSH_12;
	elsif input =  "1011" then
	    return WALSH_11;
	elsif input =  "1010" then
	    return WALSH_10;
	elsif input =  "1001" then
	    return WALSH_09;
	elsif input =  "1000" then
	    return WALSH_08;
	elsif input =  "0111" then
	    return WALSH_07;
	elsif input =  "0110" then
	    return WALSH_06;
	elsif input =  "0101" then
	    return WALSH_05;
	elsif input =  "0100" then
	    return WALSH_04;
	elsif input =  "0011" then
	    return WALSH_03;
	elsif input =  "0010" then
	    return WALSH_02;
	elsif input =  "0001" then
	    return WALSH_01;
	elsif input =  "0000" then
	    return WALSH_00;
	end if;
	return X"0000";
    end function walsh_encode;

    -- Whenever the hamming distance from a walsh code is greater than 12, we
    -- have an unambiguous match. Otherwise, return 0
    function walsh_decode (input : walsh_code_t) return walsh_sym_t is
    begin
	if calc_hamming(input, WALSH_15) > 12 then
	    return "1111";
	elsif calc_hamming(input, WALSH_14) > 12 then
	    return "1110";
	elsif calc_hamming(input, WALSH_13) > 12 then
	    return "1101";
	elsif calc_hamming(input, WALSH_12) > 12 then
	    return "1100";
	elsif calc_hamming(input, WALSH_11) > 12 then
	    return "1011";
	elsif calc_hamming(input, WALSH_10) > 12 then
	    return "1010";
	elsif calc_hamming(input, WALSH_09) > 12 then
	    return "1001";
	elsif calc_hamming(input, WALSH_08) > 12 then
	    return "1000";
	elsif calc_hamming(input, WALSH_07) > 12 then
	    return "0111";
	elsif calc_hamming(input, WALSH_06) > 12 then
	    return "0110";
	elsif calc_hamming(input, WALSH_05) > 12 then
	    return "0101";
	elsif calc_hamming(input, WALSH_04) > 12 then
	    return "0100";
	elsif calc_hamming(input, WALSH_03) > 12 then
	    return "0011";
	elsif calc_hamming(input, WALSH_02) > 12 then
	    return "0010";
	elsif calc_hamming(input, WALSH_01) > 12 then
	    return "0001";
	elsif calc_hamming(input, WALSH_00) > 12 then
	    return "0000";
	end if;
	return "0000";
    end function walsh_decode;

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

end package body numeric;
