
load("../v_filter_out_100.octave");
load("../v_filter_out_400.octave");
load("../v_filter_out_300.octave");
load("../v_filter_out.octave");

semilogx(f_spice, 20*log10(abs(v_filter_out_100)), ":", f_spice, 20*log10(abs(v_filter_out_400)), "--", f_spice, 20*log10(abs(v_filter_out_300)), "-.", f_spice, 20*log10(abs(v_filter_out)));

axis([100e3 500e6 -120 0]);

legend("Twin-T", "Twin-T Loaded", "Low Pass", "High Pass");
legend("boxoff");
legend("location", "southeast");

eng_axis;
