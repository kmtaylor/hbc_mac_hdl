
library ieee;
use ieee.std_logic_1164.all;

entity fifo_bus_arbitrator is
	port (	mod_bus_master	: in std_logic;
		
		io_addr    : in std_logic_vector (7 downto 0);
        	io_d_out   : in std_logic_vector (31 downto 0);
        	io_addr_strobe : in std_logic;
        	io_write_strobe : in std_logic;
        	io_io_ready : out std_logic;

		mod_addr    : in std_logic_vector (7 downto 0);
        	mod_d_out   : in std_logic_vector (31 downto 0);
        	mod_addr_strobe : in std_logic;
        	mod_write_strobe : in std_logic;
        	mod_io_ready : out std_logic;

		fifo_addr    : out std_logic_vector (7 downto 0);
        	fifo_d_out   : out std_logic_vector (31 downto 0);
        	fifo_addr_strobe : out std_logic;
        	fifo_write_strobe : out std_logic;
        	fifo_io_ready : in std_logic);
end fifo_bus_arbitrator;

architecture fifo_bus_arbitrator_arch of fifo_bus_arbitrator is

begin

	process(mod_bus_master, mod_addr, mod_d_out, mod_addr_strobe,
			mod_write_strobe, fifo_io_ready, io_addr,
			io_d_out, io_addr_strobe, io_write_strobe) begin
		if mod_bus_master = '1' then
			fifo_addr <= mod_addr;
			fifo_d_out <= mod_d_out;
			fifo_addr_strobe <= mod_addr_strobe;
			fifo_write_strobe <= mod_write_strobe;
			mod_io_ready <= fifo_io_ready;
			io_io_ready <= '0';
		else
			fifo_addr <= io_addr;
			fifo_d_out <= io_d_out;
			fifo_addr_strobe <= io_addr_strobe;
			fifo_write_strobe <= io_write_strobe;
			mod_io_ready <= '0';
			io_io_ready <= fifo_io_ready;
		end if;
	end process;
	
end fifo_bus_arbitrator_arch;

