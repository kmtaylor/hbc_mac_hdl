#include <preprocessor/constants.vhh>

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity toplevel is
    port(
	sw : in std_logic_vector (7 downto 0);
	Led : out std_logic_vector (7 downto 0);
	LCDD : inout std_logic_vector (7 downto 0);
	LCDEN, LCDRW, LCDRS : out std_logic;
	clkin, rstbtn, btn1, btn2 : in std_logic;
	serial_clk_out : out std_logic;
	s_data_out : out std_logic;
	s_data_in : in std_logic;
	-- Physical memory interface
	ddr2_dq	    : inout std_logic_vector (63 downto 0);
	ddr2_a	    : out std_logic_vector (12 downto 0);
	ddr2_ba	    : out std_logic_vector (1 downto 0);
	ddr2_ras_n  : out std_logic;
	ddr2_cas_n  : out std_logic;
	ddr2_we_n   : out std_logic;
	ddr2_cs_n   : out std_logic_vector (0 downto 0);
	ddr2_odt    : out std_logic_vector (0 downto 0);
	ddr2_cke    : out std_logic_vector (0 downto 0);
	ddr2_dm	    : out std_logic_vector (7 downto 0);
	ddr2_dqs    : inout std_logic_vector (7 downto 0);
	ddr2_dqs_n  : inout std_logic_vector (7 downto 0);
	ddr2_ck	    : out std_logic_vector (1 downto 0);
	ddr2_ck_n   : out std_logic_vector (1 downto 0);
	-- USB Interface
	UsbClk	    : in std_logic;
	UsbEN	    : in std_logic;
	UsbEmpty    : in std_logic;
	UsbFull	    : in std_logic;
	UsbOE	    : out std_logic;
	UsbAdr	    : out std_logic_vector (1 downto 0);
	UsbWR	    : out std_logic;
	UsbRD	    : out std_logic;
	UsbPktEnd   : out std_logic;
	UsbDB	    : inout std_logic_vector (7 downto 0)
	);
end toplevel;

