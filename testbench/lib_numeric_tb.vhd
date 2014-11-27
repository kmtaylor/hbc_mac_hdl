use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library transceiver;
use transceiver.numeric.all;

entity numeric_tb is
end numeric_tb;
 
architecture test of numeric_tb is 
 
begin

#if 0
    process
	variable l : line;
	variable w_code_1 : walsh_code_t;
	variable w_code_2 : walsh_code_t;
	variable w_sym : walsh_sym_t;
	variable distance : natural;
    begin
	for j in 0 to 15 loop
	    w_sym := std_logic_vector(to_unsigned(j, 4));
	    w_code_1 := X"9549"; --walsh_encode(w_sym);

	    for i in 0 to 15 loop
		w_sym := std_logic_vector(to_unsigned(i, 4));
		w_code_2 := walsh_encode(w_sym);

		distance := calc_hamming(w_code_1, w_code_2);

		write(l, distance);
		writeline(output, l);
	    end loop;
	    write(l, string'("Next..."));
	    writeline(output, l);
	end loop;

	wait;
    end process;
#endif

    process
	variable l : line;
    begin
	write(l, string'("bits_for_val(15) = "));
	write(l, bits_for_val(16));
	writeline(output, l);
	wait;
    end process;

end;
