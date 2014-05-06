library ieee;
use ieee.std_logic_1164.all;

entity c_to_vhd_tb is
end c_to_vhd_tb;
 
architecture behaviour of c_to_vhd_tb is 
 
    component fifo_tx port (
	rst : IN STD_LOGIC;
	wr_clk : IN STD_LOGIC;
	rd_clk : IN STD_LOGIC;
	din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
	wr_en : IN STD_LOGIC;
	rd_en : IN STD_LOGIC;
	dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
	full : OUT STD_LOGIC;
	almost_full : OUT STD_LOGIC;
	overflow : OUT STD_LOGIC;
	empty : OUT STD_LOGIC;
	almost_empty : OUT STD_LOGIC;
	underflow : OUT STD_LOGIC);
    end component fifo_tx;

   --Inputs
    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
    signal io_addr : std_logic_vector(7 downto 0) := (others => '0');
    signal io_d_in : std_logic_vector(31 downto 0) := (others => '0');
    signal io_addr_strobe : std_logic := '0';
    signal io_read_strobe : std_logic := '0';
    signal io_write_strobe : std_logic := '0';
    signal fifo_d_in : std_logic_vector(31 downto 0) := (others => '0');

     --Outputs
    signal io_d_out : std_logic_vector(31 downto 0);
    signal io_ready : std_logic;
    signal fifo_d_out : std_logic_vector(31 downto 0);
    signal fifo_wren : std_logic;
    signal fifo_rden : std_logic;

   -- Clock period definitions
    constant clk_period : time := 10 ns;
    
    signal full, almost_full : std_logic;
    signal overflow, underflow : std_logic;
    signal empty, almost_empty : std_logic;
 
begin
 
    -- Instantiate the Unit Under Test (UUT)
    uut: entity work.fifo_interface port map (
	clk => clk,
	reset => reset,
	io_addr => io_addr,
	io_d_in => io_d_in,
	io_d_out => io_d_out,
	io_addr_strobe => io_addr_strobe,
	io_read_strobe => io_read_strobe,
	io_write_strobe => io_write_strobe,
	io_ready => io_ready,
	fifo_d_out => fifo_d_out,
	fifo_wren => fifo_wren,
	fifo_d_in => fifo_d_in,
	fifo_rden => fifo_rden);

    tx_fifo : component fifo_tx port map (
	rst => reset,
	wr_clk => clk,
	rd_clk => clk,
	din => fifo_d_out,
	wr_en => fifo_wren,
	rd_en => fifo_rden,
	dout => fifo_d_in,
	full => full,
	almost_full => almost_full,
	overflow => overflow,
	empty => empty,
	almost_empty => almost_empty,
	underflow => underflow);
	    
	  
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

	wait for clk_period * 20.5;

	-- Set bits at address 0x01
	io_write_strobe <= '1';
	io_addr_strobe <= '1';
	io_d_in <= X"00000020";
	io_addr <= X"01";
	wait for clk_period;
	io_write_strobe <= '0';
	io_addr_strobe <= '0';
	
	wait for clk_period * 6;
	
	-- Write at address 0x00
	io_write_strobe <= '1';
	io_addr_strobe <= '1';
	io_d_in <= X"12345678";
	io_addr <= X"00";
	wait for clk_period;
	io_write_strobe <= '0';
	io_addr_strobe <= '0';
	
	wait for clk_period * 6;
	
	-- Write at address 0x00
	io_write_strobe <= '1';
	io_addr_strobe <= '1';
	io_d_in <= X"12345678";
	io_addr <= X"00";
	wait for clk_period;
	io_write_strobe <= '0';
	io_addr_strobe <= '0';
	
	wait for clk_period * 6;
	
	-- Write at address 0x00
	io_write_strobe <= '1';
	io_addr_strobe <= '1';
	io_d_in <= X"12345678";
	io_addr <= X"00";
	wait for clk_period;
	io_write_strobe <= '0';
	io_addr_strobe <= '0';
	
	wait for clk_period * 6;
	
	-- Write at address 0x00
	io_write_strobe <= '1';
	io_addr_strobe <= '1';
	io_d_in <= X"12345678";
	io_addr <= X"00";
	wait for clk_period;
	io_write_strobe <= '0';
	io_addr_strobe <= '0';
	
	wait for clk_period * 6;
	
	-- Read at address 0x00---------------------------------------------
	io_read_strobe <= '1';
	io_addr_strobe <= '1';
	wait for clk_period;
	io_read_strobe <= '0';
	io_addr_strobe <= '0';
	
	wait for clk_period * 6;
	
	 -- Write at address 0x05
	io_write_strobe <= '1';
	io_addr_strobe <= '1';
	io_addr <= X"05";
	io_d_in <= X"12345678";
	wait for clk_period;
	io_write_strobe <= '0';
	io_addr_strobe <= '0';
	
	wait for clk_period * 2;
	
	-- Read at address 0x05
	io_read_strobe <= '1';
	io_addr_strobe <= '1';
	wait for clk_period;
	io_read_strobe <= '0';
	io_addr_strobe <= '0';

	wait;
    end process;

end;
