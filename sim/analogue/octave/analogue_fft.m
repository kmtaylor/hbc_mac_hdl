#Resample inputs at 1ns resolution 
#Skip first n samples to get rid of LF

skip = 1;

# Input
load("../v_filter_in.octave");
time = t(skip) : 1e-9 : t(numel(t));
input_int = interp1(t(skip:end), v_filter_in(skip:end), time, "pchip");

# Output
load("../v_filter_out.octave");
output_int = interp1(t(skip:end), v_filter_out(skip:end), time, "pchip");

# Build f from time
fft_points = numel(time)/2 + 1;
f_max = 1/(2*(time(2) - time(1)));
f = [f_max/(fft_points-1) : f_max/(fft_points-1) : f_max];

# Perform FFT - IGNORE DC
input_f = 20*log10(abs(fft(input_int)(2:fft_points)));
output_f = 20*log10(abs(fft(output_int)(2:fft_points)));

# Normalise each data set
input_f = input_f - max(input_f);
output_f = output_f - max(output_f);

mask = spectral_mask(f);

clf; plot(f, input_f, f, output_f, f, mask);
