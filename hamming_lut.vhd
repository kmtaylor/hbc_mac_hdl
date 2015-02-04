-- Hamming weight calculator based on the LUT method proposed in:
-- "Digital Hamming Weight and Distance Analyzers for Binary Vectors and 
-- Matrices" - International Journal of Innovative Computing, Information and
-- Control - Volume 9, Number 12, December 2013
-- Valery Sklyarov and Iouliia Skilarova

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hamming_lut is
    port (
	val : in std_logic_vector (63 downto 0);
	weight : out std_logic_vector (6 downto 0));
end entity hamming_lut;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity hamming_lut_36 is
    port (
	val : in std_logic_vector (35 downto 0);
	weight : out std_logic_vector (5 downto 0));
end entity hamming_lut_36;

architecture toplevel of hamming_lut is

    signal sum : unsigned(6 downto 0);
    signal weight_0, weight_1 : std_logic_vector(5 downto 0);
    constant zeros : std_logic_vector(7 downto 0) := X"00";
    signal tmp_val : std_logic_vector (35 downto 0);

begin

    weight <= std_logic_vector(unsigned('0' & weight_0) + unsigned(weight_1));

    tmp_val <= zeros & val(63 downto 36);

    hammint_lut_36_0 : entity work.hamming_lut_36
	port map (val => val(35 downto 0), weight => weight_0);

    hammint_lut_36_1 : entity work.hamming_lut_36
	port map (val => tmp_val, weight => weight_1);

end architecture toplevel;

architecture hamming_lut_arch of hamming_lut_36 is
#define SIGNAL_HAMMING_LUT(layer, num) \
    signal tmp_##layer##_##num : std_logic_vector (5 downto 0);		    \
    signal tmp_out_##layer##_##num : std_logic_vector (2 downto 0);

    SIGNAL_HAMMING_LUT(0, 0)
    SIGNAL_HAMMING_LUT(0, 1)
    SIGNAL_HAMMING_LUT(0, 2)
    SIGNAL_HAMMING_LUT(0, 3)
    SIGNAL_HAMMING_LUT(0, 4)
    SIGNAL_HAMMING_LUT(0, 5)
    SIGNAL_HAMMING_LUT(1, 0)
    SIGNAL_HAMMING_LUT(1, 1)
    SIGNAL_HAMMING_LUT(1, 2)
    
    signal sum_a : unsigned (4 downto 0);
    signal sum_b : unsigned (5 downto 0);

begin

#define HAMMING_LUT(layer, num) \
    L##layer##_##num##_LUT_0 : LUT6					    \
	generic map (INIT => X"6996966996696996")			    \
	port map (							    \
	    I0 => tmp_##layer##_##num##(0), I1 => tmp_##layer##_##num##(1), \
	    I2 => tmp_##layer##_##num##(2), I3 => tmp_##layer##_##num##(3), \
	    I4 => tmp_##layer##_##num##(4), I5 => tmp_##layer##_##num##(5), \
	    O => tmp_out_##layer##_##num##(0));				    \
    L##layer##_##num##_LUT_1 : LUT6					    \
	generic map (INIT => X"8117177E177E7EE8")			    \
	port map (							    \
	    I0 => tmp_##layer##_##num##(0), I1 => tmp_##layer##_##num##(1), \
	    I2 => tmp_##layer##_##num##(2), I3 => tmp_##layer##_##num##(3), \
	    I4 => tmp_##layer##_##num##(4), I5 => tmp_##layer##_##num##(5), \
	    O => tmp_out_##layer##_##num##(1));				    \
    L##layer##_##num##_LUT_2 : LUT6					    \
	generic map (INIT => X"FEE8E880E8808000")			    \
	port map (							    \
	    I0 => tmp_##layer##_##num##(0), I1 => tmp_##layer##_##num##(1), \
	    I2 => tmp_##layer##_##num##(2), I3 => tmp_##layer##_##num##(3), \
	    I4 => tmp_##layer##_##num##(4), I5 => tmp_##layer##_##num##(5), \
	    O => tmp_out_##layer##_##num##(2));

    HAMMING_LUT(0, 0)
    HAMMING_LUT(0, 1)
    HAMMING_LUT(0, 2)
    HAMMING_LUT(0, 3)
    HAMMING_LUT(0, 4)
    HAMMING_LUT(0, 5)

    HAMMING_LUT(1, 0)
    HAMMING_LUT(1, 1)
    HAMMING_LUT(1, 2)

    tmp_0_0 <= val(5 downto 0);
    tmp_0_1 <= val(11 downto 6);
    tmp_0_2 <= val(17 downto 12);
    tmp_0_3 <= val(23 downto 18);
    tmp_0_4 <= val(29 downto 24);
    tmp_0_5 <= val(35 downto 30);

    -- MSB of weights W_n
    tmp_1_2(0) <= tmp_out_0_0(2);
    tmp_1_2(1) <= tmp_out_0_1(2);
    tmp_1_2(2) <= tmp_out_0_2(2);
    tmp_1_2(3) <= tmp_out_0_3(2);
    tmp_1_2(4) <= tmp_out_0_4(2);
    tmp_1_2(5) <= tmp_out_0_5(2);

    tmp_1_1(0) <= tmp_out_0_0(1);
    tmp_1_1(1) <= tmp_out_0_1(1);
    tmp_1_1(2) <= tmp_out_0_2(1);
    tmp_1_1(3) <= tmp_out_0_3(1);
    tmp_1_1(4) <= tmp_out_0_4(1);
    tmp_1_1(5) <= tmp_out_0_5(1);

    -- LSB of weights W_n
    tmp_1_0(0) <= tmp_out_0_0(0);
    tmp_1_0(1) <= tmp_out_0_1(0);
    tmp_1_0(2) <= tmp_out_0_2(0);
    tmp_1_0(3) <= tmp_out_0_3(0);
    tmp_1_0(4) <= tmp_out_0_4(0);
    tmp_1_0(5) <= tmp_out_0_5(0);

    sum_a <= unsigned('0' & tmp_out_1_2 & '0') + unsigned(tmp_out_1_1);
    sum_b <= (sum_a & '0' ) + unsigned(tmp_out_1_0);

    weight <= std_logic_vector(sum_b);

end architecture hamming_lut_arch;
