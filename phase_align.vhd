#include <preprocessor/constants.vhh>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library transceiver;
use transceiver.numeric.all;
use transceiver.bits.all;

entity phase_align is
    port (
	pkt_reset : in std_logic;
	serial_clk : in std_logic;
	data_in : in std_logic;
	data_in_sync : out std_logic;
	phase_change : out std_logic;
	comma_found_out : out std_logic;
	re_align : out std_logic);
end phase_align;

architecture phase_align_arch of phase_align is

    function wrap (val : natural) return natural is begin
	if (val = 7) then
	    return 0;
	else 
	    return val + 1;
	end if;
    end function wrap;

    constant COMMA : std_logic_vector (COMMA_SIZE-1 downto 0) := HEX(PREAMBLE);
    constant COMMA_WEIGHT_BITS : natural := bits_for_val(COMMA_SIZE);

    constant EARLY_SYMBOL_SIZE : natural := 8;
    constant EARLY_SYMBOL_INDEX_BITS : natural := 
			    bits_for_val(EARLY_SYMBOL_SIZE-1);

    subtype demod_reg_t is std_logic_vector (COMMA_SIZE-1 downto 0);
    subtype phase_index_t is unsigned (EARLY_SYMBOL_INDEX_BITS-1 downto 0);
    subtype comma_weight_t is std_logic_vector (COMMA_WEIGHT_BITS-1 downto 0);

    type demod_reg_array_t is array (EARLY_SYMBOL_SIZE-1 downto 0) of 
			    demod_reg_t;
    type phase_sum_array_t is array (EARLY_SYMBOL_SIZE-1 downto 0) of
			    phase_index_t;
    type comma_weight_array_t is array (EARLY_SYMBOL_SIZE-1 downto 0) of
			    comma_weight_t;


    signal s2p_align_index : phase_index_t := (others => '0');

    signal data_in_r : std_logic;

    signal expected_phase : std_logic;
    signal current_phase : std_logic_vector(EARLY_SYMBOL_SIZE-1 downto 0);
    signal max_phase_sum : phase_index_t;
    signal best_phase : phase_index_t;
    signal phase_sum : phase_sum_array_t;
    signal demod_regs : demod_reg_array_t;

    signal comma_weight :  comma_weight_array_t;
    signal max_comma_weight : comma_weight_t;
    signal comma_found : std_logic_vector(EARLY_SYMBOL_SIZE-1 downto 0); 
    signal data_inverted : std_logic_vector(EARLY_SYMBOL_SIZE-1 downto 0); 
    signal comma_xnor : demod_reg_array_t;
    signal invert_data : std_logic;

begin

    data_sync : process (serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    data_in_r <= data_in;
	end if;
    end process data_sync;

    -- Need to delay the data stream, as the upstream re-align process will
    -- require one clock cycle.
    sync_data_proc : process (serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    data_in_sync <= data_in_r xor best_phase(0) xor invert_data;
	end if;
    end process sync_data_proc;

    phase_change <= bool_to_bit(data_in = data_in_r);

    early_compare_phase : process (serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    if s2p_align_index = 7 then
		phase_sum(0) <= (others => '0');
		expected_phase <= not invert_data;
	    else
		expected_phase <= not expected_phase;
		if (data_in_r = expected_phase) then
		    phase_sum(0) <= phase_sum(0) + 1;
		end if;
	    end if;
	    s2p_align_index <= s2p_align_index + 1;
	end if;
    end process early_compare_phase;

    early_compare_phase_gen : for i in 0 to EARLY_SYMBOL_SIZE-2 generate
	early_compare_phase : process (serial_clk) begin
	    if serial_clk'event and serial_clk = '1' then
		if s2p_align_index = i then
		    phase_sum(wrap(i)) <= (others => '0');
		elsif (data_in_r = expected_phase) then
		    phase_sum(wrap(i)) <= phase_sum(wrap(i)) + 1;
		end if;
	    end if;
	end process early_compare_phase;
    end generate early_compare_phase_gen;

    early_detect_phase_gen : for i in 0 to EARLY_SYMBOL_SIZE-1 generate
	current_phase(i) <= bool_to_bit(phase_sum(i) > EARLY_SYMBOL_SIZE/2);
    end generate early_detect_phase_gen;

    early_demodulate_gen : for i in 0 to EARLY_SYMBOL_SIZE-1 generate
	early_demodulate : process (serial_clk) begin
	    if serial_clk'event and serial_clk = '1' then
		if s2p_align_index = i then
		    demod_regs(wrap(i)) <= 
			    demod_regs(wrap(i))(COMMA_SIZE-2 downto 0) &
			    current_phase(wrap(i));
		end if;
	    end if;
	end process early_demodulate;
    end generate early_demodulate_gen;

    -- FIXME: This probably generates too much logic. Probably a multiplexer
    -- could be used to pass data to one hamming_lut at the correct times.
    comma_gen : for i in 0 to EARLY_SYMBOL_SIZE-1 generate 
	comma_xnor(i) <= demod_regs(i) xnor COMMA;
	comma_distance_lut : entity work.hamming_lut
	    port map (val => comma_xnor(i), weight => comma_weight(i));
	comma_found(i) <= weight_threshold(comma_weight(i));
	data_inverted(i) <= weight_inverted(comma_weight(i));
    end generate comma_gen;

    check_inverted : process(serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    if pkt_reset = '1' then
		invert_data <= '0';
	    elsif data_inverted /= zeros(data_inverted'length) then 
		invert_data <= '1';
	    end if;
	end if;
    end process check_inverted;

    -- Mod 8 counters can't actually show a perfect phase match
    choose_phase : process (serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    if pkt_reset = '1' then
		max_phase_sum <= (others => '0');
		-- Need to initialise this to 1 so that weight_comp can do a
		-- three bit comparison, but also cover 64
		max_comma_weight <= std_logic_vector(
				to_unsigned(1, max_comma_weight'length));
		best_phase <= (others => '0');
	    else
		for i in 0 to EARLY_SYMBOL_SIZE-1 loop
		    if (s2p_align_index = i) and (comma_found(wrap(i)) = '1') 
		    then
			if weight_comp(comma_weight(wrap(i)), max_comma_weight)
			then
			    max_comma_weight <= comma_weight(wrap(i));
			    if phase_sum(wrap(i)) > max_phase_sum then
				max_phase_sum <= phase_sum(wrap(i));
				best_phase <= to_unsigned(
						wrap(i), best_phase'length);
			    end if;
			end if;
		    end if;
		end loop;
	    end if;
	end if;
    end process choose_phase;

    comma_found_out <= comma_found(to_integer(best_phase));

    re_align <= bool_to_bit(s2p_align_index = best_phase);

end phase_align_arch;

