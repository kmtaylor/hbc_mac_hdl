#include <preprocessor/constants.vhh>

#define DEBUG 0

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library transceiver;
use transceiver.numeric.all;
use transceiver.bits.all;

entity serial_to_parallel is
	port (
		serial_clk, reset_i : in std_logic;
		fifo_d_out : out vec32_t;
		fifo_wren : out std_logic;
		fifo_full : in std_logic;
		enable : in std_logic;
		data_in : in std_logic;
		pkt_active : out std_logic;
		pkt_reset : out std_logic;
		pkt_ready : out std_logic;
		pkt_ack : in std_logic);
end serial_to_parallel;

architecture serial_to_parallel_arch of serial_to_parallel is

#define _COUNT_OFFSET(val) COMMA_SIZE + INT(val)
#define COUNT_OFFSET(val) _COUNT_OFFSET(val)

    constant RESET_DELAY : natural := 16;
    constant MAX_SYMBOL_SIZE : natural := 64;
    constant SYMBOL_INDEX_BITS : natural := bits_for_val(MAX_SYMBOL_SIZE-1);
    constant RATE_SELECT_BITS : natural := bits_for_val(MAX_SYMBOL_SIZE);
    constant COMMA_WEIGHT_BITS : natural := bits_for_val(COMMA_SIZE);
    constant SFD : std_logic_vector (COMMA_SIZE-1 downto 0) := HEX(SFD);
    constant NIBBLE_SIZE : natural := 8;
    constant WORD_SIZE : natural := 32;
    constant PKT_END_THRESH : natural := 8;

    signal using_ri : std_logic;
    signal rate_found : std_logic;
    signal ri_rate : unsigned(RATE_SELECT_BITS-1 downto 0);
    signal r_sf : unsigned(RATE_SELECT_BITS-1 downto 0);

    signal sym_reset_i : std_logic;
    signal sym_reset : std_logic;
    signal reset_shift_r : std_logic_vector(RESET_DELAY-1 downto 0);
    signal reset : std_logic;
    attribute equivalent_register_removal : string;
    attribute max_fanout : string;
    attribute shreg_extract : string;
    attribute equivalent_register_removal of reset : signal is "no";
    attribute max_fanout of reset : signal is "10";
    attribute shreg_extract of reset : signal is "no"; 

    signal data_in_en : std_logic;
    signal data_in_sync : std_logic;
    signal re_align : std_logic;
    signal expected_phase : std_logic;
    signal phase_sum : unsigned (SYMBOL_INDEX_BITS-1 downto 0);
    signal current_phase : std_logic;

    signal s2p_index : unsigned (SYMBOL_INDEX_BITS-1 downto 0);
    signal allow_re_align : std_logic;
    signal latch_sfd : std_logic;

    signal walsh_count : unsigned (bits_for_val(WALSH_CODE_SIZE-1)-1 downto 0);
    signal walsh_msb : std_logic_vector (1 downto 0);
    signal walsh_clk : std_logic;
    signal walsh_detect_i : std_logic;
    signal walsh_detect : std_logic;
    signal walsh_reg : std_logic_vector (WALSH_CODE_SIZE-1 downto 0);
    signal nibble_count : unsigned (bits_for_val(NIBBLE_SIZE-1)-1 downto 0);
    signal nibble_ready : std_logic;
    signal nibble_ready_prev : std_logic;
    signal ignore_nibble : std_logic;
    signal decoded_sym : walsh_sym_t;
    signal decoded_word : std_logic_vector (WORD_SIZE-1 downto 0);

    signal phase_change : std_logic;
    signal phase_changes : std_logic_vector(PKT_END_THRESH-1 downto 0);
    signal chk_pkt_end : std_logic;
    signal pkt_end : std_logic;

    signal sfd_weight : std_logic_vector (COMMA_WEIGHT_BITS-1 downto 0);
    signal sfd_xnor : std_logic_vector (COMMA_SIZE-1 downto 0);
    signal demod_reg : std_logic_vector (COMMA_SIZE-1 downto 0);
    signal comma_found : std_logic;
    signal sfd_found : std_logic;
    signal sfd_found_i : std_logic;
    signal sfd_finished : std_logic;
    signal ri_count : unsigned (
		    bits_for_val(COUNT_OFFSET(RI_OFFSET_MAX))-1 downto 0);

    type state_type is (
			st_align_1,	-- Wait for alignment from phase_align
			st_align_2,	-- Wait for alignment from phase_align
			st_preamble,	-- Load in phase changes until
					-- successful comma detect.
			st_sfd,		-- Detect SFD and padding (data rate).
			st_demodulate,	-- Map to nearest Walsh code before
					-- pushing to FIFO.
			st_pkt_end);
    signal state, state_i : state_type;

