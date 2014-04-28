library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity scrambler is
    port (
	clk, en, reset, seed : in std_logic;
	d_in : in std_logic;
	d_out : out std_logic);
end entity scrambler;

architecture behavioural of scrambler is

    constant SCRAMBLER_SEED_0 : std_logic_vector (31 downto 0) := X"69540152";
    constant SCRAMBLER_SEED_1 : std_logic_vector (31 downto 0) := X"8A5F621F";

    signal scram_reg : std_logic_vector (31 downto 0);
    signal tmp_bit : std_logic;

begin

    d_out <= d_in xor scram_reg(0);

    -- Polynomial is z^32 + z^31 + z^11 + 1
    tmp_bit <=	scram_reg(32 - 11) xor
		scram_reg(32 - 31) xor
		scram_reg(32 - 32);
    
    process (reset, seed, clk) begin
	if reset = '1' then
	    if seed = '1' then
		scram_reg <= SCRAMBLER_SEED_1;
	    else
		scram_reg <= SCRAMBLER_SEED_0;
	    end if;
	elsif clk'event and clk = '1' then
	    if en = '1' then
		scram_reg <= std_logic_vector(
				shift_right(unsigned(scram_reg), 1));
		scram_reg(31) <= tmp_bit;
	    end if;
	end if;
    end process;

end architecture behavioural;
