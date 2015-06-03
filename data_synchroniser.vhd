
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library transceiver;
use transceiver.bits.all;

    -- Double shifting may help where the clock frequencies are significantly
    -- different, and the data contains long runs of 0 or 1
#define DOUBLE_SHIFT 0
    -- Glitches can cause case a delay shift if they happen to trigger the right
    -- sequence of use_0, use_90, use_180, use_270 in order (or reverse order)
    -- A possible work around is to require n consecutive counts of each 
    -- phase_hold.
    -- That means that we only shift the delay time after seeing all four phases
    -- for a significant amount of time. Defining significant may require some
    -- experimentation. These counts should be reset when a successful delay
    -- shift is done.
#define SLOW_SHIFT 0

entity data_synchroniser is
	port (
		serial_clk, reset : in std_logic;
		serial_clk_90 : in std_logic;
		data_in : in std_logic;
		data_out : out std_logic);
end data_synchroniser;

architecture data_synchroniser_arch of data_synchroniser is

    -- Larger shift register allows for greater clock drift.
    constant WRAP_REG_SIZE : natural := 64;

    signal serial_clk_180 : std_logic;
    signal serial_clk_270 : std_logic;

    signal d_0	    : std_logic_vector (1 downto 0);
    signal d_90	    : std_logic_vector (1 downto 0);
    signal d_180    : std_logic_vector (1 downto 0);
    signal d_270    : std_logic_vector (1 downto 0);

    signal d_0_wrap	: std_logic_vector (WRAP_REG_SIZE-1 downto 0);
    signal d_90_wrap	: std_logic_vector (WRAP_REG_SIZE-1 downto 0);
    signal d_180_wrap	: std_logic_vector (WRAP_REG_SIZE-1 downto 0);
    signal d_270_wrap	: std_logic_vector (WRAP_REG_SIZE-1 downto 0);

    signal d_0_n, d_0_p : std_logic;
    signal d_90_n, d_90_p : std_logic;
    signal d_180_n, d_180_p : std_logic;
    signal d_270_n, d_270_p : std_logic;

    signal use_0, use_0_hold : std_logic;
    signal use_90, use_90_hold : std_logic;
    signal use_180, use_180_hold : std_logic;
    signal use_270, use_270_hold : std_logic;

    signal previous_shift : std_logic;
    signal delay_time : unsigned (bits_for_val(WRAP_REG_SIZE-1)-1 downto 0);

    signal delay_d_0 : std_logic_vector (1 downto 0);
    signal delay_d_90 : std_logic_vector (1 downto 0);
    signal delay_d_180 : std_logic_vector (1 downto 0);
    signal delay_d_270 : std_logic_vector (1 downto 0);

#if SLOW_SHIFT
    constant VALID_COUNT : natural := 8;
    signal use_0_valid, use_90_valid, use_180_valid, use_270_valid : std_logic;
    signal use_0_valid_sum : std_logic_vector (VALID_COUNT-1 downto 0);
    signal use_90_valid_sum : std_logic_vector (VALID_COUNT-1 downto 0);
    signal use_180_valid_sum : std_logic_vector (VALID_COUNT-1 downto 0);
    signal use_270_valid_sum : std_logic_vector (VALID_COUNT-1 downto 0);
    signal shift_valid : std_logic;
#endif
    signal reset_valid : std_logic;

