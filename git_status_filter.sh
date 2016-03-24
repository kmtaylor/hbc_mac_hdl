git status |	sed '/\.o$/d'	    | \
		sed '/\.ghw$/d'	    | \
		sed '/\.cf$/d'	    | \
		sed '/\.vhd$/d'	    | \
		sed '/\.swp$/d'	    | \
		sed '/\.octave/d'
