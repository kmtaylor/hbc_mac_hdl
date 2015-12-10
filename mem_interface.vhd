#include <preprocessor/constants.vhh>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library transceiver;
use transceiver.bits.all;

entity mem_interface is
	port (
		cpu_clk, reset : in std_logic;
		io_addr	: in uint8_t;
		io_d_in	: in uint32_t;
		io_d_out : out uint32_t;
		io_addr_strobe : in std_logic;
		io_read_strobe, io_write_strobe : in std_logic;
		io_ready : out std_logic;

		app_af_cmd : out std_logic_vector (2 downto 0);
		app_af_addr : out std_logic_vector (30 downto 0);
		app_af_wren : out std_logic;

		app_wdf_data : out std_logic_vector (127 downto 0);
		app_wdf_wren : out std_logic;
		app_wdf_mask_data : out std_logic_vector (15 downto 0);

		rd_data_valid : in std_logic;
		rd_data_fifo_out : in std_logic_vector (127 downto 0));
end mem_interface;

architecture mem_interface_arch of mem_interface is

	-- MEM_ADDR must be word aligned
	constant MEM_RD_WR_ADDR	: uint8_t := HEX(MEM_RD_WR_ADDR);
	constant MEM_FLAGS_ADDR	: uint8_t := HEX(MEM_FLAGS_ADDR);
	constant MEM_RD_P_ADDR	: uint8_t := HEX(MEM_RD_P_ADDR);
	constant MEM_WR_P_ADDR	: uint8_t := HEX(MEM_WR_P_ADDR);

	signal io_addr_reg : uint8_t;
	signal io_write_reg : uint32_t;
	signal mem_data_reg : uint32_t;
		
	signal enabled : std_logic;

	signal flags : std_logic_vector (1 downto 0);
	signal rd_p : uint32_t;
	signal wr_p : uint32_t;

	signal latch_flags : std_logic;
	signal latch_wr_p : std_logic;
	signal latch_rd_p : std_logic;
	signal mem_op : std_logic;

	signal do_ack : std_logic;
	signal ack_pending : std_logic;
	signal do_app_op : std_logic;
	signal mem_busy : std_logic;
	signal reading : std_logic := '0';

begin
	-- Always do 32bit writes
	app_wdf_mask_data <= X"FFF0";
	app_wdf_data (127 downto 32) <= (others => '0');
	app_wdf_data (31 downto 0) <= io_write_reg;
	app_af_addr <=	rd_p (30 downto 0) when reading = '1' else
			wr_p (30 downto 0);
	app_af_cmd <= "001" when reading = '1' else "000";
	
	-- Latch mem_busy on mem clock
	mem_sync : process(cpu_clk, reset) begin
	    if reset = '1' then
		mem_busy <= '1';
	    elsif cpu_clk'event and cpu_clk = '0' then
		-- Valid data has been acknowledged
		if ack_pending = '0' then
		    mem_busy <= '1';
		elsif rd_data_valid = '1' then
		    mem_data_reg <= rd_data_fifo_out (31 downto 0);
		    mem_busy <= '0';
		end if;
	    end if;
	end process mem_sync;

	-- Assert write enable	
	app_enable : process (cpu_clk, reset) begin
	    if reset = '1' then
		app_af_wren <= '0';
		app_wdf_wren <= '0';
	    elsif cpu_clk'event and cpu_clk = '1' then
                if mem_op = '1' then
                        app_af_wren <= do_app_op;
			-- FIXME: Always issue wren, use cmd to determine
			-- direction. Not compatible with MIG
			--if reading = '0' then
			    app_wdf_wren <= do_app_op;
			--else
			--    app_wdf_wren <= '0';
			--end if;
                else
                        app_af_wren <= '0';
                        app_wdf_wren <= '0';
                end if;
	    end if;
        end process app_enable;

	-- Handshake with FIFO / State machine
	busy_proc : process(cpu_clk, reset) begin
	    if reset = '1' then
		do_ack <= '0';
		ack_pending <= '0';
	    elsif cpu_clk'event and cpu_clk = '1' then
		if do_app_op = '1' then
		    -- triggered by I/O R/W
		    -- FIXME: also use rd_data_valid for write blocking
		    -- if (mem_op = '1') and (reading = '1') then
		    if mem_op = '1' then
			ack_pending <= '1';
		    else
			do_ack <= '1';
		    end if;
		else
		    -- deassert or wait
		    if ack_pending = '1' then
			if mem_busy = '0' then
			    do_ack <= '1';
			    ack_pending <= '0';
			end if;
		    else
			do_ack <= '0';
		    end if;
		end if;
	    end if;
	end process busy_proc;

	-- Auto increment/decrement
	flags_proc : process(cpu_clk, reset) begin
	    if reset = '1' then
		flags <= (others => '0');
		wr_p <= (others => '0');
		rd_p <= (others => '0');
	    elsif cpu_clk'event and cpu_clk = '1' then
		if mem_op = '1' and do_ack = '1' then
		    if reading = '1' then
			if flags(1) = '0' then
			    rd_p <= std_logic_vector(unsigned(rd_p) + 4);
			else
			    rd_p <= std_logic_vector(unsigned(rd_p) - 4);
			end if;
		    else
			if flags(0) = '0' then
			    wr_p <= std_logic_vector(unsigned(wr_p) + 4);
			else
			    wr_p <= std_logic_vector(unsigned(wr_p) - 4);
			end if;
		    end if;
		else
		    if reading = '0' then
			if latch_flags = '1' then
			    flags <= io_write_reg (1 downto 0);
			elsif latch_wr_p = '1' then
			    wr_p <= io_write_reg;
			elsif latch_rd_p = '1' then
			    rd_p <= io_write_reg;
			end if;
		    end if;
		end if;
	    end if;
	end process flags_proc;
			
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
			    if latch_flags = '1' then
				-- offset of 1 if MEM_FLAGS_ADDR := X"05"
				io_d_out (9 downto 8) <= flags;
				io_d_out (15 downto 10) <= (others => '0');
			    elsif latch_rd_p = '1' then
				io_d_out <= rd_p;
			    elsif latch_wr_p = '1' then
				io_d_out <= wr_p;
			    elsif mem_op = '1' then
				io_d_out <= mem_data_reg;
			    end if;
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

	-- Get IO data
	io_proc : process(cpu_clk, reset) begin
		if reset = '1' then
			do_app_op <= '0';
		-- Read IO bus on falling edge
		elsif cpu_clk'event and cpu_clk = '0' then
			if io_write_strobe = '1' then
				io_write_reg <= io_d_in;
				do_app_op <= '1';
				reading <= '0';
			elsif io_read_strobe = '1' then
				do_app_op <= '1';
				reading <= '1';
			else
				do_app_op <= '0';
			end if;
		end if;
	end process io_proc;
	
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
		<=	'1' when MEM_RD_WR_ADDR,
			'1' when MEM_FLAGS_ADDR, 
			'1' when MEM_RD_P_ADDR, 
			'1' when MEM_WR_P_ADDR, 
			'0' when others;
			
	with io_addr_reg (7 downto 0) select mem_op
		<=	'1' when MEM_RD_WR_ADDR, 
			'0' when others;
	with io_addr_reg (7 downto 0) select latch_flags
		<=	'1' when MEM_FLAGS_ADDR, 
			'0' when others;
	with io_addr_reg (7 downto 0) select latch_rd_p
		<=	'1' when MEM_RD_P_ADDR, 
			'0' when others;
	with io_addr_reg (7 downto 0) select latch_wr_p
		<=	'1' when MEM_WR_P_ADDR, 
			'0' when others;
end mem_interface_arch;

