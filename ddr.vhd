library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library transceiver;
use transceiver.bits.all;

entity ddr is
    -- Capacity: (DDR_BUS_WIDTH / 8) * 
    --	    2^(RAM_BANK_WIDTH + RAM_ROW_WIDTH + RAM_COL_WIDTH)
    generic (
	DDR_BUS_WIDTH : natural := 16;
	RAM_ADDR_WIDTH : natural := 13;
	RAM_BANK_WIDTH : natural := 2;
	RAM_ROW_WIDTH : natural := 13;
	RAM_COL_WIDTH : natural := 9);
    port (
	mem_clk, mem_clk_90, reset_i : in std_logic;

	-- mem_interface loosely based on Xilinx's MIG
	app_af_cmd : in std_logic;
	app_af_addr : in std_logic_vector (31 downto 0);
	app_wdf_data : in std_logic_vector (31 downto 0);
	app_wdf_wren : in std_logic;
	app_wdf_mask_data : in std_logic_vector(DDR_BUS_WIDTH*2/8-1 downto 0);
	rd_data_valid : out std_logic;
	rd_data_fifo_out : out std_logic_vector (31 downto 0);

	-- Silicon interface
	ram_clk : out std_logic;
	ram_clk_n : out std_logic;
	ram_cke : out std_logic;
	ram_cs_n : out std_logic;
	ram_cmd : out std_logic_vector (2 downto 0);
	ram_ba : out std_logic_vector (RAM_BANK_WIDTH-1 downto 0);
	ram_addr : out std_logic_vector (RAM_ADDR_WIDTH-1 downto 0);
	ram_dm : out std_logic_vector (DDR_BUS_WIDTH/8-1 downto 0);
	ram_dqs : out std_logic_vector (DDR_BUS_WIDTH/8-1 downto 0);
	ram_dq : inout std_logic_vector (DDR_BUS_WIDTH-1 downto 0));
end entity ddr;

#define DEFAULT_ODDR2(instance, output, input_0, input_1) \
    instance##_inst : ODDR2						    \
	generic map (DDR_ALIGNMENT => "C0")				    \
	port map (							    \
	    Q => output,						    \
	    D0 => input_0,						    \
	    D1 => input_1,						    \
	    C0 => mem_clk,						    \
	    C1 => mem_clk_180,						    \
	    CE => '1',							    \
	    R => '0',							    \
	    S => '0'							    \
	)

#define DEFAULT_ODDR2_90(instance, output, input_0, input_1) \
    instance##_inst : ODDR2						    \
	generic map (DDR_ALIGNMENT => "C0")				    \
	port map (							    \
	    Q => output,						    \
	    D0 => input_0,						    \
	    D1 => input_1,						    \
	    C0 => mem_clk_90,						    \
	    C1 => mem_clk_270,						    \
	    CE => '1',							    \
	    R => '0',							    \
	    S => '0'							    \
	)

#define DEFAULT_IDDR2_90(instance, output_0, output_1, input) \
    instance##_inst : IDDR2						    \
	generic map (DDR_ALIGNMENT => "C0")				    \
	port map (							    \
	    Q0 => output_0,						    \
	    Q1 => output_1,						    \
	    D => input,							    \
	    C0 => mem_clk_90,						    \
	    C1 => mem_clk_270,						    \
	    CE => '1',							    \
	    R => '0',							    \
	    S => '0'							    \
	)

