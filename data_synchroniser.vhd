
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

entity data_synchroniser is
	port (
		serial_clk, reset : in std_logic;
		serial_clk_90 : in std_logic;
		data_in : in std_logic;
		data_out : out std_logic);
end data_synchroniser;

architecture data_synchroniser_arch of data_synchroniser is

    signal serial_clk_180 : std_logic;
    signal serial_clk_270 : std_logic;

    signal d_0	    : std_logic_vector (7 downto 0);
    signal d_90	    : std_logic_vector (7 downto 0);
    signal d_180    : std_logic_vector (7 downto 0);
    signal d_270    : std_logic_vector (7 downto 0);

    signal d_0_n, d_0_p : std_logic;
    signal d_90_n, d_90_p : std_logic;
    signal d_180_n, d_180_p : std_logic;
    signal d_270_n, d_270_p : std_logic;

    signal use_0, use_0_hold : std_logic;
    signal use_90, use_90_hold : std_logic;
    signal use_180, use_180_hold : std_logic;
    signal use_270, use_270_hold : std_logic;

    signal delay_time : unsigned (2 downto 0);

    signal delay_d_0 : std_logic;
    signal delay_d_90 : std_logic;
    signal delay_d_180 : std_logic;
    signal delay_d_270 : std_logic;

    signal sync_d_0 : std_logic;
    signal sync_d_90 : std_logic;
    signal sync_d_180 : std_logic;
    signal sync_d_270 : std_logic;