begin

    serial_clk_180 <= not serial_clk;
    serial_clk_270 <= not serial_clk_90;

    -- Oversample input signal using 4 phases of serial_clk
    sample_0 : process(serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    d_0(0) <= data_in;
	    -- Resample onto serial_clk
	    d_0(1) <= d_0(0);
	    d_90(1) <= d_90(0);
	    d_180(1) <= d_180(0);
	end if;
    end process sample_0;

    sample_90 : process(serial_clk_90) begin
	if serial_clk_90'event and serial_clk_90 = '1' then
	    d_90(0) <= data_in;
	    -- Special case for d_270, allow half a clock cycle before
	    -- resampling.
	    d_270(1) <= d_270(0);
	end if;
    end process sample_90;

    sample_180 : process(serial_clk_180) begin
	if serial_clk_180'event and serial_clk_180 = '1' then
	    d_180(0) <= data_in;
	end if;
    end process sample_180;

    sample_270 : process(serial_clk_270) begin
	if serial_clk_270'event and serial_clk_270 = '1' then
	    d_270(0) <= data_in;
	end if;
    end process sample_270;

    -- Shift register to delay incoming data. This allows us to select either a
    -- shorter or longer delay whenever we wrap from 0 to 270 or vice versa.
    wrap_delay : process (serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    d_0_wrap <= d_0_wrap(WRAP_REG_SIZE-2 downto 0) & d_0(1);
	    d_90_wrap <= d_90_wrap(WRAP_REG_SIZE-2 downto 0) & d_90(1);
	    d_180_wrap <= d_180_wrap(WRAP_REG_SIZE-2 downto 0) & d_180(1);
	    d_270_wrap <= d_270_wrap(WRAP_REG_SIZE-2 downto 0) & d_270(1);
	end if;
    end process wrap_delay;

    -- May need to optimise this using SRL16
    delay_d_0(0) <=d_0_wrap(to_integer(delay_time));
    delay_d_90(0) <=d_90_wrap(to_integer(delay_time));
    delay_d_180(0) <=d_180_wrap(to_integer(delay_time));
    delay_d_270(0) <=d_270_wrap(to_integer(delay_time));

    edge_store : process(serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    delay_d_0(1) <= delay_d_0(0);
	    delay_d_90(1) <= delay_d_90(0);
	    delay_d_180(1) <= delay_d_180(0);
	    delay_d_270(1) <= delay_d_270(0);
	end if;
    end process edge_store;

    edge_detect : process(serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    d_0_p <=
		    (delay_d_0(1)   xor delay_d_0(0))	and delay_d_0(0);
            d_90_p <=
		    (delay_d_90(1)  xor delay_d_90(0))	and delay_d_90(0);
            d_180_p <=
		    (delay_d_180(1) xor delay_d_180(0))	and delay_d_180(0);
            d_270_p <=
		    (delay_d_270(1) xor delay_d_270(0))	and delay_d_270(0);

	    d_0_n <= 
		    (delay_d_0(1)   xor delay_d_0(0))	and not delay_d_0(0);
            d_90_n <= 
		    (delay_d_90(1)  xor delay_d_90(0))	and not delay_d_90(0);
            d_180_n <= 
		    (delay_d_180(1) xor delay_d_180(0))	and not delay_d_180(0);
            d_270_n <= 
		    (delay_d_270(1) xor delay_d_270(0))	and not delay_d_270(0);
	end if;
    end process edge_detect;

    select_phase : process(serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    use_0   <= (d_0_p and     d_90_p and not d_180_p and not d_270_p) or
                       (d_0_n and     d_90_n and not d_180_n and not d_270_n);
            use_90  <= (d_0_p and     d_90_p and     d_180_p and not d_270_p) or
                       (d_0_n and     d_90_n and     d_180_n and not d_270_n);
            use_180 <= (d_0_p and     d_90_p and     d_180_p and     d_270_p) or
                       (d_0_n and     d_90_n and     d_180_n and     d_270_n);
            use_270 <= (d_0_p and not d_90_p and not d_180_p and not d_270_p) or
                       (d_0_n and not d_90_n and not d_180_n and not d_270_n);
	end if;
    end process select_phase;

    hold_phase : process(serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    if reset = '1' then
		use_0_hold <= '0';
		use_90_hold <= '0';
		use_180_hold <= '0';
		use_270_hold <= '0';
#if DOUBLE_SHIFT
	    elsif (use_0 or use_90 or use_180 or use_270) = '1' then
#else
	    -- Don't allow double shifts
	    elsif ((use_0 and not use_180_hold) or
		(use_90 and not use_270_hold) or
		(use_180 and not use_0_hold) or
		(use_270 and not use_90_hold)) = '1' then
#endif
		use_0_hold <= use_0;
		use_90_hold <= use_90;
		use_180_hold <= use_180;
		use_270_hold <= use_270;
	    end if;
	end if;
    end process hold_phase;


#if SLOW_SHIFT
    acc_phase : process (serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    use_0_valid_sum <=	    use_0_valid_sum(VALID_COUNT-2 downto 0) & 
				    use_0_hold;
	    use_90_valid_sum <=	    use_90_valid_sum(VALID_COUNT-2 downto 0) & 
				    use_90_hold;
	    use_180_valid_sum <=    use_180_valid_sum(VALID_COUNT-2 downto 0) & 
				    use_180_hold;
	    use_270_valid_sum <=    use_270_valid_sum(VALID_COUNT-2 downto 0) & 
				    use_270_hold;
	end if;
    end process acc_phase;

    phase_valid : process (serial_clk) begin
	if serial_clk'event and serial_clk = '1' then
	    if reset_valid = '1' or reset = '1' then
		use_0_valid <= '0';
		use_90_valid <= '0';
		use_180_valid <= '0';
		use_270_valid <= '0';
	    else
		if use_0_valid_sum = ones(VALID_COUNT) then
		    use_0_valid <= '1';
		elsif use_90_valid_sum = ones(VALID_COUNT) then
		    use_90_valid <= '1';
		elsif use_180_valid_sum = ones(VALID_COUNT) then
		    use_180_valid <= '1';
		elsif use_270_valid_sum = ones(VALID_COUNT) then
		    use_270_valid <= '1';
		end if;
	    end if;
	end if;
    end process phase_valid;

    shift_valid <=  use_0_valid and use_90_valid and 
		    use_180_valid and use_270_valid;
#endif

    wrap_detect : process(serial_clk, reset) begin
	if serial_clk'event and serial_clk = '1' then
	    if reset = '1' then
		-- On packet reset, initialise the delay to the centre of 
		-- the array.
		delay_time <= to_unsigned(WRAP_REG_SIZE/2, delay_time'length);
	    elsif (use_270_hold and use_0) = '1' then
#if SLOW_SHIFT
		if shift_valid = '1' then
		    delay_time <= delay_time - 1;
		    previous_shift <= '0';
		    reset_valid <= '1';
		end if;
#else
		delay_time <= delay_time - 1;
		previous_shift <= '0';
#endif
	    elsif (use_0_hold and use_270) = '1' then
#if SLOW_SHIFT
		if shift_valid = '1' then
		    delay_time <= delay_time + 1;
		    previous_shift <= '1';
		    reset_valid <= '1';
		end if;
#else
		delay_time <= delay_time + 1;
		previous_shift <= '1';
#endif
#if DOUBLE_SHIFT
	    elsif ( (use_0_hold and use_90) or
		    (use_90_hold and use_180) or
		    (use_180_hold and use_270) ) = '1' then
		previous_shift <= '0';
	    elsif ( (use_270_hold and use_180) or
		    (use_180_hold and use_90) or
		    (use_90_hold and use_0) ) = '1' then
		previous_shift <= '1';
	    -- For double shifts, it's not so easy. We rely on the previous
	    -- shift direction.
	    elsif ( (use_0_hold and use_180) or
		    (use_180_hold and use_0) or 
		    (use_90_hold and use_270) or
		    (use_270_hold and use_90) ) = '1' then
		if previous_shift = '0' then
		    delay_time <= delay_time - 1;
		else
		    delay_time <= delay_time + 1;
		end if;
#endif
	    else
		reset_valid <= '0';
	    end if;
	end if;
    end process wrap_detect;

    data_out <= (delay_d_0(0)   and use_0_hold) or 
		(delay_d_90(0)  and use_90_hold) or
		(delay_d_180(0) and use_180_hold) or
		(delay_d_270(0) and use_270_hold);

end data_synchroniser_arch;