architecture ddr_arch of ddr is
    
    -- Asynchronous to synchronous reset logic
    constant RESET_DELAY : natural := 16;
    signal reset_shift_r : unsigned (RESET_DELAY-1 downto 0);
    signal reset : std_logic;
    attribute equivalent_register_removal : string;
    attribute max_fanout : string;
    attribute shreg_extract : string;
    attribute equivalent_register_removal of reset : signal is "no";
    attribute max_fanout of reset : signal is "10";
    attribute shreg_extract of reset : signal is "no";

    signal mem_clk_180 : std_logic;
    signal mem_clk_270 : std_logic;

    -- Signals for mem_clk to DDR translation
    signal dqs_ddr : std_logic_vector (DDR_BUS_WIDTH/8-1 downto 0);
    signal dqs_ddr_hiz : std_logic_vector (DDR_BUS_WIDTH/8-1 downto 0);
    signal dm_ddr : std_logic_vector (DDR_BUS_WIDTH/8-1 downto 0);
    --signal dm_ddr_hiz : std_logic_vector (DDR_BUS_WIDTH/8-1 downto 0);
    signal dq_ddr_out : std_logic_vector (DDR_BUS_WIDTH-1 downto 0);
    signal dq_ddr_in : std_logic_vector (DDR_BUS_WIDTH-1 downto 0);
    signal dq_ddr_in_delay : std_logic_vector (DDR_BUS_WIDTH-1 downto 0);
    signal dq_ddr_hiz : std_logic_vector (DDR_BUS_WIDTH-1 downto 0);

    -- State machine DDR control
    signal dq_io_read : std_logic; -- Disable DQ & DQS
    signal dq_in : std_logic_vector (DDR_BUS_WIDTH*2-1 downto 0);	
    signal dq_out : std_logic_vector (DDR_BUS_WIDTH*2-1 downto 0);  -- ram_dq
    signal dqs_out : std_logic;					    -- ram_dqs
    signal ram_be : std_logic_vector (DDR_BUS_WIDTH*2/8-1 downto 0);-- ram_dm

    -- Bus state
    signal bus_bank_addr : std_logic_vector(RAM_BANK_WIDTH-1 downto 0);
    signal bus_row_addr : std_logic_vector(RAM_ROW_WIDTH-1 downto 0);
    signal bus_column_addr : std_logic_vector(RAM_COL_WIDTH-1 downto 0);
    signal bus_bytes : std_logic_vector(DDR_BUS_WIDTH*2/8-1 downto 0);
    signal bus_data : std_logic_vector (DDR_BUS_WIDTH*2-1 downto 0);

    constant MAX_DELAY : natural := 30000;
    signal delay, delay_r : unsigned (bits_for_val(MAX_DELAY)-1 downto 0);
    signal start_delay : std_logic;

    constant REFRESH_TIME : natural := 640;
    signal refresh_count : unsigned (bits_for_val(REFRESH_TIME)-1 downto 0);
    signal do_refresh : std_logic;
    signal do_write, do_read : std_logic;
    signal write_done, read_done : std_logic;

    type state_type is (
	st_reset,	-- Delay before initialisation
	st_nop,		-- Required after enableing CKE
	st_init_prch_1,	-- Precharge all banks
	st_init_prch_2,	-- Precharge all banks
	st_init_emr,	-- Write EMR
	st_init_mr1,	-- Write MR (DLL reset)
	st_init_mr2,	-- Write MR (DLL clear)
	st_init_rfsh_1,	-- Auto refresh
	st_init_rfsh_2,	-- Auto refresh
	st_idle,
	st_refresh,
	st_ras,
	st_cas);
    signal state, state_i : state_type;
    signal end_state, new_state, new_state_i : std_logic;
    signal force_new_state, force_new_state_i : std_logic;

#define DDR_CMD(name, val) \
	constant name : std_logic_vector (2 downto 0) := \
			std_logic_vector(to_unsigned(val, 3))
    DDR_CMD(CMD_LMR,	0);
    DDR_CMD(CMD_RFSH,	1);
    DDR_CMD(CMD_PRE,	2);
    DDR_CMD(CMD_RAS,	3);
    DDR_CMD(CMD_WRITE,	4);
    DDR_CMD(CMD_READ,	5);
    DDR_CMD(CMD_STOP,	6);
    DDR_CMD(CMD_NOP,	7);
