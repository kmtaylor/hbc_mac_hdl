#include <preprocessor/constants.vhh>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity psoc_interface is
	port (
		swdio_dir : in std_logic;
		swdck_dir : in std_logic;
		xres_dir : in std_logic;
		swdio_o : in std_logic;
		swdio_i : out std_logic;
		swdck_o : in std_logic;
		swdck_i : out std_logic;
		xres_o : in std_logic;
		xres_i : out std_logic;
		swdio : inout std_logic;
		swdck : inout std_logic;
		xres : inout std_logic);
end entity psoc_interface;

architecture psoc_interface_arch of psoc_interface is

begin

    swdio_i <= swdio;
    swdck_i <= swdck;
    xres_i <= xres;

#define TRISTATE(name) \
    name##_proc : process (name##_dir, name##_o) begin	\
	if name##_dir = '1' then			\
	    name <= name##_o;				\
	else						\
	    name <= 'Z';				\
	end if;						\
    end process name##_proc

    TRISTATE(swdio);
    TRISTATE(swdck);
    TRISTATE(xres);

end architecture psoc_interface_arch;

