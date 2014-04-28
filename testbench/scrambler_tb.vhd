library ieee;
use ieee.std_logic_1164.all;
 
entity scrambler_tb is
end entity scrambler_tb;
 
architecture behaviour of scrambler_tb is

    constant clk_period : time := 10 ns;
    signal clk, en, reset, seed, d_in, d_out : std_logic;

begin 

    uut: entity work.scrambler
	port map (
	    clk => clk,
	    en => en,
	    reset => reset,
	    seed => seed,
	    d_in => d_in,
	    d_out => d_out);
		  
   -- Clock process definitions
    clk_process: process begin
	clk <= '0';
	wait for clk_period/2;
	clk <= '1';
	wait for clk_period/2;
    end process;

    -- Stimulus process
    stim_proc: process begin		
	reset <= '1';
	wait for clk_period * 2;	
	reset <= '0';
	wait for clk_period * 3;

	d_in <= '1';
	en <= '1';
	seed <= '0';
	
	wait;
   end process;

end architecture behaviour;
