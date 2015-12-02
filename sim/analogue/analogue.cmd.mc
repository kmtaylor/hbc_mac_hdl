* Model Definitions
.INCLUDE ~/Spice/Models/OPA356.MOD
.INCLUDE ~/Spice/Models/TLV3501.MOD

* NG-Spice Simulation Commands
*.control
*SET XTRTOL=1
*.endc

*.OPTIONS RELTOL=.01
*.OPTIONS ABSTOL=1N VNTOL=1M
*.OPTIONS ITL4=500
*.OPTIONS RAMPTIME=10NS
*.OPTIONS METHOD=GEAR
*.OPTIONS ACCURATE=1 GMIN=1e-9

* Remove the .SAVE commands when doing a sensitivity analysis
*.SAVE v(filter_in) v(filter_out)
*.SAVE v(filter_out_100) v(filter_out_200) v(filter_out_300) v(filter_out_400)
*.SAVE v(rx_data)

* Set V_TX to "AC 1.25 DC 1.25"

* let ::= Vector assignment
* set ::= Variable assignment
.options noacct
.control
    let tolerance = 0.01			    $ Plot scope is const
    let brute_force = false			    $ Global to all plots
    let loops = 2
    let num_vals = 17
    let print_vals = false
    let do_plot = false

    if brute_force
	let loops = 2^num_vals
	save v(filter_out)
    end

    if do_plot = false
	let toplevel_dir_vect = tolerance * 100
	set toplevel_dir = $&toplevel_dir_vect
	let dir_vect = 0
    end

    define unif(nom, tol) (nom + nom*tol*sunif(0))
    define limit(nom, tol) (nom + ((sgauss(0) >= 0) ? (nom*tol) : -(nom*tol)))
    define brute(nom, tol, rand) (nom + (rand ? (nom*tol) : -(nom*tol)))

    run						    $ Loads component values
    let r101_val = @r101[resistance]
    let r102_val = @r102[resistance]		    $ Cant use set here as set
    let r103_val = @r103[resistance]		    $ creates a pointer to the
    let r301_val = @r301[resistance]		    $ value to be changed ie:
    let r302_val = @r302[resistance]		    $ c101_val would be @c101[c]
    let r303_val = @r303[resistance]		    $ and not constant
    let r201_val = @r201[resistance]
    let r202_val = @r202[resistance]
    let r203_val = @r203[resistance]
    let r204_val = @r204[resistance]
    let c101_val = @c101[capacitance]
    let c102_val = @c102[capacitance]
    let c103_val = @c103[capacitance]
    let c301_val = @c301[capacitance]
    let c302_val = @c302[capacitance]
    let c201_val = @c201[capacitance]
    let c202_val = @c202[capacitance]

    let run_i = 0
    let brute_val = 0				    $ Must have const scope
    let brute_tmp = 0
    let brute_vect = unitvec(num_vals)*0
    let brute_i = 0

    set curplot = new				    $ Allocate a new plot
    set curplottitle = "Monte Carlo Simulation"	    $ New plot's name
    set mc_plot = $curplot			    $ Pointer to new plot

    dowhile run_i < loops

	$ Calculate brute_vect:
	let brute_tmp = brute_val
	let brute_i = 0
	while brute_tmp > 0
	    let brute_vect[brute_i] = brute_tmp % 2
	    let brute_tmp = (brute_tmp - brute_vect[brute_i]) / 2
	    let brute_i = brute_i + 1
	end
	let brute_val = brute_val + 1

	if brute_force
	    alter r101 = brute(r101_val, tolerance, brute_vect[0])
	    alter r102 = brute(r102_val, tolerance, brute_vect[1])
	    alter r103 = brute(r103_val, tolerance, brute_vect[2])
	    alter r301 = brute(r301_val, tolerance, brute_vect[3])
	    alter r302 = brute(r302_val, tolerance, brute_vect[4])
	    alter r303 = brute(r303_val, tolerance, brute_vect[5])
	    alter r201 = brute(r201_val, tolerance, brute_vect[6])
	    alter r202 = brute(r202_val, tolerance, brute_vect[7])
	    alter r203 = brute(r203_val, tolerance, brute_vect[8])
	    alter r204 = brute(r204_val, tolerance, brute_vect[9])
	    alter c101 = brute(c101_val, tolerance, brute_vect[10])
	    alter c102 = brute(c102_val, tolerance, brute_vect[11])
	    alter c103 = brute(c103_val, tolerance, brute_vect[12])
	    alter c301 = brute(c301_val, tolerance, brute_vect[13])
	    alter c302 = brute(c302_val, tolerance, brute_vect[14])
	    alter c201 = brute(c201_val, tolerance, brute_vect[15])
	    alter c202 = brute(c202_val, tolerance, brute_vect[16])
	else
	    alter r101 = unif(r101_val, tolerance)
	    alter r102 = unif(r102_val, tolerance)
	    alter r103 = unif(r103_val, tolerance)
	    alter r301 = unif(r301_val, tolerance)
	    alter r302 = unif(r302_val, tolerance)
	    alter r303 = unif(r303_val, tolerance)
	    alter r201 = unif(r201_val, tolerance)
	    alter r202 = unif(r202_val, tolerance)
	    alter r203 = unif(r203_val, tolerance)
	    alter r204 = unif(r204_val, tolerance)
	    alter c101 = unif(c101_val, tolerance)
	    alter c102 = unif(c102_val, tolerance)
	    alter c103 = unif(c103_val, tolerance)
	    alter c301 = unif(c301_val, tolerance)
	    alter c302 = unif(c302_val, tolerance)
	    alter c201 = unif(c201_val, tolerance)
	    alter c202 = unif(c202_val, tolerance)
	end

	if print_vals	
	    print @r101[resistance]
	    print @r102[resistance]
	    print @r103[resistance]
	    print @r301[resistance]
	    print @r302[resistance]
	    print @r303[resistance]
	    print @r201[resistance]
	    print @r202[resistance]
	    print @r203[resistance]
	    print @r204[resistance]
	    print @c101[capacitance]
	    print @c102[capacitance]
	    print @c103[capacitance]
	    print @c301[capacitance]
	    print @c302[capacitance]
	    print @c201[capacitance]
	    print @c202[capacitance]
	end

	AC DEC 100 10K 100Meg			    $ Creates a new plot
	set ac = $curplot			    $ Pointer to AC plot
	set run_var = "$&run_i"

	if do_plot
	    setplot $mc_plot 
	    if run_i = 0
		let frequency = {$ac}.frequency
	    end
	    let vout.{$run_var} = {$ac}.v(filter_out)
	else
	    let dir_vect = floor(run_i/1000)
	    set dir = $&dir_vect
	    write mc_rand_{$toplevel_dir}/{$dir}/mc_data_{$run_var}.raw
	end

	echo finished run: $run_var

	if run_i
	    destroy $ac_old
	end
	set ac_old = $ac
        let run_i = run_i + 1
    end
    
    if do_plot
	setplot $ac
	plot db({$mc_plot}.allv)
    end

.endc
