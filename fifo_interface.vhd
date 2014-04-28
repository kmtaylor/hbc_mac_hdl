
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fifo_interface is
	port (
		clk, reset : in std_logic;
		io_addr	: in std_logic_vector (7 downto 0);
		io_d_in	: in std_logic_vector (31 downto 0);
		io_d_out	: out std_logic_vector (31 downto 0);
		io_addr_strobe : in std_logic;
		io_read_strobe, io_write_strobe : in std_logic;
		io_ready : out std_logic;
		fifo_d_out : out std_logic_vector (31 downto 0);
		fifo_wren : out std_logic;
		fifo_d_in : in std_logic_vector (31 downto 0);
		fifo_rden : out std_logic);
end fifo_interface;

architecture Behavioral of fifo_interface is

	-- FIFO_ADDR must be word aligned
	constant FIFO_ADDR	: std_logic_vector (7 downto 0) := X"00";
			
	signal io_addr_reg : std_logic_vector (7 downto 0);
		
	signal enabled : std_logic := '0';
	signal do_fifo_wren : std_logic := '0';
	signal do_fifo_rden : std_logic := '0';
	signal do_ack : std_logic := '0';
	signal reading : std_logic := '0';

begin
	-- Get IO data
	io_proc : process(clk, reset) begin
		if reset = '1' then
			fifo_d_out <= (others => '0');
			do_fifo_wren <= '0';
			do_fifo_rden <= '0';
			do_ack <= '0';
		-- Read IO bus on falling edge
		elsif clk'event and clk = '0' then
			if io_write_strobe = '1' then
				fifo_d_out <= io_d_in;
				do_fifo_wren <= '1';
				do_ack <= '1';
				reading <= '0';
			elsif io_read_strobe = '1' then
				do_fifo_rden <= '1';
				do_ack <= '1';
				reading <= '1';
			else
				do_fifo_wren <= '0';
				do_fifo_rden <= '0';
				do_ack <= '0';
			end if;
		end if;
	end process io_proc;
	
	-- ACK process
	ack_proc : process(clk, reset) begin
		if reset = '1' then
			io_ready <= '0';
			io_d_out <= (others => 'Z');
		elsif clk'event and clk = '0' then
			if enabled = '1' then
				if do_ack = '1' then
					io_ready <= '1';
					if reading = '1' then
						io_d_out <= fifo_d_in;
					end if;
				else
					io_ready <= '0';
					if reading = '1' then
						io_d_out <= (others => 'Z');
					end if;
				end if;
			end if;
		end if;
	end process ack_proc;
	
	-- Get address from IO bus
	get_io_addr : process(clk, reset) begin
		if reset = '1' then
			io_addr_reg <= (others => '0');
		elsif clk'event and clk = '0' then
			if io_addr_strobe = '1' then
				io_addr_reg <= io_addr;
			end if;
		end if;
	end process get_io_addr;
	
	-- Assert enabled
	with io_addr_reg (7 downto 0) select enabled
		<=	'1' when FIFO_ADDR,
			'0' when others;
			
	fifo_enable : process (enabled, do_fifo_wren, do_fifo_rden) begin
		if enabled = '1' then
			fifo_wren <= do_fifo_wren;
			fifo_rden <= do_fifo_rden;
		else
			fifo_wren <= '0';
			fifo_rden <= '0';
		end if;
	end process fifo_enable;

end Behavioral;

