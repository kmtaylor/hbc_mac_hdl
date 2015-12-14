library ieee;
use ieee.std_logic_1164.all;

library transceiver;
use transceiver.bits.all;

entity hbc_tx is port (
    cpu_clk, cpu_reset : in std_logic;
    serial_clk, serial_reset : in std_logic;
    io_addr : in vec8_t;
    io_d_in : in vec32_t;
    io_d_out : out vec32_t;
    io_addr_strobe : in std_logic;
    io_read_strobe : in std_logic;
    io_write_strobe : in std_logic;
    io_ready_fifo : out std_logic;
    io_ready_mod : out std_logic;
    hbc_tx_fifo_flush : in std_logic;
    hbc_tx_trigger : in std_logic;
    hbc_tx_fifo_full : out std_logic;
    hbc_tx_fifo_almost_full : out std_logic;
    hbc_tx_fifo_overflow : out std_logic;
    s_data_out : out std_logic);
end entity hbc_tx;

architecture hbc_tx_arch of hbc_tx is

    COMPONENT fifo_tx
        PORT (
            rst : IN STD_LOGIC;
            wr_clk : IN STD_LOGIC;
            rd_clk : IN STD_LOGIC;
            din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            wr_en : IN STD_LOGIC;
            rd_en : IN STD_LOGIC;
            dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            full : OUT STD_LOGIC;
            prog_full : OUT STD_LOGIC;
            overflow : OUT STD_LOGIC;
            empty : OUT STD_LOGIC;
            underflow : OUT STD_LOGIC
        );
    END COMPONENT;

    signal mod_bus_master : std_logic;
    signal fifo_bus_addr : vec8_t;
    signal fifo_d_out : vec32_t;
    signal fifo_addr_strobe : std_logic;
    signal fifo_write_strobe : std_logic;
    signal fifo_io_ready : std_logic;
    signal mod_bus_addr : vec8_t;
    signal mod_d_out : vec32_t;
    signal mod_addr_strobe : std_logic;
    signal mod_write_strobe : std_logic;
    signal mod_io_ready : std_logic;

    signal to_tx_fifo : vec32_t;
    signal from_tx_fifo : vec32_t;
    signal tx_fifo_rden : std_logic;
    signal tx_fifo_wren : std_logic;
    signal tx_fifo_empty : std_logic;

begin

    bus_arb : entity work.fifo_bus_arbitrator
        port map (
            mod_bus_master => mod_bus_master,
            io_addr => io_addr (7 downto 0),
            io_d_in => io_d_in,
            io_addr_strobe => io_addr_strobe,
            io_write_strobe => io_write_strobe,
            io_io_ready => io_ready_fifo,
            mod_addr => mod_bus_addr,
            mod_d_out => mod_d_out,
            mod_addr_strobe => mod_addr_strobe,
            mod_write_strobe => mod_write_strobe,
            mod_io_ready => mod_io_ready,
            fifo_addr => fifo_bus_addr,
            fifo_d_out => fifo_d_out,
            fifo_addr_strobe => fifo_addr_strobe,
            fifo_write_strobe => fifo_write_strobe,
            fifo_io_ready => fifo_io_ready);

    modulator : entity work.modulator
        port map (
            clk => cpu_clk,
            reset => cpu_reset,
            io_addr => io_addr (7 downto 0),
            io_d_in => io_d_in,
            io_addr_strobe => io_addr_strobe,
            io_write_strobe => io_write_strobe,
            io_ready => io_ready_mod,
            bus_master => mod_bus_master,
            sub_addr_out => mod_bus_addr,
            sub_d_out => mod_d_out,
            sub_addr_strobe => mod_addr_strobe,
            sub_write_strobe => mod_write_strobe,
            sub_io_ready => mod_io_ready);

    fifo_int : entity work.tx_fifo_interface
        port map (
            clk => cpu_clk,
            reset => cpu_reset,
            trigger => hbc_tx_fifo_flush,
            io_addr => fifo_bus_addr,
            io_d_in => fifo_d_out,
            io_d_out => io_d_out,
            io_addr_strobe => fifo_addr_strobe,
            io_read_strobe => io_read_strobe,
            io_write_strobe => fifo_write_strobe,
            io_ready => fifo_io_ready,
            fifo_d_out => to_tx_fifo,
            fifo_wren => tx_fifo_wren,
            fifo_d_in => from_tx_fifo,
            -- Disabled
            fifo_rden => open);

    tx_fifo : component fifo_tx
        port map (
            rst => cpu_reset,
            wr_clk => cpu_clk,
            rd_clk => serial_clk,
            din => to_tx_fifo,
            wr_en => tx_fifo_wren,
            rd_en => tx_fifo_rden,
            dout => from_tx_fifo,
            full => hbc_tx_fifo_full,
            prog_full => hbc_tx_fifo_almost_full,
            overflow => hbc_tx_fifo_overflow,
            empty => tx_fifo_empty,
            underflow => open);

    p_to_s : entity work.parallel_to_serial
        port map (
            clk => serial_clk,
            reset => serial_reset,
            trigger => hbc_tx_trigger,
            trig_clk => cpu_clk,
            fifo_d_in => from_tx_fifo,
            fifo_rden => tx_fifo_rden,
            fifo_empty => tx_fifo_empty,
            data_out => s_data_out);

end architecture hbc_tx_arch;
