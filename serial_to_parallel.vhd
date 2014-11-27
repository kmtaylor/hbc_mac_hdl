#include <preprocessor/constants.vhh>

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library transceiver;
use transceiver.numeric.all;
use transceiver.bits.all;

entity serial_to_parallel is
	port (
		serial_clk, reset : in std_logic;
		fifo_d_out : out std_logic_vector (31 downto 0);
		fifo_wren : out std_logic;
		fifo_full : in std_logic;
		data_in : in std_logic);
end serial_to_parallel;

architecture serial_to_parallel_arch of serial_to_parallel is

#define _COUNT_OFFSET(val) COMMA_SIZE-1 + INT(val)
#define COUNT_OFFSET(val) _COUNT_OFFSET(val)

    constant MAX_SYMBOL_SIZE : natural := 64;
    constant SYMBOL_INDEX_BITS : natural := bits_for_val(63);
    constant COMMA_SIZE : natural := 64;
    constant COMMA : std_logic_vector (COMMA_SIZE-1 downto 0) := HEX(PREAMBLE);
    constant SFD : std_logic_vector (COMMA_SIZE-1 downto 0) := HEX(SFD);
    constant COMMA_TEST_BITS : natural := bits_for_val(64);
    constant COMMA_THRESHOLD : unsigned(COMMA_TEST_BITS-1 downto 0) := 
			    to_unsigned(INT(COMMA_THRESHOLD), COMMA_TEST_BITS);
    constant WALSH_SIZE : natural := 16;
    constant NIBBLE_SIZE : natural := 8;
    constant WORD_SIZE : natural := 32;
    constant PKT_END_THRESH : natural := 8;

    signal using_ri : std_logic;
    signal rate_found : std_logic;
    signal ri_rate : unsigned(SYMBOL_INDEX_BITS-1 downto 0);
    signal r_sf : unsigned(SYMBOL_INDEX_BITS-1 downto 0);

    signal sym_reset_i : std_logic;
    signal sym_reset : std_logic;

    signal s2p_index : unsigned (SYMBOL_INDEX_BITS-1 downto 0);
    signal s2p_align_index : unsigned (SYMBOL_INDEX_BITS-1 downto 0);
    signal s2p_sym : std_logic_vector (MAX_SYMBOL_SIZE-1 downto 0);
    signal s2p_align_sym : std_logic_vector (MAX_SYMBOL_SIZE-1 downto 0);
    signal allow_re_align : std_logic;

    signal walsh_count : unsigned (bits_for_val(WALSH_SIZE-1)-1 downto 0);
    signal walsh_clk : std_logic;
    signal walsh_detect_i : std_logic;
    signal walsh_detect : std_logic;
    signal walsh_reg : std_logic_vector (WALSH_SIZE-1 downto 0);
    signal nibble_count : unsigned (bits_for_val(NIBBLE_SIZE-1)-1 downto 0);
    signal read_nibble : std_logic;
    signal nibble_ready_i : std_logic;
    signal nibble_ready : std_logic;
    signal nibble_ready_prev : std_logic;
    signal ignore_nibble : std_logic;
    signal decoded_sym : walsh_sym_t;
    signal decoded_word : std_logic_vector (WORD_SIZE-1 downto 0);

    signal phase_change : std_logic;
    signal phase_changes : std_logic_vector(PKT_END_THRESH-1 downto 0);
    signal current_phase : std_logic;
    signal chk_pkt_end : std_logic;
    signal pkt_end : std_logic;

    signal demod_reg : std_logic_vector (COMMA_SIZE-1 downto 0);
    signal comma_distance : unsigned (COMMA_TEST_BITS-1 downto 0);
    signal sfd_distance : unsigned (COMMA_TEST_BITS-1 downto 0);
    signal comma_found : std_logic;
    signal sfd_found : std_logic;
    signal sfd_found_i : std_logic;
    signal sfd_finished : std_logic;
    signal ri_count : unsigned (
		    bits_for_val(COUNT_OFFSET(RI_OFFSET_MAX))-1 downto 0);

    type state_type is (
			st_preamble,	-- Load in phase changes until
					-- successful comma detect.
			st_sfd,		-- Detect SFD and padding (data rate).
			st_demodulate,	-- Map to nearest Walsh code before
					-- pushing to FIFO.
			st_pkt_end);
    signal state, state_i : state_type;

begin

    fifo_control : process(reset, state) begin
	using_ri <= '1';
	allow_re_align <= '0';
	walsh_detect_i <= '0';
	chk_pkt_end <= '0';
	sym_reset_i <= '0';
	case(state) is
	    when st_preamble =>
		allow_re_align <= '1';
	    when st_sfd =>
	    when st_demodulate =>
		walsh_detect_i <= '1';
		chk_pkt_end <= '1';
	    when st_pkt_end =>
		sym_reset_i <= '1';
	end case;
    end process fifo_control;

    next_state : process(reset, state, comma_found, sfd_finished, pkt_end,
			    nibble_count) begin
	state_i <= state;
	case (state) is
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
		state_i <= st_preamble;
	end case;
    end process next_state;

    sync_proc : process(serial_clk, reset) begin
	if reset = '1' then
	    state <= st_preamble;
	elsif serial_clk'event and serial_clk = '1' then
	    state <= state_i;
	end if;
    end process sync_proc;

