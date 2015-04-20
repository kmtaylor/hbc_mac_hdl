words=64

get_cps() {
    case $1 in
	RI_SF_64)
	    cps=64
	    ;;
	RI_SF_32)
	    cps=32
	    ;;
	RI_SF_16)
	    cps=16
	    ;;
	RI_SF_8)
	    cps=8
	    ;;
    esac
	
}

get_chip_period() {
    case $1 in 
	300KHZ)
	chip_period_ns=1667
	;;
	2MHZ)
	chip_period_ns=250
	;;
	5MHZ)
	chip_period_ns=100
	;;
	13MHZ)
	chip_period_ns=38.5
	;;
	21MHZ)
	chip_period_ns=23.8
	;;
	30MHZ)
	chip_period_ns=16.7
	;;
	42MHZ)
	chip_period_ns=11.9
	;;
	55MHZ)
	chip_period_ns=9.1
	;;
	60MHZ)
	chip_period_ns=8.3
	;;
    esac
}

get_sim_time() {
    sim_time=`echo "scale=0; \
	     $chip_period_ns*(128 * $cps * ($words+1) + 512 * 6)/1" | bc`
}

#Run rates as separate processes
rate=$1
#for rate in RI_SF_8 RI_SF_16 RI_SF_32 RI_SF_64; do
    get_cps $rate
    for freq in 300KHZ 2MHZ 5MHZ 13MHZ 21MHZ 30MHZ 42MHZ 55MHZ 60MHZ ; do
	get_chip_period $freq
	get_sim_time

	make clean
	vhhflags="-DPACKET_RATE=$rate -DSERIAL_CLK_NS=$chip_period_ns"
	make VHHFLAGS="$vhhflags" SIMULATION_TIME="$sim_time ns"

	filename="power_report_$rate##_$freq##"
	filename=`echo $filename | sed 's/##//g'`
	cp power_report.pwr $filename

	filename="saif_$rate##_$freq##"
	filename=`echo $filename | sed 's/##//g'`
	cp xpower.saif $filename

	filename="wdb_$rate##_$freq##"
	filename=`echo $filename | sed 's/##//g'`
	cp isim.wdb $filename

    done;
#done

