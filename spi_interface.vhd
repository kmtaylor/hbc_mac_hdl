#include <preprocessor/constants.vhh>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_interface is
    port (
	clk, reset  : in std_logic;
	io_addr	    : in std_logic_vector (7 downto 0);
	io_d_out    : out std_logic_vector (31 downto 0);
	io_addr_strobe : in std_logic;
	io_read_strobe : in std_logic;
	io_ready    : out std_logic;
	hbc_data_sclk : in std_logic;
	hbc_data_mosi : in std_logic;
	hbc_data_miso : out std_logic;
	hbc_ctrl_sclk : in std_logic;
	hbc_ctrl_mosi : in std_logic;
	hbc_ctrl_miso : out std_logic);
end spi_interface;

architecture spi_interface_arch of spi_interface is

    -- FIFO_ADDR must be word aligned
    constant SPI_DATA_ADDR : std_logic_vector (7 downto 0) :=
							HEX(SPI_DATA_ADDR);
    constant SPI_CTRL_ADDR : std_logic_vector (7 downto 0) :=
							HEX(SPI_CTRL_ADDR);
	    
    signal io_addr_reg : std_logic_vector (7 downto 0);
	
    signal enabled : std_logic;
    signal do_fifo_rden : std_logic := '0';
    signal do_ack : std_logic := '0';

begin

    spi_data : entity work.spi_slave
        generic map (
            N => 32,
            CPOL => '0',
            CPHA => '0',
            PREFETCH => 3)
        port map (
            clk_i => clk,
            spi_ssel_i => '0',
            spi_sck_i => hbc_data_sclk,
            spi_mosi_i => hbc_data_mosi,
            spi_miso_o => hbc_data_miso,
            di_req_o => open, -- FIXME
            di_i => (others => '0'), --FIXME
            wren_i => '0', -- FIXME
            wr_ack_o => open, -- FIXME
            do_valid_o => open, -- FIXME
            do_o => open); -- FIXME

    spi_cmd : entity work.spi_slave
        generic map (
            N => 8,
            CPOL => '0',
            CPHA => '0',
            PREFETCH => 3)
        port map (
            clk_i => clk,
            spi_ssel_i => '0',
            spi_sck_i => hbc_ctrl_sclk,
            spi_mosi_i => hbc_ctrl_mosi,
            spi_miso_o => hbc_ctrl_miso,
            di_req_o => open, -- FIXME
            di_i => (others => '0'), --FIXME
            wren_i => '0', -- FIXME
            wr_ack_o => open, -- FIXME
            do_valid_o => open, -- FIXME
            do_o => open); -- FIXME


    -- Get IO data
    io_proc : process(clk, reset) begin
	if reset = '1' then
	    do_fifo_rden <= '0';
	    do_ack <= '0';
	-- Read IO bus on falling edge
	elsif clk'event and clk = '0' then
	    if io_read_strobe = '1' then
		do_fifo_rden <= '1';
		do_ack <= '1';
	    else
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
		    -- FIXME: io_d_out <= fifo_d_in;
		else
		    io_ready <= '0';
		    io_d_out <= (others => 'Z');
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
	<=  '1' when SPI_DATA_ADDR,
	    '0' when others;

    fifo_enable : process (enabled, do_fifo_rden) begin
	if enabled = '1' then
	    -- FIXME: fifo_rden <= do_fifo_rden;
	    null;
	else
	    -- FIXME: fifo_rden <= '0';
	    null;
	end if;
    end process fifo_enable;

end spi_interface_arch;

