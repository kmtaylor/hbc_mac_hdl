
case $1 in
    300KHZ)
	pll_div=1
	pll_mul=6
	out_div=100
        ;;
    2MHZ)
	pll_div=5
	pll_mul=24
	out_div=120
        ;;
    5MHZ)
	pll_div=1
	pll_mul=5
	out_div=50
        ;;
    13MHZ)
	pll_div=2
	pll_mul=13
	out_div=25
        ;;
    21MHZ)
	pll_div=5
	pll_mul=21
	out_div=10
        ;;
    30MHZ)
	pll_div=1
	pll_mul=6
	out_div=10
        ;;
    42MHZ)
	pll_div=5
	pll_mul=21
	out_div=5
        ;;
    55MHZ)
	pll_div=5
	pll_mul=22
	out_div=4
        ;;
    60MHZ)
	pll_div=1
	pll_mul=6
	out_div=5
        ;;
esac

echo DIVCLK_DIVIDE: $pll_div CLKFBOUT_MULT: $pll_mul CLKOUT0_DIVIDE: $out_div

cat pll_core_21MHz.vhd |
	sed "s/DIVCLK_DIVIDE =>.*,/DIVCLK_DIVIDE => $pll_div,/" |
	sed "s/CLKFBOUT_MULT =>.*,/CLKFBOUT_MULT => $pll_mul,/" |
	sed "s/CLKOUT0_DIVIDE =>.*,/CLKOUT0_DIVIDE => $out_div,/" > pll_core.vhd
