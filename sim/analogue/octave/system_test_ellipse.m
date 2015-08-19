plot_step = 0;
plot_sim = 0;
plot_spectrum = 0;
plot_freqs = 0;

lpf_first = 1;

book = 0;

% Run low pass filter
use_custom_zero = 0;
N = 2;
RP = 2;
RS = 80;
WP = 2*pi*23e6;
type = "low";
ellip_test;

tr_func_lpf = tr_func;

% Run high pass filter
use_custom_zero = 1;
N = 3;
WP = 2*pi*18e6;
type = "high";
ellip_test;

tr_func_hpf = tr_func;

if lpf_first == 1
    output_sim_lpf = lsim(tr_func_lpf, input_int, time);
    output_sim_hpf = lsim(tr_func_hpf, output_sim_lpf, time);
    plot(time, input_int, time, output_sim_hpf);
    axis([3.5321e-06   4.0226e-06  -1  1]); eng_axis;
%    return;
    output_sim_f = 20*log10(abs(fft(output_sim_hpf)(2:fft_points)));
    output_sim_f = output_sim_f - max(output_sim_f);
    plot(f, input_f, f, output_sim_f, f, mask);
else
    output_sim_hpf = lsim(tr_func_hpf, input_int, time);
    output_sim_lpf = lsim(tr_func_lpf, output_sim_hpf, time);
    plot(time, input_int, time, output_sim_hpf, time, output_sim_lpf);
    axis([3.5321e-06   4.0226e-06  -1  1]); eng_axis;
endif
