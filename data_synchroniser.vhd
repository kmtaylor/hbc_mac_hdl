
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

library transceiver;
use transceiver.bits.all;

-- Double shifting may help where the clock frequencies are significantly
-- different, and the data contains long runs of 0 or 1
#define DOUBLE_SHIFT 0

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

    wrap_detect : process(serial_clk, reset) begin
	if serial_clk'event and serial_clk = '1' then
	    if reset = '1' then
		-- On packet reset, initialise the delay to the centre of 
		-- the array.
		delay_time <= to_unsigned(WRAP_REG_SIZE/2, delay_time'length);
	    elsif (use_270_hold and use_0) = '1' then
		delay_time <= delay_time - 1;
		previous_shift <= '0';
	    elsif (use_0_hold and use_270) = '1' then
		delay_time <= delay_time + 1;
		previous_shift <= '1';
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
	    end if;
	end if;
    end process wrap_detect;

    data_out <= (delay_d_0(0)   and use_0_hold) or 
		(delay_d_90(0)  and use_90_hold) or
		(delay_d_180(0) and use_180_hold) or
		(delay_d_270(0) and use_270_hold);

end data_synchroniser_arch;