#define DDR_ADDR(name, val) \
	constant name : std_logic_vector (11 downto 0) := val
    DDR_ADDR(A10_ADDR,	X"400");
    DDR_ADDR(EMR_ADDR,  X"002");
    DDR_ADDR(MR1_ADDR,	X"131");
    DDR_ADDR(MR2_ADDR,	X"031");

-- DDR Time requirements at 125MHz		Datasheet
-- RAS time		40ns	5 cycles	tRAS
-- RAS cycle		55ns	7 cycles	tRC
-- RAS precharge	15ns	2 cycles	tRP
-- RAS to RAS delay	10ns	2 cycles	tRRD
-- RAS to CAS delay	15ns	2 cycles	tRCD
-- CAS latency			3 cycles
-- Write time		15ns	2 cycles	tWR
-- Write to read		2 cycles	tWTR
-- Refresh time		120ns	15 cycles	tRFC
-- Refresh interval	7.8us	975 cycles	tREFI
-- DQS start		0.72 to 1.28 cycles	tDQSS

#define DELAY_VAL(val) to_unsigned(val, delay_r'length) 
    constant DDR_RESET_DELAY	    : natural := 200; -- FIXME Must be 20000
    constant DDR_INIT_PRCH_DELAY    : natural := 1;
    constant DDR_INIT_EMR_DELAY	    : natural := 1;
    constant DDR_INIT_MR1_DELAY	    : natural := 1;
    constant DDR_INIT_RFSH_DELAY    : natural := 14;
    constant DDR_INIT_MR2_DELAY	    : natural := 1;
    constant DDR_REFRESH_DELAY	    : natural := 14;
    constant DDR_RAS_DELAY	    : natural := 3;
    constant DDR_CAS_DELAY	    : natural := 3;
   
