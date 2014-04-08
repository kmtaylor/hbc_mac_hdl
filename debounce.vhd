
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity debounce is
	port (
		clk : in std_logic;
		d_in : in std_logic;
		q_out : out std_logic);
end debounce;

architecture Behavioral of debounce is
	
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

end Behavioral;