library ieee;
use ieee.std_logic_1164.all;

entity modulator_tb is
end modulator_tb;
 
architecture behaviour of modulator_tb is 
 
   --Inputs
    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
    signal io_addr : std_logic_vector(7 downto 0) := (others => '0');
    signal io_d_in : std_logic_vector(31 downto 0) := (others => '0');
    signal io_addr_strobe : std_logic := '0';
    signal io_read_strobe : std_logic := '0';
    signal io_write_strobe : std_logic := '0';
    signal io_ready : std_logic;
    signal sub_io_ready : std_logic;

    --Outputs
    signal sub_addr_out: std_logic_vector (7 downto 0);
    signal sub_d_out   : std_logic_vector (31 downto 0);
    signal sub_addr_strobe : std_logic;
    signal sub_write_strobe : std_logic;
    signal bus_master : std_logic;

    -- FIFO
    signal fifo_d_out : std_logic_vector (31 downto 0);
    signal fifo_wren, fifo_rden : std_logic;
 
    -- Clock period definitions
    constant clk_period : time := 10 ns;
    
begin
 
    -- Instantiate the Unit Under Test (UUT)
    uut: entity work.modulator port map (
	clk => clk,
	reset => reset,
	io_addr => io_addr,
	io_d_in => io_d_in,
	io_addr_strobe => io_addr_strobe,
	io_write_strobe => io_write_strobe,
	io_ready => io_ready,
	bus_master => bus_master,
	sub_addr_out => sub_addr_out,
	sub_d_out => sub_d_out,
	sub_addr_strobe => sub_addr_strobe,
	sub_write_strobe => sub_write_strobe,
	sub_io_ready => sub_io_ready);

    resp_unit : entity work.fifo_interface port map (
	clk => clk,
	reset => reset,
	trigger => '0',
	io_addr => sub_addr_out,
	io_d_in => sub_d_out,
	io_d_out => open,
	io_addr_strobe => sub_addr_strobe,
	io_read_strobe => '0',
	io_write_strobe => sub_write_strobe,
	io_ready => sub_io_ready,
	fifo_d_out => fifo_d_out,
	fifo_d_in => (others => '0'),
	fifo_wren => fifo_wren,
	fifo_rden => fifo_rden);

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

	wait for clk_period * 6;
	
	-- Set bits at address 0x01
	io_write_strobe <= '1';
	io_addr_strobe <= '1';
	io_d_in <= X"12345678";
	io_addr <= X"18";
	wait for clk_period;
	io_write_strobe <= '0';
	io_addr_strobe <= '0';
	
	wait;
    end process;

end;
