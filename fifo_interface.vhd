
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo_interface is
    port (
	clk, reset : in std_logic;
	io_addr    : in std_logic_vector (7 downto 0);
	io_d_in    : in std_logic_vector (31 downto 0);
	io_d_out    : out std_logic_vector (31 downto 0);
	io_addr_strobe : in std_logic;
	io_read_strobe, io_write_strobe : in std_logic;
	io_ready : out std_logic;
	fifo_d_out : out std_logic_vector (31 downto 0);
	fifo_wren : out std_logic;
	fifo_d_in : in std_logic_vector (31 downto 0);
	fifo_rden : out std_logic);
end fifo_interface;

architecture Behavioural of fifo_interface is

    -- FIFO_ADDR must be word aligned
    constant FIFO_ADDR : std_logic_vector (7 downto 0) := X"00";
    constant FIFO_MASK_ADDR : std_logic_vector (7 downto 0) := X"01";
	    
    signal io_addr_reg : std_logic_vector (7 downto 0);
    signal io_d_in_r : std_logic_vector (31 downto 0);
	
    signal enabled : std_logic;
    signal mask_op : std_logic;
    signal do_fifo_rden : std_logic := '0';
    signal do_ack : std_logic := '0';
    signal reading : std_logic := '0';

    subtype counter_type is unsigned (5 downto 0);
    signal num_bits : counter_type := to_unsigned(32, 6);
    signal bit_p : counter_type := to_unsigned(32, 6);
    signal bit_p_i : counter_type;
    signal cur_buf : std_logic_vector (31 downto 0);
    signal cur_buf_i : std_logic_vector (31 downto 0);
    signal wrap_buf : std_logic_vector (31 downto 0);
    signal wrap_buf_i : std_logic_vector (31 downto 0);
    signal write_wrap_buf : std_logic;
    signal write_wrap_buf_i : std_logic;
    signal flush_i : std_logic;
    signal wrap_mask : std_logic_vector (31 downto 0);
    signal nowrap_mask : std_logic_vector (31 downto 0);
    signal new_mask : std_logic_vector (31 downto 0);
    constant unity : unsigned (31 downto 0) := X"00000001";

begin
    nowrap_mask <= std_logic_vector(
			shift_left(unity, to_integer(num_bits)) - 1);
    new_mask <= std_logic_vector(
			shift_left(unity, to_integer(num_bits - bit_p)) - 1);
    wrap_mask <= std_logic_vector(shift_left(
			shift_left(unity, to_integer(bit_p)) - 1,
			to_integer(num_bits - bit_p)));

    with write_wrap_buf select fifo_d_out
	<=  wrap_buf	when '1',
	    cur_buf	when others;

    push_sync : process(clk, reset) begin
	if reset = '1' then
	    cur_buf <= (others => '0');
	    wrap_buf <= (others => '0');
	    bit_p <= to_unsigned(32, 6);
	    num_bits <= to_unsigned(32, 6);
	    write_wrap_buf <= '0';
	    fifo_wren <= '0';
	elsif clk'event and clk = '0' then
	    fifo_wren <= '0';
	    if do_ack = '1' and enabled = '1' and reading = '0' then
		if mask_op = '0' then
		    cur_buf <= cur_buf_i;
		    wrap_buf <= wrap_buf_i;
		    bit_p <= bit_p_i;
		    fifo_wren <= flush_i;
		    write_wrap_buf <= write_wrap_buf_i;
		else
		    num_bits <= unsigned(io_d_in(5 downto 0));
		end if;
	    end if;
	end if;
    end process push_sync;

    push_proc : process(num_bits, bit_p, cur_buf, io_d_in_r, wrap_mask,
				nowrap_mask, new_mask) begin
	wrap_buf_i <= cur_buf or std_logic_vector(
				shift_right(unsigned(io_d_in_r and wrap_mask),
					    to_integer(num_bits - bit_p)));
	flush_i <= '0';
	write_wrap_buf_i <= '0';
	if num_bits > bit_p then
	    bit_p_i <= to_unsigned(32, 6) - (num_bits - bit_p);
	    cur_buf_i <= std_logic_vector(
				shift_left( unsigned(io_d_in_r and new_mask),
					    32 - to_integer(num_bits - bit_p)));
	    flush_i <= '1';
	    write_wrap_buf_i <= '1';
	else
	    cur_buf_i <= cur_buf or std_logic_vector(
				shift_left( unsigned(io_d_in_r and nowrap_mask),
					    to_integer(bit_p - num_bits)));
	    if num_bits = bit_p then
		bit_p_i <= to_unsigned(32, 6);
		flush_i <= '1';
	    else
		bit_p_i <= bit_p - num_bits;
	    end if;
	end if;
    end process push_proc;

    -- Get IO data
    io_proc : process(clk, reset) begin
	if reset = '1' then
	    do_fifo_rden <= '0';
	    do_ack <= '0';
	    io_d_in_r <= (others => '0');
	-- Read IO bus on falling edge
	elsif clk'event and clk = '0' then
	    if io_write_strobe = '1' then
		io_d_in_r <= io_d_in;
		do_ack <= '1';
		reading <= '0';
	    elsif io_read_strobe = '1' then
		do_fifo_rden <= '1';
		do_ack <= '1';
		reading <= '1';
	    else
		do_fifo_rden <= '0';
		do_ack <= '0';
	    end if;
	end if;
    end process io_proc;
    
    -- ACK process
    ack_proc : process(clk, reset) begin
	if reset = '1' then
	    io_ready <= '0';
	    io_d_out <= (others => 'Z');
	elsif clk'event and clk = '0' then
	    if enabled = '1' then
		if do_ack = '1' then
		    io_ready <= '1';
		    if reading = '1' then
			io_d_out <= fifo_d_in;
		    end if;
		else
		    io_ready <= '0';
		    if reading = '1' then
			io_d_out <= (others => 'Z');
		    end if;
		end if;
	    end if;
	end if;
    end process ack_proc;
    
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
	<=  '1' when FIFO_ADDR,
	    '1' when FIFO_MASK_ADDR,
	    '0' when others;

    with io_addr_reg (7 downto 0) select mask_op
	<=  '1' when FIFO_MASK_ADDR,
            '0' when others;
	    
    fifo_enable : process (enabled, do_fifo_rden) begin
	if enabled = '1' then
	    fifo_rden <= do_fifo_rden;
	else
	    fifo_rden <= '0';
	end if;
    end process fifo_enable;

end Behavioural;

