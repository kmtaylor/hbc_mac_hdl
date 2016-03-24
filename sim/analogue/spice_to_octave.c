/* Copyright (C) 2016 Kim Taylor
 *
 * This file is part of hbc_mac.
 *
 * hbc_mac is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * hbc_mac is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with hbc_mac.  If not, see <http://www.gnu.org/licenses/>.
 */

/* gcc -Wall spice_to_octave.c -o spice_to_octave -I/usr/include/gwave2 `pkg-config glib-2.0 --cflags` -lspicefile `pkg-config glib-2.0 --libs` -D_GNU_SOURCE */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <gwave2/wavefile.h>

#ifndef FILENAME
#define FILENAME analogue.raw
#endif
#define str(s) #s
#define xstr(s) str(s)
#define FILENAME_STR xstr(FILENAME)

static FILE *val_fp;
static double *im_val_buf;
static double *val_buf;
static double *time_buf;
static int im_val_buf_count, val_buf_count, time_buf_count;
static int complex_data;

static int octave_open_file(const char *filename) {
    val_fp = fopen(filename, "w");

    printf("Opening %s for writing\n", filename);

    if (!val_fp) {
	printf("Couldn't open value file %s\n", filename);
	return -1;
    }

    return 0;
}

static void print_var_header(const char *var_name, int num_samples, int real) {
    fprintf(val_fp, "# name: %s\n", var_name);
    if (real) fprintf(val_fp, "# type: matrix\n");
    else fprintf(val_fp, "# type: complex matrix\n");
    fprintf(val_fp, "# rows: 1\n");
    fprintf(val_fp, "# columns: %i\n", num_samples);
}

#define SKIP 0
static void octave_dump_vals(const char *val_name) {
    int index;
    if (complex_data) print_var_header("f_spice", time_buf_count, 1);
    else print_var_header("t", time_buf_count, 1);
    for (index = SKIP; index < time_buf_count; index++) {
	fprintf(val_fp, "%e ", time_buf[index]);
    }
    fprintf(val_fp, "\n");

    print_var_header(val_name, val_buf_count, !complex_data);
    for (index = SKIP; index < val_buf_count; index++) {
	if (complex_data) {
	    fprintf(val_fp, "(%e,%e) ", val_buf[index], im_val_buf[index]);
	} else {
	    fprintf(val_fp, "%e ", val_buf[index]);
	}
    }
    fprintf(val_fp, "\n");
}

#define BUF_SIZE 1024
/* Allocate buffers of BUF_SIZE doubles and fill them. */
static void octave_write_val(double time, double value, double im_value) {
    static int val_buf_size, time_buf_size, im_val_buf_size;

    if ((!im_val_buf) || (im_val_buf_count >= im_val_buf_size)) {
	im_val_buf_size += BUF_SIZE;
	im_val_buf = realloc(im_val_buf, sizeof(double) * im_val_buf_size);
    }

    if ((!val_buf) || (val_buf_count >= val_buf_size)) {
	val_buf_size += BUF_SIZE;
	val_buf = realloc(val_buf, sizeof(double) * val_buf_size);
    }

    if ((!time_buf) || (time_buf_count >= time_buf_size)) {
	time_buf_size += BUF_SIZE;
	time_buf = realloc(time_buf, sizeof(double) * time_buf_size);
    }

    im_val_buf[im_val_buf_count++] = im_value;
    val_buf[val_buf_count++] = value;
    time_buf[time_buf_count++] = time;
}

int main(int argc, char **argv) {
    WaveFile *wf;
    WvTable *table;
    int i;
    WaveVar *var;
    double time, val, im_val;

    if (argc < 5) {
	printf("Usage: spice_to_octave input_file net_name "
		"octave_file_name octave_var_name\n");
	return 1;
    }

    wf = wf_read(argv[1], NULL);
    printf("Number of tables: %i\n", wf->wf_ntables);

    table = wf_wtable(wf, 0);
    printf("Number of values: %i\n", table->nvalues);
    printf("Independent variable: %s\n", table->iv->sv->name);
    printf("%i dependent variables\n", table->wt_ndv); 

    var = wf_find_variable(wf, argv[2], 0);

    if (!var) {
	printf("Variable %s not found\n", argv[2]);
	return 1;
    }
    if (var->wv_ncols == 2) complex_data = 1;
    printf("Found %s var: %s\n", 
		    complex_data ? "complex" : "real", var->wv_name);

    if (octave_open_file(argv[3]) < 0) {
	printf("Couldn't open %s for writing\n", argv[3]);
	return 1;
    }

    /* API:
     * Linear interpolation: time->value
     * double wv_interp_value(WaveVar *dv, double ival);
     *
     * Get index from independent variable (time)
     * int wf_find_point(WaveVar *iv, double ival);
     *
     * Get data val at index (independent or dependent) 
     * double wds_get_point(WDataSet *ds, int n);
     */

    for (i = 0; i < table->nvalues; i++) {
	time = wds_get_point(var->wv_iv->wds, i);
	val = wds_get_point(&var->wds[0], i);

	if (complex_data) im_val = wds_get_point(&var->wds[1], i);
	else im_val = 0;

	octave_write_val(time, val, im_val);
    }

    wf_free(wf);

    octave_dump_vals(argv[4]);

    return 0;
}
