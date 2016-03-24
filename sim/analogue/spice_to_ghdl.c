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

/* gcc -Wall spice_to_ghdl.c -o spice_to_ghdl -I/usr/include/gwave2 `pkg-config glib-2.0 --cflags` -lspicefile `pkg-config glib-2.0 --libs` -D_GNU_SOURCE */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <gwave2/wavefile.h>

#define GHDL_STIM_DIR "../"
#ifndef FILENAME
#define FILENAME analogue.raw
#endif
#define str(s) #s
#define xstr(s) str(s)
#define FILENAME_STR xstr(FILENAME)

/*  TYPE std_ulogic IS ( 'U',  -- Uninitialized
 *                       'X',  -- Forcing  Unknown
 *                       '0',  -- Forcing  0
 *                       '1',  -- Forcing  1
 *                       'Z',  -- High Impedance
 *                       'W',  -- Weak     Unknown
 *                       'L',  -- Weak     0
 *                       'H',  -- Weak     1
 *                       '-'   -- Don't care
 *                     ); */

typedef enum {
    STD_LOGIC_U,
    STD_LOGIC_X,
    STD_LOGIC_0,
    STD_LOGIC_1,
    STD_LOGIC_Z,
    STD_LOGIC_W,
    STD_LOGIC_L,
    STD_LOGIC_H,
    STD_LOGIC_D,
} std_logic;

static FILE *time_fp, *val_fp;

static int ghdl_open_file(const char *filename) {
    char *time_filename, *val_filename;

    asprintf(&val_filename, "%s%s.value", GHDL_STIM_DIR, filename);
    asprintf(&time_filename, "%s%s.time", GHDL_STIM_DIR, filename);

    time_fp = fopen(time_filename, "w");
    val_fp = fopen(val_filename, "w");

    printf("Opening %s for writing\n", val_filename);
    printf("Opening %s for writing\n", time_filename);

    free(time_filename);
    free(val_filename);

    if (!time_fp) {
	printf("Couldn't open time file %s\n", time_filename);
        return -1;
    }

    if (!val_fp) {
        printf("Couldn't open value file %s\n", val_filename);
        return -1;
    }

    return 0;
}

//#define DELAY 100e-9
#define DELAY 100e-9
#define DEBUG_EDGES 0
static int ghdl_write_val(double time, int value) {
    static int last_val = -1;
    uint64_t ghdl_time;
    uint8_t ghdl_val;
    int retval = 0;

    if ((last_val >=0) && (last_val == value)) {
#if DEBUG_EDGES
	/* This can occur if the voltage increases past the low threshold, but
	 * does not cross the high threshold. A subsequent voltage decrease
	 * can then retrigger a negative edge. */
	printf("Warning: Recieved identical edges at time: %e\n", time);
#endif
	retval = -1;
    }

    /* Need to write using the same endianness as the ghdl host machine */
    ghdl_time = (long) ((time + DELAY) * 1e15);
    if (value) ghdl_val = STD_LOGIC_0;
    else ghdl_val = STD_LOGIC_1;

    fwrite(&ghdl_time, sizeof(uint64_t), 1, time_fp);
    fwrite(&ghdl_val, sizeof(uint8_t), 1, val_fp);

    last_val = value;
    return retval;
}

int main(int argc, char **argv) {
    WaveFile *wf;
    WvTable *table;
    int i;
    WaveVar *var;
    double time, old_val, new_val;
    double hi_threshold, lo_threshold;

    if (argc < 3) {
	printf("Usage: spice_to_ghdl net_name ghdl_stim_name\n");
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

    if (ghdl_open_file(argv[2]) < 0) {
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

#define Vdd 3.3
    hi_threshold = (2.0*Vdd/3.0);
    lo_threshold = (1.0*Vdd/3.0);
    old_val = Vdd;

    for (i = 0; i < table->nvalues; i++) {
	time = wds_get_point(var->wv_iv->wds, i);
	new_val = wds_get_point(var->wds, i) + 1.65;

	if ((old_val < hi_threshold) && (new_val >= hi_threshold)) {
	    /* Found a positive edge */
	    if (ghdl_write_val(time, 1) < 0) {
	    }
	} else if ((old_val > lo_threshold) && (new_val <= lo_threshold)) {
	    /* Found a negative edge */
	    if (ghdl_write_val(time, 0) < 0) {
	    }
	}
	old_val = new_val;
    }

    wf_free(wf);

    return 0;
}