begin

    mem_clk_180 <= not mem_clk;
    mem_clk_270 <= not mem_clk_90;

    -- Aligned DDR clock output
    DEFAULT_ODDR2(ram_clk, ram_clk, '0', '1');
    DEFAULT_ODDR2(ram_clk_n, ram_clk_n, '1', '0');

    xilinx_io_2bit_gen : for i in 0 to (DDR_BUS_WIDTH/8 - 1) generate

	-- Double data rate register for strobe
	DEFAULT_ODDR2(dqs_ddr, dqs_ddr(i), '0', dqs_out);
	-- Double data rate register for strobe hi-Z
	DEFAULT_ODDR2(dqs_ddr_hiz, dqs_ddr_hiz(i), dq_io_read, dq_io_read);

	-- IO buffer for strobe 
	dqs_iobuf : OBUFT port map (
		O => ram_dqs(i),
		I => dqs_ddr(i),
		T => dqs_ddr_hiz(i));

	-- Double data rate register for mask bits
	DEFAULT_ODDR2_90(dm_ddr, dm_ddr(i), ram_be(i), ram_be(i + 2));
	-- Double data rate register for mask bits hi-Z
	-- FIXME: Always low (does this do anything?)
	-- DEFAULT_ODDR2_90(dm_ddr_hiz, dm_ddr_hiz(i), '0', '0');

	-- IO buffer for mask bits
	dm_obuf : OBUFT port map (
		O => ram_dm(i),
		I => dm_ddr(i),
		-- T => dm_ddr_hiz(i));
		T => '0');

    end generate xilinx_io_2bit_gen;

    xilinx_io_16bit_gen : for i in 0 to (DDR_BUS_WIDTH-1) generate

	DEFAULT_ODDR2_90(dq_ddr_out, dq_ddr_out(i), dq_out(i + 16), dq_out(i));
	-- FIXME: This seems to just mirror the previous ODDR2
	DEFAULT_ODDR2_90(dq_ddr_hiz, dq_ddr_hiz(i), dq_io_read, dq_io_read);
	DEFAULT_IDDR2_90(dq_ddr_in_delay, dq_in(i + 16), 
			dq_in(i), dq_ddr_in_delay(i));

	dq_delay : IODELAY2
	    generic map (
		DATA_RATE => "DDR",
		DELAY_SRC => "IDATAIN",
		IDELAY_TYPE => "FIXED",
		IDELAY_VALUE => 62 -- FIXME
	    )
	    port map (
		IDATAIN => dq_ddr_in(i),
		DATAOUT => dq_ddr_in_delay(i),
		-- VHDL LRM 1.1.1.2 Ports: Ports without a default vaule must
		-- be connected. Unisim does not provide default values
		CAL => '0',
		CE => '0',
		CLK => '0',
		INC => '0',
		IOCLK0 => '0',
		IOCLK1 => '0',
		ODATAIN => '0',
		RST => '0',
		T => '0'
	    );

	dq_iobuf : IOBUF port map (
		IO => ram_dq(i),
		I => dq_ddr_out(i),
		O => dq_ddr_in(i),
		T => dq_ddr_hiz(i));

    end generate xilinx_io_16bit_gen;

    reset_sync_proc : process(mem_clk, reset_i) begin
	if reset_i = '1' then
	    reset_shift_r <= (others => '1');
	elsif mem_clk'event and mem_clk = '1' then
	    reset_shift_r <= shift_right(reset_shift_r, 1);
	end if;
    end process reset_sync_proc;

    reset <= reset_shift_r(0);

    latch_op : process(mem_clk) begin
	if mem_clk'event and mem_clk = '1' then
	    if reset = '1' then
		do_write <= '0';
	    else
		if app_wdf_wren = '1' then
		    do_write <= '1';
		elsif write_done = '1' and end_state = '1' then
		    do_write <= '0';
		end if;
	    end if;
	end if;
    end process latch_op;

    
    bus_data <= app_wdf_data;
    bus_bytes <= app_wdf_mask_data;
    -- 32 bit aligned
    bus_column_addr <= app_af_addr(9 downto 2) & '0';
    bus_bank_addr <= app_af_addr(11 downto 10);
    bus_row_addr <= app_af_addr(24 downto 12);

    ddr_control : process(  state, do_write, do_read, bus_data, bus_row_addr,
			    bus_column_addr, bus_bank_addr, bus_bytes,
			    new_state) begin
	ram_cs_n <= '0';
	ram_cke <= '1';
	ram_cmd <= CMD_NOP;
	ram_ba <= (others => '0');
	ram_addr <= (others => '0');
	ram_be <= (others => '0');
	dq_out <= (others => '0');
	dqs_out <= '0';
	dq_io_read <= '0';
	write_done <= '0';
	read_done <= '0';

	case (state) is
	    when st_reset =>
		ram_cke <= '0';
	    when st_init_prch_1 | st_init_prch_2 =>
		if new_state = '1' then
		    ram_cmd <= CMD_PRE;
		    ram_addr <= pad(A10_ADDR, ram_addr'length);
		end if;
	    when st_init_emr =>
		if new_state = '1' then
		    ram_cmd <= CMD_LMR;
		    ram_ba <= "01";
		    ram_addr <= pad(EMR_ADDR, ram_addr'length);
		end if;
	    when st_init_mr1 =>
		if new_state = '1' then
		    ram_cmd <= CMD_LMR;
		    ram_addr <= pad(MR1_ADDR, ram_addr'length);
		end if;
	    when st_init_rfsh_1 | st_init_rfsh_2 | st_refresh =>
		if new_state = '1' then
		    ram_cmd <= CMD_RFSH;
		end if;
	    when st_init_mr2 =>
		if new_state = '1' then
		    ram_cmd <= CMD_LMR;
		    ram_addr <= pad(MR2_ADDR, ram_addr'length);
		end if;
	    when st_ras =>
		ram_cmd <= CMD_RAS; 
		ram_addr <= pad(bus_row_addr, ram_addr'length);
		ram_ba <= bus_bank_addr;
		ram_be <= bus_bytes;
		if do_write = '1' then
		    dq_io_read <= '0';
		else
		    dq_io_read <= '1';
		end if;
	    when st_cas =>
		if do_write = '1' then
		    ram_cmd <= CMD_WRITE;
		    dq_io_read <= '0';
		    dq_out <= bus_data;
		    dqs_out <= '1';
		else
		    ram_cmd <= CMD_READ;
		    dq_io_read <= '1';
		end if;
		ram_addr <= pad(A10_ADDR, ram_addr'length) or 
			    pad(bus_column_addr, ram_addr'length);
		ram_ba <= bus_bank_addr;
		ram_be <= bus_bytes;
		write_done <= '1';
		read_done <= '1';
	    when others =>
	end case;
    end process ddr_control;

#define DELAY_STATE(_delay_val, _next_state) \
		if new_state = '1' then					    \
		    start_delay <= '1';					    \
		    delay <= DELAY_VAL(_delay_val);			    \
		elsif end_state = '1' then				    \
		    state_i <= _next_state;				    \
		end if

    update_state : process( state, end_state, new_state, do_refresh, 
			    do_write, do_read) begin
	state_i <= state;
	start_delay <= '0';
	delay <= (others => '0');
	force_new_state_i <= '0';
	case (state) is
	    when st_reset =>
		if end_state = '1' then
		    state_i <= st_nop;
		end if;
	    when st_nop =>
		state_i <= st_init_prch_1;
		force_new_state_i <= '1';
	    when st_init_prch_1 =>
		DELAY_STATE(DDR_INIT_PRCH_DELAY, st_init_emr);
	    when st_init_emr =>
		DELAY_STATE(DDR_INIT_EMR_DELAY, st_init_mr1);
	    when st_init_mr1 =>
		DELAY_STATE(DDR_INIT_MR1_DELAY, st_init_prch_2);
	    when st_init_prch_2 =>
		DELAY_STATE(DDR_INIT_PRCH_DELAY, st_init_rfsh_1);
	    when st_init_rfsh_1 =>
		DELAY_STATE(DDR_INIT_RFSH_DELAY, st_init_rfsh_2);
	    when st_init_rfsh_2 =>
		DELAY_STATE(DDR_INIT_RFSH_DELAY, st_init_mr2);
	    when st_init_mr2 =>
		DELAY_STATE(DDR_INIT_MR2_DELAY, st_idle);
	    when st_idle =>
		if do_refresh = '1' then
		    state_i <= st_refresh;
		    force_new_state_i <= '1';
		elsif (do_write = '1') or (do_read = '1') then
		    state_i <= st_ras;
		    force_new_state_i <= '1';
		end if;
	    when st_refresh =>
		DELAY_STATE(DDR_REFRESH_DELAY, st_idle);
	    when st_ras =>
		DELAY_STATE(DDR_RAS_DELAY, st_cas);
	    when st_cas =>
		DELAY_STATE(DDR_CAS_DELAY, st_idle);
	end case;
    end process update_state;
	
    sync_proc : process(mem_clk) begin
	if mem_clk'event and mem_clk = '1' then
	    if reset = '1' then
		state <= st_reset;
		delay_r <= DELAY_VAL(DDR_RESET_DELAY);
		new_state_i <= '0';
	    else
		state <= state_i;
		force_new_state <= force_new_state_i;
		new_state_i <= end_state;
		if start_delay = '1' then
		    delay_r <= delay;
		else
		    delay_r <= delay_r - 1;
		end if;
	    end if;
	end if;
    end process sync_proc;
    new_state <= force_new_state or new_state_i;
    end_state <= bool_to_bit(delay_r = DELAY_VAL(0));

    update_refresh_count : process(mem_clk) begin
	if mem_clk'event and mem_clk = '1' then
	    if reset = '1' then
		refresh_count <= (others => '0');
	    else
		refresh_count <= refresh_count + 1;
	    end if;
	end if;
    end process update_refresh_count;
    do_refresh <= bool_to_bit(refresh_count = REFRESH_TIME);

end architecture ddr_arch;
