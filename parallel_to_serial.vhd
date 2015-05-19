library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library transceiver;
use transceiver.bits.all;

entity parallel_to_serial is
	port (
		clk, reset : in std_logic;
		trigger : in std_logic;
		trig_clk : in std_logic;
		fifo_d_in : in std_logic_vector (31 downto 0);
		fifo_rden : out std_logic;
		fifo_empty : in std_logic;
		data_out : out std_logic);
end parallel_to_serial;

architecture parallel_to_serial_arch of parallel_to_serial is

    type state_type is (st_reset,
			st_rd_fifo_1,
			st_rd_fifo_2,
			st_output_data,
			st_chain_1,
			st_chain_2,
			st_chain_3,
			st_finish_1,
			st_finish_2);
    signal state, next_state : state_type; 
    signal data_out_i : std_logic;
	
    signal tmp_data, tmp_data_i : std_logic_vector (31 downto 0)
							:= (others => '0');
	
    type cur_bit_type is range 0 to 31;
    signal cur_bit, cur_bit_i : cur_bit_type := 0;

    signal enabled, en_reset : std_logic;
	
begin

    trigger_proc : process(trig_clk, reset, en_reset) begin
	if reset = '1' or en_reset = '1' then
	    enabled <= '0'; 
	elsif trig_clk'event and trig_clk = '1' then
	    if trigger = '1' then
		enabled <= '1';
	    end if;
	end if;
    end process trigger_proc;

    output_decode : process (state, tmp_data) begin
	if (state = st_rd_fifo_1) or (state = st_chain_2) then
	    fifo_rden <= '1';
	else
	    fifo_rden <= '0';
	end if;
		
	if (state = st_output_data) or (state = st_chain_1) or 
	    (state = st_chain_2) or (state = st_chain_3) or 
	    (state = st_finish_1) or (state = st_finish_2) then
	    data_out_i <= tmp_data(31);
	else
	    data_out_i <= '0';
	end if;
    end process;
 
    -- enabled is asynchronous
    -- synthesise fsm with -safe_implementation
    next_state_decode : process (state, fifo_empty, cur_bit,
				       fifo_d_in, tmp_data, enabled) begin
	next_state <= state;
	cur_bit_i <= cur_bit;
	tmp_data_i <= tmp_data;
	en_reset <= '0';
		
	case (state) is
	    when st_reset =>
		if fifo_empty = '0' and enabled = '1' then
		    next_state <= st_rd_fifo_1;
		end if;
	    when st_rd_fifo_1 =>
		next_state <= st_rd_fifo_2;
	    when st_rd_fifo_2 =>
		tmp_data_i <= fifo_d_in;
		next_state <= st_output_data;
	    when st_output_data =>
		tmp_data_i <= shift_left(tmp_data, 1);
		if cur_bit = 31 - 3 then
		    cur_bit_i <= 0;
		    next_state <= st_chain_1;
		else
		    cur_bit_i <= cur_bit + 1;
		end if;
	    when st_chain_1 =>
		tmp_data_i <= shift_left(tmp_data, 1);
		if fifo_empty = '0' then
		    next_state <= st_chain_2;
		else
		    next_state <= st_finish_1;
		end if;
	    when st_chain_2 =>
		tmp_data_i <= shift_left(tmp_data, 1);
		next_state <= st_chain_3;
	    when st_chain_3 =>
		tmp_data_i <= fifo_d_in;
		next_state <= st_output_data;
	    when st_finish_1 =>
		tmp_data_i <= shift_left(tmp_data, 1);
		next_state <= st_finish_2;
	    when st_finish_2 =>
		en_reset <= '1';
		next_state <= st_reset;
	end case;      
    end process;

    sync_proc : process (clk, reset) begin
	if reset = '1' then
	    state <= st_reset;
	    data_out <= '0';
	    cur_bit <= 0;
	    tmp_data <= (others => '0');
	elsif clk'event and clk = '1' then
	    state <= next_state;
	    data_out <= data_out_i;
	    cur_bit <= cur_bit_i;
	    tmp_data <= tmp_data_i;
	end if;
    end process;

end parallel_to_serial_arch;

