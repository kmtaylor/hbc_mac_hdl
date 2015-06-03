#Resample inputs at 1ns resolution 

# Input FIXME: Name this net
load("v_filter_in.octave");
time = 0 : 1e-9 : t(numel(t));
input_int = interp1(t, v_filter_in, time, "pchip");

# Output FIXME: Name this net
load("v_filter_out.octave");
time = 0 : 1e-9 : t(numel(t));
output_int = interp1(t, v_filter_out, time, "pchip");

# Build f from time
fft_points = size(time)(2)/2 + 1;
f_max = 1/(2*(time(2) - time(1)));
f = [f_max/(fft_points-1) : f_max/(fft_points-1) : f_max];

# Perform FFT - IGNORE DC
input_f_prenorm = 20*log10(abs(fft(input_int)(2:fft_points)));
output_f_prenorm = 20*log10(abs(fft(output_int)(2:fft_points)));

# Normalise each data set
input_f = input_f_prenorm - max(input_f_prenorm);
output_f = output_f_prenorm - max(output_f_prenorm);

mask = spectral_mask(f);

clf; plot(f, input_f, f, output_f, f, mask);
