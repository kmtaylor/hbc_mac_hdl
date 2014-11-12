library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package numeric is
    function bits_for_val(val: natural) return natural;
    function calc_hamming(slv, target : std_logic_vector) return natural;
    function phase_sum (reg : std_logic_vector; size : unsigned) return natural;
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
 
    function phase_sum  (reg : std_logic_vector; size : unsigned)
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

end package body numeric;
