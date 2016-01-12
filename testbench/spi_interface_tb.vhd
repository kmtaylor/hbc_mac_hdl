library ieee;
use ieee.std_logic_1164.all;

entity spi_interface_tb is
end spi_interface_tb;
 
architecture testbench of spi_interface_tb is 
 
   -- CPU
    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
    signal io_addr : std_logic_vector(7 downto 0) := (others => '0');
    signal io_d_in : std_logic_vector(31 downto 0) := (others => '0');
    signal io_d_out : std_logic_vector(31 downto 0) := (others => '0');
    signal io_addr_strobe : std_logic := '0';
    signal io_read_strobe : std_logic := '0';
    signal io_write_strobe : std_logic := '0';
    signal io_ready : std_logic;


    signal hbc_data_int : std_logic;
    signal hbc_ctrl_int : std_logic;
    signal hbc_data_sclk : std_logic := '0';
    signal hbc_data_mosi : std_logic;
    signal hbc_data_miso : std_logic;
    signal hbc_data_ss : std_logic := '1';
    signal hbc_ctrl_sclk : std_logic := '0';
    signal hbc_ctrl_mosi : std_logic;
    signal hbc_ctrl_miso : std_logic;
    signal hbc_ctrl_ss : std_logic := '1';
 
    -- Clock period definitions
    constant clk_period : time := 10 ns;
    
begin
 
    -- Instantiate the Unit Under Test (UUT)
    uut: entity work.spi_interface port map (
	clk => clk,
	reset => reset,
	io_addr => io_addr,
	io_d_in => io_d_in,
	io_d_out => io_d_out,
	io_addr_strobe => io_addr_strobe,
	io_write_strobe => io_write_strobe,
	io_read_strobe => io_read_strobe,
	io_ready => io_ready,
	hbc_data_int => hbc_data_int,
	hbc_ctrl_int => hbc_ctrl_int,
	hbc_data_sclk => hbc_data_sclk,
	hbc_data_mosi => hbc_data_mosi,
	hbc_data_miso => hbc_data_miso,
	hbc_data_ss => hbc_data_ss,
	hbc_ctrl_sclk => hbc_ctrl_sclk,
	hbc_ctrl_mosi => hbc_ctrl_mosi,
	hbc_ctrl_miso => hbc_ctrl_miso,
	hbc_ctrl_ss => hbc_ctrl_ss);

    -- Clock process definitions
    clk_process : process begin
	clk <= '0';
	wait for clk_period/2;
	clk <= '1';
	wait for clk_period/2;
    end process;

    -- Stimulus process
    stim_proc: process begin	
	-- hold reset state for 20 ns.
	reset <= '1';
	wait for 20 ns;
	reset <= '0';

	wait for clk_period * 5.5;

	-- Set SF
	io_write_strobe <= '1';
	io_addr_strobe <= '1';
	io_d_in <= X"00000001";
	io_addr <= X"19";
	wait for clk_period;
	io_write_strobe <= '0';
	io_addr_strobe <= '0';

	wait for clk_period * 16;
	
	-- Set bits at address 0x01
	io_write_strobe <= '1';
	io_addr_strobe <= '1';
	io_d_in <= X"00008112";
	io_addr <= X"26";
	wait for clk_period;
	io_write_strobe <= '0';
	io_addr_strobe <= '0';
	
#if 0
	wait for clk_period * 30;
	
	-- Set bits at address 0x01
	io_write_strobe <= '1';
	io_addr_strobe <= '1';
	io_d_in <= X"00008115";
	io_addr <= X"26";
	wait for clk_period;
	io_write_strobe <= '0';
	io_addr_strobe <= '0';
#endif
	
	wait;
    end process;

    spi_proc : process begin
	wait for 200 ns;
	hbc_ctrl_ss <= '0';
	wait for 20 ns;
	hbc_ctrl_sclk <= '1';
	wait for 20 ns;
	hbc_ctrl_sclk <= '0';
	wait for 20 ns;
	hbc_ctrl_sclk <= '1';
	wait for 20 ns;
	hbc_ctrl_sclk <= '0';
	wait for 20 ns;
	hbc_ctrl_sclk <= '1';
	wait for 20 ns;
	hbc_ctrl_sclk <= '0';
	wait for 20 ns;
	hbc_ctrl_sclk <= '1';
	wait for 20 ns;
	hbc_ctrl_sclk <= '0';
	wait for 20 ns;
	hbc_ctrl_sclk <= '1';
	wait for 20 ns;
	hbc_ctrl_sclk <= '0';
	wait for 20 ns;
	hbc_ctrl_sclk <= '1';
	wait for 20 ns;
	hbc_ctrl_sclk <= '0';
	wait for 20 ns;
	hbc_ctrl_sclk <= '1';
	wait for 20 ns;
	hbc_ctrl_sclk <= '0';
	wait for 20 ns;
	hbc_ctrl_sclk <= '1';
	wait for 20 ns;
	hbc_ctrl_sclk <= '0';

	wait for 20 ns;
	hbc_ctrl_sclk <= '1';
	wait for 20 ns;
	hbc_ctrl_sclk <= '0';
	wait for 20 ns;
	hbc_ctrl_sclk <= '1';
	wait for 20 ns;
	hbc_ctrl_sclk <= '0';
	wait for 20 ns;
	hbc_ctrl_sclk <= '1';
	wait for 20 ns;
	hbc_ctrl_sclk <= '0';
	wait for 20 ns;
	hbc_ctrl_sclk <= '1';
	wait for 20 ns;
	hbc_ctrl_sclk <= '0';
	wait for 20 ns;
	hbc_ctrl_sclk <= '1';
	wait for 20 ns;
	hbc_ctrl_sclk <= '0';
	wait for 20 ns;
	hbc_ctrl_sclk <= '1';
	wait for 20 ns;
	hbc_ctrl_sclk <= '0';
	wait for 20 ns;
	hbc_ctrl_sclk <= '1';
	wait for 20 ns;
	hbc_ctrl_sclk <= '0';
	wait for 20 ns;
	hbc_ctrl_sclk <= '1';
	wait for 20 ns;
	hbc_ctrl_sclk <= '0';

	wait for 20 ns;
	hbc_ctrl_sclk <= '1';
	wait for 20 ns;
	hbc_ctrl_sclk <= '0';
	wait for 20 ns;
	hbc_ctrl_sclk <= '1';
	wait for 20 ns;
	hbc_ctrl_sclk <= '0';
	wait for 20 ns;
	hbc_ctrl_sclk <= '1';
	wait for 20 ns;
	hbc_ctrl_sclk <= '0';
	wait for 20 ns;
	hbc_ctrl_sclk <= '1';
	wait for 20 ns;
	hbc_ctrl_sclk <= '0';
	wait for 20 ns;
	hbc_ctrl_sclk <= '1';
	wait for 20 ns;
	hbc_ctrl_sclk <= '0';
	wait for 20 ns;
	hbc_ctrl_sclk <= '1';
	wait for 20 ns;
	hbc_ctrl_sclk <= '0';
	wait for 20 ns;
	hbc_ctrl_sclk <= '1';
	wait for 20 ns;
	hbc_ctrl_sclk <= '0';
	wait for 20 ns;
	hbc_ctrl_sclk <= '1';
	wait for 20 ns;
	hbc_ctrl_sclk <= '0';

	wait for 20 ns;
	hbc_ctrl_ss <= '1';

	wait;
    end process;




end;
