library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cho_demod is
    port (
	data, clk : in std_logic;
	output : out std_logic);
end entity cho_demod;

architecture cho_demod_arch of cho_demod is

    constant delay : time := 3 ns;

    signal ff_1, ff_2 : std_logic;
    signal ff_1_n, ff_2_n : std_logic;
    signal t_1, t_2 : std_logic;
    signal b_1, b_2 : std_logic;

    signal clk_delay : std_logic;

begin

    clk_delay <= clk after delay;

    ff_1_proc : process (clk_delay) begin
	if clk_delay'event and clk_delay = '1' then
	    ff_1 <= data;
	end if;
    end process ff_1_proc;

    ff_2_proc : process (clk_delay) begin
	if clk_delay'event and clk_delay = '1' then
	    ff_2 <= ff_1;
	end if;
    end process ff_2_proc;

    ff_1_n <= not ff_1;
    ff_2_n <= not ff_2;

    t_1 <= ff_1_n and ff_2_n;
    b_1 <= ff_1_n nor ff_2_n;

    t_2 <= t_1 nor b_2;
    b_2 <= b_1 nor t_2;

    output <= t_2;

end architecture cho_demod_arch;
