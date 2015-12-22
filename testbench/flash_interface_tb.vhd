library ieee;
use ieee.std_logic_1164.all;

entity flash_interface_tb is
end flash_interface_tb;
 
architecture testbench of flash_interface_tb is 
 
   --Inputs
    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
    signal io_addr : std_logic_vector(7 downto 0) := (others => '0');
    signal io_d_in : std_logic_vector(31 downto 0) := (others => '0');
    signal io_d_out : std_logic_vector(31 downto 0) := (others => '0');
    signal io_addr_strobe : std_logic := '0';
    signal io_read_strobe : std_logic := '0';
    signal io_write_strobe : std_logic := '0';
    signal io_ready : std_logic;

    --Outputs
    signal flash_sclk : std_logic;
    signal flash_mosi : std_logic;
    signal flash_miso : std_logic := '1';
    signal flash_ss : std_logic;
 
    -- Clock period definitions
    constant clk_period : time := 10 ns;
    
begin
 
    -- Instantiate the Unit Under Test (UUT)
    uut: entity work.flash_interface port map (
	cpu_clk => clk,
	reset => reset,
	io_addr => io_addr,
	io_d_in => io_d_in,
	io_d_out => io_d_out,
	io_addr_strobe => io_addr_strobe,
	io_write_strobe => io_write_strobe,
	io_read_strobe => io_read_strobe,
	io_ready => io_ready,
	flash_sclk => flash_sclk,
	flash_mosi => flash_mosi,
	flash_miso => flash_miso,
	flash_ss => flash_ss);

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

	-- Wrong address
	io_write_strobe <= '1';
	io_addr_strobe <= '1';
	io_d_in <= X"00000001";
	io_addr <= X"19";
	wait for clk_period;
	io_write_strobe <= '0';
	io_addr_strobe <= '0';

	wait for clk_period * 6;
	
	-- Write data
	io_write_strobe <= '1';
	io_addr_strobe <= '1';
	io_d_in <= X"12345678";
	io_addr <= X"28";
	wait for clk_period;
	io_write_strobe <= '0';
	io_addr_strobe <= '0';

	wait until io_ready = '1';
	wait until io_ready = '0';
	wait until clk = '1';
	
	-- Read data (wrong address)
	io_read_strobe <= '1';
	io_addr_strobe <= '1';
	io_addr <= X"28";
	wait for clk_period;
	io_read_strobe <= '0';
	io_addr_strobe <= '0';

	wait for clk_period * 6;

	-- Write data
	io_write_strobe <= '1';
	io_addr_strobe <= '1';
	io_addr <= X"28";
	wait for clk_period;
	io_write_strobe <= '0';
	io_addr_strobe <= '0';

	wait until io_ready = '1';
	wait until io_ready = '0';
	wait until clk = '1';
	
	-- Read data (wrong address)
	io_read_strobe <= '1';
	io_addr_strobe <= '1';
	io_addr <= X"28";
	wait for clk_period;
	io_read_strobe <= '0';
	io_addr_strobe <= '0';
	wait;
    end process;

end;