------------------------------------------------------------------------------

    -- Demodulator: 
    -- When detecting the correct phase early in the packet. Use two shift
    -- registers. One always tracks the input, the other resets whenever there
    -- is a phase change.
    -- If the reset register then detects a consistent phase block, it takes
    -- over as the tracking register.

    sym_reset <= reset or sym_reset_i;

    s2p_reg : process (serial_clk, sym_reset) begin
	if sym_reset = '1' then
	    s2p_sym <= (others => '0');
	elsif serial_clk'event and serial_clk = '1' then
	    s2p_sym(MAX_SYMBOL_SIZE-1 downto 1) <= 
			    s2p_sym(MAX_SYMBOL_SIZE-2 downto 0);
	    s2p_sym(0) <= data_in;
	end if;
    end process s2p_reg;
    
    detect_phase_shift : process(s2p_align_sym, data_in) begin
	if s2p_align_sym(0) = data_in then
	    phase_change <= '1';
	else
	    phase_change <= '0';
	end if;
    end process detect_phase_shift;

    s2p_align : process (serial_clk, sym_reset) begin
	if sym_reset = '1' then
	    s2p_align_sym <= (others => '0');
	    s2p_align_index <= (others => '0');
	elsif serial_clk'event and serial_clk = '1' then
	    if (phase_change = '1') or (s2p_align_index = r_sf-1) then
		-- We received the same two values in a row, this may be a
		-- phase change. 
		s2p_align_index <= (others => '0');
	    else
		s2p_align_index <= s2p_align_index + 1;
	    end if;
	    s2p_align_sym(MAX_SYMBOL_SIZE-1 downto 1) <=
			    s2p_align_sym(MAX_SYMBOL_SIZE-2 downto 0);
	    s2p_align_sym(0) <= data_in;
	end if;
    end process s2p_align;

    -- If we are at s2p_align_index = r_sf-1, and phase_sum() = 8 or 0, then the
    -- alignment register is correctly aligned. Reset s2p_index.
    re_align : process (serial_clk, sym_reset) begin
	if sym_reset = '1' then
	    s2p_index <= (others => '0');
	elsif serial_clk'event and serial_clk = '1' then
	    if (s2p_align_index = r_sf-1) and (allow_re_align = '1') then
		if (phase_sum(s2p_align_sym, r_sf) = 8) or
		    (phase_sum(s2p_align_sym, r_sf) = 0) then
		    s2p_index <= (others => '0');
		end if;
	    elsif s2p_index = r_sf-1 then
		s2p_index <= (others => '0');
	    else
		s2p_index <= s2p_index + 1;
	    end if;
	end if;
    end process re_align;

    detect_phase : process (s2p_sym) begin
	if phase_sum(s2p_sym, r_sf) > r_sf/2 then
	    current_phase <= '1';
	else
	    current_phase <= '0';
	end if;
    end process detect_phase;

    demodulate : process(serial_clk, sym_reset) begin
	if sym_reset = '1' then
	    demod_reg <= (others => '0');
	    walsh_count <= (others => '1');
	    walsh_detect <= '0';
	elsif serial_clk'event and serial_clk = '1' then
	    if s2p_index = r_sf-1 then
		demod_reg(0) <= current_phase;
		demod_reg(COMMA_SIZE-1 downto 1) <= 
				demod_reg(COMMA_SIZE-2 downto 0);
		if walsh_detect_i = '1' then
		    if walsh_count = WALSH_SIZE-1 then
			walsh_detect <= '1';
			walsh_count <= (others => '0');
		    else
			walsh_count <= walsh_count + 1;
		    end if;
		end if;
	    end if;
	end if;
    end process demodulate;

    comma_distance <= to_unsigned(
		    calc_hamming(demod_reg, COMMA), comma_distance'length);

    detect_comma : process(comma_distance) begin
	if comma_distance > COMMA_THRESHOLD then
	    comma_found <= '1';
	else
	    comma_found <= '0';
	end if;
    end process detect_comma;

    sfd_distance <= to_unsigned(
		    calc_hamming(demod_reg, SFD), sfd_distance'length);

    detect_sfd : process(sfd_distance) begin
	if sfd_distance > COMMA_THRESHOLD then
	    sfd_found_i <= '1';
	else
	    sfd_found_i <= '0';
	end if;
    end process detect_sfd;

    latch_sfd : process(sym_reset, serial_clk) begin
	if sym_reset = '1' then
	    sfd_found <= '0';
	elsif serial_clk'event and serial_clk = '1' then
	    if sfd_found_i = '1' then
		sfd_found <= '1';
	    end if;
	end if;
    end process latch_sfd;

    consume_ri_chips : process(sym_reset, serial_clk) begin
	if sym_reset = '1' then
	    sfd_finished <= '0';
	elsif serial_clk'event and serial_clk = '1' then
	    if sfd_found = '1' then
		if ri_count = COUNT_OFFSET(RI_OFFSET_MAX) then
		    sfd_finished <= '1';
		end if;
	    end if;
	end if;
    end process consume_ri_chips;
    
    -- Count the number of chips in between the last COMMA and the SFD.
    -- This determines whether the packet is using RI or DRF mode.
    count_ri : process(sym_reset, serial_clk) begin
	if sym_reset = '1' then
	    ri_count <= (others => '0');
	elsif serial_clk'event and serial_clk = '1' then
	    if comma_found = '1' then
		ri_count <= (others => '0');
	    elsif s2p_index(2 downto 0) = INT(SF_8_CHIPS)-1 then
		ri_count <= ri_count + 1;
	    end if;
	end if;
    end process count_ri;

    set_rate : process(sym_reset, serial_clk) begin
	if sym_reset = '1' then
	    r_sf <= to_unsigned(8, ri_rate'length);
	elsif serial_clk'event and serial_clk = '1' then
	    if rate_found = '1' and sfd_finished = '1' then
		r_sf <= ri_rate;
	    end if;
	end if;
    end process set_rate;

    choose_rate : process(sym_reset, serial_clk) begin
	if sym_reset = '1' then
	    ri_rate <= to_unsigned(8, ri_rate'length);
	    rate_found <= '0';
	elsif serial_clk'event and serial_clk = '1' then
	    if using_ri = '1' then
		if sfd_found_i = '1' and rate_found = '0' then
		    if ri_count = COUNT_OFFSET(RI_OFFSET_8) then
			ri_rate <= to_unsigned(8, ri_rate'length);
		    elsif ri_count = COUNT_OFFSET(RI_OFFSET_16) then
			ri_rate <= to_unsigned(16, ri_rate'length);
		    elsif ri_count = COUNT_OFFSET(RI_OFFSET_32) then
			ri_rate <= to_unsigned(32, ri_rate'length);
		    elsif ri_count = COUNT_OFFSET(RI_OFFSET_64) then
			ri_rate <= to_unsigned(64, ri_rate'length);
		    end if;
		    rate_found <= '1';
		end if;
	    end if;
	end if;
    end process choose_rate;

    store_walsh : process(sym_reset, serial_clk) begin
	if sym_reset = '1' then
	    walsh_reg <= (others => '0');
	elsif serial_clk'event and serial_clk = '1' then
	    if walsh_detect = '1' then
		if walsh_count = WALSH_SIZE-1 then
		    walsh_reg <= bit_swap(demod_reg(WALSH_SIZE-1 downto 0));
		end if;
	    end if;
	end if;
    end process store_walsh;

    decoded_sym <= walsh_decode(walsh_reg);

    walsh_clk <= walsh_count(walsh_count'length-1);

    decode_word : process(sym_reset, walsh_clk) begin
	if sym_reset = '1' then
	    nibble_count <= (others => '0');
	    decoded_word <= (others => '0');
	elsif walsh_clk'event and walsh_clk = '1' then
	    if walsh_detect = '1' then
		if nibble_count = NIBBLE_SIZE-1 then
		    nibble_count <= (others => '0');
		else
		    nibble_count <= nibble_count + 1;
		end if;
		decoded_word(WORD_SIZE-WALSH_SYM_SIZE-1 downto 0) <= 
			    decoded_word(WORD_SIZE-1 downto WALSH_SYM_SIZE);
		decoded_word(WORD_SIZE-1 downto WORD_SIZE-WALSH_SYM_SIZE) <=
			    decoded_sym;
	    end if;
	end if;
    end process decode_word;

    nibble_ready_i <= is_equal(nibble_count, 1) and is_equal(walsh_count, 0);
    nibble_ready <= nibble_ready_i and read_nibble;

    latch_nibble_ready : process(sym_reset, nibble_ready_i) begin
	if sym_reset = '1' then
	    read_nibble <= '0';
	elsif nibble_ready_i'event and nibble_ready_i = '1' then
	    read_nibble <= '1';
	end if;
    end process latch_nibble_ready;

    detect_pkt_end : process(sym_reset, serial_clk) begin
	if sym_reset = '1' then
	    pkt_end <= '0';
	    phase_changes <= (others => '0');
	elsif serial_clk'event and serial_clk = '1' then
	    -- Detect packet ending by receiving 8 by phase_change = '1'
	    phase_changes (PKT_END_THRESH-1 downto 1) <=
			phase_changes(PKT_END_THRESH-2 downto 0);
	    phase_changes(0) <= phase_change;
	    if chk_pkt_end = '1' then
		if phase_changes = ones(phase_changes'length) then
		    pkt_end <= '1';
		end if;
	    end if;
	end if;
    end process detect_pkt_end;

    fifo_d_out <= decoded_word;

    push_fifo : process(sym_reset, serial_clk) begin
	if sym_reset = '1' then
	    nibble_ready_prev <= '0';
	    fifo_wren <= '0';
	    ignore_nibble <= '1';
	elsif serial_clk'event and serial_clk = '0' then
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
    end process push_fifo;

end serial_to_parallel_arch;
