    % Design parameters
    %N = 3;
    %RP = 2;
    %RS = 80;
    %WP = 2*pi*18e6;
    %type = "high";

    %N = 2;
    %RP = 2;
    %RS = 80;
    %WP = 2*pi_23e6;
    %type = "low";
    %Ignore zeros;

    plot_step = 0;
    plot_sim = 0;
    plot_spectrum = 0;
    plot_freqs = 1;

    z = [   6.2832e+06j, -6.2832e+06j,	%twin_t: 1MHz, -1MHz
	    0, 0,			%s_k_hpf
	];
    p = [   -3.1290e+08,		%twin_t: 49.8MHz
	    -1.2617e+05,		%twin_t: 20kHz
	    -2.3416e+07 + 1.1778e+08j,	%s_k_hpf 19.1MHz, Q = 2.56
	    -2.3416e+07 - 1.1778e+08j,
	    -5.8077e+07 + 1.1755e+08j,	%s_k_lpf 20.9MHz, Q = 1.13
	    -5.8077e+07 - 1.1755e+08j,
	];

    g = 10e15;				%s_k_lpf
    %g = .3;


z = reshape(z, 1, numel(z));
p = reshape(p, 1, numel(p));
[q_z, w_z] = pole2qw(z);
[q_p, w_p] = pole2qw(p);

printf("Gain:     %s\n", print_eng(g));
printf("Zeros at: %s\n", print_eng_list(w_z./(2*pi), false, true));
printf("Poles at: %s\n", print_eng_list(w_p./(2*pi), false, true));
printf("Pole Qs:  %s\n", print_eng_list(q_p, false, true));

num = poly(z);
den = poly(p);

tr_func = tf(g * real(num), real(den));

if plot_step == 1
    step(tr_func);
    eng_axis;
elseif plot_sim == 1
    output_sim = lsim(tr_func, input_int, time);
    plot(time, input_int, time, output_sim);
    axis([3.5321e-06   4.0226e-06  -1.4175e-02   1.6692e+00]);
    eng_axis;
elseif plot_spectrum == 1
    output_sim = lsim(tr_func, input_int, time);
    output_sim_f = 20*log10(abs(fft(output_sim)(2:fft_points)));
    output_sim_f = output_sim_f - max(output_sim_f);
    plot(f, input_f, f, output_sim_f, f, mask);
elseif plot_freqs == 1
    h_db = 20*log10(abs(freqs(g * real(num), real(den), 2*pi*f)));
h_db = h_db - max(h_db);
    load("../v_filter_out.octave");
%    output_f = input_f + h_db;
    output_f = input_f + 20*log10(abs(v_filter_out));
    output_f = output_f - max(output_f);
    %plot(f, input_f, f, output_f, f, mask, f, h_db);
    plot(f(1:1:numel(f)), output_f(1:1:numel(output_f)), f, mask, f, h_db, f_spice, 20*log10(abs(v_filter_out)));
  %  plot(f, output_f, f, mask, f_spice, 20*log10(abs(v_filter_out)));
%    plot(f, mask, f, h_db, f_spice, 20*log10(v_filter_out));
    axis([0, 42e6, -130, 0]);
endif
