
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity modulator is
    port (
	clk, reset  : in std_logic;
	io_addr	    : in std_logic_vector (7 downto 0);
	io_d_in	    : in std_logic_vector (31 downto 0);
	io_addr_strobe : in std_logic;
	io_write_strobe : in std_logic;
	io_ready    : out std_logic;
	bus_master  : out std_logic;
	sub_addr_out: out std_logic_vector (7 downto 0);
	sub_d_out   : out std_logic_vector (31 downto 0);
	sub_addr_strobe : out std_logic;
	sub_write_strobe : out std_logic;
	sub_io_ready : in std_logic);
end modulator;

architecture Behavioural of modulator is

    -- FIFO_ADDR must be word aligned
    constant MODULATOR_ADDR : std_logic_vector (7 downto 0) := X"18";
    constant MODULATOR_SF_ADDR : std_logic_vector (7 downto 0) := X"19";
    constant FIFO_ADDR : std_logic_vector (7 downto 0) := X"00";

    constant BIT_MAP_32_1 : std_logic_vector(31 downto 0) := X"AAAAAAAA";
    constant BIT_MAP_32_0 : std_logic_vector(31 downto 0) := X"55555555";
    
    constant DOUBLE_WRITE : std_logic_vector (7 downto 0) := X"00";

    constant WALSH_SIZE : integer := 16;
    constant SYM_SIZE : integer := 4;
    constant SYM_LIMIT : integer := 32 / SYM_SIZE;
	    
    signal io_addr_reg : std_logic_vector (7 downto 0);
    signal io_d_in_r : std_logic_vector (31 downto 0);
    signal sf : std_logic_vector (7 downto 0);
	
    signal enabled : std_logic;
    signal set_sf_op : std_logic;
    signal got_write : std_logic := '0';
    signal ack_write : std_logic;
    signal do_ack : std_logic;
    signal io_ready_s, io_ready_d : std_logic;

    type state_type is (st_idle,
			st_fifo_write,
			st_fifo_ack,
			st_bus_ack);
    signal state, state_i : state_type;
    
    type bit_counter is range 0 to WALSH_SIZE - 1;
    type sym_counter is range 0 to SYM_LIMIT - 1;
    signal symbol_count, symbol_count_i : sym_counter;
    signal bit_count, bit_count_i : bit_counter;
    signal repeat, repeat_i : std_logic;

    signal walsh_data : std_logic_vector (WALSH_SIZE - 1 downto 0);
    signal walsh_bit : std_logic;
    signal symbol : std_logic_vector (SYM_SIZE - 1 downto 0);

begin
    io_ready <= io_ready_s or io_ready_d;

    with symbol select walsh_data
	<=  X"9669" when "1111",
	    X"C33C" when "1110",
	    X"A55A" when "1101",
	    X"F00F" when "1100",
	    X"9966" when "1011",
	    X"CC33" when "1010",
	    X"AA55" when "1001",
	    X"FF00" when "1000",
	    X"9696" when "0111",
	    X"C3C3" when "0110",
	    X"A5A5" when "0101",
	    X"F0F0" when "0100",
	    X"9999" when "0011",
	    X"CCCC" when "0010",
	    X"AAAA" when "0001",
	    X"FFFF" when "0000",
	    X"0000" when others;

    walsh_bit <= walsh_data(integer(bit_count));

    symbol <= std_logic_vector(shift_right( unsigned(io_d_in_r),
					    natural(symbol_count) * 4)
				(SYM_SIZE - 1 downto 0));

    output_decode : process (state, walsh_bit) begin
	sub_addr_out <= FIFO_ADDR;
	sub_d_out <= (others => 'Z');
	sub_write_strobe <= '0';
	sub_addr_strobe <= '0';
	bus_master <= '1';

	if state = st_idle then
	    bus_master <= '0';
	end if;

	if state = st_fifo_write then
	    sub_write_strobe <= '1';
	    sub_addr_strobe <= '1';
	    if walsh_bit = '1' then
		sub_d_out <= BIT_MAP_32_1;
	    else
		sub_d_out <= BIT_MAP_32_0;
	    end if;
	end if;
	
	if state = st_bus_ack then
	    io_ready_s <= '1';
	else
	    io_ready_s <= '0';
	end if;
    end process;

    next_state_decode : process (state, got_write, sub_io_ready, enabled,
					set_sf_op, sf, repeat, bit_count,
					symbol_count) begin
        state_i <= state;
	bit_count_i <= bit_count;
	symbol_count_i <= symbol_count;
	ack_write <= '0';
	repeat_i <= repeat;

        case (state) is
            when st_idle =>
		if got_write = '1' and enabled = '1' and set_sf_op = '0' then
		    state_i <= st_fifo_write;
		end if;
		symbol_count_i <= 0;
		bit_count_i <= 0;
	    when st_fifo_write =>
		state_i <= st_fifo_ack;
	    when st_fifo_ack =>
		-- Also do counter updating here
		if sub_io_ready = '1' then
		    if sf = DOUBLE_WRITE and repeat = '0' then
			state_i <= st_fifo_write;
			repeat_i <= '1';
		    elsif bit_count /= bit_counter(WALSH_SIZE - 1) then
			state_i <= st_fifo_write;
			bit_count_i <= bit_count + 1;
			repeat_i <= '0';
		    elsif symbol_count /= sym_counter(SYM_LIMIT - 1) then 
			state_i <= st_fifo_write;
			symbol_count_i <= symbol_count + 1;
			bit_count_i <= 0;
			repeat_i <= '0';
		    else
			state_i <= st_bus_ack;
		    end if;
		end if;
	    when st_bus_ack =>
		state_i <= st_idle;
		ack_write <= '1';
        end case;
    end process;

    sync_proc : process (clk, reset) begin
        if reset = '1' then
            state <= st_idle;
	    bit_count <= 0;
	    symbol_count <= 0;
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
    io_proc : process(clk, reset, ack_write) begin
	if reset = '1' or ack_write = '1' then
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
	    
end Behavioural;

