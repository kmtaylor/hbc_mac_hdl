library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity scrambler is
    port (
	cpu_clk, reset : in std_logic;
	reseed, seed_val, seed_clk : in std_logic;
	io_addr : in std_logic_vector (7 downto 0);
	io_d_out : out std_logic_vector (31 downto 0);
	io_addr_strobe : in std_logic;
	io_read_strobe : in std_logic;
	io_ready : out std_logic);
end entity scrambler;

architecture behavioural of scrambler is

    constant SCRAMBLER_SEED_0 : std_logic_vector (31 downto 0) := X"69540152";
    constant SCRAMBLER_SEED_1 : std_logic_vector (31 downto 0) := X"8A5F621F";

    constant SCRAMBLER_ADDR  : std_logic_vector (7 downto 0) := X"14";

    signal io_addr_reg : std_logic_vector (7 downto 0);
    signal enabled : std_logic;
    signal do_ack : std_logic;

    signal scram_reg : std_logic_vector (31 downto 0);

    signal inc_scram : std_logic;
    signal scram_update : std_logic;

begin
    
    scram_update <= seed_clk or inc_scram;

    update_scram : process (scram_update) 
	variable scram_reg_i : std_logic_vector (31 downto 0);
	variable tmp_bit : std_logic;
    begin 

	if scram_update'event and scram_update = '1' then
	    if reseed = '1' then
		if seed_val = '1' then
		    scram_reg <= SCRAMBLER_SEED_1;
		else
		    scram_reg <= SCRAMBLER_SEED_0;
		end if;
	    else
		scram_reg_i := scram_reg;
		for i in 31 downto 0 loop
		    -- Polynomial is z^32 + z^31 + z^11 + 1
		    tmp_bit :=	scram_reg_i(32 - 11) xor
				scram_reg_i(32 - 31) xor
				scram_reg_i(32 - 32);
		    scram_reg_i := std_logic_vector(
				shift_right(unsigned(scram_reg_i), 1));
		    scram_reg_i(31) := tmp_bit;
		end loop;
		scram_reg <= scram_reg_i;
	    end if;
	end if;
    end process update_scram;

    -- Get IO data
    io_proc : process(cpu_clk, reset) begin
	if reset = '1' then
	    do_ack <= '0';
	-- Read IO bus on falling edge
	elsif cpu_clk'event and cpu_clk = '0' then
	    if io_read_strobe = '1' then
		do_ack <= '1';
	    else
		do_ack <= '0';
	    end if;
	end if;
    end process io_proc;

    -- ACK process
    ack_proc : process(cpu_clk, reset) begin
	if reset = '1' then
	    io_ready <= '0';
	    io_d_out <= (others => 'Z');
	    inc_scram <= '0';
	elsif cpu_clk'event and cpu_clk = '0' then
	    if enabled = '1' then
		if do_ack = '1' then
		    io_ready <= '1';
		    io_d_out <= scram_reg;
		    inc_scram <= '1';
		else
		    io_ready <= '0';
		    io_d_out <= (others => 'Z');
		    inc_scram <= '0';
		end if;
	    end if;
	end if;
    end process ack_proc;

    -- Get address from IO bus
    get_io_addr : process(cpu_clk, reset) begin
	if reset = '1' then
	    io_addr_reg <= (others => '0');
	elsif cpu_clk'event and cpu_clk = '0' then
	    if io_addr_strobe = '1' then
		io_addr_reg <= io_addr;
	    end if;
	end if;
    end process get_io_addr;

    -- Assert enabled
    with io_addr_reg (7 downto 0) select enabled
	<=  '1' when SCRAMBLER_ADDR,
	    '0' when others;

end architecture behavioural;
