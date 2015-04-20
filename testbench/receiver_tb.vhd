#include <preprocessor/constants.vhh>

library ieee;
use ieee.std_logic_1164.all;

entity receiver_tb is
end receiver_tb;
 
architecture behaviour of receiver_tb is 
 
    component fifo_rx port (
        rst : IN STD_LOGIC;
        wr_clk : IN STD_LOGIC;
        rd_clk : IN STD_LOGIC;
        din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        wr_en : IN STD_LOGIC;
        rd_en : IN STD_LOGIC;
        dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        full : OUT STD_LOGIC;
        overflow : OUT STD_LOGIC;
        empty : OUT STD_LOGIC;
        underflow : OUT STD_LOGIC);
    end component fifo_rx;

   --Inputs
    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
    signal pkt_reset : std_logic;
    signal pkt_reset_2 : std_logic;
    signal pkt_ack : std_logic := '0';
    signal pkt_ack_2 : std_logic := '0';
    signal io_addr : std_logic_vector(7 downto 0) := (others => '0');
    signal io_d_in : std_logic_vector(31 downto 0) := (others => '0');
    signal io_addr_strobe : std_logic := '0';
    signal io_read_strobe : std_logic := '0';
    signal io_write_strobe : std_logic := '0';
    signal io_ready : std_logic;
    signal sub_io_ready : std_logic;

    signal s_data_in, s_data_sync : std_logic;
    signal s_data_in_2, s_data_sync_2 : std_logic;
    signal serial_clk : std_logic;
    signal serial_clk_90 : std_logic;
    signal s2p_full, s2p_overflow, s2p_empty, s2p_underflow : std_logic;
    signal s2p_fifo_wren : std_logic;
    signal s2p_fifo_wren_2 : std_logic;
    signal s2p_fifo_data : std_logic_vector (31 downto 0);
    signal s2p_fifo_data_2 : std_logic_vector (31 downto 0);
    signal s2p_fifo_full : std_logic;
    signal s2p_fifo_full_2 : std_logic;
    signal s2p_fifo_rden : std_logic;
    signal s2p_from_fifo : std_logic_vector (31 downto 0);
    signal rx_fifo_data : std_logic_vector (31 downto 0);
    signal rx_fifo_io_ready : std_logic;
 
    -- Clock period definitions
    constant clk_period : time := 10 ns;
    constant s_clk_period : time := 24 ns;
    
    type val_ft is file of std_logic;
    type time_ft is file of time;
    file val_file : val_ft open READ_MODE is "spice_channel.value";
    file val_file_2 : val_ft open READ_MODE is "receiver_tb_stim.value";
    file time_file : time_ft open READ_MODE is "spice_channel.time";
    file time_file_2 : time_ft open READ_MODE is "receiver_tb_stim.time";

    function read_time return time is 
	variable val : time;
    begin
	read(time_file, val);
	return val;
    end function read_time;

    function read_time_2 return time is 
	variable val : time;
    begin
	read(time_file_2, val);
	return val;
    end function read_time_2;

    function read_data return std_logic is
	variable val : std_logic;
    begin
	read(val_file, val);
	return val;
    end function read_data;

    function read_data_2 return std_logic is
	variable val : std_logic;
    begin
	read(val_file_2, val);
	return val;
    end function read_data_2;

    function data_available return boolean is begin
	return not endfile(val_file);
    end function data_available;

    function data_available_2 return boolean is begin
	return not endfile(val_file_2);
    end function data_available_2;

begin
 
    sync : entity work.data_synchroniser port map (
	reset => pkt_reset,
	serial_clk => serial_clk,
	serial_clk_90 => serial_clk_90,
	data_in => s_data_in,
	data_out => s_data_sync);

    s_to_p : entity work.serial_to_parallel port map (
	reset_i => reset,
	pkt_reset => pkt_reset,
	serial_clk => serial_clk,
	fifo_d_out => s2p_fifo_data,
	fifo_wren => s2p_fifo_wren,
	fifo_full => s2p_fifo_full,
	data_in => s_data_sync,
	pkt_ack => pkt_ack);

    sync_2 : entity work.data_synchroniser port map (
	reset => pkt_reset_2,
	serial_clk => serial_clk,
	serial_clk_90 => serial_clk_90,
	data_in => s_data_in_2,
	data_out => s_data_sync_2);

    s_to_p_2 : entity work.serial_to_parallel port map (
	reset_i => reset,
	pkt_reset => pkt_reset_2,
	serial_clk => serial_clk,
	fifo_d_out => s2p_fifo_data_2,
	fifo_wren => s2p_fifo_wren_2,
	fifo_full => s2p_fifo_full_2,
	data_in => s_data_sync_2,
	pkt_ack => pkt_ack_2);

    rx_fifo : component fifo_rx port map (
        rst => reset,
        wr_clk => serial_clk,
        rd_clk => clk,
        din => s2p_fifo_data,
        wr_en => s2p_fifo_wren,
        rd_en => s2p_fifo_rden,
        dout => s2p_from_fifo,
        full => s2p_full,
        overflow => s2p_overflow,
        empty => s2p_empty,
        underflow => s2p_underflow);

    rx_fifo_int : entity work.rx_fifo_interface port map (
            clk => clk,
            reset => reset,
            io_addr => io_addr,
            io_d_out => rx_fifo_data,
            io_addr_strobe => io_addr_strobe,
            io_read_strobe => io_read_strobe,
            io_ready => rx_fifo_io_ready,
            fifo_d_in => s2p_from_fifo,
            fifo_rden => s2p_fifo_rden); 

    -- Clock process definitions
    clk_process : process begin
	clk <= '0';
	wait for clk_period/2;
	clk <= '1';
	wait for clk_period/2;
    end process;

    s_clk_process : process begin
	serial_clk <= '0';
	wait for s_clk_period/2;
	serial_clk <= '1';
	wait for s_clk_period/2;
    end process;

    serial_clk_90 <= serial_clk after s_clk_period/4;

    data_process : process
	variable prev_wait : time := 0 ns;
	variable next_wait : time;
    begin
	if not data_available then
	    wait;
	end if;
	next_wait := read_time;
	s_data_in <= read_data;
	wait for (next_wait - prev_wait);
	prev_wait := next_wait;
    end process;

    data_process_2 : process
	variable prev_wait : time := 0 ns;
	variable next_wait : time;
    begin
	if not data_available_2 then
	    wait;
	end if;
	next_wait := read_time_2;
	s_data_in_2 <= read_data_2;
	wait for (next_wait - prev_wait);
	prev_wait := next_wait;
    end process;

    -- Stimulus process
    stim_proc: process begin	
	-- hold reset state for 60 ns.
	reset <= '1';
	wait for 60 ns;
	reset <= '0';

	wait for clk_period * 5.5;

#define READ_RX_FIFO()			    \
	io_read_strobe <= '1';		    \
	io_addr_strobe <= '1';		    \
	io_addr <= HEX(RX_FIFO_ADDR);	    \
	wait for clk_period;		    \
	io_read_strobe <= '0';		    \
	io_addr_strobe <= '0';		    \
	wait for clk_period * 3;

	wait;
    end process;

end;
