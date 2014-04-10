
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity usb_fifo is
	port (
		usb_clk, cpu_clk, reset : in std_logic;
		io_addr	: in std_logic_vector (7 downto 0);
		io_d_in	: in std_logic_vector (31 downto 0);
		io_d_out	: out std_logic_vector (31 downto 0);
		io_addr_strobe : in std_logic;
		io_read_strobe, io_write_strobe : in std_logic;
		io_ready : out std_logic;
		pkt_end : in std_logic;
		UsbIRQ : out std_logic;
		UsbDB : in std_logic_vector (7 downto 0); --fixme
		UsbAdr : out std_logic_vector (1 downto 0);
		UsbOE : out std_logic;
		UsbWR : out std_logic;
		UsbRD : out std_logic;
		UsbPktEnd : out std_logic;
		UsbEmpty : in std_logic;
		UsbEN : in std_logic);
end usb_fifo;

architecture Behavioral of usb_fifo is

	-- USB_ADDR must be word aligned
	constant USB_ADDR : std_logic_vector := X"10";

	signal UsbDB_sim : std_logic_vector (7 downto 0); --fixme
			
	signal io_addr_reg : std_logic_vector (7 downto 0);
	signal usb_read_data : std_logic_vector (31 downto 0);
	signal usb_write_data : std_logic_vector (31 downto 0);
	signal do_read_data : std_logic;
	signal reading : std_logic := '0';
	signal enabled : std_logic;

	signal do_ack : std_logic;
	signal do_pkt_end : std_logic;
	signal do_cpu_write : std_logic;
	signal do_cpu_read : std_logic;
	signal reset_pkt_end : std_logic;
	signal reset_cpu_write : std_logic;
	signal reset_cpu_read : std_logic;

   	type state_type is (st_reset,
                        st_idle,
                        st_pktend,
                        st_wr_addr,
                        st_wr_byte,
                        st_rd_addr,
                        st_rd_byte,
                        st_rd_int,
                        st_rd_ack);
    	signal state, next_state : state_type;
	signal byte_counter : unsigned (1 downto 0);
	signal byte_counter_i : unsigned (1 downto 0);