architecture toplevel_arch of toplevel is

    COMPONENT mcs_0
	PORT (
	    Clk : IN STD_LOGIC;
	    Reset : IN STD_LOGIC;
	    IO_Addr_Strobe : OUT STD_LOGIC;
	    IO_Read_Strobe : OUT STD_LOGIC;
	    IO_Write_Strobe : OUT STD_LOGIC;
	    IO_Address : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
	    IO_Write_Data : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
	    IO_Read_Data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
	    IO_Ready : IN STD_LOGIC;
	    GPO1 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	    GPO2 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	    GPI1 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
	    GPI2 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
	    INTC_Interrupt : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
    END COMPONENT;
    
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

    COMPONENT fifo_rx
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

    signal io_read_strobe, io_write_strobe : std_logic;
    signal io_ready, io_addr_strobe : std_logic;
    signal io_address : std_logic_vector (31 downto 0);
    signal io_write_data : std_logic_vector (31 downto 0);
    signal io_read_data : std_logic_vector (31 downto 0);

    signal clk_lock_int : std_logic;
    signal usb_irq : std_logic;
    
    signal bus1_data : std_logic_vector (31 downto 0);
    signal bus1_ready : std_logic;
    signal bus2_data : std_logic_vector (31 downto 0);
    signal bus2_ready : std_logic;
    signal bus3_data : std_logic_vector (31 downto 0);
    signal bus3_ready : std_logic;
    signal bus4_data : std_logic_vector (31 downto 0);
    signal bus4_ready : std_logic;
    signal bus5_data : std_logic_vector (31 downto 0);
    signal bus5_ready : std_logic;
    signal bus6_ready : std_logic;
    signal bus7_data : std_logic_vector (31 downto 0);
    signal bus7_ready : std_logic;
    
    -- Internal memory signals
    signal phy_init_done    : std_logic;
    signal mem_fifo_full    : std_logic;
    signal rst0_tb	: std_logic;
    signal clk0_tb	: std_logic;
    signal app_wdf_afull    : std_logic;
    signal app_af_afull    : std_logic;
    signal rd_data_valid    : std_logic;
    signal app_rdf_rden    : std_logic;
    signal app_wdf_wren    : std_logic;
    signal app_af_wren    : std_logic;
    signal app_af_addr    : std_logic_vector (30 downto 0);
    signal app_af_cmd    : std_logic_vector (2 downto 0);
    signal rd_data_fifo_out    : std_logic_vector (127 downto 0);
    signal app_wdf_data    : std_logic_vector (127 downto 0);
    signal app_wdf_mask_data : std_logic_vector (15 downto 0);
    
    signal to_tx_fifo : std_logic_vector (31 downto 0);
    signal from_tx_fifo : std_logic_vector (31 downto 0);
    signal tx_fifo_rden : std_logic;
    signal tx_fifo_wren : std_logic;
    signal tx_fifo_full : std_logic;
    signal tx_fifo_almost_full : std_logic;
    signal tx_fifo_overflow : std_logic;
    signal tx_fifo_empty : std_logic;
    signal tx_fifo_underflow : std_logic;
    signal tx_fifo_flush : std_logic;

    signal from_rx_fifo : std_logic_vector (31 downto 0);
    signal rx_fifo_rden : std_logic;
    signal rx_fifo_wren : std_logic;
    signal rx_fifo_full : std_logic;
    signal rx_fifo_almost_full : std_logic;
    signal rx_fifo_overflow : std_logic;
    signal rx_fifo_empty : std_logic;
    signal rx_fifo_underflow : std_logic;
    signal rx_fifo_flush : std_logic;

    signal s2p_fifo_data : std_logic_vector (31 downto 0);
    signal s2p_pkt_ready : std_logic;
    signal s2p_pkt_ack : std_logic;

    signal mod_bus_master : std_logic;
    signal fifo_bus_addr : std_logic_vector (7 downto 0);
    signal fifo_d_out : std_logic_vector (31 downto 0);
    signal fifo_addr_strobe : std_logic;
    signal fifo_write_strobe : std_logic;
    signal fifo_io_ready : std_logic;
    signal mod_bus_addr : std_logic_vector (7 downto 0);
    signal mod_d_out : std_logic_vector (31 downto 0);
    signal mod_addr_strobe : std_logic;
    signal mod_write_strobe : std_logic;
    signal mod_io_ready : std_logic;

    signal parallel_to_serial_enable : std_logic;

    signal usb_pkt_end : std_logic;
    
    signal reseed, seed_val, seed_clk : std_logic;

    signal s_data_in_sync : std_logic;

    signal reset : std_logic;
    signal pkt_reset : std_logic;
    signal clk_debounce, clkin_ibufg : std_logic;
    signal pll_clk, cpu_clk, serial_clk, serial_clk_90, usb_clk : std_logic;
    signal mem_clk0, mem_clk90, mem_clkdiv0, mem_clk200 : std_logic;
    signal pll_locked, mem_pll_locked : std_logic;
    signal serial_dcm_locked : std_logic;
    signal cpu_dcm_locked : std_logic;

    signal btn1_d : std_logic;
    signal btn2_d : std_logic;

begin
    
    serial_clk_out <= serial_clk;

    cpu_clk <= mem_clk0;

    reset <= not rstbtn;

    clk_lock_int <= not(pll_locked and serial_dcm_locked and 
		cpu_dcm_locked and mem_pll_locked);

    mem_fifo_full <= app_af_afull or app_wdf_afull;

    -- 100MHz XTal to 42MHz PLL
    core_pll : entity work.pll_core
	port map (
	    CLKIN1_IN => clkin,
	    RST_IN => '0',
	    CLKOUT0_OUT => pll_clk,
	    CLKIN_IBUFG => clkin_ibufg,
	    LOCKED_OUT => pll_locked);

    -- 100MHz XTal to 125MHz Mem clock (Also 200MHz and 62.5MHz)
    mem_pll : entity work.pll_mem
	port map (
	    CLKIN1_IN => clkin_ibufg,
	    RST_IN => '0',
	    CLKOUT0_OUT => mem_clk0,
	    CLKOUT1_OUT => mem_clk90,
	    CLKOUT2_OUT => mem_clkdiv0,
	    CLKOUT3_OUT => mem_clk200,
	    LOCKED_OUT => mem_pll_locked);

    usb_bufr : component BUFR
	port map (
	    I => UsbClk,
	    O => usb_clk);
    
    -- 90MHz PLL to 100MHz cpu clock (unused, operating CPU at MEM HZ)
    -- To reinstate, two FIFOs are requred between the mem controller and
    -- the CPU bus.
    --cpu_clk_dcm : entity work.dcm_cpu
    --    port map (
    --	CLKIN_IN => pll_clk,
    --	RST_IN => '0',
    --	CLKFX_OUT => open, --cpu_clk,
    --	LOCKED_OUT => cpu_dcm_locked);
    cpu_dcm_locked <= '1';

    -- 42MHz PLL to 42MHz serial clock for TX
    serial_clk_dcm : entity work.dcm_serial
	port map (
	    CLKIN_IN => pll_clk,
	    RST_IN => '0',
	    CLK0_OUT => serial_clk,
	    CLK90_OUT => serial_clk_90,
	    LOCKED_OUT => serial_dcm_locked);
	    
    -- 125MHz cpu_clk to 6.25kHz clk for pushbutton debouncing 
    clk_div_0 : entity work.clock_divider
	generic map (DIV_BY => 20E3)
	port map (clk => cpu_clk, clk_div => clk_debounce);
	    
    cpu_0 : component mcs_0
	port map (
	    Clk => cpu_clk,
	    Reset => reset,
	    IO_Addr_Strobe => io_addr_strobe,
	    IO_Read_Strobe => io_read_strobe,
	    IO_Write_Strobe => io_write_strobe,
	    IO_Address => io_address,
	    IO_Write_Data => io_write_data,
	    IO_Read_Data => io_read_data,
	    IO_Ready => io_ready,
	    GPI2 => sw,
	    GPO1 (0) => parallel_to_serial_enable,
	    GPO1 (1) => usb_pkt_end,
	    GPO1 (2) => reseed,
	    GPO1 (3) => seed_val,
	    GPO1 (4) => seed_clk,
	    GPO1 (5) => tx_fifo_flush,
	    GPO1 (6) => s2p_pkt_ack,
	    GPO1 (7) => open,
	    GPO2 => Led,
	    INTC_Interrupt (INT(IRQ_BUTTON)) => btn1_d,
	    INTC_Interrupt (INT(IRQ_FIFO_FULL)) => tx_fifo_full,
	    INTC_Interrupt (INT(IRQ_FIFO_ALMOST_FULL)) => tx_fifo_almost_full,
	    INTC_Interrupt (INT(IRQ_FIFO_OVERFLOW)) => tx_fifo_overflow,
	    INTC_Interrupt (INT(IRQ_RX_DATA_READY)) => not(rx_fifo_empty),
	    INTC_Interrupt (INT(IRQ_RX_PKT_READY)) => s2p_pkt_ready,
	    INTC_Interrupt (INT(IRQ_RX_FIFO_FULL)) => rx_fifo_almost_full,
	    INTC_Interrupt (INT(IRQ_CLOCK_LOSS)) => clk_lock_int,
	    INTC_Interrupt (INT(IRQ_RAM_INIT)) => not(phy_init_done),
	    INTC_Interrupt (INT(IRQ_RAM_FIFO_FULL)) => mem_fifo_full,
	    INTC_Interrupt (INT(IRQ_USB_INT)) => usb_irq,
	    INTC_Interrupt (INT(IRQ_USB_FULL)) => UsbFull,
	    INTC_Interrupt (INT(IRQ_USB_EN)) => UsbEN,
	    INTC_Interrupt (INT(IRQ_USB_EMPTY)) => UsbEmpty,
	    INTC_Interrupt (INT(IRQ_BUTTON_2)) => btn2_d,
	    INTC_Interrupt (15) => '0',
	    GPI1 (INT(IRQ_BUTTON)) => btn1_d,
	    GPI1 (INT(IRQ_FIFO_FULL)) => tx_fifo_full,
	    GPI1 (INT(IRQ_FIFO_ALMOST_FULL)) => tx_fifo_almost_full,
	    GPI1 (INT(IRQ_FIFO_OVERFLOW)) => tx_fifo_overflow,
	    GPI1 (INT(IRQ_RX_DATA_READY)) => not(rx_fifo_empty),
	    GPI1 (INT(IRQ_RX_PKT_READY)) => s2p_pkt_ready,
	    GPI1 (INT(IRQ_RX_FIFO_FULL)) => rx_fifo_almost_full,
	    GPI1 (INT(IRQ_CLOCK_LOSS)) => clk_lock_int,
	    GPI1 (INT(IRQ_RAM_INIT)) => not(phy_init_done),
	    GPI1 (INT(IRQ_RAM_FIFO_FULL)) => mem_fifo_full,
	    GPI1 (INT(IRQ_USB_INT)) => usb_irq,
	    GPI1 (INT(IRQ_USB_FULL)) => UsbFull,
	    GPI1 (INT(IRQ_USB_EN)) => UsbEN,
	    GPI1 (INT(IRQ_USB_EMPTY)) => UsbEmpty,
	    GPI1 (INT(IRQ_BUTTON_2)) => btn2_d,
	    GPI1 (15) => '0');
    
    ba_0 : entity work.io_bus_arbitrator
	port map (
	    io_d_out => io_read_data,
	    io_ready => io_ready,
	    bus1_d_in => bus1_data,
	    bus1_ready => bus1_ready,
	    bus2_d_in => bus2_data,
	    bus2_ready => bus2_ready,
	    bus3_d_in => bus3_data,
	    bus3_ready => bus3_ready,
	    bus4_d_in => bus4_data,
	    bus4_ready => bus4_ready,
	    bus5_d_in => bus5_data,
	    bus5_ready => bus5_ready,
	    bus6_d_in => (others => '0'),
	    bus6_ready => bus6_ready,
	    bus7_d_in => bus7_data,
	    bus7_ready => bus7_ready);
	    
    mem_if : entity work.mem_interface
	port map (
	    cpu_clk => cpu_clk,
	    reset => reset,
	    io_addr => io_address (7 downto 0),
	    io_d_in => io_write_data,
	    io_d_out => bus3_data,
	    io_addr_strobe => io_addr_strobe,
	    io_read_strobe => io_read_strobe,
	    io_write_strobe => io_write_strobe,
	    io_ready => bus3_ready,
	    app_af_cmd => app_af_cmd,
	    app_af_addr => app_af_addr,
	    app_af_wren => app_af_wren,
	    app_wdf_data => app_wdf_data,
	    app_wdf_wren => app_wdf_wren,
	    app_wdf_mask_data => app_wdf_mask_data,
	    rd_data_valid => rd_data_valid,
	    rd_data_fifo_out => rd_data_fifo_out);
	    
    ram : entity work.mem_controller
	port map (
	    -- Physical RAM interface
	    ddr2_dq		=> ddr2_dq,
	    ddr2_a		=> ddr2_a,
	    ddr2_ba		=> ddr2_ba,
	    ddr2_ras_n		=> ddr2_ras_n,
	    ddr2_cas_n		=> ddr2_cas_n,
	    ddr2_we_n		=> ddr2_we_n,
	    ddr2_cs_n		=> ddr2_cs_n,
	    ddr2_odt		=> ddr2_odt,
	    ddr2_cke		=> ddr2_cke,
	    ddr2_dm		=> ddr2_dm,
	    ddr2_dqs		=> ddr2_dqs,
	    ddr2_dqs_n		=> ddr2_dqs_n,
	    ddr2_ck		=> ddr2_ck,
	    ddr2_ck_n		=> ddr2_ck_n,
	    -- Infrastructure
	    clk0		=> mem_clk0,
	    clk90		=> mem_clk90,
	    clkdiv0		=> mem_clkdiv0,
	    clk200		=> mem_clk200,
	    locked		=> mem_pll_locked,
	    sys_rst_n		=> rstbtn,
	    phy_init_done	=> phy_init_done,
	    rst0_tb		=> rst0_tb,
	    clk0_tb		=> clk0_tb,
	    -- Address FIFO
	    app_af_cmd		=> app_af_cmd,
	    app_af_addr		=> app_af_addr,
	    app_af_wren		=> app_af_wren,
	    app_af_afull	=> app_af_afull,
	    -- Write FIFO
	    app_wdf_data	=> app_wdf_data,
	    app_wdf_wren	=> app_wdf_wren,
	    app_wdf_afull	=> app_wdf_afull,
	    app_wdf_mask_data	=> app_wdf_mask_data,
	    --Read FIFO
	    rd_data_valid	=> rd_data_valid,
	    rd_data_fifo_out	=> rd_data_fifo_out);

    fifo_int_0 : entity work.fifo_interface
	port map (
	    clk => cpu_clk,
	    reset => reset,
	    trigger => tx_fifo_flush,
	    io_addr => fifo_bus_addr,
	    io_d_in => fifo_d_out,
	    io_d_out => bus1_data,
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
	    rst => reset,
	    wr_clk => cpu_clk,
	    rd_clk => serial_clk,
	    din => to_tx_fifo,
	    wr_en => tx_fifo_wren,
	    rd_en => tx_fifo_rden,
	    dout => from_tx_fifo,
	    full => tx_fifo_full,
	    prog_full => tx_fifo_almost_full,
	    overflow => tx_fifo_overflow,
	    empty => tx_fifo_empty,
	    underflow => tx_fifo_underflow);

    p_to_s : entity work.parallel_to_serial
	port map (
	    clk => serial_clk,
	    reset => reset,
	    trigger => parallel_to_serial_enable,
	    trig_clk => cpu_clk,
	    fifo_d_in => from_tx_fifo,
	    fifo_rden => tx_fifo_rden,
	    fifo_empty => tx_fifo_empty,
	    data_out => s_data_out);

    usb_0 : entity work.usb_fifo
	port map (
	    usb_clk => usb_clk,
	    cpu_clk => cpu_clk,
	    reset => reset,
	    io_addr => io_address (7 downto 0),
	    io_d_in => io_write_data,
	    io_d_out => bus4_data,
	    io_addr_strobe => io_addr_strobe,
	    io_read_strobe => io_read_strobe,
	    io_write_strobe => io_write_strobe,
	    io_ready => bus4_ready,
	    pkt_end => usb_pkt_end,
	    UsbIRQ => usb_irq,
	    UsbDB => UsbDB,
	    UsbAdr => UsbAdr,
	    UsbOE => UsbOE,
	    UsbWR => UsbWR,
	    UsbRD => UsbRD,
	    UsbPktEnd => UsbPktEnd,
	    UsbEmpty => UsbEmpty,
	    UsbFull => UsbFull,
	    UsbEN => UsbEN,
	    UsbDBG => open);

    lcd_0 : entity work.lcd_interface
	port map (
	    clk => cpu_clk,
	    reset => reset,
	    io_addr => io_address (7 downto 0),
	    io_d_in => io_write_data (7 downto 0),
	    -- offset of 2 if MEM_FLAGS_ADDR := X"02"
	    io_d_out => bus2_data (23 downto 16),
	    io_addr_strobe => io_addr_strobe,
	    io_read_strobe => io_read_strobe,
	    io_write_strobe => io_write_strobe,
	    io_ready => bus2_ready,
	    lcd_data => LCDD,
	    lcd_en => LCDEN,
	    lcd_rw => LCDRW,
	    lcd_rs => LCDRS);
	
    scrambler : entity work.scrambler
	port map (
	    cpu_clk => cpu_clk,
	    reset => reset,
	    reseed => reseed,
	    seed_val => seed_val,
	    seed_clk => seed_clk,
	    io_addr => io_address (7 downto 0),
	    io_d_out => bus5_data,
	    io_addr_strobe => io_addr_strobe,
	    io_read_strobe => io_read_strobe,
	    io_ready => bus5_ready);

    ba1 : entity work.fifo_bus_arbitrator
	port map (
	    mod_bus_master => mod_bus_master,
	    io_addr => io_address (7 downto 0),
	    io_d_out => io_write_data,
	    io_addr_strobe => io_addr_strobe,
	    io_write_strobe => io_write_strobe,
	    io_io_ready => bus1_ready,
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
	    reset => reset,
	    io_addr => io_address (7 downto 0),
	    io_d_in => io_write_data,
	    io_addr_strobe => io_addr_strobe,
	    io_write_strobe => io_write_strobe,
	    io_ready => bus6_ready,
	    bus_master => mod_bus_master,
	    sub_addr_out => mod_bus_addr,
	    sub_d_out => mod_d_out,
	    sub_addr_strobe => mod_addr_strobe,
	    sub_write_strobe => mod_write_strobe,
	    sub_io_ready => mod_io_ready);
    
    rx_fifo : component fifo_rx
	port map (
	    rst => reset,
	    wr_clk => serial_clk,
	    rd_clk => cpu_clk,
	    din => s2p_fifo_data,
	    wr_en => rx_fifo_wren,
	    rd_en => rx_fifo_rden,
	    dout => from_rx_fifo,
	    full => rx_fifo_full,
	    prog_full => rx_fifo_almost_full,
	    overflow => rx_fifo_overflow,
	    empty => rx_fifo_empty,
	    underflow => rx_fifo_underflow);

    cdr0 : entity work.data_synchroniser
	port map (
	    reset => pkt_reset,
	    serial_clk => serial_clk,
	    serial_clk_90 => serial_clk_90,
	    data_in => s_data_in,
	    data_out => s_data_in_sync);

    s_to_p : entity work.serial_to_parallel
	port map (
	    reset_i => reset,
	    pkt_reset => pkt_reset,
	    serial_clk => serial_clk,
	    fifo_d_out => s2p_fifo_data,
	    fifo_wren => rx_fifo_wren,
	    fifo_full => '0',
	    data_in => s_data_in_sync,
	    pkt_ack => s2p_pkt_ack,
	    pkt_ready => s2p_pkt_ready,
	    dbg => open);

    fifo_int_1 : entity rx_fifo_interface
	port map (
	    clk => cpu_clk,
	    reset => reset,
	    io_addr => io_address (7 downto 0),
	    io_d_out => bus7_data,
	    io_addr_strobe => io_addr_strobe,
	    io_read_strobe => io_read_strobe,
	    io_ready => bus7_ready,
	    fifo_d_in => from_rx_fifo,
	    fifo_rden => rx_fifo_rden);

    db_btn1 : entity work.debounce
	port map (
	    clk => clk_debounce,
	    d_in => btn1,
	    q_out => btn1_d);

    db_btn2 : entity work.debounce
	port map (
	    clk => clk_debounce,
	    d_in => btn2,
	    q_out => btn2_d);

end toplevel_arch;

