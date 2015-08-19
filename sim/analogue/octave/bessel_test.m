
internal_params = 0;

if internal_params == 1
    % Design parameters
    N = 2;
    WP = 2*pi*23e6;
    type = "low";
    book = 0;
    plot_step = 0;
    plot_sim = 0;
    plot_spectrum = 0;
    plot_freqs = 1;
endif

if book == 1
    [p, g] = besselde(N, WP, 7.55);
    z = [];
else
    [z, p, g] = besself(N, WP, type, "s");
endif

[q_z, w_z] = pole2qw(z);
[q_p, w_p] = pole2qw(p);

printf("Gain:     %s\n", print_eng(g));
printf("Zeros at: %s\n", print_eng_list(w_z, false, true));
printf("Poles at: %s\n", print_eng_list(w_p, false, true));
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
    output_f = input_f + h_db;
    output_f = output_f - max(output_f);
    plot(f, output_f, f, mask, f, h_db);
    axis([0, 42e6, -130, 0]);
endif