begin
-------------------------- USB FIFO State machine -----------------------------
    output_decode : process (state, byte_counter) begin

	UsbPktEnd <= '1';
	UsbAdr <= "00";
	UsbRD <= '1';
	UsbOE <= '1';
	UsbWR <= '1';
	do_read_data <= '0';
	UsbIRQ <= '0';
	UsbDB_sim <= (others => 'Z');

	case (state) is
	    -- Packet End
	    when st_pktend =>
		UsbPktEnd <= '0';
	    -- Read FIFO
	    when st_rd_byte =>
		UsbRD <= '0';
		UsbOE <= '0';
		do_read_data <= '1';
	    when st_rd_int =>
		UsbIRQ <= '1';
	    when st_wr_addr =>
		UsbAdr <= "10";
	    when st_wr_byte =>
		--UsbDB <= UsbDB_sim;
		UsbAdr <= "10";
		UsbWR <= '0';
		if byte_counter = 3 then
		    UsbDB_sim <= usb_write_data (31 downto 24);
		elsif byte_counter = 2 then
		    UsbDB_sim <= usb_write_data (23 downto 16);
		elsif byte_counter = 1 then
		    UsbDB_sim <= usb_write_data (15 downto 8);
		elsif byte_counter = 0 then
		    UsbDB_sim <= usb_write_data (7 downto 0);
		end if;
	    when others =>
	end case;
    end process output_decode;

    fifo_read_proc : process (usb_clk, reset) begin
	if reset = '1' then
	    usb_read_data <= (others => '0');
	elsif usb_clk'event and usb_clk = '1' then
	    if do_read_data = '1' then
		if byte_counter = 3 then
		    usb_read_data (31 downto 24) <= UsbDB;
		elsif byte_counter = 2 then
		    usb_read_data (23 downto 16) <= UsbDB;
		elsif byte_counter = 1 then
		    usb_read_data (15 downto 8) <= UsbDB;
		elsif byte_counter = 0 then
		    usb_read_data (7 downto 0) <= UsbDB;
		end if;
	    end if;
	end if;
    end process fifo_read_proc;

    next_state_decode : process (state, UsbEmpty, do_pkt_end, do_cpu_write,
				 byte_counter, do_cpu_read, enabled,
				 UsbEN) begin
        next_state <= state;
	byte_counter_i <= byte_counter - 1;
	reset_pkt_end <= '0';
	reset_cpu_read <= '0';
	reset_cpu_write <= '0';

        case (state) is
            when st_reset =>
		if UsbEN = '1' then
		    next_state <= st_idle;
		end if;
            when st_idle =>
		if UsbEmpty = '0' then
		    next_state <= st_rd_addr;
		elsif do_pkt_end = '1' then
		    next_state <= st_pktend;
		elsif (do_cpu_write = '1') and (enabled = '1') then
		    next_state <= st_wr_addr;
		end if;
	    -- Packet End
	    when st_pktend =>
		next_state <= st_idle;
		reset_pkt_end <= '1';
	    -- Read FIFO
	    when st_rd_addr =>
		reset_cpu_read <= '1';
		next_state <= st_rd_byte;
		byte_counter_i <= TO_UNSIGNED(3, 2);
	    when st_rd_byte =>
		if byte_counter = 0 then
		    next_state <= st_rd_int;
		end if;
	    when st_rd_int =>
		next_state <= st_rd_ack;
	    when st_rd_ack =>
		if (do_cpu_read = '1') and (enabled = '1') then
		    next_state <= st_idle;
		end if;
	    -- Write FIFO
	    when st_wr_addr =>
		next_state <= st_wr_byte;
		byte_counter_i <= TO_UNSIGNED(3, 2);
		reset_cpu_write <= '1';
	    when st_wr_byte =>
		if byte_counter = 0 then
		    next_state <= st_idle;
		end if;
	end case;
    end process next_state_decode;

    sync_proc : process (usb_clk, reset) begin
	if reset = '1' then
	    state <= st_reset;
	    byte_counter <= "00";
	elsif usb_clk'event and usb_clk = '1' then
	    state <= next_state;
	    byte_counter <= byte_counter_i;
	end if;
    end process sync_proc;
	
----------------- CPU Interface -----------------------------------------------	
    trigger_proc : process(cpu_clk, reset, reset_pkt_end) begin
	if reset = '1' then
	    do_pkt_end <= '0';
	elsif reset_pkt_end = '1' then
	    do_pkt_end <= '0';
	elsif cpu_clk'event and cpu_clk = '0' then
	    if pkt_end = '1' then
		do_pkt_end <= '1';
	    end if;
	end if;
    end process trigger_proc;

--	-- Get IO data
    io_proc : process(cpu_clk, reset, reset_cpu_read, reset_cpu_write) begin
	if reset = '1' then
	    do_ack <= '0';
	    do_cpu_read <= '0';
	    do_cpu_write <= '0';
	    usb_write_data <= (others => '0');
	elsif reset_cpu_read = '1' then
	    do_cpu_read <= '0';
	elsif reset_cpu_write = '1' then
	    do_cpu_write <= '0';
	-- Read IO bus on falling edge
	elsif cpu_clk'event and cpu_clk = '0' then
	    if io_write_strobe = '1' then
		do_ack <= '1';
		reading <= '0';
		usb_write_data <= io_d_in;
		do_cpu_write <= '1';
	    elsif io_read_strobe = '1' then
		do_ack <= '1';
		reading <= '1';
		do_cpu_read <= '1';
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
        elsif cpu_clk'event and cpu_clk = '0' then
            if enabled = '1' then
                if do_ack = '1' then
                    io_ready <= '1';
                    if reading = '1' then
                        io_d_out <= usb_read_data;
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
--    
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
        <=  '1' when USB_ADDR,
	    '0' when others;

end Behavioral;

