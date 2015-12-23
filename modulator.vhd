#include <preprocessor/constants.vhh>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library transceiver;
use transceiver.numeric.all;
use transceiver.bits.all;

entity modulator is
    port (
	clk, reset  : in std_logic;
	io_addr	    : in vec8_t;
	io_d_in	    : in vec32_t;
	io_addr_strobe : in std_logic;
	io_write_strobe : in std_logic;
	io_ready    : out std_logic;
	bus_master  : out std_logic;
	sub_addr_out: out vec8_t;
	sub_d_out   : out vec32_t;
	sub_addr_strobe : out std_logic;
	sub_write_strobe : out std_logic;
	sub_io_ready : in std_logic;
	fifo_almost_full : in std_logic);
end modulator;

architecture modulator_arch of modulator is

    -- FIFO_ADDR must be word aligned
    constant MODULATOR_ADDR : vec8_t := HEX(MODULATOR_ADDR);
    constant MODULATOR_SF_ADDR : vec8_t := HEX(MODULATOR_SF_ADDR);
    constant FIFO_ADDR : vec8_t := X"00";

    constant BIT_MAP_32_1 : vec32_t := X"AAAAAAAA";
    constant BIT_MAP_32_0 : vec32_t := X"55555555";
    
    constant DOUBLE_WRITE : vec8_t := X"00";

    constant SYM_LIMIT : integer := 32 / WALSH_SYM_SIZE;
	    
    signal io_addr_reg : vec8_t;
    signal io_d_in_r : vec32_t;
    signal sf : vec8_t;
	
    signal enabled : std_logic;
    signal set_sf_op : std_logic;
    signal got_write : std_logic := '0';
    signal do_ack : std_logic;
    signal walsh_load : std_logic;
    signal walsh_shift : std_logic;
    signal symbol_load : std_logic;
    signal symbol_shift : std_logic;
    signal io_ready_s, io_ready_d : std_logic;

    type state_type is (st_idle,
			st_load,
			st_fifo_write,
			st_fifo_ack,
			st_shift,
			st_bus_ack);
    signal state, state_i : state_type;
    
    constant BIT_COUNTER_BITS : natural := bits_for_val(WALSH_CODE_SIZE - 1);
    constant SYM_COUNTER_BITS : natural := bits_for_val(SYM_LIMIT - 1);
    signal symbol_count, symbol_count_i : unsigned(SYM_COUNTER_BITS-1 downto 0);
    signal bit_count, bit_count_i : unsigned(BIT_COUNTER_BITS-1 downto 0);
    signal repeat, repeat_i : std_logic;

    signal walsh_data, walsh_data_r : walsh_code_t;
    signal walsh_bit : std_logic;
    signal symbol : walsh_sym_t;
    signal symbol_r : vec32_t;