#define EXPORT_DATA_STREAM 0
#if EXPORT_DATA_STREAM
    signal stream_data : std_logic_vector (7 downto 0);

    type output_ft is file of std_logic_vector;
    file output_file : output_ft open WRITE_MODE is "bit_data";

    procedure write_output(val: std_logic_vector(7 downto 0)) is begin
        write(output_file, val);
    end procedure write_output;
#endif

begin

    reset_sync_proc : process (serial_clk, reset_i) begin
	if reset_i = '1' then
	    reset_shift_r <= (others => '1');
	elsif serial_clk'event and serial_clk = '1' then
	    reset_shift_r <= shift_left(reset_shift_r, 1);
	end if;
    end process reset_sync_proc;

    reset <= reset_shift_r(RESET_DELAY-1);

    fifo_control : process(state) begin
	using_ri <= '1';
	allow_re_align <= '0';
	walsh_detect_i <= '0';
	chk_pkt_end <= '0';
	sym_reset_i <= '0';
	latch_sfd <= '0';
	pkt_active <= '1';
	case(state) is
	    when st_align_1 =>
		pkt_active <= '0';
		allow_re_align <= '1';
	    when st_align_2 =>
		allow_re_align <= '1';
	    when st_preamble =>
		allow_re_align <= '1';
	    when st_sfd =>
		latch_sfd <= '1';
	    when st_demodulate =>
		walsh_detect_i <= '1';
		chk_pkt_end <= '1';
	    when st_pkt_end =>
		pkt_active <= '0';
		sym_reset_i <= '1';
	end case;
    end process fifo_control;

    next_state : process(state, comma_found, sfd_finished, pkt_end,
			    nibble_count) begin
	state_i <= state;
	case (state) is
	    when st_align_1 =>
		if comma_found = '1' then
		    state_i <= st_align_2;
		end if;
	    when st_align_2 =>
		if comma_found = '0' then
		    state_i <= st_preamble;
		end if;
	    when st_preamble =>
		if comma_found = '1' then
		    state_i <= st_sfd;
		end if;
	    when st_sfd =>
		if sfd_finished = '1' then
		    state_i <= st_demodulate;
		end if;
	    when st_demodulate =>
		if pkt_end = '1' and nibble_count = 2 then
		    state_i <= st_pkt_end;
		end if;
	    when st_pkt_end =>
		state_i <= st_align_1;
	end case;
    end process next_state;

    sync_proc : process(serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    if reset = '1' then
		state <= st_align_1;
	    else
		state <= state_i;
	    end if;
	end if;
    end process sync_proc;

------------------------------------------------------------------------------

#if EXPORT_DATA_STREAM
    process (serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    stream_data <= concat_bit(stream_data, data_in_sync);
	end if;
    end process;

    process (serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    if (re_align = '1') and (state = st_demodulate) then
		write_output(stream_data);
	    end if;
	end if;
    end process;
#endif

    data_in_en <= data_in and enable;

    -- Demodulator: 
    phase_aligner : entity work.phase_align
	port map (
	    pkt_reset => sym_reset,
	    serial_clk => serial_clk,
	    data_in => data_in_en,
	    allow_re_align => allow_re_align,
	    data_in_sync => data_in_sync,
	    phase_change => phase_change,
	    comma_found_out => comma_found,
	    re_align => re_align);

    sym_reset <= reset or sym_reset_i;
    pkt_reset <= sym_reset;

    re_align_proc : process (serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    if (allow_re_align = '1') and (re_align = '1') then
		phase_sum <= (others => '0');
		s2p_index <= (others => '0');
		expected_phase <= '1';
	    elsif s2p_index = r_sf-1 then
		phase_sum <= (others => '0');
		s2p_index <= (others => '0');
		expected_phase <= '1';
	    else
		if (data_in_sync = expected_phase) then
		    phase_sum <= phase_sum + 1;
		end if;
		s2p_index <= s2p_index + 1;
		expected_phase <= not expected_phase;
	    end if;
	end if;
    end process re_align_proc;

    current_phase <= bool_to_bit(phase_sum >= r_sf/2);  

    packet_ack : process (reset, pkt_ack, serial_clk) begin
	if pkt_ack = '1' or reset = '1'then
	    pkt_ready <= '0';
	elsif serial_clk'event and serial_clk = '1' then
	    if sym_reset_i = '1' then
		pkt_ready <= '1';
	    end if;
	end if;
    end process packet_ack;

    demodulate : process(serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    if sym_reset = '1' then
		walsh_count <= (others => '1');
		walsh_detect <= '0';
	    else
		if s2p_index = r_sf-1 then
		    demod_reg <= concat_bit(demod_reg, current_phase);
		    if walsh_detect_i = '1' then
			if walsh_count = WALSH_CODE_SIZE-1 then
			    walsh_detect <= '1';
			    walsh_count <= (others => '0');
			else
			    walsh_count <= walsh_count + 1;
			end if;
		    end if;
		end if;
	    end if;
	end if;
    end process demodulate;

    sfd_xnor <= demod_reg xnor SFD;

    sfd_distance_lut : entity work.hamming_lut
	port map (val => sfd_xnor, weight => sfd_weight);

    sfd_found_i <= weight_threshold(sfd_weight);

    latch_sfd_proc : process(serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    if sym_reset = '1' then
		sfd_found <= '0';
	    else
		if sfd_found_i = '1' and latch_sfd = '1' then
		    sfd_found <= '1';
		end if;
	    end if;
	end if;
    end process latch_sfd_proc;

    consume_ri_chips : process(serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    if sym_reset = '1' then
		sfd_finished <= '0';
	    else
		if sfd_found = '1' then
		    if ri_count = COUNT_OFFSET(RI_OFFSET_MAX) then
			sfd_finished <= '1';
		    end if;
		end if;
	    end if;
	end if;
    end process consume_ri_chips;
    
    -- Count the number of chips in between the last COMMA and the SFD.
    -- This determines whether the packet is using RI or DRF mode.
    count_ri : process(serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    if sym_reset = '1' then
		ri_count <= (others => '0');
	    else
		if comma_found = '1' then
		    ri_count <= (others => '0');
		elsif s2p_index(2 downto 0) = INT(SF_8)-1 then
		    ri_count <= ri_count + 1;
		end if;
	    end if;
	end if;
    end process count_ri;

    set_rate : process(serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    if sym_reset = '1' then
		r_sf <= to_unsigned(INT(SF_8), r_sf'length);
	    else
		if rate_found = '1' and sfd_finished = '1' then
		    r_sf <= ri_rate;
		end if;
	    end if;
	end if;
    end process set_rate;

    choose_rate : process(serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    if sym_reset = '1' then
		ri_rate <= to_unsigned(INT(SF_8), ri_rate'length);
		rate_found <= '0';
	    else
		if using_ri = '1' then
		    if sfd_found = '1' and rate_found = '0' then
			if ri_count = COUNT_OFFSET(RI_OFFSET_8) then
			    ri_rate <= to_unsigned(INT(SF_8), ri_rate'length);
			elsif ri_count = COUNT_OFFSET(RI_OFFSET_16) then
			    ri_rate <= to_unsigned(INT(SF_16), ri_rate'length);
			elsif ri_count = COUNT_OFFSET(RI_OFFSET_32) then
			    ri_rate <= to_unsigned(INT(SF_32), ri_rate'length);
			elsif ri_count = COUNT_OFFSET(RI_OFFSET_64) then
			    ri_rate <= to_unsigned(INT(SF_64), ri_rate'length);
			end if;
			rate_found <= '1';
		    end if;
		end if;
	    end if;
	end if;
    end process choose_rate;

    store_walsh : process(serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    if sym_reset = '1' then
		walsh_reg <= (others => '0');
	    else
		if walsh_detect = '1' then
		    if walsh_count = WALSH_CODE_SIZE-1 then
			walsh_reg <= bit_swap(
					demod_reg(WALSH_CODE_SIZE-1 downto 0));
		    end if;
		end if;
	    end if;
	end if;
    end process store_walsh;

    walsh_decoder : entity work.walsh_decoder
	port map (clk => serial_clk, data => walsh_reg, sym => decoded_sym);

    walsh_clk_proc : process(serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    if sym_reset = '1' then
		walsh_clk <= '0';
		walsh_msb <= (others => '0');
	    else
		walsh_msb(1) <= walsh_msb(0);
		walsh_msb(0) <= walsh_count(walsh_count'length-1);
		-- Detect rising edge
		if walsh_msb(1) = '0' and walsh_msb(0) = '1' then 
		    walsh_clk <= '1';
		else
		    walsh_clk <= '0';
		end if;
	    end if;
	end if;
    end process walsh_clk_proc;

    decode_word : process(serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    if sym_reset = '1' then
		nibble_count <= (others => '0');
		decoded_word <= (others => '0');
	    else
		if walsh_detect = '1' and walsh_clk = '1' then
		    if nibble_count = NIBBLE_SIZE-1 then
			nibble_count <= (others => '0');
		    else
			nibble_count <= nibble_count + 1;
		    end if;
		    decoded_word <= decoded_sym & 
				decoded_word(WORD_SIZE-1 downto WALSH_SYM_SIZE);
		end if;
	    end if;
	end if;
    end process decode_word;

    nibble_ready <=	bool_to_bit(nibble_count = 1) and 
			bool_to_bit(walsh_count = 0);

    detect_pkt_end : process(serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    if sym_reset = '1' then
		pkt_end <= '0';
		phase_changes <= (others => '0');
	    else
		-- Detect packet ending by receiving 8 by phase_change = '1'
		phase_changes <= concat_bit(phase_changes, phase_change);
		if chk_pkt_end = '1' then
		    if phase_changes = ones(phase_changes'length) then
			pkt_end <= '1';
		    end if;
		end if;
	    end if;
	end if;
    end process detect_pkt_end;

    fifo_d_out <= decoded_word;

    push_fifo : process(serial_clk) begin
	if serial_clk'event and serial_clk = '0' then
	    if sym_reset = '1' then
		nibble_ready_prev <= '0';
		fifo_wren <= '0';
		ignore_nibble <= '1';
	    else
		nibble_ready_prev <= nibble_ready;
		if nibble_ready = '1' then
		    if nibble_ready_prev = '1' then
			fifo_wren <= '0';
		    else
			fifo_wren <= not ignore_nibble;
		    end if;
		else
		    if nibble_ready_prev = '1' then
			ignore_nibble <= '0';
		    end if;
		end if;
	    end if;
	end if;
    end process push_fifo;

end serial_to_parallel_arch;

