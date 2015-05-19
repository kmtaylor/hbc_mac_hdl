#include <preprocessor/constants.vhh>
#include "send_packet.vhh"

#ifndef SERIAL_CLK_NS
#define SERIAL_CLK_NS 24
#endif

#ifndef STIMULUS
#define STIMULUS 1
#endif

library ieee;
use ieee.std_logic_1164.all;

entity transmitter_stim_tb is
end transmitter_stim_tb;
 
architecture behaviour of transmitter_stim_tb is 
 
   --Inputs
    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
    signal io_addr : std_logic_vector(7 downto 0) := (others => '0');
    signal io_d_in : std_logic_vector(31 downto 0) := (others => '0');
    signal io_addr_strobe : std_logic := '0';
    signal io_write_strobe : std_logic := '0';
    signal io_ready : std_logic;

    signal fi_addr : std_logic_vector (7 downto 0) := (others => '0');
    signal fi_d : std_logic_vector (31 downto 0) := (others => '0');
    signal fi_addr_strobe : std_logic := '0';
    signal fi_write_strobe : std_logic := '0';
    signal prog_full : std_logic;

    signal serial_clk, parallel_to_serial_enable : std_logic;
    signal s_data_out : std_logic;

    -- Clock period definitions
    constant clk_period : time := 10 ns;
    constant s_clk_period : time := SERIAL_CLK_NS ns;
    
begin
 
    -- Instantiate the Unit Under Test (UUT)
    transmitter_tb: entity work.transmitter_tb port map (
	clk => clk,
	reset => reset,
	io_addr => io_addr,
	io_d_in => io_d_in,
	io_addr_strobe => io_addr_strobe,
	io_write_strobe => io_write_strobe,
	io_ready => io_ready,
	fi_addr_strobe => fi_addr_strobe,
	fi_write_strobe => fi_write_strobe,
	fi_addr => fi_addr,
	fi_d => fi_d,
	prog_full => prog_full,
	parallel_to_serial_enable => parallel_to_serial_enable,
	serial_clk => serial_clk,
	s_data_out => s_data_out);

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

    -- Stimulus process
    stim_proc: process begin	
	-- hold reset state for 60 ns.
	reset <= '1';
	parallel_to_serial_enable <= '0';
	wait for 60 ns;
	reset <= '0';

	wait for clk_period * 5.5;

	-- Trigger P2S
#if STIMULUS
	TRIGGER()
	SEND_PACKET()
#endif

	wait;
    end process;

end;