begin
    io_ready <= io_ready_s or io_ready_d;

    walsh_bit <= walsh_data_r(0);
    symbol <= symbol_r(WALSH_SYM_SIZE - 1 downto 0);

    walsh_encoder : entity work.walsh_encode_lut
	port map (
	    symbol => symbol,
	    walsh => walsh_data);

    walsh_shifter : process (clk) begin
	if clk'event and clk = '1' then
	    if walsh_load = '1' then
		walsh_data_r <= walsh_data;
	    elsif walsh_shift = '1' then 
		walsh_data_r <= shift_right(walsh_data_r, 1);
	    end if;
	end if;
    end process walsh_shifter;

    symbol_shifter : process (clk) begin
	if clk'event and clk = '1' then
	    if symbol_load = '1' then
		symbol_r <= io_d_in_r;
	    elsif symbol_shift = '1' then
		symbol_r <= shift_right(symbol_r, WALSH_SYM_SIZE);
	    end if;
	end if;
    end process symbol_shifter;

    output_decode : process (state, walsh_bit, sf, repeat) begin
	sub_addr_out <= FIFO_ADDR;
	sub_d_out <= (others => 'Z');
	sub_write_strobe <= '0';
	sub_addr_strobe <= '0';
	bus_master <= '1';
	io_ready_s <= '0';
	walsh_shift <= '0';
	walsh_load <= '0';
	symbol_load <= '0';
	symbol_shift <= '0';

	case (state) is
	    when st_idle =>
		bus_master <= '0';
		symbol_load <= '1';
	    when st_load =>
		walsh_load <= '1';
	    when st_fifo_write =>
		sub_write_strobe <= '1';
		sub_addr_strobe <= '1';
		if walsh_bit = '1' then
		    sub_d_out <= BIT_MAP_32_1;
		else
		    sub_d_out <= BIT_MAP_32_0;
		end if;
	    when st_fifo_ack =>
		if sf = DOUBLE_WRITE then
		    walsh_shift <= repeat;
		else
		    walsh_shift <= '1';
		end if;
	    when st_shift =>
		symbol_shift <= '1';
	    when st_bus_ack =>
		io_ready_s <= '1';
	end case;
    end process;

    next_state_decode : process (state, got_write, sub_io_ready, enabled,
					set_sf_op, sf, repeat, bit_count,
					symbol_count, fifo_almost_full) begin
        state_i <= state;
	bit_count_i <= bit_count;
	symbol_count_i <= symbol_count;
	repeat_i <= repeat;

        case (state) is
            when st_idle =>
		if got_write = '1' and enabled = '1' and set_sf_op = '0' then
		    state_i <= st_load;
		end if;
		bit_count_i <= to_unsigned(0, bit_count_i'length);
		symbol_count_i <= to_unsigned(0, symbol_count_i'length);
	    when st_load =>
		if fifo_almost_full = '0' then
		    state_i <= st_fifo_write;
		end if;
	    when st_fifo_write =>
		state_i <= st_fifo_ack;
	    when st_fifo_ack =>
		-- Also do counter updating here
		if sub_io_ready = '1' then
		    if sf = DOUBLE_WRITE and repeat = '0' then
			state_i <= st_fifo_write;
			repeat_i <= '1';
		    elsif bit_count /= WALSH_CODE_SIZE - 1 then
			state_i <= st_fifo_write;
			bit_count_i <= bit_count + 1;
			repeat_i <= '0';
		    elsif symbol_count /= SYM_LIMIT - 1 then 
			state_i <= st_shift;
			repeat_i <= '0';
		    else
			state_i <= st_bus_ack;
			repeat_i <= '0';
		    end if;
		end if;
	    when st_shift =>
		state_i <= st_load;
		symbol_count_i <= symbol_count + 1;
		bit_count_i <= to_unsigned(0, bit_count_i'length);
	    when st_bus_ack =>
		state_i <= st_idle;
        end case;
    end process;

    sync_proc : process (clk, reset) begin
        if reset = '1' then
            state <= st_idle;
	    bit_count <= to_unsigned(0, bit_count'length);
	    symbol_count <= to_unsigned(0, symbol_count'length);
	    repeat <= '0';
        elsif clk'event and clk = '1' then
            state <= state_i;
	    symbol_count <= symbol_count_i;
	    bit_count <= bit_count_i;
	    repeat <= repeat_i;
        end if;
    end process; 

    sf_proc : process (clk, reset) begin
	if reset = '1' then
	    sf <= (others => '0');
	    io_ready_d <= '0';
	elsif clk'event and clk = '0' then
	    if io_ready_d = '1' then
		io_ready_d <= '0';
	    elsif set_sf_op = '1' and do_ack = '1' then
		sf <= io_d_in_r(7 downto 0);
		io_ready_d <= '1';
	    end if;
	end if;
    end process sf_proc;

    -- Get IO data
    io_proc : process(clk, reset, io_ready_s) begin
	if reset = '1' or io_ready_s = '1' then
	    io_d_in_r <= (others => '0');
	    got_write <= '0';
	    do_ack <= '0';
	-- Read IO bus on falling edge
	elsif clk'event and clk = '0' then
	    if io_write_strobe = '1' then
		io_d_in_r <= io_d_in;
		got_write <= '1';
		do_ack <= '1';
	    else
		do_ack <= '0';
	    end if;
	end if;
    end process io_proc;
    
    -- Get address from IO bus
    get_io_addr : process(clk, reset) begin
	if reset = '1' then
	    io_addr_reg <= (others => '0');
	elsif clk'event and clk = '0' then
	    if io_addr_strobe = '1' then
		io_addr_reg <= io_addr;
	    end if;
	end if;
    end process get_io_addr;
    
    -- Assert enabled
    with io_addr_reg (7 downto 0) select enabled
	<=  '1' when MODULATOR_ADDR,
	    '1' when MODULATOR_SF_ADDR,
	    '0' when others;

    with io_addr_reg (7 downto 0) select set_sf_op
	<=  '1' when MODULATOR_SF_ADDR,
            '0' when others;
	    
end modulator_arch;

