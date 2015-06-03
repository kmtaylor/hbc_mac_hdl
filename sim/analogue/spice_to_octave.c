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
static double *val_buf;
static double *time_buf;
static int val_buf_count, time_buf_count;

static int octave_open_file(const char *filename) {
    val_fp = fopen(filename, "w");

    printf("Opening %s for writing\n", filename);

    if (!val_fp) {
	printf("Couldn't open value file %s\n", filename);
	return -1;
    }

    return 0;
}

static void print_var_header(const char *var_name, int num_samples) {
    fprintf(val_fp, "# name: %s\n", var_name);
    fprintf(val_fp, "# type: matrix\n");
    fprintf(val_fp, "# rows: 1\n");
    fprintf(val_fp, "# columns: %i\n", num_samples);
}

#define SKIP 0
static void octave_dump_vals(const char *val_name) {
    int index;
    print_var_header("t", time_buf_count);
    for (index = SKIP; index < time_buf_count; index++) {
	fprintf(val_fp, "%e ", time_buf[index]);
    }
    fprintf(val_fp, "\n");

    print_var_header(val_name, val_buf_count);
    for (index = SKIP; index < val_buf_count; index++) {
	fprintf(val_fp, "%e ", val_buf[index]);
    }
    fprintf(val_fp, "\n");
}

#define BUF_SIZE 1024
/* Allocate buffers of BUF_SIZE doubles and fill them. */
static void octave_write_val(double time, double value) {
    static int val_buf_size, time_buf_size;

    if ((!val_buf) || (val_buf_count >= val_buf_size)) {
	val_buf_size += BUF_SIZE;
	val_buf = realloc(val_buf, sizeof(double) * val_buf_size);
    }

    if ((!time_buf) || (time_buf_count >= time_buf_size)) {
	time_buf_size += BUF_SIZE;
	time_buf = realloc(time_buf, sizeof(double) * time_buf_size);
    }

    val_buf[val_buf_count++] = value;
    time_buf[time_buf_count++] = time;
}

int main(int argc, char **argv) {
    WaveFile *wf;
    WvTable *table;
    int i;
    WaveVar *var;
    double time, val;

    if (argc < 4) {
	printf("Usage: spice_to_octave net_name "
		"octave_file_name octave_var_name\n");
	return 1;
    }

    wf = wf_read(FILENAME_STR, NULL);
    printf("Number of tables: %i\n", wf->wf_ntables);

    table = wf_wtable(wf, 0);
    printf("Number of values: %i\n", table->nvalues);
    printf("Independent variable: %s\n", table->iv->sv->name);
    printf("%i dependent variables\n", table->wt_ndv); 

    var = wf_find_variable(wf, argv[1], 0);

    if (!var) {
	printf("Variable %s not found\n", argv[1]);
	return 1;
    }
    printf("Found var: %s\n", var->sv->name);

    if (octave_open_file(argv[2]) < 0) {
	printf("Couldn't open %s for writing\n", argv[2]);
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

    /* Loop through data and find edges. Consider an edge where the value
     * passes a threshold point. We'll use (2/3)Vdd and (1/3)Vdd */

    for (i = 0; i < table->nvalues; i++) {
	time = wds_get_point(var->wv_iv->wds, i);
	val = wds_get_point(var->wds, i);

	octave_write_val(time, val);
    }

    wf_free(wf);

    octave_dump_vals(argv[3]);

    return 0;
}