begin

    serial_clk_180 <= not serial_clk;
    serial_clk_270 <= not serial_clk_90;

    -- Oversample input signal using 4 phases of serial_clk
    sample_0 : process(serial_clk, reset) begin
	if reset = '1' then
	    d_0(2 downto 0) <= "000";
	    d_90(2 downto 1) <= "00";
	    d_180(2 downto 1) <= "00";
	    d_270(2) <= '0';
	elsif serial_clk'event and serial_clk = '1' then
	    d_0(0) <= data_in;
	    -- Resample onto serial_clk
	    d_0(1) <= d_0(0);
	    d_90(1) <= d_90(0);
	    d_180(1) <= d_180(0);

	    -- Synchronise with d_270
	    d_0(2) <= d_0(1);
	    d_90(2) <= d_90(1);
	    d_180(2) <= d_180(1);
	    d_270(2) <= d_270(1);
	end if;
    end process sample_0;

    sample_90 : process(serial_clk_90, reset) begin
	if reset = '1' then
	    d_90(0) <= '0';
	    d_270(1) <= '0';
	elsif serial_clk_90'event and serial_clk_90 = '1' then
	    d_90(0) <= data_in;
	    -- Special case for d_270, allow half a clock cycle before
	    -- resampling.
	    d_270(1) <= d_270(0);
	end if;
    end process sample_90;

    sample_180 : process(serial_clk_180, reset) begin
	if reset = '1' then
	    d_180(0) <= '0';
	elsif serial_clk_180'event and serial_clk_180 = '1' then
	    d_180(0) <= data_in;
	end if;
    end process sample_180;

    sample_270 : process(serial_clk_270, reset) begin
	if reset = '1' then
	    d_270(0) <= '0';
	elsif serial_clk_270'event and serial_clk_270 = '1' then
	    d_270(0) <= data_in;
	end if;
    end process sample_270;

    edge_detect : process(serial_clk, reset) begin
	if reset = '1' then
	    d_0_p	<= '0';	    d_0_n   <= '0';
	    d_90_p	<= '0';	    d_90_n  <= '0';
	    d_180_p	<= '0';	    d_180_n <= '0';
	    d_270_p	<= '0';	    d_270_n <= '0';
	elsif serial_clk'event and serial_clk = '1' then
	    d_0_p       <= (d_0(2)   xor d_0(1))    and not d_0(1);
            d_90_p      <= (d_90(2)  xor d_90(1))   and not d_90(1);
            d_180_p     <= (d_180(2) xor d_180(1))  and not d_180(1);
            d_270_p     <= (d_270(2) xor d_270(1))  and not d_270(1);

	    d_0_n       <= (d_0(2)   xor d_0(1))    and     d_0(1);
            d_90_n      <= (d_90(2)  xor d_90(1))   and     d_90(1);
            d_180_n     <= (d_180(2) xor d_180(1))  and     d_180(1);
            d_270_n     <= (d_270(2) xor d_270(1))  and     d_270(1);
	end if;
    end process edge_detect;

    select_phase : process(serial_clk, reset) begin
	if reset = '1' then
	    use_0   <= '0';
	    use_90  <= '0';
	    use_180 <= '0';
	    use_270 <= '0';
	elsif serial_clk'event and serial_clk = '1' then
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

    hold_phase : process(serial_clk, reset) begin
	if reset = '1' then
	    use_0_hold <= '0';
	    use_90_hold <= '0';
	    use_180_hold <= '0';
	    use_270_hold <= '0';
	elsif serial_clk'event and serial_clk = '1' then
	    if (use_0 or use_90 or use_180 or use_270) = '1' then
		use_0_hold <= use_0;
		use_90_hold <= use_90;
		use_180_hold <= use_180;
		use_270_hold <= use_270;
	    end if;
	end if;
    end process hold_phase;

    -- Shift register to delay incoming data. This allows us to select either a
    -- shorter or longer delay whenever we wrap from 0 to 270 or vice versa.
    wrap_delay : process (serial_clk, reset) begin
	if reset = '1' then
	    d_0(7 downto 3) <= (others => '0');
	    d_90(7 downto 3) <= (others => '0');
	    d_180(7 downto 3) <= (others => '0');
	    d_270(7 downto 3) <= (others => '0');
	elsif serial_clk'event and serial_clk = '1' then
	    d_0(7 downto 3) <= d_0(6 downto 2);
	    d_90(7 downto 3) <= d_90(6 downto 2);
	    d_180(7 downto 3) <= d_180(6 downto 2);
	    d_270(7 downto 3) <= d_270(6 downto 2);
	end if;
    end process wrap_delay;

    wrap_detect : process(serial_clk, reset) begin
	if reset = '1' then
	    delay_time <= to_unsigned(2, 3);
	elsif serial_clk'event and serial_clk = '1' then
	    if (use_270_hold and use_0) = '1' then
		delay_time <= delay_time - 1;
	    elsif (use_0_hold and use_270) = '1' then
		delay_time <= delay_time + 1;
	    end if;
	end if;
    end process wrap_detect;

    with (delay_time) select delay_d_0
	<=  d_0(3) when "000",
	    d_0(4) when "001",
	    d_0(5) when "010",
	    d_0(6) when "011",
	    d_0(7) when others;
 
    with (delay_time) select delay_d_90
	<=  d_90(3) when "000",
	    d_90(4) when "001",
	    d_90(5) when "010",
	    d_90(6) when "011",
	    d_90(7) when others;
 
    with (delay_time) select delay_d_180
	<=  d_180(3) when "000",
	    d_180(4) when "001",
	    d_180(5) when "010",
	    d_180(6) when "011",
	    d_180(7) when others;
 
    with (delay_time) select delay_d_270
	<=  d_270(3) when "000",
	    d_270(4) when "001",
	    d_270(5) when "010",
	    d_270(6) when "011",
	    d_270(7) when others;
 
    sync_d_0     <= delay_d_0   and use_0_hold;
    sync_d_90    <= delay_d_90  and use_90_hold;
    sync_d_180   <= delay_d_180 and use_180_hold;
    sync_d_270   <= delay_d_270 and use_270_hold;

    data_out <= sync_d_0 or sync_d_90 or sync_d_180 or sync_d_270;

end data_synchroniser_arch;

