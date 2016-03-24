-- ghdl_flags: --stop-time=100ns --wave=clk_div_tb.ghw
-- ghdl_deps: clk_div.vhd

library ieee;
use ieee.std_logic_1164.all;
 
entity clk_div_tb is
end entity clk_div_tb;
 
architecture testbench of clk_div_tb is

    constant clk_period : time := 1 ns;
    
    signal clk, clk_div : std_logic;

begin 

    uut: entity work.clock_divider
	generic map (DIV_BY => 8)
	port map (
	    clk => clk,
	    clk_div => clk_div);
		  
   -- Clock process definitions
    clk_process: process begin
	clk <= '0';
	wait for clk_period/2;
	clk <= '1';
	wait for clk_period/2;
    end process;

    -- Stimulus process
    stim_proc: process begin		
	
	wait;
   end process;

end architecture testbench;
