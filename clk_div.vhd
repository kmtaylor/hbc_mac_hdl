
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clock_divider is
	port (
		clk : in std_logic;
		clk_div : out std_logic);
end clock_divider;

architecture Behavioral of clock_divider is

    signal counter : integer := 0;
    signal clk_div_i : std_logic := '0';

    constant LIMIT : integer := 10E3;
	
begin

    process (clk) begin
	if clk'event and clk = '1' then

	    clk_div_i <= clk_div_i;
	    counter <= counter + 1;

	    if counter = LIMIT then
		clk_div_i <= not(clk_div_i);
		counter <= 0;
	    end if;

	end if;
    end process;

    clk_div <= clk_div_i;

end Behavioral;
