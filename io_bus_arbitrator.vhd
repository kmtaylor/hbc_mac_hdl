
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity io_bus_arbitrator is
	port (
		io_d_out		: out std_logic_vector (31 downto 0);
		io_ready		: out std_logic;
		
		bus1_d_in	: in std_logic_vector (31 downto 0);
		bus1_ready	: in std_logic;
		
		bus2_d_in	: in std_logic_vector (31 downto 0);
		bus2_ready	: in std_logic;
		
		bus3_d_in	: in std_logic_vector (31 downto 0);
		bus3_ready	: in std_logic);
end io_bus_arbitrator;

architecture Behavioral of io_bus_arbitrator is

begin

	process(bus1_ready, bus1_d_in,
		bus2_ready, bus2_d_in,
		bus3_ready, bus3_d_in) begin
		if bus1_ready = '1' then
			io_d_out <= bus1_d_in;
			io_ready <= '1';
		elsif bus2_ready = '1' then
			io_d_out <= bus2_d_in;
			io_ready <= '1';
		elsif bus3_ready = '1' then
			io_d_out <= bus3_d_in;
			io_ready <= '1';
		else
			io_d_out <= (others => 'Z');
			io_ready <= '0';
		end if;
	end process;
	
end Behavioral;

