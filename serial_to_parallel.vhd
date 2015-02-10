#include <preprocessor/constants.vhh>

#define DEBUG 0

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

library transceiver;
use transceiver.numeric.all;
use transceiver.bits.all;

entity serial_to_parallel is
	port (
		serial_clk, reset_i : in std_logic;
		fifo_d_out : out std_logic_vector (31 downto 0);
		fifo_wren : out std_logic;
		fifo_full : in std_logic;
		data_in : in std_logic;
		pkt_reset : out std_logic;
		pkt_ready : out std_logic;
		pkt_ack : in std_logic;
		dbg : out std_logic_vector (7 downto 0));
end serial_to_parallel;

architecture serial_to_parallel_arch of serial_to_parallel is

#define _COUNT_OFFSET(val) COMMA_SIZE-1 + INT(val)
#define COUNT_OFFSET(val) _COUNT_OFFSET(val)

    constant RESET_DELAY : natural := 25;
    constant MAX_SYMBOL_SIZE : natural := 64;
    constant COMMA_SIZE : natural := 64;
    constant SYMBOL_INDEX_BITS : natural := bits_for_val(MAX_SYMBOL_SIZE-1);
    constant RATE_SELECT_BITS : natural := bits_for_val(MAX_SYMBOL_SIZE);
    constant COMMA_WEIGHT_BITS : natural := bits_for_val(COMMA_SIZE);
    constant COMMA : std_logic_vector (COMMA_SIZE-1 downto 0) := HEX(PREAMBLE);
    constant SFD : std_logic_vector (COMMA_SIZE-1 downto 0) := HEX(SFD);
    constant WALSH_SIZE : natural := 16;
    constant NIBBLE_SIZE : natural := 8;
    constant WORD_SIZE : natural := 32;
    constant PKT_END_THRESH : natural := 8;

    signal data_in_r : std_logic;

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

    signal s2p_index : unsigned (SYMBOL_INDEX_BITS-1 downto 0);
    signal s2p_align_index : unsigned (SYMBOL_INDEX_BITS-1 downto 0);
    signal s2p_sym : std_logic_vector (MAX_SYMBOL_SIZE-1 downto 0);
    signal allow_re_align : std_logic;
    signal latch_sfd : std_logic;

    signal walsh_count : unsigned (bits_for_val(WALSH_SIZE-1)-1 downto 0);
    signal walsh_msb : std_logic_vector (1 downto 0);
    signal walsh_clk : std_logic;
    signal walsh_detect_i : std_logic;
    signal walsh_detect : std_logic;
    signal walsh_reg : std_logic_vector (WALSH_SIZE-1 downto 0);
    signal nibble_count : unsigned (bits_for_val(NIBBLE_SIZE-1)-1 downto 0);
    signal nibble_ready : std_logic;
    signal nibble_ready_prev : std_logic;
    signal ignore_nibble : std_logic;
    signal decoded_sym : walsh_sym_t;
    signal decoded_word : std_logic_vector (WORD_SIZE-1 downto 0);

    signal phase_change : std_logic;
    signal phase_changes : std_logic_vector(PKT_END_THRESH-1 downto 0);
    signal expected_phase : std_logic;
    signal current_phase : std_logic;
    signal phase_sum : unsigned (SYMBOL_INDEX_BITS-1 downto 0);
    signal chk_pkt_end : std_logic;
    signal pkt_end : std_logic;

    signal comma_weight : std_logic_vector (COMMA_WEIGHT_BITS-1 downto 0);
    signal sfd_weight : std_logic_vector (COMMA_WEIGHT_BITS-1 downto 0);
    signal comma_xnor : std_logic_vector (COMMA_SIZE-1 downto 0);
    signal sfd_xnor : std_logic_vector (COMMA_SIZE-1 downto 0);
    signal demod_reg : std_logic_vector (COMMA_SIZE-1 downto 0);
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

    reset_sync_proc : process (serial_clk, reset_i) begin
	if reset_i = '1' then
	    reset_shift_r <= (others => '1');
	elsif serial_clk'event and serial_clk = '1' then
	    reset_shift_r <= reset_shift_r(RESET_DELAY-2 downto 0) & '0';
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
	case(state) is
	    when st_preamble =>
		allow_re_align <= '1';
	    when st_sfd =>
		latch_sfd <= '1';
	    when st_demodulate =>
		walsh_detect_i <= '1';
		chk_pkt_end <= '1';
	    when st_pkt_end =>
		sym_reset_i <= '1';
	end case;
    end process fifo_control;

    next_state : process(state, comma_found, sfd_finished, pkt_end,
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

    sync_proc : process(serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    if reset = '1' then
		state <= st_preamble;
	    else
		state <= state_i;
	    end if;
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
    pkt_reset <= sym_reset;

    packet_ack : process (reset, pkt_ack, serial_clk) begin
	if pkt_ack = '1' or reset = '1'then
	    pkt_ready <= '0';
	elsif serial_clk'event and serial_clk = '1' then
	    if sym_reset_i = '1' then
		pkt_ready <= '1';
	    end if;
	end if;
    end process packet_ack;

    data_sync : process (serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    data_in_r <= data_in;
	end if;
    end process data_sync;

    s2p_reg : process (serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    if sym_reset = '1' then
		s2p_sym <= (others => '0');
	    else
		s2p_sym <= s2p_sym(MAX_SYMBOL_SIZE-2 downto 0) & data_in_r;
	    end if;
	end if;
    end process s2p_reg;
    
    detect_phase_shift : process(serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    if s2p_sym(0) = data_in_r then
		phase_change <= '1';
	    else
		phase_change <= '0';
	    end if;
	end if;
    end process detect_phase_shift;

    s2p_align : process (serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    if sym_reset = '1' then
		s2p_align_index <= (others => '0');
	    else
		if (phase_change = '1') then
		    -- We received the same two values in a row, this may be a
		    -- phase change. 
		    s2p_align_index <= to_unsigned(1, s2p_align_index'length);
		elsif s2p_align_index = r_sf-1 then
		    s2p_align_index <= (others => '0');
		else
		    s2p_align_index <= s2p_align_index + 1;
		end if;
	    end if;
	end if;
    end process s2p_align;

    -- If we are at s2p_align_index = r_sf-1, and phase_sum() = 8 or 0, then the
    -- alignment register is correctly aligned. Reset s2p_index.
    re_align : process (serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    if sym_reset = '1' then
		s2p_index <= (others => '0');
		phase_sum <= (others => '0');
		expected_phase <= '1';
	    else
		if (s2p_align_index = INT(SF_8)-1) and 
			    (allow_re_align = '1') then
		    if sym_in_phase(s2p_sym) then 
			s2p_index <= (others => '0');
			phase_sum <= (others => '0');
			expected_phase <= '1';
		    end if;
		elsif s2p_index = r_sf-1 then
		    s2p_index <= (others => '0');
		    phase_sum <= (others => '0');
		    expected_phase <= '1';
		else
		    s2p_index <= s2p_index + 1;
		    if (s2p_sym(0) = expected_phase) then
			phase_sum <= phase_sum + 1;
		    end if;
		    expected_phase <= not expected_phase;
		end if;
	    end if;
	end if;
    end process re_align;

    detect_phase : process (phase_sum, r_sf) begin
	if phase_sum >= r_sf/2 then
	    current_phase <= '1';
	else
	    current_phase <= '0';
	end if;
    end process detect_phase;

    demodulate : process(serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    if sym_reset = '1' then
		demod_reg <= (others => '0');
		walsh_count <= (others => '1');
		walsh_detect <= '0';
	    else
		if s2p_index = r_sf-1 then
		    demod_reg <= demod_reg(COMMA_SIZE-2 downto 0) & 
				current_phase;
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
	end if;
    end process demodulate;

    comma_xnor <= demod_reg xnor COMMA;
    sfd_xnor <= demod_reg xnor SFD;

    comma_distance_lut : entity work.hamming_lut
	port map (val => comma_xnor, weight => comma_weight);

    sfd_distance_lut : entity work.hamming_lut
	port map (val => sfd_xnor, weight => sfd_weight);

    comma_found <= weight_threshold(comma_weight);

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

#if DEBUG
    dbg_latch : process(serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    if reset = '1' then
		dbg <= (others => '0');
	    else
		if comma_found = '1' then
		    dbg(0) <= '1';
		end if;
		if sfd_found = '1' then
		    dbg(1) <= '1';
		end if;
		if sym_reset_i = '1' then
		    dbg(2) <= '1';
		end if;
		if sfd_finished = '1' and rate_found = '1' then 
			if ri_rate = 8 then
			    dbg(4 downto 3) <= "11";
			elsif ri_rate = 16 then
			    dbg(4 downto 3) <= "10";
			elsif ri_rate = 32 then
			    dbg(4 downto 3) <= "01";
			elsif ri_rate = 64 then
			    dbg(4 downto 3) <= "00";
			else
			    dbg(4 downto 3) <= "11";
			end if;
		end if;
	    end if;
	end if;
    end process dbg_latch;
#endif

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
		    if walsh_count = WALSH_SIZE-1 then
			walsh_reg <= bit_swap(demod_reg(WALSH_SIZE-1 downto 0));
		    end if;
		end if;
	    end if;
	end if;
    end process store_walsh;

    decoded_sym <= walsh_decode(walsh_reg);

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
		phase_changes <= phase_changes(PKT_END_THRESH-2 downto 0) & 
				    phase_change;
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

