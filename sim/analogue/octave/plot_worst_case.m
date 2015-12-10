% Load first set

start_dir = pwd;

cd ../mc_1_data

load ("0/mc_data_0.octave");
v_min = v_filter_out;
v_max = v_filter_out;

% Loop through all input data
tol_dir = pwd;

for i = 0:131
    subdir = sprintf("%i", i);
    cd(subdir);
    file_list = glob("*.octave");

    for j = 1:numel(file_list)
	filename = sprintf("%s", file_list{j});
	load(filename);
	v_min = min(v_min, v_filter_out);
	v_max = max(v_max, v_filter_out);
    endfor

    cd(tol_dir);
endfor

cd(start_dir);
